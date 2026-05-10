@primer.md

# PREFERENCES
- One clear next action per response, not a list
- Flag anything uncertain with [UNCLEAR]
- Remind me to commit at session end

# AGENT RULES
- Read primer.md before doing anything else
- If primer.md is empty or missing, ask what we're working on
- Keep primer.md under 100 lines
- Never ask for context that exists in imported files
- After completing any task (not just session end), silently overwrite ~/.claude/primer.md with: active project, what's been completed, exact next step, open blockers. Keep under 100 lines.
- Before closing, check for uncommitted changes and remind me to commit
- When context reaches ~70%, rewrite primer.md with current state, tell me to /compact

# SELF-LEARNING
- After any correction, immediately add an entry to tasks/lessons.md
- Format: [date] | what went wrong | rule to follow next time
- Read tasks/lessons.md at start of every session before doing anything

# stamflow
- `/stamflow view` — Terminal agent office visualization (3×4 grid, status colors)
- `/stamflow dashboard` — Terminal dashboard: project metrics, recommendations, security
- `/stamflow plan` — Discovery interview → Agent deployment plan
- `/stamflow deploy` — Deploy agents to current project
- `/stamflow swarm` — Start multi-agent swarm
- `/stamflow gate` — Manage safety gates
- `/stamflow status` — Check running agents and progress
- `/stamflow graph` — Input → Knowledge Graph → Obsidian
- `/stamflow test --all` — Run ALL tests (code + security + agents + gates)
- `/stamflow test --code` — Code Health: ShellCheck, perms, complexity
- `/stamflow test --security` — Security: secrets, SAST, prompt injection, deps
- `/stamflow test --agents` — Agents: frontmatter, duplicates, size check
- `/stamflow test --gates` — Gates: regex validation + edge case fuzzing

# Planmode
When user triggers `/stamflow plan`, follow the discovery interview in core/planmode.md:
1. Discover: ask about project, field, tasks, scope, constraints
2. Analyze: scan project, propose agents + gates + memory
3. Deploy: user approves → execute deployment
4. Orchestrate: if multi-agent, spawn and monitor

Never skip Phase 1 questions. Each answer refines the plan.

# graphify
- Trigger: `/graphify`
- Converts any input (code, docs, papers, images) to knowledge graph → Obsidian
