# Blue3 Drive

Distribuição corporativa do Nextcloud montada por camadas: imagem base, apps
curados, tema Blue3, configuração e provisionamento. Este repositório contém o
empacotamento e seus overlays; o core Nextcloud e os apps são consumidos de
upstream, sem patch local.

## Estado atual e leitura

Revisão de fonte em 15/10/2026, base `ef85d36` (`0.1.17`). A implementação em
[build/Dockerfile](build/Dockerfile) usa **`nextcloud:34-apache`**, oito tarballs
externos e o tema de [themes/blue3/](themes/blue3/). O
[compose](build/compose.yml) define `app`, MariaDB 11.4 e whiteboard 1.5.9.
Esses são alvos de configuração, não confirmação de disponibilidade atual das
imagens ou aceitação em produção.

- [Guia de instalação, configuração e operação](docs/OPERACAO.md).
- [Revisão e pontos de código para decisão](docs/REVISAO-20261015.md).
- [Plano e registros anteriores](docs/PLANO-DE-ACAO.md), preservados com datas.
- [Diretrizes de segurança](SECURITY_GUIDELINES.md).
- [Handoff da integração Office](.continue/CONTINUAR.md).

## Funcionalidades e limites

| Área | O que está configurado |
|---|---|
| Arquivos | Nextcloud Files, compartilhamento, lixeira, versões, viewer e edição Text |
| Colaboração | Calendar, Contacts, Mail, Notes, Deck e Whiteboard na curadoria |
| Office | Conector richdocuments e CODE embutido x86_64; a última validação registrada reporta falha e proposta de backend externo, ainda sem alteração no compose |
| Identidade | Marca Blue3, tema nativo/CSS, imagens e skeleton de novos usuários |
| Administração | Loja e atualizador Web desligados, idioma/locale padrão pt_BR, apps de segurança habilitados por configuração |
| Persistência | Volumes nomeados para MariaDB e a árvore `/var/www/html` do Nextcloud |

A allowlist aplica somente `enable` e `disable` explícitos: não desliga todo app
fora da lista. Habilitar TOTP não torna 2FA obrigatória para cada usuário.
O provisionamento é best-effort: WARN não interrompe o boot. Não há automação de
backup/restauração, cron do Nextcloud, proxy TLS ou scanner de dependências
implementados neste compose. Esses requisitos precisam ser definidos na operação.

## Iniciar um ambiente local

Docker com Compose v2, Git, espaço para core/tarballs/dados e uma configuração
privada são necessários. Use os comandos somente em ambiente destinado ao Drive:

```bash
# Em um checkout novo, preservar qualquer configuração local já existente.
cp -n build/.env.example build/.env
# Preencher o arquivo privado antes de iniciar a stack.
docker compose -f build/compose.yml --env-file build/.env config --quiet
docker compose -f build/compose.yml --env-file build/.env up -d --build
```

A porta padrão é `8080` para o app e `3002` para whiteboard. O compose publica
ambas no host sem endereço loopback explícito; não assuma que são privadas.
O admin inicial, domínio confiável, senhas e URL pública do quadro vêm do template.
O [guia operacional](docs/OPERACAO.md) detalha parâmetros, verificação e recuperação.

## Atualizar e contribuir

As versões/URLs de apps são mantidas tanto em `build/apps.versions` quanto nas
linhas `fetch` do Dockerfile; o manifesto não é lido automaticamente pelo build.
O core e o MariaDB usam tags por linha de versão, sem digest. Rebuild não equivale
à prova de que um volume existente recebeu o overlay, nem à validação do Office.

Run `python3 -m unittest discover -s tests -v` to check provisioning argument
handling and best-effort failure logging with synthetic values and local command
stubs. These checks do not start Nextcloud, a database, or containers.

`deploy.sh` faz fetch/fast-forward, recria a stack e tenta upgrade/repair; seu
tratamento de falha não restaura imagem, banco ou volume. Consulte os limites
antes de utilizá-lo. Esta revisão não iniciou containers, executou deploy,
inferiu a saúde de produção ou corrigiu código.

Contribuições seguem [AGENTS.md](AGENTS.md), em português e por PR. A versão do
repositório é distinta do core Nextcloud e das versões dos apps.
