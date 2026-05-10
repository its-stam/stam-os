#!/usr/bin/env bash
# stamflow dashboard — Terminal Dashboard with Discovery Interview
# Usage: /stamflow dashboard [--quick] [--json]
set -euo pipefail

# === Colors ===
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[0;31m'; CYAN=$'\033[0;36m'
else
  BOLD=''; DIM=''; RESET=''; GREEN=''; YELLOW=''; RED=''; CYAN=''
fi

box() { printf "%s\n" "$*"; }
header() { echo "${BOLD}${CYAN}$*${RESET}"; }
metric() { printf "  %-30s ${BOLD}%s${RESET}\n" "$1" "$2"; }

MODE="${1:---interactive}"
QUICK=0; [[ "$MODE" == "--quick" ]] && QUICK=1

# === Discovery Phase ===
echo ""
header "════════════════════════════════════════════════════════"
header "  stam-os Dashboard"
header "════════════════════════════════════════════════════════"
echo ""

if [[ $QUICK -ne 1 ]]; then
  echo "${BOLD}Discovery: What are you building?${RESET}"
  echo ""

  # Detect project context
  PROJECT_NAME=$(basename "$(pwd)" 2>/dev/null || echo "unknown")
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "none")
  FILES_COUNT=$(find . -type f -not -path "./.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  GIT_COMMITS=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
  LAST_COMMIT=$(git log -1 --format="%ar" 2>/dev/null || echo "never")

  # Detect project type
  if [[ -f package.json ]]; then PROJECT_TYPE="Node.js/TypeScript"
  elif [[ -f pyproject.toml ]] || [[ -f requirements.txt ]]; then PROJECT_TYPE="Python"
  elif [[ -f mix.exs ]]; then PROJECT_TYPE="Elixir"
  elif [[ -f Cargo.toml ]]; then PROJECT_TYPE="Rust"
  elif [[ -f go.mod ]]; then PROJECT_TYPE="Go"
  elif ls *.sh &>/dev/null; then PROJECT_TYPE="Shell"
  else PROJECT_TYPE="Unknown"; fi

  # === Project Section ===
  echo "${BOLD}┌─ Project ───────────────────────────────────────┐${RESET}"
  printf "${BOLD}│${RESET} %-48s ${BOLD}│${RESET}\n" "$PROJECT_NAME"
  printf "${BOLD}│${RESET} Type: %-43s ${BOLD}│${RESET}\n" "$PROJECT_TYPE"
  printf "${BOLD}│${RESET} Branch: %-41s ${BOLD}│${RESET}\n" "$GIT_BRANCH ($GIT_COMMITS commits)"
  printf "${BOLD}│${RESET} Files: %-42s ${BOLD}│${RESET}\n" "$FILES_COUNT"
  printf "${BOLD}│${RESET} Last commit: %-36s ${BOLD}│${RESET}\n" "$LAST_COMMIT"
  printf "${BOLD}└────────────────────────────────────────────────┘${RESET}\n\n"

  # === Recommendations ===
  echo "${BOLD}┌─ Recommendations ───────────────────────────────┐${RESET}"

  # Agent recommendations based on project type
  if [[ -f package.json ]]; then
    echo "${BOLD}│${RESET} ${GREEN}Agents:${RESET} code-reviewer, security-engineer, sre"
  elif [[ -f pyproject.toml ]]; then
    echo "${BOLD}│${RESET} ${GREEN}Agents:${RESET} data-engineer, ai-engineer, security-engineer"
  else
    echo "${BOLD}│${RESET} ${GREEN}Agents:${RESET} software-architect, code-reviewer, security-engineer"
  fi

  # Gate recommendations
  echo "${BOLD}│${RESET} ${GREEN}Gates:${RESET} no-force-push, no-credentials-in-files, no-env-commit"

  # Memory recommendation
  if [[ -d ~/Documents/Obsidian\ Vault ]] || [[ -d ~/Desktop/UNI ]]; then
    echo "${BOLD}│${RESET} ${GREEN}Memory:${RESET} primer.md + Obsidian vault (detected)"
  else
    echo "${BOLD}│${RESET} ${GREEN}Memory:${RESET} primer.md (try /stamflow vault for Obsidian)"
  fi

  echo "${BOLD}└────────────────────────────────────────────────┘${RESET}\n"
fi

# === Metrics Dashboard ===
echo "${BOLD}┌─ Metrics ────────────────────────────────────────┐${RESET}"

# Agent metrics
AGENT_COUNT=$(find ~/.claude/agents/ -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
GATE_COUNT=$(python3 -c "
import json
with open('$HOME/.claude/gates.json') as f:
    g = json.load(f)
enabled = [x for x in g.get('gates',[]) if x.get('enabled') != False]
blocks = sum(1 for x in enabled if x.get('level') == 'block')
warns = sum(1 for x in enabled if x.get('level') == 'warn')
print(f'{len(enabled)} ({blocks} block, {warns} warn)')
" 2>/dev/null || echo "?")


metric "Agents available" "$AGENT_COUNT"
metric "Active gates" "$GATE_COUNT"

# Session metrics
SESSION_LOG=$(find ~/.claude-flow/sessions/ -type f 2>/dev/null | wc -l | tr -d ' ') || SESSION_LOG="0"
MEMORY_SIZE=$(du -sh ~/.claude-flow/data/ 2>/dev/null | cut -f1) || MEMORY_SIZE="0"
metric "Sessions today" "$SESSION_LOG"
metric "Memory store" "$MEMORY_SIZE"

# Security metrics
LAST_SECRET_SCAN=$(find ~/.claude/hooks/stamflow-secure.sh -mtime 0 2>/dev/null && echo "Today" || echo "N/A")
HOOKS_ACTIVE=$(ls ~/.claude/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ')
metric "Hooks active" "$HOOKS_ACTIVE"
metric "Last secret scan" "$LAST_SECRET_SCAN"

# Lessons
LESSONS=$(wc -l < ~/tasks/lessons.md 2>/dev/null | tr -d ' ' || echo "0")
metric "Lessons learned" "$LESSONS entries"

echo "${BOLD}└────────────────────────────────────────────────┘${RESET}\n"

# === Quick Actions ===
echo "${BOLD}┌─ Quick Actions ──────────────────────────────────┐${RESET}"
echo "${BOLD}│${RESET} ${CYAN}/stamflow plan${RESET}     Plan & deploy agents"
echo "${BOLD}│${RESET} ${CYAN}/stamflow test${RESET}      Run all tests (code+security+agents+gates)"
echo "${BOLD}│${RESET} ${CYAN}/stamflow gate${RESET}      Manage safety gates"
echo "${BOLD}│${RESET} ${CYAN}/stamflow graph${RESET}    Input → Knowledge Graph → Obsidian"
echo "${BOLD}└────────────────────────────────────────────────┘${RESET}\n"

if [[ $QUICK -ne 1 ]]; then
  echo "${DIM}Run '/stamflow plan' to deploy agents tailored to your project.${RESET}"
  echo "${DIM}Run '/stamflow test --all' for a complete security + health check.${RESET}\n"
fi

echo "${GREEN}stam-os is ready.${RESET}"
