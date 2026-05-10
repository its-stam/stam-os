#!/usr/bin/env bash
# stamflow test — Unified test runner
# Usage: bash stamflow-test.sh [--all] [--code] [--security] [--agents] [--gates]
set -euo pipefail

MODE="${1:---all}"

run_test() {
  local label="$1" script="$2"
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  $label"
  echo "════════════════════════════════════════════════════════"
  bash "$script" --quiet 2>&1 | grep -E "✅|❌|⚠️|Result|Errors:" || true
}

case "$MODE" in
  --all)
    run_test "1/4: Code Health"    "$(dirname "$0")/stamflow-check.sh"
    run_test "2/4: Security Audit" "$(dirname "$0")/stamflow-secure.sh"
    run_test "3/4: Agents"         "$(dirname "$0")/stamflow-test-agents.sh"
    run_test "4/4: Gates (Fuzzing)" "$(dirname "$0")/stamflow-test-gates.sh"
    ;;
  --code)
    run_test "Code Health" "$(dirname "$0")/stamflow-check.sh"
    ;;
  --security)
    run_test "Security Audit" "$(dirname "$0")/stamflow-secure.sh"
    ;;
  --agents)
    run_test "Agents" "$(dirname "$0")/stamflow-test-agents.sh"
    ;;
  --gates)
    run_test "Gates (Fuzzing)" "$(dirname "$0")/stamflow-test-gates.sh"
    ;;
  *)
    echo "Usage: /stamflow test [--all|--code|--security|--agents|--gates]"
    exit 1
    ;;
esac

echo ""
echo "════════════════════════════════════════════════════════"
echo "  stamflow test — Complete"
echo "════════════════════════════════════════════════════════"
