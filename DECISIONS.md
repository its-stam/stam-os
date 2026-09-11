# Decisions

One line per cut: what, why, where it still is. Everything below was
removed from the working tree in this pass; the content is retrievable
from the commit named, via `git show <hash>:<path>`.

- **`agents/`** (persona catalog) — third-party content, not this repo's
  contribution; the layering pattern this repo demonstrates does not need
  a bundled persona catalog to be useful. Last touched: `9f92278`.
- **`converters/`** (to-claude.sh, to-cursor.sh, to-opencode.sh) — format
  converters for the removed agent catalog; no longer has anything to
  convert. Last touched: `9f92278`.
- **`graphify/`** — an unrelated knowledge-graph feature, not part of the
  one sentence this repo proves. Last touched: `9f92278`.
- **`docs/TESTCATALOG.md`** — a manually maintained test catalog; the
  tests under `tests/` are now the catalog, and they run. Last touched:
  `237f95c`.
- **`core/lessons.md`**, **`core/retro-log.md`** — example content from a
  specific working session, not a reusable pattern. Last touched:
  `a3406ad`, `1ebbcbc`.
- **`core/workflow-epcc.md`** — a process document describing how one
  session was run, not part of the layering claim. Last touched:
  `9f92278`.
- **`skills/retrospective/`**, **`skills/example-project.md`** — a
  session-specific skill and a worked example tied to a project this
  repo doesn't name. Last touched: `1ebbcbc`, `9f92278`.
- **`recall/`** — a hybrid retrieval pipeline (BM25 + vector + graph,
  RRF fusion). Archived at its last commit. It solves a different
  problem (query-time recall over a corpus) than the layering this repo
  proves (what loads by default vs. on demand), and it was never
  evaluated against a benchmark. Returns to this repo only paired with
  an evaluation set and numbers, not before. Last touched: `85e4a9d`.
- **`BLUEPRINT.md`** — superseded by `core/LAYERS.md` and this file: the
  parts that were decisions live here, the parts that were architecture
  live in `core/LAYERS.md`, the parts that were an agent catalog and a
  multi-agent coordination plan are cut per the entries above. Last
  touched: `1ebbcbc`.
- **`hooks/stamflow-*.sh`** (nine scripts: check, dash, recall, secure,
  test-agents, test-gates, test, vet, view) — a dashboard and test-runner
  CLI for the removed agent catalog and recall pipeline. `tests/` now
  covers what `stamflow-test*.sh` covered, with assertions instead of a
  human reading a dashboard. Last touched: `faed496`, `43c1d04`,
  `85e4a9d`, `4ab7e2c`, `271dc14`.
- **External service dependency removed.** `session-start.sh`,
  `session-end.sh`, and `post-compact.sh` called out to a local HTTP
  service (`localhost:8888`) for behavioral-pattern recall. All three
  hooks are file-only now: `post-compact.sh` re-injects `primer.md`, the
  ledger tail, and the latest checkpoint instead, which is the
  three-file recovery the layering already claims — no external service
  needed to prove it.
