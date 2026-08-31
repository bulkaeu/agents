---
description: Never run migration-up/down (or equivalents) without the user's explicit confirmation — including when a plan includes those steps.
alwaysApply: true
---

# Migration apply/rollback requires explicit confirmation

## Hard stop

Do **not** run database migration apply or rollback commands unless the user has explicitly confirmed them **in this conversation**, even when:

- They appear in an approved plan
- Todos say to run them
- A skill/workflow lists them as the next step
- You already ran `migration-create` successfully

### Covered commands (any project / ORM)

Includes equivalents and wrappers, for example:

- `npm run migration-up` / `npm run migration-down`
- `npx mikro-orm migration:up` / `migration:down`
- `rails db:migrate` / `db:rollback` / `db:migrate:down`
- `knex migrate:latest` / `migrate:rollback`
- `prisma migrate deploy` / `migrate reset`
- `alembic upgrade` / `alembic downgrade`
- Raw SQL that applies or reverts a migration on a shared/local DB that changes schema for the team

`migration-create` / generating a migration file (without applying) is allowed when the task/plan calls for it.

Altering schema via ad-hoc `ALTER TABLE` / `DROP COLUMN` against shared DBs is also gated the same way unless the user explicitly asked for that specific SQL.

## What counts as confirmation

Only clear, recent user phrases, for example:

- "run migration-up"
- "apply the migration"
- "confirm Phase 2 — run migration-up"
- "migration-down then migration-up"

**Does not count:** "implement the plan", "complete all todos", "finish the migration work", "do the v2 schema flow", or plan text that lists `migration-up`/`migration-down` as steps.

## Plans

When writing or updating a plan that includes apply/rollback:

- Mark those steps/todos **`BLOCKED — wait for user confirmation`**
- Put a hard stop after generate: *"Do not run migration-up/down until the user explicitly confirms."*
- Prefer ending the executable phase before apply; wait for a follow-up confirmation message

## Required behavior

1. Finish entity/migration-create/snapshot/Kysely work as allowed.
2. Stop and ask: whether to run `migration-up` (and/or `migration-down`).
3. Only then run apply/rollback after explicit yes.

If unsure, **ask** — do not apply.

<!-- Canonical copy: bulkaeu/agents → rules/migration-apply-confirmation.md. install.sh links it to
     ~/.claude/rules/migration-apply-confirmation.md and ~/.cursor/rules/migration-apply-confirmation.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
