#!/bin/bash
# Pre-Action Gate -- blocks known-bad patterns before tool execution
# Exit 0 = allow, Exit 2 = block

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GATES_FILE="$CONFIG_DIR/gates.json"
[ ! -f "$GATES_FILE" ] && exit 0

INPUT=$(cat)

RESULT=$(echo "$INPUT" | GATES_FILE="$GATES_FILE" python3 -c "
import json, sys, re, os

try:
    hook_input = json.load(sys.stdin)
except:
    sys.exit(0)

tool = hook_input.get('tool_name', '')
tool_input = json.dumps(hook_input.get('tool_input', {}))

gates_path = os.environ['GATES_FILE']
with open(gates_path) as f:
    gates = json.load(f)

blocks = []
warns = []

for gate in gates.get('gates', []):
    if not gate.get('enabled', True):
        continue
    tool_pattern = gate.get('tool', '*')
    if tool_pattern != '*' and tool_pattern != tool:
        if not re.search(tool_pattern, tool):
            continue
    input_pattern = gate.get('pattern', '')
    if input_pattern and not re.search(input_pattern, tool_input, re.IGNORECASE):
        continue
    level = gate.get('level', 'warn')
    message = gate.get('message', 'Blocked by gate')
    if level == 'block':
        blocks.append(message)
    else:
        warns.append(message)

if blocks:
    print(f\"BLOCK|{'; '.join(blocks)}\")
elif warns:
    print(f\"WARN|{'; '.join(warns)}\")
else:
    print('ALLOW|')
" 2>/dev/null)

ACTION=$(echo "$RESULT" | cut -d'|' -f1)
MESSAGE=$(echo "$RESULT" | cut -d'|' -f2-)

if [ "$ACTION" = "BLOCK" ]; then
    echo "GATE BLOCKED: $MESSAGE" >&2
    exit 2
elif [ "$ACTION" = "WARN" ]; then
    echo "GATE WARNING: $MESSAGE" >&2
fi

exit 0
