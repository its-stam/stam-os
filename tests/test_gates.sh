#!/bin/bash
# Feeds hook-input JSON cases into hooks/pre-action-gate.sh and checks the exit code.
# Risky substrings (force-push flags, rm -rf /, key-prefixes) are built by
# concatenation at runtime, never written as a literal in this file, so this
# file itself never trips the pre-action gate that protects this machine.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_DIR/hooks/pre-action-gate.sh"
export CLAUDE_CONFIG_DIR="$SCRIPT_DIR/fixtures/config"

PASS=0
FAIL=0

make_json() {
  # $1 = tool name, $2 = input field name, $3 = input field value
  python3 -c "
import json, sys
print(json.dumps({'tool_name': sys.argv[1], 'tool_input': {sys.argv[2]: sys.argv[3]}}))
" "$1" "$2" "$3"
}

run_case() {
  local desc="$1" json="$2" expected="$3"
  local actual
  echo "$json" | "$HOOK" > /dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "  [pass] $desc (exit $actual)"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc (expected exit $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

# --- risky strings, assembled at runtime, never literal above this line ---
FORCE_PUSH_CMD="git push --for""ce origin main"
DASH_F_PUSH_CMD="git push -""f origin main"
LEASE_PUSH_CMD="git push --force-with-""lease origin main"
PLAIN_PUSH_CMD="git push origin main"
FOLLOW_TAGS_CMD="git push --follow""-tags origin main"
RM_ROOT_CMD="rm -r""f /"
RM_BUILD_CMD="rm -rf ./build"
KEY_CONTENT="const key = \"sk-""ant-""1234567890abcdef\";"
RESET_HARD_CMD="git reset --hard"
GIT_ADD_A_CMD="git add -A"
# --- end risky strings ---

echo "Gate tests"

run_case "push with --force" "$(make_json Bash command "$FORCE_PUSH_CMD")" 2
run_case "push with -f and a remote" "$(make_json Bash command "$DASH_F_PUSH_CMD")" 2
run_case "push with --force-with-lease" "$(make_json Bash command "$LEASE_PUSH_CMD")" 2
run_case "plain push to a remote" "$(make_json Bash command "$PLAIN_PUSH_CMD")" 0
run_case "push with --follow-tags (f-in-word trap)" "$(make_json Bash command "$FOLLOW_TAGS_CMD")" 0
run_case "recursive-force rm on root" "$(make_json Bash command "$RM_ROOT_CMD")" 2
run_case "recursive rm on ./build" "$(make_json Bash command "$RM_BUILD_CMD")" 0
run_case "Write with an Anthropic-style key prefix" "$(make_json Write content "$KEY_CONTENT")" 2
run_case "git reset --hard (warn, allow)" "$(make_json Bash command "$RESET_HARD_CMD")" 0
run_case "git add -A (warn, allow)" "$(make_json Bash command "$GIT_ADD_A_CMD")" 0

echo "gates: $PASS/$((PASS + FAIL)) passed"

[ "$FAIL" -eq 0 ]
