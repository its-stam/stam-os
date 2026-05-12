# stam-os — Blueprint

## Mission
**One config. Any AI tool. Never forgets. Never screws up.**

Ein einheitlicher Standard für AI-Agent-Konfiguration, der über Claude Code, OpenCode, Cursor und andere Tools hinweg funktioniert. Kein Vendor Lock-in. Open Source. MIT.

## DNA — Was wir von jedem übernehmen

| Quelle | Bestes Feature | Wie wir's übernehmen |
|--------|---------------|---------------------|
| **recall-stack** | Gates + primer.md + Self-Learning | Kern-Mechanismus |
| **agency-agents** | 184 spezialisierte Personas | Agenten-Bibliothek (konvertiert für alle Tools) |
| **ruflo** | Swarm-Orchestrierung + MCP + Memory | Optionales Plugin (Layer 6-7) |
| **gstack** | Browser QA + Screenshot-Testing | Optionaler Skill |
| **graphify** | Input → Knowledge Graph → HTML+JSON | Layer 5b — Erkenntnis-Pipeline |
| **Obsidian** | Multi-Vault, Daily Notes, Templates | Layer 5a — Persistent Knowledge |
| **Unser Setup** | Multi-Vault Obsidian, Graphify-Integration, 7 konfliktfreie Hooks | Lokale Referenz-Implementierung |

## Architektur — 7 Layer

```
┌─────────────────────────────────────────────────┐
│ LAYER 7: Swarm (optional)                       │
│ Multi-Agent-Koordination, Consensus, Federation │
│ → ruflo-kompatibel, aber standalone lauffähig   │
├─────────────────────────────────────────────────┤
│ LAYER 6: Memory (optional)                      │
│ AgentDB + HNSW, Hindsight, Vector Search        │
│ → ruflo/AgentDB oder Hindsight Docker           │
├─────────────────────────────────────────────────┤
│ LAYER 5b: Graphify (Input → Knowledge Graph)    │
│ Code, Docs, Papers, Bilder → Clustered Graph    │
│ → HTML + JSON + Audit-Report                    │
│ → Output fließt direkt in Obsidian Vault        │
├─────────────────────────────────────────────────┤
│ LAYER 5a: Knowledge Base (Obsidian)             │
│ Obsidian Vault, Projekt-Docs, NDA-geschützt     │
│ → Shell-Alias mount, .gitignore für Secrets     │
│ → Graphify-Output als .md im Vault speichern    │
├─────────────────────────────────────────────────┤
│ LAYER 4: Hooks (Session Lifecycle)              │
│ SessionStart, PreToolUse, PostCompact, End      │
│ → Bash-Scripts, konfliktfrei mit Ruflo-Hooks    │
├─────────────────────────────────────────────────┤
│ LAYER 3: GATES (Pre-Action Enforcement)         │
│ Blockiert force-push, rm -rf, Credential-Leaks  │
│ → gates.json + pre-action-gate.sh               │
│ → 3x gleicher Fehler = auto-promote warn→block  │
├─────────────────────────────────────────────────┤
│ LAYER 2: State (Auto-Rewriting)                 │
│ primer.md — Projekt-Status, nächster Task       │
│ retro-log.md — Session-Audit, akkumuliert       │
│ → Schreibt nach jedem Task, überlebt Crashes    │
├─────────────────────────────────────────────────┤
│ LAYER 1: Rules (Immutable)                      │
│ CLAUDE.md — Persönlichkeit, Präferenzen, Import │
│ → @primer.md, @MEMORY.md, Konventionen          │
├─────────────────────────────────────────────────┤
│ LAYER 0: Agents (Personas)                      │
│ 184+ spezialisierte Agenten in .md              │
│ → Konvertierbar für Claude/OpenCode/Cursor/...  │
└─────────────────────────────────────────────────┘
```

## File Structure (Repo)

```
agent-os/
├── README.md                    # Was, Warum, Quick Start
├── BLUEPRINT.md                 # Diese Architektur-Doku
├── LICENSE                      # MIT
├── setup.sh                     # One-Command Installer
│
├── core/                        # Layer 1-3 (immer, keine Dependencies)
│   ├── CLAUDE.md                # Master-Regeln
│   ├── primer.md                # Auto-Rewriting State
│   ├── retro-log.md             # Session-Audit Log
│   ├── gates.json               # Safety Gates
│   └── lessons.md               # Self-Learning Log
│
├── hooks/                       # Layer 4 (Shell Scripts)
│   ├── session-start.sh         # Git-Kontext laden
│   ├── session-end.sh           # Session speichern
│   ├── pre-action-gate.sh       # Gate-Check
│   └── post-compact.sh          # Kontext nach Compaction
│
├── agents/                      # Layer 0 (184+ Personas)
│   ├── engineering/
│   │   ├── security-engineer.md
│   │   ├── code-reviewer.md
│   │   └── ...
│   ├── design/
│   ├── testing/
│   ├── product/
│   └── specialized/
│
├── converters/                  # Tool-Konverter
│   ├── to-claude.sh             # → ~/.claude/agents/
│   ├── to-opencode.sh           # → .opencode/agents/
│   ├── to-cursor.sh             # → .cursor/rules/
│   └── to-gemini.sh             # → ~/.gemini/extensions/
│
├── skills/                      # Domain-Skills (Templates, keine NDA-Daten!)
│   ├── retrospective/            #   Session-Audit Skill
│   │   └── SKILL.md
│   ├── SKILL_TEMPLATE.md         # Vorlage für eigene Skills
│   ├── example-project.md        # Generisches Beispiel (kein Kundenprojekt)
│   └── .gitignore                # Schützt lokale NDA-Skills
│
├── skills-local/ (⚠️ NIEMALS commiten, in .gitignore)
│   ├── kunde-b.md                # ← nur lokal, vertraulich
│   ├── kunde-a.md                # ← nur lokal, vertraulich
│   └── voice-ai.md               # ← nur lokal
│
├── graphify/                     # Input → Knowledge Graph
│   ├── SKILL.md                  # Graphify Skill (Trigger: /graphify)
│   ├── graphify.py               # Core Pipeline
│   └── templates/                # HTML/JSON Templates
│
├── obsidian/                     # Obsidian Vault Templates
│   ├── vault-structure.md        # Empfohlene Ordnerstruktur
│   ├── daily-note.md             # Daily Note Template
│   ├── project-note.md           # Projekt-Notiz Template
│   └── graphify-import.md        # Graphify → Obsidian Workflow
│
├── plugins/                     # Optional (Layer 6-7)
│   ├── ruflo-compat/            # Ruflo Integration Guide
│   └── gstack-compat/           # GStack Browser Skill
│
└── docs/                        # Guides
    ├── INSTALL.md               # Installation pro Tool
    ├── CUSTOMIZE.md             # Eigene Agenten bauen
    ├── GATES.md                 # Gate-Referenz
    └── SECURITY.md              # Security Policy
```

## Installation Flow

```
$ git clone https://github.com/its-stam/agent-os.git
$ cd agent-os
$ bash setup.sh
```

Setup erkennt automatisch:
- Claude Code → installiert core + hooks + agents
- OpenCode → installiert agents in .opencode/
- Cursor → installiert rules in .cursor/
- Obsidian → richtet Shell-Alias ein
- Ruflo → überspringt Layer 6-7 (schon da)

## Was wir NICHT neu erfinden

- **Swarm/Memory** → Ruflo macht das schon gut. Wir dokumentieren nur die Integration.
- **Browser QA** → GStack ist der Standard. Wir verlinken.
- **Agent-Personas** → Agency-agents liefert die Basis. Wir kuratieren + erweitern.

## Was WIR neu beitragen

1. **Einheitlicher Standard** — Eine `CLAUDE.md` die ALLE Tools versteht
2. **Gates-System** — Safety-Enforcement auf Hook-Ebene (nicht Prompt-Ebene)
3. **Self-Learning** — 3x gleicher Fehler = auto-escalate
4. **Graphify-Integration** — Jeder Input (Code, Docs, Papers) → Knowledge Graph → Obsidian
5. **Obsidian-Vault-Templates** — Vorgefertigte Struktur für Daily Notes, Projekte, Lernen
6. **Domain-Skills** — Template-basiert, NDA-geschützt via `.gitignore` (lokal = privat, repo = generisch)
7. **Multi-Tool-Konvertierung** — Gleicher Agent läuft in Claude, OpenCode, Cursor, Gemini
8. **Retrospective Audit** — Session-End-Check: Doku-Drift, Workflow-Friction, Patterns. Silence-Path bei sauberem Run.

## Naming

Vorschläge:
- **agent-os** — Operating System für AI Agents
- **agent-core** — Der Kern, den jeder Agent braucht
- **ai-agent-stack** — Der vollständige Stack

## Nächste Schritte

1. [ ] Repo `its-stam/agent-os` anlegen (privat → public wenn ready)
2. [ ] core/ befüllen (CLAUDE.md, primer.md, gates.json, lessons.md)
3. [ ] hooks/ portieren (aus recall-stack + eigenes)
4. [ ] agents/ kuratieren (Top-50 aus 184, nicht alle)
5. [ ] converters/ bauen
6. [ ] setup.sh schreiben
7. [ ] README.md mit Quick-Start
8. [ ] skills/ mit generischen Projekt-Beispielen
9. [ ] Security Audit + SECURITY.md
10. [ ] Test auf verschiedenen Tools
