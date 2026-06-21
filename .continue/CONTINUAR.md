# Blue3 Drive — Onde Paramos (handoff)

> **Atualizado:** 2026-06-21 · **Versão:** v0.1.1 · **Branch:** `master` (sincronizado com o GitHub)
> **Repo:** https://github.com/samirhvbr/BLUE3_DRIVE
>
> **Spec viva (LEIA PRIMEIRO ao retomar):** [docs/PLANO-DE-ACAO.md](../docs/PLANO-DE-ACAO.md) — arquitetura,
> decisões travadas e fases estão lá, marcadas ✅/⏳. Este arquivo é só o "snapshot de retomada".

---

## TL;DR — estado geral

A **camada Blue3** está completa e commitada. **Fases 0→4 prontas.** Falta a **Fase 5**:
subir com Docker e validar ao vivo (marca, CSS, Office, whiteboard). **Ainda não rodou em lugar nenhum**
(este ambiente não tem Docker).

```
Fase 0 — Fundação (apps pinados)        ✅
Fase 1 — Marca (tema Dark Blue3)        ✅  (validar CSS ao vivo)
Fase 2 — Curadoria (config + allowlist) ✅
Fase 3 — Enxugar UI                      ✅  (validar seletores ao vivo)
Fase 4 — Empacotamento (build)           ✅  (arquivos montados; falta rodar)
Fase 5 — Validação & docs                ⏳  ← PRÓXIMA (precisa de Docker)
```

---

## Decisões travadas (pra não reabrir discussão)

1. **Modelo em camadas, não patch.** Core e apps ficam puros; tudo Blue3 é overlay. Nunca dar merge no upstream.
2. **`/home/samir/x/DRIVE` é descartável** — só espelho de estudo; o build NÃO lê de lá.
3. **Core = imagem oficial `nextcloud:34-apache`** (MVP; fpm+nginx seria upgrade de produção).
4. **Apps externos = tarball oficial pinado** (`build/apps.versions`). Atualizar = trocar número + rebuild.
5. **Collabora = CODE embutido** (`richdocumentscode` 26.4.104) → sem container Collabora externo.
6. **notify_push = fora do MVP** (clientes em polling). `tasks` = fora do MVP (sem release p/ NC34).
7. **Tema "Dark Blue3"** = base Abyss (VS Code) + accent Blue3 `#29ABE2`. Slogan "Um local seguro para seus dados!". URL `drive.blue3.com.br`.
8. **Banco = MariaDB sempre, nunca SQLite.**
9. **Conduta:** commits `versão - comentário`; `version.md` (X.Y.Z); pt-BR; segurança prioridade máxima.

---

## O que está pronto (mapa de arquivos)

| Área | Arquivo | Status |
|---|---|---|
| Pin dos apps | [build/apps.versions](../build/apps.versions) | ✅ 8 download + bundled + deferred/out |
| Tema | [themes/blue3/defaults.php](../themes/blue3/defaults.php) · [core/css/server.css](../themes/blue3/core/css/server.css) · `core/img/*` | ✅ marca + paleta + declutter |
| Config | [config/blue3.config.php](../config/blue3.config.php) · [config/apps.allowlist](../config/apps.allowlist) | ✅ theme/loja/locale + required/enable/disable |
| Build | [build/Dockerfile](../build/Dockerfile) · [build/compose.yml](../build/compose.yml) · [build/provision.sh](../build/provision.sh) | ✅ validados offline (parser/sintaxe) |
| Segredos | [build/.env.example](../build/.env.example) | ✅ (`.env` real é ignorado) |
| Conduta | README · CLAUDE · AGENTS · SECURITY_GUIDELINES · deploy.sh · version.md | ✅ commitados em v0.1.0 |

**Apps (NC34):** calendar 6.5.0 · mail 5.10.1 · notes 6.0.0 · contacts 8.7.1 · richdocuments 11.0.0 ·
richdocumentscode 26.4.104 · deck 1.18.1 · whiteboard 1.5.9. Bundled (só habilitar): text, serverinfo,
twofactor_totp, etc.

---

## PRÓXIMA: Fase 5 — subir e validar (precisa de Docker)

### 1. Rodar (numa máquina com Docker), a partir de `BLUE3/DRIVE`:
```bash
cp build/.env.example build/.env     # preencher senhas + WHITEBOARD_JWT_SECRET (openssl rand -hex 32)
docker compose -f build/compose.yml --env-file build/.env up -d --build
# abrir http://localhost:8080  (admin = NEXTCLOUD_ADMIN_* do .env)
```
> 1º boot demora (instala NC + roda provision). `richdocumentscode` baixa ~centenas de MB.

### 2. Checklist de validação
- [ ] **Marca:** header navy, logo branco, nome "Blue3 Drive", slogan no rodapé, cor `#29ABE2`.
- [ ] **CSS Dark Blue3:** se algum `--color-*` não pegou (o app Theming sobrepõe), reforçar via `occ theming:config`.
- [ ] **Apps:** só os do `[enable]` no menu; bagunça do `[disable]` ausente; loja inacessível.
- [ ] **Office:** abrir um `.docx` → CODE embutido conecta (validar WOPI).
- [ ] **Whiteboard:** criar quadro → conecta no serviço `:3002`.

### ✅ De-riscado offline em v0.1.1 (verificado contra o fonte do NC34 em /DRIVE/SERVER)
- **Chaves do `occ theming:config`** conferidas: `color` é **deprecado** → trocado por `primary_color`;
  adicionado `background_color #000c18`; chaves de imagem `logo`/`favicon` confirmadas (caminho absoluto).
- **Imagem do whiteboard** pinada em **`:v1.5.9`** (casa com o app) — confirmado que a tag existe no GHCR.

### ⚠️ Ainda exige validação ao vivo (Docker — `provision.sh` é tolerante, não derruba o boot)
- **Seletores CSS de declutter** em `server.css` mudam entre versões do NC — conferir e ajustar.
- **CODE embutido (WOPI):** richdocuments deve auto-detectar o `richdocumentscode` (+ `allow_local_remote_servers`
  já setado). Confirmar abrindo um `.docx`.
- **Import do logo:** conferir se `occ theming:config logo` importou o arquivo certo (header/login).

---

## Pendências menores (não bloqueiam)
- Logo/favicon em **SVG** (hoje só PNG; usar PNG via Theming é aceitável). §11 do plano.
- `dashboard`/`user_status` ficam em `enable` — candidatos a desligar se quiser mais enxuto.
- `admin_audit` está em `[disable]` (MVP) — ligar se precisar de trilha de auditoria.

---

## Comandos úteis
```bash
# Atualizar um app:  editar build/apps.versions + a linha 'fetch' do Dockerfile,
#                    bumpar version.md (Z+1), depois:
./deploy.sh                                   # pull -> build -> compose up -> occ upgrade/repair

# Commit (convenção) + push
git add -A
git commit -m "0.1.1 - <o que mudou>"
git push origin master
```

---

## Como retomar amanhã (ordem sugerida)
1. Ler este arquivo + [docs/PLANO-DE-ACAO.md](../docs/PLANO-DE-ACAO.md) (Fase 5 e §11).
2. Numa máquina com Docker, rodar o `compose up --build` e percorrer o checklist da Fase 5.
3. Anotar o que destoou (CSS/theming/whiteboard) e ajustar — depois `version.md` Z+1 + commit + push.
4. Quando validado: escrever o fechamento da Fase 5 no plano e considerar apagar o `/DRIVE` (espelho).
