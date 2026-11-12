# Close-out

Read by `/plan-build` when the last row closes, starting or resuming — not before. It holds the final
review, close-out, the single question and the report; the loop that leads here is
[EXECUTION.md](EXECUTION.md). A run that ends at a hand-off row reads none of it. Read
[RULES.md](RULES.md) first — this file assumes it, and the rule numbers it cites are that file's.

## Contents

- The final review, then close-out
- Order, stated once
- The report

## The final review, then close-out

**Final review** — after the last row, per `DISPATCH.md`: one reviewer on the whole run's diff, one
fix wave, one re-review, the verdict in the Run log. It runs even when every row was inline, if the
run changed any file in the plan's repositories.

**Close-out** applies `plan-finish` inline. This skill cannot invoke `/plan-finish`: it sets
`disable-model-invocation: true`, which hides it from the model entirely. So:

1. Read `plan-finish/SKILL.md`, `plan-finish/CHECKLIST.md` and `plan-finish/CLEANUP.md` from the
   sibling skill directory — `${CLAUDE_SKILL_DIR}/../plan-finish/`, or the same relative path on a host
   that does not set that variable.
2. Apply them **verbatim** — the audit, the fix-by-default posture, the per-ecosystem command tables.
3. **Name the file you applied** in the report, so a reader can tell an applied checklist from a
   remembered one.
4. If the sibling is missing, do not improvise a close-out: print *run `/plan-finish`* and end.

`plan-finish`'s own stop-list governs this stage, and `RULES.md` rule 3 applies here as everywhere.
**Outside a git repository**, the commit and cleanup areas report *no repo* rather than being
skipped silently. **Cleanup deletes scratch, never deliverables**: a file a row exists to create is
the plan's output and stays; scratch is what the run made incidentally. In the run directory, the
records stay, `scratch/` goes, uncited media is asked about.

## Order, stated once

```
execute → park what must be parked → final review → fix wave → close out
       → one question covering the parked set → report, ending with "Rulings I made", then the stats line
       → on yes: run the rows that yes releases, then review and close out again
       → on no: they stay blocked
```

`plan-finish`'s own *"not done — N items"* ask is **folded into that one question**. Rows parked by a
no to the `needs: screen` ask (`EXECUTION.md`) are listed in the report, not asked again. A run that
ends at a hand-off row does none of this; the resuming run does it at the true end.

**A plan over 400 KiB at close-out moves its closed history out** as `plan-add/SKILL.md` step 7 says —
the app stops rendering a plan near 512 KiB. The move comes after the fix wave and just before
`plan-finish`'s audit begins, so the audit commits `<plan stem>-history.md` with the plan file as the
run's own path, never as an unclaimed dirty file.

## The report

Scale it to what happened. A clean run is its one-line summary plus the stats line:

```
done · 12/12 · 5 rows reviewed, final review PASS · checks green · committed a1b2c3d
Run: 2h 14m · helpers 11 (standard 9 · strong 2 · strongest 0) · first-pass reviews 4/5
```

When rows parked, they are the news — lead with them, name the blocker, and give the exact command
so a yes is one word. When a check could not run, say which and why (rule 7). Then **Rulings I
made**, one line each in the Run log's format — decisions taken on the user's behalf are theirs to
see, even when every one of them was right.

**Every report ends with one stats line**, so the user sees what the run cost without asking — one
line in the report, wrapped here only to fit this file:

```
Run: <wall time> · helpers <n> (standard <a> · strong <b> · strongest <c>)
  · first-pass reviews <passed>/<reviewed>
```

Compute it from the Run log and the saved reviews, not from memory. The wall time runs from the start
time in this run's Run log header to now. Helpers counts every subagent the run dispatched —
implementers, reviewers, fix rounds, the final review and its fix — by the tier each ran on, from the
Run log's per-row model lines and step-up lines. First-pass reviews is, over the rows this run
dispatched, how many have a `rows/<row id>/review-1.md` ending `Verdict: PASS`, out of how many were
reviewed. A resumed run reports its own figures and, where earlier run headers exist in the Run log
or in `<plan stem>-history.md`, adds the plan's total on the same line.

An example table, icons omitted so this file never reads as live work:

```markdown
| # | Step | Notes |
| - | ---- | ----- |
| 1 | `add-index` — index on the events table | 2.1 M rows, 41 s · review: `rows/<row id>/review-<n>.md` PASS |
| 2 | `deploy-staging` — ship the image | BLOCKED: deploy, rule 3 |
```
