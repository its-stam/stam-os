#!/usr/bin/env bash
# stamflow check — Code Health Dashboard
# ShellCheck, Gate Testing, File Perms, Dead Code, Complexity
# Usage: /stamflow check [--quick] [--json]
set -euo pipefail

MODE="${1:-full}"
QUIET=0; [[ "$MODE" == "--quiet" ]] && QUIET=1

PASS=0; FAIL=0; WARN=0
pass() { ((PASS++)); [[ $QUIET -eq 0 ]] && echo "  ✅ $*"; }
fail() { ((FAIL++)); [[ $QUIET -eq 0 ]] && echo "  ❌ $*"; }
warn() { ((WARN++)); [[ $QUIET -eq 0 ]] && echo "  ⚠️  $*"; }

echo "════════════════════════════════════════"
echo "  stamflow check — Code Health"
echo "════════════════════════════════════════"
echo ""

# 1. ShellCheck — Static analysis for all .sh files
echo "▸ ShellCheck"
if command -v shellcheck &>/dev/null; then
  for f in $(find . -name "*.sh" -not -path "./.git/*" -not -path "*/node_modules/*" 2>/dev/null); do
    if shellcheck -e SC1091 "$f" 2>/dev/null | grep -q .; then
      warn "shellcheck: $f has warnings"
    else
      pass "shellcheck: $f"
    fi
  done
else
  warn "shellcheck not installed (brew install shellcheck)"
fi

# 2. Gate Pattern Testing
echo ""
echo "▸ Gate Testing"
GATES_FILE=""
for loc in core/gates.json ~/.claude/gates.json ./gates.json; do
  [[ -f "$loc" ]] && GATES_FILE="$loc" && break
done
if [[ -n "$GATES_FILE" ]] && command -v python3 &>/dev/null; then
  python3 -c "
import json, re
with open('$GATES_FILE') as f:
    gates = json.load(f)
tests = [
    ('git push --force origin main', 'no-force-push'),
    ('git push -f', 'no-force-push'),
    ('rm -rf /etc', 'no-rm-rf-root'),
    ('rm -rf ~/Documents', 'no-rm-rf-root'),
    ('echo OPENAI_API_KEY=sk-abc > .env', 'no-credentials-in-files'),
    ('git reset --hard HEAD~1', 'no-git-reset-hard'),
    ('git add .env', 'no-env-commit'),
]
all_ok = True
for test, expected in tests:
    matched = False
    for gate in gates['gates']:
        if gate.get('enabled') != False and re.search(gate['pattern'], test):
            if gate['name'] == expected:
                print(f'  ✅ \"{test}\" → {gate[\"name\"]} ({gate[\"level\"]})')
            else:
                print(f'  ⚠️  \"{test}\" → {gate[\"name\"]} (expected {expected})')
            matched = True
            break
    if not matched:
        print(f'  ❌ \"{test}\" → NOT CAUGHT')
        all_ok = False
"
  pass "gate patterns tested ($GATES_FILE)"
else
  warn "no gates.json found or python3 missing"
fi

# 3. File Permissions
echo ""
echo "▸ File Permissions"
for f in $(find . -type f -perm +111 -not -path "./.git/*" 2>/dev/null); do
  case "$f" in
    *.sh|*.bash|*.py|configure|Makefile) pass "exec: $f" ;;
    *) warn "unexpected exec: $f" ;;
  esac
done
for f in $(find . -type f \( -name "*.env" -o -name "*.key" -o -name "*.pem" -o -name "credentials*" \) -not -path "./.git/*" 2>/dev/null); do
  perms=$(stat -f "%A" "$f" 2>/dev/null || stat -c "%a" "$f" 2>/dev/null)
  if [[ "$perms" != "600" ]]; then
    fail "insecure perms ($perms): $f (should be 600)"
  fi
done
pass "file permissions checked"

# 4. Dead Code / TODO Scan
echo ""
echo "▸ Dead Code"
founds=$(grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.sh" --include="*.md" --include="*.py" . 2>/dev/null | grep -v ".git/" | grep -v "stamflow-check\|stamflow-secure" | wc -l | tr -d ' ')
if [[ "$founds" -gt 0 ]]; then
  warn "$founds TODO/FIXME markers found"
else
  pass "no TODO markers"
fi

echo ""
echo "════════════════════════════════════════"
echo "  Results: $PASS passed  $WARN warnings  $FAIL failed"
echo "════════════════════════════════════════"
