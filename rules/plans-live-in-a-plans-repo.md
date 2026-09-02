---
description: Plan documents live in a dedicated private plans repo, one directory per project — never in a public repo, never only on disk
alwaysApply: true
---

# Plans live in a dedicated private plans repo

Applies whenever a plan document, execution runbook, design note or spike artifact is created,
moved, or asked about — in any project.

A plan that exists only on a laptop has no history: nobody can see what a decision used to say, an
edit has no undo beyond a hand-made copy, and the reasoning behind a reversal is gone the moment it
is overwritten. These documents outlive the work they describe, so they get a real home.

## The rule

- **One dedicated repository holds every project's plans**, one directory per project:

  ```text
  plans/                    the repo
    <project-a>/            that project's stage plans, runbooks, artifacts
    <project-b>/
    archive/                pre-version-control snapshots, if any
  ```

- **That repository is PRIVATE, and stays private.** See *Why private* below — this is the part
  that must never be relaxed for convenience.
- **Never commit plans to a public repository**, including a shared agent-config repo. Check
  visibility before proposing a destination, not after pushing:

  ```bash
  gh repo view <owner>/<repo> --json visibility -q .visibility
  ```

- **Never leave a plan as the only copy in a scratch directory.** Session scratchpads are erased.
  If a snapshot is worth keeping, it belongs in the repo's `archive/`.
- **The working copy stays where the paths point.** Docs, tickets and agent config reference plan
  files by their existing path; moving them under a per-project prefix locally breaks all of it.
  The prefix exists **only on the remote**, so the two differ by design.
- **Publish with `git subtree`, not a copy.** A flat copy discards the history that motivated
  having a repo at all.

  ```bash
  git -C <clone> subtree pull --prefix=<project> <working-copy> <branch> -m "Sync <project> plans"
  git -C <clone> push
  ```

  Record those two commands at the top of the project's plan `README.md`, with the clone's path, so
  the next session does not have to rediscover them.

## Why private

Plan documents accumulate exactly the material that should not be public, and it arrives gradually
enough that nobody notices the threshold being crossed:

- infrastructure identifiers — account ids, instance/subnet/security-group ids, static IPs
- secret *locations* — parameter-store paths, which host holds which credential file, rotation state
- account identifiers, tracker ids, absolute home paths
- security findings, and which of them are still unfixed

**No single value is a secret. Together they map a live system.** The concrete case this rule came
from: a plan set recorded a production host's static IP next to a finding that the upstream service
trusts that IP for logins, next to the account identifier, next to where the credentials live.

## Before proposing any destination

1. **Check visibility.** Public is disqualifying, full stop.
2. **Run the target's own guard, if it has one.** A repo with a sanitization script has it for a
   reason — run it rather than assuming the content will pass. In the case that produced this rule,
   the public repo's own scanner rejected the plans with **149 hits across 11 files**, and its term
   list named the project outright.
3. **Say what is being published.** Name the categories above that apply, so the choice is informed.

**A refusal here is not obstruction.** Offer the private alternative in the same breath, and get on
with it.

## Per-project documentation

Every project repo names its concrete destination in `AGENTS.md` — repo, directory, sync commands.
This rule owns the *policy*; the project owns the *address*, because only the project repo is
private enough to hold it.

## Ownership

This rule owns **where plan documents live and how they are published**. Siblings own the rest:

- `no-plan-copies.md` — one topic, one plan file.
- `plan-progress-section.md` — the Progress table.
- `plan-ticket-tracking.md` — whether a plan is tracked, and its `**Ticket:**` line.
- `plan-mode-edit-plans.md` — that editing a plan needs no permission.
- `ui-rendered-files-use-write-tool.md` — which tool writes the file.
