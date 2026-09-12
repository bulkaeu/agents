# plan-add — matching, reopening and placement

The detail behind steps 3, 4 and 5 of [SKILL.md](SKILL.md): how to tell a matched row from a merely
adjacent one, what each match does to the row, and how to get new rows into the table without
duplicating the row that follows them. Terms — row id, step id, done-state, closed/parked/open — are
[CONVENTIONS.md](../plan-shared/CONVENTIONS.md)'s.

Run all three tests before deciding — an addition can both break a row's output and retire it, and
§3's precedence needs both answers. State the evidence in one sentence someone else can go and check.

## 1. The three relate tests, worked through

### Test 1 — the addition makes what the row produced or verified no longer correct

**Evidence:** name the artifact, name both rows that touch it, and say which part of the earlier
row's output stops holding. A part you cannot name is a suspicion; a directory is not an artifact.

**Worked.** Row 2 wrote the schema column as nullable; the addition makes it required. What row 2
left on disk is now wrong, not merely edited around. Matched.

**Near-miss.** The addition edits that same module beside row 2's column, leaving the column
exactly as row 2 wrote it. A changed file is not a changed output. Not matched.

### Test 2 — the row's done-state would now answer differently

**Evidence:** read the done-state back as a question and answer it against the plan *with* the
addition in it. Matched only when the answer moves.

**Worked.** Row 5's done-state is `npm test` green at 214 tests, recorded in its Notes. The addition
brings a module and its tests: the command now runs over code that did not exist, and 214 is wrong.
Matched.

**Near-miss.** Row 5's done-state is that `out/report.csv` exists. The addition writes a different
file elsewhere. "Does it exist" still answers yes, unchanged. Not matched. Existence done-states
rarely move; counts, exit codes and command output move often.

### Test 3 — the new work replaces what the row was for

**Evidence:** state the row's purpose in one clause and the new work's purpose in one clause. The
test holds when they are the same clause — one purpose, two mechanisms.

**Worked.** Row 7 polls an endpoint for status. The addition receives the same status on a webhook.
The poll is not wanted. Matched.

**Near-miss.** The addition puts a retry inside that poll. The row's purpose survives, so test 3
does not hold; an implementation change answers neither test 1's correctness question nor test 2's
done-state question by itself. Replacement retires a step; changing how a step works does not.

## 2. What is not a test

- **Adjacency in the table.** The row above the insertion point is a neighbour, not a dependency.
- **A shared phase.** Phases group work by when it runs, not by what it touches.
- **A shared subsystem, repository or directory.** Too coarse to carry evidence.
- **"Probably worth a recheck."** A hunch with a hedge in front of it.

**Acting on a false match costs more than the rerun.** The row goes back to `⬜`, so the plan reports
itself incomplete when it is not; an executor picks the row up and redoes work nobody asked for,
side effects included; and the Notes gain a reason no evidence supports, which the next reader has
to disprove before trusting the rest of the column. Reopens also spend their credibility — a reader
who has waved away three cosmetic ones waves away the fourth.

**The opposite error is as real.** A missed match leaves a `✅` standing over work the addition
invalidated, which is the failure this whole step exists to prevent. Unsure is not a verdict: go and
read the artifact or re-answer the done-state, then decide.

## 3. The three outcomes

| Outcome | What the row becomes | Reached by |
| --- | --- | --- |
| Reopen | `✅` or `⏭️` → `⬜`, Notes rewritten per §5 | test 1 or test 2 |
| Supersede | `⏭️`, with the reason and the causing row id in Notes | test 3 |
| Leave alone | untouched, and unremarked | no test holds |

- **Reopen** returns the step to the queue. The row keeps its id, its step text and its recorded
  result; only the icon and the Notes move.
- **Supersede** retires the step. An open row superseded never runs. A closed row whose output the
  addition discards keeps its recorded result beside the supersede line — the work did run, and that
  Note is the only surviving proof of what the plan once produced.
- **Leave alone** means no edit and no note. A closed row the addition does not touch is evidence
  the addition was scoped well; writing "checked, still valid" into it is noise the column cannot
  filter back out.
- **One row, one outcome.** Where test 3 holds alongside test 1 or test 2, supersede wins —
  reopening a step you have just decided against asks someone to redo work you do not want.

Deciding the outcome is this file's job. *Writing* it is gated by the guard in `SKILL.md` step 4.

## 4. The verification-row case

**A row whose whole job is a check matches on test 2 nearly every time.** Its done-state is a count,
an exit code or a command's output over code the addition changes, so the answer moves by
construction. Still run the test — a check scoped to a subsystem the addition never touches
genuinely does not move — but expect it to hold.

**Placement is what makes the reopen honest.** The new code rows go *before* the verification row. A
reopened `⬜` sitting above the rows that caused it tells an executor to run the check first and the
code after: the check passes, against a tree the addition has not landed in, and the reopen bought
nothing. Appending the new rows at the end produces exactly that.

Rows 1–4 already closed, the addition landing as `3a` and `3b` (icons omitted from the first cell,
so this file never reads as live work):

```markdown
| # | Step | Notes |
| - | ---- | ----- |
| 3 | `add-retry` — retry the fetch on 5xx | 3 call sites, unit-tested |
| 3a | `retry-config` — read the backoff from config | |
| 3b | `retry-tests` — cover the 5xx path | |
| 4 | `run-suite` — `npm test` green | Reopened by 3b — … |
```

## 5. The Notes-rewriting template

**Never overwrite a Notes cell.** The recorded result is the only evidence of what the step
produced; erasing it leaves a later reader unable to tell a rerun from a first run, and quietly
turns `plan-progress-section.md`'s "Notes record the result" into "Notes record the latest result".

One line, in this order:

```text
Reopened by <row id> — <what changed, one clause>. Earlier result: <the original Notes, verbatim>
```

A superseded row takes the same shape with the verb swapped:

```text
Superseded by <row id> — <why the work is no longer wanted>. Earlier result: <the original Notes, verbatim>
```

Worked — §4's `run-suite` row carries the *after*, elided; here it is in full, with the *before*:

```text
before   214 tests / 18 suites green, format:check clean
after    Reopened by 3b — the 5xx retry path landed after this ran. Earlier result: 214 tests / 18 suites green, format:check clean
```

- **The id is the causing row's**, never the reopened row's own. It is what lets a reader jump from
  the reopen to the work that forced it.
- **A row that never ran drops the clause.** No result, nothing to keep — write no `Earlier result:`
  at all rather than `Earlier result: none`, which reads like a result someone lost.
- **A second reopen appends; it does not nest** — the new reason goes in front, the earliest recorded
  result stays last, and never a chain of quoted quotes:

  ```text
  Reopened by 5a — the backoff moved to config. Reopened by 3b — the 5xx retry path landed after this ran. Earlier result: 214 tests / 18 suites green, format:check clean
  ```

## 6. Renumber versus suffix

**Renumber only when the plan has not started at all** — every row `⬜`, nothing in flight, nothing
closed, no `## Run log`. No reference to any id exists yet, so insert in place and renumber straight
through.

**The moment any row is in flight or closed, suffix instead** — `3a`, `3b`, between `3` and `4`. The
trigger is *started*, not *has closed rows*: a plan with a `🟡` row and nothing closed is running,
and an executor is holding an id that renumbering would repoint under it.

**What renumbering breaks is silent.** The Run log, the review files under the run directory, the
report the user has already read and any ticket comment all cite rows by id. Renumbering fails
nothing — it repoints every one of those at a different step, and a reader following the reference
has nothing to notice.

- **The id identifies; the position sequences.** Suffixed ids stop being sortable, and that is fine:
  rows sit in the order they run, so `3`, `3c`, `3a`, `4` is a correct table when that is the order.
  Never move a row to make the ids read alphabetically.
- **Never reuse or repoint a suffix.** Take the next unused letter, wherever the row goes.
- **Phase-lettered plans suffix the same way** — `A1a` after `A1`.

## 7. The insertion mechanic

**Anchor each `Edit` on the preceding row, and make one `Edit` per row.** The match text is the
whole line of the row *before* the insertion point; the replacement is that line plus the new one.
The row you are inserting before appears in neither.

**The duplicate comes from a replacement that restates a row its match text does not contain.**
Anchored on the preceding row there is nothing to restate — the replacement is that one line plus
the new one. Batching several rows into one replacement is where it bites: every row the replacement
carries but the match omits is written a second time, wherever the anchor sits.

**The duplicate is silent.** The table reads as longer, not as wrong; an executor runs the step
twice, or picks whichever copy it read first. So **re-read the table and count the rows after
inserting** — old count plus rows added, or you have one. Use `Edit`, never a `sed` pass
(`ui-rendered-files-use-write-tool.md`): the bytes land and the rendered panel keeps the old table.

Reopens take the same discipline — one `Edit` per row changed, each matching that row's line alone.

## 8. Cursor plans

**A Cursor plan carries its steps twice** — the `## Progress` table and the YAML frontmatter `todos`
that drive the panel. Every change above lands in both, in the same edit: rows added, rows reopened,
rows superseded.

- **Mirror the state, not only the text.** Cursor's todos carry `completed`, `pending`, `cancelled`
  or `in_progress` — a reopened row's todo goes back to `pending`, a superseded one to `cancelled`,
  and deleting a todo is the frontmatter's version of deleting a row.
- **Quote any todo text holding `:`, `#`, `[` or `{`.** An unquoted colon makes the frontmatter fail
  to parse and the panel render mangled. Notes never reach the frontmatter, so §5's
  `Earlier result:` stays a table-only string.
- **Parse the frontmatter afterwards** — `plan-yaml-frontmatter.md` owns the command and the
  assertions. A correct Progress table proves nothing about the panel, and neither does a screenshot
  of it: claim the todos are healthy only once the parse prints its count.
