---
name: plan-summary
description: >-
  Renders a one-page summary of an implementation plan — what it will do, how it
  will do it, and, when the plan is already in progress, exactly where it stands
  from its Progress table. Read-only: it reports on a plan, it does not execute
  one. Use when the user invokes /plan-summary or asks for a summary, overview,
  recap, or status of a plan.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---

# Plan summary

One screen that answers three questions about a plan: **what** are we doing, **how**, and — if it has
started — **where are we**. Nothing else. A summary that runs to two screens has failed at its job.

## Hard rules

- **Read-only by default.** Do not execute a step, fix a finding, or edit the plan. The one exception
  is the offer in *No Progress table* below, and only after the user says yes.
- **Never invent progress.** If the plan has no Progress table, say so and label anything you derive
  as *inferred*. A confident-sounding status that came from guesswork is worse than no status.
- **Never re-summarize the whole plan body.** The body is already the long version.
- **Report the plan's own claims as claims.** If a `✅` row says the suite passed, that is what the
  table says — do not restate it as a fact you verified. Use `/plan-finish` to actually verify.

## 1. Resolve the plan file

In order, stopping at the first hit:

1. A path or `@`-mention in the invocation → use it.
2. The session's active plan file, or the only plan touched this session.
3. Most recently modified in `~/.claude/plans/`, `~/.cursor/plans/`, `.cursor/plans/`.

If two or more are plausible, **list the candidates with their mtimes and stop**. Never guess — a
summary of the wrong plan is indistinguishable from a summary of the right one until it misleads.

Read the whole file, including frontmatter.

## 2. Parse the Progress table

Per `plan-progress-section.md`, rows look like `| A1 ✅ | step-id — description | notes |`, the icon
sitting in the first cell after the step id.

| Icon | State |
| --- | --- |
| ⬜ | waiting |
| 🟡 | in progress |
| ✅ | done |
| ⛔ | blocked |
| ⏭️ | skipped |

### Legacy tables

Plans written before `plan-progress-section.md` put the icon in its own `Status` column:
`| # | Phase | Status | Date | Notes |`. **Read those too** — several existing plans use it, and
refusing to parse them makes the skill useless on exactly the plans most worth summarizing.

Rule: if any table row contains one of the five icons in *any* cell, treat that table as the
Progress table. Take the step name from the first non-numeric text cell and the notes from the last.
Do not offer to convert the format — the summary is read-only, and a working table in an old shape
is not a defect.

Tally each state. **Current step** = the `🟡` row; if none, the first `⬜`. If every row is `✅`/`⏭️`,
the plan is complete — say so in one line rather than printing a "where we are" section.

## 3. Render the one-pager

Print to chat. Never write it to a file unless asked.

### What

Two or three sentences from `## Context`: the problem, and the intended outcome. Not the approach.

### How

5–10 bullets, one per phase or `§` section, in execution order. One line each. If the plan has more
than 10 phases, group them and say so.

### Progress

The tally line first, because it is the part most often read alone:

`12/18 done · 1 in progress · 2 blocked · 1 skipped`

Then the table — **at most 10 rows**. Past that, render an active window:

- the last two `✅` rows,
- every `🟡` and `⛔` row,
- every `⏭️` row (they carry reasons that outlive them),
- the next three `⬜` rows,

with `… N earlier rows omitted` above the window. The cap is what makes this a summary; a 30-row
table pushes the page past one screen and defeats the skill.

### Where we are

The current step, spelled out — id, what it does, and what it is waiting on. Then every `⛔` with its
blocker and every `⏭️` with its reason, quoted from the Notes column. **This is the section the skill
exists for**; when the plan has started, lead the reader here.

If the plan has not started (all `⬜`), replace this section with one line: *"Not started — N steps
waiting, first is `<id>`."*

### Verification & exit criteria

Condensed from `## Verification` / `## Exit criteria`. Name the checks; do not reproduce them. Call
out any the plan itself marks pending-user.

### Footer

Plan path, size, last modified. One line.

## No Progress table

Say so plainly in the first line of the Progress section, then:

1. Derive a best-effort status from whatever the plan does have — `✅` markers in body tables,
   `- [x]` checklists, a `## Status` line — and **label it *inferred*.**
2. If there is nothing to derive from, say the plan's state is unknown. Do not fill the gap.
3. Offer once: *"Add a conforming `## Progress` table? I can derive N steps from the body."* On a
   yes, write it per `plan-progress-section.md` — with `Edit`/`Write`, never Bash, and matching the
   body's real step boundaries rather than inventing tidier ones.

Do not nag. One offer per invocation.

## Examples

**`/plan-summary`** — resolves the active plan, prints the six sections. The user reads the tally and
the *Where we are* section and stops.

**`/plan-summary ~/.claude/plans/old-migration.md`** — explicit path, no Progress table, 8 body rows
with `✅`. Prints *"No Progress table — status below is inferred from 8 `✅` markers in the body"*,
then offers to add one.

**A 30-step plan mid-flight** — tally line, `… 14 earlier rows omitted`, then the window: two recent
`✅`, the `🟡`, both `⛔` rows with their blockers, the `⏭️`, and the next three `⬜`.
