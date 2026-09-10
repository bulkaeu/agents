# Hard rules

The safety surface of `/plan-build` and `/plan-continue`. Both `SKILL.md` files load this file
first, before resolving a plan. `EXECUTION.md` restates inline only the rules it enforces; this is
the canonical wording.

**The stop-list itself lives in [`../plan-shared/STOPS.md`](../plan-shared/STOPS.md)** — one file
shared with `plan-finish`, so the two can never disagree. Read it now, with this one; rules 1, 3 and
4 below are defined by it.

## 1. Uninterrupted by default

Ordinary, reversible, in-scope work is simply done. Handing back a list of small, safe problems for
the user to authorise one at a time costs them the time these skills exist to save.

During execution the run asks **at most one question, after close-out**, covering the whole parked
set — **except the asked-alone set in `STOPS.md`**, each of which is asked on its own with its
exact command.

Pre-flight offers (derive a Progress table? proceed on a part-done plan?) sit outside this budget —
they happen before execution starts.

## 2. Park, don't halt

A step that hits the stop-list becomes `⛔` with the blocker named in Notes. A later row that
depends on it is parked too, with *"depends on N"*. **Every other row continues.** A blocked item
never justifies leaving the fixable ones undone.

The one sanctioned halt is a **hand-off row**, defined in `EXECUTION.md`.

## 3. The stop-list

`STOPS.md`, in full — including its evidenced-action clause: a `BLOCKED — wait for user` row whose
awaited action is already evidenced is verified and ticked, not parked. Everything not on that list
is work, not a question.

## 4. A harness prompt is not a stop-list item

`STOPS.md` states it. In short: answer the hook's prompt and continue; never re-shape a command to
get past a matcher.

## 5. One boundary, one edit

Icon and Notes together, with `Edit`/`Write` and never Bash (`ui-rendered-files-use-write-tool.md`),
at the moment the boundary is crossed. Never backfilled at the end: the table exists to record what
was true *when*, and one edit at the close destroys exactly that. Notes record the measured
result — counts, versions, paths — not the intent. A `✅` whose Notes restate the step name is a
`✅` nobody can audit.

## 6. Shared state

Stage by explicit path. **Never `git add -A` or `git add .`** — a blanket add publishes another
session's uncommitted work under your message. Between staging and committing, `git status --short`
must show only the paths you named. Announce before changing shared state, not after. Leave another
session's sequencer files and dirty tree alone (`shared-state-between-agents.md`).

## 7. A check you did not run is not a check that passed

Name what did not run, and why. "Tests pass" is not a result; the counts are.

## 8. Never bend the plan to make a step pass

A step that cannot be done as written becomes `⛔` with the reason — not a quietly narrowed step
that ticks green. Rewriting the target to match what you managed is the one failure this whole
contract exists to prevent.

## 9. Subagents are not authoritative

An implementer's `DONE` is a claim, and so is a reviewer's `PASS`. The controller runs the
done-state check itself, reads the diff, and confirms every claimed file and sha before it ticks.
**Only the controller writes** the table, the Run log and commits; a subagent that did any of them
has left work to be undone, not work to be kept.

## 10. Rulings, not stalls

A judgement the stop-list does not cover — an ambiguous step, a finding that contradicts the
wording, a fix loop that stopped converging — is made, not asked. Log it in the Run log as
`R<n> · <row id> · <what> — <why> — <cost if wrong>` and carry on; the report lists every ruling
under **Rulings I made**. A ruling never releases a stop-list item.

## 11. Independent review

A row that changes files in the plan's repositories is built by one subagent and reviewed by
another that did not write it, and the run ends with a review of its whole diff — the mechanics are
in `DISPATCH.md`. Independence comes from a reviewer the run dispatches itself, never from how some
other command happens to behave on a given call. Without subagents, the row's Notes say
`review: same-agent`.
