# stam-os

A file layout that keeps an agent's session context small and recoverable:
routing files stay within a budget, detail lives one layer down, and a
session resumes after a crash or compaction from three files.

## Results

Numbers from `./test.sh`, and from `bin/context-budget.py` run against
the synthetic fixtures in `tests/fixtures/` plus one real config.

| Measurement | Value |
|---|---|
| Start-load, synthetic fixture, monolithic (one file, everything inline) | 33,659 bytes |
| Start-load, synthetic fixture, layered (same content, split by layer) | 7,740 bytes |
| Ratio | 4.35x smaller |
| Total corpus, monolithic vs. layered fixture | 33,659 vs. 34,620 bytes (2.8% apart) |
| Author's own config, live run (2026-09-11): loaded at start | 112,870 bytes |
| Author's own config, live run (2026-09-11): available on demand | 3,346,950 bytes |
| Author's own config, live run (2026-09-11): flags raised | 1 |
| Gate test cases (`tests/test_gates.sh`) | 10/10 passed |
| Three-file recovery test (`tests/test_post_compact.sh`) | 8/8 passed |
| Installer test (`tests/test_setup.sh`) | 11/11 passed |
| Auto-promotion test (`tests/test_session_end.sh`) | 4/4 passed |
| Budget unit tests (`tests/test_context_budget.py`) | 4/4 passed |
| `./test.sh` | 37 passed, 0 failed |

Run it yourself: `./test.sh`.

## How it works

Four layers, each with its own budget:

| Layer | Contents | Budget |
|---|---|---|
| L0 Identity | `CLAUDE.md` | <= 200 lines |
| L1 Routing/State | `primer.md` | ~100 lines, hard cap 110 |
| L2 Reference | `rules/`, `memory/`, `knowledge/` | <= 150 lines per file |
| L3 Working artifacts | `coordination/`, checkpoints, journals | loaded on demand only |

Five rules (full text in `core/LAYERS.md`):

1. Routing files never carry working detail.
2. Hard invariants live in L0/L2, never only in L1 (L1 rotates).
3. Volatile state never lives in L2 (it would go stale silently).
4. Every intermediate result is a readable, editable file.
5. Three-file recovery: `primer.md` + the working ledger + the latest
   checkpoint must be enough to resume a session.

`hooks/post-compact.sh` proves rule 5 directly: after compaction it
re-injects exactly those three sources, plus the active safety gates,
using only local file reads (`tests/test_post_compact.sh` stubs `curl`
to confirm zero network calls).

`bin/context-budget.py` measures what layering costs and saves: it
resolves a `CLAUDE.md`, follows every `@import` recursively, adds
`rules/*.md` and every `MEMORY.md` (capped at 24,576 bytes each,
matching what the host actually loads), and reports what a session
loads at start versus what stays available on demand. It flags an
oversized `primer.md`, `CLAUDE.md`, or rule file and exits 1.

## What's in the repo

```
core/
  CLAUDE.md              L0 identity + agent rules
  primer.md               L1 routing/state template
  LAYERS.md                the layer model (this README's basis)
  KNOWLEDGE.md              the L2 knowledge-base format
  gates.json                 pre-action safety gates
  context-management.md       when to /compact vs /clear
  planmode.md                  discovery-interview workflow
hooks/
  session-start.sh        injects git context at session start
  session-end.sh           promotes repeated lessons to gates
  pre-action-gate.sh        enforces gates.json before a tool runs
  post-compact.sh            three-file recovery re-injection
bin/
  context-budget.py       measures start-load vs. on-demand bytes
tests/
  test_gates.sh            10 gate cases, exit-code assertions
  test_post_compact.sh      recovery + no-network assertions
  test_setup.sh              installer idempotency + --force
  test_session_end.sh         auto-promotion to a gate after 3x
  test_context_budget.py        layering ratio + flag assertions
  fixtures/                      synthetic: monolithic/, layered/,
                                  primer-over-budget/,
                                  memory-index-over-budget/
setup.sh                  installer
test.sh                    runs every proof, prints one total
```

## Setup

```
bash setup.sh              # installs into $CLAUDE_CONFIG_DIR or ~/.claude
bash setup.sh --force      # overwrite existing files
```

Run the tests:

```
./test.sh
```

Check your own config against the budget:

```
python3 bin/context-budget.py ~/.claude
python3 bin/context-budget.py ~/.claude --json
```

## License

MIT, see `LICENSE`.
