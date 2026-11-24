#!/usr/bin/env bash
# Instala o Fala Clara (skill de comunicação clara) para Claude Code e Codex, já ativa.
#
#   curl -fsSL https://raw.githubusercontent.com/carlos-dataengineer/fala-clara/main/install.sh | bash
#
# Opções: --skip-claude  --skip-codex  --no-always-on  --ref <branch|tag>
# Variáveis equivalentes: FALA_CLARA_SKIP_CLAUDE=1 FALA_CLARA_SKIP_CODEX=1
#   FALA_CLARA_NO_ALWAYS_ON=1 FALA_CLARA_REF=v1.0.0 FALA_CLARA_HOME=/outra/home (testes)
set -euo pipefail

REPO="carlos-dataengineer/fala-clara"
NAME="fala-clara"
BEGIN="<!-- fala-clara:inicio (gerenciado pelo instalador do Fala Clara; nao edite dentro deste bloco) -->"
END="<!-- fala-clara:fim -->"

SKIP_CLAUDE="${FALA_CLARA_SKIP_CLAUDE:-0}"
SKIP_CODEX="${FALA_CLARA_SKIP_CODEX:-0}"
NO_ALWAYS_ON="${FALA_CLARA_NO_ALWAYS_ON:-0}"
REF="${FALA_CLARA_REF:-main}"

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-claude) SKIP_CLAUDE=1 ;;
    --skip-codex) SKIP_CODEX=1 ;;
    --no-always-on) NO_ALWAYS_ON=1 ;;
    --ref) shift; REF="${1:?--ref precisa de um valor}" ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

HOME_DIR="${FALA_CLARA_HOME:-$HOME}"
CODEX_DIR="${CODEX_HOME:-$HOME_DIR/.codex}"

step() { printf '  \033[36m>\033[0m %s\n' "$1"; }
ok() { printf '  \033[32mok\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1" >&2; }

printf '\n  Fala Clara - o Claude falando como gente\n\n'

# 1. Origem dos arquivos
TEMP=""
cleanup() { if [ -n "$TEMP" ]; then rm -rf "$TEMP"; fi; }
trap cleanup EXIT

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/skills/$NAME/SKILL.md" ]; then
  ROOT="$SCRIPT_DIR"
  step "Usando os arquivos locais em $ROOT"
else
  TEMP="$(mktemp -d)"
  case "$REF" in v[0-9]*) KIND=tags ;; *) KIND=heads ;; esac
  step "Baixando $REPO ($REF)"
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/$KIND/$REF" | tar -xz -C "$TEMP"
  ROOT="$(find "$TEMP" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  [ -f "$ROOT/skills/$NAME/SKILL.md" ] || { echo "O pacote baixado não tem skills/$NAME/SKILL.md." >&2; exit 1; }
fi

SKILL_SRC="$ROOT/skills/$NAME"
BLOCK_SRC="$ROOT/ativacao/sempre-ativo.md"

# 2. Skill
install_skill() {
  local target="$1" label="$2"
  if [ -e "$target" ]; then
    if [ -f "$target/SKILL.md" ] && grep -Eq "^name:[[:space:]]*${NAME}[[:space:]]*$" "$target/SKILL.md"; then
      rm -rf "$target"
    else
      warn "$target já existe e não parece ser o Fala Clara. Pulei $label para não apagar nada."
      return 0
    fi
  fi
  mkdir -p "$(dirname "$target")"
  cp -R "$SKILL_SRC" "$target"
  ok "Skill instalada para $label em $target"
}

# 3. Bloco sempre ativo (idempotente: troca o bloco antigo pelo novo)
strip_block() {
  awk -v b="<!-- fala-clara:inicio" -v e="$END" '
    index($0, b) == 1 { skip = 1; next }
    skip && index($0, e) == 1 { skip = 0; next }
    !skip { print }
  ' "$1"
}

set_always_on() {
  local file="$1" label="$2" tmp
  mkdir -p "$(dirname "$file")"
  tmp="$(mktemp)"
  if [ -f "$file" ]; then
    if [ ! -f "$file.antes-fala-clara.bak" ] && ! grep -q "<!-- fala-clara:inicio" "$file"; then
      cp "$file" "$file.antes-fala-clara.bak"
    fi
    strip_block "$file" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$tmp"
  fi
  {
    if [ -s "$tmp" ]; then cat "$tmp"; printf '\n'; fi
    printf '%s\n' "$BEGIN"
    cat "$BLOCK_SRC"
    printf '%s\n' "$END"
  } > "$file"
  rm -f "$tmp"
  ok "Sempre ativo para $label ($file)"
}

if [ "$SKIP_CLAUDE" != "1" ]; then
  install_skill "$HOME_DIR/.claude/skills/$NAME" "Claude Code"
  [ "$NO_ALWAYS_ON" = "1" ] || set_always_on "$HOME_DIR/.claude/CLAUDE.md" "Claude Code"
fi
if [ "$SKIP_CODEX" != "1" ]; then
  install_skill "$CODEX_DIR/skills/$NAME" "Codex"
  [ "$NO_ALWAYS_ON" = "1" ] || set_always_on "$CODEX_DIR/AGENTS.md" "Codex"
fi
install_skill "$HOME_DIR/.agents/skills/$NAME" "outros agentes"

printf '\n  Pronto! Abra uma sessão nova do Claude Code ou do Codex e converse normalmente.\n'
printf '  Não precisa chamar a skill: ela já vem ligada.\n\n'
printf '  Usa o Claude no app ou no site (claude.ai)? Veja o passo extra no README:\n'
printf '  https://github.com/%s#no-app-ou-site-do-claude\n\n' "$REPO"
