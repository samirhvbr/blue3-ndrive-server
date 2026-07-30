# Blue3 Drive — guia de agentes

As convenções deste projeto (comunicação, versionamento, stack, arquitetura em
camadas, banco, segurança, fluxo de trabalho) vivem em **[CLAUDE.md](CLAUDE.md)**,
que é a fonte única. Este arquivo existe só por compatibilidade com ferramentas
que procuram `AGENTS.md` — leia o `CLAUDE.md`.

Veja também: [docs/PLANO-DE-ACAO.md](docs/PLANO-DE-ACAO.md) (a spec viva do produto)
e [SECURITY_GUIDELINES.md](SECURITY_GUIDELINES.md).

---

## PS — Commits: a skill COMMITTER cuida disso

**Existe `.committer.yml` na raiz deste repositório** — é o opt-in da skill
**COMMITTER**, que roda em ciclo (cron, via `~/x/GIT/run.sh`). Enquanto esse arquivo
existir com `enabled: true`, **commitar e pushar não é trabalho seu**.

**O que muda para você:**

- **Não commite nem pushe por padrão.** Conclua a entrega bumpando o `version.md`
  **com a entrada de changelog** e deixe a árvore pronta. É dali que a mensagem do
  commit sai — o changelog virou o artefato de handoff entre você e a skill.
- A skill monta `X.Y.Z - descrição`, commita e pusha a branch atual sozinha. Ela
  **nunca bumpa versão** (isso continua sendo julgamento seu) e nunca inventa
  mensagem: sem entrada de changelog ela cai num fallback Sonnet, e sem conseguir
  descrever com honestidade ela aborta e espera.

**Você ainda commita quando:**

- o Samir pedir explicitamente;
- a tarefa exigir o SHA na hora (deploy, abrir PR, referência cruzada);
- o `.committer.yml` sumir ou estiver `enabled: false` — aí vale o fluxo antigo,
  você bumpa, commita e pusha.

**Por que isso existe:** tirar de um modelo caro (Opus/Fable) o trabalho mecânico de
empacotar commit, que um Sonnet — ou, na maioria das vezes, nenhum modelo — resolve.
Economiza token e devolve tempo de desenvolvimento.
