<?php

/**
 * Blue3 Drive — overrides de configuração (camada Blue3).
 *
 * Este arquivo é MESCLADO ao config.php do Nextcloud (vários $CONFIG são somados).
 * No build, vai para  /var/www/html/config/blue3.config.php  — nunca editamos o
 * config.php gerado pela instalação; só adicionamos este por cima.
 *
 * Ver docs/PLANO-DE-ACAO.md §9 e Fase 2.
 */

$CONFIG = [

	// ── Marca / tema ────────────────────────────────────────────────
	// Ativa o tema nativo themes/blue3/ (precisa existir em /var/www/html/themes/blue3,
	// copiado pelo Dockerfile). Complementado pelo app Theming via provision.sh.
	'theme' => 'blue3',

	// App de destino ao logar.
	'defaultapp' => 'files',

	// ── Trancar a loja e updates pelo usuário ───────────────────────
	// Desliga a App Store (sem instalar app aleatório → fim da "bagunça").
	'appstoreenabled' => false,
	// Atualização de core é por rebuild da imagem, não pela web.
	'upgrade.disable-web' => true,
	'updatechecker' => false,
	// Some o botão "ajuda"/base de conhecimento do menu.
	'knowledgebaseenabled' => false,
	// Some o link "crie sua conta grátis".
	'simpleSignUpLink.shown' => false,

	// ── Localização (produto BR) ────────────────────────────────────
	'default_language' => 'pt_BR',
	'default_locale' => 'pt_BR',
	'default_phone_region' => 'BR',

	// ── Banco ───────────────────────────────────────────────────────
	// Regra do projeto: MariaDB/MySQL sempre, NUNCA SQLite. O dbtype/credenciais
	// são definidos na instalação (compose/env), não aqui — deixado como lembrete.
	// 'dbtype' => 'mysql',
];
