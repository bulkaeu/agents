# The execution loop

Shared by `/plan-build` and `/plan-continue`. Read [RULES.md](RULES.md) first — this file assumes
it and does not repeat the stop-list.

## Contents

- The loop — one row at a time
- Hand-off rows — the one sanctioned halt
- The spin guard
- Close-out — applying `plan-finish` inline
- The report

## The loop — one row at a time

Rows run in **table order**. For each:

1. **Mark `🟡`.** One `Edit`, icon only.
2. **Find the work.** The body section backing the row, located by *name reference* — rows cite
   sections and sections cite rows, many-to-many. Position is not the mapping: the section next to a
   row is not necessarily its section.
3. **Do it**, under `RULES.md`.
4. **Verify against that row's own done-state**, not against a general sense that it went fine. The
   step text names what "done" means; if it does not, the row is under-specified — say so rather
   than inventing a criterion.
5. **Mark `✅` and write the Notes cell in the same edit** (rule 5). Counts, versions, paths, the
   real command output.
6. Next row.

A row that hits the stop-list becomes `⛔` with the blocker in Notes, and rows depending on it get
`⛔` *"depends on N"* — then the loop **continues** with everything else (rule 2).

**Scope changes go in the table as they happen.** A step you discover is needed becomes a row where
it actually ran, never appended beside a thematically similar one — a table reading `E1 E2 E5 E3 E4`
makes every later reader reconstruct the real order. Renumber rather than misplace. A step you are
told to skip gets `⏭️` and a reason; silent omission and a recorded skip look identical in the body
and completely different six weeks later.

## Hand-off rows — the one sanctioned halt

A row whose step is to give the user work to do outside this run and stop — its text says
**`hand-off row`** — ends the run mid-table:

1. Print exactly what the row says to print.
2. Tick it `✅`.
3. **End — with no closing question and no close-out.** Both belong to the run that resumes after
   the user's part.
4. Rows behind it stay `⬜`.

**Name who picks up the parked set.** A hand-off defers the closing question, so anything parked
before it has no scheduled owner — and if the hand-off is the *last* row, deferring is indefinite.
The printed block must therefore say what resumes the plan (normally `/plan-continue <plan path>`)
and list the parked rows it will have to answer for. A hand-off that ends the table with rows still
`⛔` and no named resumption is a leak, not a halt.

This is the only place a run stops before the last row. It is not a stop-list item and needs no
approval: the plan author put it there.

## The spin guard

Borrowed from `plan-review`'s no-op detection. **If two consecutive rows are ticked `✅` with nothing
verifiable to put in Notes, stop and report.** Marching to the end producing un-auditable ticks
looks like progress and is the opposite — it destroys the record the table exists to keep. Say
which rows, and what you could not measure.

**`⛔` and `⏭️` rows do not count toward the guard.** Their Notes carry a named blocker or reason,
which is the verifiable content those rows can have; two parked rows in a row is a normal shape, not
a spin. The guard is aimed at *ticks* that claim work with nothing behind them — read literally
without this carve-out, it halts a healthy run one row before its natural end.

## Close-out — applying `plan-finish` inline

These skills cannot invoke `/plan-finish`: it sets `disable-model-invocation: true`, which hides it
from the model entirely. So the last stage **loads its files and applies them**:

1. Read `plan-finish/SKILL.md` and `plan-finish/CHECKLIST.md` from the sibling skill directory —
   `${CLAUDE_SKILL_DIR}/../plan-finish/`, or the same relative path on a host that does not set that
   variable.
2. Apply them **verbatim** — the audit, the fix-by-default posture, the per-ecosystem command
   tables. The same device `plan-review` uses to apply `/code-review`'s instructions to a plan.
3. **Name the file you applied** in the report, so a reader can tell an applied checklist from a
   remembered one.
4. If the sibling is missing, do not improvise a close-out: print *run `/plan-finish`* and end.

`plan-finish`'s own stop-list governs this stage, and `RULES.md` rule 3 applies here as everywhere.

**Outside a git repository**, the commit and cleanup areas report *no repo* rather than being
skipped silently. **Cleanup deletes scratch, never deliverables**: a file a row exists to create is
the plan's output and stays, however throwaway the plan; scratch is what the run made
incidentally — probes, decoys, temp copies.

## Order, stated once

```
execute → park what must be parked → close out → one question covering the parked set
       → on yes: run the rows that yes releases, then close out again
       → on no: they stay blocked
```

`plan-finish`'s own *"not done — N items"* ask is **folded into that one question**, not raised
beside it. A run that ends at a hand-off row does none of this; the resuming run does it at the
true end.

## The report

Scale it to what happened. A clean run is a line:

```
done · 12/12 · checks green · committed a1b2c3d
```

When rows parked, they are the news — lead with them, name the blocker, and give the exact command
so a yes is one word. When a check could not run, say which and why (rule 7). The report is the
record of what you did, not a request for permission to have done it.

An example table, icons omitted so this file never reads as live work:

```markdown
| # | Step | Notes |
| - | ---- | ----- |
| 1 | `add-index` — index on the events table | 2.1 M rows, 41 s |
| 2 | `deploy-staging` — ship the image | BLOCKED: deploy, rule 3 |
```
