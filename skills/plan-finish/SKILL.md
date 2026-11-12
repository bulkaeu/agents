---
name: plan-finish
description: >-
  Finishes a plan: audits whether it is genuinely done — applicable checks green,
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

- **Audit fully, then act.** Complete the whole audit before changing anything — fixing as you go means acting
  without the full picture. Then *act*: the report is the record of what you did, not a request to start.
- **Never run an open row.** A `⬜`/`🟡` row (*open*, per `CONVENTIONS.md`) is reported, not run,
  however small its step: point at `/plan-build <plan>`, which starts or resumes it and
  brings the separate reviewer and the parking this skill lacks.
- **Fix by default; stop only for `STOPS.md`.** That list is exhaustive — never invent a reason to ask.
- **One approval covers a batch** — except `STOPS.md`'s asked-alone set, each asked alone. Otherwise ask once
  for the whole set: "these four things" → one yes → all four. Never turn six worktrees into six prompts.
- **A harness prompt is not a stop** (`STOPS.md`): answer the hook and continue.
- **A check you did not run is not a check that passed.** Name a missing tool or script; never green.
- **Report what the commands actually said.** Real counts, real failures. "Tests pass" is not a result.

### What it fixes without asking

Anything reversible, in scope, and implied by the word *finish* — never the plan's remaining steps:

- The plan's own `## Progress` table, as a ledger — add a missing row for a commit this plan made;
  write icon and Notes only for a row whose step demonstrably ran: its commit exists, or, for work
  outside every repository, its artifact does with nothing of it left uncommitted. A `🟡` row, or one
  owning uncommitted or unreviewed files, **stays open** — never tick a row on an artifact alone.
- Scratch files, decoys, and probes **this skill or this plan created**.
- Doc drift it can verify mechanically — a stale count, a missing table row, a renamed path.
- `git add` and `git commit` of **claimed paths** only, by explicit path, never `git add -A` or `.`: the plan
  file and its `<plan stem>-history.md`, always — no `commit:` releases them; a closed row's own paths
  (`plan-build`'s `EXECUTION.md`) and the Run log's `inline <row id>: <paths>`, each until a logged `commit:`
  holds them; its own writes — never to a file dirty and unclaimed when it began (*dirty at start*): drift or
  a red check's cause is reported, not fixed. Run the `plan-build` `SKILL.md` §2 *Concurrency* check first: a
  leftover sequencer stops the commit. Any other dirty path — a legacy row with no report, a later hunk on a
  path a `commit:` holds, a peer's file — is *not committed — unclaimed*: listed, committed if the user names
  it; in repo-only mode, its fixes only. Staged, `git diff --cached --name-only` shows only named paths; an
  open row's files stay, listed.
- `git push` of those commits to the current branch's existing upstream.

### What it stops for

Everything on [`STOPS.md`](../plan-shared/STOPS.md), and nothing else. When you stop, say what you
were about to do and the exact command, so a yes is one word.

## 1. Scope

Resolve the plan with the ladder in `CONVENTIONS.md`. This skill commits and pushes, so it **never
picks a plan by recency**. One rule: **no plan anywhere → audit the repo anyway, without asking**;
candidates listed at the last rung, or two or more plausible at any rung → list them with mtimes,
offer a repo-only audit, and stop — the user names a plan, or takes the audit.

A repo audit skips area 3 and the Progress check in area 5, and its report is labelled *no plan —
repo audit only*. "Is this change done?" is a first-class way to invoke this skill.

Then list every repo the work touched (`plan-build`'s `SKILL.md` §2 *Repository scope*): one audit per repo.

## 2. Audit, in order

| # | Area | Question it answers |
| - | --- | --- |
| 1 | Scope | Which plan, which repos, which worktrees? |
| 2 | Checks | Do the checks applicable to the actual change pass, by name? Full required suite for implementation; documentation checks for text-only work. |
| 3 | Verification | Does each of the plan's `## Verification` items pass — by its recorded result, or run now? |
| 4 | Commits | Is anything uncommitted, unpushed, or stashed? |
| 5 | Docs | Do README / AGENTS.md / CLAUDE.md / `docs/**` still describe reality? Which Progress rows are closed, parked, open — **and does every commit have a row?** Does the plan's `**Ticket:**` still match the plan's state? Read the ticket's state from the tracker in the same turn as the report — never carried from an earlier read, the conversation or memory — and say when a merged pull request closed it by itself |
| 6 | Cleanup | What did this plan leave on disk, with sizes, and is each item deleted, asked about or kept on purpose? |

**Area 2 follows the [global scope rule](../../claude/CLAUDE.md#finishing-a-plan):** text-only work gets
document checks; implementation (including executable input) gets the required full suite. Explicit requests
apply. Neither multiple steps nor this skill triggers unrelated checks; record these as **not applicable**
and do not repeat unchanged passing evidence — a run record that `../plan-build/scripts/check-run.sh current`
accepts is unchanged (`plan-build/RULES.md` rule 7). Enumerate the project's own scripts.
**Format-check is separate:** lint does not cover `.md`/`.json` that ESLint never parses.

**Area 3 reads before it runs.** A Verification item whose result a row's Notes already record — a
stage-time check — is reported from that row, citing its id; **do not re-run it**: its fixtures may be
gone by design. Run any other item now: PASS or FAIL, with the command's real output. An item that is
also one of the repository's own checks falls under area 2 — an obvious cause not *dirty at start* is
fixed, the check re-run — and area 3 reports the re-run's result, citing the fix. **Any other FAIL is
reported, never fixed**: a finding for the plan's own rows or `/plan-build`, not work for this
skill. No `## Verification` section reports *none*, not green. How-to: `CHECKLIST.md`, Verification.

## 3. Fix what the audit found

Work through the non-green areas in this order, verifying after each:

1. **Red checks first.** A commit on top of a failing suite is worse than no commit. Fix an obvious
   cause (one *dirty at start* is reported instead), re-run that check, report the real new result.
2. **Docs.** Fix the drift you can verify. Re-run `format:check` afterwards if it globs markdown.
3. **Commit**, then **push**. The message describes *the change*, not the plan step: `git log` readers
   never saw the plan. A plan's `**Ticket:**` identifier starts every commit — `ABC-123: <what changed>`,
   per `plan-ticket-tracking.md`; no ticket, no prefix, never an invented one. Right after each commit,
   log `commit: <short sha> <subject>` in the Run log. Push only to an **existing upstream** of the same
   name (`plan-shared/STOPS.md`); none is a new destination: stop, offer the exact `git push -u` line.
   Push the listed sha, pasted in, never a variable or a moving `HEAD` (`STOPS.md`): print
   `git rev-parse HEAD`, then `git log --oneline '@{u}'..<sha>` (`@{u}..HEAD` frozen), and push
   `git push origin <sha>:<branch>`. A listed commit neither so logged nor named by the user this session
   stops the push with the list; a yes covers only the shas shown. Repo-only mode always lists and asks.

   **Say what was left.** A dirty path nothing claims is reported *not committed — unclaimed*, not a stop.
4. **Cleanup.** Apply [CLEANUP.md](CLEANUP.md): measure what the plan left, with sizes; delete, ask once
   or keep each item. Area 6 is green only when every measured item is classified and nothing waits on an
   answer. Worktrees come out before the branches they hold, or git refuses the branch.
5. **Close the plan.** Confirm the table agrees with what happened, no row claiming more than the
   evidence shows. Closing is bookkeeping by the ledger rule above, never doing rows: a row is ticked
   only if its step demonstrably ran; every other row stays open and goes in the report.

   **Update each row as its step finishes, not all of them here.** `plan-progress-section.md` forbids
   batching a phase's rows at a boundary: the table records what was true *when*. This is the **checkpoint**.
   Notes go in with the icon, by `Edit`/`Write` and never Bash (`ui-rendered-files-use-write-tool.md`).

If a stop-list item blocks a step, do the rest first, then raise it, never leaving the fixable ones undone.

## 4. Report what you did

**Scale the report to what happened.** A clean audit with nothing to fix is one line:

```
done · 6/6 green · nothing outstanding
```

**When you fixed things**, lead with them — that is the news:

```markdown
Fixed: added 2 missing Progress rows · deleted run scratch (2.4 GB) · committed and pushed (a1b2c3d)
Not committed — unclaimed: src/retry.ts, README.md — no closed row or Run-log line claims them

| Area | Status | Detail |
| ---- | ------ | ------ |
| Checks | ✅ | bash -n ✓ · shellcheck ✓ · no project suite (said, not skipped) · formatter NOT RUN — none installed |
| Verification | ✅ | 2 items · PASS recorded in row B3's Notes, not re-run · PASS run now, `bash check.sh` exit 0 |
| Commits | ✅ | was 3 modified + 1 untracked; committed as a1b2c3d, pushed |
| Docs | ✅ | was: README omitted 3 files added last commit; fixed |
| Cleanup | ✅ | 4 items · deleted: `scratch/` 2.4 GB, worktree 140 MB · kept: run records 18 MB, a cited capture 2 MB |

disk: 41 GiB free now · 44 GiB at the run's start · 3 GiB less, 0.02 GiB of it this plan's
```

**When something stopped you**, that goes last and alone, with the exact command:

```
Not done — 1 stop-list item: 2 merged branches are deletion candidates this skill did not create.
  git branch -d feature/old-thing feature/other
```

End with a one-line verdict. **done** only when every row is closed, no Verification item fails,
nothing on the stop-list is outstanding and no clean-up item awaits an answer. Otherwise **not done**,
naming each non-empty kind apart — open rows with the command that runs them, parked rows with their
blockers, clean-up items asked (not also counted as stop-list items); anything fixable is fixed, not counted:

```
not done — open: 6, 7 → /plan-build <plan> · parked: 4 (needs yes) · 1 Verification FAIL · clean-up: 2 asked
```

## Examples

**`/plan-finish` after a feature lands** — suite green, 3 uncommitted files, one leftover scratch file
the plan created. Commits, pushes, deletes the scratch file, records the commit in the plan's table,
reports in three lines. Nothing on the stop-list, so nothing is put back to the user for a decision.

**`/plan-finish` on a half-run plan** — row 6 `🟡` with its file half-written, row 7 `⬜`, one other
file nothing claims, one Verification item failing. Lists that file as *not committed — unclaimed*;
leaves row 6's file uncommitted, listed with row 6; runs neither row; reports the FAIL
and fixes nothing: `not done — open: 6, 7 → /plan-build <plan> · 1 Verification FAIL`.

**`/plan-finish` with a stale plan table** — two commits have no Progress row and the README omits a
file added last commit. All three are mechanical and verifiable: fix, commit, push, report — never "shall I?".

**`/plan-finish` in a repo with no plan** — audits the working tree, labels the report *no plan — repo
audit only*, fixes what it finds, and commits only its own fixes and what the user names.

**Red suite** — 2 failing specs, obvious cause: fix, re-run, report the new result, continue. A cause
*dirty at start* is reported, not fixed; one not obvious stops with the failing names and what you tried.

**Merged branches present** — finishes everything else first, *then* raises the branches it did not
create: one batch question with the exact `git branch -d` line, not one prompt per branch. `--merged` lists
branches merged into the *current* branch, not proof they are merged upstream: present them as candidates.
