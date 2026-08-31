---
name: plan-finish
description: >-
  Verifies a plan or change is genuinely finished — full check suite green,
  nothing uncommitted or unpushed, docs updated, and the workspace cleaned up
  (merged branches, stale worktrees, temp files). Audits everything read-only,
  reports once, then acts only on what the user approves. Use when the user
  invokes /plan-finish or asks whether a plan or change is done, wrapped up,
  finished, or ready to close.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---

# Plan finish

"Done" is a claim with five parts: the checks pass, nothing is stranded uncommitted, the docs match
the code, the workspace is clean, and the plan says so. This skill audits all five, reports once,
and then fixes only what it is told to fix.

Command tables for each area live in [CHECKLIST.md](CHECKLIST.md). Read it before the audit.

## Hard rules

- **Audit first, act second.** Run the entire read-only audit and print the report before proposing
  a single change. A skill that fixes as it goes gives the user no chance to see the whole picture.
- **No blanket staging permission.** Unlike `verify-changes`, invoking this skill does **not**
  pre-authorize `git add`. The `PreToolUse` hook prompts on every `git add`/`commit` and that prompt
  is the intended gate, not an obstacle to route around.
- **Never** push, force-push, delete a remote branch, `git reset --hard`, amend a pushed commit, or
  delete an unmerged branch. Print those as copy-paste commands and let the user run them.
- **Deletions are confirmed one at a time.** Never batch "remove these 6 worktrees" into one yes.
- **A check you did not run is not a check that passed.** If tooling is missing or a script does not
  exist, say so by name in the report. Never let an unrun check read as green.
- **Report what the commands actually said.** Paste real counts and real failures. "Tests pass" is
  not a result.

## 1. Scope

Resolve the plan with the same ladder as `plan-summary`: explicit path or `@`-mention → the session's
active plan → most recently modified in `~/.claude/plans/`, `~/.cursor/plans/`, `.cursor/plans/`.

**If no plan resolves, do not stop and ask.** Audit the current repo anyway, skip the Progress check
in area 4, and label the report *no plan — repo audit only*. "Is this change done?" is a first-class
way to invoke this skill.

Then list every repo the work touched — the plan's own paths, the cwd, and anything in
`git worktree list`. A plan that spanned three repos needs three audits, not one.

## 2. Audit — read-only, in order

| # | Area | Question it answers |
| - | --- | --- |
| 1 | Scope | Which plan, which repos, which worktrees? |
| 2 | Checks | Does the project's own full suite pass, every script, by name? |
| 3 | Commits | Is anything uncommitted, unpushed, or stashed? |
| 4 | Docs | Do README / AGENTS.md / CLAUDE.md / `docs/**` still describe reality? Is every Progress row resolved — **and does every commit have a row?** |
| 5 | Cleanup | Merged branches, stale worktrees, `*.orig`/`*.rej`, scratch files the plan created? |

Area 2 is the one people skip. Enumerate the project's scripts rather than assuming the usual four
exist, and treat **format-check as its own step** — passing lint does not cover it, because
`format:check` typically globs `.md` and `.json` that ESLint never parses. `CHECKLIST.md` has the
per-ecosystem command tables.

## 3. Report

One table, then the details. Reuse the plan status icons so the report reads like a Progress table:

```markdown
| Area | Status | Detail | Proposed action |
| ---- | ------ | ------ | --------------- |
| Checks | ✅ | type ✓ · format:check ✓ · lint ✓ · 1,484 tests / 100 suites ✓ · build ✓ | — |
| Commits | ⛔ | 3 modified, 1 untracked; branch has no upstream | Stage and commit the 4 files |
| Docs | 🟡 | README still documents `--legacy-flag`, removed in this change | Update README |
| Cleanup | 🟡 | 2 merged branches, 1 stale worktree, 1 `.orig` file | Delete each, confirmed individually |
```

Below the table, for each non-`✅` row: what exactly is wrong, and the exact command that fixes it.

Finish the report with a one-line verdict: **done**, or **not done — N items outstanding**.

## 4. Act on approval

Take the approved items one at a time, verifying after each:

1. **Fix red checks first.** A commit on top of a failing suite is a worse state than no commit.
   Fix, re-run the failing check, and report the new result before moving on.
2. **Commit** — a message describing the change, not the plan step. Expect the hook's prompt.
3. **Docs** — edit, then re-run `format:check` if it globs markdown.
4. **Cleanup** — one confirmation per deletion. Worktrees before their branches.
5. **Close the plan** — set the remaining Progress rows to `✅` (or `⏭️` with a reason), add a
   closing note, and update with `Edit`/`Write`, never Bash.

If the user approves nothing, stop after the report. That is a valid outcome.

## Examples

**`/plan-finish`** after a feature lands — suite green, 3 uncommitted files, one merged branch.
Reports, gets a yes on the commit and the branch, does both, ticks the plan, stops.

**`/plan-finish` in a repo with no plan** — audits the working tree, labels the report
*no plan — repo audit only*, finds an unpushed commit and prints the `git push` for the user to run.

**Red suite** — reports `Checks ⛔ 2 failing specs` with their names, proposes fixing them, and
refuses to propose the commit until they are green.
