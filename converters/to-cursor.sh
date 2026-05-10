#!/bin/bash
# stam-os → Cursor: converts agents to .cursor/rules/*.mdc
set -e
AGENTS_DIR="$(cd "$(dirname "$0")/../agents" && pwd)"
DEST="${PWD}/.cursor/rules"
mkdir -p "$DEST"
count=0
for dir in engineering design testing product specialized; do
  [[ -d "$AGENTS_DIR/$dir" ]] || continue
  for f in "$AGENTS_DIR/$dir"/*.md; do
    [[ -f "$f" ]] || continue
    slug="$(basename "$f" .md)"
    cat > "$DEST/$slug.mdc" << EOF
---
description: stam-os agent - see agents/$dir/$(basename "$f")
globs: ""
alwaysApply: false
---
$(cat "$f")
EOF
    ((count++))
  done
done
echo "✓ $count agents → $DEST"
