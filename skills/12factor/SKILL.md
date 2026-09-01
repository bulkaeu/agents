---
name: 12factor
description: >-
  Audit the current project against the Twelve-Factor App methodology
  (12factor.net): grade each of the twelve factors, cite file-level evidence
  for every violation, and report findings with concrete fixes in chat. Use
  when the user invokes /12factor or asks for a twelve-factor audit, review,
  or report on a project's cloud-readiness.
disable-model-invocation: true
argument-hint: "[optional project path]"
---

# Twelve-Factor audit

An audit is only as good as its evidence. A grade nobody can trace to a file is an opinion;
this skill produces findings someone can act on the same afternoon.

## Hard rules

- **Read-only.** Audit and report. Never fix anything unless the user asks afterwards.
- **Evidence or nothing.** Every ❌/⚠️ cites concrete evidence — `file:line`, or an explicit
  absence ("absent: no lockfile in repo root"). No evidence → no grade below ✅.
- **Never quote secrets.** When a credential is found in the code, cite its location and
  variable name only. The report lands in chat and transcripts; reproducing the value there
  turns a finding into a second leak.
- **➖ is an honest grade.** A factor that doesn't apply (Port binding for a CLI tool) gets
  ➖ N/A with the reason — never a guessed pass or fail. Exclude ➖ from the score denominator.
- **Report goes to chat only.** Write no report file into the audited project.

## Procedure

### 1. Resolve target and detect the stack

Target = the argument path if given, else the current working directory. In one pass, read the
signals that every factor check depends on:

- Manifests: `package.json`, `pyproject.toml`, `requirements*.txt`, `go.mod`, `Gemfile`,
  `Cargo.toml`, `pom.xml`, `build.gradle`, `composer.json`
- Lockfiles, `Dockerfile*`, `docker-compose*.yml`, `Procfile`, CI configs (`.github/workflows/`,
  `.gitlab-ci.yml`, …), k8s/terraform dirs, `.env*` files, top-level directory layout

Write a short **stack summary** (language, framework, how it's built, deployed, and configured,
notable absences). Every factor check receives this summary — it exists so no check re-derives
the basics.

### 2. Choose the audit mode

| Mode | When | How |
| --- | --- | --- |
| **Grouped fan-out** (default) | A subagent/Task tool is available and the project is non-trivial | 4 read-only agents in parallel, one per group below |
| **Per-factor fan-out** | Large repo (monorepo, many services) or the user asks for a thorough audit | Up to 12 agents, one factor each |
| **Inline** | No subagent tool (e.g. Cursor), a small project (~one service, few hundred files), or the user wants a quick/cheap audit | One pass through all factors in [FACTORS.md](FACTORS.md) order |

Measured on a real NestJS microservice: fan-out cost ~2.6× the tokens of inline at similar
wall-clock, but produced materially deeper evidence (it followed deploy scripts into a sibling
repo) and stricter grades. Fan-out is worth it when the verdict matters; inline when speed of
answer does.

Groups are cut so each shares its evidence files:

| Group | Factors |
| --- | --- |
| A — repo & build hygiene | I Codebase · II Dependencies · V Build/release/run |
| B — environment & config | III Config · IV Backing services · X Dev/prod parity |
| C — process model | VI Processes · VIII Concurrency · IX Disposability |
| D — interfaces & ops | VII Port binding · XI Logs · XII Admin processes |

### 3. Run the checks

Each agent's prompt (or each inline pass) gets: the stack summary, its factors' sections from
[FACTORS.md](FACTORS.md) — pasted, or (when the agent can read files) the FACTORS.md path plus
the exact section names to read — the target path, and this required return shape per factor:

```text
factor: <roman numeral + name>
grade: ✅ | ⚠️ | ❌ | ➖
evidence: <file:line, or "absent: …", or reason for ➖>
why: <one line — why this matters for this project>
fix: <one concrete step>
```

Agents are read-only (searches and file reads; no writes, no installs, no network).

### 4. Merge and grade

Collect all twelve results. Resolve contradictions between groups by re-reading the disputed
evidence yourself — the file wins, not the agent. Also re-grade each factor against FACTORS.md's
**violation signals**: agents drift strict or lenient, and a finding that is real but matches no
violation signal (a hardening gap, a nit) belongs in the finding line of a ✅, not in the grade.
Compute the score: `n compliant / m applicable` where m excludes ➖ factors.

### 5. Report

ALWAYS use this exact template, in chat:

```markdown
# Twelve-Factor audit: <project>

**Stack:** <one line> · **Date:** <YYYY-MM-DD> · **Score:** <n>/<m> applicable factors compliant

| # | Factor | Grade | Finding |
| - | ------ | ----- | ------- |
| I | Codebase | ✅ | <one line> |
| … | (all twelve rows) | | |

## ❌ <Factor name>
**What's wrong:** <evidence with paths>
**Why it matters:** <one line>
**Fix:** <concrete suggestion>

## ⚠️ <Factor name>
(same shape; ❌ sections before ⚠️ sections)
```

Detail sections only for non-✅, non-➖ factors. If a real credential was found, lead the ❌
Config section with it — location and variable name, never the value.

## Examples

**User:** `/12factor` (in an Express monolith with `express-session` defaults and a committed `.env`)
→ Stack pass finds Node/Express, compose file, no Procfile → grouped fan-out (A–D) → report:
Config ❌ (committed `.env` with real values — named, not quoted), Processes ❌ (MemoryStore
sessions), Logs ⚠️ (winston File transport), score 7/11 (Admin processes ➖ — no persistent state).

**User:** `/12factor packages/api` (inside a large monorepo)
→ Target is the one package; per-factor fan-out if the user asked for thoroughness, else grouped.

**User:** "run the twelve-factor audit" in Cursor
→ No subagent tool → inline mode, same FACTORS.md checks, same report template.
