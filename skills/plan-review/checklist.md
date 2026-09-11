# Plan Review Checklist

Use during Step 1 of [SKILL.md](SKILL.md), on every host: round 1's reviewer works through it
section by section (via [reviewer-prompt.md](reviewer-prompt.md)), and later rounds use it
in-thread. `/code-review` is only an optional extra pass, on any host whose session offers it. Skip
sections that are out of scope for the plan under review.

## Correctness and assumptions

- [ ] Stated facts match the codebase or docs cited in the plan
- [ ] Prerequisites exist or are called out as blockers
- [ ] Dependencies between steps are satisfiable (nothing needs B before A when A is scheduled first)
- [ ] Edge cases that would break the approach are addressed or explicitly deferred

## Sequencing and rollout

- [ ] Phases are ordered safely (dev/staging before prod where applicable)
- [ ] Cutover steps have a defined rollback or revert path
- [ ] Feature flags, dry-run, or canary steps exist before irreversible changes
- [ ] Parallel workstreams do not conflict on the same resource or deploy window

## Security and operations

- [ ] IAM / permissions changes are scoped least-privilege
- [ ] Secrets and credentials are not embedded in the plan as literal values
- [ ] Prod blast radius is bounded (what breaks if a step fails mid-way?)
- [ ] Monitoring, alerting, or smoke checks are specified after deploy steps

## Verification and tests

- [ ] Acceptance criteria or smoke tests are defined for major phases
- [ ] Test gaps are acknowledged when behavior changes are planned
- [ ] Manual verification steps name who runs them and what "pass" looks like

## Executability

For a plan an executor — `plan-build` or `plan-continue` — will run unattended. The markers and
terms are those of [CONVENTIONS.md](../plan-shared/CONVENTIONS.md) (*Row markers*, *Terms*); hold
the plan to that file, not to a paraphrase of it.

- [ ] **Markers** — every step that needs the user's action or yes carries the exact
      `BLOCKED — wait for user: …` marker, in either spelling *Row markers* accepts; so does every
      step that applies a migration, deploys, publishes, sends or deletes data. A `hand-off row`
      says what resumes the plan; a `(⏭️ if …)` names a condition someone can check; `review: deep`
      and `review: default` are used as *Row markers* defines them. A marker spelled any other way
      is not parsed
- [ ] **Done-states** — every row names an observable done-state (*Terms*): a file, a count, an
      exit code, a command's output — something an executor can check without asking. "Improve X"
      with no check is a finding
- [ ] **Failable Verification** — every `## Verification` item can fail, and names what failing
      looks like. A check that asserts something did *not* happen is tied to proof that the thing
      that would do it actually ran; without that proof it passes vacuously, before any run
- [ ] **Scope cuts** — anything the user asked for or decided, recorded in the plan or a document
      it cites, that the plan drops or narrows is named in the plan as out of scope, with its reason
      and a pointer to where the decision is recorded. No step quietly narrows a recorded decision

## Internal consistency

- [ ] Steps match the body — frontmatter todos in Cursor, `## Progress` rows in Claude Code (same
      phases, no orphan steps)
- [ ] House plan rules hold: a `## Summary` and a `## Progress` table exist, in that order right
      after the H1 (only a `**Ticket:**` line may precede them), rows atomic and current
      (`plan-progress-section.md`, `plan-atomic-todos.md`)
- [ ] The `## Summary` is plain language (no paths, commands, or jargon), sized to the plan
      (~30-line ceiling), and still true of the body — a body that outgrew its summary is drift.
      Absent only in plans predating the rule
- [ ] The `**Ticket:**` line records the tracking answer — filed id, `pending — <why>`, or
      `none — not tracked`; absent only in plans predating `plan-ticket-tracking.md`
- [ ] Naming conventions are consistent (jobs, resources, paths, env vars)
- [ ] Cross-references resolve (linked files, section anchors, phase numbers)
- [ ] No duplicated steps that contradict each other
- [ ] Out-of-scope items are not accidentally required by in-scope steps

## Documentation and handoff

- [ ] Operator runbooks or doc updates are included when behavior changes
- [ ] Open questions are listed or resolved — not left implicit
- [ ] "Done" for the plan is defined clearly enough to execute without guesswork
