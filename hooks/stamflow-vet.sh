#!/usr/bin/env bash
# stamflow vet — Thorough examination (Herz und Nieren Test)
# Runs ALL test categories, produces scored report
set -euo pipefail

RST='\033[0m'; BLD='\033[1m'; DIM='\033[2m'
GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; CYN='\033[0;36m'; MAG='\033[0;35m'

PASS=0; FAIL=0; WARN=0; TOTAL_TESTS=0
declare -a CATEGORY_SCORES=()

header()  { printf "\n${BLD}${CYN}━━━ %s ━━━${RST}\n" "$*"; }
pass()   { ((PASS++)); ((TOTAL_TESTS++)); printf "  ${GRN}✓${RST} %s\n" "$*"; }
fail()   { ((FAIL++)); ((TOTAL_TESTS++)); printf "  ${RED}✗${RST} %s\n" "$*"; }
warn()   { ((WARN++)); ((TOTAL_TESTS++)); printf "  ${YLW}△${RST} %s\n" "$*"; }
info()   { printf "  ${DIM}· %s${RST}\n" "$*"; }

# Category scoring
cat_start() { CAT_START_PASS=$PASS; CAT_START_FAIL=$FAIL; CAT_START_WARN=$WARN; }
cat_end() {
  local cpass=$((PASS - CAT_START_PASS))
  local cfail=$((FAIL - CAT_START_FAIL))
  local cwarn=$((WARN - CAT_START_WARN))
  local ctotal=$((cpass + cfail + cwarn))
  local score=100
  [[ $ctotal -gt 0 ]] && score=$(( (cpass * 100) / ctotal ))
  local icon="✅"
  [[ $score -lt 80 ]] && icon="⚠️"
  [[ $score -lt 50 ]] && icon="❌"
  CATEGORY_SCORES+=("$icon $score%")
}

echo ""
echo -e "${BLD}${CYN}╔══════════════════════════════════════════════════════════════╗${RST}"
echo -e "${BLD}${CYN}║${RST}  ${BLD}stamflow vet${RST} — Thorough Examination                          ${BLD}${CYN}║${RST}"
echo -e "${BLD}${CYN}║${RST}  ${DIM}$(date)${RST}                                     ${BLD}${CYN}║${RST}"
echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════════════╝${RST}"

# =============================================
# 1. CODE HEALTH
# =============================================
header "1. Code Health"
cat_start

# ShellCheck
if command -v shellcheck &>/dev/null; then
  issues=0
  for f in $(find . -name "*.sh" -not -path "./.git/*" -not -path "*/node_modules/*" 2>/dev/null); do
    sc_count=$(shellcheck -e SC1091 "$f" 2>/dev/null | grep -c "warning\|error" || true)
    [[ $sc_count -gt 0 ]] && ((issues += sc_count))
  done
  [[ $issues -eq 0 ]] && pass "ShellCheck: 0 issues" || warn "ShellCheck: $issues issues"
else
  warn "shellcheck not installed"
fi

# File permissions
bad_perms=0
for f in $(find . -type f -name "*.sh" -not -path "./.git/*" -not -path "*/node_modules/*" 2>/dev/null); do
  if [[ ! -x "$f" ]]; then warn "$(basename "$f"): not executable"; ((bad_perms++)); fi
done
[[ $bad_perms -eq 0 ]] && pass "Permissions: all .sh executable"

# Required files
for f in core/CLAUDE.md core/primer.md core/gates.json core/lessons.md core/planmode.md; do
  [[ -f "$f" ]] && pass "Required: $f" || fail "Missing: $f"
done

# Gate count
if command -v python3 &>/dev/null; then
  gc=$(python3 -c "import json; g=json.load(open('core/gates.json')); print(len([x for x in g['gates'] if x.get('enabled')!=False]))" 2>/dev/null)
  [[ ${gc:-0} -ge 4 ]] && pass "Gates: $gc enabled" || warn "Gates: only $gc enabled"
fi

cat_end

# =============================================
# 2. SECURITY
# =============================================
header "2. Security"
cat_start

# Secrets in history
if git log --all -p 2>/dev/null | grep -qE "sk-ant-[a-zA-Z0-9]{20,}|sk-proj-[a-zA-Z0-9]{20,}"; then
  fail "Secrets: API key pattern in git history"
else
  pass "Secrets: git history clean"
fi

# SAST patterns
sast_hits=$(grep -rnE "eval\s|sudo\s|chmod\s+777" --include="*.sh" . 2>/dev/null | grep -v ".git/" | grep -v "stamflow-vet\|stamflow-test\|stamflow-check\|stamflow-secure" | wc -l | tr -d ' ')
[[ $sast_hits -eq 0 ]] && pass "SAST: no dangerous patterns" || warn "SAST: $sast_hits suspicious patterns"

# Prompt injection scan
injection_hits=$(grep -rniE "ignore.*(all\s)?previous.*instructions|you are now DAN|jailbreak|developer mode" --include="*.md" agents/ 2>/dev/null | grep -vE "aidefence|injection-analyst|security-architect" | wc -l | tr -d ' ')
[[ $injection_hits -eq 0 ]] && pass "Prompt Injection: agents clean" || fail "Prompt Injection: $injection_hits hits"

# .env safety
if [[ -f .env ]]; then fail ".env file exposed in project"; else pass ".env: not present"; fi
[[ -f .gitignore ]] && grep -q "\.env" .gitignore 2>/dev/null && pass ".gitignore: .env covered" || warn ".gitignore: .env NOT excluded"

cat_end

# =============================================
# 3. AGENTS
# =============================================
header "3. Agents"
cat_start

AGENT_DIRS=()
for d in agents/ ~/.claude/agents/ .opencode/agents/stam-os/; do [[ -d "$d" ]] && AGENT_DIRS+=("$d"); done

agent_count=0; broken_agents=0; dup_agents=0
declare -A seen_names

for dir in "${AGENT_DIRS[@]}"; do
  for f in "$dir"/*.md; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .md)
    ((agent_count++))
    # Frontmatter check
    head -1 "$f" 2>/dev/null | grep -q "^---$" || { ((broken_agents++)); continue; }
    grep -q "^name:" "$f" 2>/dev/null || { ((broken_agents++)); continue; }
    grep -q "^description:" "$f" 2>/dev/null || { ((broken_agents++)); continue; }
    # Duplicate
    [[ -n "${seen_names[$name]:-}" ]] && ((dup_agents++))
    seen_names[$name]=1
  done
done

pass "Agents: $agent_count found"
[[ $broken_agents -eq 0 ]] && pass "Agent quality: all valid frontmatter" || fail "Agent quality: $broken_agents broken"
[[ $dup_agents -eq 0 ]] && pass "Agent quality: no duplicates" || warn "Agent quality: $dup_agents duplicates"

cat_end

# =============================================
# 4. GATES (FUZZING)
# =============================================
header "4. Gates — Fuzzing"
cat_start

if command -v python3 &>/dev/null && [[ -f core/gates.json ]]; then
  python3 << PYEOF
import json, re

with open("core/gates.json") as f:
    gates = json.load(f)

errors = 0

# Validate regex
for gate in gates["gates"]:
    try: re.compile(gate["pattern"])
    except re.error:
        print(f"  ✗ {gate['name']}: invalid regex")
        errors += 1

# Fuzz attacks
attacks = [
    ("git push --force origin main", True),
    ("GIT PUSH --FORCE", True),
    ("git push -f", True),
    ("git  push   --force", True),
    ("rm -rf /etc", True),
    ("rm -Rf /var", True),
    ("rm  -rf  /tmp", True),
    ("echo OPENAI_API_KEY=sk-abc > .env", True),
    ("export ANTHROPIC_API_KEY=sk-ant-xxx", True),
    ("git add .env", True),
    ("git push origin main", False),
    ("npm run clean", False),
]

for attack, should_catch in attacks:
    caught = any(re.search(g["pattern"], attack) for g in gates["gates"] if g.get("enabled") != False)
    if should_catch and not caught:
        print(f"  ✗ NOT CAUGHT: {attack}")
        errors += 1
    elif not should_catch and caught:
        who = [g["name"] for g in gates["gates"] if re.search(g["pattern"], attack)]
        print(f"  ✗ FALSE POSITIVE: {attack} by {who}")
        errors += 1

if errors == 0:
    print("  ✓ All 12 fuzz tests pass")
else:
    print(f"  ✗ {errors} fuzz failures")
PYEOF
fi

cat_end

# =============================================
# 5. HOOKS
# =============================================
header "5. Hooks"
cat_start

hook_count=0; hook_issues=0
for hook in ~/.claude/hooks/*.sh; do
  [[ -f "$hook" ]] || continue
  ((hook_count++))
  grep -q "^#!/" "$hook" 2>/dev/null || { warn "$(basename "$hook"): missing shebang"; ((hook_issues++)); }
done
[[ $hook_issues -eq 0 ]] && pass "Hooks: $hook_count valid" || warn "Hooks: $hook_issues issues"

[[ -f ~/.claude/settings.json ]] && pass "settings.json present" || fail "settings.json missing"
cat_end

# =============================================
# 6. GIT HYGIENE
# =============================================
header "6. Git Hygiene"
cat_start

# .gitignore coverage
[[ -f .gitignore ]] && pass ".gitignore exists" || fail ".gitignore missing"
grep -q "\.env" .gitignore 2>/dev/null && pass ".env gitignored" || warn ".env not in .gitignore"
grep -q "skills-local" .gitignore 2>/dev/null && pass "skills-local gitignored" || warn "skills-local not in .gitignore"
grep -q "\.DS_Store" .gitignore 2>/dev/null && pass ".DS_Store gitignored" || warn ".DS_Store not in .gitignore"

# Unstaged files
unstaged=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
[[ $unstaged -eq 0 ]] && pass "Git: working tree clean" || warn "Git: $unstaged unstaged files"

cat_end

# =============================================
# 7. DOCS & COMPLETENESS
# =============================================
header "7. Documentation"
cat_start

for doc in README.md LICENSE SECURITY.md BLUEPRINT.md; do
  [[ -f "$doc" ]] && pass "Doc: $doc" || warn "Doc: $doc missing"
done

# README has key sections
if [[ -f README.md ]]; then
  grep -qi "quick start\|getting started" README.md && pass "README: has Quick Start" || warn "README: no Quick Start"
  grep -qi "architecture\|how it works" README.md && pass "README: has Architecture" || warn "README: no Architecture"
  grep -qi "license" README.md && pass "README: has License" || warn "README: no License"
fi
cat_end

# =============================================
# 8. LEARNING & MEMORY
# =============================================
header "8. Learning & Memory"
cat_start

[[ -f ~/tasks/lessons.md ]] && pass "lessons.md exists" || warn "lessons.md missing"
lesson_entries=$(grep -c "^\[" ~/tasks/lessons.md 2>/dev/null || echo 0)
[[ $lesson_entries -gt 0 ]] && pass "Lessons: $lesson_entries entries" || warn "Lessons: empty"

[[ -f ~/.claude/primer.md ]] && pass "primer.md present" || fail "primer.md missing"
MEM_DIR=~/.claude-flow/data
[[ -d "$MEM_DIR" ]] && pass "Memory store: $(du -sh "$MEM_DIR" 2>/dev/null | cut -f1)" || warn "Memory store not found"

cat_end

# =============================================
# RESULTS
# =============================================
echo ""
echo -e "${BLD}${CYN}╔══════════════════════════════════════════════════════════════╗${RST}"
echo -e "${BLD}${CYN}║${RST}  ${BLD}Vet Results${RST}                                                   ${BLD}${CYN}║${RST}"
echo -e "${BLD}${CYN}╠══════════════════════════════════════════════════════════════╣${RST}"

total=$((PASS + FAIL + WARN))
score=0; [[ $total -gt 0 ]] && score=$(( (PASS * 100) / total ))

# Category breakdown
categories=("Code Health" "Security" "Agents" "Gates" "Hooks" "Git Hygiene" "Docs" "Memory")
idx=0
for cat in "${categories[@]}"; do
  if [[ $idx -lt ${#CATEGORY_SCORES[@]} ]]; then
    printf "${BLD}${CYN}║${RST}  %-15s ${BLD}%s${RST}\n" "$cat" "${CATEGORY_SCORES[$idx]}"
  fi
  ((idx++))
done

echo -e "${BLD}${CYN}╠══════════════════════════════════════════════════════════════╣${RST}"

score_color="$GRN"; [[ $score -lt 80 ]] && score_color="$YLW"; [[ $score -lt 50 ]] && score_color="$RED"
printf "${BLD}${CYN}║${RST}  ${GRN}✓ %3d passed${RST}  |  ${RED}✗ %3d failed${RST}  |  ${YLW}△ %3d warnings${RST}  ${score_color}Score: %d%%${RST}  ${BLD}${CYN}║${RST}\n" $PASS $FAIL $WARN $score

health="🟢 Healthy"; [[ $score -lt 80 ]] && health="🟡 Needs Attention"; [[ $score -lt 50 ]] && health="🔴 Critical"
echo -e "${BLD}${CYN}║${RST}  ${BLD}Health:${RST} ${health}                                           ${BLD}${CYN}║${RST}"

echo -e "${BLD}${CYN}╚══════════════════════════════════════════════════════════════╝${RST}"
echo ""
