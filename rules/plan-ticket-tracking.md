---
description: When writing a plan, ask whether it should be tracked in Linear/Jira and in which project — one ticket by default, split only with approval
alwaysApply: true
---

# Plans ask about ticket tracking

Applies in **Cursor** and **Claude Code** whenever a plan is being written — `~/.claude/plans/*.md`,
`~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`.

Plans and tickets drift apart when filing is a separate act that happens after the thinking. This
rule makes it part of writing the plan.

## The rule

- **Ask, on every plan.** One question, two parts: *should this work be tracked in the issue tracker,
  and in which project?* Ask even when the project configures no tracker — one can exist outside
  `.mcp.json`.
- **Pre-fill, never skip.** Read the project's `.mcp.json` and any memory naming a filing destination,
  and offer the likely answer. That shortens the question; it does not replace it.
- **Ask once per plan, not once per turn**, and record the answer (below). Re-asking on every
  iteration is the nagging this rule must not become.
- **One ticket by default.** A plan maps to one ticket. This rule files one ticket for one plan — it
  is *not* the tool for slicing work into many dependency-linked tickets. If that is what is wanted,
  say so and use a skill built for it.
- **A split needs explicit approval.** When a plan carries items that are not one coherent feature,
  *propose* a split — numbered, one line each, saying what makes them separable. Then:
  - **approved** → create that many tickets and record every identifier;
  - **declined, or no clear answer** → exactly one ticket. **Silence is not consent to split.**

  Never split unilaterally, and never re-merge a split the user approved.
- **Update before create.** If a ticket already covers this work, update it. A second ticket for the
  same feature splits the history the user tracks against, which is worse than having none.
- **File once the answer is yes** — while the plan is being written, not after it is approved. The
  user naming the project is the authorization to file.
- **The ticket's description is the plan's `## Summary`** (plus a pointer to the plan file) — not
  words improvised at filing time. The Summary was written in plain language for exactly the reader
  a ticket has; one text, two homes, no second story. If the Summary changes materially while the
  ticket is open, update the description to match — **gate-free only for a ticket this plan filed**:
  that description is your own text. A ticket *adopted* via update-before-create carries someone
  else's words — there, propose the new description and get a yes before replacing it, the same
  courtesy as any destructive edit. (`plan-progress-section.md` owns the Summary section itself;
  `/plan-finish` audits the two for drift.)

## Record the answer under the H1

One line, directly under the H1 and above `## Progress`:

| Answer | The line |
| --- | --- |
| Yes, filed | `**Ticket:** ABC-123 — <title> · <tracker> / <project>` |
| Yes, filing blocked | `**Ticket:** pending — <why>` plus a `⛔` row in `## Progress` |
| No | `**Ticket:** none — not tracked (asked <date>)` |

**The "no" line is not optional.** Without it the next session finds no field, treats the question as
unasked, and asks again. Tickets from an approved split all list on the one line.

## Once a ticket exists

- **Every commit for that plan starts with the identifier** — `ABC-123: <what changed>`. No ticket
  means no prefix; this rule never invents one.
- **Never invent or guess an identifier.** Resolve it through the tracker and use what comes back. A
  wrong id silently attaches work to someone else's ticket.
- **Confirm the destination before filing.** A tracker tool answering is not proof it points at the
  right workspace — check it against the project's configured destination, or ask.
- **Never accept a pasted API key or token.** It would persist in the transcript. Authorization is
  the tracker MCP's own OAuth flow, run by the user.
- **Creating is authorised; destructive edits are not.** Never close, delete, or reassign an issue
  without asking.
- **If a plan is abandoned after its ticket was filed, say so and ask.** An orphan ticket is the known
  cost of filing before approval, and what to do about it is the user's call — not a tidy-up.

## Ownership

This rule owns **whether a plan is tracked and how the answer is recorded**. Siblings own the rest:

- `plan-progress-section.md` — the Progress table and the `## Summary` section this rule copies
  into tickets, including where the `**Ticket:**` line sits.
- `plan-atomic-todos.md` — how finely a step is cut.
- `no-plan-copies.md` — one topic, one plan file.

`/plan-summary` reports the `**Ticket:**` line; `/plan-finish` checks the ticket's state still matches
the plan's, and proposes rather than performs any change to it.

<!-- Established 2026-08-31. Canonical copy: bulkaeu/agents → rules/plan-ticket-tracking.md.
     install.sh links it to ~/.claude/rules/plan-ticket-tracking.md and
     ~/.cursor/rules/plan-ticket-tracking.mdc. Edit the repo copy, never a symlink. This file is
     published: it names no workspace, project, host or real ticket id — those live in .mcp.json and
     memory. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
