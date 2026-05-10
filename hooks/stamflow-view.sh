#!/usr/bin/env bash
# stamflow view — Terminal Agent Visualization

RST='\033[0m'; BLD='\033[1m'; DIM='\033[2m'
GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'
CYN='\033[0;36m'; BLU='\033[0;34m'; MAG='\033[0;35m'; WHT='\033[1;37m'

emoji() {
  case "$1" in
    *security*|*threat*|*defence*) echo "🛡️";;
    *code-review*|*reviewer*)      echo "🔍";;
    *backend*|*architect*)         echo "🏗️";;
    *frontend*|*ui*)               echo "🎨";;
    *devops*|*cicd*)               echo "🚀";;
    *ai-engineer*|*ml*)            echo "🧠";;
    *sre*)                         echo "📡";;
    *data-engineer*)               echo "⚙️";;
    *tester*|*qa*)                 echo "🧪";;
    *reality*)                     echo "✅";;
    *incident*)                    echo "🚨";;
    *orchestrat*)                  echo "🎭";;
    *compliance*|*audit*)          echo "📋";;
    *product-manager*)             echo "📊";;
    *design*|*ux*)                 echo "🖌️";;
    *software*|*senior*)           echo "💻";;
    *git*)                         echo "🌿";;
    *database*)                    echo "🗄️";;
    *doc*|*writer*)                echo "📝";;
    *rapid*|*proto*)               echo "⚡";;
    *mobile*)                      echo "📱";;
    *)                             echo "💼";;
  esac
}

colorset() {
  case "$1" in
    *security*|*threat*|*audit*|*compliance*) echo "$RED" ;;
    *architect*|*backend*|*data*) echo "$BLU" ;;
    *frontend*|*design*|*ux*)     echo "$MAG" ;;
    *devops*|*sre*|*docker*)      echo "$CYN" ;;
    *ai*|*engineer*|*ml*)         echo "$YLW" ;;
    *code-review*|*tester*|*reality*) echo "$GRN" ;;
    *) echo "$WHT" ;;
  esac
}

# Collect agents
agents=""
for dir in "$HOME/.claude/agents/" "./agents/" "$HOME/.opencode/agents/stam-os/"; do
  [[ -d "$dir" ]] || continue
  agents+=$(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | head -30)
  agents+=$'\n'
done

# Filter to real agents, deduplicate, pick 12
filtered=$(echo "$agents" | grep -E "engineer|developer|architect|reviewer|tester|manager|designer|auditor|orchestrat|specialist|sre|advocate" | sort -u | sort -R | head -12 | sed 's/.*\///g' | sed 's/\.md$//')

AGENTS=()
while IFS= read -r line; do [[ -n "$line" ]] && AGENTS+=("$line"); done <<< "$filtered"

STATUSES=("🟢Work" "🟡Idle" "🟢Work" "🟢Work" "🟡Idle" "🔴Stop" "🟢Work" "🟢Work" "🟡Idle" "🟢Work" "🟢Work" "🟡Idle")

sw=0; si=0; sb=0
for s in "${STATUSES[@]}"; do case "$s" in *Work*) ((sw++));; *Idle*) ((si++));; *Stop*) ((sb++));; esac; done

clear 2>/dev/null || true
echo ""

cat << TOP
${BLD}${WHT}╔══════════════════════════════════════════════════════════════╗${RST}
${BLD}${WHT}║${RST}  ${BLD}stam-os — Agent Office${RST}                                     ${BLD}${WHT}║${RST}
${BLD}${WHT}╠══════════════════════════════════════════════════════════════╣${RST}
TOP

for row in 0 1 2; do
  t=""; m=""; b=""
  for col in 0 1 2 3; do
    idx=$((row * 4 + col))
    if [[ $idx -lt ${#AGENTS[@]} ]]; then
      agent="${AGENTS[$idx]}"
      c=$(colorset "$agent")
      icon=$(emoji "$agent")
      st="${STATUSES[$idx]}"
      # Short name (10 chars max for the box)
      short=$(echo "$agent" | sed 's/engineering-//;s/specialized-//;s/testing-//;s/product-//;s/design-//;s/marketing-//' | cut -c1-10)
      t+="${BLD}${WHT}╔══════════╗${RST}  "
      m+="${BLD}${WHT}║${RST}${c}${icon}${RST}${c}${short}${RST}  ${BLD}${WHT}║${RST}  "
      b+="${BLD}${WHT}╚${RST} ${c}${st}${RST}  ${BLD}${WHT}╝${RST}  "
    else
      t+="              "
      m+="              "
      b+="              "
    fi
  done
  printf "%s\n" "$t"
  printf "%s\n" "$m"
  printf "%s\n" "$b"
  echo ""
done

TOTAL=$(find ~/.claude/agents/ -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

cat << BOT
${BLD}${WHT}╠══════════════════════════════════════════════════════════════╣${RST}
${BLD}${WHT}║${RST}${DIM}  Agents: ${BLD}${TOTAL}${RST}  |  ${GRN}🟢 ${sw} working${RST}  |  ${YLW}🟡 ${si} idle${RST}  |  ${RED}🔴 ${sb} blocked${RST}                         ${BLD}${WHT}║${RST}
${BLD}${WHT}╚══════════════════════════════════════════════════════════════╝${RST}

  ${DIM}Commands:${RST} ${BLD}/stamflow plan${RST} • ${BLD}/stamflow test${RST} • ${BLD}/stamflow dashboard${RST}
  ${DIM}$(date)${RST}
BOT
echo ""
