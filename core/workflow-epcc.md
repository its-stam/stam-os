# Explore → Plan → Code → Commit Workflow

## The Iron Rule
**Never jump straight to writing code.** Always explore first, plan second.

## Phase 1: Explore
- Read relevant files (no edits)
- Understand the codebase and dependencies
- Identify where changes need to happen
- Gather context before any action

## Phase 2: Plan
- Enter plan mode (Shift+Tab until "Plan Mode")
- Claude reads files only, proposes a plan of action
- Review the plan. Reject or revise before any code is written.
- This is the cheapest place to course-correct.

## Phase 3: Code
- Approve the plan → Claude executes
- Define success criteria upfront
- Add tools (browser, test suite) to reduce back-and-forth
- If Claude hits the same issue twice → save solution to CLAUDE.md

## Phase 4: Commit
- Test changes yourself first (not just trusting Claude)
- Run a code-reviewer subagent (fresh eyes, no session bias)
- Generate commit message in your style
- Push. Rinse. Repeat.

## Anti-Patterns to Avoid
- ❌ "Write code for X" without exploring first
- ❌ Skipping plan mode → more course-correcting later
- ❌ No success criteria → Claude can't judge correctness
- ❌ Committing without external review → bias blindness

## Integration with stam-os
- `/stamflow plan` → automates Explore + Plan phases
- `/stamflow deploy` → sets up agents for Code phase
- `/stamflow status` → monitors progress during Code
- `agents/engineering/code-reviewer.md` → Commit phase review
