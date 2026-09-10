#!/bin/bash
# Layer 4: Fires on session end
# Auto-tracks failures from the lessons file and promotes to a gate after 3 occurrences

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GATES_FILE="$CONFIG_DIR/gates.json"
FAILURES_FILE="$CONFIG_DIR/failures.json"

[ ! -f "$GATES_FILE" ] && exit 0
[ ! -f "$FAILURES_FILE" ] && echo '{"failures":{}}' > "$FAILURES_FILE"

CONFIG_DIR="$CONFIG_DIR" python3 << 'PYEOF'
import json, re, os, sys

config_dir = os.environ["CONFIG_DIR"]
failures_file = os.path.join(config_dir, "failures.json")
gates_file = os.path.join(config_dir, "gates.json")

# Find all lessons files across projects
lessons_paths = []
projects_dir = os.path.join(config_dir, "projects")
if os.path.isdir(projects_dir):
    for root, dirs, files in os.walk(projects_dir):
        for name in ("lessons.md",):
            if name in files:
                lessons_paths.append(os.path.join(root, name))

if not lessons_paths:
    sys.exit(0)

try:
    with open(failures_file) as f:
        data = json.load(f)
except:
    data = {"failures": {}}

try:
    with open(gates_file) as f:
        gates = json.load(f)
except:
    sys.exit(0)

changed = False
for lpath in lessons_paths:
    try:
        with open(lpath) as f:
            lines = f.readlines()
    except:
        continue

    for line in lines:
        # Match: [date] | what went wrong | rule to follow
        m = re.match(r'\[([^\]]+)\]\s*\|\s*(.+?)\s*\|\s*(.+)', line.strip())
        if not m:
            continue

        lesson_date, mistake, rule = m.groups()
        key = re.sub(r'[^a-z0-9 ]', '', rule.lower()).strip()[:50]
        if not key:
            continue

        if key not in data["failures"]:
            data["failures"][key] = {"count": 0, "rule": rule.strip(), "mistake": mistake.strip(), "promoted": False}
        data["failures"][key]["count"] += 1
        changed = True

        # Auto-promote to warning gate after 3 occurrences
        if data["failures"][key]["count"] >= 3 and not data["failures"][key]["promoted"]:
            gate_name = "auto-" + key.replace(" ", "-")[:30]
            existing = [g for g in gates.get("gates", []) if g.get("name") == gate_name]
            if not existing:
                gates["gates"].append({
                    "name": gate_name,
                    "tool": "*",
                    "pattern": "",
                    "level": "warn",
                    "message": "Repeated mistake (3x): " + rule.strip()[:80],
                    "enabled": True,
                    "auto": True
                })
                data["failures"][key]["promoted"] = True

if changed:
    with open(failures_file, 'w') as f:
        json.dump(data, f, indent=2)
    with open(gates_file, 'w') as f:
        json.dump(gates, f, indent=2)

PYEOF

exit 0
