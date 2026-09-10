#!/bin/bash
# Fires after context compaction -- proves three-file recovery.
# A session must be able to resume from just: primer + ledger + latest checkpoint.
# No network calls: everything here is local file reads.

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

echo "## Post-Compaction Re-injection"
echo ""

# --- L1: Primer (routing/state) ---
PRIMER="$CONFIG_DIR/primer.md"
if [ -f "$PRIMER" ]; then
  echo "### Primer"
  cat "$PRIMER"
  echo ""
fi

# --- L3: Ledger (working artifact, tail only) ---
LEDGER="$CONFIG_DIR/coordination/ledger.md"
if [ -f "$LEDGER" ]; then
  echo "### Ledger (tail)"
  tail -10 "$LEDGER"
  echo ""
fi

# --- L3: Latest checkpoint (header only) ---
CHECKPOINT_DIR="$CONFIG_DIR/checkpoints"
if [ -d "$CHECKPOINT_DIR" ]; then
  LATEST=$(ls -1 "$CHECKPOINT_DIR" 2>/dev/null | sort | tail -1)
  if [ -n "$LATEST" ]; then
    echo "### Latest Checkpoint ($LATEST)"
    head -5 "$CHECKPOINT_DIR/$LATEST"
    echo ""
  fi
fi

# --- L2: Active block-level gates (reminders) ---
GATES_FILE="$CONFIG_DIR/gates.json"
if [ -f "$GATES_FILE" ]; then
  GATE_LIST=$(GATES_FILE="$GATES_FILE" python3 -c "
import json, os
with open(os.environ['GATES_FILE']) as f:
    gates = json.load(f)
for g in gates.get('gates', []):
    if g.get('enabled', True) and g.get('level') == 'block':
        print(f'- BLOCKED: {g[\"message\"]}')
" 2>/dev/null)

  if [ -n "$GATE_LIST" ]; then
    echo "### Active Gates (enforced by hooks)"
    echo "$GATE_LIST"
    echo ""
  fi
fi

exit 0
