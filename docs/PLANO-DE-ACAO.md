# Blue3 Drive — Plano de Ação

> **Status:** planejamento (nada implementado ainda)
> **Data:** 2026-06-20
> **Base:** Nextcloud **v34** (linha estável) — o espelho hoje está em v35.0.0 *dev*
> **Marca:** azul Blue3 `#29ABE2` (primário) · `#0071BC` (escuro)

---

## 1. Objetivo

Montar a **Blue3 Drive**: uma distribuição do Nextcloud com a **cara visual da Blue3** e
**enxuta** — só com os módulos que usamos, sem a "bagunça" de apps que conflitam entre si.

Dois problemas a resolver:

1. **Marca** — logo, nome, cores e identidade Blue3 em todo o produto.
2. **Bagunça** — Nextcloud traz/permite dezenas de apps; um app aleatório instalado "dá zuada".
   Queremos um conjunto **fechado e controlado** de apps, com a loja **trancada**.

---

## 2. Arquitetura de pastas (duas raízes)

```
/home/samir/x/DRIVE/         →  Base de conhecimento TEMPORÁRIA (espelho upstream).
                                 ~50 repos git p/ estudo/merge único. DESCARTÁVEL — some quando
                                 terminarmos. NUNCA é fonte de build. Ver §3 (categorias A/B).

/home/samir/x/BLUE3/DRIVE/   →  Camada BLUE3 — único repo que sobrevive.
                                 Só o que é nosso: tema, config, build, docs.
```

**Princípio:** o build **não lê do `/DRIVE`**. Ele parte da **imagem oficial do core**
(`FROM nextcloud:34-apache` — variante Apache p/ MVP; fpm+nginx é upgrade de produção)
e **baixa os apps externos por tarball** na versão fixada (§4/§9).
Tudo que é Blue3 vive em `/BLUE3/DRIVE` e é **sobreposto** por cima. Assim a atualização do
Nextcloud continua trivial (bump de versão) — nunca damos merge de patch nosso no upstream,
e o `/DRIVE` pode ser apagado sem afetar o build.

```
   IMAGEM OFICIAL nextcloud:34-apache       /BLUE3/DRIVE (camada Blue3, único repo)
   ┌───────────────────────────┐           ┌──────────────────────────┐
   │ core + apps bundled        │           │ themes/blue3/  (marca)    │
   │ (files, dav, theming…)     │           │ config/        (curadoria)│
   └───────────────────────────┘  + overlay │ build/         (empacotar)│
   TARBALLS OFICIAIS (pin NC34)   ─────────► │ docs/                     │
   ┌───────────────────────────┐           └──────────────────────────┘
   │ calendar, mail, deck,      │                        │
   │ richdocuments, whiteboard… │                        │
   └───────────────────────────┘                        │
                          │                              │
                          └──────────  BUILD  ──────────┘
                                       │
                               Imagem "Blue3 Drive"
                       (core v34 + apps curados + tema + config)
```

---

## 3. O que é a pasta /DRIVE (inventário)

Não é um projeto único — são **~50 repositórios git independentes** do ecossistema Nextcloud
(≈19 GB).

| Categoria | Itens | Observação |
|---|---|---|
| **Core** | `SERVER` | Hoje em `master` = **v35.0.0 dev**. Fixar em **v34.0.0** (estável). |
| **Apps externos** | `CALENDAR`, `MAIL`, `tasks`, `notes`, `deck`, `richdocuments`, `office`, `text`, `whiteboard`, `news`, `BOOKMARKS`, `serverinfo`, `notify_push`, `twofactor_*`, `groupquota`, `files_filter`, `files_zip`, `integration_openai/gptzero`, `user_external/retention`, `AVIRUS`, `BRUTEFORCE`… | A fonte da "bagunça". Vamos curar. |
| **Clientes** | `ANDROID`, `IOS`, `IOS_KIT`, `DESKTOP`, `notes-android`, `apple-clients`, `ALLinONE` | `ALLinONE` = Docker AIO (útil no empacotamento). |
| **Site/infra** | `nextcloud.com` (site), `appstore` (a loja), `nextcloud-theme`, `RPI`, `docs` | ⚠️ `nextcloud-theme` é o tema **WordPress do site**, **não** é o tema do Drive. |

> ⚠️ **Importante:** os apps no espelho estão em **versões dev alinhadas ao NC 35**.
> Ao fixar o core na v34, cada app precisa ir para a **tag compatível com NC 34**
> (conferir `max-version` do `nextcloud` em cada `appinfo/info.xml`).

### 3.1. Dois papéis — e o `/DRIVE` é descartável

Cada repo do espelho serve a **um** de dois propósitos. Nenhum deles exige manter o `/DRIVE`:

| Papel | Quais | Destino | Entra no `BLUE3/DRIVE`? |
|---|---|---|---|
| **A) Insumo do produto** | apps externos curados (§7): `calendar`, `mail`, `tasks`, `notes`, `deck`, `richdocuments`/`text`, `whiteboard`, `contacts`… | build baixa **tarball oficial** na versão fixada | não — só o número da versão fica no `build/` |
| **B) Base de conhecimento / merge único** | `SERVER` (estudo do tema/`OC_Defaults`), `IOS`, `ANDROID`, `DESKTOP`, `nextcloud.com`, `appstore`, `docs`, `RPI`… | estudar/extrair **uma vez**, depois **descartar** | não — nunca foram daqui |

Notas:
- O **core (`SERVER`) é categoria B**: o build usa a **imagem oficial** `nextcloud:34-apache` (já traz core
  + apps bundled). O fonte do `SERVER` serve só pra estudar o mecanismo de tema → descartável.
- **Clientes móveis (`IOS`/`ANDROID`) ficam de fora.** O `BLUE3/MOBILE` segue **separado** — *não* faremos
  merge dos clientes Nextcloud nele (custo alto, pouco ganho). Decisão fechada.
- Quando todo insumo A estiver fixado no `build/` e os repos B estudados/extraídos, **`/DRIVE` pode ser apagado**.

---

## 4. Princípio central: camadas, não patch no core

O Nextcloud tem mecanismos **oficiais** de personalização que **não exigem editar o código-fonte**
— é por eles que vamos. Confirmados no core (`/DRIVE/SERVER`):

1. **Tema nativo `themes/blue3/`** (ver `SERVER/themes/README`)
   - Cria-se uma pasta espelhando a estrutura do core; ativa-se com `'theme' => 'blue3'` no `config.php`.
   - Sobrescreve **logo, nome, cores, fundo de login, e-mails, CSS e até templates**.
   - O CSS é carregado **por cima** do padrão → basta sobrepor variáveis (`--color-primary`…).
   - `defaults.php` sobrescreve as strings de marca (`getName`, `getEntity`, `getBaseUrl`,
     `getSlogan`, `getLogo`…), via `OC_Defaults`.
   - **Sobrevive a atualizações.** O `SERVER/themes/example` é o esqueleto de partida.

2. **App de Theming** (`SERVER/apps/theming`) — branding pela UI de admin
   (cor, logo, nome, fundo, CSS custom), persistido no banco. Complementa o tema nativo.

3. **Curadoria + trancar a loja** — a dor de "app que dá zuada" se resolve em **configuração**:
   habilitar só a allowlist e desligar a app store (`appstoreenabled => false`).

> **Por que não um fork de código real do core?** O `SERVER` é um monorepo grande que se move
> rápido (já em v35 *dev*). Forkar e remendar = herdar merge de upstream para sempre. O modelo em
> camadas entrega marca + enxugamento mantendo o core **puro e atualizável**.

---

## 5. Decisões travadas

| Tema | Decisão |
|---|---|
| **Modelo** | **Híbrido** — core e apps sempre upstream fixado; forka-se **só um app específico** se/quando precisar mudar o comportamento dele. |
| **Origem do código** | **Referência + overlay** — **nunca mover** nem **copiar em massa** de `/DRIVE`. Core = **imagem oficial** `nextcloud:34-apache`; apps externos = **tarball oficial** na versão fixada (baixado no build). `/DRIVE` é só estudo e **descartável** (§3.1). Copiar só em 2 casos pontuais: (a) *seed* do tema a partir de `SERVER/themes/example`; (b) fork de **um** app específico. |
| **Remotes (git)** | **Sem fork global.** `BLUE3/DRIVE` tem **`origin` próprio** (push, é todo nosso) e **nenhum upstream** — não há o que puxar do NC na nossa camada. Core/apps **não têm remote nosso** (vêm por imagem/tarball). O par **`upstream` (pull oficial) + `origin` (push rebrand)** existe **só** dentro de um app que a gente forkar pontualmente. |
| **Apps** | Files (base) + **Produtividade** + **Office** + **Deck** + **Whiteboard**. **Sem Talk.** |
| **Visual** | **Branding + enxugar a UI** (não é só logo; também simplificar dashboard/menus). |
| **Tema** | **Dark Blue3** — escuro por padrão, base **Abyss** (VS Code) + accent azul Blue3 `#29ABE2`. Paleta travada em §6.2. |

---

## 6. Identidade visual — "Dark Blue3" (tokens travados)

**Tema:** **Dark Blue3** — tema **escuro** inspirado no **Abyss** do VS Code (azul-marinho profundo),
com o **azul Blue3 como accent**. É o visual padrão do produto. (Decisão 2026-06-20.)

### 6.1. Strings de marca (`defaults.php`)

| Token | Valor | Onde |
|---|---|---|
| Nome do produto | **Blue3 Drive** | `getName` / `getTitle` |
| Entidade | **Blue3** | `getEntity` (rodapé/e-mails) |
| Slogan | **Um local seguro para seus dados!** | `getSlogan` |
| URL base | **https://drive.blue3.com.br** | `getBaseUrl` |

### 6.2. Paleta Dark Blue3 (base Abyss + accent Blue3)

Base escura extraída do tema **Abyss** (`theme-abyss/abyss-color-theme.json`); accent da marca Blue3.

| Papel | Hex | Origem | Var. NC (alvo) |
|---|---|---|---|
| Fundo principal | `#000c18` | Abyss `editor.background` | `--color-main-background` |
| Fundo sidebar / app menu | `#060621` | Abyss `sideBar` | `--color-background-dark` |
| Barras (header / status) | `#10192c` | Abyss `titleBar`/`statusBar` | header/footer |
| Superfícies (inputs, cards) | `#181f2f` | Abyss `input`/`dropdown` | `--color-background-hover` |
| Popovers / widgets | `#262641` | Abyss `editorWidget` | `--color-main-background-blur` |
| **Primário (marca/accent)** | **`#29ABE2`** | **Blue3** | `--color-primary`, links, botões |
| Primário hover / escuro | `#0071BC` | Blue3 | hover, gradientes |
| Accent secundário (badges/progress) | `#0063a5` | Abyss `badge` | destaques, notificações |
| Texto principal | `#d8e2f0` | legibilidade s/ navy | `--color-main-text` |
| Texto secundário | `#6688cc` | Abyss `editor.foreground` | `--color-text-maxcontrast` |
| Bordas / foco | `#596f99` | Abyss `focusBorder` | `--color-border`, foco |
| Divisores / linhas | `#406385` | Abyss `editorLineNumber` | `--color-border-dark` |

### 6.3. Logo e favicon

**Fonte:** `BLUE3/INTRANET/public/assets/images/logo/` (confirmado pelo Samir).
Disponíveis (PNG/ICO): `logo-blue3.png`, `logo-icon.png`, `logo.png`, `logo_dark.png`, `favicon.ico`, `favicon.png`.
- Fundo escuro → usar a **variante clara/branca** (conferir `logo_dark.png` x `MOBILE/docs/IMGS/blue3white.png`).
- **SVG ainda pendente** (só há raster): na Fase 1 decidir entre vetorizar (trace) ou usar PNG no app Theming.

---

## 7. Conjunto curado de apps

Base sempre presente; demais blocos conforme decisão.

Origem resolvida na Fase 0 (ver [`build/apps.versions`](../build/apps.versions)):
**bundled** = vem na imagem `nextcloud:34-apache`, só habilitar · **download** = tarball oficial pinado.

| Bloco | app-id | Origem | Notas |
|---|---|---|---|
| **Base** | `files`, `files_sharing`, `files_trashbin`, `files_versions`, `dav` | **bundled** | núcleo do Drive |
| **Produtividade** | `calendar` 6.5.0 · `mail` 5.10.1 · `notes` 6.0.0 | **download** | — |
| | `contacts` 8.7.1 | **download** | não está no espelho; tarball oficial |
| | ~~`tasks`~~ | **fora do MVP** | sem release NC34; reincluir quando upstream tagar (§11) |
| **Office** | `richdocuments` 11.0.0 · `richdocumentscode` 26.4.104 · (+ `text`) | richdocuments/code=**download** · text=**bundled** | Collabora = **CODE embutido** (richdocumentscode); sem container externo (§8) |
| **Colaboração** | `deck` 1.18.1 · `whiteboard` 1.5.9 | **download** | Whiteboard **precisa serviço websocket** (ver §8) |
| **Infra** | `serverinfo` · `twofactor_totp` | **bundled** | já vêm na imagem |
| | ~~`notify_push`~~ | **fora do MVP** | tempo real (push server); polling no MVP (§11) |
| **Fora** | `spreed` (Talk), `news`, `bookmarks`, `integration_*`, etc. | — | desligados + loja trancada |

---

## 8. Notas de empacotamento (gotchas)

- **Collabora (`richdocuments`)** é só o *conector*. Decisão = **CODE embutido**: o app
  **`richdocumentscode`** roda o servidor CODE dentro do próprio container do NC → **sem** container
  Collabora externo. (x86_64; em ARM usar `richdocumentscode_arm64`. Tarball grande, ~centenas de MB.)
- **Whiteboard** tem `websocket_server/` → exige um **serviço Node separado** (container próprio). → serviço extra.
- **notify_push** ("Client Push"): **fora do MVP** → sem serviço de push; clientes em polling.
- **Banco:** **MariaDB/MySQL** sempre. **Nunca SQLite** (regra do projeto).
- Resultado (MVP): **Docker Compose** com **app (NC + CODE embutido) + MariaDB + whiteboard-ws**.
  O `ALLinONE` (AIO) serve de base/referência.

---

## 9. Estrutura do /BLUE3/DRIVE (a montar)

```
BLUE3/DRIVE/                      (estado atual — Fases 0→4 prontas)
├── docs/
│   └── PLANO-DE-ACAO.md          ← este documento
├── themes/blue3/                 ✅ CAMADA DE MARCA "Dark Blue3"
│   ├── defaults.php              nome/entidade/URL/slogan + cor #29ABE2 + fundo #000c18
│   └── core/
│       ├── img/                  logo.png (branco), logo-icon.png, favicon.png/.ico
│       └── css/server.css        paleta Dark Blue3 (--color-*) + declutter da UI
├── config/
│   ├── blue3.config.php          ✅ theme=blue3, appstoreenabled=false, defaultapp=files, pt_BR
│   └── apps.allowlist            ✅ required (intocável) / enable / disable
├── build/
│   ├── Dockerfile                ✅ FROM nextcloud:34-apache + tarballs + overlay + hook
│   ├── compose.yml               ✅ app (NC+CODE embutido) + MariaDB + whiteboard
│   ├── provision.sh              ✅ hook post-installation: allowlist + branding + trancar loja
│   ├── apps.versions             ✅ pin dos apps (download) + bundled + deferred
│   ├── .env.example              modelo de segredos (DB, admin, JWT whiteboard)
│   └── .gitignore                ignora o .env real
└── README.md
```

> **Nada de upstream vive aqui.** O core vem da imagem base; os apps vêm de tarball no `Dockerfile`
> (versões em `apps.versions`). Atualizar = editar um número em `apps.versions`. O `/DRIVE` não é
> referenciado pelo build — pode ser apagado (§3.1).

---

## 10. Fases do plano

### Fase 0 — Fundação
- ~~Inicializar repo git em `/BLUE3/DRIVE`~~ ✅ feito (já existe `.git`).
- ~~Base do build = imagem oficial **`nextcloud:34-apache`**~~ ✅ definido (traz os 56 apps *shipped*).
- ~~Levantar versão/URL do tarball oficial de cada app curado compatível com NC34~~ ✅ **feito** → [`build/apps.versions`](../build/apps.versions). Fontes: App Store API (`platform/34`) + `SERVER@v34.0.0:core/shipped.json`.
  - **8 apps por download:** calendar 6.5.0 · mail 5.10.1 · notes 6.0.0 · contacts 8.7.1 · richdocuments 11.0.0 · richdocumentscode 26.4.104 · deck 1.18.1 · whiteboard 1.5.9. *(notify_push movido p/ deferred — §11.)*
  - **Bundled (vêm na imagem, só habilitar):** text, serverinfo, **twofactor_totp**, twofactor_backupcodes, files, dav, theming, viewer…
  - **`tasks` fora do MVP:** sem release que declare NC34 (última tag v0.17.1 = NC31-33). Reincluir quando upstream tagar. Ver §11.
- Finalizar tokens de marca: **logo/favicon em SVG**, slogan, URL base. ← *pendente (precisa de você)*

### Fase 1 — Marca (tema `themes/blue3/`)  ← primeiro resultado visível
- ~~Semear o tema a partir de `SERVER/themes/example`~~ ✅ estrutura criada em `themes/blue3/`.
- ~~Preencher `defaults.php`~~ ✅ nome/entidade/URL/slogan + cor `#29ABE2` + fundo navy `#000c18`.
- ~~Colocar logo/favicon em `core/img/`~~ ✅ `logo.png` (branco, p/ fundo escuro = `MOBILE/.../blue3white.png`), `logo-icon.png`, `favicon.png/.ico`.
- ~~Sobrescrever variáveis CSS em `core/css/server.css`~~ ✅ paleta Dark Blue3 (custom properties `--color-*` + header/login/botões).
- **Pendente:** ativar `'theme' => 'blue3'` no `config.php` (vai no `config/blue3.config.php`, Fase 2) e **validar num NC34 rodando** (as `--color-*` precisam vencer as do app Theming — reforçar via `occ theming:config` se preciso). Fase 5.
- **Pendente (opcional):** logo/favicon em **SVG** (hoje PNG) e **fundo de login** dedicado.

### Fase 2 — Curadoria ("desbagunçar")
- ~~Definir `apps.allowlist`~~ ✅ [`config/apps.allowlist`](../config/apps.allowlist) — 3 seções: **required** (alwaysEnabled, nunca tocar) · **enable** (nossos) · **disable** (bagunça bundled). Regra segura: liga o `enable`, desliga só o `disable` explícito (nunca "desliga tudo fora da lista").
- ~~`config.php`: tema + loja + defaultapp~~ ✅ [`config/blue3.config.php`](../config/blue3.config.php): `theme=blue3`, `appstoreenabled=false`, `defaultapp=files`, `updatechecker=false`, `upgrade.disable-web=true`, locale pt_BR/BR.
- Bloqueio de instalação/update pelo usuário: garantido via `appstoreenabled=false` + `upgrade.disable-web=true` (sem store, sem upgrade web).
- **Aplicação:** o `provision.sh` (Fase 4) consome a allowlist e roda os `occ app:enable/disable`. ⏳ pendente: app `office` na allowlist depende da decisão Collabora (§11).

### Fase 3 — Enxugar a UI
- ~~Top bar/menu~~ ✅ já curado pela Fase 2: só os apps do `[enable]` aparecem (os do `[disable]` somem de menu/dashboard/settings). Reforço por CSS no `server.css` (esconder menu de contatos recentes, atalho da store).
- **Dashboard:** decisão → **manter habilitado, mas Files é o landing** (`defaultapp=files`). Com weather/recommendations já desligados, o dashboard fica "mínimo". Flippável: pra tirar de vez, mover `dashboard` para `[disable]` na allowlist.
- ~~Settings: ocultar seções~~ ✅ bloco "declutter" no `server.css`: esconde "Apps de celular e desktop" (cliente Blue3 é separado), faixa "recomendados", rodapé de clients no login.
- **Ordem de apps:** o NC34 guarda a ordem **por usuário** (sem default global limpo via `occ`). Fica na ordem natural do `[enable]`; ajuste fino é per-user. (Não forçamos via fork — regra da Fase 3.)
- ⚠️ **Validar os seletores CSS num NC34 rodando (Fase 5)** — UI do NC muda entre versões.
- **Regra:** só CSS/config aqui. Se algo exigir mexer no Vue → vira **fork daquele app** (modelo híbrido).
- `user_status` (presença) mantido — leve; flippável na allowlist se quiser tirar os indicadores.

### Fase 4 — Empacotamento  ✅ (arquivos montados)
- ~~`build/Dockerfile`~~ ✅ `FROM nextcloud:34-apache` (variante Apache p/ MVP — 1 container web; fpm+nginx fica como upgrade de produção) + baixa os 8 tarballs de `apps.versions` (inclui `richdocumentscode`) + copia `themes/blue3` + `config/blue3.config.php` + instala o hook `provision.sh`.
- ~~`build/compose.yml`~~ ✅ **app (NC + CODE embutido)** + **MariaDB 11.4** + **whiteboard** (`ghcr.io/nextcloud-releases/whiteboard`). Sem Collabora externo, sem notify_push. Segredos em `build/.env` (`.env.example` versionado; `.env` no `.gitignore`).
- ~~`build/provision.sh`~~ ✅ hook **post-installation**: parseia `apps.allowlist` (enable/disable, nunca toca required), reforça branding (`occ theming:config`), tranca loja, libera `allow_local_remote_servers` (CODE local), faz wiring do whiteboard. Best-effort (erro de occ não derruba o boot). Parser e sintaxe validados.
- ✅ Build só com imagem + tarballs (sem tocar `/DRIVE`) → `/DRIVE` pode ser apagado.
- ⏳ **Falta rodar de fato** (precisa de Docker) — isso é a Fase 5.

### Fase 5 — Validação & docs
- Subir local, conferir: marca aplicada, set de apps correto, **loja trancada**.
- Atualizar `README.md` da Blue3 Drive.

---

## 11. Pendências / decisões em aberto

- [x] ~~**Collabora:**~~ ✅ **CODE embutido** → app `richdocumentscode` v26.4.104 (x86_64; ARM = `richdocumentscode_arm64`). Sem container Collabora externo. (`office` shipped ≠ CODE server; não tocado.)
- [x] ~~**notify_push** no MVP?~~ ✅ **Fora do MVP** (clientes em polling). Em `[deferred]` no `apps.versions`/`apps.allowlist`.
- [x] ~~Confirmar cor / tema~~ ✅ **Dark Blue3** (base Abyss + accent `#29ABE2`); paleta em §6.2.
- [x] ~~Definir URL base e slogan~~ ✅ URL `https://drive.blue3.com.br` · slogan "Um local seguro para seus dados!".
- [ ] Converter logo/favicon Blue3 para **SVG** (só há PNG) — ou usar PNG via Theming. Decidir na Fase 1.
- [x] ~~Levantar versão/URL do tarball (compatível v34) de cada app → `build/apps.versions`~~ ✅ (Fase 0).
- [x] ~~**`tasks`:** decidido **fora do MVP**~~ (sem release NC34). Reincluir quando upstream tagar uma versão que declare NC34.

---

## 12. Referências (caminhos úteis)

| O quê | Caminho |
|---|---|
| Core Nextcloud | `/home/samir/x/DRIVE/SERVER` |
| Mecanismo de tema nativo | `/home/samir/x/DRIVE/SERVER/themes/README` + `themes/example` |
| App de Theming | `/home/samir/x/DRIVE/SERVER/apps/theming` |
| Defaults de marca | `/home/samir/x/DRIVE/SERVER/lib/private/legacy/OC_Defaults.php` |
| Config de exemplo | `/home/samir/x/DRIVE/SERVER/config/config.sample.php` (chave `theme`, `appstoreenabled`) |
| Docker AIO | `/home/samir/x/DRIVE/ALLinONE` |
| Logos Blue3 | `/home/samir/x/BLUE3/INTRANET/public/assets/images/logo/` |
