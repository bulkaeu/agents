# Hard rules

The safety surface of `/plan-build` and `/plan-continue`. Both `SKILL.md` files load this file
first, before resolving a plan. `EXECUTION.md` restates inline only the rules it enforces; this is
the canonical wording.

The stop table below is **reproduced in full** rather than cited. A rules file that sends you to a
second file to learn what you may not do is a two-hop read, and a partially-read rules file is how a
gate gets silently skipped.

## 1. Uninterrupted by default

Ordinary, reversible, in-scope work is simply done. Handing back a list of small, safe problems for
the user to authorise one at a time costs them the time these skills exist to save.

During execution the run asks **at most one question, after close-out**, covering the whole parked
set — **except the irreversible-outward set, which is asked one item at a time**. A database
migration apply or rollback, a deploy, and a publish to a live surface are never folded into the
batch: each is listed separately with its exact command, because a yes to "these six things" is
exactly the blanket approval `migration-apply-confirmation.md` refuses to accept — and a deploy is
no more recoverable than a migration. Everything else parked goes in the one batch.

So a run with four parked rows, one of them a deploy, asks **two** questions: the batch of three,
and the deploy on its own. Not four, and not one.

Pre-flight offers (derive a Progress table? proceed on a part-done plan?) sit outside this budget —
they happen before execution starts.

## 2. Park, don't halt

A step that hits the stop-list becomes `⛔` with the blocker named in Notes. A later row that
depends on it is parked too, with *"depends on N"*. **Every other row continues.** A blocked item
never justifies leaving the fixable ones undone.

The one sanctioned halt is a **hand-off row**, defined in `EXECUTION.md`.

## 3. The stop-list

Exhaustive. Everything else is work, not a question.

| Stop | Why |
| --- | --- |
| `git push --force`, deleting a remote branch, `git reset --hard`, amending a pushed commit | Destroys work or published history |
| Deleting a branch, worktree, or file **neither this run nor the plan it is executing** created | Not its to delete |
| Database migration apply/rollback | `migration-apply-confirmation.md` owns this; needs an explicit yes, asked on its own |
| Closing, reassigning, or deleting a tracker issue | `plan-ticket-tracking.md` owns this — creating is authorised, destructive edits are not |
| A step the plan itself marks `BLOCKED` or waiting on the user | The plan already said to stop |
| A red check whose fix is not obvious, or a doc change needing a judgment call on wording or scope | Guessing produces work the user has to undo |
| Anything outward-facing to a *new* destination — first push of a new repo, publishing, filing into a tracker not yet agreed | Approval for one destination is not approval for another |
| **Deploying** — shipping to any running environment | Promoted from `plan-finish`'s prose; not ordinary work whatever the plan says |
| **Publishing to a live surface** — a package registry, a public site, a shared channel | Same; the audience cannot be un-notified |

Pushing to a branch's **existing upstream** stays ordinary, exactly as in `plan-finish`. So do
`git add` and `git commit` of work in scope, by explicit path.

### Origin, and the three deliberate divergences

This table comes from `plan-finish`'s. Three rows differ on purpose:

1. **Deploys** — promoted from its prose (*"a plan step that deploys, migrates, publishes, sends,
   deletes data… stops"*) into a row of its own.
2. **Publishing to a live surface** — promoted from the same sentence.
3. **The deletion row, widened** from *"it did not create"* to *"neither this run nor the plan it is
   executing"*. A resumed run must be able to delete what an earlier session of the same plan
   created; the narrow reading parks every cleanup step that crosses a session boundary.

That sentence's *"touches anything outside this checkout"* is deliberately **not** promoted — it
would park every step that writes under `~/`, which is ordinary and reversible.

**For every other row: if this table and `plan-finish`'s ever differ, `plan-finish` wins and this
file is the one to fix.**

### Evidenced action

A `BLOCKED — wait for user` row whose awaited action is **already evidenced** — in this session's
context, or on disk — is *verified and ticked*, not parked. The marker gates the action, not the
bookkeeping after it. A migration someone already applied still may not be re-run; recording that it
happened is not running it.

## 4. A harness prompt is not a stop-list item

A `PreToolUse` hook may prompt on `git add`/`commit` even though this contract calls them ordinary.
That prompt is the environment's gate and it is legitimate. Answer it and continue. **Never**
rephrase a command, chain it, or wrap it to slip past a matcher — "uninterrupted" governs what you
decide to do, never how you get a command past a hook.

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
