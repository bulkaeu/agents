---
description: Plan steps must be atomic; keep todos (Cursor) and Progress rows (Claude) in sync with the body
alwaysApply: true
---

# Plan steps — atomic and kept in sync

Applies whenever creating, editing, or iterating on Cursor/Claude plans (`~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`, `~/.claude/plans/*`, etc.).

## Atomic todos

- Each atomic step is **one** completable action (one verb, one clear done-state). The step lives
  in **frontmatter todos** in Cursor and in the **`## Progress` table** in Claude (see
  `plan-progress-section.md`); the same granularity rule governs both.
- **Do NOT** pack multiple steps into one todo (no “do A; then B; also C”).
- Prefer splitting prep / implement / docs / blocked-apply / verify into separate todos.
- Use `BLOCKED — wait for user confirmation: …` as its own todo when apply/cutover needs an explicit yes.

```text
❌ BAD: Export template; backup keys; write AL2023 template; update docs
✅ GOOD: export-pre-al2023-template | backup-authorized-keys | write-al2023-template | write-bastion-runbook | …
```

## Update steps when building the plan

- When **creating** a plan (CreatePlan or first draft), write atomic steps — frontmatter todos in
  Cursor, Progress rows in Claude — that match the body.
- When **iterating** the plan (scope change, review fixes, new phases), **edit those steps in the
  same change** — add/split/rename/remove so they stay aligned with the body.
- Do **not** leave stale bundled steps after the plan body was refined.
- Do **not** re-run CreatePlan only to refresh todos (see no-plan-copies); edit the existing plan file.

<!-- Canonical copy: bulkaeu/agents → rules/plan-atomic-todos.md. install.sh links it to
     ~/.claude/rules/plan-atomic-todos.md and ~/.cursor/rules/plan-atomic-todos.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
