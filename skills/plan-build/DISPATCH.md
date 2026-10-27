# Dispatch — a row built by one subagent and reviewed by another

Read by `plan-build` and `plan-continue` for every row [EXECUTION.md](EXECUTION.md) classifies as
*dispatch*. The controller — the session running the plan — coordinates, and writes no code itself
on those rows: code it wrote would skip the review that is the point of this file.

## Contents

- The run directory
- 1 Base · 2 Brief · 3 Agents and models · 4 Filling a prompt · 5 Statuses
- 6 Review · 7 Fix loop · 8 Rulings · 9 Record
- The run base · The final review · Fallback

## The run directory

`bash scripts/row-snapshot.sh dir <plan>` alone computes it: `~/.claude/plan-runs/<plan stem>-<path hash>/`.
On creating it, log `run dir: <the absolute path dir prints>` in the Run log; a legacy `<plan stem>`
directory, recorded or named by `dir` on stderr, is kept: log it. Each dispatched row gets `rows/<row id>/`:
the base, then per pass `<n>` `brief-<n>.md`, `report-<n>.md`, `diff-<n>.patch`, `impl-checks-<n>-<k>.txt`,
`checks-<n>.txt`, `review-<n>.md` — pass 1 the first attempt, each fix round adding one. The script numbers
the diffs; number the rest to match. All of it lives outside every repository, so none can reach a commit.

## 1. Base — once per repository in scope

Before the implementer starts:

```bash
bash scripts/row-snapshot.sh base <plan> <row id> --repo <repo> [--repo <repo>]...
```

It records a commit per repo plus a copy of every untracked file. **Never use `HEAD~1` as a base**:
it drops all but the last commit of a row that makes several. Exit 3 means no base can be recorded
(mid-rebase, no commits): park the row with the exit's reason. A dispatched row never runs inline.

A resumed `🟡` row with no recorded base takes `HEAD` as its base; the untracked files its row or
body section names count as the row's own work. `diff` says so in its header.

## 2. Brief — the implementer never reads the whole plan

Write `brief-<n>.md` with these sections, each quoted from the plan, not paraphrased:

- **`Mode:`** `row`, `rereview` or `run` — the reviewer reads it; the implementer ignores it.
- **Row** — its id and step text, verbatim, and its done-state.
- **Specification** — the body section or sections backing the row, found by name, not position.
- **Interfaces** — what the row consumes from earlier rows and what later rows need from it.
- **Scope** — the repositories it may change, and the plan file's path, which it may not.
- **Constraints** — the plan's global constraints, every project rule the work must obey, and the
  row's check commands, its runner's process name and its time limit, where the plan gives them —
  each slow check (`RULES.md` rule 7) wrapped with its own record `<rec>` =
  `<run dir>/rows/<row id>/impl-checks-<n>-<k>.txt`, `<k>` = 1, 2, … in brief order:
  `bash <this skill>/scripts/check-run.sh run <rec> --repo <repo> -- <command>`.
  `Explore` loads no instruction files, so a rule not written here does not exist for the reviewer.
- **Rulings** — every ruling touching this row, or `none`.

## 3. Agents and models

Models are named by tier — **standard**, **strong**, **strongest**. The model a tier means on each
host, never a Claude model on Cursor, is `CONVENTIONS.md`, *Model tiers*. An effort the table names
is Claude Code's and replaces the tier's; every other cell, and every other host, uses the tier's:

| Who | Default | Steps up |
| --- | --- | --- |
| Implementer | standard, at medium effort | strong, at medium effort, for a risky step, an edit to instructions, rules or prompts, and fix round 2 — on Codex from fix round 1; strongest, at medium effort, for fix round 3 only |
| Reviewer — row and rereview | strong, at medium effort | strong at high effort for a risky step — strongest on Codex, where this table's efforts do not apply; strongest at medium effort for a `review: deep` marker in the step text, fix round 3, a stalled fix loop |
| Final whole-run review | strong, at medium effort | strongest, at medium effort, if any row this run reached fix round 3, was reviewed under a `review: deep` marker or stalled its fix loop, or a Medium-or-worse defect turned up during the run |
| Final review's fix subagent, and its re-review | strong, at medium effort | never — strong whatever tier the final review ran on |
| `plan-add`'s explorer | standard, at the tier's effort — not the implementer's medium | never |

**Risky** means untrusted input reaching file paths or shell commands, auth, secrets, data deletion,
or migrations. The controller judges it from the step text and the diff. A `review: default` marker
cancels only the risk step-up: the row's reviewer keeps its default even when the step is
risky, but fix round 3 and a stalled fix loop still step it up, and the implementer still steps up.
A row carrying both `review: deep` and `review: default` gets the strongest-tier reviewer —
`review: deep` wins (`CONVENTIONS.md`, *Row markers*). **Every step-up, and every review of a
`review:`-marked row, is logged per `EXECUTION.md`, *The Run log*.**

- **Implementer:** a `general-purpose` subagent (`generalPurpose` on Cursor), model per the table.
  It returns its report as its reply. **Save that reply verbatim** as `report-<n>.md` — only the
  controller writes files, exactly as for a reviewer's review.
- **Reviewer:** an `Explore` subagent (`explore` on Cursor), model **set explicitly** per the
  table; `Explore` may otherwise default to a smaller one. `Explore` keeps Bash, so it is not
  read-only by construction: the prompt alone enforces it, and the write check below backs it up.
  It returns its findings as its reply. **Save that reply verbatim** as `review-<n>.md` — only the
  controller writes files, and a paraphrased review is not a review.
- Every dispatch is a **fresh** subagent. A re-review is a new reviewer handed the saved findings,
  never "the same reviewer" — subagents do not outlive their session.

## 4. Filling a prompt

Take the text below the `---` line of the prompt file and replace its placeholders with paths, or
with `none`. Add nothing: no hints, no expected answers, no pre-judged findings.

- [implementer-prompt.md](implementer-prompt.md) — `{brief}`, `{findings}`, `{out}` (the reply's path).
- [reviewer-prompt.md](reviewer-prompt.md) — `{brief}`, `{diff}`, `{report}`, `{findings}`, `{checks}`.

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

`diff` can exit 3 too: a recorded base is not an ancestor of `HEAD`, or no repository's status is `changed`.
A repository the report lists under Changed but `no changes since base` counts as exit 3. Either takes
§1's remedy: park the row with the exit's reason. Not an ancestor writes no paths file: leave the tree,
stop the run, print the reports' **Changed** union and `git status --short` (as for no usable report).

Before dispatching the reviewer, account for every check: the done-state command and each one the
brief names. Cite a slow check `k` whose `impl-checks-<n>-<k>.txt` `check-run.sh current` accepts,
pass or fail (`RULES.md` rule 7). Run every other check yourself (quick, unwrapped, unrecorded or
not current), slow ones into `checks-<n>-<k>.txt` in the background. Concatenate the records and
the quick checks' output, each command with its exit status, into `checks-<n>.txt`: a check silent
on success otherwise looks unrun. Dispatch the reviewer with that diff, the brief (`Mode: row`),
the report, `{checks}` = that file (or `none` if the row names no check), and `{findings}` = `none`.

**After every reviewer dispatch** — this one, a rereview in §7, and the final review below — compare
`git status --short` in each repository in scope against its state before the dispatch, and check
the scratchpad and the run directory for anything not saved there by the controller itself. Any write is
a finding, including one inside a location a brief named: a brief grants the reviewer no write location.
Record it like any other finding; list the stray files and ask, and remove them only on the user's yes.

## 7. Fix loop

**Open** means a spec ❌, or a finding at Critical, High or Medium. An UNVERIFIED open finding is
checked by the controller: confirmed, it stays open; refuted, it is dropped with a ruling. Low and
Very Low findings go to the Run log as *deferred* and do not enter the loop.

A defect the controller confirms itself while reading the diff (`RULES.md` rule 9) is an **open
finding**, handled exactly like a reviewer's CONFIRMED one: the controller records it with its
evidence in the row's findings file, it goes to a fresh implementer in the next fix round, and only
a fresh reviewer in `rereview` mode can report it ADDRESSED. **The controller never closes a finding
itself** — confirming one only opens it; §8's override of the step's wording applies to it the same
way, at Medium or above. Independence stays in the *finding* of defects and in the *closing* of them.

Each round: a fresh implementer with `{findings}` = the latest review file; a new diff from the
**original** base, so the whole row is shown with its fixes in; a fresh `checks-<n>.txt`, run as in
§6; a fresh reviewer, `Mode: rereview`. At most **3 rounds**, on §3's tiers: the implementer on
strong in round 2 (from round 1 on Codex), strongest in round 3, the reviewer strongest in round 3.
**If the open count does not fall** between two rounds, the loop has stalled: the next round's
review runs on the strongest tier. If it still does not fall after a strongest-tier review, or
anything is open after round 3, park the row with its open findings as the reason; no ruling
accepts one. A row is never ticked with a finding at Medium or above still open.

## 8. Rulings — including overriding the step's wording

A CONFIRMED finding at Medium or above that conflicts with the row's literal wording — a "copy
verbatim" that would ship a path traversal — **overrides the wording**. Log it in the Run log as

`R<n> · <row id> · <what> — <why> — <cost if wrong>`

and write it into the next fix brief and the re-review brief, so neither the implementer nor the
reviewer treats the departure as a spec failure. Rule 8 forbids narrowing a step to make it pass; a
ruling that raises the bar is its opposite. One that lowers the bar is not a ruling: park the row.

## 9. Record

Only the controller writes the table and commits. Before the tick: pass `EXECUTION.md`'s
verification gate — the done-state check run fresh, or cited from a `checks-<n>.txt` that
`check-run.sh current` accepts — every claimed file present, every claimed sha in `git log`. Then
`✅` with Notes carrying that evidence and a review token, its path its own backticked span so
`table-claims.sh` can check it: review: `rows/<row id>/review-<n>.md` PASS.

## The run base — per repository

The first run of a plan that records one writes it before its first row:

```bash
bash scripts/row-snapshot.sh base <plan> run --repo <repo>...
```

and lists each repo's sha in the Run log as `run base: <repo> <sha>`. **A later resume never
overwrites it** — if the Run log already has one, it stands. A repository that joins the run
later, such as a worktree, is based alone: `base <plan> run --repo <it>`.

## The final review

Before close-out, `row-snapshot.sh diff <plan> run --repo …` gives the whole run as one diff. With no run
base recorded, `diff` falls back to the merge-base with the remote default branch; say so in the Run log.
One fresh reviewer in `Mode: run`, briefed with the rows this run did, on §3's tiers, with `{checks}` = the
plan's `## Verification` commands run over the whole run. Findings at Medium or above go to **one** fix
subagent for the whole list, then one re-review, both on §3's tiers; no second wave. The fix subagent
reports **Changed** like an implementer; that list is its own paths. A foreign path in its diff stops the
run as for a row (`EXECUTION.md`); its commit names only its own paths, logged `inline final-fix: <paths>`
so `plan-finish` claims them. A finding at Medium or above still open is parked for the closing question,
never a ruling. Log `final review: <file> <verdict>`. Run §6's write check after it and after the re-review.

## Fallback — a host without subagents

The controller implements and reviews in-thread, with the same brief and diff, and labels the row's
Notes `review: same-agent`. That is weaker, and the label says so rather than hiding it.
