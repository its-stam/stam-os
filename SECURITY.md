# Security Policy

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Open a private security advisory via the GitHub Security tab.

## Response

- Acknowledgment: within 48 hours
- Assessment: within 7 days
- Fix: depends on severity

## Security Practices

This project employs:

- **Gates** — Pre-action enforcement at hook level (not prompt level). Blocks force-push, rm -rf, credential leaks before execution.
- **No credentials in repo** — `skills-local/` and `.env*` are in `.gitignore`.
- **Input validation** — `gates.json` regex patterns validated before deployment.
- **Hook isolation** — Each hook has a timeout; failures are logged, not silently ignored.
- **No npm/WASM runtime** — Core is 100% shell + markdown. Optional plugins (Ruflo) are documented but not bundled.

## Scope

- `core/` — Markdown config files + JSON gates
- `hooks/` — Bash scripts (session lifecycle)
- `agents/` — Agent persona definitions (markdown)
- `setup.sh` — Installer

Report: suspicious gate patterns, hook vulnerabilities, credential leakage, prompt injection vectors.
