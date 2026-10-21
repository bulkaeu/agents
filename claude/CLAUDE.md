# Global instructions

## Rule files

Standing rules also live in `~/.claude/rules/`, loaded automatically each session. **Every `.md` file
in that directory is part of these instructions** — the directory is the list, so nothing here needs
updating when one is added.

If those rules are not present in your context, read the directory before starting work.

## Finishing a plan

Choose checks from what the change affects, not from the number of steps or the presence of a
plan. Before reporting the work as complete:

- **Documentation, storyline, plan, ticket, or instruction-only changes:** check the changed text,
  source consistency, links and references, and any configured formatter/documentation checks.
  Do not run application builds, Godot/runtime tests, unrelated asset checks, or the full project
  suite solely because the edit has multiple steps or `/plan-finish` is being used.
- **Implementation changes affecting runtime behavior, executable data/assets, saves,
  dependencies or build/release configuration:** run the project's required full check suite.
  A Markdown/JSON file consumed as executable input is implementation, not a documentation-only
  exception. An explicit user request for additional checks still applies.

- Enumerate the project's **own** commands rather than assuming the usual four exist — check
  `package.json` scripts / the build config — and run every applicable required check for the
  scope above. Do not repeat an already passing check without a relevant subsequent change,
  failure, unresolved concern or explicit request.
- **A formatter check is its own step.** Passing lint does not cover it: `format:check` typically
  globs `.md`/`.json`, which ESLint never parses. Any change touching markdown or JSON needs it even
  when lint is green.
- If a check fails, fix it and re-run. If a check can't be run, say so explicitly. Report which
  checks you ran, by name — "all checks pass" is not a result, and a check you didn't run is not a
  check that passed.

Report deliberately inapplicable checks as **not applicable**, with the scope reason, rather than
as passed or blocked. Do not invent a missing formatter command or install tooling just for a
documentation edit; use available document/whitespace checks and state the limit.

The full procedure — check suite, commit state, docs drift, and cleanup of merged branches,
worktrees and temp files — is the **`/plan-finish`** skill. Its per-ecosystem command tables live in
`skills/plan-finish/CHECKLIST.md`.

## Plans

Every plan opens with a plain-language `## Summary` and a `## Progress` table of atomic steps;
`rules/plan-progress-section.md` owns both formats. `/plan-summary` renders the Summary in full plus
a technical twin and the recent + upcoming steps (windowed only when the table outgrows ten rows).

Writing a plan also means settling whether the work is tracked in an issue tracker and in which
project — filed straight to the one destination on record, asked only when that is ambiguous; one
ticket by default, split only with explicit approval.
`rules/plan-ticket-tracking.md` owns that, including the `**Ticket:**` line the answer is
recorded on.

New work for a plan that already exists goes in through `/plan-add`, never a second plan file
for the same topic: it writes the new rows where they will run, reopens the closed steps the
addition invalidates, and reviews the whole plan afterwards.
