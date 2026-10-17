---
description: Third-party skills defer to the rules here however they arrived, vendored or plugin or marketplace — plans go to the plans repo with a Progress table, nothing is pushed or merged unasked, and six skills are on demand only
alwaysApply: true
---

# Third-party skills defer to these rules

Applies whenever a third-party skill is loaded or invoked, in any host, however it arrived —
vendored, installed as a plugin, or pulled from a marketplace.

A third-party skill was written for somebody else's workflow, and it states its conventions as
confidently as these rules state theirs. **Where the two disagree, the rules here win.** The clauses
below are the disagreements that actually exist; each names the failure mode and which side wins.

## Where our rules win

- **Plans and specs.** A brainstorming or plan-writing skill that files its output into a docs
  directory inside the project is wrong here: the document goes to the plans repo
  (`plans-live-in-a-plans-repo.md`) and opens with a Summary and a Progress table
  (`plan-progress-section.md`). Keep the skill's own `### Task N:` headings below that opening —
  downstream task extraction parses them.
- **Progress ticking.** A plan-executing skill ticks the Progress table as it goes, at every
  boundary. Tracking only in its todo list or its own ledger leaves the table stale, which is the
  one defect `plan-progress-section.md` exists to prevent.
- **Pushes, PRs, merges, review replies and publishing.** No third-party skill does any of these
  unless the user asked in this session. A skill that says not to wait for human approval
  (`iterate-pr`), or that offers a push/PR step when a branch is finished, does not override that:
  commit or push only when asked.
- **Worktrees.** The project's declared worktree convention — in its own `AGENTS.md` / `CLAUDE.md` —
  wins over a skill's `.worktrees/` default; if the project declares none, ask before creating one.
  Sessions may share the checkout, so `shared-state-between-agents.md` governs the branch, the index
  and the tree a skill touches.
- **Migrations.** `migration-apply-confirmation.md` wins over any skill, including one whose own
  steps list an apply, a rollback or a state migration as the next action.
- **Close-out.** When a plan exists, `/plan-finish` is the close-out. A skill's merge/PR menu is at
  most the integration step inside it, run with the user's explicit yes.

## On demand only

Six skills — all of them vendored — must not start on the model's own initiative: `iterate-pr`,
`playwright-cli`, `skill-scanner`, `differential-review`, `supply-chain-risk-auditor`,
`using-superpowers`. They commit and push, drive a real browser, or pre-approve unrestricted
`Bash` — and `using-superpowers` asks to be loaded at the start of every conversation.

**What gates them today is this rule and nothing else.** A host-side trigger override is the
intended mechanism but is configured nowhere yet, so all six still fire on their own descriptions;
`iterate-pr` even sets `disable-model-invocation: false`, opting itself in. Do not write or act as
if the gate were in place.

**Gating the trigger is not gating the grant.** Invoking one consents to its declared
`allowed-tools` for that invocation — unrestricted `Bash` for `skill-scanner`,
`differential-review` and `supply-chain-risk-auditor`; for `playwright-cli`, Playwright-scoped
`Bash` only (three prefixes — `playwright-cli`, `npx playwright` and `npx --no-install playwright`
— never `npx` at large).

## Vetting and editing

- **Never edit a vendored copy in place** — a fix goes upstream or into one of our own skills; the
  next re-pin silently reverts an in-place edit, so the work is lost rather than merged.
- **Never install a third-party skill twice** — a plugin or marketplace entry beside the vendored
  copy, or the reverse: two live copies at different versions is a skill nobody can reason about.
- **Read and scan every new source and every bump before it is linked.** The diff is the review.

## Ownership

This rule owns **how third-party skills interact with the rules here**. Siblings own the rest:

- `plans-live-in-a-plans-repo.md` — where a plan document lives and how it is published.
- `plan-progress-section.md` — the Summary and the Progress table a skill must keep current.
- `migration-apply-confirmation.md` — the apply/rollback stop this rule points a skill at.
- `shared-state-between-agents.md` — collisions when a skill's branch, worktree or PR is shared.
- `ui-rendered-files-use-write-tool.md` — which tool writes a file a skill tells you to edit.

The vendored catalogue — what each skill is, what it runs, and where each clause above lands — is
`vendor/README.md` in `bulkaeu/agents`. This rule owns the ordering; the catalogue owns the
inventory.

<!-- Canonical copy: bulkaeu/agents → rules/third-party-skills.md. install.sh links it to
     ~/.claude/rules/third-party-skills.md and ~/.cursor/rules/third-party-skills.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
