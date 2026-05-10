# stam-os — Operating System for AI Agents

> One config. Any AI tool. Never forgets. Never screws up.

**stam-os** is a unified standard for AI agent configuration. Works across Claude Code, OpenCode, Cursor, Gemini CLI, and more. No vendor lock-in. Open source. MIT.

Built by [Rustam Kohen](https://github.com/its-stam).

---

## What It Does

- **Never forgets** — 5-layer memory system (rules → state → hooks → memory → knowledge base)
- **Never screws up** — Pre-action gates block force-push, rm -rf, credential leaks at tool level
- **Learns** — 3x same mistake = auto-promotes from warn to block
- **Works anywhere** — Convert agents between Claude Code, OpenCode, Cursor, Gemini CLI
- **Graphify** — Input (code, docs, papers) → knowledge graph → Obsidian vault

---

## Architecture

```
LAYER 7: Swarm (optional)     ← ruflo-compatible
LAYER 6: Memory (optional)    ← AgentDB + HNSW
LAYER 5b: Graphify            ← Input → Knowledge Graph
LAYER 5a: Knowledge Base      ← Obsidian Vault
LAYER 4: Hooks                ← Session Lifecycle
LAYER 3: GATES                ← Pre-Action Enforcement
LAYER 2: State                ← Auto-Rewriting (primer.md)
LAYER 1: Rules                ← Immutable (CLAUDE.md)
LAYER 0: Agents               ← 41 Curated
```

---

## Quick Start

```bash
git clone https://github.com/its-stam/stam-os.git
cd stam-os
bash setup.sh
```

Setup auto-detects what's installed and skips conflicts. Nothing overwritten without asking.

### Commands

```
/stamflow plan    → Discovery interview → auto-select agents + gates
/stamflow dash    → Styled terminal dashboard with metrics
/stamflow view    → Agent office visualization (3×4 desk grid)
/stamflow vet     → Thorough exam (8 categories, 60+ checks, scored)
/stamflow test    → Code + Security + Agents + Gates (--all, --code, --security, --agents, --gates)
/stamflow graph   → Input → Knowledge Graph → Obsidian
/graphify         → Convert any input to knowledge graph
```

---

## What's Included

| Component | Source | What |
|-----------|--------|------|
| **Gates** | recall-stack | Pre-action enforcement (survives compaction) |
| **primer.md** | recall-stack | Auto-rewriting project state |
| **Agents** | agency-agents | 41 curated specialists |
| **Swarm** | ruflo (optional) | Multi-agent coordination |
| **Graphify** | built-in | Input → Knowledge Graph |
| **Obsidian** | templates included | Vault structure + daily notes |

---

## File Structure

```
stam-os/
├── core/           # Layer 1-3 (always, no deps)
├── hooks/          # Layer 4 (shell scripts)
├── agents/         # Layer 0 (41 curated agents)
├── converters/     # Multi-tool exporters (claude/opencode/cursor)
├── graphify/       # Layer 5b (knowledge graph)
├── skills/         # Domain skill templates (NDA-safe)
└── docs/           # Guides
```

---

## License

MIT — [Rustam Kohen](https://github.com/its-stam)
