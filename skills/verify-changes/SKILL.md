---
name: verify-changes
description: >-
  Stage conversation-related changes, run in-agent /code-review --fix per
  repo, pause with decision reports for ambiguous fixes, then summarize changes.
  Use when the user invokes /verify-changes or asks to verify changes.
disable-model-invocation: true
---

# Verify Changes

Stage related work, path-scoped `/code-review --fix`, decision reports for ambiguous fixes, then one Changes report.

## Contract

1. Stage conversation/work-related files in each affected repo
2. `/code-review --fix` on **path-scoped** staged diffs (candidate set only); auto-fix clear findings
3. Decision reports when judgment is required
4. One combined Changes report (partial OK if decisions remain open)

## Staging permission (this run only)

Invoking this skill **is** explicit permission to `git add` **for this skill run only**. Overrides the global “never stage unless asked” rule while running. After the Changes report (or pause awaiting decisions with no further auto-work), that global rule applies again.

- Never commit, push, amend, or unstage files this skill did not stage
- Staging grant does **not** authorize migration apply/rollback or other gated ops

## Token budget

- Diff-first: `git diff --staged -- <candidate paths>`; full-file reads only to confirm a finding
- Path-scoped only — never full index / unrelated dirty files
- `git status` only in repos in the candidate set (or already touched this session); do not walk every sibling repo
- Round output: findings table only; Very Low → one-line count or defer to Changes report
- Fix narrowly; re-stage then re-diff candidate paths only
- Stop when no **clear Critical–Low** remain; do not burn rounds on Very Low
- One combined Changes report per run; no large diff dumps in reports
- No Bugbot / Security Review / explore Task unless user asks
- Process multi-repo sequentially

## Resolve staging set

Per repo with candidate paths:

1. **Candidates** = paths created/edited/deleted this session + paths the user clearly tied to this work
2. Intersect with dirty paths (`git status`: unstaged, untracked, already-staged)
3. **Exclude** secrets by default (`.env`, `.env.*`, `*credentials*`, `*secret*`, `*.pem`, `*.key`, similar). If related and dirty → list and ask; do not stage without yes
4. Unclear membership → list and ask; do not stage
5. `git add -- <paths…>` only — never `git add -A` / `git add .`

**Pre-existing staged (outside candidates):** leave staged; exclude from review; tell the user.

**Empty:** nothing related → stop. Related already staged → review without re-adding.

## Review + fix (per repo)

Apply `/code-review` mindset (bugs, regressions, security, missing tests). Same loop shape as plan-review; **do not** load that skill. Target path-scoped staged diffs.

| Severity | Action |
|----------|--------|
| Critical–Low | Auto-fix if clear; else park Decision |
| Very Low | Accept; do not auto-fix unless asked |

Stop repo loop when no clear Critical–Low left to fix; unclear Critical–Low stay parked as decisions.

| Auto-fix | Decision |
|------------|----------|
| One correct fix (bug, null check, wrong import, broken assertion, standard security fix) | Tradeoffs, public API/shape, behavior beyond intent, perf vs complexity, fix-vs-intentional |

### Loop

1. Review `git diff --staged -- <candidates>`; table: Severity \| Location (`file:line`) \| Finding
2. Auto-fix clear Critical–Low; new/renamed paths → add to candidates (secrets rules still apply)
3. `git add -- <paths…>` for fixed/created/deleted candidates before next round
4. Re-review (max **5** rounds). Same clear Critical–Low unchanged twice → park/ask
5. Continue other repos’ clear fixes while decisions are parked

### End of run (reports)

After all candidate repos finish clear auto-fix:

1. Open decisions → Decision report(s) + one combined Changes report (list open decisions)
2. Else → one combined Changes report only
3. Wait on decisions; do not guess. No per-repo Changes reports.

Read [report-templates.md](report-templates.md) only when writing reports.

### Resume after decisions

Apply chosen options → extend candidates if needed → re-stage → resume loop. When no clear Critical–Low and no open decisions → updated Changes report. If user leaves decisions open → partial Changes report stands; do not guess.

## Out of scope

Commit/PR/push/CI; staging unrelated paths; unstaging user’s unrelated staged files; migration apply; replacing Bugbot/security skills.
