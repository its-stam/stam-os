---
name: retrospective
type: skill
description: Audits the just-completed session and surfaces a concise, targeted list of suggested improvements — to skills, docs, conventions, or workflow — or stays silent if nothing meaningful was learned. Use proactively when a multi-step task wraps up, a feature ships, or the user asks for a "retro" / "what could be improved" / "what did we learn". Run before /save-context. Silence on a clean run is the design intent.
---

# Skill: retrospective

After a session of meaningful work completes, audit what happened and produce a concise list of suggested improvements. Or stay silent.

Part of [stam-os](https://github.com/its-stam/stam-os) Layer 2 (State) — bridges session experience into permanent project improvements.

## When to use

Invoke at:

- **End of every meaningful session.** After a feature ships, a bug is fixed, or a multi-step task wraps up.
- **Manual request:** "retro on this", "audit the session", "what could be improved?", "what did we learn?", "anything to update?".

Run **before** `/save-context` so findings land in the context snapshot. Don't run mid-session.

## Relation to other stam-os features

| Feature | What it does | Retro's role |
|---|---|---|
| `lessons.md` | Explicit corrections from user | Retro finds things the user DIDN'T explicitly correct |
| `/stamflow recall` | Hybrid search over project memory | Retro checks prior findings before repeating them |
| `session-end.sh` | Auto-promotes repeated failures to gates | Retro surfaces failures BEFORE they repeat 3x |
| `primer.md` | Session state tracking | Retro writes findings that outlive a single session |

## State file

Before auditing, search prior findings:

```
/stamflow recall "retro finding <topic>"
```

Or read `core/retro-log.md` directly if recall is not built yet.

After producing findings, append new ones to `core/retro-log.md` with status "open". Format:

```
### <date> — <one-line summary>
- **Category:** stale-doc | instruction-mismatch | runtime-lesson | workflow-gap | new-pattern
- **Status:** open
- **Detail:** <what happened, what to change>
- **Trace:** <specific moment from session>
```

Mark prior findings as "resolved" when the fix has been applied.

## Inputs (what to audit)

1. **Skill / doc instructions vs. reality.** Documented step failed when run as written.
2. **User corrections.** Process/structural pushback only — skip stylistic choices.
3. **Silent failures.** Things that seemed to work but didn't.
4. **Drift between docs.** README vs. CLAUDE.md vs. skill files vs. reality.
5. **Workflow friction.** Steps that took multiple tries. Heavy iteration loops.
6. **Patterns that emerged.** New helpers or techniques worth saving for reuse.

## Output format

If findings exist, produce a concise numbered list. Group by category only with 5+ items.

```markdown
## Retrospective — <session subject>

### Stale docs
1. **<file>** — what's wrong, what to change.

### Skill / doc instructions that don't match reality
2. **<name>** — what failed, the actual behavior.

### Run-time lessons not captured
3. **<lesson>** — what we learned, where to put it.

### Workflow gaps
4. **<friction>** — what felt heavy, what could ease it.
```

## The silence path

Output **nothing** if the run was clean. No acknowledgment. Silence is the filter working.

Stay silent when: every documented step worked, corrections were stylistic only, no doc drift, no new reusable patterns emerged.

Speak when: a documented step failed, user pushed back on process, a failure mode was discovered, docs are out of date, or a reusable pattern was built.

Mental check: "Would the user benefit from this becoming a permanent change?"

## Post-output steps

1. Append each finding to `core/retro-log.md`
2. For structural corrections matching the `lessons.md` pattern, suggest adding them there
3. If a finding reveals a safety gap, flag for gates review

## Anti-patterns

- Don't pad with weak items. A 2-item list is fine.
- Don't surface stylistic/content preferences as skill issues.
- Don't propose net-new skills without real friction motivating them.
- Don't auto-implement — surface, let the user decide.
- Don't repeat findings from prior sessions — check retro-log.md first.
- Don't speak when there's nothing worth saying.
