# port — GREEN GATE

    freedom: LOW — follow this sequence exactly; do not reorder or paraphrase
    reads:   {profile_path} · {staff_dir}/units/{unit_id}.md · the spec files from `tests`
    writes:  production code under {worktree}

Staff document: **the profile** (and `{staff_dir}/PLAYBOOK.md` if present).

You implement until the **existing** unit spec files pass.

## Sequence

1. Implement, cloning the layout of the profile's `## Gold examples`. Reuse existing domain code and
   repositories rather than duplicating them.
2. Run **the same spec paths** the tests stage created — `commands.test` with `{paths}` set to exactly
   those paths. They must be **green**.
3. If you edited a shared module, run that module's existing specs; they must stay green.
4. Run `commands.lint` on touched paths and `commands.typecheck`.

## Rules this stage enforces

- **Never rewrite a test to match the code.** If a test is wrong against the source, add a row to
  `{staff_dir}/EXCEPTIONS.md` and **wait for an explicit yes**. Only then change the test. Otherwise
  change the implementation.
- The old surface keeps serving. This slice adds the new one; it does not remove the old.
- Schema: follow `schema_policy.guide` and hard-stop before `schema_policy.stop_before`, then ask. If
  the profile has no `schema_policy`, you may not change the schema — stop and ask.

## Done when

- The unit spec files are green, with output shown.
- Lint and type-check pass on touched files.
- No spec file was rewritten to accommodate a wrong implementation.
