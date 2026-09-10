# Layers

A file layout that keeps an agent's session context small and recoverable:
routing files stay within a budget, detail lives one layer down, and a
session resumes after a crash or compaction from three files.

## The four layers

| Layer | Contents | Changes | Budget |
|---|---|---|---|
| L0 Identity | `CLAUDE.md` | Stable, rarely edited | <= 200 lines |
| L1 Routing/State | `primer.md` | Current state, next step, blockers only | ~100 lines, hard cap 110 |
| L2 Reference | `rules/`, `memory/`, `knowledge/` | Stable, loaded on demand or via a short index | <= 150 lines per file |
| L3 Working artifacts | `coordination/`, `checkpoints/`, journals | Every run | Never loaded wholesale |

- **L0 Identity.** Where am I, what always applies. Bootstraps every session.
- **L1 Routing/State.** Current project, what's done, next step, open
  blockers. Nothing else. It rotates, so nothing that must survive
  indefinitely lives only here.
- **L2 Reference (stable).** Conventions that hold across sessions:
  rules, project memory, the knowledge base. Loaded on demand, not
  by default.
- **L3 Working artifacts (per run).** Coordination ledgers, checkpoints,
  journals. Change every run, read selectively, never dumped into
  context wholesale.

## Rules

1. Routing files never carry working detail. If L1 grows, the detail moves
   one layer down (L2 or L3) and L1 keeps a one-line pointer.
2. Hard invariants live in L0 or L2, never only in L1 — L1 rotates and
   would silently drop them.
3. Volatile state never lives in L2 — it would go stale silently and no
   one would notice until it was acted on.
4. Every intermediate result is a readable file a human can edit before
   the next step reads it. No result lives only inside a running process.
5. Three-file recovery: `primer.md` + the working ledger + the latest
   checkpoint must be enough to resume a session after a crash or
   compaction. If resuming needs more than three files, the state is too
   complex — split it, don't add a fourth file to the recovery path.

## Why

Irrelevant context in the window degrades work on the relevant part
("lost in the middle"). Layering is prevention, not later compression:
a session should never load more than the layer it is currently working
in requires. `bin/context-budget.py` measures this directly — see
`tests/test_context_budget.py` for the fixture numbers and `README.md`
for the real run output.
