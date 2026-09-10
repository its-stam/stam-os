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

- **Approach** (which expertise areas the task touches)
- **Gates to activate** (which safety rules from gates.json)
- **Memory strategy** (primer.md only / +obsidian)
- **Hooks needed** (which session lifecycle hooks)

### Phase 3: Deploy
Present the plan. User approves → execute:

- Activate relevant gates
- Set up primer.md for this session
- Output: "Ready for [project]. Focus: [list]. Gates: [list]."

### Phase 4: Orchestrate
If multi-agent task:
- Spawn agents in sequence or parallel
- Monitor via /stamflow status
- Collect results, generate summary

## Example Session

Agent: What are you working on?
User: A feasibility study — analyzing CAD export data with an LLM pipeline
Agent: What field of expertise?
User: Engineering + Data Science
Agent: What specific tasks?
User: Pipeline code review, architecture docs, a security audit
Agent: Scope?
User: Full project, ~500 LOC, confidential client data
Agent: [Analyzes...]
Agent: Plan:
  - Focus: security review, architecture review, code review
  - Gates: no-credentials-in-files, no-force-push
  - Memory: primer.md + local knowledge base only (nothing leaves the machine)
  - Hooks: pre-action-gate, post-compact
  Proceed now?
User: Yes
