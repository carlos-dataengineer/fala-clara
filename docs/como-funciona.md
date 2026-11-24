# Como o Fala Clara funciona

## Por que só a skill não basta

O Claude lê o nome e a descrição de cada skill instalada e decide sozinho quando carregá-la. Isso é ótimo para tarefas específicas ("gerar um PDF"), mas comunicação vale para **toda** resposta. Se dependesse só da descrição, haveria conversas em que a skill não entraria.

É como ter um manual de atendimento na gaveta: ele só ajuda se a pessoa lembrar de abrir. O bloco sempre ativo é o cartaz na parede que lembra de usá-lo.

## As duas camadas

| Camada | Arquivo | Onde fica | Papel |
|---|---|---|---|
| Skill | `skills/fala-clara/` | `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, ou enviada no app | Regras completas, exemplos, banco de perguntas, tiques a evitar |
| Ativação | `ativacao/sempre-ativo.md` | Bloco marcado no `~/.claude/CLAUDE.md` e `~/.codex/AGENTS.md`, ou gancho `SessionStart` do plugin | Resumo curto que entra em toda sessão e chama a skill |
| Ativação (app/site) | `ativacao/preferencias-claude-ai.txt` | Preferências do perfil no claude.ai | Mesmo papel, no app e no site |

O resumo da ativação é curto de propósito: ele ocupa contexto em toda conversa, então só carrega o essencial. Os detalhes ficam na skill, que só é lida quando precisa.

## O bloco no CLAUDE.md

O instalador escreve assim:

```markdown
<!-- fala-clara:inicio (gerenciado pelo instalador do Fala Clara; nao edite dentro deste bloco) -->
## Fala Clara: jeito de conversar (sempre ativo)
...
<!-- fala-clara:fim -->
```

- Rodar o instalador de novo **troca** o bloco, não duplica.
- O desinstalador tira **só** o bloco.
- Na primeira vez, o arquivo original é copiado para `CLAUDE.md.antes-fala-clara.bak`.

Quer personalizar? Escreva suas preferências **fora** do bloco, no mesmo arquivo. Exemplo: "Sou professora de matemática do ensino médio; use exemplos da sala de aula." Isso deixa os exemplos do Fala Clara muito melhores.

## O plugin

`.claude-plugin/marketplace.json` publica o repositório como um marketplace com um plugin só. O plugin traz:

- a pasta `skills/` (descoberta automaticamente);
- `hooks/hooks.json`, que no início, retomada, limpeza ou compactação da sessão imprime `ativacao/sempre-ativo.md`. O Claude Code coloca esse texto no contexto.

O gancho usa `cat`. No Windows, o Claude Code roda ganchos pelo Git Bash, que já traz o `cat`.

## Limites conhecidos

- Instruções de projeto (`CLAUDE.md` do repositório) ou pedidos explícitos seus têm prioridade. Se você pedir "seja técnico e sem exemplos", ele obedece.
- O exemplo "da sua vida" depende do que o Claude sabe de você. Sem memória nem contexto, ele usa exemplos do cotidiano e pergunta.
- Não existe garantia de 100%: modelos de linguagem às vezes escorregam. Se notar, diga "fala clara" que ele volta ao jeito combinado.
