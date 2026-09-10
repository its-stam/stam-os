#!/bin/bash
# Layer 1: Fires on every session start
# Injects git context so the session starts oriented without re-reading history

echo "## Live Context (auto-injected)"
echo ""

if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "### Git Status"
  echo "**Branch:** $(git branch --show-current 2>/dev/null)"
  echo "**Last 5 commits:**"
  git log --oneline -5 2>/dev/null
  echo ""
  MODIFIED=$(git status --short 2>/dev/null)
  if [ -n "$MODIFIED" ]; then
    echo "**Modified files:**"
    echo "$MODIFIED"
    echo ""
  fi
fi

exit 0
