---
name: plan-add
description: >-
  Adds new work to a plan that already exists — resolving the plan, matching the
  addition against the rows already there, writing atomic rows where they will
  actually run, and reopening the closed rows the addition invalidates. It
  authors and never executes: it ends by pointing at /plan-build or
  /plan-continue. Use when the user invokes /plan-add, or asks to add a step to
  a plan, fold new scope into one, or extend a plan that is already running.
disable-model-invocation: true
argument-hint: "<what to add> [optional plan path]"
---

# Plan add — new scope, into the plan that already exists

Scope arrives after the plan is written. Writing the new steps is the easy part; the three things
that go wrong are a second plan file for the same topic, a row appended at the end that should have
run third, and a `✅` left standing over work the addition just invalidated. This skill does those
three on purpose, in that order, and hands the plan back to an executor rather than running it.

## Hard rules

- **One topic, one plan file.** Never a second plan for a topic that has one (`no-plan-copies.md`).
  A genuinely different topic earns a plan of its own — that is not a copy of this one.
- **Never delete a row.** Work no longer wanted becomes `⏭️` with the reason and the id of the row
  that superseded it. The history of what was *not* done is worth as much as what was.
- **Never invent a done-state.** A step whose proof you cannot name is under-specified: say so and
  ask, rather than writing an observable-sounding sentence nobody can actually check.
- **Plan edits go through `Edit`/`Write`, never Bash** (`ui-rendered-files-use-write-tool.md`). A
  `sed -i` lands the bytes and leaves the rendered panel showing the stale table.
- **This skill authors; it never executes.** No step runs here, however small. It ends pointing at
  `/plan-build`, or `/plan-continue` for a plan already under way.

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

Either way, write the new plan with its `**Ticket:**` line, `## Summary` and `## Progress` table
(`plan-progress-section.md`, `plan-ticket-tracking.md`), **with the body sections its rows cite, per
step 4**: at the named path in the first case, at the path the user names in the second. **The plan
is written at the path it belongs, in plan mode too** (`plans-live-in-a-plans-repo.md`). Plan mode
auto-permits one file, the harness's own designated session plan, so a write anywhere else may
prompt: answer the prompt, and never divert the content into that file (`plan-mode-edit-plans.md`).
Diverting leaves the named path empty, so the next invocation sees a missing path again and creates
a second plan for the same topic.

Read the whole plan once resolved, and note its mtime — step 4's guard compares against it.

## 2. Understand the addition

The argument is the work. With no argument, use what this conversation has already agreed; with
neither, ask once — one question, then proceed on the answer.

**Where the addition touches code, dispatch one `Explore` subagent** on the standard tier
([DISPATCH.md](../plan-build/DISPATCH.md) §3) to confirm that the files, commands and checks the new
rows will name actually exist. A done-state citing a script that is not there is worse than a vague
one: it reads as verified, and fails at the moment someone trusts it.

**A purely editorial addition skips the dispatch and says so in the report.** A silent skip is
indistinguishable from having forgotten.

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

**The guard holds in plan mode.** `plan-mode-edit-plans.md` frees plan edits from asking permission;
it does not free them from another session's work in flight. What this guard waits on is a fact
about the tree, not a permission to write.

Rows are atomic per `plan-atomic-todos.md`: one verb, one done-state, and that done-state observable
— a file that exists, a count, an exit code, a command's output.

- **Rows go where they will run**, not at the end. A check that belongs after row 3 leaves the plan
  reading `1 2 3 5 4` for every later reader if you append it.
- **Every new row gets the body section it cites, written in the same change.** The executors find a
  row's work by *name reference* into the body — `plan-build/EXECUTION.md` step 2, quoted into an
  implementer's brief as its **Specification** (`plan-build/DISPATCH.md` §2) — and position is not
  the mapping. Extend the section an existing row already names where the addition belongs in it;
  otherwise write a new section and name it from the row. A row with nothing behind it hands the
  next `/plan-continue` an implementer whose Specification is empty: the under-specified step the
  hard rules above forbid.
- **Renumber only when the plan has not started at all** — every row `⬜`, nothing in flight, no
  `## Run log`. The moment any row is in flight or closed, insert with a suffixed id — `3a`, `3b` —
  so existing references keep pointing at the same steps ([MATCHING.md](MATCHING.md) §6).
- **Gated work carries the `BLOCKED — wait for user:` marker** (`CONVENTIONS.md`, *Row markers*), on
  a row of its own. A gate bundled into a step that also does work cannot be parked.
- **Notes stay empty on a new waiting row.** The Notes column records results, never intentions.

## 5. Reopen what the addition invalidates

**Test 1 or test 2 reopens**: the matched `✅` or `⏭️` goes back to `⬜`. **Test 3 supersedes
instead** — the row becomes `⏭️`, an open one included, and a superseded row never runs
([MATCHING.md](MATCHING.md) §3). Either way **its Notes keep the original result** and gain the
reason and the id of the row that caused the change — the earlier run is evidence, and overwriting
it destroys the only record of what that step once produced.

Every write here is under step 4's guard, evaluated before the first table write of the whole
change: if it stopped you, these reopens were in what you printed.

## 6. Update the Summary and the ticket

- **A scope change that leaves the `## Summary` untrue gets the Summary edit in the same change.**
  It is the first thing anyone reads, and the text a ticket carries whole.
- **A plan with no ticket line has never been asked the question** — so ask it now
  (`plan-ticket-tracking.md`) and record the answer on the `**Ticket:**` line, a `none` included.
  A missing field is not an answer; the next session reads it as an unasked question and asks again.
- **A ticket this plan filed** gets its description refreshed from the new Summary, no gate: that
  description is this plan's own text. **A ticket the plan adopted** carries someone else's words —
  propose the new description and get a yes, the same courtesy as any destructive edit.

## 7. Report, then review — inline, not by invocation

First the report, and keep it short: the rows added with their ids, the rows reopened with why,
whether the Summary moved, and the pointer — `/plan-build` for a plan that has not started,
`/plan-continue` for one that has.

Then **review the whole plan, not only the new rows**: read
`${CLAUDE_SKILL_DIR}/../plan-review/SKILL.md` — on a host that does not set that variable, the same
relative path from this file's own directory — and apply its cycle **verbatim**: round 1's
dispatched reviewer, the fix loop, the closing pass, and the `### Plan review cycle` log it appends.
New rows change the plan a reviewer would have read. **If that file is missing, say so and stop** —
do not reconstruct the cycle from memory.

**The cycle's edits stay under step 4's guard.** `plan-review` does not ask before plan edits, and
that settles permission, not concurrency: on a mid-run plan, a fix that touches a row another
session may be holding is printed and waited on exactly as step 4 requires, and every other plan
edit in the loop goes in unannounced.

**`/plan-review` cannot be invoked.** It sets `disable-model-invocation: true`, which hides it from
the model entirely, so reading its file and applying it is the only way to get its cycle — one of
the one-hop cross-skill reads the README's contributing section names. A later edit that "fixes"
this into a call breaks the skill silently.

## Examples

**A verification step, mid-run.** The user wants a smoke check after the deploy row. The plan
resolves at rung 2; the addition names a script, so one `Explore` run confirms it exists and what it
prints. No closed row is matched. Rows 1–4 are closed, so the new row goes in as `4a`, in place,
with the script's exit code as its done-state. Short report, then the review cycle on the whole plan.

**An addition that reopens two closed rows.** A schema change makes a column the migration row wrote
as nullable required, so that row's output is now wrong, and the fixture row's done-state would now
answer differently — two tests, two matches. Both rows go back to waiting, their original Notes
intact plus the reason and the id of the row that caused it. One row is in flight, so the guard
holds before the first table write: print the new rows and the two intended reopens, and wait for
the yes before writing any of them.

**An addition that does not belong.** The user asks to fold an unrelated refactor into a plan about
the price loop. No evidence test holds and the two share nothing but a repository. Say so, and offer
a plan of its own — that is a different topic, not a second file for this one.

**A plan that does not exist yet.** The invocation names a path with no file at it: the one signal
this skill acts on alone. Write the plan — ticket line, Summary, a Progress table whose rows all
sit waiting, and the body sections those rows cite — then run the same review cycle over it. Nothing
executes; the report ends at `/plan-build`.
