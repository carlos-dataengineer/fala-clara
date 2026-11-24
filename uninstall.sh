#!/usr/bin/env bash
# Remove o Fala Clara: as pastas da skill e o bloco "sempre ativo".
#   curl -fsSL https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/uninstall.sh | bash
set -euo pipefail

NAME="fala-clara"
END="<!-- fala-clara:fim -->"
HOME_DIR="${FALA_CLARA_HOME:-$HOME}"
CODEX_DIR="${CODEX_HOME:-$HOME_DIR/.codex}"

remove_skill() {
  local target="$1"
  if [ -f "$target/SKILL.md" ] && grep -Eq "^name:[[:space:]]*$NAME[[:space:]]*$" "$target/SKILL.md"; then
    rm -rf "$target"
    printf '  ok Removido %s\n' "$target"
  fi
}

remove_block() {
  local file="$1" tmp
  [ -f "$file" ] || return 0
  grep -q "<!-- fala-clara:inicio" "$file" || return 0
  tmp="$(mktemp)"
  awk -v b="<!-- fala-clara:inicio" -v e="$END" '
    index($0, b) == 1 { skip = 1; next }
    skip && index($0, e) == 1 { skip = 0; next }
    !skip { print }
  ' "$file" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$tmp"
  if [ -s "$tmp" ] && grep -q '[^[:space:]]' "$tmp"; then mv "$tmp" "$file"; else rm -f "$tmp" "$file"; fi
  printf '  ok Bloco sempre ativo retirado de %s\n' "$file"
}

remove_skill "$HOME_DIR/.claude/skills/$NAME"
remove_skill "$CODEX_DIR/skills/$NAME"
remove_skill "$HOME_DIR/.agents/skills/$NAME"
remove_block "$HOME_DIR/.claude/CLAUDE.md"
remove_block "$CODEX_DIR/AGENTS.md"

printf '\n  Fala Clara removido. Os backups *.antes-fala-clara.bak, se existirem, ficaram onde estavam.\n\n'
