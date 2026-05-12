#!/bin/bash
# recall — stam-os Layer 6: Hybrid retrieval (BM25 + Vector + Graph → RRF fusion)
# Usage: recall <query> | --rebuild | --status | --mode hybrid|manual | --watch

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STAM_OS_DIR="$(dirname "$SCRIPT_DIR")"

cd "$STAM_OS_DIR" && /usr/local/bin/python3.11 -m recall.cli "$@"
