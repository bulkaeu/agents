---
name: plan-summary
description: >-
  Renders a summary of an implementation plan: the plan's own plain-language
  Summary in full, a technical summary of the same scale, and where the work
  stands — recently finished and upcoming steps from its Progress table.
  Read-only: it reports on a plan, it does not execute one. Use when the user
  invokes /plan-summary or asks for a summary, overview, recap, or status of
  a plan.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---

# Plan summary

Answers three questions about a plan: **what** are we doing (in the plan's own plain words),
**how** (in technical ones), and **where are we**. Each section is as long as it needs to be and no
longer — the discipline is per-section weight, not a global line budget.

## Hard rules

- **Read-only by default.** Do not execute a step, fix a finding, or edit the plan. The one exception
  is the offer in *No Progress table* below, and only after the user says yes.
- **Never invent progress.** If the plan has no Progress table, say so and label anything you derive
  as *inferred*. A confident-sounding status that came from guesswork is worse than no status.
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
`| # | Phase | Status | Date | Notes |`. **Read those too** — refusing to parse them makes the skill
useless on exactly the plans most worth summarizing. If any table row contains one of the five icons
in *any* cell, treat that table as the Progress table; take the step name from the first non-numeric
text cell and the notes from the last. Do not offer to convert the format — the summary is
read-only, and a working table in an old shape is not a defect.

Tally each state. **Current step** = the `🟡` row; if none, the first `⬜`. If every row is `✅`/`⏭️`,
the plan is complete — one line says so **in place of the Where-we-are section, with no
`## Where we are` header at all**. A header wrapping the "complete" line is the section the spec
said not to print.

## 3. Render the summary

Print to chat. Never write it to a file unless asked.

### Ticket

The plan's `**Ticket:**` line, verbatim, first — a reader asking "where are we" needs the tracker id
in the same breath as the answer. **Report all three of its forms, including the empty one.**
`**Ticket:** none — not tracked` is information; silently omitting the section when the plan is
untracked is not, because the reader cannot then tell "untracked" from "the skill forgot to look".
If the plan has no `**Ticket:**` line at all, say *"no ticket field — predates
`plan-ticket-tracking.md` or was never asked"*.

### Summary — the plan's own, in full

Quote the plan's `## Summary` **verbatim and whole**. It was written in plain language for exactly
this reader, sized to the plan by `plan-progress-section.md`'s own rule — do not condense it,
trim it, or restyle it. If the plan predates the rule and has no `## Summary`, derive 2–3 plain
sentences from `## Context` and label them ***derived** — plan has no Summary section*.

### Technical summary

The same scale as the plan's Summary, written by you from the plan body: the approach, the files
and systems touched, the key decisions and their reasons — file paths, commands and jargon belong
here. The Summary above says *what and why* for any reader; this section says *how* for the one who
will open the code. Scaled like its twin: a few lines for a small plan, more for a staged one,
never padded.

### Progress

The tally line first:

`12/18 done · 1 in progress · 2 blocked · 1 skipped`

Then the rows. **First count the window-relevant rows** — trailing `✅` plus upcoming `⬜`. **Ten or
fewer: show them all, no cut.** Only beyond ten does the window apply: the last 5 implemented (`✅`,
in table order, most recently done last) and the next 5 to implement (`⬜`, in order). A fresh reader
verified against this text once cut a 9-row table to 5 because "last 5" led the paragraph — the
count comes first for exactly that reason.

Mark any cut on the side it happens: `… N earlier rows omitted` **above the table, never after it**
(the cut precedes the first shown row), `… N later rows omitted` below. Naming the omitted step ids
inside the marker is welcome — position is the part that must not drift.

**Never reorder rows.** Render them in the plan's own order even when ids run out of sequence — the
table is the source of truth, and silently sorting it hides a real defect the reader should see and
fix in the plan, per `plan-progress-section.md`.

`🟡`, `⛔` and `⏭️` rows are not lost to the window — they carry the reasons, and they all appear in
**Where we are**.

### Where we are

The current step, spelled out — id, what it does, and what it is waiting on. Then every `⛔` with its
blocker and every `⏭️` with its reason, quoted from the Notes column. **This is the section the skill
exists for**; when the plan has started, lead the reader here.

If the plan has not started, replace this section with one line — *"Not started — N waiting, first is
`<id>`."* **Count only `⬜` in that N**: a plan with 16 `⬜` and 2 `⛔` is "16 waiting, 2 blocked by
design", never "18 waiting". A count that disagrees with the tally line discredits both.

### Verification & exit criteria

Condensed from `## Verification` / `## Exit criteria`. Name the checks; do not reproduce them. Call
out any the plan itself marks pending-user.

### Footer

Plan path, size, last modified. One line.

## No Progress table

Say so plainly in the Progress section, then:

1. Derive a best-effort status from whatever the plan does have — `✅` markers in body tables,
   `- [x]` checklists, a `## Status` line — and **label it *inferred*.**
2. If there is nothing to derive from, say the plan's state is unknown. Do not fill the gap.
3. Offer once: *"Add a conforming `## Progress` table? I can derive N steps from the body."* On a
   yes, write it per `plan-progress-section.md` — with `Edit`/`Write`, never Bash, and matching the
   body's real step boundaries rather than inventing tidier ones.

**Put the offer last** — after the footer, as the closing line. Mid-page it interrupts the summary
the user asked for, and it reads as part of the plan's content rather than as your question. Do not
nag: one offer per invocation.

## Examples

**`/plan-summary` mid-flight** — ticket line, the plan's 20-line Summary quoted whole, a matching
technical summary from the body, tally, the last 5 `✅` and next 5 `⬜`, then *Where we are* with the
one `🟡` and both `⛔` reasons. The user reads the Summary and *Where we are* and stops.

**`/plan-summary` on a pre-rule plan** — no `## Summary`: 2–3 sentences derived from Context,
labelled *derived*; no Progress table either: status *inferred* from 8 body checkmarks, and the
add-a-table offer as the closing line.

**A 30-step plan, 22 done** — `… 17 earlier rows omitted`, the last 5 `✅`, the next 5 `⬜`,
`… 3 later rows omitted`, and the blocked row's reason in *Where we are* even though it sits outside
the window.
