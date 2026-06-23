# Blue3 Drive — Deploy em produção (VPS)

Guia para subir o Blue3 Drive num servidor real, com **HTTPS** (Caddy + Let's Encrypt),
**domínio próprio** e **Office (Collabora)**. O modelo é o mesmo do dev — muda só a
**borda**: um proxy reverso TLS na frente e domínios reais no `.env`.

> Branch: por ora o kit de produção vive na branch **`deploy-prod`**. Tudo aqui é
> **aditivo e opcional** (não muda o comportamento dev/local), então quando validar
> dá pra mergear no `master` sem susto.

## O que sobe

```
caddy       proxy reverso + HTTPS automático (portas 80/443) — a borda
app         Nextcloud 34 (imagem blue3-drive) — atrás do Caddy
db          MariaDB
collabora   Collabora/CODE (Office) — em office.<domínio>
whiteboard  servidor do quadro branco — em whiteboard.<domínio>
```

## 1. Pré-requisitos

- VPS Linux com **Docker** + **Docker Compose v2.24+** (o overlay usa o tag `!reset`).
- **~4 GB RAM mín. (8 GB confortável)** — o Collabora é faminto.
- Portas **80 e 443** abertas (firewall/security group).
- Acesso ao repo (`git`/`gh`) e usuário no grupo `docker`.

## 2. DNS

Crie 3 registros **A** apontando para o IP do VPS (resolvendo **antes** de subir —
o Caddy só emite o certificado quando o domínio resolve):

| Host | Aponta para |
|---|---|
| `drive.blue3.com.br`      | IP do VPS |
| `office.blue3.com.br`     | IP do VPS |
| `whiteboard.blue3.com.br` | IP do VPS |

## 3. Subir

```bash
# clonar e ir pra branch do kit de produção
git clone git@github.com:samirhvbr/BLUE3_DRIVE.git
cd BLUE3_DRIVE
git checkout deploy-prod

# segredos + domínios
cp build/.env.example build/.env
# gere senhas fortes e o JWT do whiteboard:
#   openssl rand -hex 16   (MYSQL_PASSWORD, MYSQL_ROOT_PASSWORD, NEXTCLOUD_ADMIN_PASSWORD)
#   openssl rand -hex 32   (WHITEBOARD_JWT_SECRET)
# e DESCOMENTE/preencha a seção PRODUÇÃO do .env:
#   DEPLOY_COMPOSE_OVERLAY=build/compose.prod.yml
#   NEXTCLOUD_PUBLIC_HOST / COLLABORA_PUBLIC_HOST / WHITEBOARD_PUBLIC_HOST
#   ACME_EMAIL, COLLABORA_IMAGE (pinar versão)
nano build/.env

# deploy (o deploy.sh inclui o overlay de produção automaticamente via DEPLOY_COMPOSE_OVERLAY)
./deploy.sh
```

Equivalente manual (sem o deploy.sh):
```bash
docker compose -f build/compose.yml -f build/compose.prod.yml --env-file build/.env up -d --build
```

## 4. Primeiro acesso

- Acesse **`https://drive.blue3.com.br`** (admin = `NEXTCLOUD_ADMIN_*` do `.env`).
- O 1º boot instala o NC e roda o `provision.sh` (marca, idioma pt-BR, curadoria,
  e o wiring do Office: como `COLLABORA_PUBLIC_URL` está setado, ele **desliga o
  CODE embutido** e aponta o richdocuments p/ o Collabora externo).
- O Caddy pode levar alguns segundos para emitir os certificados no 1º acesso.

## 5. Office (Collabora)

Em produção o Collabora roda em `office.<domínio>` atrás do Caddy (HTTPS real, sem o
problema de endereçamento local do ambiente de dev). ⚠️ Se o `.docx` travar em
"Carregando", é o bug conhecido do **NC 34.0.0** (richdocuments↔core) — um `./deploy.sh`
depois que sair o **34.0.1** (a tag `nextcloud:34-apache` é móvel) deve resolver.

## 6. Manutenção

- **Atualizar:** `git push` no `master`/branch → no VPS, `./deploy.sh` (git pull → build →
  up → `occ upgrade/repair`, idempotente, com lock e notificação opcional no Telegram).
- **Pinar o Collabora:** troque `COLLABORA_IMAGE` para uma tag fixa (ex.:
  `collabora/code:24.04.x.x.x`) — evita updates surpresa.
- **Backup:** volumes `blue3-drive_db` e `blue3-drive_nextcloud`. Faça dump do banco
  (`occ` ou `mariadb-dump`) + cópia dos arquivos, com offsite.

## 7. Segurança (resumo — ver SECURITY_GUIDELINES.md)

- Só HTTPS (o Caddy força; `overwriteprotocol=https` no NC).
- `trusted_domains` restrito ao domínio; `trusted_proxies` = rede do Caddy.
- 2FA + brute-force já habilitados na allowlist; App Store trancada.
- `.env` nunca versionado; segredos fortes.
