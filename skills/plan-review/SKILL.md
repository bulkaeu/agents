---
name: plan-review
description: >-
  Iteratively review and refine implementation plans until nothing above Very Low
  remains, then fix the remaining Very Low nits in a closing pass — only
  deliberate tradeoffs stay accepted, with reasons. Review runs via the
  /code-review command on the plan file where the session offers one, else an
  inlined review mindset. Use when the user invokes /plan-review, asks to review
  or harden a plan, or wants a plan review cycle after planning.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---
# Plan Review

Iteratively review and refine an implementation plan until only **Very Low** findings remain.

## Review loop

1. **Review the plan** — via the session's `/code-review` command targeted at the plan file when one exists (see Step 1), else the inlined Review mindset. Print findings before fixing.
2. **Fix all relevant findings** — edit the plan (Step 2)
3. If this round found anything above **Very Low** severity → go to step 1
4. If only **Very Low** findings (or none) → **closing pass**: fix those too (Step 4), then document (Step 5)

## Resolve the plan file

1. If the user passes a path or `@`-mentions a `.plan.md` or plan markdown file → use it.
2. Else if the conversation has a clear active plan (recent plan output, or only one plan file touched this session — commonly `~/.claude/plans/*.md` in Claude Code, `~/.cursor/plans/*.plan.md` or `.cursor/plans/*.plan.md` in Cursor) → use that.
3. Else ask once: "Which plan file should I review?"

Read the **full plan** (YAML frontmatter + body), not just todos.

## Step 1 — Review the plan

Review the plan as an **implementation spec**, not repository code. Findings first, ordered by severity, no praise or broad summaries. Do **not** edit the plan in step 1 — fixes happen in step 2.

Also read [checklist.md](checklist.md) for a structured pass. When the plan cites repo paths or behavior, spot-check against the codebase or docs if available — do not review the whole repository.

Map findings to the **Severity scale** below. Do not invoke Bugbot, security review, or project MR/local code-review skills — those target repo diffs.

### Step 1 — Cursor

Run **`/code-review`** with the **plan file** as the review target (not the repo diff).

Apply the `/code-review` command instructions verbatim, except:

- **Target** — the plan document (sections, todos, sequencing, ops steps), not source files
- **Priorities** — same as `/code-review`: bugs, behavioral regressions, security issues, missing tests — interpreted for plan correctness, rollout safety, IAM/ops gaps, and missing verification
- **Output** — use this skill's severity labels and **Round output** format (include **Very Low**)
- **Edits** — do not change the plan in this step; step 2 handles fixes

If `/code-review` is unavailable, fall back to **Step 1 — Claude Code**.

### Step 1 — Claude Code

If this session offers a `/code-review` skill or command, run it with the **plan file** as the target,
exactly as the Cursor branch does — same exceptions, same output shape. Only when none is available,
apply this **Review mindset**:

1. **Correctness** — wrong assumptions, impossible sequencing, missing prerequisites
2. **Behavioral regressions** — steps that break existing flows or skip cutover/rollback
3. **Security** — IAM gaps, secret handling, tenancy/auth gaps described in the plan
4. **Missing verification** — no smoke test, rollback, acceptance criteria, or test plan where behavior changes
5. **Internal consistency** — todos vs body, naming, cross-references, duplicated or conflicting steps

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

Print findings first, ordered by severity (Critical → Very Low). Then a compact markdown table with exactly these columns:

| Severity | Location | Finding |

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

After fixes, re-read the **updated** plan and run step 1 again (new round).

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

**Very low (fixed at close):** …
**Very low (accepted):** … — each with its reason
```

- **Low+ found** — brief list of every finding above Very Low, severity-labelled, or `None`. Low
  findings continue the loop, so a round that found only Lows must not read `None` — that is the
  stop signature
- **Action** — what was fixed that round, or `Stopped — very low only` / `Stop review cycle`
- **Very low (fixed at close)** — what the closing pass fixed; **(accepted)** — only deliberate
  tradeoffs, each with the reason it was kept

Final message to the user:

- Round count
- Highest severity in the last round
- Whether the cycle stopped on very-low-only or clean
- Path to the plan file

## Safety guards

- **Max rounds: 10** — if exceeded, stop and report stuck findings
- **No-op detection** — if the same **Low-or-above** finding appears in two consecutive rounds unchanged, stop and ask the user. Low findings block completion too; a stuck Low must not burn rounds silently until the cap
- **Plan mode** — edit the plan file freely; do not block on user confirmation for plan markdown updates

## Examples

**Round 1 finds a missing rollback (Medium):**

1. Print Medium finding under `Phase 3 — Cutover`
2. Add rollback steps to the plan
3. Re-read plan → Round 2

**Round 2 finds only Very Low nits:**

1. Print Very Low findings (optional pagination note, diagram label, a stale cross-reference)
2. Closing pass: fix them — except the one recording a deliberate tradeoff, which stays accepted
   with its reason
3. Re-read the edited sections; nothing new above Very Low → write cycle log → stop

**Clean plan:**

1. Round 1: zero findings
2. Nothing for the closing pass — write cycle log with `None` / `Stop review cycle` → stop immediately

**Closing fix backfires:**

1. Loop stops; closing pass rewords a nit and breaks a section cross-reference (Low)
2. That is a new round: back to Step 1, fix it, re-stop — still within the 10-round cap
