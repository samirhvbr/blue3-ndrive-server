# Blue3 Drive — Diretrizes de Segurança

> Estas são diretrizes e requisitos; não uma certificação de implementação. A
> [revisão de 15/10/2026](docs/REVISAO-20261015.md) distingue controles presentes,
> portas publicadas, falhas toleradas e operação ainda não comprovada.

**Versão:** 1.0
**Data:** 2026-06-20
**Base:** adaptado das diretrizes da Blue3 Intranet (v1.1) para o contexto **Blue3 Drive** (Nextcloud 34 em Docker, modelo em camadas).
**Objetivo:** garantir que **segurança seja sempre prioridade máxima**, mesmo sacrificando performance, produtividade ou facilidade.

> Fonte única de princípios de segurança do Blue3 Drive. Detalhes de arquitetura: [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md). Convenções: [CLAUDE.md](CLAUDE.md).

---

## 1. Princípio Fundamental

> **Segurança > Produtividade > Performance > Facilidade**

Toda decisão passa primeiro pelo filtro de segurança. Não "deixar para depois" nem "aceitar o risco por enquanto".

**Princípios derivados:**

- **Menor privilégio.** Cada serviço, app, token e processo opera com o mínimo necessário. Usuário comum não é admin; app não habilitado não roda.
- **Fail-closed.** Na ausência de config ou em erro, **nega**. (Ex.: a loja vem trancada por padrão; sem `WHITEBOARD_JWT_SECRET`, o wiring do whiteboard é pulado, não aberto.)
- **Defesa em profundidade.** Várias camadas: curadoria de apps + loja trancada + brute-force + 2FA + HTTPS na borda. Nunca uma camada só.
- **Não confiar em entrada.** Upload, link público, requisição de cliente, payload de webhook — tudo hostil até prova em contrário. (O core do NC já trata o grosso; nosso papel é **não enfraquecer** isso por config.)

---

## 2. Modelo de Ameaças

| Ator | Vetor típico | Mitigação principal |
|---|---|---|
| **Atacante externo (Internet)** | Brute-force no login, scan, upload malicioso, abuso de link público | App **bruteforcesettings** ligado, **2FA** (twofactor_totp), HTTPS+HSTS na borda, `trusted_domains` restrito, limites de upload |
| **Ex-funcionário com credenciais residuais** | Sessão antiga, **app password** (WebDAV/cliente) não revogada, link compartilhado ativo | `occ user:disable`, revogar app-passwords e sessões, expirar/limpar shares |
| **Usuário com excesso de permissão** | Vira admin, instala app, muda config | Poucos admins; **loja trancada** (`appstoreenabled=false`) + `upgrade.disable-web=true`; grupos com escopo |
| **Supply chain** | Imagem base, tarball de app ou imagem do whiteboard comprometidos | Versões de apps fixas no Dockerfile, espelhadas manualmente em `build/apps.versions`; fontes oficiais; manter atualizado; checksum/assinatura e digest ainda pendentes |
| **Erro humano em deploy/operação** | Expor `.env` (JWT, senha admin/DB), subir com SQLite, `trusted_domains` aberto | `.env` fora do git; MariaDB configurado no compose; revisar config, backup e resultado de cada etapa do deploy; o script não fornece recuperação transacional |
| **Serviços auxiliares (CODE embutido, whiteboard, DB)** | Segredo JWT fraco/vazado, porta interna exposta, server-to-server abusado | Segredo JWT forte e secreto; bind/ingress/firewall a definir: o compose atual publica app e whiteboard no host; `allow_local_remote_servers` só para o CODE local |

Ao desenhar/alterar algo, pergunte: **qual desses atores tem incentivo e capacidade de atacar este fluxo, e como ele é barrado?**

---

## 3. Regras Gerais (obrigatórias)

- **Menor privilégio** em tudo (serviços, apps, usuários, tokens).
- **Fail-closed** em qualquer decisão de config/roteamento.
- **Nunca** commitar `.env`, JWT, senha de admin/DB ou qualquer segredo — `.env.example` é a fonte das chaves, com placeholders.
- **Loja trancada** e update pela web desabilitado — usuário não instala app aleatório.
- **MariaDB sempre, nunca SQLite.**
- **HTTPS na borda** em produção (proxy/SSL); `trusted_domains` só com os hosts reais.
- **Não enfraquecer o core**: não desligar app de segurança, não afrouxar headers, não habilitar debug em produção.
- **Nunca** logar segredo (senha, JWT, token de sessão/app-password) nem PII bruta.

---

## 4. Hardening do Nextcloud (config)

A segurança aqui é **configuração**, não código. Garantir:

- **Apps de segurança ligados** (em `config/apps.allowlist` → `[enable]`): `bruteforcesettings`, `twofactor_totp`, `twofactor_backupcodes`, `password_policy`, `privacy`.
  - *Auditoria:* `admin_audit` está em `[disable]` no MVP por peso. Para ambientes que exigem trilha de auditoria, mover para `[enable]`.
- **Loja/Update:** `appstoreenabled=false` + `upgrade.disable-web=true` (em `config/blue3.config.php`).
- **Acesso:** `trusted_domains` mínimo; `overwriteprotocol=https` + `overwrite.cli.url=https://drive.blue3.com.br` atrás de proxy TLS.
- **Headers de segurança / HSTS:** aplicados na **borda** (reverse proxy) em produção — HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, CSP do NC.
- **Uploads:** limites coerentes no proxy/PHP; antivírus opcional (`files_antivirus` + ClamAV — repo `AVIRUS` no espelho) como evolução.
- **Avisos do NC:** rodar `occ setupchecks` / conferir o painel **Administração → Visão geral** sem alertas de segurança.
- **debug sempre `false`** em produção; `loglevel` ≥ 2 (warning).

---

## 5. Segredos e Configuração

- **`.env` nunca é commitado.** Está no `build/.gitignore`. `.env.example` é a verdade das chaves, com placeholders.
- **Gerar segredos fortes:** ex. `WHITEBOARD_JWT_SECRET`, senhas → `openssl rand -hex 32`. Nada de senha óbvia/placeholder em produção.
- **Segredos que existem aqui:** senha do admin inicial, senha do MariaDB (user + root), `WHITEBOARD_JWT_SECRET`. Todos só no `.env`/ambiente — nunca em código, log, mensagem de erro ou commit.
- **Rotação:** alterar apenas o `.env` não troca as credenciais de contas já criadas. Atualizar a senha efetiva no Nextcloud/MariaDB pelo procedimento próprio do serviço e sincronizar os consumidores. O JWT exige concordância entre a configuração efetiva do app e o serviço whiteboard; o hook atual é pós-instalação. Testar a rotação em ambiente isolado e documentar incidente quando houver suspeita.
- **`occ config:system:get`** pode expor segredo no terminal — não colar saída em chat/issue.

---

## 6. Imagem e Dependências (supply chain)

- **Pinning:** os downloads usam as versões fixas nas linhas `fetch` do Dockerfile; `build/apps.versions` é um registro manual e não é lido pelo build. Conferir a paridade dos dois arquivos. A imagem base ainda usa uma tag por major, sem digest.
- **Fontes oficiais apenas:** `github.com/nextcloud-releases/*`, `github.com/CollaboraOnline/*`, `apps.nextcloud.com`, imagem base `nextcloud:34-*` oficial, whiteboard `ghcr.io/nextcloud-releases/whiteboard`.
- **Manter atualizado:** CVE `high`/`critical` em NC core, num app curado, no MariaDB ou na imagem do whiteboard **força** bump de versão + rebuild. Acompanhar os advisories do Nextcloud.
- **(Ideal)** verificar checksum/assinatura dos tarballs no build; pinar a imagem do whiteboard por versão/digest (hoje `:v1.5.9` no compose; sem digest).
- **Compatibilidade NC34:** novo app só entra na versão cujo `max-version` cobre o 34 (App Store `platform/34`).

---

## 7. Logs e Auditoria

- **Logar:** logins/falhas e ações administrativas (via `admin_audit` quando habilitado), eventos do core em `nextcloud.log`, acessos no proxy/apache.
- **Nunca** aparecer em log: senha, JWT, token de sessão/app-password, `.env`, PII bruta. Mascarar CPF/CNPJ.
- **Retenção:** definir rotação do `nextcloud.log` e dos logs do proxy; backups do banco + `data/` com retenção definida.

---

## 8. Tratamento de Erros

- **`debug=false`** em produção, sempre. Stacktrace/headers internos nunca chegam ao usuário.
- Mensagens de erro não distinguem "usuário não existe" de "senha errada" (o NC já trata — não reverter).
- O `provision.sh` é **best-effort**: erra → loga WARN e continua (não derruba o boot), mas o WARN deve ser revisado na validação (Fase 5).

---

## 9. LGPD — Princípios Mínimos

O Drive armazena arquivos e dados pessoais de usuários. Princípios:

- **Finalidade & minimização:** coletar/expor só o necessário (a UI enxuta ajuda — menos apps, menos coleta).
- **Acesso do titular:** o NC tem exportação de dados pessoais nativa (Configurações → Privacidade) — manter o app `privacy` ligado.
- **Retenção:** definir política para lixeira (`files_trashbin`) e versões (`files_versions`); backups com prazo.
- **Compartilhamento externo:** links públicos com senha/expiração quando contiverem PII.
- **Responsável por solicitações de titular:** Samir Hanna Verza.

---

## 10. Resposta a Incidentes

1. **Conter:** `occ maintenance:mode --on`. Se for usuário comprometido, `occ user:disable <uid>` primeiro.
2. **Revogar:** sessões e **app-passwords** do(s) usuário(s); invalidar links compartilhados suspeitos.
3. **Rotar segredos:** trocar as credenciais efetivas do admin/MariaDB e atualizar os consumidores; sincronizar o JWT do whiteboard nos dois lados. Recriar o `.env` e os containers, isoladamente, não altera contas persistidas. Seguir a seção 5 e validar o procedimento antes de reabrir o serviço.
4. **Snapshot:** dump do MariaDB + cópia do volume `data/` no momento do incidente, guardados à parte (não sobrescrever backups normais).
5. **Examinar logs:** `nextcloud.log`, `admin_audit` (se ligado), logs do proxy/apache — logins fora de hora, ações admin inesperadas, scan.
6. **Comunicar:** notificar Samir Hanna Verza. PII de terceiro vazada → avaliar ANPD (LGPD art. 48).
7. **Postmortem:** `.md` em `docs/postmortems/` — timeline, causa raiz, ações. Culpar processo, não pessoa.
8. **Patch:** corrigir (bump/rebuild/config), e se virar regra, atualizar este documento.

---

## 11. Checklist Rápido (pré-commit)

- [ ] Nenhum segredo no diff (`.env`, JWT, senha admin/DB)? `.env.example` atualizado?
- [ ] Loja continua trancada (`appstoreenabled=false`) e update web desabilitado?
- [ ] Apps de segurança (`bruteforcesettings`, `twofactor_totp`, `password_policy`) ainda em `[enable]`?
- [ ] `[required]` da allowlist intocado?
- [ ] Versões de app **pinadas** e de **fonte oficial**? Compatíveis com NC34?
- [ ] Banco continua **MariaDB** (nada de SQLite)?
- [ ] Nada de `debug=true` / afrouxamento de header / segredo em log?
- [ ] Mudança relevante refletida no `docs/PLANO-DE-ACAO.md` e `version.md` bumpado?

---

## 12. Filosofia Blue3

Segurança não é custo nem "nice to have". **Segurança é parte do produto.**
Não colocamos no ar algo sabidamente vulnerável só porque "está funcionando".

**"O que é feito com pressa, é pago com arrependimento."** Dúvida sobre aplicar uma regra? Pergunte **antes**.

---

## 13. Referências

- [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md) — arquitetura em camadas, decisões, fases.
- [CLAUDE.md](CLAUDE.md) — convenções, banco, build, checklist.
- [README.md](README.md) — visão geral, como subir/atualizar.
- Hardening oficial do Nextcloud: https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html
- Advisories: https://github.com/nextcloud/security-advisories

---

**Responsável:** Samir Hanna Verza · **Empresa:** Blue3
