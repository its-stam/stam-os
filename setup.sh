#!/usr/bin/env bash
# stam-os Setup — https://github.com/its-stam/stam-os
# One command installer. Non-destructive. Auto-detects existing configs.
# Usage: bash setup.sh [--force] [--skip-agents] [--skip-hooks] [--help]

set -euo pipefail

FORCE=0
SKIP_AGENTS=0
SKIP_HOOKS=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --force) FORCE=1; shift ;;
    --skip-agents) SKIP_AGENTS=1; shift ;;
    --skip-hooks) SKIP_HOOKS=1; shift ;;
    --help|-h)
      echo "stam-os Setup"
      echo "  --force        Overwrite existing files"
      echo "  --skip-agents  Skip agent installation"
      echo "  --skip-hooks   Skip hook installation"
      exit 0 ;;
    *) shift ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helpers ---
info()  { echo "  [✓] $*"; }
warn()  { echo "  [!] $*"; }
skip()  { echo "  [=] $* (already exists, skipping)"; }

safe_copy() {
  local src="$1" dest="$2"
  if [[ -f "$dest" && $FORCE -ne 1 ]]; then
    skip "$(basename "$dest")"
    return 0
  fi
  cp "$src" "$dest"
  info "$(basename "$dest") → $dest"
}

echo ""
echo "════════════════════════════════════════"
echo "  stam-os Setup"
echo "════════════════════════════════════════"
echo ""

# --- Layer 1-2: Rules + State ---
echo "▸ Core (Layer 1-3)"
mkdir -p ~/.claude
safe_copy "$REPO_DIR/core/CLAUDE.md" ~/.claude/CLAUDE.md
safe_copy "$REPO_DIR/core/primer.md" ~/.claude/primer.md
safe_copy "$REPO_DIR/core/gates.json" ~/.claude/gates.json
safe_copy "$REPO_DIR/core/lessons.md" "$HOME/tasks/lessons.md"

# --- Layer 4: Hooks ---
if [[ $SKIP_HOOKS -ne 1 ]]; then
  echo ""
  echo "▸ Hooks (Layer 4)"
  mkdir -p ~/.claude/hooks
  for hook in session-start.sh session-end.sh pre-action-gate.sh post-compact.sh; do
    safe_copy "$REPO_DIR/hooks/$hook" ~/.claude/hooks/$hook
  done
  chmod +x ~/.claude/hooks/*.sh 2>/dev/null
  info "hooks are executable"

  # Merge settings.json hooks (add gates + post-compact if not present)
  if [[ -f ~/.claude/settings.json ]]; then
    info "settings.json exists — merge hooks manually: docs/INSTALL.md#hooks"
  elif [[ -f "$REPO_DIR/core/settings.template.json" ]]; then
    safe_copy "$REPO_DIR/core/settings.template.json" ~/.claude/settings.json
  else
    info "no settings template — skip. Add gates to your ~/.claude/settings.json manually."
  fi
fi

# --- Layer 0: Agents ---
if [[ $SKIP_AGENTS -ne 1 ]]; then
  echo ""
  echo "▸ Agents (Layer 0)"
  mkdir -p ~/.claude/agents

  # Install to Claude Code
  AGENT_COUNT=0
  for dir in engineering design testing product specialized; do
    [[ -d "$REPO_DIR/agents/$dir" ]] || continue
    for f in "$REPO_DIR/agents/$dir"/*.md; do
      [[ -f "$f" ]] || continue
      name="$(basename "$f")"
      if [[ -f ~/.claude/agents/$name && $FORCE -ne 1 ]]; then
        continue
      fi
      cp "$f" ~/.claude/agents/
      ((AGENT_COUNT++)) || true
    done
  done

  # Install to OpenCode (if detected)
  if command -v opencode &>/dev/null || [[ -d ~/.opencode ]]; then
    mkdir -p ~/.opencode/agents/stam-os
    for dir in engineering design testing product specialized; do
      [[ -d "$REPO_DIR/agents/$dir" ]] || continue
      cp "$REPO_DIR/agents/$dir"/*.md ~/.opencode/agents/stam-os/ 2>/dev/null
    done
    info "agents also installed to ~/.opencode/agents/stam-os/"
  fi

  info "$AGENT_COUNT agents installed"
fi

# --- Layer 5a: Obsidian ---
echo ""
echo "▸ Knowledge Base (Layer 5a)"
if [[ -d ~/Documents/Obsidian\ Vault ]] || [[ -d ~/Desktop/UNI ]]; then
  info "Obsidian vault detected"
  info "Templates in obsidian/ — copy manually or use /stamflow vault"
else
  warn "No Obsidian vault found. Install Obsidian from https://obsidian.md"
fi

echo ""
echo "════════════════════════════════════════"
echo "  stam-os is ready."
echo ""
echo "  Next: restart Claude Code or OpenCode"
echo "  Try:  /stamflow deploy"
echo "════════════════════════════════════════"
echo ""
