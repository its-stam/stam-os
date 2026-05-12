#!/usr/bin/env bash
# stamflow recall — Hybrid retrieval: BM25 + Vector + Graph → RRF fusion
# Usage: /stamflow recall <query> | --rebuild | --status | --mode hybrid|manual
set -euo pipefail

RECALL_DIR="$(cd "$(dirname "$0")/../recall" && pwd)"
RECALL_SH="$RECALL_DIR/recall.sh"

if [[ ! -f "$RECALL_SH" ]]; then
  echo "recall.sh not found at $RECALL_SH"
  exit 1
fi

chmod +x "$RECALL_SH" 2>/dev/null
bash "$RECALL_SH" "$@"
