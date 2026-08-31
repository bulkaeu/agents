# Migration profile — contract

Start from [`examples/TEMPLATE-annotated.md`](examples/TEMPLATE-annotated.md) — a framework-agnostic
profile with inline guidance. A profile is one markdown file: **restricted-YAML frontmatter** for mechanical facts, prose sections for
judgment. Put it at `<workspace>/.agents/migrations/<name>.md` (or `.claude/` / `.cursor/`).

All paths are relative to the **profile root** — the directory containing the `.agents/` / `.claude/` /
`.cursor/` directory holding the profile. **Not** a git repo root: a workspace with sibling clones and
no `.git` of its own is a normal and supported case.

## Frontmatter: flat, dotted, scalar keys only

No nesting. No `[a, b]` sequences. Lists are **space-separated on one line**. This is not cosmetic — it
is what lets `scripts/validate-profile.sh` parse the file correctly in POSIX `sh` with `grep` and `cut`
alone. Nested YAML is what makes shell parsing silently wrong, and a validator that quietly passes a
malformed profile is worse than no validator.

| Key | Required | Meaning |
| --- | --- | --- |
| `name` | yes | profile identifier |
| `source.root` | yes | directory being ported *from* |
| `source.label` | no | human name shown in reports, e.g. `legacy monolith` |
| `source.discovery.http` | no | space-separated paths holding HTTP route definitions |
| `source.discovery.cron` | no | path(s) holding cron registration |
| `target.root` | yes | directory being ported *into* |
| `target.label` | no | human name |
| `target.discovery.http` | no | where ported HTTP lands |
| `target.discovery.cron` | no | where ported crons land |
| `staff_dir` | yes | holds `EXCEPTIONS.md`, `REGISTRY.md`, `units/` (created at `map`) |
| `commands.test` | yes | must contain `{paths}` |
| `commands.lint` | no | must contain `{paths}` when present |
| `commands.typecheck` | no | takes no paths |
| `commit_prefix` | no | subject prefix when the user asks to commit |
| `worktree_policy` | no | path to a worktree doc, or the literal `in-place` |
| `schema_policy.guide` | no | schema-change guide; **omit both keys → no schema changes allowed** |
| `schema_policy.stop_before` | no | irreversible step to hard-stop before |
| `skills.tdd` | no | project TDD skill; omitted → the red/green gates stand alone |
| `skills.code_review` | no | project review skill; omitted → see fallback below |

### `{paths}` substitution

`commands.test` and `commands.lint` must contain the literal token `{paths}`. The engine replaces it
with the space-separated paths for the current gate, shell-quoted. A command without the token would
run against the whole project — explicitly wrong for the red and green gates, which must run **only**
the unit's spec files. Validation rejects a `commands.test` missing it.

### Trust boundary

A profile is local developer-authored config, discovered only under the workspace being worked in and
never fetched. The engine runs `commands.*` as declared; it evaluates no other profile string as code.

## Prose sections

- `## Name mapping` — source area → target area renames.
- `## Framework equivalences` — feeds the `framework` verdict in line-compare (auth → guard, ORM → ORM,
  CLI → CLI). Without this, framework glue reads as a behavior change.
- `## Parity surface` — what "matches the old behavior" means concretely (e.g. inner `data` under a
  `{ success, data }` wrapper).
- `## Gold examples` — pointer table of paths to clone. Pointers only; never paste their source.
- `## Standards sources` — extra docs for file-review.
- `## Docs walk A` — doc edits in the source and target repos after a unit.
- `## Docs walk B` — doc edits in the orchestrating workspace.

**The profile replaces a PLAYBOOK.** Prompts read `Staff: <profile>`. If `{staff_dir}/PLAYBOOK.md` also
exists it is read *in addition*; `templates/playbook.md` and `templates/gold-examples.md` ship for
projects that want the longer prose form.

### Fallback when `skills.code_review` is omitted

file-review reviews the unit's changed files against the target repo's `AGENTS.md` / `CONTEXT.md` plus
any `## Standards sources`, with the same severity rule: documented-standard breach → fail the stage;
baseline smell → fixed by `port` or waived in that file's block; skip tooling-enforced items.

## Blank profile

```yaml
---
name:

source.root:
source.label:
source.discovery.http:
source.discovery.cron:

target.root:
target.label:
target.discovery.http:
target.discovery.cron:

staff_dir:

commands.test:
commands.lint:
commands.typecheck:

commit_prefix:
worktree_policy:
schema_policy.guide:
schema_policy.stop_before:
skills.tdd:
skills.code_review:
---
```

## Name mapping

## Framework equivalences

## Parity surface

## Gold examples

## Standards sources

## Docs walk A

## Docs walk B
