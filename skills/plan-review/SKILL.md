---
name: plan-review
description: >-
  Reviews and refines an implementation plan round by round until nothing above
  Very Low remains, then fixes the remaining Very Low nits in a closing pass —
  only deliberate tradeoffs stay accepted, with reasons. Round 1 is run by a
  reviewer subagent the skill dispatches, which did not write the plan; later
  rounds re-check the fixes in-thread, and every finding is CONFIRMED with a
  quote or marked UNVERIFIED. Use when the user invokes /plan-review, asks to
  review or harden a plan, or wants a plan review cycle after planning.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---
# Plan Review

Iteratively review and refine an implementation plan until only **Very Low** findings remain.

**The loop** is the Step headings below, one numbering: Steps 1–3 (review, fix, decide) repeat, one
**round** per pass, until nothing above Very Low remains; then Step 4 (closing pass) and Step 5.

## Resolve the plan file

The ladder in [CONVENTIONS.md](../plan-shared/CONVENTIONS.md). This skill edits the plan, so at the
last rung — or with two or more plausible at any rung — it lists the candidates with mtimes and
stops rather than picking one.

Read the **full plan** (YAML frontmatter + body), not just todos.

## Step 1 — Review the plan

Review the plan as an **implementation spec**, not repository code: findings first, ordered by
severity, no praise or broad summaries. Do **not** edit the plan in Step 1 — fixes happen in Step 2.
Do not invoke Bugbot, security review, or project MR/local code-review skills — those target repo
diffs.

### Round 1 — a dispatched reviewer subagent

Independence comes from a reviewer that did not write the plan, dispatched by this skill. In order:

- **Note `git status --short`** in each repository in scope (`CONVENTIONS.md`, *Terms*), and the
  plan's checksum (`shasum -a 256 <plan>`) — the plan usually sits outside every repository.
- **Dispatch one fresh `Explore` subagent** with [reviewer-prompt.md](reviewer-prompt.md): the text
  below its `---` line, `{plan}` and `{checklist}` replaced with the paths of the plan and
  [checklist.md](checklist.md), nothing added. Set its model **explicitly**, on the row-reviewer
  tiers of [DISPATCH.md](../plan-build/DISPATCH.md) §3. The prompt resolves paths across the scope.
- **Save its reply verbatim** as `~/.claude/plan-runs/<plan stem>/plan-review/review-<n>.md`, `<n>`
  the next free number — outside every repository, and never over an earlier cycle's review.
- **Run the write check** (`DISPATCH.md` §6): both notes against the present, plus the scratchpad
  and the review's directory — anything the controller did not write. Any write is a finding; stray
  files are removed, and a changed plan is restored to the text read before dispatch.
- **Build the round output** below from the reply — findings, labels, locations, severities as given.

**Host without subagents** (Cursor): run round 1 in-thread with the same prompt, filled the same
way, labelled `same-agent` in the cycle log.

### Rounds 2 onward — scoped re-checks, in-thread

Re-check the fixes and whatever they touched, with the lenses, checklist and spot-check rules of
[reviewer-prompt.md](reviewer-prompt.md) — not a fresh review of the whole plan.

### Evidence — every round

Every finding is **CONFIRMED** — quoting the plan's own words, plus the file line or the command and
its output when it rests on the repository — or **UNVERIFIED**, saying what could not be checked and
why. **Refute before reporting:** look for the step that covers the finding, the section that defers
it, the decision that records it as deliberate, the marker that gates it. Report only what survives.

### Optional — a `/code-review` pass (Claude Code only)

`/code-review` may be run on the plan file as an extra pass in any round, **never as the source of
independence**: whether it fans out to separate agents or runs as a single pass by the calling agent
depends on how it is invoked, not on this skill. Its findings join the round output under the
evidence rules and severity scale here, and the cycle log records the **mode it actually ran in** —
fanned out, or a single pass by the calling agent — as its output reports it. No `/code-review`: skip.

### Severity scale

Stop threshold = **Very Low**. Findings at or above **Low** block completion.

| Severity | Meaning | Action |
|----------|---------|--------|
| Critical | Plan would cause data loss, security breach, or prod outage if followed | Must fix; loop continues |
| High | Major gap or incorrect approach likely to fail implementation | Must fix; loop continues |
| Medium | Important missing detail, unclear ownership, or risky omission | Must fix; loop continues |
| Low | Should fix for clarity or maintainability | Must fix; loop continues |
| Very Low | Nit, optional polish, safe-by-design tradeoff | Never blocks stop; fixed in the closing pass (Step 4). A deliberate tradeoff stays accepted, with its reason |

### Round output (before fixing)

Print findings first, ordered by severity (Critical → Very Low), each with its label and evidence —
the quoted words, or the command and its output. Then a compact table with exactly these columns:

| Severity | Evidence | Location | Finding |

- **Evidence** — `CONFIRMED` or `UNVERIFIED`
- **Location** — plan section or heading (e.g. `Phase 2 — Rollout`, `todos: phase3-validate`), not `file:line`
- One-line status after the table: `Round {N}: {count} findings ({Critical: X} {High: X} {Medium: X} {Low: X} {Very Low: X})`

## Step 2 — Fix relevant findings

- **Relevant** = Critical, High, Medium, Low → edit the plan file directly
- Preserve the plan's structure — in Cursor, the frontmatter (`name`, `overview`, `todos`); in Claude
  Code, the `## Progress` table. **When a fix changes scope, update the steps in the same edit**:
  frontmatter todos in Cursor, Progress rows in Claude — add, split, or retire them per
  `plan-atomic-todos.md` and `plan-progress-section.md`. A review fix that grows the body but not the
  step list recreates the drift this skill exists to catch
- Keep edits minimal and scoped to each finding
- Do **not** fix Very Low items during the loop — churning nits every round blocks convergence. The
  closing pass (Step 4) fixes them once, after the loop stops

In **plan mode**, still edit the **plan file** directly (plan markdown is in-scope). Do not ask for confirmation before plan edits. Only skip writes when the environment truly cannot edit files.

## Step 3 — Loop decision

After fixes, re-read the **updated** plan and run Step 1 again (new round) — a scoped re-check.

- **Continue** if the latest review round has any finding above Very Low
- **Stop** when the latest round has **only** Very Low findings or **zero** findings

## Step 4 — Closing pass: fix the Very Lows

The loop has stopped — nothing above Very Low remains. Now fix the Very Low findings too, once,
instead of leaving them as a list the user has to act on:

- **Fix each Very Low finding directly**, same editing rules as Step 2.
- **Exception — deliberate tradeoffs stay.** A Very Low that records a safe-by-design choice, where
  the "fix" would change intended behavior or make the plan worse (duplicating a statement invites
  drift; an id pinned in the plan goes stale), is *accepted*, not fixed. Keep it with its reason.
- **Re-read the edited sections once** after the pass — nit fixes break cross-references more often
  than they break anything else. If a closing fix introduced something **Low or above**, that is a new
  round: go back to Step 1. The 10-round cap still applies; the closing pass never loops on its own.

## Step 5 — Stop and document

Append or update a `### Plan review cycle` section in the plan:

```markdown
### Plan review cycle

| Round | Low+ found | Action |
| ----- | ---------- | ------ |
| 1     | …          | …      |
| 2     | None       | Stopped — very low only |

**Round 1 reviewer:** dispatched subagent, <tier> tier — `<review file>`
**Very low (fixed at close):** …
**Very low (accepted):** … — each with its reason
```

- **Low+ found** — brief list of every finding above Very Low, severity-labelled, or `None`. Low
  findings continue the loop, so a round that found only Lows must not read `None` — that is the
  stop signature
- **Re-reviewing a plan whose existing log has the old `Medium+ found` header:** rename the header
  to `Low+ found` in the same edit that appends the new rows — old rows keep their meaning (they
  never hid Lows behind `None` knowingly), and mixing the two semantics under one header recreates
  the ambiguity the rename removed
- **Action** — what was fixed that round, or `Stopped — very low only` / `Stop review cycle`
- **Round 1 reviewer** — `dispatched subagent`, the tier it ran on and the saved review's path; or
  `same-agent` on a host without subagents. A later cycle adds its own line
- **`/code-review`** — only when one ran: a `**/code-review:**` line naming the round and the mode it
  actually ran in
- **Very low (fixed at close)** — what the closing pass fixed; **(accepted)** — only deliberate
  tradeoffs, each with the reason it was kept

Final message to the user:

- Round count
- Highest severity in the last round
- Whether the cycle stopped on very-low-only or clean
- Path to the plan file

## Safety guards

- **Max rounds: 10** — if exceeded, stop and report the stuck findings
- **Stall** — the loop has stalled, so stop and report the stuck findings to the user, when either
  the count of findings at **Low or above** does not fall between two consecutive rounds, or the
  same Low-or-above finding appears unchanged in two consecutive rounds. Low findings block
  completion too; a stuck Low must not burn rounds silently until the cap. A round the closing pass
  reopens is exempt from the count test — the round before it found none
- **Plan mode** — edit the plan file freely; do not block on user confirmation for plan markdown updates

## Examples

**Round 1 finds a missing rollback (Medium):**

1. The dispatched reviewer reports a CONFIRMED Medium under `Phase 3 — Cutover`, quoting the step
2. Add rollback steps to the plan
3. Re-read plan → Round 2, an in-thread re-check of the rollback steps

**Round 2 finds only Very Low nits:**

1. Print Very Low findings (optional pagination note, diagram label, a stale cross-reference)
2. Closing pass: fix them — except the one recording a deliberate tradeoff, which stays accepted
   with its reason
3. Re-read the edited sections; nothing new above Very Low → write cycle log → stop

**Clean plan:**

1. Round 1 (the dispatched reviewer): zero findings
2. Nothing for the closing pass — write cycle log with `None` / `Stop review cycle` → stop immediately
