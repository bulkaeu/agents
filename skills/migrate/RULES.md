# Hard rules

The safety surface of `/migrate`. `SKILL.md` loads this file directly. **Prompt files do not cite this
file** — that would make the rules a two-hop read, and a partially-read rules file is how a gate gets
silently skipped. Each prompt restates inline only the rules it enforces; this is the canonical wording.

## 1. Isolation

Work in a worktree of the target repo per `worktree_policy`. Mapping, specs, code and target docs for
the unit live in that worktree. Merge `--no-ff` onto the active feature branch only **after file-review
and docs pass**, then append the registry row on that branch. Source-repo doc edits happen in a source
worktree, merged before the unit is done. Integration branches are never touched unless the user asks.

`worktree_policy: in-place` skips the worktree and stage 9 entirely; the stage operates directly on the
target repo and `{worktree}` expands to `{target_root}`.

## 2. Git restraint

Leave the index and remotes unchanged unless the user asks. Worktree merge-back is the sole exception.
When the user does ask to commit, prefix the subject with `commit_prefix`.

## 3. Schema

Follow `schema_policy.guide` and **hard-stop before `schema_policy.stop_before`**, then ask.
With `schema_policy` omitted the port **may not change the schema at all** — stop and ask instead of
improvising a column.

## 4. Additive

The old surface keeps serving; this slice **adds** the new one. Match old behavior. Any intentional
difference needs a row in `{staff_dir}/EXCEPTIONS.md` **and** an explicit yes before it can ship.
Revert unapproved diffs.

## 5. TDD

New specs are **red** before implementation and the **same files** green after. `port` never rewrites a
test to match the code. A test that is wrong against the source goes through rule 4's exception path.

## 6. `ported` is a defined term

    green specs + line-compare + file-review + docs + callers listed + registry row

It does **not** mean clients cut over. Do not report a unit as ported until every element holds.

## 7. One writer

Run-plan writes and registry appends are serialized. One run plan per invocation, updated **in place** —
never copied, forked, or re-minted mid-run.

## 8. Subagents are not authoritative

A subagent never marks a unit `ported` and never writes `REGISTRY.md`. Only the orchestrator does, and
only after rule 6 is satisfied.
