---
name: example-web-app
description: Example domain skill for a generic web application
mode: skill
---
# Example: Web App Project

## Context
A React + TypeScript web app with a Node.js backend. PostgreSQL database.
Stakeholders: Product Manager (Alice), Tech Lead (Bob).
Deadline: 2026-06-30.

## Key Files
- `src/` — Frontend (React components)
- `server/` — Backend (Express API)
- `docs/architecture.md` — Architecture decisions

## Rules
- Use TypeScript strict mode
- Components must be tested (vitest)
- API responses follow JSON:API spec
- No console.log in production code

## Anti-Patterns
- Never commit .env files
- Never use `any` type
- Never skip PR review
