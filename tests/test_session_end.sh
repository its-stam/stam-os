#!/bin/bash
# Proves session-end.sh's auto-promotion: the same lesson repeated 3x in a
# project's lessons.md gets promoted to a warn-level "auto-" gate, 2x does
# not, and re-running the hook never creates a duplicate gate.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_DIR/hooks/session-end.sh"

PASS=0
FAIL=0

check() {
  local desc="$1" condition="$2"
  if [ "$condition" -eq 0 ]; then
    echo "  [pass] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc"
    FAIL=$((FAIL + 1))
  fi
}

count_auto_gates() {
  python3 -c "
import json
with open('$1') as f:
    gates = json.load(f)
print(sum(1 for g in gates.get('gates', []) if g.get('name', '').startswith('auto-')))
"
}

make_fixture() {
  # $1 = target config dir, $2 = number of repeated lesson lines
  mkdir -p "$1/projects/x"
  cp "$SCRIPT_DIR/fixtures/config/gates.json" "$1/gates.json"
  : > "$1/projects/x/lessons.md"
  local i=0
  while [ "$i" -lt "$2" ]; do
    echo "[2026-01-0$((i + 1))] | forgot to check the fixture | always check the fixture first" >> "$1/projects/x/lessons.md"
    i=$((i + 1))
  done
}

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# --- Case A: 3x the same rule -> exactly one auto- gate, warn level ---
A="$WORKDIR/three-times"
make_fixture "$A" 3
CLAUDE_CONFIG_DIR="$A" "$HOOK" > /dev/null 2>&1
COUNT_A=$(count_auto_gates "$A/gates.json")
[ "$COUNT_A" -eq 1 ]
check "3x same rule promotes exactly one auto- gate" $?

LEVEL_A=$(python3 -c "
import json
with open('$A/gates.json') as f:
    gates = json.load(f)
g = [x for x in gates.get('gates', []) if x.get('name', '').startswith('auto-')][0]
print(g.get('level'))
")
[ "$LEVEL_A" = "warn" ]
check "promoted gate has level warn" $?

# --- second run must not create a duplicate ---
CLAUDE_CONFIG_DIR="$A" "$HOOK" > /dev/null 2>&1
COUNT_A2=$(count_auto_gates "$A/gates.json")
[ "$COUNT_A2" -eq 1 ]
check "second run does not create a duplicate auto- gate" $?

# --- Case B: 2x the same rule -> no auto- gate ---
B="$WORKDIR/two-times"
make_fixture "$B" 2
CLAUDE_CONFIG_DIR="$B" "$HOOK" > /dev/null 2>&1
COUNT_B=$(count_auto_gates "$B/gates.json")
[ "$COUNT_B" -eq 0 ]
check "2x same rule creates no auto- gate" $?

echo "session-end: $PASS/$((PASS + FAIL)) passed"

[ "$FAIL" -eq 0 ]
