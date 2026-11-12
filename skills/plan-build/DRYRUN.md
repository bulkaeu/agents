# `--dry-run` — rehearse, write nothing

Read by `/plan-build` at invocation when `--dry-run` is given, before [SKILL.md](SKILL.md) §1, and
only then. It changes how §1's stop and §2's offer report, and it ends the run with its report: §4
and §5 do not run. Rule numbers are `RULES.md`'s.

**Nothing is written, whichever shape applies.** Where §2 saves a `dirty-at-start` file, measures
`disk:` or opens a Run log header, a dry run does none of it: what pre-flight found goes in the report.

Pre-flight only on an unstarted plan; on a started one, reconcile-and-report in
[RESUME.md](RESUME.md)'s shape instead. An unstarted plan prints:

- the **verdict** — would run from row *N*, or refuses because … (a collision, with its paths);
- the ***will park*** list — open rows whose step text carries the explicit `BLOCKED` marker, printed on
  both verdicts including a refusal — and, before it, any author-parked `⛔` rows as *already
  parked*;
- the ***will defer*** list — rows carrying `needs: screen` (`EXECUTION.md`, *The loop*);
- the **dispatch count** — the rows `EXECUTION.md` would classify as dispatch, by id, and the
  subagent floor that implies (*Cost*, below), so the cost is known before anything starts,
  and the floor's count per model tier from `DISPATCH.md` §3 — each row's implementer and reviewer
  judged from its step text, markers included, and the final review's tier as the table predicts it;
- and **writes nothing**.

Rows that merely *depend* on a marked row are not listed: a dry run is a text scan, not a simulation.

State plainly, every time, that the other stop-list categories — deploys, migrations, sends, deletions,
judgement calls — are recognised at execution time from what a step actually does. **A clean
dry-run is not clearance.**

**A dry run makes no offers.** `SKILL.md` §2's offer to derive a table is absent here: accepting it
means executing, which a dry run cannot do. Report the refusal and stop.

*Cost.* A dispatched row costs at least 2 subagents, and up to 10 — one `NEEDS_CONTEXT` retry, three
fix rounds, one closing pass; the final review adds 1 to 3. Only code rows dispatch, each on
`DISPATCH.md` §3's tiers. The floor is 2 × dispatched rows + 1.

Report shape — follow it, so two runs on the same plan are comparable. A list with nothing in it
prints `none` after its label, one with several rows repeats its label, one line per row, and
`foreign dirty paths:` names every repo in scope with its count, zeros included:

```
/plan-build --dry-run · <plan file>
Verdict:  would run from row <n>   |   REFUSED — <why>
Pre-flight: table <pass/fail> · started no · concurrency <pass, or the colliding paths>
            · foreign dirty paths: <repo> <n>, … · scope <…>   (no repo: concurrency no repo, no count)
Tiers:    <tiers.sh's line, or its error>
Parked:   row <n> <step-id> — already parked by the author: <its Notes>
Will park: row <n> <step-id> — <the BLOCKED marker, quoted>
           (dependents are not listed; they park at execution under rule 2)
Will defer: row <n> <step-id> — needs: screen
Dispatch: <k> rows (<ids>) → at least <2k + 1> subagents · standard <a> · strong <b> · strongest <c>
A clean dry-run is not clearance. Nothing written.
```

When no plan resolves, the shape is fixed too, so runs from different directories compare:

```
/plan-build --dry-run · (no plan resolved)
Verdict:  REFUSED — plan not resolved, <N> candidates at rung <r>
<the candidate list, as CONVENTIONS.md shapes it>
A clean dry-run is not clearance. Nothing written.
```
