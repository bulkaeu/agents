# Host capabilities

**As of 2026-08-30.** These are version-specific facts that will age. Re-date this file when you verify
a change; `SKILL.md` deliberately contains no version claims.

## Where this skill is read from

| Host | Global skill paths | Reads `~/.agents/skills/`? |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | **No** — needs the adapter symlink |
| Cursor 2.4+ | `~/.cursor/skills/`, `~/.agents/skills/` | Yes (also legacy-scans `~/.claude/skills/`) |
| Codex CLI | `.codex/skills/`, `.agents/skills/` | Yes — `.agents/` is its primary path |
| Gemini CLI | `.gemini/skills/`, `.agents/skills/` | Yes, with precedence |

Canonical content lives in `~/.agents/skills/migrate/`. Claude Code is the only host needing an adapter:

    ~/.claude/skills/migrate -> ../../.agents/skills/migrate

**If Cursor does not list `/migrate`:** escalate and record which step worked here.
(a) symlink `~/.cursor/skills/migrate` → `../../.agents/skills/migrate`;
(b) if still absent, `cp -R` the canonical directory there — and re-sync it after every edit, since a
copy does not track the canonical.

## Subagent dispatch

Dispatch stages as subagents where the host has them; otherwise run them sequentially in-thread. The
gates — red-before-port, green-before-compare, stop-on-fail — are what must hold, not the parallelism.
File-based handoff (`reads:` / `writes:` headers) makes the two paths equivalent.

## Run plan location

Use the host's own plan directory: `~/.claude/plans/` (Claude Code) or `~/.cursor/plans/` (Cursor).
If the host has neither, use `{staff_dir}/units/{unit_id}-run.md`.

One run plan per invocation, keyed by `{run_id}`, updated **in place**. Each invocation is its own
topic, so minting one file per run is correct; forking or re-minting *within* a run is not.
