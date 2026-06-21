# syntax=docker/dockerfile:1
#
# Blue3 Drive — imagem do produto.
# core NC34 (imagem oficial) + apps curados (tarball pinado) + tema Dark Blue3 + config Blue3.
# Decisão: CODE embutido (richdocumentscode) → sem container Collabora externo.
# Ver docs/PLANO-DE-ACAO.md §9 / Fase 4.
#
# Contexto de build = raiz BLUE3/DRIVE (compose já faz isso). Manual:
#   docker build -f build/Dockerfile -t blue3-drive:34 .
#
FROM nextcloud:34-apache

# ── Apps externos (tarballs oficiais pinados — espelha build/apps.versions) ──
# Extraídos em /usr/src/nextcloud/custom_apps; o entrypoint do NC copia essa árvore
# para o volume no 1º boot. 'curl' é instalado só para baixar e removido na mesma layer.
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends curl ca-certificates; \
	mkdir -p /usr/src/nextcloud/custom_apps; \
	cd /tmp; \
	fetch() { curl -fSL "$2" -o app.tgz; tar -xzf app.tgz -C /usr/src/nextcloud/custom_apps; rm -f app.tgz; }; \
	fetch calendar          https://github.com/nextcloud-releases/calendar/releases/download/v6.5.0/calendar-v6.5.0.tar.gz; \
	fetch mail              https://github.com/nextcloud-releases/mail/releases/download/v5.10.1/mail-v5.10.1.tar.gz; \
	fetch notes             https://github.com/nextcloud-releases/notes/releases/download/v6.0.0/notes-v6.0.0.tar.gz; \
	fetch contacts          https://github.com/nextcloud-releases/contacts/releases/download/v8.7.1/contacts-v8.7.1.tar.gz; \
	fetch richdocuments     https://github.com/nextcloud-releases/richdocuments/releases/download/v11.0.0/richdocuments-v11.0.0.tar.gz; \
	fetch richdocumentscode https://github.com/CollaboraOnline/richdocumentscode/releases/download/26.4.104/richdocumentscode.tar.gz; \
	fetch deck              https://github.com/nextcloud-releases/deck/releases/download/v1.18.1/deck-v1.18.1.tar.gz; \
	fetch whiteboard        https://github.com/nextcloud-releases/whiteboard/releases/download/v1.5.9/whiteboard-v1.5.9.tar.gz; \
	apt-get purge -y --auto-remove curl; \
	rm -rf /var/lib/apt/lists/*; \
	chown -R www-data:www-data /usr/src/nextcloud/custom_apps

# ── Camada Blue3: tema Dark Blue3 + overlay de config ──
# Copiados para o template do NC; entram no volume no 1º boot.
COPY --chown=www-data:www-data themes/blue3/ /usr/src/nextcloud/themes/blue3/
COPY --chown=www-data:www-data config/blue3.config.php /usr/src/nextcloud/config/blue3.config.php

# allowlist consumida pelo provision.sh (fica na imagem, fora do volume)
COPY config/apps.allowlist /usr/src/blue3/apps.allowlist

# ── Provisionamento de 1º boot (hook oficial post-installation) ──
COPY build/provision.sh /docker-entrypoint-hooks.d/post-installation/10-blue3.sh
RUN chmod +x /docker-entrypoint-hooks.d/post-installation/10-blue3.sh
