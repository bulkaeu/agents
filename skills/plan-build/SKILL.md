---
name: plan-build
description: >-
  Runs a plan that has not started, from its first step to its last, without
  stopping for ordinary work — leaving plan mode first, handing each code step
  to a fresh subagent and having a second one review it, ticking each Progress
  row as it goes, parking anything gated and asking about the whole parked set
  once at the end. Offers --dry-run to rehearse. Use when the user invokes
  /plan-build or asks to build, execute, implement or run a plan end to end.
disable-model-invocation: true
argument-hint: "[optional plan path] [--dry-run]"
---

# Plan build — run a fresh plan end to end

A plan that has been approved and then executed one permission prompt at a time was not worth
approving. This skill takes a plan whose steps are all still waiting and works it to the last row,
stopping only where stopping is the correct answer.

Read [RULES.md](RULES.md) and [the stop-list](../plan-shared/STOPS.md) now — together they are the
safety surface, and this file assumes both. The loop and the close-out are
[EXECUTION.md](EXECUTION.md); how a code row is built and reviewed is [DISPATCH.md](DISPATCH.md),
with its two prompts beside it; shared terms and the plan ladder are
[CONVENTIONS.md](../plan-shared/CONVENTIONS.md).

**For a plan already part-way through, this is the wrong skill.** Use `/plan-continue`, which
reconciles the table against reality before resuming.

## Standing orders

Re-read these, `RULES.md`, the Progress table and the Run log after any context summary.

1. The table and the Run log are the ledger. Never re-dispatch a `✅` row.
2. A code row is built by an implementer and checked by a separate reviewer; the controller writes
   no code on it (`DISPATCH.md`).
3. Only the controller writes the table, the Run log and commits.
4. Stop only for `STOPS.md`. Every other judgement is a ruling, logged, and the run goes on.
5. One question, after close-out — bar `STOPS.md`'s asked-alone set, each asked on its own.

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

All four, before any work:

| Check | On failure |
| --- | --- |
| A conforming `## Progress` table exists | Offer **once** to derive one from the body, then stop |
| Every row is `⬜` (or `⏭️`), bar author-parked `⛔` rows | It is a resume — say so, point at `/plan-continue`, offer once to proceed anyway |
| No concurrent session | Report what you found and stop |
| Repository scope known | Proceed; *no repo* is a state, not a failure |

**Concurrency** (`shared-state-between-agents.md`), in every repo in scope: `git status --short` for
work that is not yours, and `.git/CHERRY_PICK_HEAD`, `.git/MERGE_HEAD`, `.git/rebase-merge` for a
sequencer someone left mid-flight. Another session's dirty tree is not yours to clean, and a
cleanup command is the dangerous one.

**Repository scope**: list every repo the plan touches the way `plan-finish` does — the plan's own
paths, the cwd, and anything in `git worktree list` — and check each. Rows whose artifacts live
outside any repository are verified on disk, not by `git log`. **No repository in scope is a state,
not an error**: the concurrency check reports *no repo* and passes.

**Author-parked rows are not a resume.** A `⛔` the plan's author wrote before any run — the
pending-ticket row `plan-ticket-tracking.md` requires is the usual one — passes this check. It is
listed as already parked, and the run starts at the first `⬜`. A `⛔` whose Notes record a run's
blocker, or any `🟡`/`✅`, is a resume.

These two pre-flight offers are outside rule 1's one-question budget, which governs execution.

## 3. `--dry-run`

Pre-flight only. Prints:

- the **verdict** — would run from row *N*, or refuses because …;
- the ***will park*** list — rows whose step text carries the explicit `BLOCKED` marker, printed on
  both verdicts including a refusal — and, before it, any author-parked `⛔` rows as *already
  parked*;
- the **dispatch count** — the rows `EXECUTION.md` would classify as dispatch, by id, and the
  subagent floor that implies (`DISPATCH.md`, *Cost*), so the cost is known before anything starts;
- and **writes nothing**.

Rows that merely *depend* on a marked row are not listed: dependent parking is an execution-time
consequence of rule 2, and a dry run is a text scan, not a simulation.

State plainly, every time, that the other stop-list categories — deploys, migrations, sends, deletions,
judgement calls — are recognised at execution time from what a step actually does. **A clean
dry-run is not clearance.**

**A dry run makes no offers.** The pre-flight offers in section 2 — derive a table, proceed anyway
on a part-done plan — are absent here: accepting either means executing, which a dry run cannot do.
Report the refusal and stop.

Report shape — follow it, so two runs on the same plan are comparable:

```
/plan-build --dry-run · <plan file>
Verdict:  would run from row <n>   |   REFUSED — <why>
Pre-flight: table <pass/fail> · all-⬜ <pass/fail> · concurrency <pass/no repo> · scope <…>
Parked:   row <n> <step-id> — already parked by the author: <its Notes>
Will park: row <n> <step-id> — <the BLOCKED marker, quoted>
           (dependents are not listed; they park at execution under rule 2)
Dispatch: <k> rows (<ids>) → at least <2k + 1> subagents
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

The final review, close-out, the single question and the report are all in `EXECUTION.md` —
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

**`/plan-build` on a part-done table** — refuses, names the `✅` rows it found, points at
`/plan-continue`, and offers once to proceed anyway. It does not silently re-run finished steps.

**`--dry-run` on the same plan** — the refusal, the *will park* list, and the reminder that the list
covers only the explicit markers. Nothing written.
