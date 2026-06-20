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
/home/samir/x/DRIVE/         →  Nextcloud ORIGINAL (upstream). NUNCA editar.
                                 ~50 repos git (core + apps + clientes). Referência/base.

/home/samir/x/BLUE3/DRIVE/   →  Camada BLUE3 (o nosso "fork" de verdade).
                                 Só o que é nosso: tema, config, build, docs.
```

**Princípio:** o core e os apps ficam puros em `/DRIVE` (cada repo fixado numa tag estável).
Tudo que é Blue3 vive em `/BLUE3/DRIVE` e é **sobreposto** no build. Assim a atualização do
Nextcloud continua trivial — nunca damos merge de patch nosso dentro do código upstream.

```
        /DRIVE (upstream puro, pin v34)              /BLUE3/DRIVE (camada Blue3)
        ┌───────────────────────────┐               ┌──────────────────────────┐
        │ SERVER (core)             │               │ themes/blue3/  (marca)    │
        │ calendar, mail, deck, ... │   + overlay   │ config/        (curadoria)│
        │ richdocuments, whiteboard │  ───────────► │ build/         (empacotar)│
        └───────────────────────────┘               │ docs/                     │
                                                     └──────────────────────────┘
                          │                                       │
                          └────────────  BUILD  ─────────────────┘
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
| **Apps** | Files (base) + **Produtividade** + **Office** + **Deck** + **Whiteboard**. **Sem Talk.** |
| **Visual** | **Branding + enxugar a UI** (não é só logo; também simplificar dashboard/menus). |

---

## 6. Identidade visual Blue3 (tokens)

Extraídos do logo `BLUE3/INTRANET/public/assets/images/logo/logo-blue3.png`:

| Token | Valor | Uso |
|---|---|---|
| **Azul primário** | `#29ABE2` | `--color-primary`, header, links, botões |
| **Azul escuro** | `#0071BC` | hover, gradientes, acentos |
| Nome do produto | **Blue3 Drive** | `getName` / `getTitle` |
| Entidade | **Blue3** | `getEntity` (rodapé/e-mails) |
| Logo | `logo-blue3.png` / `logo-icon.png` | converter para **SVG** para o tema |
| Favicon | `favicon.ico` / `favicon.png` | `core/img/favicon.*` |

**Assets de origem:** `BLUE3/INTRANET/public/assets/images/logo/` e `BLUE3/MOBILE/docs/IMGS/`.

> A converter para SVG (o tema do NC prefere SVG para logo/favicon). Definir também a URL base
> (`getBaseUrl`) e o slogan.

---

## 7. Conjunto curado de apps

Base sempre presente; demais blocos conforme decisão.

| Bloco | app-id | Origem | Notas |
|---|---|---|---|
| **Base** | `files`, `files_sharing`, `files_trashbin`, `files_versions`, `dav` | core (`SERVER/apps`) | núcleo do Drive |
| **Produtividade** | `calendar`, `mail`, `tasks`, `notes` | `/DRIVE` | PHP puro |
| | `contacts` | **clonar** (`nextcloud/contacts`) | **não está no espelho** |
| **Office** | `richdocuments` (+ `text`) | `/DRIVE` | **precisa servidor Collabora/CODE** (ver §8) |
| **Colaboração** | `deck`, `whiteboard` | `/DRIVE` | Whiteboard **precisa serviço websocket** (ver §8) |
| **Infra (sugestão)** | `notify_push`, `serverinfo`, `twofactor_totp` | `/DRIVE` | notify_push = real-time (binário Rust, opcional) |
| **Fora** | `spreed` (Talk), `news`, `bookmarks`, `integration_*`, etc. | — | desligados + loja trancada |

---

## 8. Notas de empacotamento (gotchas)

- **Collabora (`richdocuments`)** é só o *conector*. Precisa de um **servidor Collabora Online**:
  o app `office`/CODE embutido **ou** um container Collabora externo. Definir qual. → serviço extra.
- **Whiteboard** tem `websocket_server/` → exige um **serviço Node separado** (com `docker-compose`
  próprio no repo). → serviço extra.
- **notify_push** ("Client Push") precisa de **binário** (push server) para tempo real. Opcional no MVP.
- **Banco:** **MariaDB/MySQL** sempre. **Nunca SQLite** (regra do projeto).
- Resultado: a distribuição é **multi-serviço** → o empacotamento natural é **Docker Compose**
  (PHP-FPM + MariaDB + Collabora + whiteboard-ws [+ notify_push]). O `ALLinONE` (AIO) serve de base.

---

## 9. Estrutura do /BLUE3/DRIVE (a montar)

```
BLUE3/DRIVE/
├── docs/
│   └── PLANO-DE-ACAO.md          ← este documento
├── themes/blue3/                 CAMADA DE MARCA (a partir de SERVER/themes/example)
│   ├── defaults.php              nome "Blue3 Drive", entidade, URL, slogan, logo, cor
│   └── core/
│       ├── img/                  logo.svg, logo-icon.svg, favicon.*, fundo de login
│       └── css/server.css        --color-primary: #29ABE2; etc.
├── config/
│   ├── blue3.config.php          theme=blue3, appstoreenabled=false, defaultapp=files
│   └── apps.allowlist            lista fechada de app-ids habilitados
├── build/
│   ├── compose.yml               PHP-FPM + MariaDB + Collabora + whiteboard-ws
│   ├── Dockerfile                imagem do app (core v34 + apps curados + tema)
│   └── provision.sh              occ: ativa só a allowlist, aplica theming, tranca a loja
└── README.md
```

---

## 10. Fases do plano

### Fase 0 — Fundação
- Inicializar repo git em `/BLUE3/DRIVE`.
- Fixar `SERVER` em **v34.0.0** (sair do master/v35-dev).
- Fixar cada app escolhido na **tag compatível com NC 34** (conferir `info.xml`).
- **Clonar `contacts`** do upstream (não está no espelho).
- Finalizar tokens de marca: **logo/favicon em SVG**, slogan, URL base.

### Fase 1 — Marca (tema `themes/blue3/`)  ← primeiro resultado visível
- Copiar `SERVER/themes/example` → `BLUE3/DRIVE/themes/blue3`.
- Preencher `defaults.php` (nome, entidade, URL, slogan, logo, cor `#29ABE2`).
- Colocar logo/favicon/fundo de login em `core/img/`.
- Sobrescrever variáveis CSS em `core/css/server.css`.
- Ativar `'theme' => 'blue3'` e complementar pelo app Theming.

### Fase 2 — Curadoria ("desbagunçar")
- Definir `apps.allowlist` (§7); `occ app:disable` em tudo fora dela.
- `config.php`: `appstoreenabled => false`, `defaultapp => files`.
- Bloquear instalação/atualização de apps pelo usuário.

### Fase 3 — Enxugar a UI
- Dashboard: layout mínimo ou desligar o app `dashboard`.
- Top bar/menu: esconder ícones de apps que não usamos (CSS do tema + ordem de apps).
- Settings: ocultar seções desnecessárias.
- **Regra:** só CSS/config aqui. Se algo exigir mexer no Vue → vira **fork daquele app** (modelo híbrido).

### Fase 4 — Empacotamento
- `build/compose.yml`: PHP-FPM + **MariaDB** + **Collabora/CODE** + **whiteboard-ws** [+ notify_push].
- `provision.sh` aplica tema + allowlist + config no primeiro boot.

### Fase 5 — Validação & docs
- Subir local, conferir: marca aplicada, set de apps correto, **loja trancada**.
- Atualizar `README.md` da Blue3 Drive.

---

## 11. Pendências / decisões em aberto

- [ ] **Collabora:** CODE embutido (`office`) ou servidor Collabora externo?
- [ ] **notify_push** entra no MVP (tempo real) ou fica para depois?
- [ ] Confirmar **azul primário** `#29ABE2` como cor oficial (extraído do logo).
- [ ] Converter logo/favicon Blue3 para **SVG**.
- [ ] Definir **URL base** e **slogan** da Blue3 Drive.
- [ ] Confirmar tags exatas (v34) de cada app na Fase 0.

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
