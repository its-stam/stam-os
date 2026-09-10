#!/usr/bin/env bash
# stam-os Setup
# One command installer. Non-destructive by default. Auto-detects existing configs.
# Usage: bash setup.sh [--force] [--help]
# Target directory: $CLAUDE_CONFIG_DIR if set, otherwise ~/.claude

set -euo pipefail

FORCE=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --force) FORCE=1; shift ;;
    --help|-h)
      echo "stam-os Setup"
      echo "  --force  Overwrite existing files"
      exit 0 ;;
    *) shift ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

info()  { echo "  [OK] $*"; }
skip()  { echo "  [=] $* (already exists, skipping)"; }

safe_copy() {
  local src="$1" dest="$2"
  if [[ -f "$dest" && $FORCE -ne 1 ]]; then
    skip "$(basename "$dest")"
    return 0
  fi
  cp "$src" "$dest"
  info "$(basename "$dest") -> $dest"
}

echo ""
echo "========================================"
echo "  stam-os Setup"
echo "  target: $CONFIG_DIR"
echo "========================================"
echo ""

echo "> Core (L0-L2)"
mkdir -p "$CONFIG_DIR"
safe_copy "$REPO_DIR/core/CLAUDE.md" "$CONFIG_DIR/CLAUDE.md"
safe_copy "$REPO_DIR/core/primer.md" "$CONFIG_DIR/primer.md"
safe_copy "$REPO_DIR/core/gates.json" "$CONFIG_DIR/gates.json"
safe_copy "$REPO_DIR/core/LAYERS.md" "$CONFIG_DIR/LAYERS.md"
safe_copy "$REPO_DIR/core/KNOWLEDGE.md" "$CONFIG_DIR/KNOWLEDGE.md"
safe_copy "$REPO_DIR/core/context-management.md" "$CONFIG_DIR/context-management.md"
safe_copy "$REPO_DIR/core/planmode.md" "$CONFIG_DIR/planmode.md"

echo ""
echo "> Hooks (L3)"
mkdir -p "$CONFIG_DIR/hooks"
for hook in session-start.sh session-end.sh pre-action-gate.sh post-compact.sh; do
  safe_copy "$REPO_DIR/hooks/$hook" "$CONFIG_DIR/hooks/$hook"
done
chmod +x "$CONFIG_DIR"/hooks/*.sh 2>/dev/null || true
info "hooks are executable"

if [[ -f "$CONFIG_DIR/settings.json" ]]; then
  info "settings.json exists -- wire the hooks in manually (see README.md#setup)"
fi

echo ""
echo "========================================"
echo "  stam-os is ready."
echo "  Next: restart your session."
echo "========================================"
echo ""
