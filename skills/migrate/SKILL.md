---
name: migrate
description: >-
  Ports named HTTP endpoints or cron jobs from one codebase into another —
  any framework, any language, any A→B pair — driven by a per-project migration
  profile that supplies the roots, commands and conventions. NOT for database
  migrations or schema changes. Use when the user asks to migrate, port, or move
  an endpoint, route, area, or cron between two codebases.
disable-model-invocation: true
argument-hint: "<unit> | inventory | resume <run>"
---

# Migrate — port a unit from one codebase into another

User-invoked orchestrator. The **profile** is the staff document: it supplies every project-specific
fact (repo roots, discovery paths, framework vocabulary, commands, doc targets). This file supplies the
pipeline and the gates. Nothing here names a specific project.

Read [RULES.md](RULES.md) now — it is the safety surface and this file assumes it.
Host quirks live in [HOSTS.md](HOSTS.md). Profile contract: [PROFILE-SCHEMA.md](PROFILE-SCHEMA.md).

## 1. Resolve the profile (before any read of project code)

Walk **up from cwd**, checking at each level in order:

1. `.agents/migrations/*.md`
2. `.claude/migrations/*.md`
3. `.cursor/migrations/*.md`

**Stop at `$HOME`, exclusive.** `~/.agents/migrations/` is never a profile source — a profile names
concrete repo roots and test commands, so a home-level one would silently apply to unrelated projects.
`examples/` here is a library to copy from, not a resolution target.

- Exactly one match → use it, and **say which file** in your first message.
- Several → ask which (AskUserQuestion). Do not pick.
- None → ask the user for the facts and offer to write a profile from
  [PROFILE-SCHEMA.md](PROFILE-SCHEMA.md). **Never infer roots or commands.**

The **profile root** is the directory containing the `.agents/` / `.claude/` / `.cursor/` directory the
profile was found in — *not* a git repo root. It may be a repo, a monorepo superproject, or a plain
workspace directory holding sibling clones.

## 2. Validate (hard gate)

Run the validator that ships **beside this file** — resolve it relative to this skill's own
directory, not the user's cwd:

```sh
sh <this-skill-dir>/scripts/validate-profile.sh <profile-path>
```

Under a default install that is `~/.agents/skills/migrate/scripts/validate-profile.sh`. If you cannot
locate it, say so and **stop** — do not proceed on an unvalidated profile.

Non-zero exit → **stop** and report the named key.
Do not proceed on a malformed profile, and do not repair it by guessing.

The script validates the mechanical frontmatter only. The prose sections are judgment and are checked
by the stage that consumes them.

## 3. Parse input

- **Named unit(s)** (default) — area/stem, leaf file, method+path, or a cron identifier. Several names
  are separate units. Run at most **3 in parallel, and only when they share no source leaf and no
  target module**; overlapping units run sequentially.
- **`inventory`** — catalog remaining surfaces, seed the run plan, **stop**. Read-only apart from the
  run plan. Named units *and* `inventory` → inventory first, then the named path.
- **`resume <run>`** — read that run plan plus the on-disk artifacts and continue at the first
  incomplete stage.
- **Nothing named** → ask. Do **not** default to inventory.

## 4. Stage handoff

Stages communicate through **files**, never through inline context. Each prompt file declares
`reads:` / `writes:` as path templates over this token set; the stage expands them itself from the
profile plus the two values you pass (`unit_id`, `profile_path`):

`{profile_path}` `{profile_root}` `{source_root}` `{target_root}` `{staff_dir}` `{unit_id}`
`{run_id}` `{worktree}`

`{profile_path}` is the profile file itself (what every prompt's `reads:` header names);
`{profile_root}` is the directory all profile paths resolve against.

`{worktree}` = the worktree path under a `worktree_policy` document; = `{target_root}` under
`in-place`, where no worktree exists.

Dispatch stages as subagents where the host has them, otherwise run them sequentially in-thread. The
gates below are what must hold — not the parallelism.

## 5. Stages

Each stage's **freedom** says how to write and follow it. Low-freedom stages are exact sequences: do
not paraphrase or reorder them. Stop the pipeline on any stage failure.

| # | Stage | Freedom | Prompt |
| --- | --- | --- | --- |
| 1 | map | high | [map-prompt.md](map-prompt.md) |
| 2 | run-plan | medium | — (orchestrator) |
| 3 | tests (red gate) | **low** | [tests-prompt.md](tests-prompt.md) |
| 4 | port (green gate) | **low** | [port-prompt.md](port-prompt.md) |
| 5 | line-compare | **low** | [line-compare-prompt.md](line-compare-prompt.md) |
| 6 | file-review | medium | [file-review-prompt.md](file-review-prompt.md) |
| 7 | docs walk A | high | [docs-prompt.md](docs-prompt.md) |
| 8 | docs walk B | high | [docs-prompt.md](docs-prompt.md) |
| 9 | merge-back | **low** | — (orchestrator) |
| 10 | registry | **low** | — (orchestrator) |
| — | inventory (mode) | medium | [inventory-prompt.md](inventory-prompt.md) |

**1 — map.** Expand the named unit into in-scope handlers. **Done:** `{staff_dir}/units/{unit_id}.md`
exists with a row per in-scope handler, callers listed or "none found".
Create missing `{staff_dir}` scaffolding from `templates/` — `templates/exceptions.md` →
`EXCEPTIONS.md`, `templates/registry.md` → `REGISTRY.md`, plus an empty `units/`
**here and not earlier** — resolution, validation and `inventory` stay read-only apart from the run plan.

**2 — run-plan.** Create or update **in place** one run plan per invocation, in the host plan directory
(see [HOSTS.md](HOSTS.md)); if the host has none, use `{staff_dir}/units/{unit_id}-run.md`. Columns:
map / tests / port / compare / review / docs / registry. One atomic todo per in-scope item — one verb,
one done-state. Never fork or re-mint a run plan mid-run. Update after **every** later stage.

**3 — tests (red gate).** Exact sequence:
1. Write a spec for **every** mapping row.
2. Run **only those spec paths** via `commands.test` with `{paths}` substituted.
3. Assert **red** (failing assertions or missing symbols).
Do not modify existing spec files. Do not run the full suite. Verify red **before** stage 4.

**4 — port (green gate).** Exact sequence:
1. Implement until **the same spec paths** pass.
2. Re-run those exact paths; assert **green**.
3. If a shared module was touched, run that module's existing specs; they stay green.
4. Run `commands.lint` on touched paths and `commands.typecheck`.
Never rewrite a test to match the code (RULES.md rule 5). A test wrong against the source needs an
`EXCEPTIONS.md` row **and** an explicit yes first.

**5 — line-compare.** Ledger over every source line for in-scope handlers. Verdicts: `kept`,
`relocated`, `framework`, `exception`. Any `missing` or `silent-change` → **fail**, return to stage 4,
re-pass the green gate, compare again.

**6 — file-review.** Standards review of the unit's changed files. Fail → stage 4 → green gate → review
again.

**7/8 — docs.** Walk A = source and target repos. Walk B = the orchestrating workspace's agent docs.
Both from the profile's `## Docs walk A` / `## Docs walk B`.

**9 — merge-back.** Worktree `--no-ff` onto the active feature branch, after file-review **and** docs.
**Skipped under `in-place`** — note the skip in the run plan.

**10 — registry.** Append **one** row (`status: ported`) to `{staff_dir}/REGISTRY.md` and mark the
run-plan todo complete. Trigger is after merge-back; under `in-place` it is after file-review and docs
pass. One writer, serialized. Only the orchestrator does this — never a subagent.

## 6. Reporting

Report which stages ran and their actual results. A stage you skipped is not a stage that passed.
`ported` means what RULES.md rule 6 says it means — not that clients cut over.
