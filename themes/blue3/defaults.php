<?php

/**
 * Blue3 Drive — tema nativo "Dark Blue3".
 *
 * Sobrescreve as strings de marca e cores do Nextcloud sem patch no core
 * (mecanismo oficial de tema: themes/<nome>/, ativado por 'theme' => 'blue3').
 * Ver docs/PLANO-DE-ACAO.md §4 e §6.
 *
 * SPDX-License-Identifier: AGPL-3.0-only
 */

class OC_Theme {

	/** URL base da marca (rodapé, e-mails). */
	public function getBaseUrl(): string {
		return 'https://drive.blue3.com.br';
	}

	/** Mantém a documentação oficial do Nextcloud. */
	public function getDocBaseUrl(): string {
		return 'https://docs.nextcloud.com';
	}

	/** Título exibido (aba do navegador, telas). */
	public function getTitle(): string {
		return 'Blue3 Drive';
	}

	/** Nome curto do produto. */
	public function getName(): string {
		return 'Blue3 Drive';
	}

	/** Nome com HTML (mesmo texto). */
	public function getHTMLName(): string {
		return 'Blue3 Drive';
	}

	/** Entidade (rodapé, copyright, e-mails). */
	public function getEntity(): string {
		return 'Blue3';
	}

	/** Slogan da marca. */
	public function getSlogan(): string {
		return 'Um local seguro para seus dados!';
	}

	/** Rodapé curto: © ano + entidade (link) + slogan. */
	public function getShortFooter(): string {
		$footer = '© ' . date('Y');
		$footer .= ' <a href="' . $this->getBaseUrl() . '" target="_blank" rel="noreferrer noopener">'
			. $this->getEntity() . '</a><br/>';
		$footer .= $this->getSlogan();

		return $footer;
	}

	/** Rodapé longo (mesma composição). */
	public function getLongFooter(): string {
		return $this->getShortFooter();
	}

	/** Link de documentação por chave. */
	public function buildDocLinkToKey($key): string {
		return $this->getDocBaseUrl() . '/server/latest/go.php?to=' . $key;
	}

	/** Cor primária da marca (cabeçalho de e-mails, accent). Azul Blue3. */
	public function getColorPrimary(): string {
		return '#29ABE2';
	}

	/** Cor de fundo padrão — navy profundo do "Dark Blue3" (base Abyss). */
	public function getColorBackground(): string {
		return '#000c18';
	}

	/** Variáveis que sobrescrevem core/css/variables.scss. */
	public function getScssVariables(): array {
		return [
			'color-primary' => '#29ABE2',
			'color-primary-text' => '#ffffff',
		];
	}
}
