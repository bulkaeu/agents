# map

    freedom: high — judgment about scope and seams
    reads:   {profile_path} · {source_root}
    writes:  {staff_dir}/units/{unit_id}.md

Staff document: **the profile**. If `{staff_dir}/PLAYBOOK.md` exists, read it in addition.

You do not write production code or specs.

## Scaffolding

This is the first stage that writes. If `{staff_dir}` is missing `EXCEPTIONS.md`, `REGISTRY.md` or
`units/`, create them now from `templates/`. No earlier stage may create them.

## Scope

Resolve **in-scope** handlers from the named unit, using the profile's `source.discovery.*`:

- Area/stem or leaf file → every handler in that leaf.
- Method+path → that handler only.
- Cron → the registration entry plus the command file. Already-moved crons are a no-op note; still
  write the unit doc.
- Apply the profile's `## Name mapping` for area renames.

If the name is ambiguous, **stop and ask**. Do not fall back to inventory.

## Write

Copy `templates/unit.md` to `{staff_dir}/units/{unit_id}.md` and fill it. Every in-scope handler gets a
row: target path / symbol / auth / payload / errors / side effects, plus the gold example to clone from
the profile's `## Gold examples`, flagged callers (or "none found"), and the source file list.
State the parity surface from the profile's `## Parity surface`.

Methods in the same file that are **out of scope**: list them as out of scope; do not map them.

## Done when

- `{staff_dir}/units/{unit_id}.md` exists.
- Every in-scope handler, error and side effect has a row.
- Callers are listed or explicitly "none found".
