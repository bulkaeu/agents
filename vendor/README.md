# Vendored third-party skills

`vendor/<name>/` holds a pinned copy of somebody else's skill set. Each source directory carries
`SOURCE` (the repo, the ref, the licence path and one `path:` line per adopted skill directory),
`UPSTREAM` (the repo, the ref and the resolved 40-hex sha), a `LICENSE` where upstream ships one,
and `skills/<skill>/` per adopted skill. `update-vendor.sh` copies exactly what `SOURCE` lists and
nothing else, and the recorded **sha** is what identifies the tree: a re-pin at a tag or a commit
ref reproduces it byte for byte, while a re-pin at a branch ref takes whatever the branch points at
then and writes a new sha.

They are vendored rather than installed as plugins so that every upgrade is a reviewed diff, and so
that no upstream hook, agent or marketplace wiring arrives with them. `install.sh` links each
`vendor/*/skills/<dir>` into `~/.claude/skills/<dir>`, `~/.cursor/skills/<dir>` and
`~/.agents/skills/<dir>` — the same three places as our own `skills/*`, by **directory** name.
`check-vendor.sh` fails if a vendored directory name or frontmatter `name:` would shadow one of
ours, another vendored skill, or a skill Claude Code ships itself.

This page is the catalogue: what each skill is, when it fires, what it writes or runs, what it
pre-approves, which siblings it hands off to, and how our rules modify it. `vendor/ponytail/` is
**not** described here — it has its own section in the repo's `README.md`, including its hooks,
`update-ponytail.sh`, `check-ponytail.sh` and `wire-ponytail-hooks.sh`.

## Sources

Thirty skills from eight sources. Attribution is to the upstream repository; the licence column
records what the vendored `LICENSE` file actually says.

| Source | Upstream repo | Ref · sha | Licence | Skills |
| --- | --- | --- | --- | --- |
| `anthropics` | github.com/anthropics/skills | `main` · `dbd4588` | Apache 2.0 (`LICENSE`, from the skill's own `LICENSE.txt`) | 1 |
| `getsentry` | github.com/getsentry/skills | `main` · `f57ada2` | Apache 2.0 (`LICENSE`, Copyright 2025 Functional Software, Inc. dba Sentry) | 4 |
| `hashicorp` | github.com/hashicorp/agent-skills | `v1.0.0` · `146815e` | MPL 2.0 (`LICENSE`); skill metadata says Copyright IBM Corp. 2026 | 4 |
| `playwright-cli` | github.com/microsoft/playwright-cli | `v0.1.22` · `b85c7a7` | Apache 2.0 (`LICENSE`, Copyright (c) Microsoft Corporation) | 1 |
| `supabase` | github.com/supabase/agent-skills | `v0.1.9` · `544bfc5` | MIT (`LICENSE`, Copyright (c) 2026 Supabase) | 1 |
| `superpowers` | github.com/obra/superpowers | `v7.0.0` · `bb92a77` | MIT (`LICENSE`, Copyright (c) 2025 Jesse Vincent) | 15 |
| `trailofbits` | github.com/trailofbits/skills | `main` · `5c99c03` | CC BY-SA 4.0 (`LICENSE`) — attribution and share-alike required | 3 |
| `vercel` | github.com/vercel-labs/agent-skills | `agent-skills-063bee94c3f4df8453406c830b0a7df0f2860278` · `063bee9` | MIT — **no licence file**, see below | 1 |

Refs are written in full, because `update-vendor.sh` passes a `<ref>` straight to
`git clone --branch`; only the sha column abbreviates.

**Two facts a reader cannot see from the tree.**

- `vendor/vercel/skills/react-best-practices` keeps its upstream directory name while its
  frontmatter declares `name: vercel-react-best-practices`. `install.sh` links the **directory**
  name, so the three symlinks are `react-best-practices`. `check-vendor.sh` compares both spellings
  for collisions, so neither name can shadow anything.
- `vendor/vercel` has no `LICENSE` file because none exists upstream. The MIT grant is the skill's
  `license: MIT` frontmatter field plus the upstream repository's README, recorded as a
  `license-note:` line in `SOURCE`. Vercel is adopted on that basis.

Licence ids and spec numbers inside the vendored prose trip `sanitize-check.sh`'s generic pattern
(`[A-Z]{2,5}-[0-9]+`); the matching lines are excused in the tracked `.sanitize-allow`, which is
deliberate. This page spells licence names with spaces (`MPL 2.0`, `CC BY-SA 4.0`) for the same
reason.

---

## anthropics

### `frontend-design` — fires automatically by description

Fires when new UI is being built or an existing one reshaped. It casts the agent as a design lead
whose client has already rejected templated work, and makes it ground every choice in the actual
subject matter rather than in a house default. The substance is a list of tells to avoid — cream
background with a high-contrast serif and a terracotta accent, one accented word in a headline,
ALL-CAPS eyebrow labels, `01 / 02 / 03` markers on content that is not a sequence, identical
rounded cards with one shadow, fade-and-slide-up on every section — plus typographic rules (one or
two families, a deliberate type scale, lines under about 80 characters) and a copywriting section
(active voice, a button that says what happens, errors that say how to fix it). The process is two
passes: a compact token plan of four to six named hex values, type roles, an ASCII wireframe and
stated principles, then a review of that plan against the brief before any code is written. It
writes nothing of its own, runs nothing, declares no `allowed-tools`, and takes screenshots to
critique itself where the environment allows. No sibling handoffs. None of our rules bear on it —
it is the one skill here that only advises.

---

## getsentry

Four skills, Apache 2.0. Three of them need an authenticated `gh`; two need `uv` to run bundled
Python.

### `find-bugs` — fires automatically by description

Fires on "review changes", "find bugs", "security review" or "audit this branch". It reviews the
whole branch diff against the default branch (`gh repo view --json defaultBranchRef`, then
`git diff`), and insists on reading every changed line before reasoning — if the diff truncates,
read the files. Five phases: gather the full diff, map the attack surface per file (inputs, queries,
auth checks, session and state, external calls, crypto), walk an eleven-item security checklist for
every file, verify each candidate is real rather than already handled or already tested, then audit
itself before concluding by listing what it read, what it checked and what it could not verify.
Output is findings ordered security before bugs before quality, each with file and line, severity,
evidence and a concrete fix; it is explicitly told to report and change nothing. No scripts, no
`allowed-tools`. It overlaps our own `/code-review` and `ponytail-review`, so pick one per task
rather than running all three. No rule of ours modifies it: it writes nothing and pushes nothing.

### `iterate-pr` — to be on demand only (gate pending; see the on-demand set)

Drives an existing pull request to green: fetch the checks, fetch and bucket the review feedback,
fix everything high and medium, ask which low-priority items to take, fix CI failures at the root
cause, verify locally, then commit, push, and poll every thirty seconds until the actionable checks
pass. Its own frontmatter sets `disable-model-invocation: false` — upstream opts **into** model
invocation — and its description says not to wait for human approval, draft status or merge gates.
Its `agents/openai.yaml` opts in a second time for OpenAI-style hosts: its `interface:` block holds
a `default_prompt` telling the agent to drive the current PR until the checks pass, and a top-level
`policy:` sets `allow_implicit_invocation: true`. It is the only one of the four vendored
`openai.yaml` files that holds anything beyond interface metadata; whether any host honours that
`policy` key is unverified from here.
Four bundled Python scripts run through `uv`: `fetch_pr_checks.py`, `fetch_pr_feedback.py`,
`monitor_pr_checks.py` and `reply_to_thread.py`, the last of which posts replies to review threads.
It needs authenticated `gh`, `uv`, and the repository root as the working directory. It declares no
`allowed-tools`, but it commits, pushes and comments as a matter of course, which is why it is in
the on-demand set. **Our rules modify it at the gate:** no third-party skill pushes, comments or
merges without the user asking in this session, so the loop stops before its first push unless they
did — its "do not wait for human approval" instruction does not reach past that.

### `pr-writer` — fires automatically by description

Fires when a PR is being opened or its title and body refreshed. It writes the body as a cover note
for reviewers rather than a changelog: inspect the branch, the working tree, any existing PR, the
base branch, the commits and the whole diff, then pick the smallest useful shape from a table that
runs from one paragraph for an obvious change up to migration guidance for a contract break.
Titles follow `<type>(<scope>): <subject>` from a fixed type list, with `!` reserved for an actual
external break. It bans default `Summary` / `Changes` / `Test Plan` headings, pasted commands and CI
logs, exhaustive file lists, and — worth knowing in a public repo — customer names, user emails,
ticket contents, secrets and PII. It creates PRs as drafts (`gh pr create --draft --body-file`) and
updates existing ones through `gh api -X PATCH`. No bundled scripts; `EVAL.md` and `evals/` are
upstream's own test fixtures. **Our rules modify it at the gate:** creating or editing a PR waits for the
user asking in this session. Nothing of ours governs the title format, so upstream's
`<type>(<scope>): <subject>` stands.

### `skill-scanner` — to be on demand only (gate pending; see the on-demand set)

Audits a skill directory before adoption, in eight phases: run the bundled static scanner, validate
the frontmatter, triage prompt-injection hits (a security skill that *documents* injection patterns
is not performing one), read the body for behavioural problems — config and memory poisoning,
instructions that write to an agent's own settings or allowlists, scope creep, unnecessary data
gathering, symlinks that resolve outside the skill, frontmatter hooks, load-time command expansion,
auto-discovered test files, npm lifecycle hooks, text hidden in image metadata — read every bundled
script in full, review the URLs for supply-chain risk, and rate the permission profile against a
least-privilege tier table. It runs `uv run scripts/scan_skill.py <dir>` for the deterministic part
and reads three reference files for the judgment part. **It pre-approves `Read Grep Glob Bash` —
unrestricted Bash** — which is why it is in the on-demand set. Output is a severity-rated report ending in
"Safe to install", "Install with caution" or "Do not install". **Our rules make it part of the
bump procedure:** every vendor bump is read as a diff and scanned with this skill before
`install.sh` links it.

---

## hashicorp

Four Terraform skills, MPL 2.0. All four write or review Terraform rather than running it, with one
exception noted below. None declares `allowed-tools`.

### `refactor-module` — fires automatically by description

Fires on turning a monolithic Terraform configuration into reusable modules. It works in phases:
group resources by function and map dependencies, design the interface first (typed variables with
validation rules, documented outputs), transform the configuration into
`modules/<name>/{main,variables,outputs}.tf` with a root module that calls it, then migrate state
with `moved` blocks and prove the migration by a plan that shows no changes. It also prescribes the
module README, a test suite, a semantic-versioning scheme for module releases, and a success-criteria
checklist; its pitfalls section argues against over-generic interfaces and against modules coupled
through direct cross-references. It writes Terraform and documentation, bundles no scripts, and
leaves `terraform plan` and `terraform apply` to the user's own workflow. It hands off to
`terraform-style-guide` (vendored) for the new module's style, and links a raw upstream URL for an
`azure-verified-modules` skill that is **not** vendored — treat that as a reference, not an
installed sibling. **Our rules:** a state migration is the same class of act as a database
migration, so nothing is applied without an explicit yes.

### `terraform-search-import` — fires automatically by description

Fires on bringing unmanaged cloud resources under Terraform control, auditing cloud resources, or
migrating to infrastructure as code. It requires Terraform 1.14 or newer plus providers with
list-resource support, and checks that support *first*: `scripts/list_resources.sh [provider]`
(bash, needs `terraform` and `jq`) extracts the provider's list-resource schemas. That script is the
one vendored script that mutates its working directory and reaches the network — it runs
`terraform init -upgrade` when `.terraform` is missing. The workflow then writes `list` blocks in a
`.tfquery.hcl` file, runs the query, generates a `generated.tf` carrying `__generated__`
configuration, cleans that up by hand, and imports by identity. Where support is missing it falls
back to `references/MANUAL-IMPORT.md`. **Our rules:** the init, the query and the import all touch
real cloud state, so they are gated the way an apply is gated — explicit yes, in this session.

### `terraform-style-guide` — fires automatically by description

Fires when Terraform is being written, reviewed or generated. It encodes HashiCorp's official
conventions: the standard file split (`terraform.tf`, `providers.tf`, `main.tf`, `variables.tf`,
`outputs.tf`, `locals.tf`), variables and outputs in alphabetical order, block ordering inside a
resource, naming as descriptive nouns with underscores and no repetition of the resource type,
`for_each` over `count` except for conditional creation, explicitly pinned version constraints,
`sensitive = true` on secrets, and a code-review checklist to finish. It names the commands to run
before committing — `terraform fmt -recursive` and `terraform validate` — and mentions `tflint`,
`checkov` and `tfsec` as optional extras. No scripts, no pre-approvals, no handoffs; it is the
sibling `refactor-module` defers to. No rule of ours modifies it.

### `terraform-test` — fires automatically by description

Fires when `.tftest.hcl` files, run blocks, assertions, provider mocks or test troubleshooting come
up. It covers the test file's shape (test-wide settings, file-level variables, provider blocks, run
blocks with asserts), the two modes — `plan` validates logic, `apply` **creates real resources** —
mock providers for Terraform 1.7 and newer, a naming convention that lets CI filter unit tests from
integration tests, parallel runs isolated by `state_key`, cleanup in reverse run-block order, and
`-no-cleanup` for debugging. Three reference files carry the mock syntax, GitHub Actions and GitLab
CI pipelines, and a complete example suite. It runs `terraform test` with its filters; no bundled
scripts. **Our rules:** an apply-mode test creates infrastructure, so it waits for an explicit yes
exactly as a migration apply does.

---

## playwright-cli

### `playwright-cli` — to be on demand only (gate pending; see the on-demand set)

Drives a real browser from the shell. The primary interface is the accessibility snapshot with `eN`
element refs, not screenshots: `open`, `goto`, `snapshot`, `find`, `click`, `type`, `fill`, `select`,
`upload`, `drop`, `eval`, `press`, then `close`. It also covers tabs, cookies and local or session
storage, device and media emulation, network mocking, tracing and video recording, a codegen
recorder that prints Playwright code, a review dashboard that collects a user's annotations, WebMCP
tool calls exposed by the page, and named persistent browser sessions. Ten reference files hold the
detail — tests, test generation, request mocking, storage state, sessions, tracing, video, element
attributes, running code, and attaching artifacts to pull requests. It needs Node and the
`@playwright/cli` package, and tells the agent to `npm install -g @playwright/cli@latest` when the
global binary is missing. **It pre-approves `Bash(playwright-cli:*)`, `Bash(npx playwright:*)` and
`Bash(npx --no-install playwright:*)`** — at this pin the grant is scoped to Playwright rather than
to all of `npx`, though `npx playwright <anything>` is still a wide surface and the skill's own text
notes that package installs and custom `npm` scripts may need separate approval. That, plus a
browser that can be pointed at any site with any saved profile, is why it is in the on-demand set. **Our
rules:** installing a package is the user's call, and so is any sign-in the browser performs.

---

## supabase

### `supabase-postgres-best-practices` — fires automatically, on a very wide trigger

Its description asks to be loaded *before* writing or changing anything that lives in Postgres —
tables and column types, schema design, migrations and declarative schema files, RLS policies and
their tests, indexes, triggers, functions, queues and scheduled jobs, vector search, dump restores
and data imports — and also when diagnosing slow queries, high CPU, timeouts, EXPLAIN plans,
connection exhaustion, locking, bloat, or rows visible to the wrong tenant. Expect it to fire on
almost any database task, including a one-column change. The skill file itself is only an index: 8
priority categories with the prefixes `query-`, `conn-`, `security-`, `schema-`, `lock-`, `data-`,
`monitor-` and `advanced-`, pointing at roughly thirty rule files under `references/`, each giving a
short rationale, wrong and right SQL, and EXPLAIN output or metrics where they help. It writes
nothing, runs nothing and pre-approves nothing. **Our rules:** it will fire on migration work, and
`migration-apply-confirmation.md` still owns whether anything is applied — this skill advises, it
never runs SQL.

---

## superpowers

Fifteen skills, MIT, from `obra/superpowers` v7.0.0. They are a connected set: they refer to each
other as `superpowers:<name>`, and some reach sideways by relative path —
`../using-superpowers/references/<harness>-tools.md`, and
`../subagent-driven-development/scripts/<script>` from `executing-plans`. Those paths resolve
because `install.sh` links every skill directory side by side in one directory, and they resolve in
this checkout too. **Dropping one superpowers skill can break another's references**, so check the
relative paths before removing one.

The upstream `SessionStart` hook is **not** adopted; see "The superpowers hook we skip" below.

### `brainstorming` — fires automatically by description

Its description is the most forceful in the set: use it before any creative work, in software or
out of it. It replaces proposing with asking — the first message offers an opt-out and then asks one
open question; every later message ends with exactly one question, and understanding is played back
in 200 to 300 word chunks that alternate with the questions. It covers ground rather than a script
(what the thing is, why now, goals and anti-goals, prior art, current state), marks guesses as
guesses, thinks wide privately before proposing, offers to go and look at code or the web, and
offers a throwaway spike when building something is the cheapest way to learn. It then sizes the
work — quick task, small change, or a project with a written design — and for a project writes a
design document, has a fresh subagent read it as the builder would (`builder-check-prompt.md`), and
sorts the questions that come back into answered, minor and theirs. A `HARD-GATE` blocks all
building, scaffolding, dependency installs and implementation skills until the human approves the
description. It can start a local Node server for a visual companion
(`scripts/start-server.sh`, `server.cjs`, a random high port bound to loopback by default, reached
through a per-session key in the served URL). **Two things that server does are worth knowing before
the next bump.** Its branding block embeds an `<img>` pointing at a hardcoded logo on
`primeradiant.com`, with the installed superpowers version as a query parameter
(`server.cjs:106`, `:242-249`) — so opening the companion calls out to the skill author's host and
tells it which version is running. The fetch is suppressed only if one of
`SUPERPOWERS_DISABLE_TELEMETRY`, `DISABLE_TELEMETRY` or
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is truthy in the environment (`:107-112`), and nothing
in this repo sets them. And `visual-companion.md:95-101` instructs
`--host 0.0.0.0` whenever the URL is unreachable from the browser, which drops the loopback bind and
exposes the server — the mockups and the key the agent prints into the chat — to every host that
can route to the machine. `rules/third-party-skills.md` keeps the bind on loopback unless the user
says otherwise; the fetch is the session's to opt out of. It hands off to `writing-plans`.
**Our rules modify where its output goes:** designs and specs go to the plans repo, not
`docs/superpowers/specs/`, and they open with a Summary and a Progress table.

### `writing-plans` — fires automatically by description

Fires once a spec or a set of requirements exists, before code. It writes the plan for an engineer
who has seen neither the codebase nor the spec: map the files first, right-size tasks so each one
carries its own test cycle and is worth a fresh reviewer's gate, and cut steps so each is one action
with a checkable result. It mandates a plan header — Goal, Architecture, Tech Stack, the Spec's
path, Global Constraints copied verbatim, and a Review Focus section naming the five uncovered
failure modes most likely to bite — and a per-task block with exact Files, an Interfaces block
naming what the task consumes and produces, and TDD steps ending in a commit. A five-point
self-review closes it: spec coverage, a step scan for steps that decide nothing or transcribe code,
type and signature consistency across tasks, Review Focus coverage, and proportion against the
spec's own length. Default output is `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`, and it
ends by asking the human to choose subagent-driven or inline execution. **Our rules modify it in
three ways:** the plan lives in the plans repo, it opens with a Summary and a Progress table, and it
keeps superpowers' `### Task N:` headings below those, because the `task-brief` script extracts a
task by matching that heading.

### `executing-plans` — fires automatically by description

Fires when the human chose inline execution at the plan handoff, or when the harness has no subagent
tool. It executes the plan itself, task by task, without pausing between tasks, with TDD as the
per-task gate and a single fresh-context review of the whole branch at the end. Because a compacted
context re-implements tasks whose commits already exist, it keeps a ledger at
`<repo-root>/.superpowers/sdd/<plan-basename>/progress.md` whose first line names the plan, and it
trusts that ledger and `git log` over its own recollection. Deviations are decided, not escalated,
and recorded as `Ruling: <what you decided> — <why> — <what it costs if wrong>`; only four things
stop it — an irreversible or destructive operation, a security-sensitive action, a side effect
outside the worktree such as a merge, a push or a publish, and a plan too broken to guess at. It
runs two bash scripts, `scripts/task-start` and `scripts/task-done`, which call
`subagent-driven-development`'s `task-brief` and `sdd-workspace`, and it requires
`test-driven-development` before Task 1. It hands off to `systematic-debugging` on an unexpected
failure and to `finishing-a-development-branch` at the end. **Our rules:** it ticks the plan's
Progress table as it goes, `/plan-finish` is the close-out when a plan exists, and its pushes and
merges wait for the user.

### `subagent-driven-development` — fires automatically by description

Fires on a plan whose tasks are mostly independent. It dispatches a fresh implementer subagent per
task (`implementer-prompt.md`), builds a review package, dispatches a task reviewer for spec
compliance and code quality (`task-reviewer-prompt.md`), and runs up to five scoped fix rounds
(`re-review-prompt.md`), escalating to a fresh implementer on a more capable model at round four;
then one broad whole-branch review using `requesting-code-review`'s `code-reviewer.md`. It shares
the workspace, the ledger and the "rulings, not stalls" discipline with `executing-plans`, so a plan
can change executors mid-flight. Three bash scripts: `sdd-workspace` (one git-ignored directory per
plan, with a marker naming its owning plan so two plans cannot read each other's artifacts),
`task-brief` (extracts one `### Task N:` section to a file), and `review-package` (commit list, stat
summary and the net diff for a recorded BASE..HEAD range). A model-selection section tiers the roles
— cheap for mechanical tasks, the most capable model for the final review. Before Task 1 it scans
the plan for conflicts and writes the scan out as a table of rows, not a verdict. **Our rules:** it
ticks the Progress table; our own `/plan-build` covers the same ground, so run one or the other per
plan rather than nesting them; pushes and merges stay gated.

### `test-driven-development` — fires automatically by description

Fires before any implementation code, for features, bug fixes, refactors and behaviour changes, with
throwaway prototypes, generated code and configuration as the only exceptions, and those only after
asking. The iron law is that no production code exists without a failing test first, and code
written before its test is deleted rather than adapted or kept for reference. It spells out
red-green-refactor step by step, what makes a test worth having, a verification checklist, and a
rationalization table for the usual excuses. It writes tests and runs the project's own test
command; no scripts, no pre-approvals. `executing-plans` loads it as a required sub-skill before
Task 1; `subagent-driven-development` leaves it to the task ("write tests following TDD if the task
says to"). It names no sibling of its own — its own debugging advice is one line, "write a failing
test reproducing the bug" — and the handoff to `systematic-debugging` on an unexplained failure
is `executing-plans`', not this skill's. No rule of ours modifies it.

### `systematic-debugging` — fires automatically by description

Fires on any bug, test failure or unexpected behaviour, before any fix is proposed. Its iron law is
no fix without root-cause investigation, and it is emphatic that the rule matters most under time
pressure. Four phases must complete in order, starting with reading the error text and stack trace
properly, reproducing consistently, checking what changed recently, and — in a multi-component
system — adding instrumentation at each component boundary before proposing anything. Sibling
documents cover root-cause tracing, condition-based waiting instead of arbitrary timeouts (with a
TypeScript example), and defence in depth; `find-polluter.sh` (bash) bisects a test suite to find
the test that pollutes shared state. It also says what to do when the process finds no root cause.
No pre-approvals. No rule of ours modifies it.

### `requesting-code-review` — fires automatically by description

Fires on finishing a task, completing a major feature, or before a merge. It dispatches a
`general-purpose` reviewer subagent built from the `code-reviewer.md` template with a BASE and HEAD
sha and a precisely constructed context — never the session's history, because the coordinator's
context is what the delegation is protecting. Findings come back graded, and the skill says to fix
Critical immediately, fix Important before proceeding, note Minor, and push back with technical
reasoning where the reviewer is wrong. It writes nothing itself and runs only `git rev-parse`. Both
plan executors use it for the final whole-branch review. **Our rules:** `/plan-build` already runs a
reviewer that did not write the code, so this is the mechanism for work outside a plan.

### `receiving-code-review` — fires automatically by description

Fires when review feedback arrives, before any of it is implemented. Six steps: read it all without
reacting, restate the requirement in your own words or ask, verify it against what the codebase
actually does, evaluate whether it is sound *for this* codebase, respond with a technical
acknowledgement or reasoned pushback, and implement one item at a time with a test each. It forbids
performative agreement — "You're absolutely right!", "Great point!", "Let me implement that now"
before verification — requires a stop-and-ask when any item is unclear, handles feedback differently
by source, applies a YAGNI check to "professional-sounding" suggestions, and covers how to correct
your own pushback gracefully. It includes guidance on replying to GitHub review threads. **Our
rules:** a reply posted on a PR is a publish-class action and waits for the user asking in this
session.

### `verification-before-completion` — fires automatically by description

Fires when work is about to be called complete, fixed or passing, and before any commit or PR. One
rule: no completion claim without fresh verification evidence, run in the same message as the claim.
A gate function names the steps — identify the command that would prove the claim, run it in full,
read the whole output and the exit code, check that it actually confirms the claim, and only then
say so — and a table pairs each claim with what proves it and what does not ("linter passed" does
not prove the build compiles, an agent's success report does not prove the diff exists). The red
flags are the words themselves: "should", "probably", "seems to", and any satisfaction expressed
before a command was run. It writes and runs nothing of its own. No rule of ours modifies it; it
restates the standard our own reports are held to.

### `finishing-a-development-branch` — fires automatically by description

Fires when implementation is complete and the tests pass. It verifies the full suite first and stops
if anything fails, detects whether it is in a linked worktree or on a detached HEAD, confirms the
base branch before merging, then presents a fixed menu and waits: three options in a normal repo or
a named-branch worktree — merge back to the base locally, push and open a pull request, or keep the
branch as it is — and a reduced two on a detached HEAD, where merging is dropped. On a merge it
re-runs the tests on the merged result before deleting anything; on a PR it keeps the worktree for
iteration; cleanup of the worktree is by provenance, and a request to discard work requires the
literal word `discard` typed back. **Our rules modify it in three places:** the merge and the push
wait for the user asking in this session, this project's declared worktree convention wins over the
skill's defaults, and when a plan exists `/plan-finish` is the close-out rather than this menu.

### `using-git-worktrees` — fires automatically by description

Fires before isolated feature work or plan execution. It checks for existing isolation first,
comparing `git rev-parse --git-dir` against `--git-common-dir`, with a guard for submodules — which
look identical to a worktree by that test — and does not create a second worktree when it is already
in one. It then prefers the harness's own worktree tool (`EnterWorktree` and the like) over
`git worktree add`, on the grounds that a manual worktree creates state the harness cannot see,
asks consent before creating anything, verifies the chosen directory is git-ignored before writing
into it, and finally installs dependencies by detected ecosystem and runs a baseline test suite so
that later failures are unambiguous. **Our rules:** this project's declared worktree convention wins
over the `.worktrees/` default the skill falls back to.

### `using-superpowers` — to be on demand only (gate pending; see the on-demand set)

This is the dispatcher the upstream hook injects, and the reason we do not inject it: its
description is "Use when starting any conversation", and its body instructs the agent to invoke any
skill with as little as a 1% chance of applying, before any response at all — including clarifying
questions and before looking at the codebase. It also sets a priority order (process skills first,
then implementation skills), requires announcing "Using [skill] to [purpose]", turns a skill's
checklist into a todo per item, and carries a red-flag table against the usual ways of rationalizing
out of it. Its `references/` directory holds seven per-harness files — Claude Code, Codex,
Gemini, Pi, Antigravity, Hermes Agent and Muse — that tell the other skills which tools exist on
the current platform; the skill's own "Platform Adaptation" section lists only six, omitting Gemini,
which `writing-skills` nonetheless links. Those files are why the directory stays even though we
gate the skill. It writes and runs nothing, and declares no pre-approvals. Its closing
section already says user instructions outrank skills, which is the ordering our rules rely on.

### `writing-skills` — fires automatically by description

Fires on creating, editing or verifying a skill. It treats skill authoring as test-driven
development: run a pressure scenario against a subagent **without** the skill and record the exact
rationalizations it produces, write the skill to address those, verify compliance, then close
loopholes and re-verify. Around that it covers skill types, directory structure, the expected
SKILL.md shape, writing a description for discovery (triggering conditions only, no workflow
summary, no first person), flowchart and code-example conventions, when detail belongs in a sibling
file, and a long anti-pattern list. It bundles `render-graphs.js` (Node, needs graphviz's `dot`) to
render `dot` blocks from a SKILL.md into SVG, plus sibling documents on testing with subagents,
persuasion principles, and Anthropic's own authoring guidance. It requires
`test-driven-development`. **Our rules:** this repo's own contributing section owns SKILL.md length
and the one-hop reference convention, and a vendored skill is never edited in place.

### `dispatching-parallel-agents` — fires automatically by description

Fires when there are two or more genuinely independent tasks with no shared state. One agent per
problem domain, all dispatched in the same response so they run concurrently, each with a specific
scope, a clear goal, explicit constraints and a named expected output; then read each summary, check
whether the agents touched the same code, run the full suite, and spot-check, because agents make
systematic errors. It is equally clear about when not to use it — related failures, work needing
whole-system context, exploratory debugging, or shared state. It writes and runs nothing. No rule of
ours modifies it; `/plan-build` does its own dispatching.

### `diagnosing-superpowers` — fires automatically by description

Fires when a session went wrong and the human wants to know why — repeated work, a skill that did
not fire, "it took too long", "why is it so expensive" — or wants a bug report for the superpowers
maintainers. Every finding must cite `path:line` and every number must come from the transcript or
from a command that was run; findings without a citation are discarded. The workflow is intake one
question at a time until the problem is stated in observable terms, locate and verify the session
transcripts on disk (quoting the first prompt to confirm, and listing the candidates rejected),
create a case directory under the home directory at `~/.superpowers/diagnosing-superpowers/<session
id>/`, dispatch one analyst subagent per dimension in parallel — skill timeline, plan adherence,
repeated work, stumbles, quality evidence, request conflicts, cost and time — then fill a report
template, with a redaction and scrub pass for anything that becomes a bug-report bundle. It reads
whole session transcripts and writes outside the repository. **Our rules:** filing anything upstream
is publishing, so it waits for the user asking; and this repo's sanitization standard applies to
anything that leaves the machine.

---

## trailofbits

Three security skills, **CC BY-SA 4.0** — attribution and share-alike. Attribution: Trail of Bits,
`github.com/trailofbits/skills`; anything derived from their text carries the same licence. All
three declare `allowed-tools`, and each ships an `agents/openai.yaml` plus a Trail of Bits mark.

**One gap worth knowing.** Two of these skills dispatch a companion agent — `differential-review`
calls `differential-review:adversarial-modeler` for its adversarial-modelling phase, `sharp-edges`
calls `sharp-edges-analyzer` — and upstream ships both as part of a *plugin*. We vendor skill
directories only, so nothing registers those agents and a dispatch of either one fails at runtime.
Run the phase inline instead. `supply-chain-risk-auditor` names no agent; its `agents/openai.yaml`
is interface metadata, not a dispatch.

### `differential-review` — to be on demand only (gate pending; see the on-demand set)

Its description fires on reviewing a PR, a commit or a diff for security problems, on asking
whether a change re-introduces a fixed bug, on asking what else a change could break, and on
finding modified code with no test covering it. It classifies by risk rather than size (its first
rationalization row is "Heartbleed was 2 lines") and scales to the codebase: deep for under twenty
files, focused for up to two hundred, surgical above that. Seven phases run from triage through code
analysis, test coverage of the modified lines, blast radius calculated by counting callers, deep
context, adversarial modelling, and a report; `methodology.md`, `adversarial.md`, `reporting.md`
and `patterns.md` carry the detail and are read on demand. **It pre-approves
`Read Write Grep Glob Bash`** — it needs `git blame` and `git log` for history, and it always
writes a markdown report file, with "report to chat only" listed as a failure mode.
`methodology.md` also carries a `git checkout <baseline_commit>` step, which moves HEAD rather than
reading history; it sits under
"if `audit-context-building` is available", and we do not vendor that skill, so the path is
unreachable at this pin. The unrestricted `Bash` plus that step is why it is in the on-demand set.
**Our rules:** its report is a new file, so keep it out of the repository under review unless asked;
nothing it does pushes or publishes.

### `sharp-edges` — fires automatically by description

Fires on reviewing an API design, a configuration schema or a cryptographic library's ergonomics,
and on the words footgun, misuse-resistant, secure defaults and dangerous configuration. The
principle is the pit of success: if secure use requires reading documentation or remembering a
special rule, the API has failed. It works through six categories — algorithm and mode selection
(the JWT `alg: none` pattern), dangerous defaults (what does `timeout=0` mean?), primitive versus
semantic types (bytes that can be swapped for other bytes), configuration cliffs (one typo or one
flag disabling security), silent failures (a verifier that returns false and a caller that ignores
it), and stringly-typed permissions — in a four-phase workflow, against three adversary models (the
scoundrel, the lazy developer, the confused developer), with a severity table. Reference files cover
crypto APIs, configuration and auth patterns, real case studies, and footguns in eleven languages.
**It pre-approves `Read Grep Glob` only** — it writes nothing and runs nothing. No rule of ours
modifies it.

### `supply-chain-risk-auditor` — to be on demand only (gate pending; see the on-demand set)

Its description fires on auditing dependencies or assessing third-party package risk. The measuring
is done by two Python scripts rather than by the agent, because hand-collected figures were
measured wrong before: `uv run scripts/collect.py <project-dir> --json findings.json` then
`uv run scripts/render.py findings.json --out report.md`, with `sources.py`, `model.py`, a
`pyproject.toml`, a `uv.lock` and four test files beside them. It covers npm, PyPI and Go; it reads
`package-lock.json` or `npm-shrinkwrap.json`, `uv.lock` and a go 1.17 or newer `go.mod`, and states
plainly that `yarn.lock`, `pnpm-lock.yaml` and `poetry.lock` are not parsed. Two rules run through
it: unavailable data is never evidence of risk, and a run that measured nothing exits non-zero
rather than printing a clean report. It needs `uv` and an authenticated `gh` (sixty requests an hour
without one), never installs, builds or reads dependency source, and writes its artifacts outside
the audited repository by default; the agent adds judgment — what to act on first, upgrade paths,
replacement candidates — in a prescribed impersonal register. **It pre-approves
`Read Write Bash Glob Grep`** — unrestricted `Bash` again, which is why it is in the on-demand set
even though everything it does is a read. **Our rules:** its `gh` and registry calls are reads, so
nothing else is gated; it is the skill to reach for before adding a dependency.

---

## vercel

### `react-best-practices` — fires automatically by description

Fires when React or Next.js code is written, reviewed or refactored, and on tasks involving
components, pages, data fetching, bundle size or performance. Like the Supabase skill it is an index
rather than a document: 70 rules in 8 priority categories — `async-` (eliminating waterfalls),
`bundle-`, `server-`, `client-`, `rerender-`, `rendering-`, `js-` and `advanced-` — each named and
one-lined in the SKILL.md, each with its own file under `rules/` giving the rationale, wrong and
right code, and impact. A compiled `AGENTS.md` holds every rule expanded, for when the whole guide
is wanted at once. It writes nothing, runs nothing and pre-approves nothing. Remember the naming
split recorded above: the directory and therefore the installed skill is `react-best-practices`,
while the frontmatter name is `vercel-react-best-practices`. No rule of ours modifies it.

---

## ponytail

`vendor/ponytail/` is described in the repo's own `README.md`, under "Vendored: ponytail" — its
hooks, its subagent matcher, its upgrade order and its three helper scripts. It is kept there rather
than duplicated here so that each vendored set is described in exactly one place. Note that it is
the only vendored source with hooks. `install.sh` does not treat it specially: its six skills are
linked by the same `vendor/*/skills/*/` loop as every other set, and `check-vendor.sh`'s name sweep
includes it like any other `vendor/*/` with a `skills/`. `check-ponytail.sh` adds the checks that
are specific to it — its hook events, its mode tracker, its subagent matcher, its pinned sha —
comparing names against `skills/*` only. `update-ponytail.sh` runs both; `install.sh` runs neither.

---

## The superpowers hook we skip

Upstream superpowers ships a `SessionStart` hook that injects the `using-superpowers` skill into
every session — at start, after `/clear` and after every compaction — carrying its "if there is even
a 1% chance a skill might apply, you ABSOLUTELY MUST invoke the skill" instruction. **We do not
install it.** Three reasons: it would put superpowers' process ladder in front of every
conversation regardless of task; we already inject a ruleset through ponytail's hooks, and two
injected rulesets compound rather than cooperate; and vendoring skills without hooks is the whole
reason these sets are copied here instead of installed as plugins — a hook is upstream code
executing on our machine between reviews.

What the skills still do without it: **everything except the nudge.** Each skill is linked into the
three agent directories and still fires on its own description, which is how the other fourteen
superpowers skills were meant to be found in the first place. The per-harness reference files under
`using-superpowers/references/` are still on disk for the skills that read them. What is lost is the
reflex — "check for a skill before replying at all" — and our own always-apply rules already carry
the parts of that worth having: process before code, a plan before implementation, evidence before
claims. `using-superpowers` itself remains invocable by name when its dispatcher behaviour is
actually wanted.

## The on-demand set and its pre-approvals

Six of the thirty should never start on the model's own initiative. All six currently do, on their
own descriptions, because the gate below is not yet in place.

| Skill | Why it should be on demand |
| --- | --- |
| `iterate-pr` | It commits, pushes and replies to review threads as part of its loop, and its own description says not to wait for human approval. |
| `playwright-cli` | While active it pre-approves `Bash(playwright-cli:*)` and `Bash(npx playwright:*)`, and it drives a real browser that can be pointed anywhere with any saved profile. |
| `skill-scanner` | It pre-approves unrestricted `Bash`. |
| `using-superpowers` | Its description — "Use when starting any conversation" — recreates the hook above. |
| `differential-review` | It pre-approves `Read Write Bash` — unrestricted `Bash` — and its methodology includes a `git checkout` of a baseline commit. |
| `supply-chain-risk-auditor` | It pre-approves `Read Write Bash` — unrestricted `Bash` — and fires on any dependency question. |

**How (pending).** In Claude Code each **is to be** set user-invocable-only through `skillOverrides`
in the settings file, edited with `jq -a` so the file's existing escapes survive. **That entry is
not in place yet**, so read this section as the standard rather than a description of the installed
state: today all six fire on their own descriptions like any other skill. **Once you call one of
them, its pre-approvals apply to that invocation anyway** — gating the trigger is not gating the
grant, and invoking `skill-scanner` is consenting to its `Bash`.

**How far that reaches, and the gap we accept.** `skillOverrides` is Claude Code only. The rule
reaches Claude Code and Cursor directly, because `install.sh` links `rules/` into both, and it
reaches Codex indirectly: `install.sh` links `claude/CLAUDE.md` to `~/.codex/AGENTS.md`, and that
file tells the agent that every `.md` in `~/.claude/rules/` is part of its instructions. **What no
host but Claude Code gets is the gate** — an agent that loads only `~/.agents/skills` sees these six
with their triggers intact. That is accepted, with reasons: no such agent is in daily use here; the
pre-approvals are advisory metadata those hosts may not honour anyway; and the alternative is
per-agent exclusion logic in `install.sh` for a host we barely use. Revisit it if Codex becomes a
daily driver.

### Every pre-approval in the thirty

All thirty `SKILL.md` frontmatters were checked. Five declare `allowed-tools`; the other
twenty-five declare none, which means they inherit whatever the session already permits.

| Skill | `allowed-tools` |
| --- | --- |
| `skill-scanner` | `Read Grep Glob Bash` |
| `differential-review` | `Read Write Grep Glob Bash` |
| `supply-chain-risk-auditor` | `Read Write Bash Glob Grep` |
| `sharp-edges` | `Read Grep Glob` — read-only |
| `playwright-cli` | `Bash(playwright-cli:*) Bash(npx playwright:*) Bash(npx --no-install playwright:*)` |

Three of the five grant unrestricted `Bash` — `skill-scanner`, `differential-review` and
`supply-chain-risk-auditor` — and all three are in the on-demand set above. `sharp-edges` is the one
Trail of Bits skill that stays on its own trigger, because `Read Grep Glob` writes and runs nothing.
One more frontmatter field is worth recording: `iterate-pr` sets `disable-model-invocation: false`,
so upstream deliberately opts it into model invocation — the pending `skillOverrides` entry is what
would reverse that here.

## How our rules modify these skills

The rule file is `rules/third-party-skills.md`; this is the short form, and the per-skill entries
above say where each clause lands.

- **Plans and specs** from `brainstorming` and `writing-plans` go to the plans repo, not
  `docs/superpowers/`. They open with a Summary and a Progress table, and keep superpowers'
  `### Task N:` headings below so `task-brief`'s extraction still works.
- **`executing-plans` and `subagent-driven-development`** tick the Progress table as they go.
- **Pushes, PRs, merges, review replies and publishing:** no third-party skill does any of these
  without the user asking in this session. That bites `iterate-pr`, `pr-writer`,
  `finishing-a-development-branch`, `receiving-code-review` and `diagnosing-superpowers`.
- **Worktrees:** the project's declared worktree convention wins over `.worktrees/`.
- **Migrations:** `migration-apply-confirmation.md` wins over any skill. That reaches the three
  HashiCorp skills that touch real infrastructure and the Supabase skill that fires on migration
  work.
- **Close-out:** when a plan exists, `/plan-finish` is the close-out, not
  `finishing-a-development-branch`'s menu.
- **Vetting and editing:** vendored copies are never edited in place; every bump is read and scanned
  before `install.sh` links it.

## Deliberately not adopted

| Not adopted | Reason |
| --- | --- |
| The superpowers `SessionStart` hook | It injects `using-superpowers` at every start, clear and compaction, with the "invoke a skill if 1% likely" instruction. See the section above. |
| Every Medusa skill | The repo ships no licence file, so it cannot be vendored into a public repo. |
| Trail of Bits `insecure-defaults` | It is now a command and workflow plugin with no `SKILL.md`, so there is nothing to link. A possible plugin follow-up. |
| Anthropic document skills and `skill-creator` | Already available in this environment, and the document skills are proprietary. |
| Anthropic `webapp-testing` | Python-based; `playwright-cli` suits our Node stack. |
| `web-design-guidelines` | It downloads its rules at runtime, so pinning cannot freeze it. |
| mattpocock, addyosmani and wshobson bundles | They overlap superpowers and our own `plan-*` skills. |
| Bulk "awesome" collections (ComposioHQ, ECC and similar) | Noisy, and some of them ship hooks. |

## Bumping one source

Upstream changes are adopted as a reviewed diff, never in the main checkout — `update-vendor.sh`
refuses to run on `main` or in the main worktree, because the installed symlinks point at the main
checkout and an update there would go live before anyone read it.

1. Create a worktree on a new branch.
2. `bash update-vendor.sh <name> [<ref>]` — with no `<ref>` it re-pins the ref recorded in
   `vendor/<name>/SOURCE`; with one, it uses that tag or branch and leaves `SOURCE` alone. It
   replaces `skills/` and `LICENSE` wholesale, so a file deleted upstream goes too, rewrites
   `UPSTREAM` with the resolved sha, runs `check-vendor.sh` and then `sanitize-check.sh`, and prints
   the upstream compare range. It never commits.
3. **Read the diff. That is the review.**
4. If `sanitize-check.sh` flagged a new harmless string, add it to `.sanitize-allow`. **Exit 3 means
   only the sanitize check failed** — `check-vendor.sh` passed. Exit 1 is a failed conflict check or
   a failed clone or copy; exit 2 is a refusal (`main`, the main worktree) or bad usage.
5. Run `skill-scanner` over the skills whose files changed.
6. Commit, open a PR, merge.
7. From the main checkout, `bash install.sh` — needed when a skill directory was added or removed
   upstream, harmless otherwise.

**A branch-pinned set cannot be re-pinned to its recorded sha through this script.**
`update-vendor.sh` passes `<ref>` to `git clone --branch`, which takes a tag or a branch and never a
sha, and `anthropics`, `getsentry` and `trailofbits` all record `ref: main` — so for those three a
bare re-pin takes whatever `main` points at that day. Their recorded sha is for verification (check
it out upstream to see exactly what was vendored), not for reproducing the tree. Pinning them to an
immutable ref would mean putting a sha or a tag in `SOURCE` and teaching the script to fetch it,
which is a change nobody has asked for yet.

## Removing one skill

Four steps, and the second is the one that gets forgotten:

1. Delete its directory from `vendor/<name>/skills/<skill>/`.
2. **Remove its `path:` line from `vendor/<name>/SOURCE`** — otherwise the next
   `update-vendor.sh <name>` copies it straight back in.
3. Delete its entry from this catalogue.
4. Delete its three symlinks: `~/.claude/skills/<dir>`, `~/.cursor/skills/<dir>` and
   `~/.agents/skills/<dir>`, where `<dir>` is the **directory** name, which for the Vercel skill is
   not its frontmatter name. `install.sh` creates links and never removes them, so a stale symlink
   survives a re-run and points at nothing.

Check the relative references before removing a superpowers skill: `executing-plans` reaches into
`subagent-driven-development/scripts/`, and several skills read
`using-superpowers/references/<harness>-tools.md`.

## Rolling everything back

1. Revert the `agents` commit that added the vendored set.
2. Delete every symlink in `~/.claude/skills/`, `~/.cursor/skills/` and `~/.agents/skills/` that
   points into a `vendor/` directory that no longer exists. `install.sh` adds links and never
   prunes them, so this step is manual; a dangling symlink in a skills directory is a skill the
   agent cannot load rather than a silent no-op.
3. Re-run `bash install.sh` to confirm what remains, and `bash check-vendor.sh` to confirm the
   surviving sets still pass.

Rolling back ponytail is a different procedure, in the repo `README.md`: its hooks are wired into
three host configuration files and `wire-ponytail-hooks.sh --uninstall` is what removes them.
