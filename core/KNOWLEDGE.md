# Knowledge

The L2 format for durable, sourced knowledge: raw sources compiled once
into linked articles, instead of re-synthesizing from scratch on every
question.

## Layout

```
knowledge/<domain>/<project>/
  raw/<topic>/YYYY-MM-DD-slug.md   immutable sources, one file per source
  wiki/index.md                    root index
  wiki/<topic>/index.md            topic index (one index.md per folder)
  wiki/<topic>/<concept>.md        compiled article
  wiki/log.md                      change log
```

One knowledge base per project. Never mix domains or projects in the
same base — a project's knowledge base is scoped, not global.

## Article frontmatter

Every article under `wiki/` is one Markdown file with YAML frontmatter.
Only `type` is required; the rest is recommended and what queries filter
on:

```yaml
---
type: <concept type, e.g. decision, term, dataset, meeting>
title: <title>
description: <one sentence, what this is about>
resource: <path to the raw source that backs this article>
tags: [topic, subtopic]
timestamp: 2026-01-01T00:00:00Z
---
```

Link between articles with normal Markdown links; that is the graph.

## Rules

- **Only sourced claims.** Every article's `resource` field must point at
  a raw source that exists. A claim without a source is a gap, and gaps
  are marked as gaps, not filled speculatively.
- **`raw/` is immutable.** Never rewritten after ingest; corrections go
  into a new source file or into the compiled article, not into the
  original.
- **Lint = every article has a `resource` that resolves.** That is the
  one deterministic check worth automating; everything else (stale
  claims, orphaned pages, missing cross-references) is a judgment call
  reported to a human, not auto-fixed.

## Why this format

Compilation happens once, at ingest time, not on every query. The
knowledge base is a growing artifact a human can read directly — same
motivation as the layering in `core/LAYERS.md`, applied to L2 instead
of L1.
