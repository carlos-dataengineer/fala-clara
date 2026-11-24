# Política de segurança

## Versões suportadas

Só a versão mais recente (branch `main` e a última tag) recebe correções.

## Como relatar uma vulnerabilidade

**Não abra uma issue pública.** Use o [relato privado de vulnerabilidades](https://github.com/carlos-dataengineer/fala-clara/security/advisories/new) do GitHub, contando o que acontece, o impacto e como reproduzir. A resposta inicial vem em até 7 dias.

## Escopo

- **Instaladores** (`install.*`, `uninstall.*`): apagar ou sobrescrever algo fora das pastas da skill ou fora do bloco marcado do `CLAUDE.md` / `AGENTS.md`.
- **Skill e ativação** (`skills/fala-clara`, `ativacao/`): instruções que levem o agente a expor dados, executar algo não pedido ou ignorar regras de segurança.
- **Plugin** (`.claude-plugin/`, `hooks/`): o gancho deve só imprimir um texto, nada mais.

## Para quem usa

Antes de rodar o instalador você pode ler o script. Ele só copia a pasta da skill para `~/.claude/skills`, `~/.codex/skills` e `~/.agents/skills`, e escreve um bloco marcado no `~/.claude/CLAUDE.md` e no `~/.codex/AGENTS.md` (com backup). Não baixa nem executa nada além do próprio repositório.
