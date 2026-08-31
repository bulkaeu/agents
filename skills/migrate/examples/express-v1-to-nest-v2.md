---
name: express-v1-to-nest-v2

source.root: api
source.label: Express (api) v1
source.discovery.http: src/routes/v1
source.discovery.cron: src/commands/cron-jobs.js

target.root: api-v2
target.label: Nest (api-v2)
target.discovery.http: src/http/api/v2
target.discovery.cron: src/providers/commands/cron

staff_dir: api-v2/docs/migration/v1-to-v2

commands.test: npm test -- {paths}
commands.lint: npx eslint {paths}
commands.typecheck: npm run type-check

worktree_policy: workspace/docs/agents/worktrees.md
schema_policy.guide: api-v2/docs/db-schema-updates.md
schema_policy.stop_before: migration-up
skills.tdd: workspace/.agents/skills/tdd/SKILL.md
skills.code_review: workspace/.agents/skills/code-review/SKILL.md
---

# Example — api (Express v1) → api-v2 (Nest v2)

> **A worked sample, not part of the engine.** It names `api/`, `api-v2/` and `workspace/`, and will
> fail validation anywhere those siblings do not exist — which is correct behavior. Start a new
> project from [TEMPLATE-annotated.md](TEMPLATE-annotated.md); read this one to see what a fully
> populated profile looks like end to end.

Copy to `<workspace>/.agents/migrations/<name>.md` to drive `/migrate`. Commands run from each repo
root. All paths are relative to the profile root — the workspace holding `api/`, `api-v2/` and
`workspace/` as siblings, which is **not** itself a git repository.

## Name mapping

Source and target rarely agree on what an area is called. Map every one you will port; an unmapped
area is a stop, not a guess.

| source area | target area |
| --- | --- |
| `application` | `client-app` |
| `interaction` | `community` |
| `widget` | `widget` |
| `dashboard` | `dashboard` |

Method+path units: strip `/v1/<area>` before matching the route suffix against the source router's
`get/post/put/delete` registrations.

## Framework equivalences

Called out as `framework` in line-compare — equivalent, not a behavior change:

| Express (v1) | Nest (v2) |
| --- | --- |
| route middleware / `auth` | `RolesGuard` |
| hand-rolled validators | DTO + `ValidationPipe` |
| ORM models and query builder | typed query-builder repositories |
| CLI command signature | Nest console command |
| queue producer helper | same queue names, producer only |

Consumers stay in their own services; a port adds producers only.

## Parity surface

A global interceptor wraps success as `{ success: true, data }`. Parity is the **inner `data`** plus
the error DTO — not the wrapper. Any deviation needs an `EXCEPTIONS.md` row and an explicit yes.

## Gold examples

Pointers only. Clone the layout; never paste their source into a prompt.

| path | teaches |
| --- | --- |
| `api-v2/src/http/api/v2/client-app/account/` | simple area port: thin controller, colocated controller/service specs, DTO specs when validation is non-trivial, guard + swagger |
| `api-v2/src/http/api/v2/community/account/` | a renamed area, same HTTP-service split |
| `api-v2/src/http/api/v2/widget/content/` | optional auth, DTO request/response specs |
| `api-v2/src/http/api/v2/common/chats/` | complex: thin controller → fat HTTP service → domain → repository + queue/realtime; e2e only for this class of side effects |
| `api-v2/src/providers/commands/cron/clean-jobs.command.spec.ts` | command specs at the public seam, paired with schedule wiring |

## Standards sources

`api-v2/AGENTS.md`, `api-v2/CONTEXT.md`.

## Docs walk A

**api (source)**

- Append a row to `api/docs/migration/v1-to-v2.md`: surface, target path or command, status, notes.
  v1 still serves.
- Crons: mark the command in `api/docs/commands.md` as moved to api-v2.
- Do not create `api/AGENTS.md` or `api/CONTEXT.md`.

**api-v2 (target, same worktree as the port)**

- New cron → `api-v2/docs/commands.md`.
- `CONTEXT.md` only if a glossary term is genuinely new.
- `AGENTS.md` only if a new convention belongs there.

## Docs walk B

Edit only when a pointer is missing or stale:

- `workspace/docs/agents/worktrees.md` — per-submodule worktree rules apply to api-v2 (and api when
  that repo's docs change).
- `workspace/docs/agents/domain.md` — staff docs live at `api-v2/docs/migration/v1-to-v2/`.
- `workspace/CONTEXT-MAP.md` — only if the api ↔ api-v2 relationship note is wrong for this unit.
- `workspace/AGENTS.md` — if `CLAUDE.md` is a symlink to it, edit `AGENTS.md` only.

If nothing is stale, record "no workspace-doc change" in the run plan.
