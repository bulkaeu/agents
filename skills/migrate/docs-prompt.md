# docs

    freedom: high — prose
    reads:   {profile_path} · {staff_dir}/units/{unit_id}.md
    writes:  the doc targets named in the profile

Two walks. Working-tree edits only — no `git add` unless the user asked.

**Do not write `{staff_dir}/REGISTRY.md`.** That is the orchestrator's, after merge-back.

The orchestrator tells you which walk (`A` or `B`).

## Walk A — source and target repos

Apply the profile's `## Docs walk A`. Typically: append a migration-table row in the source repo
recording that this surface now also exists in the target; mark moved commands; add the new command or
endpoint to the target repo's own docs. The source keeps serving — say so where status is recorded.

## Walk B — orchestrating workspace

Apply the profile's `## Docs walk B`. Edit **only** where a pointer is missing or stale. If nothing is
stale, write "no workspace-doc change" in the run plan rather than inventing an edit.

## Done when

Every in-scope surface has its walk-A row and matching target edit, or an explicit skip recorded in the
run plan; and walk B has either concrete edits or that skip note.
