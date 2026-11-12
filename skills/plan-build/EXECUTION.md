# The execution loop

Read by `/plan-build`, starting or resuming. Read [RULES.md](RULES.md) first — this file assumes
it and does not repeat the stop-list. Dispatched rows follow [DISPATCH.md](DISPATCH.md).

## Contents

- The loop — one row at a time
- Classifying a row — dispatch or inline
- The verification gate
- When to commit
- The Run log
- Hand-off rows — a sanctioned halt, beside `STOPS.md`'s safety halts
- The spin guard
- After the last row

## The loop — one row at a time

Rows run in **table order**. For each:

1. **Mark `🟡`.** One `Edit`, icon only.
2. **Find the work.** The body section backing the row, located by *name reference* — rows cite
   sections and sections cite rows, many-to-many. Position is not the mapping: the section next to a
   row is not necessarily its section.
3. **Classify it** — below — and do it: dispatched per `DISPATCH.md`, or inline, under `RULES.md`.
4. **Pass the verification gate** — below. The row's own done-state, not a general sense that it
   went fine. If the step names no done-state, it is under-specified: say so rather than invent one.
5. **Mark `✅` and write the Notes cell in the same edit** (rule 5). Counts, versions, paths, the
   real command output, and for a dispatched row its `review:` token.
6. **Commit** if the row calls for it — below — then log it in the Run log. Then the next row.

**Keep the user posted.** After a row closes or parks, send one chat line: `<row id> <icon> ·
<closed>/<total> · <elapsed since the run's start>`. While a helper works, the `🟡` row's Notes cell
names its sub-step — dispatched, reported, in review, fix round *n* — until the result replaces it
(rule 5). A turn never ends while a dispatched helper is still running unless its last line says
which row, which helper, and that the run continues when it reports: silence reads as a stall.

A row that hits the stop-list becomes `⛔` with the blocker in Notes, and rows depending on it get
`⛔` *"depends on N"* — then the loop **continues** with the rest (rule 2), bar one: no usable report.

**A `needs: screen` row is deferred while any other runnable row remains**: it stays `⬜`, the Run log
gets `deferred: <row id> — needs: screen`, and the loop goes on with every row that does not depend on
it. When only deferred rows and their dependents are left, the run asks once: the rows by id, and that
they need the screen until they finish. That ask is `STOPS.md`'s stop for a step the plan marks as
waiting on the user, batched so the user is interrupted once. On yes, they run back to back in table
order, then their dependents. On no, or no answer, they park with *needs: screen* as the blocker,
their dependents with *depends on N*, and the run closes out.

**A dispatched row acts only on its own paths**: the union of **Changed** in every `report-<n>.md` it has, all
rounds, symlinks resolved as in `paths-<n>.txt` (`/tmp` is `/private/tmp` on macOS). A **foreign path**, in
the latest `paths-<n>.txt` but not own, is never restored, removed or committed: it **stops the run** — print
them and `git status --short`, wait for the user (likely a peer). `outside-<n>.txt` lists changes beyond the
row's `--path` scope (`DISPATCH.md` §6) in a shared checkout: other sessions' work, left alone too, but no
stop. An own path there wrote outside the brief: park the row. **No usable report** (a crash, or no
**Changed**) hides own paths: park the row, leave the tree, stop the run with the diff's path list.

**A dispatched row that parks leaves no edits behind.** Before the next row, the controller restores the own
paths in its last diff and `outside-<n>.txt` (or a fresh `diff`, if it parked before one) to the row's base:
tracked files from the base sha, files untracked at base from `rows/<row id>/untracked/`, files the row
created removed. It says so in the row's Notes; the diff stays in the run directory as the record.

**Scope changes go in the table as they happen.** A step you discover is needed becomes a row where
it actually ran, never beside a similar one — a table reading `E1 E2 E5 E3 E4` makes every reader
rebuild the real order. Give it a suffixed id (`3a`, `3b`) per `../plan-add/MATCHING.md` §6, never
renumbering: `rows/<id>/`, Notes' review tokens and the Run log cite ids. A skipped step gets `⏭️`
and a reason; silent omission and a recorded skip look identical now and different six weeks later.

**Never re-dispatch a `✅` row.** After a context summary, trust the table and Run log over memory.

## Classifying a row — dispatch or inline

- **Dispatch** a row that creates or changes files inside the plan's repositories, other than the
  plan itself. An implementer builds it and a separate reviewer checks it (rule 11).
- **Inline** everything else — bookkeeping the controller does itself: table and Run log edits, git
  operations, running checks, hand-offs, and scratch fixtures outside those repositories.
- **Unsure** means dispatch: an unreviewed code change is the failure, a reviewed one-liner costs little.

## The verification gate

Before any `✅`, fresh in the same turn as the tick:

- the row's done-state check, with its output in Notes, either run by the controller or cited from a
  record `check-run.sh current` accepts (`RULES.md` rule 7, which also allows one logged retry);
- every file the row claims exists, every sha it cites resolves, and every review file the row's
  Notes cite — the `review:` token, and any other `review-<n>.md` a fix round added —
  `../plan-shared/scripts/table-claims.sh` checks all three across the repos in scope, run with
  the run directory (`row-snapshot.sh dir <plan>` prints it) also passed as a `--root`, so the
  review token's `rows/<row id>/review-<n>.md` path resolves;
- for a dispatched row, a saved `Verdict: PASS` review, nothing at Medium or above open (`DISPATCH.md` §7).

A subagent's claim clears none of these (rule 9).

## When to commit

- **A dispatched row commits after its tick**, by explicit path — its own paths in its final diff —
  with a message describing the change, not the row id, prefixed with the plan's ticket id if it
  has one. A crash then loses at most one row, and the next row's base is clean.
- **Unless the plan has its own commit row** for that work: then that row commits, and the
  executor does not pre-empt it.
- The plan's own table and Run log are committed by the plan's commit rows, or at close-out.
- `git status --short` between staging and committing shows only the paths you named (rule 6).

## The Run log

A `## Run log` section after the plan's body, written by the controller as things happen — it is
in the file, so it survives a context summary. It holds:

- a header per run: the date, the `tiers:` line (`SKILL.md` §2), the starting commits, the run base;
- every ruling, `R<n> · <row id> · <what> — <why> — <cost if wrong>`;
- every commit the run makes — dispatched row, commit row, close-out or fix wave — as
  `commit: <short sha> <subject>`, in the Run log edit right after that commit;
- every inline row that changes files, `inline <row id>: <paths>`;
- every model or effort step-up with its reason, and, on a row carrying a `review:` marker, `deep` or
  `default`, the reviewer's tier and reason for every review of that row, whether or not the marker
  changed anything — one line per review, naming the row and its `review-<n>.md` (`DISPATCH.md`
  §3). It is also the step-up's line when there is one, so a fix loop whose tier changes (round 3,
  a stall) still shows which review ran on which tier:
  `<row id> · review-<n>.md — reviewer on the strongest tier: review: deep marker`,
  `<row id> · review-<n>.md — reviewer on the default tier: review: default holds a step that
  deletes data`, `<row id> · review-<n>.md — reviewer on the default tier: review: default marker,
  step not risky`, `<row id> · review-<n>.md — reviewer on the strongest tier: fix round 3, which
  review: default does not cancel`;
- deferred findings, the Low and Very Low ones, one line each with `file:line`;
- the final review's file and verdict.

Old `✅` rows without a `review:` token are not drift: they predate this loop.

## Hand-off rows — a sanctioned halt, beside `STOPS.md`'s safety halts

A row whose step is to give the user work to do outside this run and stop — its text says
**`hand-off row`** — ends the run mid-table:

1. Print exactly what the row says to print.
2. Tick it `✅`.
3. **End — with no final review, no closing question and no close-out.** They belong to the run
   that resumes after the user's part.
4. Rows behind it stay `⬜`.

**Name who picks up the parked set.** A hand-off defers the closing question, so anything parked
before it has no scheduled owner — and if the hand-off is the *last* row, deferring is indefinite.
The printed block must therefore say what resumes the plan (normally `/plan-build <plan path>`)
and list the parked rows it will have to answer for. A hand-off that ends the table with rows still
`⛔` and no named resumption is a leak, not a halt.

This is the only place a run stops before the last row. It is not a stop-list item and needs no
approval: the plan author put it there.

## The spin guard

**If two consecutive rows are ticked `✅` with nothing verifiable to put in Notes, stop and
report.** Marching to the end producing un-auditable ticks looks like progress and is the opposite
— it destroys the record the table exists to keep. Say which rows, and what you could not measure.

**`⛔` and `⏭️` rows do not count toward the guard.** Their Notes carry a named blocker or reason;
two parked rows in a row is a normal shape, not a spin.

## After the last row

The final review, close-out, the single question and the report — and the order they run in — are
in [CLOSEOUT.md](CLOSEOUT.md), read when the last row closes. A hand-off row defers all of them.
