# Resuming a started plan — reconcile, then resume

Read this when the plan has already started — *Started* as `CONVENTIONS.md` defines it, the one test
every skill uses; this file keeps no copy of it. A run that crashed, or a session
that wandered off, leaves a table saying one thing and a repository saying another. **Resuming from a
table that lies re-does finished work or skips unfinished work**, and both look like progress at the
time. So a resumed run earns its keep before it executes a single step: it makes the table true
first, and says what it corrected.

The files this one names sit in the `plan-build` directory, beside it or under `scripts/`, except
`STOPS.md`, `CONVENTIONS.md` and `scripts/table-claims.sh`, which are in `plan-shared`.
`${CLAUDE_SKILL_DIR}` is `plan-build/`; where unset, this file's directory.

## Dirty paths a resumed run owns

Before reconciling, run the repository-scope, concurrency and tiers checks (`SKILL.md` §2): a
collision means stop and report, not clean up, and a `tiers.sh` error means stop. Their output —
`dirty at start` included — opens this run's Run log header, even when an earlier header already has one.
A `--dry-run` runs the same checks, writes no header and saves no `dirty-at-start` file: what they
found goes in its report. It skips the `disk:` measure, which only a header uses.

A dirty path is this run's own only if it is the plan file, an own path of the in-flight `🟡` row, or
an own path of a closed (`✅`) row that no commit on a Run log `commit:` line holds yet (a crash before
the plan's commit row) — as `EXECUTION.md` defines own paths, read from those rows' saved reports in
the run directory. Any other dirty path is foreign, recorded and left alone as `SKILL.md` §2 says, and
stops the run only when an open row names it. Work that is done but not yet committed is verified
from the working tree; absence of a commit is not absence of the work.

## Reconcile

For every row, compare what the table claims against what actually exists. Start with the evidence
the table itself cites:

```bash
bash ${CLAUDE_SKILL_DIR}/../plan-shared/scripts/table-claims.sh <plan> --repo <repo>... \
  --root "$(bash "${CLAUDE_SKILL_DIR}/scripts/row-snapshot.sh" dir <plan>)"
```

It lists, per row, each sha in Notes that resolves or is MISSING and each backticked path that
exists or is MISSING. A MISSING is a question, not a verdict — a path a row deleted or moved is
meant to be absent — but it is where drift shows first.

| Row | Checked against |
| --- | --- |
| `✅` | Commits since the previous `✅` in each repo; the working tree; on-disk artifacts for rows outside a repo; and whether its Notes cell records an **auditable result** rather than restating the step name |
| `🟡` | Re-verified from scratch. A crashed run leaves this icon behind — never assume it finished, and never assume it did not. For a code row, look for its base and passes in the run directory (`DISPATCH.md`) |
| `⛔` | Re-attempted **only** if the blocker is demonstrably gone. Otherwise it stays parked, reason intact |
| `⬜` | Nothing to check — it is the work ahead |

**The auditable bar is low on purpose: does the Note carry at least one thing you could go and
check?** — the *auditable Note* in `CONVENTIONS.md`. Set the bar higher and a healthy table fills
with spurious corrections.

**A thin Note is not a correction.** The icon is right; only the prose is weak. Note it in the
report as an observation and move on — never repair a row whose work actually happened.

**Repair the table to match reality**, then **name every correction in the report**: which row, what
the table claimed, what you found. A silent repair is indistinguishable from a table that was right
all along, and the difference is the whole point.

**A hand-off row already `✅` is accepted as done.** Its evidence is the run that printed it, which
by design left no commit and no artifact; reverting it would re-enter the hand-off forever.

**`STOPS.md`'s evidenced-action clause matters most here.** A `BLOCKED — wait for user` row whose
awaited action is already evidenced — in this session's context, or on disk — is verified and
ticked, not parked. The marker gates the action, not the bookkeeping after it. This run's own output
is never that evidence: a row that waits for the user to run something is not ticked by the run
doing it in their place.

## `--dry-run` on a started plan

Reconcile and report, **write nothing**. Corrections are *proposed* (`row 3: ✅ → ⬜, claims x, x
absent`), never applied. Then three lists, after the reconciliation report: *parked*, the rows already
`⛔` that reconciling keeps parked; *will park*, the open rows (`⬜`, `🟡`) carrying the explicit
`BLOCKED` marker, dependents excluded; and *will defer*, the open rows carrying `needs: screen`. A
closed or parked row is never in *will park*, marker or not: state comes from the icon. Each list,
and `Resume at`, reads the table as the proposed corrections would leave it. A clean dry-run is not
clearance.

**`--dry-run` ends here. It does not execute — Resume does not run.** The section that follows is
the real-run path; a dry run stops at this report and never enters the loop.

Report shape — follow it, so two runs on the same plan are comparable:

```
/plan-build --dry-run · <plan file>
Scope:    <repos in scope, or "no repo">
Tiers:    <tiers.sh's line, or its error>
Pre-flight: concurrency pass · foreign dirty paths: <repo> <n>, …   |   REFUSED — collision: <paths>
Reconcile: <N> correction(s) proposed, 0 applied
  row <n>: <icon> → <icon> — <what the table claims>; <what is on disk>
Parked:   row <n> <step-id> — <the blocker in its Notes>
Will park: row <n> <step-id> — <the marker, quoted>
Will defer: row <n> <step-id> — needs: screen
Resume at: row <n>   |   none — no open row
A clean dry-run is not clearance: stops other than the markers are recognised at execution.
Nothing written.
```

A list with nothing in it prints `none` after its label, and one with several rows repeats its label,
one line per row (corrections stay indented under `Reconcile:`). `foreign dirty paths:` names every
repo in scope with its count, zeros included; with no repo in scope, `Pre-flight:` reads
`concurrency no repo` and carries no count. A `🟡` row that is kept prints
`row <n>: 🟡 kept — <its partial files>` and is not counted as a correction.

A refusal, for a collision or a `tiers.sh` error, prints the lines down to `Pre-flight:`
(`Pre-flight: REFUSED — tiers` for the error, which `Tiers:` carries), then the last two lines; it
does not reconcile. Print the lines as shaped, with no added parentheticals; anything else worth
saying goes under `Reconcile:` as an `observation:` line.

## Resume

Start at the **first open row in table order** — `🟡` or `⬜`. Usually that is the `🟡` a crashed
run left, but a `✅` that reconciliation demoted to `⬜` comes before it and runs first; starting at
the `🟡` would skip it for good. Then the loop in `EXECUTION.md`, unchanged: `🟡` → work → verify →
`✅` with Notes, parking what `RULES.md` says to park, final review, close-out and one question at
the end (`CLOSEOUT.md`) — unless a hand-off row ends the run first. Record a run base only if the
Run log has none (`EXECUTION.md`, *The loop*).

**Partial work on a `🟡` code row is kept, not discarded.** A fresh implementer gets a brief that
names the partial files as its starting point and finishes the row; its diff, from the recorded base
or `HEAD` if none was recorded, shows the partial work and the rest together, and the reviewer checks
all of it. Throwing the partial work away would discard what the crashed run got right. **In the
Reconcile report every `🟡` gets a line**: `✅` if it proves finished, `⬜` if nothing of it
exists, or `🟡` kept with its partial files named.

## Examples

**A run that crashed mid-step** — row 7 is `🟡`, and the file it was writing exists but is
half-written, uncommitted. The Reconcile line names it; a fresh implementer finishes from it, a
reviewer passes the whole row, and it ticks.

**A table ahead of reality** — row 3 is `✅` claiming a migration file that is not on disk. Repaired
to `⬜`, named in the report, re-done, and the run continues to the end.

**A table behind reality** — three commits exist that no row mentions. The rows are ticked with the
commit shas as their Notes, and the report says so. Nothing is re-run.

**Resuming after a hand-off** — row 22 is `✅` with no commit behind it. Accepted as done, not
reverted. Rows 23–28 carry `BLOCKED — wait for user` markers, and the output of the user's six
commands is in this session's context: evidenced, so they are verified and ticked rather than parked.
The run continues to the last row.

**`--dry-run` on a drifted plan** — one proposed correction, the *will park* list, the fixture's
mtime unchanged. Nothing on disk moved.
