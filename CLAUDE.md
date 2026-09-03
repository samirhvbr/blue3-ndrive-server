# Blue3 Drive — Agent Guide

Este documento orienta agentes de IA (Claude Code, etc.) que trabalham no projeto **Blue3 Drive**:
uma **distribuição do Nextcloud** com a cara da Blue3 e enxuta, montada por **camadas** (sem patch
no core). Siga estas diretrizes para manter consistência, qualidade e segurança.

> **Fonte de verdade:** o código manda, e a **spec viva** é [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md)
> — arquitetura, decisões travadas e fases estão lá. Em divergência de versões de app, use
> [build/apps.versions](build/apps.versions). Segurança: [SECURITY_GUIDELINES.md](SECURITY_GUIDELINES.md).
>
> [AGENTS.md](AGENTS.md) é só um ponteiro para este arquivo.

---

## Comunicação

- **Idioma:** Português (pt-BR) para mensagens ao operador, comentários de código, descrições e textos de UI.
- **Commits:** formato obrigatório `versão - comentário` (ex.: `0.1.1 - Atualiza calendar para 6.5.1`).
  A versão vem do `version.md`; faça o bump **no mesmo commit** da mudança. Mensagem em português,
  descritiva o suficiente para pesquisa futura (o **porquê** + o **o quê**).
  - **Vários commits, uma só versão (OK):** uma entrega pode ser dividida em commits por **assunto**
    com a **mesma versão** (ex.: dois `0.1.7 - ...`). O bump do `version.md` vai em **um** deles
    (o primeiro) e os demais repetem a versão no título, sem novo bump. Dois commits com a mesma
    versão no `git log` são esperados, não erro.
- **Identificadores de código:** Inglês (app-ids, variáveis de shell, nomes de serviço do compose, chaves de config).
- **Strings de UI / marca:** Português. Nome "Blue3 Drive", slogan "Um local seguro para seus dados!".
- **Code review e explicações ao operador:** Português, tom técnico e direto.

---

## Versão pública (`version.md`)

A versão do produto vive em `version.md` na raiz, formato **X.Y.Z**:

- **X** — versão estável final (alteração manual).
- **Y** — mudança estrutural (ex.: subir o core NC de major, trocar a arquitetura do build,
  mudança grande no conjunto de apps). Alteração manual.
- **Z** — incremento automático. Bumpar `Z+1` quando:
  - subir/baixar a versão de um app em `build/apps.versions`;
  - mexer no tema (`themes/blue3/` — `defaults.php`, CSS, logos);
  - mexer na curadoria (`config/apps.allowlist`, `config/blue3.config.php`);
  - mexer no build (`build/Dockerfile`, `compose.yml`, `provision.sh`);
  - documentação relevante para uma nova instalação.

**Como bumpar:** editar `version.md` com o novo número e incluir no mesmo commit, usando-o no
título (`versão - comentário`). O `version.md` é versionado no git.

---

## Stack

- **Core:** Nextcloud **34** via imagem oficial **`nextcloud:34-apache`** (traz os 56 apps *shipped*).
- **Apps externos:** instalados por **tarball oficial pinado** (`build/apps.versions`) no Dockerfile.
- **Office:** Collabora **CODE embutido** (app `richdocumentscode`) — sem container externo.
- **Whiteboard:** serviço websocket separado (`ghcr.io/nextcloud-releases/whiteboard`).
- **Banco:** **MariaDB** (regra do projeto — ver abaixo).
- **Empacotamento:** **Docker Compose** (`build/compose.yml`): app + db + whiteboard.
- **Marca:** tema nativo **"Dark Blue3"** (`themes/blue3/`) — base Abyss (VS Code) + accent `#29ABE2`.

> **NÃO** é um projeto Laravel/PHP-app. Nada de composer/npm/artisan/migrations aqui — o "código"
> deste repo é tema + config + build. O core e os apps são upstream **consumidos**, nunca editados.

---

## Arquitetura: camadas, não patch (princípio central)

Detalhes em [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md) §2/§4. Resumo do que um agente precisa respeitar:

- **Referência + overlay.** O core e os apps ficam **puros** (imagem oficial + tarball pinado). Tudo que
  é Blue3 vive neste repo e é **sobreposto** no build. **Nunca** dar patch/merge no código upstream.
- **`/DRIVE` (`/home/samir/x/DRIVE`) é descartável.** É só espelho de estudo do upstream — o build **não**
  lê de lá. Não criar dependência do `/DRIVE` em nada deste repo.
- **Atualizar = bump de versão.** Subir um app é trocar um número em `build/apps.versions` (+ Dockerfile)
  e rebuildar. Subir o core é trocar a tag da imagem base.
- **Fork pontual (modelo híbrido).** Só se for **mesmo** necessário mudar o *comportamento* de um app
  (Vue/PHP), forka-se **aquele** app (remote `upstream` p/ pull oficial + `origin` p/ push rebrand).
  Isso é exceção — a regra é não tocar upstream.
- **Marca por mecanismo oficial.** Tema nativo `themes/blue3/` (`defaults.php` + CSS) + app Theming via
  `occ` no `provision.sh`. Sobrevive a atualizações.

---

## Banco de Dados

**MariaDB/MySQL sempre. NUNCA SQLite** (regra do projeto). O `dbtype` é definido na instalação
(compose/env), não hardcodado no overlay. Sem autorização prévia, não trocar de banco.

---

## Estrutura do repositório

```
docs/PLANO-DE-ACAO.md     spec viva (arquitetura, decisões, fases)
themes/blue3/             tema "Dark Blue3" (defaults.php, core/css/server.css, core/img/*)
config/
  blue3.config.php        overlay de config (theme=blue3, loja trancada, pt_BR)
  apps.allowlist          conjunto fechado: required (intocável) / enable / disable
build/
  Dockerfile              FROM nextcloud:34-apache + tarballs + overlay + hook
  compose.yml             app + MariaDB + whiteboard
  provision.sh            hook post-installation (allowlist + branding + trancar loja)
  apps.versions           pin dos apps (download) + bundled + deferred
  .env.example            modelo de segredos (NÃO commitar o .env real)
version.md  README.md  CLAUDE.md  AGENTS.md  SECURITY_GUIDELINES.md  deploy.sh
```

---

## Quando editar

### Tema / marca (`themes/blue3/`)
- Só **CSS/config**. Cores na paleta de §6.2 do plano. Não introduzir cores fora dos tokens travados.
- Logo branco no fundo escuro; favicon a partir de `INTRANET/.../logo/`.

### Curadoria (`config/`)
- `apps.allowlist`: **3 seções**. Nunca mover app de `[required]` (são `alwaysEnabled` — desligar quebra a
  instância). Para tirar ruído, vai em `[disable]`. Para adicionar produto, vai em `[enable]`.
- `blue3.config.php`: overlay — chaves de sistema (theme, loja, locale). Não duplicar o que o `provision.sh` faz por `occ`.

### Apps (`build/apps.versions` + Dockerfile)
- Versões **compatíveis com NC34** (conferir `max-version` no `info.xml`/App Store). Fonte: App Store API
  `platform/34` + `core/shipped.json`. **bundled** = só habilitar; **download** = pinar versão + URL e
  adicionar a linha `fetch` no Dockerfile.
- Bump de versão de app → bump de `version.md`.

### Build (`build/`)
- `Dockerfile` e `apps.versions` devem ficar **em sincronia** (mesmas versões/URLs).
- `provision.sh` é **best-effort** (erro de `occ` loga WARN, nunca derruba o boot). É **idempotente**.

### Enxugar UI (Fase 3)
- Só CSS/config. Se exigir mexer no Vue de um app → vira **fork pontual** daquele app.

---

## Build & Run (local / Fase 5)

A partir de `BLUE3/DRIVE`:
```bash
cp build/.env.example build/.env     # preencha senhas + WHITEBOARD_JWT_SECRET
docker compose -f build/compose.yml --env-file build/.env up -d --build
# http://localhost:8080  (admin = NEXTCLOUD_ADMIN_* do .env)
```
Atualização contínua: ver [deploy.sh](deploy.sh).

---

## Checklist (pré-commit)

- [ ] `version.md` bumpado e usado no título do commit (`versão - comentário`)?
- [ ] `bash -n build/provision.sh` OK (sintaxe)?
- [ ] `build/apps.versions` e `build/Dockerfile` em sincronia (mesmas versões/URLs)?
- [ ] Apps novos compatíveis com **NC34** (`max-version`)? `[required]` intocado?
- [ ] Se mexeu no tema: cores dentro dos tokens (§6.2); logo claro no fundo escuro?
- [ ] `docker compose -f build/compose.yml config` valida (quando houver Docker)?
- [ ] **Nenhum segredo** commitado (`.env`, JWT, senha admin)? `.env.example` atualizado?
- [ ] `docs/PLANO-DE-ACAO.md` atualizado se mudou arquitetura/decisão/fase?
- [ ] Arquivos de texto em **LF** (`.gitattributes` cuida; scripts rodam em container Linux)?
- [ ] Validação ao vivo pendente anotada (seletores CSS / chaves `occ theming:config` mudam por versão)?

---

## Documentação

- **Manter [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md) vivo:** toda decisão de arquitetura ou mudança
  de fase entra lá (é a spec). Marcar `[x]`/✅ o que foi concluído e registrar o porquê das decisões.
- Comentários breves e úteis nos arquivos (Dockerfile, provision.sh, config) — explicar o **porquê**.
- Não copiar doc externa do Nextcloud para comentários — linkar para `docs.nextcloud.com`.

---

## Segurança

Prioridade máxima. Diretrizes completas em [SECURITY_GUIDELINES.md](SECURITY_GUIDELINES.md). Mínimos:
- **Nunca** commitar `.env`/segredos (JWT do whiteboard, senha do admin/DB). `.env.example` é a fonte das chaves.
- **Loja trancada** (`appstoreenabled=false`) + sem update pela web — usuário não instala app aleatório.
- Manter **brute-force protection** e **2FA** (apps habilitados na allowlist).
- Core e apps **pinados e atualizados** (CVE em NC/app força bump + rebuild).
- `MariaDB` sempre; `trusted_domains` restrito; HTTPS na borda (proxy/SSL) em produção.

---

## Notas Finais

- **Segurança > Produtividade > Performance > Facilidade.**
- **Não tocar o upstream.** Marca e enxugamento por camada — core puro e atualizável.
- **Manutenibilidade:** um número pinado e documentado > um hack que "funciona".
- **Em dúvida?** Consulte o `PLANO-DE-ACAO.md` antes de criar um padrão novo.

---

## PS — Commits: a skill COMMITTER cuida disso

**Existe `.committer.yml` na raiz deste repositório** — é o opt-in da skill
**COMMITTER**, que roda em ciclo (cron, via `~/x/GIT/run.sh`). Enquanto esse arquivo
existir com `enabled: true`, **commitar e pushar não é trabalho seu**.

**O que muda para você:**

- **Não commite nem pushe por padrão.** Conclua a entrega bumpando o `version.md`
  **com a entrada de changelog** e deixe a árvore pronta. É dali que a mensagem do
  commit sai — o changelog virou o artefato de handoff entre você e a skill.
- A skill monta `X.Y.Z - descrição`, commita e pusha a branch atual sozinha. Ela
  **nunca bumpa versão** (isso continua sendo julgamento seu) e nunca inventa
  mensagem: sem entrada de changelog ela cai num fallback Sonnet, e sem conseguir
  descrever com honestidade ela aborta e espera.

**Você ainda commita quando:**

- o Samir pedir explicitamente;
- a tarefa exigir o SHA na hora (deploy, abrir PR, referência cruzada);
- o `.committer.yml` sumir ou estiver `enabled: false` — aí vale o fluxo antigo,
  você bumpa, commita e pusha.

**Por que isso existe:** tirar de um modelo caro (Opus/Fable) o trabalho mecânico de
empacotar commit, que um Sonnet — ou, na maioria das vezes, nenhum modelo — resolve.
Economiza token e devolve tempo de desenvolvimento.

---

<!-- RELEASES-RULE:repodocs -->

## Releases — the `version.md` on GitHub is what the Releases show

> Marked echo. The single source is **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/versioning.md)**
> — change it there, not here. This block is regenerated.

**The `version.md` of the default branch, on GitHub, is what the GitHub Releases
must show.** The local checkout does not enter the calculation: it can be behind,
ahead or mid-work, and none of that is published — GitHub cannot tag a commit it
does not have.

**The bump and the Release are one act.** A commit that bumps `version.md` is not
finished until that version has a tag, a published Release, and the **`Latest`
badge on it** — the same push, not "later". A badge sitting on an older release
tells whoever looks that the project is at a version it is not.

- `.github/workflows/release.yml` does it on any push that touches `version.md`.
- `./tools/release.sh` does it by hand. It is **idempotent and self-healing**:
  it publishes whatever is missing and moves a drifted badge back. Running it is
  always safe, so it is both the check and the fix.

A PR publishes nothing while it is a PR. The moment it merges, the push moves
`version.md` on the default branch and the Release becomes that version.

Tag and Release title are the **bare version — no `v` prefix**.

## Language — English (US), everywhere in the repository

**Everything that lives in this repository, or in GitHub's interface around it,
is written in English (US)**: documents, **commit messages**, pull request titles
and bodies, issues, code comments, changelog entries, release notes.

Commit format: `X.Y.Z - short description in English`. The version comes from
`version.md` and is bumped in the same commit. Conventional Commits prefixes
(`feat:`, `fix:`, `chore:`) and vague one-word messages are forbidden.

**Exactly one carve-out:** end-user-facing strings — UI text, transactional
email, product copy. That is product i18n for a Brazilian audience, not
repository content.

History is not rewritten: Portuguese messages already in the log stay as they
are.

<!-- /RELEASES-RULE -->
