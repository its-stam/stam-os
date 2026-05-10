#!/bin/bash
# stam-os → OpenCode: copies agents to .opencode/agents/stam-os/
set -e
AGENTS_DIR="$(cd "$(dirname "$0")/../agents" && pwd)"
DEST="${PWD}/.opencode/agents/stam-os"
mkdir -p "$DEST"
count=0
for dir in engineering design testing product specialized; do
  [[ -d "$AGENTS_DIR/$dir" ]] || continue
  for f in "$AGENTS_DIR/$dir"/*.md; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    cp "$f" "$DEST/$name"
    ((count++))
  done
done
echo "✓ $count agents → $DEST"
