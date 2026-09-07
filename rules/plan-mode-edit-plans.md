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
  to make in advance. (Outright denials are rare — none observed 2026-08-30 across a full plan-mode
  session. *Prompts* are not rare at all; see below.)
- Planning still forbids non-plan implementation work (app source, package installs, deploys) until
  the user approves execution — **unless the user explicitly asks for it in-session**, in which case
  do it. The restriction stops *self-directed* drift; it does not override a direct request.
- **How** to edit these files is owned by `ui-rendered-files-use-write-tool.md`. This rule says *edit*;
  that one says *with which tool*.

This overrides any skill text saying to wait for confirmation before writing plan files while planning.

**If an edit is genuinely denied:** show the changed hunks (not the whole document — paste a full plan
only if it is a screenful), apply it once unblocked, and never Bash around the block.

## When the harness asks anyway

Everything above is about *your* conduct. None of it changes what the harness permits, and in plan
mode the harness permits exactly one file for free: the session plan file it designated itself. A
plan kept anywhere else — in the dedicated plans repository that `plans-live-in-a-plans-repo.md`
*requires* — is an ordinary path, and every write to it is gated. The two rules pull in opposite
directions by construction, and the harness wins. That is not a defect in either rule; it is the
seam between instructions and permissions.

- **The prompt is the harness answering, not you choosing to ask.** Never narrate it as caution, as
  policy, or as a judgement you made — that misreports what happened, and invites the user to correct
  behaviour that was never yours. Name the file that was gated and say why the harness treats it as
  ordinary.
- **Instructions are not permissions.** No rule file grants tool access, this one included. The only
  lever is a path-scoped `Edit`/`Write` allow entry in the user's own settings, which covers one
  agent's harness rather than both. A project records its concrete paths in its own private
  instructions; this rule stays generic because it is published.
- **Batch rather than abandon.** Prefer one `Edit` per file per turn over six small ones, so the user
  approves once instead of six times. Work through the prompts; do not quietly shrink the plan to fit
  what happens to be free.
- **Never route around the block.** Not through the shell, and not by relocating plan content into
  the auto-permitted session file — that splits one plan across two documents and breaks
  `no-plan-copies.md`.

<!-- Canonical copy: bulkaeu/agents → rules/plan-mode-edit-plans.md. install.sh links it to
     ~/.claude/rules/plan-mode-edit-plans.md and ~/.cursor/rules/plan-mode-edit-plans.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
