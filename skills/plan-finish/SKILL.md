---
name: plan-finish
description: >-
  Finishes a plan: audits whether it is genuinely done — full check suite green,
  the plan's own verification items passing, nothing uncommitted or unpushed,
  docs matching the code, workspace clean, plan state accurate — then fixes what
  it found and reports what it did. Reports the plan's unfinished rows rather
  than running them. Stops only for work that is destructive, gated, ambiguous,
  or not its own to delete. Use when the user invokes /plan-finish or asks to
  finish, wrap up, or close out a plan or change.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---

# Plan finish

"Done" is a claim with six parts: the checks pass, the plan's own verification items pass, nothing is
stranded uncommitted, the docs match the code, the workspace is clean, and the plan says so. This
skill audits all six **and then finishes the job** — fixes what it found, reports what it did.

**It is a finisher, not a reporter.** Handing back a list of small, safe, self-created problems for
the user to authorize one at a time costs them the time the skill exists to save. If the audit found
it and it is reversible and in scope, fix it. The plan's unfinished rows are not in scope.

Command tables for each area live in [CHECKLIST.md](CHECKLIST.md). Read it before the audit, with
[the stop-list](../plan-shared/STOPS.md) and [CONVENTIONS.md](../plan-shared/CONVENTIONS.md).

## Hard rules

- **Audit fully, then act.** Complete the whole read-only audit before changing anything — fixing as
  you go means acting without the full picture. But once the audit is done, *act*: the report is the
  record of what you did, not a request for permission to start.
- **Never run an open row.** A `⬜`/`🟡` row (*open*, per `CONVENTIONS.md`) is reported, not run,
  however small its step: point at `/plan-continue <plan>` (`/plan-build` if none has started), which
  brings the separate reviewer and the parking this skill lacks.
- **Fix by default; stop only for `STOPS.md`.** That list is exhaustive. If something is not on it,
  do it — do not invent a reason to ask.
- **One approval covers a batch** — except `STOPS.md`'s asked-alone set, each of which is asked on
  its own. Otherwise ask once for the whole set: "these four things" → one yes → all four. Never
  turn six worktrees into six prompts.
- **A harness prompt is not a stop** (`STOPS.md`): answer the hook and continue.
- **A check you did not run is not a check that passed.** If tooling is missing or a script does not
  exist, say so by name. Never let an unrun check read as green.
- **Report what the commands actually said.** Real counts, real failures. "Tests pass" is not a result.

### What it fixes without asking

Anything reversible, in scope, and implied by the word *finish* — never the plan's remaining steps:

- The plan's own `## Progress` table, as a ledger — add a missing row for a commit this plan made;
  write icon and Notes only for a row whose step demonstrably ran: its commit exists, or, for work
  outside every repository, its artifact does with nothing of it left uncommitted. A `🟡` row, or one
  owning uncommitted or unreviewed files, **stays open** — never tick a row on an artifact alone.
- Scratch files, decoys, and probes **this skill or this plan created**.
- Doc drift it can verify mechanically — a stale count, a missing table row, a renamed path.
- `git add` and `git commit` of work in the tree, in scope, that **no open row owns** — **by explicit
  path, never `git add -A` or `git add .`**. A blanket add stages whatever else appeared in the working
  tree since the audit: another agent's half-written file, a stray download. Between staging and
  committing, `git status --short` must show only the paths you named. An open row's files — a
  crashed row's half-written file, work its step names — stay uncommitted, listed in the report with
  that row for `/plan-continue` to finish and review.
- `git push` of those commits to the current branch's existing upstream.

### What it stops for

Everything on [`STOPS.md`](../plan-shared/STOPS.md), and nothing else. When you stop, say what you
were about to do and the exact command, so a yes is one word.

## 1. Scope

Resolve the plan with the ladder in `CONVENTIONS.md`. This skill commits and pushes, so it **never
picks a plan by recency**: at the last rung, or with two or more plausible at any rung, list the
candidates with mtimes and offer a repo-only audit instead — the user names a plan, or takes the
audit.

**If no plan resolves, do not stop and ask.** Audit the current repo anyway, skip area 3 and the
Progress check in area 5, and label the report *no plan — repo audit only*. "Is this change done?"
is a first-class way to invoke this skill.

Then list every repo the work touched — the plan's own paths, the cwd, and anything in
`git worktree list`. A plan that spanned three repos needs three audits, not one.

## 2. Audit — read-only, in order

| # | Area | Question it answers |
| - | --- | --- |
| 1 | Scope | Which plan, which repos, which worktrees? |
| 2 | Checks | Does the project's own full suite pass, every script, by name? |
| 3 | Verification | Does each of the plan's `## Verification` items pass — by its recorded result, or run now? |
| 4 | Commits | Is anything uncommitted, unpushed, or stashed? |
| 5 | Docs | Do README / AGENTS.md / CLAUDE.md / `docs/**` still describe reality? Which Progress rows are closed, parked, open — **and does every commit have a row?** Does the plan's `**Ticket:**` still match the plan's state? |
| 6 | Cleanup | Merged branches, stale worktrees, `*.orig`/`*.rej`, scratch files the plan created? |

Area 2 is the one people skip. Enumerate the project's scripts rather than assuming the usual four
exist, and treat **format-check as its own step** — passing lint does not cover it, because
`format:check` typically globs `.md` and `.json` that ESLint never parses.

**Area 3 reads before it runs.** A Verification item whose result a row's Notes already record — a
stage-time check — is reported from that row, citing its id; **do not re-run it**, since its fixtures
may be gone by design. Run any other item now: PASS or FAIL, with the command's real output. An item
that is also one of the repository's own checks falls under area 2 — an obvious cause is fixed and the
check re-run — and area 3 reports the re-run's result, citing the fix. **Any other FAIL is reported,
never fixed**: a finding for the plan's own rows or `/plan-continue`, not work for this skill. No
`## Verification` section reports *none*, not green. How-to: `CHECKLIST.md`, Verification.

## 3. Fix what the audit found

Work through the non-green areas in this order, verifying after each:

1. **Red checks first.** A commit on top of a failing suite is worse than no commit. Fix, re-run that
   check, and carry the real new result into the report.
2. **Docs.** Fix the drift you can verify. Re-run `format:check` afterwards if it globs markdown.
3. **Commit**, then **push**. The commit message describes *the change*, not the plan step — `git log`
   is read by people who never saw the plan, so "F7 commit-push-f" tells them nothing. When the
   plan's `**Ticket:**` line names an identifier, every commit starts with it —
   `ABC-123: <what changed>`, per `plan-ticket-tracking.md`; no ticket, no prefix, never an invented
   one. Push only to a branch that **already has an upstream**; if it has none, that is a new
   destination, so stop and offer the exact `git push -u` line rather than choosing a remote.

   **Say what no reviewer saw.** Changes found in the tree that no open row owns, not a dispatched
   row's reviewed diff, are committed unreviewed — not a stop, but the report names their paths.
4. **Cleanup.** Delete what this plan created; leave anything else alone. Worktrees come out before
   the branches they hold, or git refuses the branch and leaves a dangling registration.
5. **Close the plan.** Confirm the table agrees with what happened, no row claiming more than the
   evidence shows. Closing is bookkeeping by the ledger rule above, never doing rows: a row is ticked
   only if its step demonstrably ran; every other row stays open and goes in the report.

   **Update each row as its step finishes, not all of them here.** `plan-progress-section.md` forbids
   batching a phase's rows into one edit at a boundary — the table records what was true *when*. This
   step is the **checkpoint** that confirms nothing was missed, not the moment to write six rows.
   Notes go in with the icon, `Edit`/`Write` and never Bash, per `ui-rendered-files-use-write-tool.md`.

If something on the stop-list blocks a step, do everything else first, then raise it. A blocked item
never justifies leaving the fixable ones undone.

## 4. Report what you did

**Scale the report to what happened.** A clean audit with nothing to fix is one line:

```
done · 6/6 green · nothing outstanding
```

**When you fixed things**, lead with them — that is the news:

```markdown
Fixed: added 2 missing Progress rows · deleted 1 scratch file · committed and pushed (a1b2c3d)
Committed unreviewed: src/retry.ts, README.md — found in the tree, not a reviewed row's diff

| Area | Status | Detail |
| ---- | ------ | ------ |
| Checks | ✅ | bash -n ✓ · shellcheck ✓ · no project suite (said, not skipped) · formatter NOT RUN — none installed |
| Verification | ✅ | 2 items · PASS recorded in row B3's Notes, not re-run · PASS run now, `bash check.sh` exit 0 |
| Commits | ✅ | was 3 modified + 1 untracked; committed as a1b2c3d, pushed |
| Docs | ✅ | was: README omitted 3 files added last commit; fixed |
```

**When something stopped you**, that goes last and alone, with the exact command:

```
Not done — 1 stop-list item: 2 merged branches are candidates for deletion, but this skill did not create them.
  git branch -d feature/old-thing feature/other
```

End with a one-line verdict. **done** only when every row is closed, no Verification item fails, and
nothing on the stop-list is outstanding. Otherwise **not done**, naming each kind apart and leaving
out the empty ones — open rows with the command that runs them, parked rows with their blockers. The
stop-list number counts only stop-list items; an item you could have fixed belongs fixed, not counted:

```
not done — open: 6, 7 → /plan-continue <plan> · parked: 4 (deploy awaits a yes) · 1 Verification FAIL · 1 stop-list item
```

## Examples

**`/plan-finish` after a feature lands** — suite green, 3 uncommitted files, one leftover scratch file
the plan created. Commits, pushes, deletes the scratch file, records the commit in the plan's table,
reports in three lines. Nothing on the stop-list, so nothing is put back to the user for a decision —
though a `PreToolUse` hook may still prompt for the commit: the environment's prompt, not a stop.

**`/plan-finish` on a half-run plan** — row 6 `🟡` with its file half-written, row 7 `⬜`, one other
file uncommitted, one Verification item failing. Commits the other file by path and names it
unreviewed; leaves row 6's file uncommitted, listed with row 6; runs neither row; reports the FAIL
and fixes nothing: `not done — open: 6, 7 → /plan-continue <plan> · 1 Verification FAIL`.

**`/plan-finish` with a stale plan table** — two commits have no Progress row and the README omits a
file added last commit. All three are mechanical and verifiable: fix them, commit, push, report. This
is the case that must never come back as "shall I?".

**`/plan-finish` in a repo with no plan** — audits the working tree, labels the report *no plan — repo
audit only*, finishes what it finds.

**Red suite** — 2 failing specs with an obvious cause: fix, re-run, report the new result, then
continue. If the cause is not obvious, stop with the failing names and what you tried.

**Merged branches present** — finishes everything else first (commit, push, the plan's table, its own
scratch files), *then* raises the branches, because it did not create them. One batch question with
the exact `git branch -d` line, not one prompt per branch. Note `--merged` lists branches merged into
the *current* branch, which is not proof they are merged upstream, so present them as candidates
rather than as safe deletions.
