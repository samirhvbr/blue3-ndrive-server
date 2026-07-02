# Blue3 Drive

> A **Nextcloud 34** distribution with the **Blue3** look, lean and curated.
> Internal documentation — versioning is mandatory; publishing is optional.
> Always commit with a good description in the `version - comment` format.

**See also:** [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md) (living spec — architecture, decisions, phases) ·
[CLAUDE.md](CLAUDE.md) (code and agent conventions) ·
[SECURITY_GUIDELINES.md](SECURITY_GUIDELINES.md) (security — always review).

## What it is

A **Blue3 layer on top of Nextcloud**, assembled via **overlay** (no core patching):

- **Brand** — native "Dark Blue3" theme (VS Code's Abyss base + Blue3 blue `#29ABE2`).
- **Lean** — a closed set of apps; App Store locked; decluttered UI.
- **Upgradable** — core = official image; apps = pinned tarball. Upgrade = version bump + rebuild.

The upstream mirror at `/home/samir/x/DRIVE` is only a **disposable study reference** — the build
does not depend on it.

## Structure

| Path | What |
|---|---|
| `docs/PLANO-DE-ACAO.md` | living spec (architecture, locked decisions, phases 0→5) |
| `themes/blue3/` | "Dark Blue3" theme (`defaults.php`, `core/css/server.css`, `core/img/`) |
| `config/blue3.config.php` | config overlay (`theme=blue3`, locked store, `defaultapp=files`, pt_BR) |
| `config/apps.allowlist` | closed set: `required` (untouchable) / `enable` / `disable` |
| `build/Dockerfile` | `FROM nextcloud:34-apache` + app tarballs + overlay + hook |
| `build/compose.yml` | stack: app (NC + embedded CODE) + MariaDB + whiteboard |
| `build/provision.sh` | first-boot hook: allowlist + branding + lock the store |
| `build/apps.versions` | app pins (download/bundled/deferred) |
| `build/.env.example` | secrets template (the real `.env` is **not** versioned) |

## How to bring it up (local)

From this folder:

```bash
cp build/.env.example build/.env        # fill in passwords + WHITEBOARD_JWT_SECRET
docker compose -f build/compose.yml --env-file build/.env up -d --build
```

Access `http://localhost:8080` (admin = `NEXTCLOUD_ADMIN_USER`/`_PASSWORD` from `.env`).
The first boot installs NC and runs `provision.sh`. Manual image build: `docker build -f build/Dockerfile -t blue3-drive:34 .`

## How to update an app

1. Check the version compatible with **NC34** (App Store `platform/34` or `info.xml`).
2. Update the line in `build/apps.versions` **and** the corresponding `fetch` in the `build/Dockerfile`.
3. Bump `version.md` (`Z+1`) and rebuild (`deploy.sh` or `up -d --build`).

Updating the **core**: swap the base image tag (`nextcloud:34-…`) — only within the same major without review.

## Versioning and commits

`version.md` (`X.Y.Z`) is the product version. Commits use `version - comment`
(e.g., `0.1.1 - Atualiza calendar 6.5.0 → 6.5.1`). Bump rules in [CLAUDE.md](CLAUDE.md).

## Git

Repo: `origin` → GitHub (`samirhvbr/BLUE3_DRIVE`). Flow: `add` → `commit` → `push` (HTTPS, no scp).
Secrets (`.env`) never enter git — see `build/.gitignore` and `.gitattributes` (LF in scripts).

---

**Maintainer:** Samir Hanna Verza · **Company:** Blue3
