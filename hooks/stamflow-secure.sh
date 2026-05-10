#!/usr/bin/env bash
# stamflow secure — Security Audit
# Secret Scanning, SAST, Prompt Injection, Dependency Audit
# Usage: /stamflow secure [--quick] [--json]
set -euo pipefail

QUIET=0; [[ "${1:-}" == "--quiet" ]] && QUIET=1

PASS=0; FAIL=0; WARN=0
pass() { ((PASS++)); [[ $QUIET -eq 0 ]] && echo "  ✅ $*"; }
fail() { ((FAIL++)); [[ $QUIET -eq 0 ]] && echo "  ❌ $*"; }
warn() { ((WARN++)); [[ $QUIET -eq 0 ]] && echo "  ⚠️  $*"; }

echo "════════════════════════════════════════"
echo "  stamflow secure — Security Audit"
echo "════════════════════════════════════════"
echo ""

# 1. Secret Scanning
echo "▸ Secret Scanning"
SECRET_PATTERNS=(
  "sk-ant-[a-zA-Z0-9]{20,}"
  "sk-proj-[a-zA-Z0-9]{20,}"
  "OPENAI_API_KEY[=\s]+['\"]?sk-"
  "DASHSCOPE_API_KEY"
  "NVIDIA_API_KEY"
  "ANTHROPIC_API_KEY"
)
FOUND_SECRETS=0
for pattern in "${SECRET_PATTERNS[@]}"; do
  # Search files, exclude .git and node_modules
  matches=$(grep -rnE "$pattern" --include="*.sh" --include="*.md" --include="*.json" --include="*.py" --include="*.js" --include="*.ts" --include="*.yml" --include="*.yaml" . 2>/dev/null | grep -v ".git/" | grep -v "node_modules/" | grep -v "gates.json" | grep -v "TESTCATALOG.md" | grep -v "SECURITY.md" || true)
  if [[ -n "$matches" ]]; then
    # Exclude known-safe files (test data, security docs, self)
    if echo "$matches" | grep -qv "gates.json\|SECURITY\|TESTCATALOG\|stamflow-secure\|stamflow-check\|injection-analyst\|aidefence\|security-architect"; then
      fail "potential secret: $(echo "$matches" | head -3)"
      ((FOUND_SECRETS++))
    fi
  fi
done
if [[ $FOUND_SECRETS -eq 0 ]]; then
  pass "no secrets found"
fi

# 2. SAST Pattern Scan
echo ""
echo "▸ SAST (Static Analysis)"
DANGEROUS_PATTERNS=(
  "eval\s"
  "exec\s*\(.*\$"
  "curl.*\|.*bash"
  "wget.*\|.*sh"
  "sudo\s"
  "chmod\s+777"
  "rm\s+-rf\s+/"
  "fetch\(.*\.exec\("
)
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  matches=$(grep -rnE "$pattern" --include="*.sh" --include="*.js" --include="*.ts" . 2>/dev/null | grep -v ".git/" | grep -v "node_modules/" | grep -v "stamflow-secure\|stamflow-check" || true)
  if [[ -n "$matches" ]]; then
    warn "dangerous pattern: $matches"
  fi
done
pass "SAST scan complete"

# 3. Prompt Injection Scan (Agents)
echo ""
echo "▸ Prompt Injection (Agents)"
INJECTION_EXCLUDE="aidefence|injection-analyst|security-architect|baidu-seo"
INJECTION_PATTERNS=(
  "ignore.*(all\s)?previous.*instructions"
  "ignore.*above.*instructions"
  "disregard.*previous"
  "forget.*everything"
  "you are now DAN"
  "jailbreak"
  "bypass.*gate"
  "developer mode"
  "system:\s*override"
)
AGENT_DIRS=()
for d in agents/ ~/.claude/agents/ .opencode/agents/stam-os/; do
  [[ -d "$d" ]] && AGENT_DIRS+=("$d")
done
if [[ ${#AGENT_DIRS[@]} -gt 0 ]]; then
  for pattern in "${INJECTION_PATTERNS[@]}"; do
    matches=$(grep -rni "$pattern" "${AGENT_DIRS[@]}" --include="*.md" 2>/dev/null | grep -vE "$INJECTION_EXCLUDE" || true)
    if [[ -n "$matches" ]]; then
      fail "prompt injection: $matches"
    fi
  done
  pass "agent prompt scan ($(find "${AGENT_DIRS[@]}" -name '*.md' 2>/dev/null | wc -l | tr -d ' ') agents)"
else
  warn "no agent directories found"
fi

# 4. Dependency Audit (npm/pip if applicable)
echo ""
echo "▸ Dependencies"
if [[ -f package.json ]]; then
  if command -v npm &>/dev/null; then
    npm audit --audit-level high 2>&1 | head -10 || warn "npm audit found issues"
    pass "npm audit run"
  else
    warn "npm not found, skip dependency audit"
  fi
elif [[ -f requirements.txt ]] || [[ -f pyproject.toml ]]; then
  if command -v pip-audit &>/dev/null; then
    pip-audit 2>&1 | head -10 || warn "pip-audit found issues"
    pass "pip-audit run"
  else
    warn "pip-audit not installed (pip install pip-audit)"
  fi
else
  pass "no dependencies to audit (shell-only project)"
fi

# 5. .env Safety
echo ""
echo "▸ .env Safety"
if [[ -f .env ]]; then
  fail ".env file exists in project root (should be .gitignored)"
elif ls .env.* &>/dev/null 2>&1; then
  warn ".env.* files found"
else
  pass "no .env files"
fi

if grep -q "\.env" .gitignore 2>/dev/null; then
  pass ".env in .gitignore"
else
  warn ".env NOT in .gitignore"
fi

echo ""
echo "════════════════════════════════════════"
echo "  Results: $PASS passed  $WARN warnings  $FAIL failed"
echo "════════════════════════════════════════"
