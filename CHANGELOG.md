# Changelog

Entradas no formato da mensagem de commit (`versão - descrição curta em
português`), mais recente no topo. **Cada cabeçalho `##` é literalmente o
assunto do commit** — a entrada é escrita *antes* do commit, para que a frase
que cai no `git log` seja uma frase pesada e não improvisada na hora.

Corpos são narrativos: o que mudou, por quê e o que foi medido. Este arquivo
não se reescreve.

> **O registro começa aqui.** Este arquivo nasceu depois do repositório: as
> versões anteriores estão no `git log` e não foram retroalimentadas, porque
> reconstruí-las agora produziria uma história plausível, não uma verdadeira.


## 0.1.15 - os blocos de eco são regenerados a partir do repodocs

As quatro regras marcadas de `CLAUDE.md` e `AGENTS.md` são reescritas a partir
da fonte única em [samirhvbr/repodocs](https://github.com/samirhvbr/repodocs):
`QUEUE-RULE`, `RELEASES-RULE`, `LANGUAGE-RULE` e `COMMIT-RULE`. Bloco é
substituído por inteiro entre os marcadores, cabeçalho incluído — é isso que faz
uma edição local não sobreviver e não confundir a próxima leitura.

O `QUEUE-RULE` é novo e chega pela primeira vez: a `.continue/` guarda trabalho
que ainda não existe, e um documento só sai dela quando a coisa que ele descreve
**existe**. Tamanho, idioma e desalinho não são condição de saída. **Nunca
esvazie essa pasta como arrumação.**
