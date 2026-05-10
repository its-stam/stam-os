#!/usr/bin/env bash
# stamflow test --gates — Fuzz gates.json with edge cases
set -euo pipefail

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✅ $*"; }
fail() { ((FAIL++)); echo "  ❌ $*"; }

GATES_FILE=""
for loc in core/gates.json ~/.claude/gates.json ./gates.json; do
  [[ -f "$loc" ]] && GATES_FILE="$loc" && break
done

echo "════════════════════════════════════════"
echo "  stamflow test — Gates (Fuzzing)"
echo "════════════════════════════════════════"
echo ""

[[ -z "$GATES_FILE" ]] && { fail "no gates.json found"; exit 1; }
[[ ! $(command -v python3) ]] && { fail "python3 required"; exit 1; }

python3 << PYEOF
import json, re

with open("$GATES_FILE") as f:
    gates = json.load(f)

print("▸ Gate Validation")
errors = 0
for gate in gates.get("gates", []):
    name = gate.get("name", "unnamed")
    if not gate.get("enabled", True):
        print(f"  ⚡ {name}: disabled (skipping)")
        continue
    # Check regex compiles
    try:
        compiled = re.compile(gate["pattern"])
    except re.error as e:
        print(f"  ❌ {name}: invalid regex — {e}")
        errors += 1
        continue
    print(f"  ✅ {name}: regex OK")

# Fuzz attacks
print("")
print("▸ Fuzzing: Edge Cases")

attacks = [
    # force-push variations
    ("git push --force origin main", "force-push"),
    ("git push -f", "force-push"),
    ("GIT PUSH --FORCE", "force-push (case)"),
    ("git\\tpush\\t-f", "force-push (tabs)"),
    ("git  push   --force", "force-push (spaces)"),
    # rm -rf variations
    ("rm -rf /etc/passwd", "rm-rf-root"),
    ("rm -rf /home/user", "rm-rf-root"),
    ("rm -Rf /var/log", "rm-rf-root (case)"),
    ("rm  -rf  /tmp", "rm-rf-root (spaces)"),
    # credential variations
    ("echo 'OPENAI_API_KEY=sk-abc123' > .env", "credentials"),
    ("export ANTHROPIC_API_KEY=sk-ant-xxx", "credentials"),
    ("Write file with DASHSCOPE_API_KEY in it", "credentials"),
    # env commit variations
    ("git add .env", "env-commit"),
    ("git add .env.production", "env-commit"),
    ("git add src/.env", "env-commit (subdir)"),
    # Should NOT match (safe)
    ("echo 'no-key-here' > .env.example", "SAFE"),
    ("git push origin main", "SAFE"),
    ("npm run clean", "SAFE"),
]

for attack, expected in attacks:
    caught = False
    for gate in gates["gates"]:
        if gate.get("enabled") != False and re.search(gate["pattern"], attack):
            level = gate.get("level", "?")
            if expected == "SAFE":
                print(f"  ❌ FALSE POSITIVE: \"{attack}\" caught by {gate['name']} ({level})")
                errors += 1
            else:
                print(f"  ✅ \"{attack}\" → {gate['name']} ({level})")
            caught = True
            break
    if not caught:
        if expected == "SAFE":
            print(f"  ✅ \"{attack}\" correctly passed")
        else:
            print(f"  ❌ NOT CAUGHT: \"{attack}\" ({expected})")
            errors += 1

print(f"\n  Errors: {errors}")
if errors > 0:
    print("  ❌ gate tests failed")
else:
    print("  ✅ all gates pass")
PYEOF

echo "════════════════════════════════════════"
echo "  Result: $PASS passed  $FAIL failed"
echo "════════════════════════════════════════"
