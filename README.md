# Fala Clara

**Faz o Claude conversar como gente: claro, curto, com exemplo da sua vida e honesto quando não sabe.**

[![CI](https://github.com/carlos-dataengineer/fala-clara/actions/workflows/ci.yml/badge.svg)](https://github.com/carlos-dataengineer/fala-clara/actions/workflows/ci.yml)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-blue.svg)](LICENSE)
![Idioma: pt-BR](https://img.shields.io/badge/idioma-pt--BR-green.svg)

Fala Clara é uma [skill](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) para Claude Code, Claude (app e site) e Codex. Depois de instalada, **você não precisa chamar nada**: ela liga sozinha em toda conversa.

## O que muda na prática

| Antes | Com o Fala Clara |
|---|---|
| "Ótima pergunta! A inflação é um fenômeno macroeconômico caracterizado pelo aumento generalizado..." | "Inflação é quando os preços sobem e o mesmo dinheiro compra menos. Pensa no seu mercado do mês: se R$ 600 enchiam o carrinho e agora são R$ 640..." |
| Inventa uma resposta para não ficar sem | "Não sei. Isso depende de uma decisão que ainda não saiu. Dá para olhar a previsão em tal lugar." |
| Muro de texto com títulos e negritos | A primeira frase já responde. O resto só se ajudar. |
| Responde e encerra | Resolve e deixa **uma** pergunta que te faz pensar diferente, e te convida a perguntar. |

## Os 5 combinados

1. **Fala como gente.** Frases curtas, sem jargão (ou com a explicação na mesma frase), sem tiques de texto de IA.
2. **Pouco texto, entendimento completo.** Corta enfeite, nunca a ressalva que muda a decisão.
3. **Sempre um exemplo prático da sua vida.** Usa o que sabe de você (trabalho, rotina, projetos). Se não sabe, usa o cotidiano comum e pergunta para personalizar.
4. **Quando não sabe, diz.** "Não sei", "não entendi", "ainda não tenho essa resposta". Separa certeza de palpite.
5. **Age como coach.** Resolve primeiro, depois provoca com uma pergunta que tira da caixa. O apoio diminui conforme você aprende.

Quando você pede só código, um comando ou um formato fixo, ela fica discreta e entrega direto.

O detalhe de tudo está em [skills/fala-clara/SKILL.md](skills/fala-clara/SKILL.md).

## Instalação

### Claude Code e Codex (um comando)

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/install.ps1 | iex
```

**macOS e Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/install.sh | bash
```

O instalador:

1. copia a skill para `~/.claude/skills/fala-clara`, `~/.codex/skills/fala-clara` e `~/.agents/skills/fala-clara`;
2. coloca um bloco curto e marcado no seu `~/.claude/CLAUDE.md` e no `~/.codex/AGENTS.md`, que é o que deixa a skill **sempre ativa**. Antes de mexer, ele guarda uma cópia em `*.antes-fala-clara.bak`, e nunca toca no resto do arquivo.

Abra uma sessão nova e converse normalmente.

<details>
<summary>Opções do instalador</summary>

| PowerShell | Bash | Variável | O que faz |
|---|---|---|---|
| `-SkipClaude` | `--skip-claude` | `FALA_CLARA_SKIP_CLAUDE=1` | Não instala no Claude Code |
| `-SkipCodex` | `--skip-codex` | `FALA_CLARA_SKIP_CODEX=1` | Não instala no Codex |
| `-NoAlwaysOn` | `--no-always-on` | `FALA_CLARA_NO_ALWAYS_ON=1` | Só copia a skill, sem o bloco sempre ativo |
| `-Ref v1.0.0` | `--ref v1.0.0` | `FALA_CLARA_REF=v1.0.0` | Instala uma versão específica |

Com `irm | iex` use as variáveis, por exemplo: `$env:FALA_CLARA_SKIP_CODEX='1'; irm ... | iex`.
</details>

### Como plugin do Claude Code

Se você prefere gerenciar pelo sistema de plugins, rode dentro do Claude Code:

```
/plugin marketplace add carlos-dataengineer/fala-clara
/plugin install fala-clara@fala-clara
```

O plugin traz a skill e um gancho `SessionStart` que liga o Fala Clara no início de cada sessão. Não precisa rodar o instalador também.

### Com o `skills` CLI

```bash
npx skills add carlos-dataengineer/fala-clara
```

Esse caminho copia só a skill. Para ficar sempre ativa, cole o conteúdo de [ativacao/sempre-ativo.md](ativacao/sempre-ativo.md) no `CLAUDE.md` (ou `AGENTS.md`) do seu agente.

### No app ou site do Claude

1. Baixe o `fala-clara-skill.zip` da [última versão](https://github.com/carlos-dataengineer/fala-clara/releases/latest).
2. No Claude, vá em **Configurações > Capacidades > Skills**, clique em **Enviar skill** e escolha o zip.
3. Para ela agir sem ser chamada, vá em **Configurações > Perfil > Preferências** e cole o texto de [ativacao/preferencias-claude-ai.txt](ativacao/preferencias-claude-ai.txt).

Os nomes dos menus podem mudar um pouco conforme a versão do app.

### Manual

Copie a pasta `skills/fala-clara` para a pasta de skills do seu agente e cole [ativacao/sempre-ativo.md](ativacao/sempre-ativo.md) nas instruções globais dele.

## Desinstalar

**Windows:**

```powershell
irm https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/uninstall.ps1 | iex
```

**macOS e Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/uninstall.sh | bash
```

Remove as pastas da skill e só o bloco marcado do `CLAUDE.md` / `AGENTS.md`. Plugin: `/plugin uninstall fala-clara`.

## Como funciona

Uma skill comum só entra em ação quando o assunto combina com a descrição dela. Comunicação vale para **toda** resposta, então o Fala Clara usa duas camadas:

- **A skill** ([SKILL.md](skills/fala-clara/SKILL.md) + [referências](skills/fala-clara/references/)) tem as regras completas, exemplos e o banco de perguntas de coach.
- **A ativação** ([sempre-ativo.md](ativacao/sempre-ativo.md)) é um resumo curto que fica nas instruções globais (ou entra pelo gancho do plugin). Ela garante o comportamento em toda conversa e manda o Claude carregar a skill quando precisar dos detalhes.

Mais detalhes em [docs/como-funciona.md](docs/como-funciona.md).

## Estrutura

```
fala-clara/
├── skills/fala-clara/        # a skill
│   ├── SKILL.md
│   └── references/           # exemplos, perguntas de coach, tiques de IA
├── ativacao/                 # textos que deixam a skill sempre ativa
├── .claude-plugin/           # plugin e marketplace do Claude Code
├── hooks/hooks.json          # gancho SessionStart do plugin
├── install.ps1 / install.sh
├── uninstall.ps1 / uninstall.sh
├── tests/validate_repo.py
└── docs/
```

## Inspirações

Projetos que ajudaram a desenhar este, sem copiar código:

- [blader/humanizer](https://github.com/blader/humanizer): a ideia de listar padrões de texto de IA para evitar.
- Skills de *plain language* do ecossistema (como [patrick204nqh/skills](https://github.com/patrick204nqh/skills)): simplificar sem perder ressalvas importantes.
- Skills de ensino socrático, como *socratic-teaching-scaffolds*: apoio que diminui conforme a pessoa aprende.
- O guia oficial de [boas práticas para criar skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices) da Anthropic.

A diferença do Fala Clara é juntar as quatro coisas (linguagem simples, exemplo da vida real, honestidade e coach) em português e ligadas o tempo todo.

## Contribuindo

Sugestões de exemplos, perguntas de coach e ajustes de tom são muito bem-vindos. Veja o [CONTRIBUTING.md](CONTRIBUTING.md).

## Licença

[MIT](LICENSE).
