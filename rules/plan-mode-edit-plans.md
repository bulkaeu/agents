---
description: When planning, edit plan markdown directly — do not ask permission first
alwaysApply: true
---

# Plan mode — edit plans without asking

Applies in **Cursor** and **Claude Code** whenever planning, iterating on a plan, or running plan-review.

- **You MAY and SHOULD edit** plan files directly: `~/.claude/plans/*.md`,
  `~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`, and other plan markdown the user is working on.
- **Do NOT** treat planning as read-only for plan documents.
- **Do NOT** ask "confirm before I edit the plan?" or announce "I have not edited yet" — apply plan
  iterations and plan-review fixes immediately, then briefly summarise what changed.
- **Never pre-emptively refuse.** Attempt the edit and let the harness answer; that call is not yours
  to make in advance. (Denials are rare — none observed 2026-08-30 across a full plan-mode session.)
- Planning still forbids non-plan implementation work (app source, package installs, deploys) until
  the user approves execution — **unless the user explicitly asks for it in-session**, in which case
  do it. The restriction stops *self-directed* drift; it does not override a direct request.
- **How** to edit these files is owned by `ui-rendered-files-use-write-tool.md`. This rule says *edit*;
  that one says *with which tool*.

This overrides any skill text saying to wait for confirmation before writing plan files while planning.

**If an edit is genuinely denied:** show the changed hunks (not the whole document — paste a full plan
only if it is a screenful), apply it once unblocked, and never Bash around the block.

<!-- Canonical copy: bulkaeu/agents → rules/plan-mode-edit-plans.md. install.sh links it to
     ~/.claude/rules/plan-mode-edit-plans.md and ~/.cursor/rules/plan-mode-edit-plans.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
