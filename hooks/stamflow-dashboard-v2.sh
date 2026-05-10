#!/usr/bin/env bash
# stam-os Dashboard v2 — Styled Terminal Dashboard
# Auto-detects project, shows metrics, security, recommendations
set -euo pipefail

RST='\033[0m'; BLD='\033[1m'; DIM='\033[2m'; REV='\033[7m'
GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'
CYN='\033[0;36m'; BLU='\033[0;34m'; MAG='\033[0;35m'; WHT='\033[1;37m'

# ---- Helpers ----
kpi() { printf " ${BLD}${WHT}║${RST}  ${BLD}%6s${RST}  %-28s\n" "$1" "$2"; }
bar() { 
  local val=$1 max=$2 color=$3 w=38
  local filled=$(( val * w / (max ? max : 1) ))
  local empty=$(( w - filled ))
  printf "${color}"
  for ((i=0; i<filled; i++)); do printf "█"; done
  printf "${DIM}"
  for ((i=0; i<empty; i++)); do printf "░"; done
  printf "${RST}"
}

# ---- Detect ----
PROJ=$(basename "$(pwd)" 2>/dev/null)
BRANCH=$(git branch --show-current 2>/dev/null || echo "–")
COMMITS=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
FILES=$(find . -type f -not -path "./.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
UNSTAGED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
LAST=$(git log -1 --format="%ar" 2>/dev/null || echo "–")

# Detect type
if [[ -f package.json ]]; then PTYPE="📦 Node.js"
elif [[ -f pyproject.toml ]] || [[ -f requirements.txt ]]; then PTYPE="🐍 Python"
elif [[ -f mix.exs ]]; then PTYPE="💧 Elixir"
elif [[ -f Cargo.toml ]]; then PTYPE="🦀 Rust"
elif [[ -f go.mod ]]; then PTYPE="🔵 Go"
elif ls *.sh &>/dev/null 2>&1; then PTYPE="🐚 Shell"
else PTYPE="❓ Unknown"
fi

# Agent stats
AGENT_TOTAL=$(find ~/.claude/agents/ -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
ENGINEERING=$(find ~/.claude/agents/ -name "engineering-*.md" 2>/dev/null | wc -l | tr -d ' ')
SECURITY=$(find ~/.claude/agents/ -name "*security*" 2>/dev/null | wc -l | tr -d ' ')

# Gate stats
GATE_TOTAL=0; GATE_BLOCK=0; GATE_WARN=0
if command -v python3 &>/dev/null && [[ -f ~/.claude/gates.json ]]; then
  read GATE_TOTAL GATE_BLOCK GATE_WARN <<< $(python3 -c "
import json
with open('$HOME/.claude/gates.json') as f:
    g=json.load(f)
enabled=[x for x in g['gates'] if x.get('enabled')!=False]
print(len(enabled), sum(1 for x in enabled if x.get('level')=='block'), sum(1 for x in enabled if x.get('level')=='warn'))
")
fi

# Session/Memory
SESSIONS=$(find ~/.claude-flow/sessions/ -type f 2>/dev/null | wc -l | tr -d ' ')
MEM_SIZE=$(du -sh ~/.claude-flow/data/ 2>/dev/null | cut -f1 || echo "–")
HOOKS=$(ls ~/.claude/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ')
LESSONS=$(grep -c "^\[" ~/tasks/lessons.md 2>/dev/null || echo 0)

# Security score (simplified)
SEC_SCORE=85
[[ $UNSTAGED -gt 5 ]] && SEC_SCORE=$((SEC_SCORE - 10))
[[ $GATE_TOTAL -lt 4 ]] && SEC_SCORE=$((SEC_SCORE - 20))
[[ $SEC_SCORE -lt 0 ]] && SEC_SCORE=0

# Health score
HEALTH=100; [[ $UNSTAGED -gt 0 ]] && HEALTH=$((HEALTH - 5 * UNSTAGED))
[[ $HEALTH -lt 0 ]] && HEALTH=0

# ---- RENDER ----
clear 2>/dev/null || true
echo ""

cat << TOP
${BLD}${CYN}╔══════════════════════════════════════════════════════════════════════╗${RST}
${BLD}${CYN}║${RST}  ${BLD}${WHT}stam-os${RST}${DIM} — Agent Operating System${RST}                              ${DIM}v1.0${RST}  ${BLD}${CYN}║${RST}
${BLD}${CYN}╠══════════════════════════╦══════════════╦════════════════════════════╣${RST}
${BLD}${CYN}║${RST}  ${BLD}Project${RST}                ${BLD}${CYN}║${RST}  ${BLD}Security${RST}    ${BLD}${CYN}║${RST}  ${BLD}Agents & Memory${RST}          ${BLD}${CYN}║${RST}
${BLD}${CYN}╠══════════════════════════╬══════════════╬════════════════════════════╣${RST}
TOP

# ---- Project Column ----
printf "${BLD}${CYN}║${RST}  ${DIM}Name:${RST}     ${BLD}%-10s${RST} ${BLD}${CYN}║${RST}  ${DIM}Score:${RST}    ${BLD}%3d%%${RST}     ${BLD}${CYN}║${RST}  ${DIM}Total:${RST}     ${BLD}%4s${RST} agents     ${BLD}${CYN}║${RST}\n" \
  "$PROJ" "$SEC_SCORE" "$AGENT_TOTAL"
printf "${BLD}${CYN}║${RST}  ${DIM}Type:${RST}     %-16s ${BLD}${CYN}║${RST}  ${BLD}             ${BLD}${CYN}║${RST}  ${DIM}Engin.:${RST}    ${BLD}%4s${RST} agents     ${BLD}${CYN}║${RST}\n" \
  "$PTYPE" "$ENGINEERING"
printf "${BLD}${CYN}║${RST}  ${DIM}Branch:${RST}   ${GRN}%-10s${RST} ${DIM}%3s commits${RST} ${BLD}${CYN}║${RST}  ${DIM}Gates:${RST}    ${BLD}%3s${RST} (${RED}%s block${RST})${BLD} ${BLD}${CYN}║${RST}  ${DIM}Security:${RST}  ${BLD}%4s${RST} agents     ${BLD}${CYN}║${RST}\n" \
  "$BRANCH" "$COMMITS" "$GATE_TOTAL" "$GATE_BLOCK" "$SECURITY"
printf "${BLD}${CYN}║${RST}  ${DIM}Files:${RST}    ${BLD}%5s${RST}              ${BLD}${CYN}║${RST}  ${DIM}Hooks:${RST}    ${BLD}%3s${RST} active   ${BLD}${CYN}║${RST}  ${DIM}Sessions:${RST}  ${BLD}%4s${RST} logged    ${BLD}${CYN}║${RST}\n" \
  "$FILES" "$HOOKS" "$SESSIONS"

printf "${BLD}${CYN}║${RST}  ${DIM}Last:${RST}     %-18s ${BLD}${CYN}║${RST}  ${DIM}Lessons:${RST}  ${BLD}%3s${RST} entries ${BLD}${CYN}║${RST}  ${DIM}Memory:${RST}    ${BLD}%6s${RST}        ${BLD}${CYN}║${RST}\n" \
  "$LAST" "$LESSONS" "$MEM_SIZE"

printf "${BLD}${CYN}║${RST}  ${DIM}Status:${RST}   %-18s ${BLD}${CYN}║${RST}  ${DIM}Vet:${RST}      ${BLD}${WHT}%3s%%${RST}      ${BLD}${CYN}║${RST}  ${DIM}Unstaged:${RST}  ${YLW}%4s${RST} files    ${BLD}${CYN}║${RST}\n" \
  "$([[ $UNSTAGED -eq 0 ]] && echo "${GRN}✓ Clean${RST}" || echo "${YLW}${UNSTAGED} changes${RST}")" "$HEALTH" "$UNSTAGED"

# ---- Progress Bars ----
echo -e "${BLD}${CYN}╠══════════════════════════════════════════════════════════════════════╣${RST}"
printf "${BLD}${CYN}║${RST}  ${DIM}Security${RST}   $(bar $SEC_SCORE 100 "$([ $SEC_SCORE -ge 80 ] && echo $GRN || echo $YLW)")  ${BLD}%3d%%${RST}  ${BLD}${CYN}║${RST}\n" $SEC_SCORE
printf "${BLD}${CYN}║${RST}  ${DIM}Health${RST}     $(bar $HEALTH 100 "$([ $HEALTH -ge 80 ] && echo $GRN || echo $YLW)")  ${BLD}%3d%%${RST}  ${BLD}${CYN}║${RST}\n" $HEALTH

# ---- Recommendations ----
echo -e "${BLD}${CYN}╠══════════════════════════════════════════════════════════════════════╣${RST}"
printf "${BLD}${CYN}║${RST}  ${BLD}Recommendations${RST}                                                    ${BLD}${CYN}║${RST}\n"

# Smart recommendations based on project type
if [[ -f package.json ]]; then
  echo -e "${BLD}${CYN}║${RST}  ${GRN}→${RST} Agents: code-reviewer, security-engineer, sre, devops-automator    ${BLD}${CYN}║${RST}"
elif [[ -f pyproject.toml ]]; then
  echo -e "${BLD}${CYN}║${RST}  ${GRN}→${RST} Agents: ai-engineer, data-engineer, security-engineer             ${BLD}${CYN}║${RST}"
else
  echo -e "${BLD}${CYN}║${RST}  ${GRN}→${RST} Agents: software-architect, code-reviewer, security-engineer       ${BLD}${CYN}║${RST}"
fi

echo -e "${BLD}${CYN}║${RST}  ${GRN}→${RST} Gates: no-force-push, no-credentials-in-files, no-env-commit        ${BLD}${CYN}║${RST}"

if [[ -d ~/Documents/Obsidian\ Vault ]] || [[ -d ~/Desktop/UNI ]]; then
  echo -e "${BLD}${CYN}║${RST}  ${GRN}→${RST} Memory: primer.md + Obsidian vault (detected)                      ${BLD}${CYN}║${RST}"
else
  echo -e "${BLD}${CYN}║${RST}  ${GRN}→${RST} Memory: primer.md (install Obsidian for Layer 5a)                  ${BLD}${CYN}║${RST}"
fi

# ---- Quick Actions ----
echo -e "${BLD}${CYN}╠══════════════════════════════════════════════════════════════════════╣${RST}"
echo -e "${BLD}${CYN}║${RST}  ${BLD}Quick Actions${RST}                                                        ${BLD}${CYN}║${RST}"
printf "${BLD}${CYN}║${RST}  ${CYN}/stamflow vet${RST}       Thorough exam (60+ checks)          ${DIM}🩺${RST}          ${BLD}${CYN}║${RST}\n"
printf "${BLD}${CYN}║${RST}  ${CYN}/stamflow plan${RST}      Agent deployment plan               ${DIM}🎯${RST}          ${BLD}${CYN}║${RST}\n"
printf "${BLD}${CYN}║${RST}  ${CYN}/stamflow view${RST}      Agent office visualization          ${DIM}🏢${RST}          ${BLD}${CYN}║${RST}\n"
printf "${BLD}${CYN}║${RST}  ${CYN}/stamflow test --all${RST} Run all 4 test suites               ${DIM}🧪${RST}          ${BLD}${CYN}║${RST}\n"
printf "${BLD}${CYN}║${RST}  ${CYN}/stamflow graph${RST}     Input → Knowledge Graph             ${DIM}🕸️${RST}          ${BLD}${CYN}║${RST}\n"
printf "${BLD}${CYN}║${RST}  ${CYN}/stamflow gate${RST}      Manage safety gates                 ${DIM}🛡️${RST}          ${BLD}${CYN}║${RST}\n"

# ---- Footer ----
echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════════════════════╝${RST}"
echo ""
echo -e "  ${DIM}$(date)${RST}  •  ${DIM}stam-os v1.0${RST}  •  ${DIM}github.com/its-stam/stam-os${RST}"
echo ""
