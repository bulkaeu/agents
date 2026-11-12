---
name: plan-build
description: >-
  Runs a plan from its first open step to its last without stopping for
  ordinary work, and for a plan already started reconciles its Progress table
  against the repositories first — leaving plan mode, handing each code step
  to a fresh subagent and having a second one review it, ticking each row as
  it goes, parking anything gated and asking about the whole parked set once
  at the end. Offers --dry-run to rehearse. Use when the user invokes
  /plan-build or asks to build, execute, implement, run, continue, resume or
  pick up a plan.
disable-model-invocation: true
argument-hint: "[optional plan path] [--dry-run]"
---

# Plan build — start or resume a plan

A plan that has been approved and then executed one permission prompt at a time was not worth
approving. This skill takes a plan, fresh or part-way through, and works it to the last row,
stopping only where stopping is the correct answer.

Read each file when first needed, not before: an early read spends context the run needs later.

| When | Read |
| --- | --- |
| At invocation | This file; [RULES.md](RULES.md) and [the stop-list](../plan-shared/STOPS.md), the safety surface this file assumes; [CONVENTIONS.md](../plan-shared/CONVENTIONS.md), shared terms and the plan ladder; [EXECUTION.md](EXECUTION.md), the loop |
| The plan is started (§2) | [RESUME.md](RESUME.md), which reconciles it before the loop |
| The first row classified as dispatch | [DISPATCH.md](DISPATCH.md), how a code row is built and reviewed, and its two prompts beside it |
| The last row closes, or a `--dry-run` | [CLOSEOUT.md](CLOSEOUT.md); a dry run also reads `DISPATCH.md` §3 for its per-tier counts |

## Standing orders

After a context summary, re-read these, `RULES.md`, the Progress table, the Run log, any late file.

1. Make the table true before running anything, and name every correction.
2. The table and the Run log are the ledger. Never re-dispatch a `✅` row.
3. A code row is built by an implementer and checked by a separate reviewer; the controller writes
   no code on it (`DISPATCH.md`).
4. Only the controller writes the table, the Run log and commits.
5. Stop only for `STOPS.md`. Every other judgement is a ruling, logged, and the run goes on.
6. One question, after close-out — bar `STOPS.md`'s asked-alone set, each asked on its own, and its safety
   halts, which end the run.
7. Dispatch on the tiers this run's `tiers.sh` printed (§2), `model` set on every dispatch, and log
   each dispatched row's models: `<row id> · implementer <model> · reviewer <model>`, one line per
   pass. A tier recalled from memory or copied from an earlier run's Run log is a defect.

## 0. Mode

A `SKILL.md` body cannot set the permission mode; only the harness can.

- **In plan mode** → call `ExitPlanMode`. One approval, and the session returns to
  `permissions.defaultMode`.
- **Not in plan mode** → nothing to do.
- **Never** attempt `bypassPermissions`, and never re-shape a command to slip past a hook (rule 4).

If the resulting mode still prompts on ordinary edits, say so in one line and carry on under it.
Working slowly is a cost; working around the harness is a breach.

## 1. Resolve the plan

The ladder in `CONVENTIONS.md`. This skill executes, so **at the last rung it lists the candidates
and stops** rather than picking the most recent — and two or more plausible at any rung means list
and stop. Never guess: executing the wrong plan is not a mistake you can take back.

Read the whole file. The body is where the steps are actually specified.

## 2. Pre-flight

All five, before any work:

| Check | On failure |
| --- | --- |
| A conforming `## Progress` table exists | Offer **once** to derive one from the body, then stop |
| Started or not (below) | Never a failure: a started plan reads [RESUME.md](RESUME.md) and reconciles before the loop; an unstarted one goes straight to the loop |
| No concurrent session | Report what you found and stop |
| Repository scope known | Proceed; *no repo* is a state, not a failure |
| Tiers resolve | Report `tiers.sh`'s error and stop — never fall back to `inherit` |

**Tiers**: run `bash ${CLAUDE_SKILL_DIR}/../plan-shared/scripts/tiers.sh <host>` — `opencode`, `codex`,
`cursor`, `claude-code`, or `other` for any host the table does not name — now, and again after any
context summary. It reads `CONVENTIONS.md`'s table from disk; put its one-line output in the run's
Run log header verbatim. That line, not an earlier read of the table and not a previous run's header,
is what every dispatch in this run uses.

**Concurrency** (`shared-state-between-agents.md`), in every repo in scope: `git status --short` for
work that is not yours, and `.git/CHERRY_PICK_HEAD`, `.git/MERGE_HEAD`, `.git/rebase-merge` for a
sequencer someone left mid-flight. Another session's dirty tree is not yours to clean, and a
cleanup command is the dangerous one.

**Repository scope**: list every repo the plan touches — the plan's own paths, the cwd, and anything
in `git worktree list` — and check each. Rows whose artifacts live
outside any repository are verified on disk, not by `git log`. **No repository in scope is a state,
not an error**: the concurrency check reports *no repo* and passes.

**On Codex**, pre-flight also prints a one-line reminder when the session's own model or effort
differs from the `plan-run` profile (`CONVENTIONS.md`, *Model tiers*, Controller). It never stops.

**Started** means any row is `🟡` or `✅`, or a `⛔` row's Notes record a run's blocker.
Author-parked rows do not count: a `⛔` the plan's author wrote before any run — the pending-ticket
row `plan-ticket-tracking.md` requires is the usual one — is listed as already parked, and an
unstarted run starts at the first `⬜`.

The offer to derive a table is outside rule 1's one-question budget, which governs execution.

## 3. `--dry-run`

Pre-flight only on an unstarted plan; on a started one, reconcile-and-report in
[RESUME.md](RESUME.md)'s shape instead. An unstarted plan prints:

- the **verdict** — would run from row *N*, or refuses because …;
- the ***will park*** list — rows whose step text carries the explicit `BLOCKED` marker, printed on
  both verdicts including a refusal — and, before it, any author-parked `⛔` rows as *already
  parked*;
- the ***will defer*** list — rows carrying `needs: screen` (`EXECUTION.md`, *The loop*);
- the **dispatch count** — the rows `EXECUTION.md` would classify as dispatch, by id, and the
  subagent floor that implies (*Cost*, below), so the cost is known before anything starts,
  and the floor's count per model tier from `DISPATCH.md` §3 — each row's implementer and reviewer
  judged from its step text, markers included, and the final review's tier as the table predicts it;
- and **writes nothing**.

Rows that merely *depend* on a marked row are not listed: dependent parking is an execution-time
consequence of rule 2, and a dry run is a text scan, not a simulation.

State plainly, every time, that the other stop-list categories — deploys, migrations, sends, deletions,
judgement calls — are recognised at execution time from what a step actually does. **A clean
dry-run is not clearance.**

**A dry run makes no offers.** Section 2's offer to derive a table is absent here: accepting it
means executing, which a dry run cannot do. Report the refusal and stop.

*Cost.* A dispatched row costs at least 2 subagents, and up to 9 — one `NEEDS_CONTEXT` retry, then
three fix rounds; the final review adds 1 to 3. Only code rows dispatch, each on `DISPATCH.md` §3's
tiers: implementers standard and reviewers strong by default, stepping up on its table's triggers.
The floor is 2 × dispatched rows + 1.

Report shape — follow it, so two runs on the same plan are comparable:

```
/plan-build --dry-run · <plan file>
Verdict:  would run from row <n>   |   REFUSED — <why>
Pre-flight: table <pass/fail> · all-⬜ <pass/fail> · concurrency <pass/no repo> · scope <…>
Tiers:    <tiers.sh's line, or its error>   (the floor's per-tier counts below use these models)
Parked:   row <n> <step-id> — already parked by the author: <its Notes>
Will park: row <n> <step-id> — <the BLOCKED marker, quoted>
           (dependents are not listed; they park at execution under rule 2)
Will defer: row <n> <step-id> — needs: screen
Dispatch: <k> rows (<ids>) → at least <2k + 1> subagents · standard <a> · strong <b> · strongest <c>
A clean dry-run is not clearance. Nothing written.
```

When no plan resolves, the shape is fixed too, so runs from different directories compare:

```
/plan-build --dry-run · (no plan resolved)
Verdict:  REFUSED — plan not resolved, <N> candidates at rung <r>
<the candidate list, as CONVENTIONS.md shapes it>
A clean dry-run is not clearance. Nothing written.
```

## 4. Execute

Per [EXECUTION.md](EXECUTION.md): record the run base, then `🟡` → work (dispatched or inline) →
verify → `✅` with Notes, one row at a time, parking what rule 3 says to park.

## 5. Review, close out, ask, report

The final review, close-out, the single question and the report are all in [CLOSEOUT.md](CLOSEOUT.md) —
including the order they happen in and the fact that `plan-finish`'s own closing ask is folded into
the one question.

**Unless the run ended at a hand-off row**, which defers all of them to the run that resumes.

## Examples

**A fresh 12-row plan** — pre-flight clean, twelve rows worked in order: five code rows each built by
an implementer, passed by a reviewer and committed; seven inline. Final review PASS, checks green,
close-out applied from `plan-finish/CHECKLIST.md`, no parked rows. Report is one line plus any
rulings. The user was asked nothing after the initial approval.

**A reviewer catches a defect** — row 4's reviewer finds a CONFIRMED path traversal the step's
"copy verbatim" would ship. One fix round under a logged ruling, a re-review reports it ADDRESSED,
and the row ticks with both review files cited. The ruling is in the report.

**A plan with a deploy step at row 8** — rows 1–7 and 9–12 done, row 8 `⛔` *deploy, rule 3*, and
whatever depended on it parked with *depends on 8*. Close-out runs on what landed. One closing
question, with the exact deploy command, so a yes is one word.

**A plan with a migration and a deploy** — each asked on its own with its exact command, never folded
into a batch: `STOPS.md` puts both in the asked-alone set. With one other parked row, that is three
questions — the migration, the deploy, and a batch of one.

**`/plan-build` on a part-done table** — is reconciled and resumed: each `✅` row checked against
the repositories, every correction named, then the loop from the first open row. It does not
silently re-run finished steps.

**`--dry-run` on the same plan** — the proposed corrections, the *will park* list, and the reminder
that the list covers only the explicit markers. Nothing written.
