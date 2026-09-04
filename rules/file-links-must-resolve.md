# File links must resolve when clicked

Applies to every user-facing message that mentions a file, in Claude Code and Cursor alike.

A file reference is rendered as a clickable link. A link that opens **"Couldn't find this file"**
is worse than plain text: the reader stops, checks whether the file was deleted, and re-reads the
claim wondering whether the rest of the message is wrong too. Plain prose costs them nothing;
a dead link costs them a detour and some trust.

## The rule

- **Link paths resolve from the project root the UI is showing — not the shell's working
  directory.** The two are the same only when the session was opened at the repository itself.
  When the session root is a **parent workspace** holding several checkouts, a path that is correct
  for `cd`, `git` and every Bash tool is still a dead link, because the viewer resolves it one level
  up.

  ```text
  session root:  ~/work/workspace          ← what the UI badge names
  shell cwd:     ~/work/workspace/api

  ❌ [scores.ts](src/commands/scores.ts)       → "Couldn't find this file"
  ✅ [scores.ts](api/src/commands/scores.ts)   → opens
  ```

- **Find the root before the first link of a session, not after a complaint.** The cheapest
  tells, in order:
  - the **project badge in the UI header** — it names the root directory;
  - the session/memory project key (`-Users-me-work-workspace` → `~/work/workspace`);
  - `git rev-parse --show-toplevel` compared against the working directory. If the toplevel is
    *below* the session root, every link needs the difference as a prefix.

- **When the root is genuinely unclear, do not guess a relative path.** Name the file in backticks
  as plain text (`` `src/commands/scores.ts` ``) and say where it is. Unlinked text always reads
  correctly; a guessed link is a coin flip the reader has to resolve.

- **Line anchors follow the same path** — `[scores.ts:386](api/src/commands/scores.ts:386)`. A
  wrong prefix breaks the anchor exactly as it breaks the file.

- **Never link a path you have not seen in this session** — from a tool result, a listing, or your
  own write. Do not link a file you deleted, renamed, or only intend to create; describe it in
  prose instead. Line numbers drift too: a number read before your own edits may no longer point
  at the thing being discussed.

- **One dead link means stop and fix the batch.** They are almost never singular — the same wrong
  prefix is usually in every link of the message. Re-state the corrected ones rather than leaving
  the reader to click each and find out.

## Not covered by this rule

- **Pull requests and issues** are full URLs, with the owner and repo taken from the remote —
  never a bare `#123`, and never a default repository assumed.
- **Which tool writes a file** is `ui-rendered-files-use-write-tool.md`.

## Per-project concretes

A project whose layout makes this trap likely — a workspace directory holding several checkouts —
should record its own prefix in its `AGENTS.md` / `CLAUDE.md`, so no session has to rediscover it.
This rule owns the principle; the project owns its path.
