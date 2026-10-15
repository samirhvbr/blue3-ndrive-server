# Instalação, configuração e operação do Blue3 Drive

## Arquitetura e configuração

O build usa a raiz do repositório como contexto. Copia tema/configuração para o
template `/usr/src/nextcloud`, apps para `custom_apps`, skeleton e um hook
`post-installation`. O entrypoint upstream aplica sua própria política ao volume;
este repositório não contém o core nem um sincronizador de overlays independente.

| Configuração de `build/.env.example` | Consumo |
|---|---|
| `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` | Banco/app precisam concordar |
| `MYSQL_ROOT_PASSWORD` | Inicialização do serviço MariaDB |
| `NEXTCLOUD_ADMIN_USER`, `NEXTCLOUD_ADMIN_PASSWORD` | Conta de instalação inicial |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Hosts permitidos no Nextcloud |
| `APP_PORT`, `WHITEBOARD_PORT` | Portas publicadas no host, padrões 8080/3002 |
| `WHITEBOARD_JWT_SECRET` | Segredo compartilhado entre app e serviço whiteboard |
| `WHITEBOARD_PUBLIC_URL` | Endereço que o navegador alcança, não o nome interno do container |
| `WHITEBOARD_NEXTCLOUD_URL` | Endereço do Nextcloud visto pelo serviço; padrão `http://app` |

Use valores próprios, mantenha o arquivo privado e não anexe saída de `compose
config` sem `--quiet` a um relatório: ela pode expandir credenciais. Mudar a senha
no template/env depois da inicialização não é procedimento completo de rotação
no banco ou na conta Nextcloud já criada.

`config/blue3.config.php` seleciona tema, app inicial Files, idioma/locale e
restrições de loja/update. O hook aplica enable/disable e branding, configura o
idioma do admin e whiteboard quando há segredo. O estado real deve ser conferido
com `occ`: o wrapper tolera falhas, inclusive na aplicação de políticas.

## Conferência local após uma instalação autorizada

```bash
docker compose -f build/compose.yml --env-file build/.env ps
docker compose -f build/compose.yml --env-file build/.env exec -T -u www-data app php occ status
docker compose -f build/compose.yml --env-file build/.env exec -T -u www-data app php occ app:list
```

A disponibilidade por HTTP/HTTPS, uploads, WebDAV, links, identidade visual,
preferência de idioma e sessões precisam de teste pelo cliente. Whiteboard exige
URL pública e websocket/proxy coerentes. Office precisa abrir/editar um documento
real em ambiente de teste; existir um app habilitado não demonstra WOPI funcional.
O registro de junho em [PLANO-DE-ACAO.md](PLANO-DE-ACAO.md) não foi repetido nesta revisão.

A origem dos oito downloads e suas versões está em `apps.versions`; comparar com
o Dockerfile antes de rebuild. URLs oficiais com versão não substituem checksum,
assinatura, digest ou verificação atual de compatibilidade. O pacote CODE embutido
selecionado é x86_64; não foi validado em ARM.

## Atualização e falha do deploy

`bash deploy.sh` é uma ação de publicação, não um teste. Usa o diretório do script,
`build/.env`, `DEPLOY_BRANCH` do ambiente (default `master`) e lock via `flock`.
Sem diferença de commit sai cedo; mudar somente o `.env` não força recriação.
Com diferença, avisa se a árvore estiver suja, faz fast-forward, `up -d --build`,
espera `occ status` e tenta upgrade/repair/índices. Telegram é opcional e lê chaves
do arquivo privado; esta revisão não envia notificações nem executa o deploy.

`occ upgrade` falhando vira uma mensagem tolerada; reparo/índices também podem
falhar sem impedir a conclusão. O cleanup tenta desligar manutenção, inclusive
após erro. Não há rollback de commit/imagem/banco/arquivos nem prova transacional
de consistência. Registre falhas e confira integridade antes de reabrir tráfego.

O hook de marca/curadoria é `post-installation`, não uma etapa explícita de
reconciliação em toda atualização. Em volume existente, confirmar quais arquivos e
políticas foram efetivamente atualizados pela imagem/entrypoint; não prometer isso
apenas porque o build copiou um arquivo para `/usr/src/nextcloud`.

## Dados, backup e recuperação

O volume `db` contém MariaDB; `nextcloud` contém configuração, dados e demais
arquivos da instalação. O nome Compose é `blue3-drive`, mas nomes efetivos dos
volumes devem ser descobertos na instalação, sem supor que sejam iguais em todo host.
`down -v` remove dados e não é um procedimento de atualização.

Não existe rotina de backup/restore nesta base. Antes de atualizar produção, a
operação precisa preparar uma cópia consistente do banco, configuração/dados e
identidade da imagem/revisão, com credenciais protegidas e retenção definida.
Restaurar e testar em destino separado; só depois decidir troca de tráfego.
Voltar apenas o Git não desfaz migrations nem alterações no volume.

Também ficam fora do compose: TLS/proxy, DNS, rotina cron/background jobs,
monitoramento, retenção e destino externo de backup. Essas são lacunas de operação,
não funcionalidades que a documentação possa declarar entregues.

## Validação desta revisão

Foram feitas inspeção de fonte, conferência de links e verificações estáticas
sem ler o `.env` real. Não foi baixada imagem/tarball, iniciado serviço, executado
`occ`, validada instalação/atualização ou auditada a produção. O único workflow
versionado é de release. [Achados para decisão](REVISAO-20261015.md).
