---
description: Never create duplicate plan files unless the user explicitly asks
alwaysApply: true
---

# No plan copies unless explicitly asked

Applies whenever working with Cursor/Claude plans (`~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`, `~/.claude/plans/*`, etc.).

## Hard rule

- **Do NOT** create a second/copy/fork of an existing plan (new `*.plan.md`, CreatePlan re-run that yields a new hash filename, `cp` of a plan, “backup” plan, or parallel plan with the same topic).
- **Do** update the **existing** active plan file in place (edit frontmatter todos + body).
- **Only** create an additional plan file when the user **explicitly** asks for a copy, fork, duplicate, or a separate new plan (e.g. “make a copy of this plan”, “fork the plan”, “create a new plan file”).

## Why

CreatePlan and similar flows mint a **new** plan path (e.g. `…_c2cfffba.plan.md` then `…_d4acb11c.plan.md`). That orphans todos and splits review history. One topic → one plan file.

## Examples

```text
❌ BAD: Re-running CreatePlan to “refresh todos” → second plan file
❌ BAD: cp ~/.cursor/plans/foo_abc.plan.md ~/.cursor/plans/foo_backup.plan.md
✅ GOOD: Edit ~/.cursor/plans/foo_abc.plan.md directly
✅ GOOD: User says “make a copy of this plan” → then a second file is allowed
```

If a duplicate already exists, consolidate into the canonical plan the user names (or the older/original path) and remove the extra file — unless they asked to keep both.

<!-- Canonical copy: bulkaeu/agents → rules/no-plan-copies.md. install.sh links it to
     ~/.claude/rules/no-plan-copies.md and ~/.cursor/rules/no-plan-copies.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
