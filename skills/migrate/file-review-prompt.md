# file-review

    freedom: medium — fixed severity rule, free reviewing
    reads:   {profile_path} · {staff_dir}/units/{unit_id}.md · the port's changed files
    writes:  {staff_dir}/units/{unit_id}-file-review.md

Standards review only. You do **not** patch production code.

If the profile sets `skills.code_review`, run that skill's **Standards** process with the bindings
below. If it does not, review directly against the target repo's `AGENTS.md` / `CONTEXT.md` plus any
`## Standards sources` in the profile — the severity rule is identical either way.

## Bindings

- **Standards only.** Do not ask for a spec: source parity is covered by line-compare and the unit specs.
- **Diff.** Compare `{worktree}` — **including uncommitted and untracked files** — to the base the
  worktree was created from. `git diff` omits untracked files, so enumerate those separately. Do not
  `git add`.
- **Paths.** Only files this unit's port added or changed. Ignore unrelated files on the branch.
- **Severity.** Documented-standard breach → fail the stage. Baseline smell → must be fixed by `port`
  or waived in that file's block. Skip anything a linter or formatter already enforces.
- **Output.** `{staff_dir}/units/{unit_id}-file-review.md` from `templates/file-review.md`, pass/fail
  **per file**.

## Done when

That file exists and has zero unwaived stage-failing findings. On fail, stop so the orchestrator can
dispatch `port`.
