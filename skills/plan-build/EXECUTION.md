# The execution loop

Shared by `/plan-build` and `/plan-continue`. Read [RULES.md](RULES.md) first — this file assumes
it and does not repeat the stop-list. Dispatched rows follow [DISPATCH.md](DISPATCH.md).

## Contents

- The loop — one row at a time
- Classifying a row — dispatch or inline
- The verification gate
- When to commit
- The Run log
- Hand-off rows — the one sanctioned halt
- The spin guard
- The final review, then close-out
- Order, stated once
- The report

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
6. **Commit** if the row calls for it — below. Then the next row.

A row that hits the stop-list becomes `⛔` with the blocker in Notes, and rows depending on it get
`⛔` *"depends on N"* — then the loop **continues** with everything else (rule 2).

**Scope changes go in the table as they happen.** A step you discover is needed becomes a row where
it actually ran, never appended beside a thematically similar one — a table reading `E1 E2 E5 E3 E4`
makes every later reader reconstruct the real order. Renumber rather than misplace. A step you are
told to skip gets `⏭️` and a reason; silent omission and a recorded skip look identical in the body
and completely different six weeks later.

**Never re-dispatch a `✅` row.** After a context summary, the table and the Run log say what is
done; trust them over a memory of intending to do it.

## Classifying a row — dispatch or inline

- **Dispatch** a row that creates or changes files inside the plan's repositories, other than the
  plan itself. An implementer builds it and a separate reviewer checks it (rule 11).
- **Inline** everything else — bookkeeping the controller does itself: table and Run log edits, git
  operations, running checks, hand-offs, and scratch fixtures outside those repositories.
- **Unsure** means dispatch. An unreviewed code change is the failure; a reviewed one-line edit only
  costs a little time.

## The verification gate

Before any `✅`, fresh in the same turn as the tick:

- the row's done-state check, run by the controller, with its output in Notes;
- every file the row claims exists, every sha it cites resolves, and every review file the row's
  Notes cite — the `review:` token, and any other `review-<n>.md` a fix round added —
  `../plan-shared/scripts/table-claims.sh` checks all three across the repos in scope, run with
  the run directory (`row-snapshot.sh dir <plan>` prints it) also passed as a `--root`, so the
  review token's `rows/<row id>/review-<n>.md` path resolves;
- for a dispatched row, a saved review with `Verdict: PASS` and nothing at Medium or above left
  open (`DISPATCH.md` §7).

A subagent's claim clears none of these (rule 9).

## When to commit

- **A dispatched row commits after its tick**, by explicit path — the paths in its final diff —
  with a message describing the change, not the row id, prefixed with the plan's ticket id if it
  has one. A crash then loses at most one row, and the next row's base is clean.
- **Unless the plan has its own commit row** for that work: then that row commits, and the
  executor does not pre-empt it.
- The plan's own table and Run log are committed by the plan's commit rows, or at close-out.
- `git status --short` between staging and committing shows only the paths you named (rule 6).

## The Run log

A `## Run log` section after the plan's body, written by the controller as things happen — it is
in the file, so it survives a context summary. It holds:

- a header per run: the date, the starting commit per repo, and the run base (`DISPATCH.md`);
- every ruling, `R<n> · <row id> · <what> — <why> — <cost if wrong>`;
- every model step-up with its reason, and, on a row carrying a `review:` marker, the reviewer's
  tier and reason for every review of that row, whether or not the marker changed anything — each
  line naming the row and its `review-<n>.md` (`DISPATCH.md` §3);
- deferred findings, the Low and Very Low ones, one line each with `file:line`;
- the final review's file and verdict.

Old `✅` rows without a `review:` token are not drift: they predate this loop.

## Hand-off rows — the one sanctioned halt

A row whose step is to give the user work to do outside this run and stop — its text says
**`hand-off row`** — ends the run mid-table:

1. Print exactly what the row says to print.
2. Tick it `✅`.
3. **End — with no final review, no closing question and no close-out.** They belong to the run
   that resumes after the user's part.
4. Rows behind it stay `⬜`.

**Name who picks up the parked set.** A hand-off defers the closing question, so anything parked
before it has no scheduled owner — and if the hand-off is the *last* row, deferring is indefinite.
The printed block must therefore say what resumes the plan (normally `/plan-continue <plan path>`)
and list the parked rows it will have to answer for. A hand-off that ends the table with rows still
`⛔` and no named resumption is a leak, not a halt.

This is the only place a run stops before the last row. It is not a stop-list item and needs no
approval: the plan author put it there.

## The spin guard

**If two consecutive rows are ticked `✅` with nothing verifiable to put in Notes, stop and
report.** Marching to the end producing un-auditable ticks looks like progress and is the opposite
— it destroys the record the table exists to keep. Say which rows, and what you could not measure.

**`⛔` and `⏭️` rows do not count toward the guard.** Their Notes carry a named blocker or reason,
which is the verifiable content those rows can have; two parked rows in a row is a normal shape, not
a spin.

## The final review, then close-out

**Final review** — after the last row, per `DISPATCH.md`: one reviewer on the whole run's diff, one
fix wave, one re-review, the verdict in the Run log. It runs even when every row was inline, if the
run changed any file in the plan's repositories.

**Close-out** applies `plan-finish` inline. These skills cannot invoke `/plan-finish`: it sets
`disable-model-invocation: true`, which hides it from the model entirely. So:

1. Read `plan-finish/SKILL.md` and `plan-finish/CHECKLIST.md` from the sibling skill directory —
   `${CLAUDE_SKILL_DIR}/../plan-finish/`, or the same relative path on a host that does not set that
   variable.
2. Apply them **verbatim** — the audit, the fix-by-default posture, the per-ecosystem command tables.
3. **Name the file you applied** in the report, so a reader can tell an applied checklist from a
   remembered one.
4. If the sibling is missing, do not improvise a close-out: print *run `/plan-finish`* and end.

`plan-finish`'s own stop-list governs this stage, and `RULES.md` rule 3 applies here as everywhere.
**Outside a git repository**, the commit and cleanup areas report *no repo* rather than being
skipped silently. **Cleanup deletes scratch, never deliverables**: a file a row exists to create is
the plan's output and stays; scratch is what the run made incidentally. The run directory holds the
reviews and is not scratch.

## Order, stated once

```
execute → park what must be parked → final review → fix wave → close out
       → one question covering the parked set → report, ending with "Rulings I made"
       → on yes: run the rows that yes releases, then review and close out again
       → on no: they stay blocked
```

`plan-finish`'s own *"not done — N items"* ask is **folded into that one question**, not raised
beside it. A run that ends at a hand-off row does none of this; the resuming run does it at the
true end.

## The report

Scale it to what happened. A clean run is a line:

```
done · 12/12 · 5 rows reviewed, final review PASS · checks green · committed a1b2c3d
```

When rows parked, they are the news — lead with them, name the blocker, and give the exact command
so a yes is one word. When a check could not run, say which and why (rule 7). Then **Rulings I
made**, one line each in the Run log's format — decisions taken on the user's behalf are theirs to
see, even when every one of them was right.

An example table, icons omitted so this file never reads as live work:

```markdown
| # | Step | Notes |
| - | ---- | ----- |
| 1 | `add-index` — index on the events table | 2.1 M rows, 41 s · review: `rows/<row id>/review-<n>.md` PASS |
| 2 | `deploy-staging` — ship the image | BLOCKED: deploy, rule 3 |
```
