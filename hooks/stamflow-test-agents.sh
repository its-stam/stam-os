#!/usr/bin/env bash
# stamflow test --agents — Validate agent .md files
# Checks: frontmatter, required fields, naming, duplicates
set -euo pipefail

PASS=0; FAIL=0
pass() { ((PASS++)); echo "  ✅ $*"; }
fail() { ((FAIL++)); echo "  ❌ $*"; }

AGENT_DIRS=()
for d in agents/ ~/.claude/agents/ .opencode/agents/stam-os/; do
  [[ -d "$d" ]] && AGENT_DIRS+=("$d")
done

echo "════════════════════════════════════════"
echo "  stamflow test — Agents"
echo "════════════════════════════════════════"
echo ""

# 1. Frontmatter check: every agent must have --- with name + description
echo "▸ Frontmatter"
for dir in "${AGENT_DIRS[@]}"; do
  while IFS= read -r -d '' f; do
    name=$(basename "$f")
    # Must start with ---
    first=$(head -1 "$f" 2>/dev/null)
    if [[ "$first" != "---" ]]; then
      fail "$name: no frontmatter"
      continue
    fi
    # Must have name field
    if ! grep -q "^name:" "$f" 2>/dev/null; then
      fail "$name: missing 'name' field"
      continue
    fi
    # Must have description field
    if ! grep -q "^description:" "$f" 2>/dev/null; then
      fail "$name: missing 'description' field"
      continue
    fi
    pass "$name"
  done < <(find "$dir" -name "*.md" -type f -not -path "*/_*" -print0 2>/dev/null)
done

# 2. Duplicate check
echo ""
echo "▸ Duplicates"
declare -A seen
for dir in "${AGENT_DIRS[@]}"; do
  for f in "$dir"/*.md "$dir"/**/*.md; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f")
    if [[ -n "${seen[$name]:-}" ]]; then
      fail "duplicate: $name ($f vs ${seen[$name]})"
    else
      seen[$name]="$f"
    fi
  done
done
pass "duplicate check"

# 3. Size check (too small = broken, too large = too much context)
echo ""
echo "▸ Size"
for dir in "${AGENT_DIRS[@]}"; do
  for f in "$dir"/*.md; do
    [[ -f "$f" ]] || continue
    lines=$(wc -l < "$f" | tr -d ' ')
    name=$(basename "$f")
    if [[ $lines -lt 5 ]]; then
      fail "$name: too small ($lines lines)"
    elif [[ $lines -gt 500 ]]; then
      fail "$name: too large ($lines lines, will eat context)"
    fi
  done
done
pass "size check"

echo ""
echo "════════════════════════════════════════"
echo "  Result: $PASS passed  $FAIL failed"
echo "════════════════════════════════════════"
