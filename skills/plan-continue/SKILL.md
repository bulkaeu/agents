---
name: plan-continue
description: >-
  Resumes a plan already part-way through: reconciles its Progress table
  against what the repositories and disk actually show, repairs the rows that
  drifted, then runs the rest to the end without stopping for ordinary work.
  Offers --dry-run to propose corrections without applying them. Use when the
  user invokes /plan-continue or asks to continue, resume or pick up a plan.
disable-model-invocation: true
argument-hint: "[optional plan path] [--dry-run]"
---

# Plan continue — reconcile, then resume

A run that crashed, or a session that wandered off, leaves a table saying one thing and a repository
saying another. **Resuming from a table that lies re-does finished work or skips unfinished work**,
and both look like progress at the time. So this skill earns its keep before it executes a single
step: it makes the table true first, and says what it corrected.

For a plan whose rows are all still `⬜`, use `/plan-build` instead.

## Files this skill uses

The contract and the loop live in the **`plan-build` directory beside this one** — a deliberate
exception to bundling, because two copies of a safety contract drift and the drift is silent:

- `${CLAUDE_SKILL_DIR}/../plan-build/RULES.md` — read it **now**, before anything else.
- `${CLAUDE_SKILL_DIR}/../plan-build/EXECUTION.md` — the loop, hand-off rows, close-out, report.

On a host that does not set that variable, the same relative path from this file's own directory.
`install.sh` links every skill into the same parent, so the sibling is present under any normal
install. **If it is missing, say so and stop** — do not reconstruct the rules from memory.

## 0. Mode

Identical to `/plan-build`. In plan mode → call `ExitPlanMode`; otherwise nothing to do. Never
`bypassPermissions`, never re-shape a command to slip past a hook.

## 1. Resolve the plan

The same ladder as `/plan-build` and `/plan-status`: explicit path or `@`-mention → the session's
active plan → the project's `plansDirectory` (resolved against the settings file's own directory),
else `plans/` under the git toplevel → most recent in `~/.claude/plans/`, `~/.cursor/plans/`,
`.cursor/plans/`. Two or more plausible → list with mtimes and stop.

## 2. Repository scope

Before reconciling, list every repo the plan touches — its own paths, the cwd, anything in
`git worktree list` — and check each. Artifacts outside any repository are verified on disk, not by
`git log`. **No repository in scope is a state, not an error.** Work that is done but not yet
committed is verified from the working tree; absence of a commit is not absence of the work.

Run the concurrency check here too: another session's dirty tree or leftover sequencer means stop
and report, not clean up.

## 3. Reconcile — the part that earns the skill

For every row, compare what the table claims against what actually exists:

| Row | Checked against |
| --- | --- |
| `✅` | Commits since the previous `✅` in each repo; the working tree; on-disk artifacts for rows outside a repo; and whether its Notes cell records an **auditable result** rather than restating the step name |
| `🟡` | Re-verified from scratch. A crashed run leaves this icon behind — never assume it finished, and never assume it did not |
| `⛔` | Re-attempted **only** if the blocker is demonstrably gone. Otherwise it stays parked, reason intact |
| `⬜` | Nothing to check — it is the work ahead |

**The auditable bar is low on purpose: does the Note carry at least one thing you could go and
check?** A path, a count, a sha, a version, a byte size, a timing. `Wrote out/alpha.txt, 6 B` clears
it; `Wrote the file` does not. Set the bar higher and a healthy table fills with spurious
corrections — a cold reader applying a stricter reading turned one real drift into three.

**A thin Note is not a correction.** The icon is right; only the prose is weak. Note it in the
report as an observation and move on — never repair a row whose work actually happened.

**Repair the table to match reality**, then **name every correction in the report**: which row, what
the table claimed, what you found. A silent repair is indistinguishable from a table that was right
all along, and the difference is the whole point.

**A hand-off row already `✅` is accepted as done.** Its evidence is the run that printed it, which
by design left no commit and no artifact; reverting it would re-enter the hand-off forever.

**Rule 3's evidenced-action clause matters most here.** A `BLOCKED — wait for user` row whose
awaited action is already evidenced — in this session's context, or on disk — is verified and
ticked, not parked. The marker gates the action, not the bookkeeping after it.

## 4. `--dry-run`

Reconcile and report, **write nothing**. Corrections are *proposed* (`row 3: ✅ → ⬜, claims x, x
absent`), never applied. Then the *will park* list — rows carrying the explicit `BLOCKED` marker,
dependents excluded — after the reconciliation report. A clean dry-run is not clearance.

**`--dry-run` ends here. It does not execute — section 5 does not run.** The section that follows is
the real-run path; a dry run stops at this report and never enters the loop.

Report shape — follow it, so two runs on the same plan are comparable:

```
/plan-continue --dry-run · <plan file>
Scope:    <repos in scope, or "no repo">
Reconcile: <N> correction(s) proposed, 0 applied
  row <n>: <icon> → <icon> — <what the table claims>; <what is on disk>
Will park: row <n> <step-id> — <the marker, quoted>
Resume at: row <n>
Nothing written.
```

## 5. Resume

Start at the `🟡` row if one survived reconciliation, else the first `⬜`. Then the loop in
`EXECUTION.md`, unchanged: `🟡` → work → verify → `✅` with Notes, parking what `RULES.md` says to
park, close-out and one question at the end — unless a hand-off row ends the run first.

## Examples

**A run that crashed mid-step** — row 7 is `🟡`. Re-verified: the file it was writing exists but is
half-written. Row 7 goes back to `⬜`, the correction is named, and the loop redoes it properly.

**A table ahead of reality** — row 3 is `✅` claiming a migration file that is not on disk. Repaired
to `⬜`, named in the report, re-done, and the run continues to the end.

**A table behind reality** — three commits exist that no row mentions. The rows are ticked with the
commit shas as their Notes, and the report says so. Nothing is re-run.

**Resuming after a hand-off** — row 22 is `✅` with no commit behind it. Accepted as done, not
reverted. Rows 23–28 carry `BLOCKED — wait for user` markers and the user's six commands are in this
session's context: evidenced, so they are verified and ticked rather than parked. The run continues
to the last row.

**`--dry-run` on a drifted plan** — one proposed correction, the *will park* list, the fixture's
mtime unchanged. Nothing on disk moved.
