#!/bin/bash
# Proves three-file recovery: post-compact.sh must re-inject primer + ledger
# tail + latest checkpoint header from CLAUDE_CONFIG_DIR, and must not touch
# the network to do it.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_DIR/hooks/post-compact.sh"

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

FIXTURE="$WORKDIR/config"
REPO="$WORKDIR/repo"
mkdir -p "$FIXTURE/coordination" "$FIXTURE/checkpoints" "$REPO"

cat > "$FIXTURE/primer.md" << 'EOF'
# Primer
Active project: demo
Next step: run tests
EOF

cat > "$FIXTURE/coordination/ledger.md" << 'EOF'
- 2026-01-01T00:00:00Z | agent-a | repo-x | main | integrator | CLAIM | testing
- 2026-01-01T00:05:00Z | agent-a | repo-x | - | integrator | RELEASE | done
EOF

cat > "$FIXTURE/checkpoints/20260101-000000.md" << 'EOF'
# Checkpoint 2026-01-01
State: demo checkpoint for the recovery test
EOF

cp "$SCRIPT_DIR/fixtures/config/gates.json" "$FIXTURE/gates.json"

(cd "$REPO" && git init -q)

# --- network guard: a stub curl on PATH that must never be called ---
MARKER="$WORKDIR/curl-was-called"
STUBDIR="$WORKDIR/stub-bin"
mkdir -p "$STUBDIR"
cat > "$STUBDIR/curl" << EOF
#!/bin/bash
touch "$MARKER"
exit 99
EOF
chmod +x "$STUBDIR/curl"

OUTPUT=$(cd "$REPO" && PATH="$STUBDIR:$PATH" CLAUDE_CONFIG_DIR="$FIXTURE" "$HOOK")
EXIT_CODE=$?

echo "$OUTPUT" | grep -q "### Primer"; check "output contains primer section" $?
echo "$OUTPUT" | grep -q "### Ledger"; check "output contains ledger section" $?
echo "$OUTPUT" | grep -q "### Latest Checkpoint"; check "output contains latest checkpoint header" $?
echo "$OUTPUT" | grep -q "### Active Gates"; check "output contains active block-gates list" $?
echo "$OUTPUT" | grep -q "run tests"; check "primer content present" $?
echo "$OUTPUT" | grep -q "Checkpoint 2026-01-01"; check "checkpoint content present" $?

[ "$EXIT_CODE" -eq 0 ]; check "hook exits 0" $?
[ ! -f "$MARKER" ]; check "no network call (curl stub never invoked)" $?

echo "post-compact: $PASS/$((PASS + FAIL)) passed"

[ "$FAIL" -eq 0 ]
