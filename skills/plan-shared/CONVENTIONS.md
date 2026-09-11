# Plan-skill conventions

Shared by all six plan skills. Each `SKILL.md` cites this file instead of restating it, so a change
here lands everywhere at once. The rules a plan *author* reads — `plan-progress-section.md`,
`plan-atomic-todos.md`, `plan-ticket-tracking.md` — own the formats; this file owns how the skills
read them.

## Contents

- Resolving the plan — the ladder
- The Progress table
- Row markers
- Closed, parked, open
- Terms
- Severity scale

## Resolving the plan — the ladder

In order, stopping at the first hit:

1. A path or `@`-mention in the invocation.
2. The session's active plan file, or the only plan touched this session.
3. The project's plan directory: walk up from cwd to the nearest `.claude/settings*.json` that sets
   `plansDirectory`, and resolve that value against **the directory holding that settings file** —
   often not a git toplevel. If none sets one, `plans/` under the git toplevel, if it exists.
4. The most recently modified plan in `~/.claude/plans/`, `~/.cursor/plans/`, `.cursor/plans/`.

**Two or more plausible at any rung → list them with mtimes and stop.** A report on the wrong plan
reads exactly like a report on the right one until it misleads.

**Stop means the report ends at the list:** the candidates newest first, each with its mtime — past
25, about a screenful, the 25 newest and the total count. No grouping, no ranking, and no pre-flight, verdict or
preview for any of them, however likely one looks; an example invocation uses a placeholder path,
never a candidate's. Choosing is the user's move; an "if you name this one…" report is a pick in all
but name. (`plan-finish`'s repo-only audit, below, is not an exception: it needs no plan, so it
previews none.)

**The last rung picks a plan only for the read-only skills**, `plan-status` and `plan-summary`. The
four that edit or execute — `plan-review`, `plan-build`, `plan-continue`, `plan-finish` — list the
candidates from rung 4 and stop there instead: executing or editing the wrong plan is not a mistake
you can take back. `plan-finish` then offers a repo-only audit, which needs no plan.

Read the whole file once resolved. The body is where the steps are actually specified.

## The Progress table

`plan-progress-section.md` owns the format. The legend, verbatim:

**Legend:** ⬜ waiting · 🟡 in progress · ✅ done · ⛔ blocked · ⏭️ skipped (reason required)

The first cell is `<id> <icon>`; the Step cell is a kebab-case step id, an em-dash, one line. **State
comes from the icon, never from step text** — a `⬜` row whose text says `BLOCKED` is waiting.

**Legacy tables** that put the icon in its own `Status` column count too: if any row carries one of
the five icons in any cell, that table is the Progress table. Take the step from the first
non-numeric text cell and the notes from the last. Never offer to convert one.

## Row markers

Markers live in the Step cell's text. The skills parse exactly these:

| Marker | Means |
| --- | --- |
| `BLOCKED — wait for user: …` or `BLOCKED — wait for user confirmation: …` | The step needs the user's action or yes. Both spellings are accepted; an executor parks it unless the action is already evidenced (`STOPS.md`) |
| `hand-off row` | The step gives the user work to do outside the run, then the run ends. The one sanctioned mid-table halt |
| `(⏭️ if …)` | A conditional skip the author allowed in advance; the Notes must say which condition held |
| `review: deep` | The row's reviewer runs on the strongest model tier (`DISPATCH.md` §3). On a row that also carries `review: default`, `review: deep` wins: an author asking for depth outranks an exemption. Every review of the row logs its reviewer's tier and reason in the Run log, naming the row and the review file it covers |
| `review: default` | The row's reviewer stays on the default tier even when the controller would judge the step risky. It cancels only that risk step-up: fix round 3 and a stalled fix loop still step the reviewer up, and a risky row's implementer still steps up. Every review of the row logs its reviewer's tier and reason in the Run log, naming the row and the review file it covers, whether or not the marker held anything back. `review: deep` on the same row wins |

**A pending ticket is author-parked.** `plan-ticket-tracking.md`'s `**Ticket:** pending` puts a `⛔`
row in a brand-new plan. That row was parked by the author, not by a run, so it does not make the
plan a resume.

## Closed, parked, open

These replace "resolved", which meant three things.

| Term | Rows |
| --- | --- |
| **Closed** | `✅`, and `⏭️` with a reason |
| **Parked** | `⛔` with a named blocker |
| **Open** | `⬜` and `🟡` |

A plan is **complete** when every row is closed. A run can **finish** with rows parked — that is
what the closing question is for — but never with rows open, except behind a hand-off row.

## Terms

- **Row id** — the first cell's id (`A1`, `12`, `§2.1`). Reports cite rows by id, never by ordinal.
- **Step id** — the kebab-case name in backticks at the start of the Step cell.
- **Done-state** — what the step names as observable proof it finished: a count, a file, an exit
  code. A step with none is under-specified; say so rather than inventing one.
- **Auditable Note** — carries at least one thing you could go and check: a path, count, sha,
  version, size or timing. `Wrote out/alpha.txt, 6 B` is auditable; `Wrote the file` is not.
- **Run log** — the optional `## Run log` section after the body: rulings, deferred findings, review
  records. It survives compaction because it is in the file.
- **Repository scope** — every repo the plan touches: its own paths, the cwd, and anything in
  `git worktree list`. **No repository in scope is a state, not an error.**

## Severity scale

One scale for every review in the family — plan review, row review, final review, stage review.

| Severity | Meaning |
| --- | --- |
| Critical | Would cause data loss, a security breach, or an outage if shipped or followed |
| High | A major gap or wrong approach likely to make the work fail |
| Medium | An important missing detail, unclear ownership, or a risky omission |
| Low | Should be fixed for clarity or maintainability |
| Very Low | A nit, optional polish, or a safe-by-design tradeoff |

What each skill does with a severity — loop, fix, defer — is that skill's call, stated in its own
file.
