# Planmode — Discovery Interview

## Trigger
/stamflow plan

## Flow

### Phase 1: Discover
Ask these questions (one at a time, conversational):

1. What are you working on? 
   → (project type, language, framework)

2. What field of expertise do you need?
   → engineering / design / testing / product / sales / marketing / security / devops

3. What specific tasks?
   → coding / code-review / architecture / security-audit / performance / UI-design / QA / documentation

4. What's the scope?
   → single-file / multi-file / full-project / multi-repo

5. Any constraints?
   → NDA / deadline / team-size / budget / private-repo

### Phase 2: Analyze
Based on answers, scan the project and propose:

- **Agents to deploy** (which personas from agents/)
- **Gates to activate** (which safety rules from gates.json)
- **Memory strategy** (primer.md only / +obsidian / +ruflo)
- **Hooks needed** (which session lifecycle hooks)

### Phase 3: Deploy
Present the plan. User approves → execute:

- Copy selected agents to project
- Activate relevant gates
- Set up primer.md for this session
- Output: "stam-os deployed for [project]. Agents: [list]. Gates: [list]."

### Phase 4: Orchestrate
If multi-agent task:
- Spawn agents in sequence or parallel
- Monitor via /stamflow status
- Collect results, generate summary

## Example Session

User: /stamflow plan
Agent: What are you working on?
User: Machbarkeitsstudie — CAD-Daten mit LLM analysieren
Agent: What field of expertise?
User: Engineering + Data Science
Agent: What specific tasks?
User: Code Review der n8n-Pipeline, Architektur-Doku, Sicherheits-Audit
Agent: Scope?
User: Full project, ~500 LOC, NDA-geschützt
Agent: [Analyzes...]
Agent: Plan:
  - Agents: Security Engineer, Code Reviewer, Software Architect
  - Gates: no-credentials-in-files, no-force-push
  - Memory: primer.md + Obsidian (NDA-safe, local only)
  - Hooks: pre-action-gate, post-compact
  Deploy now?
User: Yes
Agent: ✓ stam-os deployed. 3 agents ready. Type /stamflow status for progress.
