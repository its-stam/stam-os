#!/usr/bin/env python3
"""Unit tests for bin/context-budget.py, run against pre-built fixtures.

Fixtures live under tests/fixtures/:
  monolithic/           one CLAUDE.md with everything inline (~600 lines)
  layered/              same total content, split across CLAUDE.md (40
                         lines), primer.md (60 lines), rules/ (3 files),
                         and memory/ (the rest, on demand)
  primer-over-budget/   a 130-line primer.md, must flag and exit 1
"""

import importlib.util
import io
import json
import os
import sys
import unittest
from contextlib import redirect_stdout

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(HERE)
SCRIPT_PATH = os.path.join(REPO_ROOT, "bin", "context-budget.py")
FIXTURES = os.path.join(HERE, "fixtures")

spec = importlib.util.spec_from_file_location("context_budget", SCRIPT_PATH)
context_budget = importlib.util.module_from_spec(spec)
spec.loader.exec_module(context_budget)


def run_json(config_dir):
    buf = io.StringIO()
    old_argv = sys.argv
    sys.argv = ["context-budget.py", config_dir, "--json"]
    try:
        with redirect_stdout(buf):
            exit_code = context_budget.main()
    finally:
        sys.argv = old_argv
    return json.loads(buf.getvalue()), exit_code


class TestContextBudget(unittest.TestCase):
    def test_layered_loads_far_less_at_start_than_monolithic(self):
        mono, _ = run_json(os.path.join(FIXTURES, "monolithic"))
        layered, _ = run_json(os.path.join(FIXTURES, "layered"))
        self.assertGreater(
            mono["loaded_at_start_bytes"],
            3 * layered["loaded_at_start_bytes"],
            "monolithic start-load should be more than 3x the layered start-load",
        )

    def test_total_corpus_bytes_equal_within_5_percent(self):
        mono, _ = run_json(os.path.join(FIXTURES, "monolithic"))
        layered, _ = run_json(os.path.join(FIXTURES, "layered"))
        mono_total = mono["loaded_at_start_bytes"] + mono["available_on_demand_bytes"]
        layered_total = layered["loaded_at_start_bytes"] + layered["available_on_demand_bytes"]
        diff_ratio = abs(mono_total - layered_total) / mono_total
        self.assertLessEqual(diff_ratio, 0.05, f"corpora differ by {diff_ratio:.1%}, expected <=5%")

    def test_oversized_primer_flags_and_exits_1(self):
        result, exit_code = run_json(os.path.join(FIXTURES, "primer-over-budget"))
        self.assertEqual(exit_code, 1)
        self.assertTrue(any("primer.md" in f and "110" in f for f in result["flags"]))

    def test_nested_project_memory_index_flags_and_exits_1(self):
        result, exit_code = run_json(os.path.join(FIXTURES, "memory-index-over-budget"))
        self.assertEqual(exit_code, 1)
        self.assertTrue(any("MEMORY.md" in f for f in result["flags"]))


if __name__ == "__main__":
    unittest.main()
