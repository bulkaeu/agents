# tests — RED GATE

    freedom: LOW — follow this sequence exactly; do not reorder or paraphrase
    reads:   {profile_path} · {staff_dir}/units/{unit_id}.md · {source_root}
    writes:  new spec files under {worktree}

Staff document: **the profile** (and `{staff_dir}/PLAYBOOK.md` if present). If the profile sets
`skills.tdd`, read it too.

You write **new** specs of the source behavior. You do **not** implement production code.

## Sequence

1. Read the mapping. **Every mapping row gets a spec.**
2. Place specs at the seams the profile's `## Gold examples` demonstrates.
3. Take expected values from the **source**: literals, branches, errors. Public seams only. No
   tautological expects.
4. Run **only the new spec paths** — `commands.test` with `{paths}` replaced by exactly those paths.
5. Assert they are **red** (failing assertions or missing symbols). Report the actual output.

## Rules this stage enforces

- Do not modify existing spec files.
- Do not run the full suite at this gate.
- Red must be **verified before** the port stage starts. An unverified red gate voids the whole
  guarantee that follows.

## Done when

- Every mapping row has a spec file.
- Those files are red, and you have shown the output proving it.
- Existing spec files are unchanged; no production code was added.
