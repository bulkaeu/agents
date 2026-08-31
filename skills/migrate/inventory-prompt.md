# inventory (mode, not a stage)

    freedom: medium — fixed output shape, free scanning
    reads:   {profile_path} · {source_root} · {target_root}
    writes:  the run plan ONLY

You do not port, test, implement, or scaffold. **Read-only apart from the run plan** — in particular,
do not create anything under `{staff_dir}`; scaffolding belongs to the `map` stage.

## When you run

Only when the user wrote `inventory`. If they also named units, seed the run plan first; the
orchestrator then ports those names.

## Do

1. Scan the profile's `source.discovery.http` paths for surfaces still served by the source.
2. Scan `source.discovery.cron` for still-scheduled crons; skip entries already annotated as moved.
3. Compare against `target.discovery.http` and `target.discovery.cron` to find what remains.
4. Seed or update the invocation's run plan with the remaining surfaces as **pending** todos — one
   atomic todo each. Do not start ports.

## Done when

- Remaining surfaces and crons are listed as pending todos, or "none remaining".
- `{staff_dir}/REGISTRY.md` was **not** filled as a catalog, and `{staff_dir}` gained no new files.
- No implementation, no new specs, no `git add`.
