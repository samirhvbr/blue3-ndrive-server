#!/bin/sh
#
# Blue3 Drive — provisionamento de 1º boot.
# Roda como hook oficial "post-installation" do Nextcloud (após o install, com occ + DB prontos).
# Aplica allowlist (enable/disable), reforça o branding e tranca a loja.
#
# Best-effort: erros de occ apenas logam WARN — NUNCA abortam o boot do container.
# Ver docs/PLANO-DE-ACAO.md Fase 4.

set -u

ALLOWLIST="/usr/src/blue3/apps.allowlist"
log() { echo "[blue3-provision] $*"; }

# Executa occ como www-data (o entrypoint roda hooks como root) e tolera falha.
occ() {
	if [ "$(id -u)" = "0" ]; then
		su -p -s /bin/sh www-data -c "php /var/www/html/occ $*" || log "WARN: falhou: occ $*"
	else
		php /var/www/html/occ "$@" || log "WARN: falhou: occ $*"
	fi
}

# Extrai os app-ids de uma seção da allowlist (enable|disable|required|deferred).
# Ignora comentários e comentários inline; usa o último marcador [secao] visto.
section() {
	awk -v want="$1" '
		/\[required\]/ { sec="required"; next }
		/\[enable\]/   { sec="enable";   next }
		/\[disable\]/  { sec="disable";  next }
		/\[deferred\]/ { sec="deferred"; next }
		{ l=$0; sub(/#.*/,"",l); gsub(/[ \t]+/,"",l); if (l!="" && sec==want) print l }
	' "$ALLOWLIST"
}

log "iniciando provisionamento..."

# 1) Habilitar os apps do produto (idempotente; bundled já ligados são no-op).
for app in $(section enable); do
	log "enable  $app"; occ app:enable "$app"
done

# 2) Desligar a "bagunça" bundled (nunca toca o [required]).
for app in $(section disable); do
	log "disable $app"; occ app:disable "$app"
done

# 3) Branding via app Theming (reforça o tema nativo themes/blue3).
#    Chaves conferidas no fonte do NC34 (apps/theming UpdateConfig::SUPPORTED_KEYS):
#    name,url,imprintUrl,privacyUrl,slogan,color(DEPRECADO),primary_color,background_color,
#    disable-user-theming + imagens (background,logo,logoheader,favicon — caminho absoluto).
occ theming:config name "Blue3 Drive"
occ theming:config slogan "Um local seguro para seus dados!"
occ theming:config url "https://drive.blue3.com.br"
occ theming:config primary_color "#29ABE2"
occ theming:config background_color "#000c18"
occ theming:config logo    /var/www/html/themes/blue3/core/img/logo.png
occ theming:config favicon /var/www/html/themes/blue3/core/img/favicon.png

# 4) Trancar loja / landing (reforço — o blue3.config.php já cobre).
occ config:system:set appstoreenabled --type=boolean --value=false
occ config:system:set defaultapp --value="files"

# 4b) Admin nasce em pt-BR (idioma + locale). O default_language cobre quem tem
#     navegador pt-BR; isto garante o admin do install, que senão herdaria o
#     idioma do navegador. O seletor de idioma continua disponível — não forçamos.
if [ -n "${NEXTCLOUD_ADMIN_USER:-}" ]; then
	occ user:setting "$NEXTCLOUD_ADMIN_USER" core lang   pt_BR
	occ user:setting "$NEXTCLOUD_ADMIN_USER" core locale pt_BR
fi

# 5) Office: CODE embutido (richdocumentscode roda local em 127.0.0.1:9980).
#    Permite o NC falar com servidores locais (necessário p/ o CODE embutido).
occ config:system:set allow_local_remote_servers --type=boolean --value=true
#    richdocuments auto-detecta o richdocumentscode quando ambos ligados.
#    ⚠️ validar a conexão WOPI na Fase 5 (subir doc e abrir).

# 6) Whiteboard: apontar p/ o serviço websocket (segredo via env do compose).
if [ -n "${WHITEBOARD_JWT_SECRET:-}" ]; then
	occ config:app:set whiteboard jwt_secret_key  --value="$WHITEBOARD_JWT_SECRET"
	occ config:app:set whiteboard collabBackendUrl --value="${WHITEBOARD_PUBLIC_URL:-http://localhost:3002}"
else
	log "WHITEBOARD_JWT_SECRET vazio — pulando wiring do whiteboard"
fi

log "provisionamento concluído."
