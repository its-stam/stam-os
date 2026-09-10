# Context Management

## The Problem
Every file read, every command run, every message — it all fills the context window.
When full, automatic compaction happens. Details CAN be lost.

## Commands
- `/compact` — Summarize current session, free space, keep working on same feature
- `/clear` — Wipe everything, start fresh (new feature = new session)
- `/context` — Check context usage: size, categories, breakdown

## When to Use Which

| Command | Use When | Don't Use When |
|---------|----------|---------------|
| `/compact` | Working on same feature, nearing context limit | Starting a new feature (old context = bias) |
| `/clear` | Starting a new feature from scratch | You need to keep context of current work |

## What Survives What

| Event | CLAUDE.md | primer.md | Gates | Hooks |
|-------|-----------|-----------|-------|-------|
| `/compact` | ✅ | ✅ | ✅ | ✅ (PostCompact re-injects) |
| `/clear` | ✅ | ✅ (last saved state) | ✅ | ❌ (new session) |
| Auto-compact | ✅ | ✅ | ✅ | ✅ |
| Crash | ✅ | ✅ | ✅ | ❌ |

## Tips for Saving Context Space

1. **Be specific.** A vague prompt seems smaller but costs MORE context — Claude explores more, reasons more, uses more tokens.

2. **Manage tools.** MCP servers load all tools into context by default. Turn off unrelated servers. Use Skills instead — they don't pre-load tools.

3. **Use subagents.** They run in parallel with separate context window. Ask "where are the endpoints?" → subagent returns summary, not full context.

4. **Put learnings in CLAUDE.md.** Anything Claude needs across sessions should be in rules, not rediscovered every time.

## Integration with the layers (see core/LAYERS.md)

- **L1 (primer.md)** — Survives `/clear` and `/compact`. Always has current state.
- **L3 (post-compact hook)** — Re-injects primer, ledger tail, and the latest checkpoint after compaction.
- **L2 (Gates)** — Survive everything (hook-level, not prompt-level).

## Anti-Patterns
- ❌ Vaguer prompts to "save tokens" — actually costs more
- ❌ Keeping all MCP servers on when working on unrelated task
- ❌ Not using subagents for exploration tasks
- ❌ Manually reminding Claude of things in CLAUDE.md
