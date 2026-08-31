---
description: Every plan opens with a Progress table of atomic steps — status icon, name, notes — kept current as work proceeds
alwaysApply: true
---

# Plans open with a Progress section

Applies in **Cursor** and **Claude Code** whenever creating, iterating on, or executing a plan
(`~/.claude/plans/*.md`, `~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`, and any plan markdown
the user is working on).

## The rule

- **Every plan starts with `## Progress`**, after the H1 and before `## Context`. Exactly one thing
  may sit between them: the one-line `**Ticket:**` field that `plan-ticket-tracking.md` owns.
  Nothing else — a plan whose Progress table is below a paragraph of preamble is a plan whose
  status is not the first thing a reader sees. A plan without a Progress table is unfinished,
  even if the body is complete.
- **Write it when the plan is written** — not when execution starts. A plan that has never run is a
  table of `⬜` rows, and that is the useful state: it is the step list the user approves.
- **Legend line above the table**, verbatim:

  `**Legend:** ⬜ waiting · 🟡 in progress · ✅ done · ⛔ blocked · ⏭️ skipped (reason required)`

- **Three columns, no more.** Extra columns (dates, owners, estimates) belong in the body:

  | Column | Holds |
  | --- | --- |
  | `#` | Order number or phase id — `1`, `A1`, `§2.1` — **followed by the status icon**: `A1 ⬜` |
  | Step | A short kebab-case id, then an em-dash and one line saying what the step does |
  | Notes | Empty while waiting. On completion: what actually happened — counts, versions, paths. On `⛔`/`⏭️`: the reason |

- **Rows stay in execution order.** A step added mid-run goes where it actually ran, not next to the
  row that inspired it. Appending `E5` beside `E2` because they are both verification produces a
  table that reads `E1 E2 E5 E3 E4` — every reader then has to reconstruct the real sequence, and
  `/plan-summary`'s "last rows" window shows the wrong ones. Renumber rather than misplace.
- **Steps are atomic.** One verb, one done-state. `plan-atomic-todos.md` owns what atomic means;
  this rule owns the table it goes in.
- **Notes are mandatory for `⛔` and `⏭️`.** A blocked row without a blocker, or a skip without a
  reason, is not a valid row — that column is the whole reason a reader can trust the table.
- **Notes record the result, not the intent.** "Ran the suite" is not a note; "1,484 tests / 100
  suites green, `format:check` clean" is. A `✅` whose note only restates the step name is a `✅` no
  one can audit later.

## Keeping it current — this is the part that gets skipped

A Progress table is only worth having if it is true *right now*. A table updated in one batch at the
end is a changelog, not a progress tracker, and it was useless during the only window it mattered.

**Update the table the moment a boundary is crossed. Every one of these is a boundary:**

| Boundary | Edit |
| --- | --- |
| A step starts | `⬜` → `🟡` |
| A step finishes | `🟡` → `✅`, **and write the Notes cell in the same edit** |
| A step is blocked | → `⛔` with the blocker named in Notes |
| A step is skipped | → `⏭️` with the reason in Notes |
| A phase completes | Confirm every row in it is resolved before starting the next |
| Scope changes | Add, split, or retire rows in the same edit that changes the body |

**Rules for those edits:**

- **Update before moving on, not before reporting.** The edit belongs with the step that triggered
  it. Finishing three steps and then updating three rows loses exactly the information — what was
  true when — that the table exists to hold.
- **Never batch a phase's rows into one edit at the phase boundary.** The phase boundary is a
  *checkpoint* to confirm nothing was missed, not the moment to backfill six rows at once.
- **Write the Notes cell at the same time as the icon.** A `✅` added now with Notes "later" is a
  `✅` that never gets its Notes; the detail is gone by the next step.
- **Use `Edit`/`Write`, never Bash.** `ui-rendered-files-use-write-tool.md` owns why: a `sed -i` or
  heredoc lands the bytes but leaves the rendered panel showing the stale table.
- **A step you are told to skip still gets a row edit.** Silent omission and `⏭️ (reason)` look the
  same in the body and completely different to a reader six weeks later.
- Never delete a row to "clean up". Abandoned work becomes `⏭️` with the reason — the history of
  what was *not* done is worth as much as what was.

If a turn ends with the table disagreeing with what actually happened, that is a defect to fix
before anything else, not a tidy-up for later. The `Stop` hook in `~/.claude/settings.json` counts
`⬜`/`🟡` rows and will say so.

## Example

```markdown
## Progress

**Legend:** ⬜ waiting · 🟡 in progress · ✅ done · ⛔ blocked · ⏭️ skipped (reason required)

| # | Step | Notes |
| - | ---- | ----- |
| 1 | `add-index` — index on `events.created_at` | 2.1 M rows, 41 s, no lock contention |
| 2 | `backfill-nulls` — default the 12 k null rows | Ran in 4 slices; 12,047 updated, 0 errors |
| 3 | `drop-legacy-column` — remove `events.legacy_id` | Waiting on the read-replica cutover |
| 4 | `update-runbook` — document the new index | |
```

(Icons omitted in this fenced sample so the Stop hook does not count it as live work. In a real plan
every row's first cell carries one: `| 1 ✅ |`, `| 3 ⛔ |`.)

## Ownership

This rule owns **the Progress table**. Siblings own the rest, and none of them duplicates this one:

- `plan-atomic-todos.md` — how finely a step is cut.
- `ui-rendered-files-use-write-tool.md` — which tool writes the file.
- `no-plan-copies.md` — one topic, one plan file.
- `plan-mode-edit-plans.md` — that editing a plan needs no permission.
- `plan-ticket-tracking.md` — whether the plan is tracked, and the `**Ticket:**` line above the table.

The `/plan-summary` skill reads this table, and the `Stop` hook in `~/.claude/settings.json` counts
`⬜`/`🟡` rows to nag about unfinished work. Both depend on the first cell being `<id> <icon>` — a
row that puts the icon elsewhere is invisible to them.

<!-- Established 2026-08-31. Canonical copy: bulkaeu/agents → rules/plan-progress-section.md.
     install.sh links it to ~/.claude/rules/plan-progress-section.md and
     ~/.cursor/rules/plan-progress-section.mdc. Edit the repo copy, never a symlink. Keep the
     frontmatter — it is what makes alwaysApply work in Cursor. -->
