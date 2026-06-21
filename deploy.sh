#!/bin/bash
# versão 1.0 - 2026-06-20
#
# Deploy idempotente do Blue3 Drive (Docker Compose).
# Adaptado do deploy.sh da Blue3 Intranet — aqui NÃO há composer/npm/artisan:
# o "deploy" é git pull -> rebuild da imagem -> recriar a stack -> occ upgrade/repair.
#
# - Sai cedo se nada novo no branch.
# - Lock impede dois deploys simultâneos.
# - Rebuild só reusa cache do Docker (layers inalteradas não rebuildam).
# - Em erro, tenta tirar o NC do modo manutenção e avisa no Telegram (se configurado).
#
# Pré-requisitos:
#   - rodar a partir da raiz do repo (BLUE3/DRIVE), por um usuário no grupo 'docker';
#   - build/.env preenchido (cp de build/.env.example).
#
# Variáveis OPCIONAIS no build/.env (notificação):
#   DEPLOY_TELEGRAM_BOT_TOKEN, DEPLOY_TELEGRAM_CHAT_ID

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # raiz do repo (onde está este script)
BRANCH="${DEPLOY_BRANCH:-master}"
ENV_FILE="$DIR/build/.env"
COMPOSE=(docker compose -f "$DIR/build/compose.yml" --env-file "$ENV_FILE")
APP_SVC="app"
LOCK="/tmp/blue3-drive-deploy.lock"

# ── Helpers ──────────────────────────────────────────────────────────────────
log() { printf '[%(%H:%M:%S)T] %s\n' -1 "$*"; }

get_env() {  # lê uma chave do build/.env sem 'source'
    local key=$1
    [ -f "$ENV_FILE" ] || return 0
    { grep -E "^${key}=" "$ENV_FILE" 2>/dev/null || true; } | head -1 | cut -d= -f2- | sed 's/^"//;s/"$//'
}

# occ dentro do container, como www-data, tolerante a falha do call site.
occ() { "${COMPOSE[@]}" exec -T -u www-data "$APP_SVC" php /var/www/html/occ "$@"; }

notify() {
    [ -n "${TG_BOT:-}" ] && [ -n "${TG_CHAT:-}" ] || return 0
    curl -fsS -m 5 -X POST "https://api.telegram.org/bot${TG_BOT}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT}" \
        --data-urlencode "text=$1" \
        --data-urlencode "parse_mode=HTML" >/dev/null 2>&1 || log "(notify Telegram falhou; ignorando)"
}

cleanup_on_failure() {
    log "❌ Deploy falhou — tentando tirar o NC do modo manutenção..."
    occ maintenance:mode --off >/dev/null 2>&1 || true
    notify "❌ <b>Deploy Blue3 Drive falhou</b> em <code>$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null || echo '?')</code>"
}
fail() { log "❌ $*"; cleanup_on_failure; exit 1; }

# ── Pré-requisitos ───────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || { printf '❌ docker não encontrado no PATH\n' >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { printf '❌ "docker compose" (v2) indisponível\n' >&2; exit 1; }
[ -f "$ENV_FILE" ] || { printf '❌ %s não existe (cp de build/.env.example)\n' "$ENV_FILE" >&2; exit 1; }

cd "$DIR"

# ── Lock ─────────────────────────────────────────────────────────────────────
exec 9>"$LOCK"
flock -n 9 || { printf '❌ outro deploy já está rodando (lock: %s)\n' "$LOCK" >&2; exit 1; }

TG_BOT=$(get_env DEPLOY_TELEGRAM_BOT_TOKEN)
TG_CHAT=$(get_env DEPLOY_TELEGRAM_CHAT_ID)

# ── 1. Fetch e checagem de mudanças ─────────────────────────────────────────
log "==> Buscando alterações em origin/$BRANCH..."
git fetch --quiet origin "$BRANCH" || fail "git fetch falhou"

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✓ Nada novo em origin/$BRANCH. Saindo."
    exit 0
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    log "⚠️  Working tree tem mudanças locais não commitadas."
fi

log "==> Trazendo $(git rev-parse --short "$LOCAL") → $(git rev-parse --short "$REMOTE")..."
git merge --ff-only "origin/$BRANCH" \
    || fail "fast-forward falhou (working tree divergiu? resolva manual e rode de novo)"

# Daqui pra frente, falha dispara cleanup.
trap cleanup_on_failure ERR

# ── 2. Build + subir a stack (Docker reusa cache de layers inalteradas) ─────
log "==> Build da imagem + recriação da stack..."
"${COMPOSE[@]}" up -d --build || fail "docker compose up --build falhou"

# ── 3. Esperar o app responder ───────────────────────────────────────────────
log "==> Aguardando o Nextcloud responder..."
ok=0
for i in $(seq 1 30); do
    if occ status >/dev/null 2>&1; then ok=1; break; fi
    sleep 4
done
[ "$ok" = "1" ] || fail "o container app não respondeu ao occ a tempo"

# ── 4. occ upgrade / repair (caso versões de core/app tenham mudado) ────────
log "==> occ upgrade (se necessário) + repair..."
occ upgrade --no-interaction || log "  (occ upgrade: nada a fazer ou já atualizado)"
occ maintenance:repair --include-expensive >/dev/null 2>&1 || true
occ db:add-missing-indices >/dev/null 2>&1 || true
occ maintenance:mode --off >/dev/null 2>&1 || true

# Sucesso.
trap - ERR
SHORT_SHA=$(git rev-parse --short HEAD)
SUBJECT=$(git log -1 --pretty=%s | head -c 80)
VER=$(cat "$DIR/version.md" 2>/dev/null | head -1 | tr -d '[:space:]')
log "✅ Deploy concluído: v${VER:-?} ($SHORT_SHA — $SUBJECT)"
notify "✅ <b>Blue3 Drive deployado</b>: v${VER:-?} <code>$SHORT_SHA</code> — $SUBJECT"
