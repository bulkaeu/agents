# Global instructions

## Rule files

Standing rules also live in `~/.claude/rules/`, loaded automatically each session. **Every `.md` file
in that directory is part of these instructions** — the directory is the list, so nothing here needs
updating when one is added.

If those rules are not present in your context, read the directory before starting work.

## Finishing a plan

When you finish implementing a plan (or any multi-step change), run the project's **full check
suite** before reporting the work as complete, and report the actual results:

- Enumerate the project's **own** commands rather than assuming the usual four exist — check
  `package.json` scripts / the build config — and run every check CI runs.
- **A formatter check is its own step.** Passing lint does not cover it: `format:check` typically
  globs `.md`/`.json`, which ESLint never parses. Any change touching markdown or JSON needs it even
  when lint is green.
- If a check fails, fix it and re-run. If a check can't be run, say so explicitly. Report which
  checks you ran, by name — "all checks pass" is not a result, and a check you didn't run is not a
  check that passed.

The full procedure — check suite, commit state, docs drift, and cleanup of merged branches,
worktrees and temp files — is the **`/plan-finish`** skill. Its per-ecosystem command tables live in
`skills/plan-finish/CHECKLIST.md`.

## Plans

Every plan opens with a plain-language `## Summary` and a `## Progress` table of atomic steps;
`rules/plan-progress-section.md` owns both formats. `/plan-summary` renders the Summary in full plus
a technical twin and the last/next 5 steps.

Writing a plan also means asking whether the work should be tracked in an issue tracker and in
which project — one ticket by default, split only with explicit approval.
`rules/plan-ticket-tracking.md` owns that, including the `**Ticket:**` line the answer is
recorded on.
