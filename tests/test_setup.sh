#!/bin/bash
# Runs setup.sh into a temp CLAUDE_CONFIG_DIR and checks it installs the
# expected files, is idempotent without --force, and overwrites with it.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP="$REPO_DIR/setup.sh"

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

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
TARGET="$WORKDIR/config"

CLAUDE_CONFIG_DIR="$TARGET" bash "$SETUP" > /dev/null 2>&1

for f in gates.json primer.md CLAUDE.md LAYERS.md KNOWLEDGE.md hooks/session-start.sh hooks/session-end.sh hooks/pre-action-gate.sh hooks/post-compact.sh; do
  [ -f "$TARGET/$f" ]
  check "installed: $f" $?
done

# --- idempotent without --force: mtimes must not change on a second run ---
BEFORE=$(stat -f "%m" "$TARGET/primer.md" 2>/dev/null || stat -c "%Y" "$TARGET/primer.md")
sleep 1
CLAUDE_CONFIG_DIR="$TARGET" bash "$SETUP" > /dev/null 2>&1
AFTER=$(stat -f "%m" "$TARGET/primer.md" 2>/dev/null || stat -c "%Y" "$TARGET/primer.md")
[ "$BEFORE" -eq "$AFTER" ]
check "second run without --force leaves primer.md untouched" $?

# --- --force overwrites ---
echo "modified by test" >> "$TARGET/primer.md"
CLAUDE_CONFIG_DIR="$TARGET" bash "$SETUP" --force > /dev/null 2>&1
grep -q "modified by test" "$TARGET/primer.md"
[ $? -ne 0 ]
check "force flag overwrites primer.md" $?

echo "setup: $PASS/$((PASS + FAIL)) passed"

[ "$FAIL" -eq 0 ]
