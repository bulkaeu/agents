---
name: plan-add
description: >-
  Adds new work to a plan that already exists — resolving the plan, interviewing
  the user first when a decision that changes what gets built is still open,
  matching the addition against the rows already there, writing atomic rows where
  they will actually run, and reopening the closed rows the addition invalidates.
  It authors and never executes: it ends by pointing at /plan-build, which starts
  or resumes the plan. Use when the user invokes /plan-add, or asks to add a step to
  a plan, fold new scope into one, or extend a plan that is already running.
disable-model-invocation: true
argument-hint: "<what to add> [optional plan path]"
---

# Plan add — new scope, into the plan that already exists

Scope arrives after the plan is written. Writing the new steps is the easy part; what goes wrong is a
second plan file for the same topic, a row appended at the end that should have run third, and a `✅`
left standing over work the addition invalidated. This skill guards those three, in that order.

## Hard rules

- **One topic, one plan file.** Never a second plan for a topic that has one (`no-plan-copies.md`).
  A genuinely different topic earns a plan of its own — that is not a copy of this one.
- **Never delete a row once the plan has started.** Unwanted work becomes `⏭️` with the reason and
  the superseding row's id: what was *not* done is history too. A plan that has not started — every
  row `⬜`, nothing in flight, no `## Run log` — has none yet: a row the addition replaces is rewritten
  or removed and renumbered past, leaving no `⏭️` row, no earlier-revisions table, no trace in Notes.
- **Never invent a done-state.** A step whose proof you cannot name is under-specified: say so and
  ask, rather than write an observable-sounding sentence nobody can check.
- **Plan edits go through `Edit`/`Write`, never Bash** (`ui-rendered-files-use-write-tool.md`): a
  `sed -i` leaves the rendered panel stale.
- **This skill authors; it never executes.** No step runs here, however small. It ends pointing at
  `/plan-build`, which starts the plan or resumes one already under way.

## 1. Resolve the plan — or start one

The ladder in [CONVENTIONS.md](../plan-shared/CONVENTIONS.md). This skill edits, so at the last rung
— and whenever two candidates are plausible at any rung — it lists the candidates with mtimes and
stops. Because it can also create, that list carries one extra option: **or start a new plan**, the
same shape as `plan-finish`'s repo-only offer.

**Exactly two paths lead to creation.**

- **The invocation names a path that does not exist.** That is the one signal this skill acts on by
  itself. Every later rung returns an existing file whenever any plan is around, so nothing else in
  the ladder can mean *new*.
- **The user takes the offer**, on whichever list this skill stopped at, and names where the plan
  goes. That is a choice, not a signal — never read it into silence.

Either way, write the new plan after step 2's interview and step 4's rows: its `**Ticket:**` line,
`## Summary`, `## Progress` (`plan-progress-section.md`, `plan-ticket-tracking.md`), the body sections
its rows cite and, if the interview ran, `## Decisions` in the format the close of
[INTERVIEW.md](INTERVIEW.md) gives — at the named path, or the one the user names. **It goes where it
belongs, in plan mode too** (`plans-live-in-a-plans-repo.md`). Plan mode auto-permits only the
harness's session plan, so a write elsewhere may prompt: answer it, and never divert the content into
that file (`plan-mode-edit-plans.md`) — the named path stays empty, and the next run makes a second plan.

Read the whole plan once resolved, and note its mtime — step 4's guard compares against it.

## 2. Understand the addition

The argument is the work. With no argument, use what this conversation has already agreed; with
neither, ask once — one question, then proceed on the answer.

**Where the addition touches code, dispatch one `Explore` subagent** on the standard tier
([DISPATCH.md](../plan-build/DISPATCH.md) §3) to confirm the files, commands and checks the new rows
will name exist. A done-state citing a missing script reads as verified, and fails when trusted.

**A purely editorial addition skips the dispatch and says so in the report.** A silent skip is
indistinguishable from having forgotten.

**When a decision that changes what gets built is still open, run the interview before any table
write**: read [INTERVIEW.md](INTERVIEW.md) and follow it. A new plan from a request with no agreed
design, and an addition that contradicts what the plan already decided, are its common cases, not
the whole list: an addition that opens such a decision without contradicting anything runs it too.
**Otherwise skip it and say so in the report**, as the dispatch skip above does.

## 3. Match the addition against the existing rows

Full method in [MATCHING.md](MATCHING.md). The summary is three evidence tests, and a row — closed,
parked or still waiting — is matched when any one of them holds:

- the new work **makes what that row produced or verified no longer correct**;
- that row's **done-state would now answer differently**;
- the new work **replaces what the row was for**.

**Test an open row too.** A `⬜` whose purpose the addition replaces is superseded, not left in the
queue for an executor to pick up and run a step nobody wants any more.

**Adjacency is not a test.** Neither is a shared phase, nor "probably worth a recheck". A match you
cannot state in one of those three forms is not a match — it is a rerun the user never asked for,
and every false reopen makes the next true one easier to wave away.

## 4. Write the rows

**The guard, before the first table write.** This step and step 5 both change a file another session
may be holding, so run the guard once — immediately before the first `Edit` on the table, against a
`stat` taken right then. If any row is in flight, or the file's contents or mtime moved since step 1
read it, **print every intended change, the new rows and the reopens together, and wait for a yes**
before writing any of them. Another session may be inside the very step you are about to mark
unfinished. Announcing before you change shared state is the rule (`shared-state-between-agents.md`);
announcing after it is a collision report. **Your own writes never trigger it** — the only stat that
counts is the one taken before the first of them, and the guard is not re-evaluated between edits.

**The guard holds in plan mode.** `plan-mode-edit-plans.md` frees plan edits from asking permission,
not from another session's work in flight: the guard waits on a fact about the tree.

Rows are atomic per `plan-atomic-todos.md`: one verb, one done-state, and that done-state observable
— a file that exists, a count, an exit code, a command's output.

- **Rows go where they will run**, not at the end. A check that belongs after row 3 leaves the plan
  reading `1 2 3 5 4` for every later reader if you append it.
- **Every new row gets the body section it cites, written in the same change.** The executors find a
  row's work by *name reference* into the body — `plan-build/EXECUTION.md` step 2, quoted into an
  implementer's brief as its **Specification** (`plan-build/DISPATCH.md` §2) — and position is not
  the mapping. Extend the section an existing row already names where the addition belongs in it;
  otherwise write a new section and name it from the row. A row with nothing behind it hands the
  next `/plan-build` an implementer whose Specification is empty: the under-specified step the
  hard rules above forbid.
- **Renumber only while the plan has not started** (hard rule 2's test); once it has, suffix the id
  — `3a`, `3b` — so references keep pointing at the same steps ([MATCHING.md](MATCHING.md) §6).
- **Gated work carries the `BLOCKED — wait for user:` marker** (`CONVENTIONS.md`, *Row markers*), on
  a row of its own. A gate bundled into a step that also does work cannot be parked.
- **Notes stay empty on a new waiting row.** The Notes column records results, never intentions.

## 5. Reopen what the addition invalidates

**Test 1 or test 2 reopens**: the matched `✅` or `⏭️` goes back to `⬜`. **Test 3 supersedes
instead** — the row becomes `⏭️`, an open one included, and never runs ([MATCHING.md](MATCHING.md)
§3). Either way **its Notes keep the original result** plus the reason and the causing row's id: the
earlier run is evidence, and overwriting it destroys the only record of what that step produced. A
plan that has not started has nothing to reopen, and a row test 3 retires goes per hard rule 2.

**A reopened row whose causing rows run later moves down to sit after the last of them, keeping its
id.** Left where it is, it sits above its own causes, and a top-down executor runs it first — against
a tree the addition has not landed in, so the check passes and the reopen bought nothing. Moving it
makes the order true, and the out-of-sequence ids that result are correct rather than a defect: the
position sequences, the id only identifies ([MATCHING.md](MATCHING.md) §6). **A superseded row is not
moved** — a `⏭️` never runs, so its position carries nothing.

Every write here is under step 4's guard, a move included, evaluated before the first table write of
the whole change: if it stopped you, these reopens were in what you printed.

## 6. Update the Summary and the ticket

- **A scope change that leaves the `## Summary` untrue gets the Summary edit in the same change.**
  It is the first thing anyone reads, and the text a ticket carries whole.
- **A plan with no ticket line has never had the question settled** — so settle it now
  (`plan-ticket-tracking.md`: file to the one destination on record, ask only when it is ambiguous)
  and record the answer on the `**Ticket:**` line, a `none` included. A missing field is not an
  answer; the next session reads it as an open question and raises it again.
- **A ticket this plan filed** gets its description refreshed from the new Summary, no gate: that
  description is this plan's own text. **A ticket the plan adopted** carries someone else's words —
  propose the new description and get a yes, the same courtesy as any destructive edit.

## 7. Report, then review — inline, not by invocation

First the report, and keep it short: the rows added with their ids, the rows reopened with why,
whether the Summary moved, and the pointer — `/plan-build`, which starts a plan that has not
started and resumes one that has.

Then **review the whole plan, not only the new rows**: read
`${CLAUDE_SKILL_DIR}/../plan-review/SKILL.md` — on a host that does not set that variable, the same
relative path from this file's own directory — and apply its cycle **verbatim**: round 1's
dispatched reviewer, the fix loop, the closing pass, and the `### Plan review cycle` log it appends.
New rows change the plan a reviewer would have read. **If that file is missing, say so and stop** —
do not reconstruct the cycle from memory.

**The cycle's edits stay under step 4's guard.** `plan-review` not asking settles permission, not
concurrency: on a mid-run plan, a fix that touches a row another session may be holding is printed
and waited on as step 4 requires; every other plan edit in the loop goes in unannounced.

**`/plan-review` cannot be invoked.** Its `disable-model-invocation: true` hides it from the model,
so reading its file is the only way to get its cycle — one of the one-hop cross-skill reads the
README's contributing section names. An edit that "fixes" this into a call breaks the skill silently.

## Examples

**A verification step, mid-run.** The user wants a smoke check after the deploy row. The plan
resolves at rung 2; one `Explore` run confirms the named script exists and what it prints. No closed
row is matched; rows 1–4 are closed, so the new row goes in as `4a`, in place, with the script's exit
code as its done-state. Nothing is open to decide, so no interview runs. Report, then review.

**An addition that reopens two closed rows.** A schema change makes a column the migration row wrote
as nullable required, so that row's output is now wrong, and the fixture row's done-state would now
answer differently — two tests, two matches. Both rows go back to waiting, original Notes intact plus
the reason and the causing row's id. One row is in flight, so the guard holds before the first table
write: print the new rows and both reopens, and wait for the yes before writing any of them.

**An addition that does not belong.** The user asks to fold an unrelated refactor into a plan about
the price loop. No evidence test holds and the two share nothing but a repository. Say so, and offer
a plan of its own — that is a different topic, not a second file for this one.

**A plan that does not exist yet.** The invocation names a path with no file at it: the one signal
this skill acts on alone. With no agreed design, the interview runs first; then write the plan, its
`## Decisions` included, and run the same review cycle over it. The report ends at `/plan-build`.
