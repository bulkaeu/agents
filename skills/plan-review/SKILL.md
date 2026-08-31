---
name: plan-review
description: >-
  Iteratively review and refine implementation plans until only Very Low findings
  remain. In Cursor, step 1 uses the /code-review command on the plan; in Claude
  Code, uses an inlined review mindset. Use when the user invokes /plan-review,
  asks to review or harden a plan, or wants a plan review cycle after planning.
disable-model-invocation: true
argument-hint: "[optional plan path]"
---
# Plan Review

Iteratively review and refine an implementation plan until only **Very Low** findings remain.

## Review loop

1. **Review the plan** — **Cursor:** `/code-review` the plan (see Step 1 — Cursor). **Claude Code:** apply Review mindset (see Step 1 — Claude Code). Print findings before fixing.
2. **Fix all relevant findings** — edit the plan (Step 2)
3. If this round found anything above **Very Low** severity → go to step 1
4. If only **Very Low** findings (or none) → stop and document (Step 4)

## Resolve the plan file

1. If the user passes a path or `@`-mentions a `.plan.md` or plan markdown file → use it.
2. Else if the conversation has a clear active plan (recent plan output, or only one plan file touched this session — commonly `~/.cursor/plans/*.plan.md` or `.cursor/plans/*.plan.md`) → use that.
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

Apply this **Review mindset** (Claude has no `/code-review` command):

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
| Very Low | Nit, optional polish, safe-by-design tradeoff | Document as accepted; do not block stop |

### Round output (before fixing)

Print findings first, ordered by severity (Critical → Very Low). Then a compact markdown table with exactly these columns:

| Severity | Location | Finding |

- **Location** — plan section or heading (e.g. `Phase 2 — Rollout`, `todos: phase3-validate`), not `file:line`
- One-line status after the table: `Round {N}: {count} findings ({Critical: X} {High: X} {Medium: X} {Low: X} {Very Low: X})`

## Step 2 — Fix relevant findings

- **Relevant** = Critical, High, Medium, Low → edit the plan file directly
- Preserve plan frontmatter (`name`, `overview`, `todos`) — update todos when fixes change scope
- Keep edits minimal and scoped to each finding
- Do **not** "fix" Very Low items unless the user asked; list them under **Very low (accepted)** in the cycle log

In **plan mode**, still edit the **plan file** directly (plan markdown is in-scope). Do not ask for confirmation before plan edits. Only skip writes when the environment truly cannot edit files.

## Step 3 — Loop decision

After fixes, re-read the **updated** plan and run step 1 again (new round).

- **Continue** if the latest review round has any finding above Very Low
- **Stop** when the latest round has **only** Very Low findings or **zero** findings

## Step 4 — Stop and document

Append or update a `### Plan review cycle` section in the plan:

```markdown
### Plan review cycle

| Round | Medium+ found | Action |
| ----- | ------------- | ------ |
| 1     | …             | …      |
| 2     | None          | Stopped — very low only |

**Very low (accepted):** …
```

- **Medium+ found** — brief list of Critical/High/Medium findings, or `None`
- **Action** — what was fixed that round, or `Stopped — very low only` / `Stop review cycle`

Final message to the user:

- Round count
- Highest severity in the last round
- Whether the cycle stopped on very-low-only or clean
- Path to the plan file

## Safety guards

- **Max rounds: 10** — if exceeded, stop and report stuck findings
- **No-op detection** — if the same Medium+ finding appears in two consecutive rounds unchanged, stop and ask the user
- **Plan mode** — edit the plan file freely; do not block on user confirmation for plan markdown updates

## Examples

**Round 1 finds a missing rollback (Medium):**

1. Print Medium finding under `Phase 3 — Cutover`
2. Add rollback steps to the plan
3. Re-read plan → Round 2

**Round 2 finds only Very Low nits:**

1. Print Very Low findings (optional pagination note, diagram label)
2. Do not edit for Very Low unless asked
3. Write cycle log → stop

**Clean plan:**

1. Round 1: zero findings
2. Write cycle log with `None` / `Stop review cycle` → stop immediately
