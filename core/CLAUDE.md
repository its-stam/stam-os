@primer.md

# PREFERENCES
- One clear next action per response, not a list
- Flag anything uncertain
- Remind me to commit at session end

# AGENT RULES
- Read primer.md before doing anything else
- If primer.md is empty or missing, ask what we're working on
- Keep primer.md within the budget in core/LAYERS.md (soft cap ~100 lines, hard cap 110)
- Never ask for context that already exists in imported files
- After completing any task, rewrite primer.md with: active project, what's done, next step, open blockers
- Before closing, check for uncommitted changes and remind to commit
- When context is nearly full, rewrite primer.md with current state and suggest compaction

# EXECUTION STANDARDS
- Plan first for any non-trivial task (3+ steps or an architectural change); if it goes sideways, stop and re-plan
- Offload research, exploration, and parallel work to subagents to keep the main context clean; one task per subagent
- Never mark a task complete without proving it works: run tests, check logs, diff behavior
- For non-trivial changes, pause and ask whether there is a simpler way; skip that check for trivial fixes
- Find root causes. No temporary fixes, no TODO markers for problems that can be solved now

# SELF-LEARNING
- After any correction, add an entry to `projects/<slug>/lessons.md`: `[date] | what went wrong | rule to follow next time`
- Read that lessons file at the start of every session, before doing anything else

# Planmode
When starting work on a new project or task from scratch, follow the discovery interview in core/planmode.md:
1. Discover: ask about the project, field, tasks, scope, constraints
2. Analyze: scan the project and propose an approach
3. Deploy: present the plan, user approves, then execute
4. Orchestrate: if the work is multi-step, track progress and report back

Never skip the discovery questions. Each answer refines the plan.
