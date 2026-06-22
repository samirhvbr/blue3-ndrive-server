# Blue3 Drive — Onde Paramos (handoff)

> **Atualizado:** 2026-06-22 · **Versão:** v0.1.3 · **Branch:** `master`
> **Repo:** https://github.com/samirhvbr/BLUE3_DRIVE
>
> **Spec viva:** [docs/PLANO-DE-ACAO.md](../docs/PLANO-DE-ACAO.md). Este arquivo é o snapshot de retomada.

---

## TL;DR

A stack **roda local** (Docker) e a **Fase 5 está quase fechada**: marca, idioma, curadoria e
whiteboard **validados ao vivo**. Falta o **Office (CODE)** — em **migração para Collabora separado**
(WIP, não commitado) — e dois itens menores (CSS declutter ao vivo, skeleton em rebuild).

```
Fase 0–4 ✅
Fase 5 — Validação ⏳  (maioria OK; Office pendente)
```

## Como rodar local

- A partir de `BLUE3/DRIVE`: `docker compose -f build/compose.yml --env-file build/.env up -d`
- **Porta 8081** (a 8080 está ocupada por um `granian` no host). `build/.env` é local (gitignored).
- **db = container MariaDB** (não o MariaDB do host). Docker exige `sudo`/grupo `docker`.

## Validado nesta sessão (2026-06-22)

- ✅ **Stack sobe** (app NC34 + db + whiteboard); 1º boot instala + roda `provision.sh`.
- ✅ **pt-BR** [0.1.2]: `default_language/locale=pt_BR` + **seletor mantido** (trocável p/ EN) +
  **admin nasce pt-BR** (`provision.sh §4b`). NÃO usamos `force_language`.
- ✅ **Tema "Deep Space"** [0.1.2]: fundo espacial 100% CSS (estrelas + nebulosa ciano `#29ABE2`)
  no **login e pós-login**; caixa de login em vidro. Sem imagem externa. (`server.css`, token `--blue3-space-*`.)
- ✅ **Curadoria** (occ conferiu): 23 `[enable]` ligados, 15 `[disable]` desligados, `[required]` intactos.
  4 apps default-on **fora da lista** (`federation`, `files_downloadlimit`, `files_lock`, `office`) —
  opcional mandar p/ `[disable]` se quiser mais enxuto.
- ✅ **Whiteboard**: abre e edita (serviço `:3002`).
- ✅ **Bug de core NC34 contornado** [0.1.3]: `theming/cachebuster` lido como string no `getManifest`
  → 500 no manifest (quebrava viewer/Office + reatividade do Files). Workaround no `provision.sh §3b`
  (`occ config:app:delete theming cachebuster`). Corrigido no core a partir do NC35.

## Pendente

### Office (CODE) — em migração p/ Collabora separado (WIP, **NÃO commitado**)
- **Embutido (`richdocumentscode`) NÃO abre.** Além do cachebuster (resolvido), o `richdocuments`
  falha ao parsear o discovery: `Call to a member function xpath() on false` em `WOPI/Parser.php:42`.
  A imagem `nextcloud:34-apache` é a **34.0.0** (release .0 de 2026-06-16; bugs estão nela; sem 34.0.1 ainda).
- **Tentativa Collabora separado (em andamento) — na branch `office-collabora` (pushed):**
  - `build/compose.yml` (na branch): serviço `collabora` (collabora/code:latest) +
    `extra_hosts: host.docker.internal:host-gateway` no `app` e no `collabora`.
  - Ao vivo via `occ`: `richdocumentscode` **disabled**; `richdocuments wopi_url=http://host.docker.internal:9980`;
    `overwrite.cli.url=http://host.docker.internal:8081`; `trusted_domains += host.docker.internal[:8081]`.
  - `/etc/hosts`: `127.0.0.1 host.docker.internal`. **Acesso mudou p/ `http://host.docker.internal:8081`.**
  - **Resultado:** discovery NC→Collabora = **HTTP 200** (avançou — o embutido falhava aqui). MAS o
    `.docx` **ainda trava no "Carregando"** (provável WOPISrc/WebSocket Collabora→NC ou o token).
- **Retomar:** `git checkout office-collabora` (traz o compose do Collabora) → abrir doc em
  `host.docker.internal:8081` → `docker logs --tail 40 blue3-drive-collabora-1` + `occ log:tail 15`;
  checar WOPISrc/WS. Se resolver: bakear as configs `occ` no `provision.sh`,
  **remover `richdocumentscode` do build** (Dockerfile + apps.versions + allowlist — slim ~300 MB),
  atualizar `.env.example`/`compose.yml`, fechar a **decisão §8** (embutido → separado), bump **0.2.0**.

### Menores
- **CSS declutter**: não conferido ao vivo (4 seletores em `server.css`: "Apps de celular/desktop",
  "Arquivos recomendados", contatos recentes, atalho App Store). Ajustar seletor se algum ainda aparecer no NC34.
- **Skeleton Blue3**: feito no build; falta validar num **rebuild** (criar usuário novo).

## Commits desta sessão (no `master`)
- `0.1.2` ×3: pt-BR · Deep Space (login+pós-login) · Skeleton Blue3.
- `0.1.3`: fix do cachebuster (500 do Theming) + este handoff.
- **Branch `office-collabora`** (pushed, fora do master): `build/compose.yml` com o serviço Collabora — WIP do Office (`git checkout office-collabora` p/ retomar).

---

**Responsável:** Samir Hanna Verza · **Empresa:** Blue3
