---
# Copy this file to <workspace>/.agents/migrations/<name>.md and fill it in.
# Frontmatter is a RESTRICTED YAML subset: flat dotted scalar keys, space-separated
# lists, no nesting, no [a, b]. validate-profile.sh rejects anything else rather
# than guessing. Every path is relative to the PROFILE ROOT — the directory that
# contains the .agents/ (or .claude/ or .cursor/) directory this file sits in.
# The profile root does NOT need to be a git repository.

name: my-port

# ---- what you are porting FROM ------------------------------------------------
source.root: legacy-service
source.label: legacy monolith
# Where route/endpoint definitions live. Space-separated; each must exist.
source.discovery.http: src/routes
# Where scheduled jobs are registered. Omit if the port has no crons.
source.discovery.cron: src/jobs/schedule.js

# ---- what you are porting INTO ------------------------------------------------
target.root: new-service
target.label: new service
target.discovery.http: src/api
target.discovery.cron: src/jobs

# ---- where the engine keeps its bookkeeping -----------------------------------
# Must already exist. /migrate creates EXCEPTIONS.md, REGISTRY.md and units/
# inside it at the `map` stage — never earlier.
staff_dir: new-service/docs/migration

# ---- how to run the gates -----------------------------------------------------
# commands.test MUST contain {paths}: the red and green gates run ONLY the unit's
# spec files, never the whole suite. Same for commands.lint when you set it.
commands.test: npm test -- {paths}
commands.lint: npx eslint {paths}
commands.typecheck: npm run type-check

# ---- optional -----------------------------------------------------------------
# Subject prefix used only when YOU ask for a commit.
commit_prefix:
# Path to a worktree-workflow doc, or the literal `in-place` to work directly in
# the target repo (which also skips the merge-back stage).
worktree_policy: in-place
# Set BOTH or NEITHER. Neither = the port may not change the schema at all.
schema_policy.guide:
schema_policy.stop_before:
# Project skills to defer to. Omit and the engine's own gates stand alone.
skills.tdd:
skills.code_review:
---

# <Project> — <source> → <target>

Annotated starting point. Framework-agnostic: nothing here assumes a language,
web framework, ORM, or test runner. Replace the values above and the prose below.

## Name mapping

Area/module renames between the two codebases. Delete the table if names match.

| source area | target area |
| --- | --- |
| `old-name` | `new-name` |

## Framework equivalences

What counts as **`framework`** in the line-compare ledger — mechanically equivalent,
not a behavior change. Without this, ordinary glue reads as a dropped branch and
fails the stage.

| source | target |
| --- | --- |
| route middleware / auth check | target's guard or middleware |
| validator class | target's DTO + validation layer |
| ORM query builder | target's data-access layer |
| CLI command signature | target's command runner |

## Parity surface

State exactly what "matches the source" means — the response shape that must be
identical, and anything deliberately excluded (envelopes, wrappers, headers).
Anything outside this needs an EXCEPTIONS.md row and an explicit yes.

## Gold examples

Already-ported code to clone. **Pointers only — never paste their source.**
On a first port there may be none; write "none yet" and the map stage will say so.

| path | teaches |
| --- | --- |
| `new-service/src/api/<area>/` | the layout a simple port should copy |

## Standards sources

Extra docs file-review should hold the code to, beyond the target repo's own
AGENTS.md / CONTEXT.md.

## Docs walk A

Doc edits in the **source and target repos** after a unit lands. Typically: record
in the source that the surface now also exists in the target (the source keeps
serving), and add the new endpoint or command to the target's docs.

## Docs walk B

Doc edits in the **orchestrating workspace** — pointers, context maps, agent docs.
Edit only when something is stale; otherwise the stage records "no change".
