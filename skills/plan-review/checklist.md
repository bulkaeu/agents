# Plan Review Checklist

Use during Step 1 of [SKILL.md](SKILL.md). In Cursor, use alongside `/code-review` on the plan; in Claude Code, use as the primary review checklist. Skip sections that are out of scope for the plan under review.

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

## Internal consistency

- [ ] Frontmatter todos match the body (same phases, no orphan todos)
- [ ] Naming conventions are consistent (jobs, resources, paths, env vars)
- [ ] Cross-references resolve (linked files, section anchors, phase numbers)
- [ ] No duplicated steps that contradict each other
- [ ] Out-of-scope items are not accidentally required by in-scope steps

## Documentation and handoff

- [ ] Operator runbooks or doc updates are included when behavior changes
- [ ] Open questions are listed or resolved — not left implicit
- [ ] "Done" for the plan is defined clearly enough to execute without guesswork
