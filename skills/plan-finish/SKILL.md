---
name: plan-finish
description: >-
  Finishes a plan: audits whether it is genuinely done — full check suite green,
  nothing uncommitted or unpushed, docs matching the code, workspace clean, plan
  state accurate — then fixes what it found and reports what it did. Stops only
  for work that is destructive, gated, or genuinely ambiguous. Use when the user
  invokes /plan-finish or asks to finish, wrap up, or close out a plan or change.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---

# Plan finish

"Done" is a claim with five parts: the checks pass, nothing is stranded uncommitted, the docs match
the code, the workspace is clean, and the plan says so. This skill audits all five **and then
finishes the job** — it fixes what the audit found and reports what it did.

**It is a finisher, not a reporter.** Handing back a list of small, safe, self-created problems for
the user to authorize one at a time costs them the time the skill exists to save. If the audit found
it and it is reversible and in scope, fix it.

Command tables for each area live in [CHECKLIST.md](CHECKLIST.md). Read it before the audit.

## Hard rules

- **Audit fully, then act.** Complete the whole read-only audit before changing anything — fixing as
  you go means acting without the full picture. But once the audit is done, *act*: the report is the
  record of what you did, not a request for permission to start.
- **Fix by default; stop only for the listed exceptions.** The stop-list below is exhaustive. If
  something is not on it, do it — do not invent a reason to ask.
- **One approval covers a batch.** When you do need a yes, ask once for the whole set: "these four
  things" → one yes → all four. Never turn six worktrees into six prompts.
- **A check you did not run is not a check that passed.** If tooling is missing or a script does not
  exist, say so by name. Never let an unrun check read as green.
- **Report what the commands actually said.** Real counts, real failures. "Tests pass" is not a result.

### What it fixes without asking

Anything reversible, in scope, and implied by the word *finish*:

- The plan's own `## Progress` table — add missing rows, resolve `⬜`/`🟡`, write the Notes cells.
- Remaining plan steps that are ordinary work — the plan said to do them and the user said finish.
- Scratch files, decoys, and probes **this skill or this plan created**.
- Doc drift it can verify mechanically — a stale count, a missing table row, a renamed path.
- `git add` and `git commit` of the work in scope.
- `git push` of those commits to the current branch's existing upstream.

### What it stops for

Exhaustive. Everything else is a fix, not a question.

| Stop | Why |
| --- | --- |
| `git push --force`, deleting a remote branch, `git reset --hard`, amending a pushed commit | Destroys work or published history |
| Deleting a branch, worktree, or file **it did not create** | Not its to delete |
| Database migration apply/rollback | `migration-apply-confirmation.md` owns this; needs an explicit yes |
| Closing, reassigning, or deleting a tracker issue | `plan-ticket-tracking.md` owns this — creating is authorised, destructive edits are not |
| A step the plan itself marks `BLOCKED` or waiting on the user | The plan already said to stop |
| A red check whose fix is not obvious, or a doc change needing a judgment call on wording or scope | Guessing produces work the user has to undo |
| Anything outward-facing to a *new* destination — first push of a new repo, publishing, filing into a tracker not yet agreed | Approval for one destination is not approval for another |

When you stop, say what you were about to do and the exact command, so a yes is one word.

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
| 4 | Docs | Do README / AGENTS.md / CLAUDE.md / `docs/**` still describe reality? Is every Progress row resolved — **and does every commit have a row?** Does the plan's `**Ticket:**` still match the plan's state? |
| 5 | Cleanup | Merged branches, stale worktrees, `*.orig`/`*.rej`, scratch files the plan created? |

Area 2 is the one people skip. Enumerate the project's scripts rather than assuming the usual four
exist, and treat **format-check as its own step** — passing lint does not cover it, because
`format:check` typically globs `.md` and `.json` that ESLint never parses. `CHECKLIST.md` has the
per-ecosystem command tables.

## 3. Fix what the audit found

Work through the non-green areas in this order, verifying after each:

1. **Red checks first.** A commit on top of a failing suite is worse than no commit. Fix, re-run that
   check, and carry the real new result into the report.
2. **Remaining plan steps.** Ordinary work the plan called for — do it. Skip only what the stop-list
   covers.
3. **Docs.** Fix the drift you can verify. Re-run `format:check` afterwards if it globs markdown.
4. **Commit**, then **push** to the existing upstream.
5. **Cleanup.** Delete what this plan created. Leave anything else alone.
6. **Close the plan.** Resolve every remaining row to `✅`, or `⏭️` with a reason — never leave a row
   that disagrees with what happened. Write the Notes cells in the same edit. `Edit`/`Write`, never
   Bash, per `ui-rendered-files-use-write-tool.md`.

If something on the stop-list blocks a step, do everything else first, then raise it. A blocked item
never justifies leaving the fixable ones undone.

## 4. Report what you did

**Scale the report to what happened.** A clean audit with nothing to fix is one line:

```
done · 5/5 green · nothing outstanding
```

Nobody should read a five-row table to learn nothing was wrong.

**When you fixed things**, lead with them — that is the news:

```markdown
Fixed: added 2 missing Progress rows · deleted 1 scratch file · committed and pushed (a1b2c3d)

| Area | Status | Detail |
| ---- | ------ | ------ |
| Checks | ✅ | bash -n ✓ · shellcheck ✓ · no project suite (said, not skipped) · formatter NOT RUN — none installed |
| Commits | ✅ | was 3 modified + 1 untracked; committed as a1b2c3d, pushed |
| Docs | ✅ | was: README omitted 3 files added last commit; fixed |
```

**When something stopped you**, that goes last and alone, with the exact command:

```
Not done — 1 item: 2 merged branches are candidates for deletion, but this skill did not create them.
  git branch -d feature/old-thing feature/other
```

End with a one-line verdict: **done**, or **not done — N items outstanding**, where N counts only
things on the stop-list. An item you could have fixed and didn't does not belong in that number — it
belongs fixed.

## Examples

**`/plan-finish` after a feature lands** — suite green, 3 uncommitted files, one leftover scratch file
the plan created. Commits, pushes, deletes the scratch file, ticks the plan, reports in three lines.
No question asked, because nothing was on the stop-list.

**`/plan-finish` with a stale plan table** — two commits have no Progress row and the README omits a
file added last commit. All three are mechanical and verifiable: fix them, commit, push, report. This
is the case that must never come back as "shall I?".

**`/plan-finish` in a repo with no plan** — audits the working tree, labels the report *no plan — repo
audit only*, finishes what it finds.

**Red suite** — 2 failing specs with an obvious cause: fix, re-run, report the new result, then
continue. If the cause is not obvious, stop with the failing names and what you tried.

**Merged branches present** — reports them and stops, because it did not create them. One batch
question with the exact `git branch -d` line, not one prompt per branch.
