---
description: Edit files the UI renders (plans, artifacts) with Write/Edit — never Bash
alwaysApply: true
---

# Editing files the UI renders — use Write/Edit, never Bash

## The rule

- **Use `Write` / `Edit`** for files the UI displays back to the user:
  - the session plan file — `~/.claude/plans/*.md`, `~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`
  - any file about to be published as an Artifact
  - any file the user says they are looking at, or that a tool result shows rendered
  - **if unsure whether a file is one of these, treat it as one**
- **Never Bash-modify them** — no `sed -i`, no `cat > file <<'EOF'`, no `>` / `>>`, no `mv` over one.
  The bytes land but the UI keeps rendering the older version.
- Bash stays right for **inspection** (`cat`, `grep`, `wc`, `ls`, `find`) and for editing ordinary
  files the UI does not render. This does not retire Bash file work generally.
- **Bulk edits:** one `Edit` per file. No Bash shortcut exists — a `sed` pass still needs a `Read` +
  `Write` per file afterwards, which is *more* work than editing each once.
- This is the standing exception when a session's "auto mode" asks for file work through Bash.

## When a panel looks stale

1. **Are you editing the file the panel is actually showing?** The harness can re-designate the plan
   file mid-session while the panel still renders the previous one. Compare the panel's visible content
   against the candidates on disk. This check is the one most often skipped.
2. **Re-apply the change with `Write`** (`Read` first if required). This is *the* fix, confirmed
   working — not just worth a try.
3. **If it still shows old content, stop.** Say so plainly and route the user another way: post links
   in chat (working-directory-relative paths resolve correctly there), or point at the directory.

**Early tells:** a `<system-reminder>` saying "changed on disk since you last read it" right after your
own Bash write (that notice normally reports *external* edits); or `cat` showing correct content while
the UI disagrees. Trust the UI about what the user sees.

## Don't delete files a stale panel references

A stale panel still links to the filenames it captured; deleting them turns a display problem into a
broken one. Rewrite the referencing document through a tracked tool first.

The remedy above is proven. The *mechanism* — that the UI snapshots at the last tracked write — is
inferred; follow fresh evidence over it if they ever disagree.

<!-- Established 2026-08-30. Canonical copy: bulkaeu/agents → rules/ui-rendered-files-use-write-tool.md. install.sh links it to
     ~/.claude/rules/ui-rendered-files-use-write-tool.md and ~/.cursor/rules/ui-rendered-files-use-write-tool.mdc. Edit the repo copy,
     never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor.
     Sibling: plan-mode-edit-plans.md says *edit*; this says *with which tool*, and owns
     "never Bash around a denied edit". -->
