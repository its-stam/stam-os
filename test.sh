#!/bin/bash
# Runs every proof in tests/ and prints one final total.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TOTAL_PASS=0
TOTAL_FAIL=0
OVERALL=0

run_suite() {
  local name="$1"; shift
  echo "--- $name ---"
  local out suite_exit
  out=$("$@" 2>&1)
  suite_exit=$?
  echo "$out"
  echo ""
  local last
  last=$(echo "$out" | tail -1)
  local passed failed_total
  if [[ "$last" =~ ([0-9]+)/([0-9]+)\ passed ]]; then
    passed="${BASH_REMATCH[1]}"
    failed_total=$(( ${BASH_REMATCH[2]} - passed ))
    TOTAL_PASS=$((TOTAL_PASS + passed))
    TOTAL_FAIL=$((TOTAL_FAIL + failed_total))
  else
    OVERALL=1
  fi
  [ "$suite_exit" -eq 0 ] || OVERALL=1
}

run_suite "gates" bash tests/test_gates.sh
run_suite "post-compact" bash tests/test_post_compact.sh
run_suite "setup" bash tests/test_setup.sh
run_suite "session-end" bash tests/test_session_end.sh

echo "--- context-budget (unittest) ---"
BUDGET_OUT=$(python3 -m unittest tests.test_context_budget -v 2>&1)
echo "$BUDGET_OUT"
echo ""
BUDGET_RAN=$(echo "$BUDGET_OUT" | grep -oE "Ran [0-9]+ test" | grep -oE "[0-9]+")
if echo "$BUDGET_OUT" | grep -q "^OK"; then
  TOTAL_PASS=$((TOTAL_PASS + BUDGET_RAN))
else
  BUDGET_FAILED=$(echo "$BUDGET_OUT" | grep -oE "failures=[0-9]+" | grep -oE "[0-9]+")
  BUDGET_ERRORS=$(echo "$BUDGET_OUT" | grep -oE "errors=[0-9]+" | grep -oE "[0-9]+")
  BUDGET_FAILED=${BUDGET_FAILED:-0}
  BUDGET_ERRORS=${BUDGET_ERRORS:-0}
  BUDGET_FAIL_TOTAL=$((BUDGET_FAILED + BUDGET_ERRORS))
  TOTAL_PASS=$((TOTAL_PASS + BUDGET_RAN - BUDGET_FAIL_TOTAL))
  TOTAL_FAIL=$((TOTAL_FAIL + BUDGET_FAIL_TOTAL))
fi

echo "TOTAL: $TOTAL_PASS passed, $TOTAL_FAIL failed"

if [ "$TOTAL_FAIL" -ne 0 ] || [ "$OVERALL" -ne 0 ]; then
  exit 1
fi
exit 0
