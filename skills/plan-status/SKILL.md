---
name: plan-status
description: >-
  Answers "what is going on" about a plan in at most twelve lines: the step in
  flight, how many are done, what the working copy looks like, the next few
  steps, and anything blocked. Read-only, and deliberately terse — the long
  form is /plan-summary. Use when the user invokes /plan-status or asks
  briefly where a plan stands, what is happening now, or what is next.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---

# Plan status

One glance, after stepping away. Twelve lines is the ceiling, not the target — most plans answer in
six. `/plan-summary` already renders the long form; reaching for prose here defeats the point.

## Hard rules

- **Read-only.** Do not execute a step, fix a finding, or edit the plan. Not even to correct a row
  you can see is wrong — say it in one clause and leave it.
- **State comes from the icon, never from step text.** A `⬜` row whose text reads `BLOCKED — wait
  for user confirmation` is *waiting*, and belongs under `Next`. Only `⛔` rows populate `Blocked`.
  The step text says what a step needs; the icon says where it got to.
- **Never invent progress.** No Progress table means no counts. Say so and stop — a confident
  status derived from guesswork is worse than none.
- **Report the plan's claims as claims.** A `✅` row saying the suite passed is what the table says.
  `/plan-finish` is what verifies it.
- **At most twelve lines**, including the pointer. If you are writing a paragraph, you are writing
  the wrong skill.

## 1. Resolve the plan

In order, stopping at the first hit:

1. A path or `@`-mention in the invocation.
2. The session's active plan file, or the only plan touched this session.
3. The project's own plan directory: walk up from cwd to the nearest `.claude/settings*.json` that
   sets `plansDirectory`, and resolve that value against **the directory holding that settings
   file** — which is often not a git toplevel. If none sets one, `plans/` under the git toplevel,
   if it exists.
4. Most recently modified in `~/.claude/plans/`, `~/.cursor/plans/`, `.cursor/plans/`.

Two or more plausible → list them with mtimes and stop. A status of the wrong plan is
indistinguishable from a status of the right one until it misleads.

## 2. Read three cheap sources

| Source | For |
| --- | --- |
| The `## Progress` table | Every count, the current step, the blocked set |
| `git status --short` and `git log --oneline -5` | The `Session` line |
| What this session actually did | Whether the plan is moving right now |

Run git in the plan's own repository; if the plan is not inside one, the cwd's. Legacy tables that
put the icon in its own `Status` column count too — if any row carries one of the five icons in any
cell, that is the Progress table.

## 3. Print this shape

```
<plan name> · <ticket, condensed>
Doing:    <id> <step-id> — one clause
Done:     N/M · the two most recently finished step ids, table order
Session:  <branch> · n modified, n untracked · last commit subject
Next:     <id> <step-id> · <id> <step-id> · <id> <step-id>
Blocked:  <ids + one-clause reasons>
→ /plan-summary for the long form
```

Field rules, so two runs on the same plan match:

- **`<plan name>`** is the **filename stem** (`fixture-inflight`), never the H1 — an H1 is often a
  sentence and swamps the line.
- **`<ticket, condensed>`** is the identifier alone (`ABC-123`). A plan whose ticket line says
  `none` renders `no ticket`; a plan with no ticket line at all renders `no ticket field`.
- **`Doing`** is the `🟡` row; with no `🟡` it is the first `⬜`, and the clause says so — *waiting,
  nothing in flight* — because "Doing" otherwise overstates.
- **`Next`** lists the rows *after* `Doing`, by row id, never re-listing `Doing` itself. Row ids,
  not ordinals: `1)` `2)` tells the reader nothing they can look up.

`Blocked` is omitted entirely when nothing is `⛔` — an empty label reads as a fact you checked and
is one more line than the reader needed.

**Over budget?** Drop `Next` items from the end, then the `Session` line's commit subject, then
collapse `Blocked` to bare ids. Never drop `Doing`, `Blocked`, or the pointer.

## 4. Edge cases — one line each, in place of the shape

| Case | Line |
| --- | --- |
| No plan resolves | Session-only status, labelled *no plan* |
| Every row `✅`/`⏭️` | `<plan name> · complete · M/M` |
| No `## Progress` table | Say the plan has no table and that state is unknown. Infer nothing |
| No git repository in scope | `Session:  no repo` — a state, not an error |

**An edge-case line replaces the `Doing`/`Done`/`Session`/`Next`/`Blocked` block — but the name line
and the pointer still print.** So the no-table case is three lines, not two: name, the no-table line,
pointer. "Never drop the pointer" is absolute; the trimming rule above governs only the normal shape.

**The `Session` line is dropped in an edge case**, because git tells you nothing about a plan whose
state is unknown — except in the *no plan resolves* case, which is nothing but session state.

## Examples

**Mid-flight** — 7 lines: the plan name and ticket, `Doing` = the one `🟡`, `Done: 12/18`, the
branch and two dirty counts, three `Next` ids, one `Blocked` id with its reason, the pointer.

**Not started** — `Doing` names the first `⬜`, `Done: 0/24`, no `Blocked` line. Six lines.

**Twenty blocked rows** — the budget bites: `Next` drops to one item and `Blocked` collapses to
`Blocked:  4, 7, 9, 11, 12, …` — but it is still there, because it is the reason anyone ran this.

**A plan with no table** — three lines: the name, that it has no Progress table so its state is
unknown, and the pointer. No counts, no inference, no offer to add one.
