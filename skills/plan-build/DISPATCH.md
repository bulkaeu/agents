# Dispatch — a row built by one subagent and reviewed by another

Read by `plan-build` and `plan-continue` for every row [EXECUTION.md](EXECUTION.md) classifies as
*dispatch*. The controller — the session running the plan — coordinates, and writes no code itself
on those rows: code it wrote would skip the review that is the point of this file.

## Contents

- The run directory
- 1 Base · 2 Brief · 3 Agents and models · 4 Filling a prompt · 5 Statuses
- 6 Review · 7 Fix loop · 8 Rulings · 9 Record
- The run base · The final review · Fallback · Cost

## The run directory

`bash scripts/row-snapshot.sh dir <plan>` prints it: `~/.claude/plan-runs/<plan stem>/`. Each
dispatched row gets `rows/<row id>/`, holding the base, then one set of files per pass `<n>` —
`brief-<n>.md`, `report-<n>.md`, `diff-<n>.patch`, `review-<n>.md` — where pass 1 is the first
attempt and each fix round adds one. The script numbers the diffs; number the rest to match. It all
lives outside every repository, so none of it can reach a commit.

## 1. Base — once per repository in scope

Before the implementer starts:

```bash
bash scripts/row-snapshot.sh base <plan> <row id> --repo <repo> [--repo <repo>]...
```

It records a commit per repo plus a copy of every untracked file. **Never use `HEAD~1` as a base**:
it drops all but the last commit of a row that makes several. Exit 3 means no base can be recorded
(mid-rebase, no commits): run the row inline and label its Notes `review: none — no base`.

A resumed `🟡` row with no recorded base takes `HEAD` as its base; the untracked files its row or
body section names count as the row's own work. `diff` says so in its header.

## 2. Brief — the implementer never reads the whole plan

Write `brief-<n>.md` with these sections, each quoted from the plan, not paraphrased:

- **`Mode:`** `row`, `rereview` or `run` — the reviewer reads it; the implementer ignores it.
- **Row** — its id and step text, verbatim, and its done-state.
- **Specification** — the body section or sections backing the row, found by name, not position.
- **Interfaces** — what the row consumes from earlier rows and what later rows need from it.
- **Scope** — the repositories it may change, and the plan file's path, which it may not.
- **Constraints** — the plan's global constraints, and every project rule the work must obey.
  `Explore` loads no instruction files, so a rule not written here does not exist for the reviewer.
- **Rulings** — every ruling touching this row, or `none`.

## 3. Agents and models

Models are named by tier — **standard**, **strong**, **strongest**. The model a tier means on each
host, never a Claude model on Cursor, is `CONVENTIONS.md`, *Model tiers*:

| Who | Default | Steps up |
| --- | --- | --- |
| Implementer | standard | strong for a risky step, an edit to instructions, rules or prompts, and fix round 2; strongest for fix round 3 only |
| Reviewer — row and rereview | strong | strongest for a risky step, a `review: deep` marker in the step text, fix round 3, a stalled fix loop |
| Final whole-run review | strong | strongest if any dispatch this run went to the strongest tier, or a Medium-or-worse defect turned up during the run |

**Risky** means untrusted input reaching file paths or shell commands, auth, secrets, data deletion,
or migrations. The controller judges it from the step text and the diff. A `review: default` marker
cancels only the risk step-up: the row's reviewer stays on the default tier even when the step is
risky, but fix round 3 and a stalled fix loop still step it up, and the implementer still steps up.
A row carrying both `review: deep` and `review: default` gets the strongest-tier reviewer —
`review: deep` wins (`CONVENTIONS.md`, *Row markers*). **Every step-up is logged in the Run log
with its reason** — `reviewer on the strongest tier: step writes to a path built from an argument`.
**A row carrying a `review:` marker, `deep` or `default`, has its reviewer's tier logged for every
review of that row, whether or not the marker changed anything** — one line per review, with its
reason, naming the row and the review file it covers (it is also the step-up's line when there is
one), so a fix loop whose tier changes (round 3, a stall) still shows which review ran on which
tier: `<row id> · review-<n>.md — reviewer on the strongest tier: review: deep marker`,
`<row id> · review-<n>.md — reviewer on the default tier: review: default holds a step that
deletes data`, `<row id> · review-<n>.md — reviewer on the default tier: review: default marker,
step not risky`, `<row id> · review-<n>.md — reviewer on the strongest tier: fix round 3, which
review: default does not cancel`.

- **Implementer:** a `general-purpose` subagent (`generalPurpose` on Cursor), model per the table.
  It returns its report as its reply. **Save that reply verbatim** as `report-<n>.md` — only the
  controller writes files, exactly as for a reviewer's review.
- **Reviewer:** an `Explore` subagent (`explore` on Cursor), model **set explicitly** per the
  table; `Explore` may otherwise default to a smaller one. `Explore` keeps Bash, so it is not
  read-only by construction — read-only is enforced by the prompt alone, and the write check below
  backs it up.
  It returns its findings as its reply. **Save that reply verbatim** as `review-<n>.md` — only the
  controller writes files, and a paraphrased review is not a review.
- Every dispatch is a **fresh** subagent. A re-review is a new reviewer handed the saved findings,
  never "the same reviewer" — subagents do not outlive their session.

## 4. Filling a prompt

Take the text below the `---` line of the prompt file and replace its placeholders with paths, or
with `none`. Add nothing: no hints, no expected answers, no pre-judged findings.

- [implementer-prompt.md](implementer-prompt.md) — `{brief}`, `{findings}`, `{out}` (the path the
  controller saves the reply to).
- [reviewer-prompt.md](reviewer-prompt.md) — `{brief}`, `{diff}`, `{report}`, `{findings}`.

## 5. Statuses

**Status tokens:** `DONE` · `DONE_WITH_CONCERNS` · `BLOCKED` · `NEEDS_CONTEXT`

- `DONE` and `DONE_WITH_CONCERNS` — package the diff and review it. Concerns reach the reviewer
  through the report; do not restate them.
- `BLOCKED` — a stop-list reason parks the row (`RULES.md` rule 3); "cannot be done as written"
  parks it too (rule 8). Never re-dispatch a narrowed step.
- `NEEDS_CONTEXT` — add what was missing to a new brief and dispatch once more. A second
  `NEEDS_CONTEXT` parks the row as under-specified.

## 6. Review

```bash
bash scripts/row-snapshot.sh diff <plan> <row id> --repo <repo>...
```

Dispatch the reviewer with that diff, the brief (`Mode: row`), the report, and `{findings}` = `none`.

**After every reviewer dispatch** — this one, a rereview in §7, and the final review below — compare
`git status --short` in each repository in scope against its state before the dispatch, and check
the scratchpad and the run directory for anything not saved there by the controller itself. Any
write is a finding, recorded like any other finding; stray files are removed.

## 7. Fix loop

**Open** means a spec ❌, or a finding at Critical, High or Medium. An UNVERIFIED open finding is
checked by the controller: confirmed, it stays open; refuted, it is dropped with a ruling. Low and
Very Low findings go to the Run log as *deferred* and do not enter the loop.

A defect the controller confirms itself while reading the diff (`RULES.md` rule 9) is an **open
finding**, handled exactly like a reviewer's CONFIRMED one: the controller records it with its
evidence in the row's findings file, it goes to a fresh implementer in the next fix round, and only
a fresh reviewer in `rereview` mode can report it ADDRESSED. **The controller never closes a finding
itself** — confirming one only opens it; §8's override of the step's wording applies to it the same
way, at Medium or above. Independence stays in the *finding* of defects and in the *closing* of
them.

Each round: a fresh implementer with `{findings}` = the latest review file; a new diff from the
**original** base, so the whole row is shown with its fixes in; a fresh reviewer, `Mode: rereview`.
At most **3 rounds**, on §3's tiers: the implementer on strong in round 2 and strongest in round 3,
the reviewer on strongest in round 3. **If the open count does not fall** between two rounds, the
loop has stalled: the next round's review runs on the strongest tier. If it still does not fall after
a strongest-tier review, or anything is open after round 3, stop and write a ruling: accept with the
reason and the risk, or park the row. A row is never ticked with a finding at Medium or above still
open.

## 8. Rulings — including overriding the step's wording

A CONFIRMED finding at Medium or above that conflicts with the row's literal wording — a "copy
verbatim" that would ship a path traversal — **overrides the wording**. Log it in the Run log as

`R<n> · <row id> · <what> — <why> — <cost if wrong>`

and write it into the next fix brief and the re-review brief, so neither the implementer nor the
reviewer treats the departure as a spec failure. Rule 8 forbids narrowing a step to make it pass; a
ruling that raises the bar is its opposite. One that lowers the bar is not a ruling: park the row.

## 9. Record

Only the controller writes the table and commits. Before the tick: run the done-state check fresh,
confirm every claimed file exists and every claimed sha is in `git log`. Then `✅` with Notes
carrying that evidence and a review token, its path its own backticked span so
`table-claims.sh` can check it: review: `rows/<row id>/review-<n>.md` PASS.

## The run base — per repository

The first run of a plan that records one writes it before its first row:

```bash
bash scripts/row-snapshot.sh base <plan> run --repo <repo>...
```

and lists each repo's sha in the Run log as `run base: <repo> <sha>`. **A later resume never
overwrites it** — if the Run log already has one, it stands.

## The final review

After the last row and before close-out: `row-snapshot.sh diff <plan> run --repo …` gives the whole
run as one diff file. With no run base recorded, diff against `@{upstream}` and say so in the Run
log. One fresh reviewer in `Mode: run`, its brief listing the rows this run did, on the tier §3's
last row gives: strongest if any dispatch this run went to the strongest tier or a Medium-or-worse
defect turned up during the run, strong otherwise — the step-up logged like any other. Findings at
Medium or above go to **one** fix subagent for the whole list, then one re-review; there is no
second wave. What stays open is a ruling or a parked item for the closing question. Log
`final review: <file> <verdict>` in the Run log. Run the write check from §6 after this dispatch,
and after the re-review, too.

## Fallback — a host without subagents

The controller implements and reviews in-thread, with the same brief and diff, and labels the row's
Notes `review: same-agent`. That is weaker, and the label says so rather than hiding it.

## Cost

A dispatched row costs at least 2 subagents, and up to 9 — one `NEEDS_CONTEXT` retry, then three
fix rounds; the final review adds 1 to 3. Only code rows dispatch, each on §3's tiers: implementers
standard and reviewers strong by default, stepping up on the table's triggers. A dry run prints the
floor — 2 × dispatched rows + 1 — and its count per model tier before anything starts.
