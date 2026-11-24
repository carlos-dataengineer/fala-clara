# Como contribuir

Obrigado! As contribuições mais valiosas aqui são **exemplos reais de antes e depois**, perguntas de coach melhores e ajustes de tom.

## Fluxo

1. Faça um fork e crie uma branch (`git checkout -b meu-ajuste`).
2. Edite o que precisar:
   - regras: `skills/fala-clara/SKILL.md`;
   - exemplos, perguntas e tiques: `skills/fala-clara/references/`;
   - ativação: `ativacao/sempre-ativo.md` e `ativacao/preferencias-claude-ai.txt` (mantenha os dois coerentes e curtos).
3. Rode a validação:
   ```bash
   python tests/validate_repo.py
   ```
4. Registre a mudança em `CHANGELOG.md`, na seção da próxima versão.
5. Abra o Pull Request preenchendo o modelo.

## Regras do projeto

- **Siga o próprio Fala Clara** ao escrever: frases curtas, exemplo concreto, sem tiques de IA.
- `SKILL.md` com menos de 500 linhas; detalhes vão para `references/`.
- O bloco de ativação fica curto, porque ele ocupa contexto em toda conversa.
- Exemplos usam **apenas pessoas e dados fictícios**. Nada de nomes de empresas, clientes, e-mails ou telefones reais.
- `install.ps1` e `uninstall.ps1` precisam ser **ASCII puro, sem BOM** (Windows PowerShell 5.1 e `irm | iex`).
- Ao mudar a versão, atualize juntos: `VERSION`, `SKILL.md` (metadata), `.claude-plugin/plugin.json` e `marketplace.json`. O teste confere.
