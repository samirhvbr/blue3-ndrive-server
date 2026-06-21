# Blue3 Drive

> Distribuição do **Nextcloud 34** com a cara da **Blue3**, enxuta e curada.
> Documentação interna — versionar é obrigatório; publicar é opcional.
> Sempre commit com boa descrição no formato `versão - comentário`.

**Ver também:** [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md) (spec viva — arquitetura, decisões, fases) ·
[CLAUDE.md](CLAUDE.md) (convenções de código e do agente) ·
[SECURITY_GUIDELINES.md](SECURITY_GUIDELINES.md) (segurança — sempre revisar).

## O que é

Uma **camada Blue3 sobre o Nextcloud**, montada por **overlay** (sem patch no core):

- **Marca** — tema nativo "Dark Blue3" (base Abyss do VS Code + azul Blue3 `#29ABE2`).
- **Enxuta** — conjunto fechado de apps; App Store trancada; UI desbagunçada.
- **Atualizável** — core = imagem oficial; apps = tarball pinado. Atualizar = bump de versão + rebuild.

O espelho upstream em `/home/samir/x/DRIVE` é só **referência de estudo e descartável** — o build
não depende dele.

## Estrutura

| Caminho | O quê |
|---|---|
| `docs/PLANO-DE-ACAO.md` | spec viva (arquitetura, decisões travadas, fases 0→5) |
| `themes/blue3/` | tema "Dark Blue3" (`defaults.php`, `core/css/server.css`, `core/img/`) |
| `config/blue3.config.php` | overlay de config (`theme=blue3`, loja trancada, `defaultapp=files`, pt_BR) |
| `config/apps.allowlist` | conjunto fechado: `required` (intocável) / `enable` / `disable` |
| `build/Dockerfile` | `FROM nextcloud:34-apache` + tarballs dos apps + overlay + hook |
| `build/compose.yml` | stack: app (NC + CODE embutido) + MariaDB + whiteboard |
| `build/provision.sh` | hook de 1º boot: allowlist + branding + trancar loja |
| `build/apps.versions` | pin dos apps (download/bundled/deferred) |
| `build/.env.example` | modelo de segredos (o `.env` real **não** é versionado) |

## Como subir (local)

A partir desta pasta:

```bash
cp build/.env.example build/.env        # preencha senhas + WHITEBOARD_JWT_SECRET
docker compose -f build/compose.yml --env-file build/.env up -d --build
```

Acesse `http://localhost:8080` (admin = `NEXTCLOUD_ADMIN_USER`/`_PASSWORD` do `.env`).
O 1º boot instala o NC e roda o `provision.sh`. Build manual da imagem: `docker build -f build/Dockerfile -t blue3-drive:34 .`

## Como atualizar um app

1. Confira a versão compatível com **NC34** (App Store `platform/34` ou `info.xml`).
2. Atualize a linha em `build/apps.versions` **e** o `fetch` correspondente no `build/Dockerfile`.
3. Bumpe `version.md` (`Z+1`) e rebuilde (`deploy.sh` ou `up -d --build`).

Atualizar o **core**: troque a tag da imagem base (`nextcloud:34-…`) — só dentro do mesmo major sem revisar.

## Versionamento e commits

`version.md` (`X.Y.Z`) é a versão do produto. Commits usam `versão - comentário`
(ex.: `0.1.1 - Atualiza calendar 6.5.0 → 6.5.1`). Regras de bump em [CLAUDE.md](CLAUDE.md).

## Git

Repo: `origin` → GitHub (`samirhvbr/BLUE3_DRIVE`). Fluxo: `add` → `commit` → `push` (HTTPS, sem scp).
Segredos (`.env`) nunca entram no git — ver `build/.gitignore` e `.gitattributes` (LF nos scripts).

---

**Responsável:** Samir Hanna Verza · **Empresa:** Blue3
