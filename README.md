# agents

Skills and rules shared by every coding agent I use — Claude Code, Cursor, and anything that reads
`~/.agents/skills/`. This repo is the **single source of truth**: each agent directory holds a
symlink pointing here, so editing a file in this checkout changes what every agent loads, with no
copy step and nothing to keep in sync.

## Layout

```
skills/            one directory per skill, each with a SKILL.md
skills/plan-shared/  files the plan-* skills share — not a skill, so no SKILL.md
rules/             always-apply rules, one .md each
claude/            CLAUDE.md — global instructions for Claude Code
vendor/<name>/     pinned copies of other people's skill sets — see Vendored skills
install.sh         links all of the above into ~/.claude, ~/.cursor and ~/.agents
sanitize-check.sh  refuses to publish private identifiers — see Sanitization
check-plan-skills.sh  static checks for the plan-* skills — see Contributing
.sanitize-allow    tracked: strings that legitimately look private (placeholders, boilerplate)
.sanitize-terms    gitignored: the names this checkout must not publish
```

## Install

```bash
git clone https://github.com/bulkaeu/agents.git ~/projects/agents
bash ~/projects/agents/install.sh
```

`--dry-run` says what it would do and changes nothing. Run it again any time you add a skill or a
rule; it only touches what is missing or wrong.

What it creates:

| Link | Target |
| --- | --- |
| `~/.claude/skills/<name>` | `skills/<name>` |
| `~/.cursor/skills/<name>` | `skills/<name>` |
| `~/.agents/skills/<name>` | `skills/<name>` |
| `~/.claude/skills/<dir>` | `vendor/<set>/skills/<dir>` |
| `~/.cursor/skills/<dir>` | `vendor/<set>/skills/<dir>` |
| `~/.agents/skills/<dir>` | `vendor/<set>/skills/<dir>` |
| `~/.claude/rules/<name>.md` | `rules/<name>.md` |
| `~/.cursor/rules/<name>.mdc` | `rules/<name>.md` |
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |
| `~/.codex/AGENTS.md` | `claude/CLAUDE.md` |

Cursor requires the `.mdc` extension for rules; a `.mdc` symlink pointing at a `.md` file works
fine, which is what lets one file serve both agents.

**It never overwrites anything.** A path already linked correctly is skipped. A path holding real
content is displaced only if it is byte-identical to the repo copy, and then it is *moved* to
`~/.agents-config-backup-<date>/` rather than deleted. Anything that differs is reported with a diff
and left alone — reconcile it yourself and re-run. A symlink pointing somewhere else is relinked,
with its old target recorded in that backup root's `relinked.txt`.

Rollback is one move per item:

```bash
rm ~/.claude/skills/<name>
mv ~/.agents-config-backup-<date>/claude/skills/<name> ~/.claude/skills/
```

## Skills

Invoke with `/<name>`. All of these set `disable-model-invocation: true` except `update-js-libs`, so
they run when asked for and not on a guess.

| Skill | What it does |
| --- | --- |
| `plan-status` | One glance at a plan: the step in flight, the done count, the working copy, the next few steps, anything blocked. At most twelve lines. Read-only. |
| `plan-build` | Runs a plan that has not started, first row to last, without stopping for ordinary work. Each code row is built by a fresh implementer subagent and checked by a separate reviewer subagent that did not write it (`DISPATCH.md`, two prompt files, `scripts/row-snapshot.sh`); the run ends with a review of its whole diff. Parks what is gated, asks about the whole parked set once at the end, then applies `plan-finish`'s checklist. `--dry-run` rehearses and prints the dispatch count. |
| `plan-continue` | Resumes a part-done plan: reconciles its Progress table against the repositories and disk (`table-claims.sh`), repairs what drifted, hands partial work to a fresh implementer, then runs the rest as `plan-build` does. Reads `RULES.md`, `EXECUTION.md` and `DISPATCH.md` from the sibling `plan-build` directory — it needs that skill installed. |
| `plan-summary` | Summary of a plan: its own plain-language Summary in full, a technical twin, and its recent + upcoming Progress steps (windowed only past 10 rows). Read-only. |
| `plan-finish` | Finishes a plan: audits the check suite, the plan's own Verification items, commit state, docs, and cleanup — then fixes what it found and reports what it did, stopping only for work that is destructive, gated, ambiguous, or not its own to delete. It reports a plan's open rows rather than running them, pointing at `/plan-continue`; a Verification area reports each item's recorded result or runs it live, reporting a FAIL rather than fixing it. The verdict separates open, parked, and stop-list items; commits carry the plan's ticket id; and work no reviewer saw is named. Its checklist (`CHECKLIST.md`) holds the per-area commands, including a claims audit with `table-claims.sh`. |
| `plan-add` | Adds new scope to the plan that already exists, instead of starting a second file for the same topic: resolves the plan — creating one when the invocation names a path that is not there, or when the user takes the new-plan offer on a list it stops at — grounds an addition that touches code in an `Explore` run first, and writes the new steps as atomic rows placed where they will actually run rather than appended at the end. A closed row is reopened only on one of three evidence tests (`MATCHING.md`), keeping its original result in the Notes beside the reason and the id of the row that caused it; if the plan looks mid-run, it prints the intended reopens and waits for a yes. It authors and never executes, ending at `/plan-build` or `/plan-continue` — and applies `plan-review`'s cycle inline, because a skill cannot invoke a sibling that sets `disable-model-invocation: true`. |
| `plan-review` | Reviews and refines a plan until nothing above Very Low remains, then fixes the remaining nits in a closing pass — only deliberate tradeoffs stay, with reasons. Round 1 is run by a reviewer subagent it dispatches, which did not write the plan (`reviewer-prompt.md`); later rounds are scoped re-checks in-thread against the same checklist (`checklist.md`), which also checks whether a plan can be executed unattended: its markers, done-states, failable Verification and scope cuts. Every finding is CONFIRMED with a quote or marked UNVERIFIED, and a stall rule stops the loop if findings stop moving. `/code-review` is an optional extra pass whose mode is logged, never the source of independence. |
| `verify-changes` | Stages conversation-related changes, runs code review per repo, summarizes. |
| `migrate` | Ports HTTP endpoints or cron jobs between two codebases, driven by a per-project profile. |
| `update-js-libs` | Updates npm/yarn/pnpm dependencies, classifies the bumps, runs the project's checks. |
| `12factor` | Audits a project against the Twelve-Factor App methodology: grades all 12 factors with file-level evidence and fixes, report in chat. |

`skills/plan-shared/` is not a command. It holds what the seven `plan-*` skills share, each in one
place: `STOPS.md` (the stop-list), `CONVENTIONS.md` (how a plan is found and read, the severity
scale) and `scripts/table-claims.sh` (checks a Progress table's shas and paths against git and
disk). `install.sh` links it beside the skills, which is what lets them reach it.

Thirty-six vendored third-party skills are linked beside these and are not listed above;
[`vendor/README.md`](vendor/README.md) is the catalogue for the thirty in the skills-only sets, and
ponytail's six have their own section. See Vendored skills.

## Rules

Every `.md` in `rules/` is loaded automatically by both agents, always-apply. They are deliberately
short and each one owns exactly one thing.

| Rule | Owns |
| --- | --- |
| `plan-progress-section.md` | Every plan opens with a plain-language Summary and a `## Progress` table, and how both are kept current |
| `plan-ticket-tracking.md` | Whether a plan is tracked in an issue tracker, and how the answer is recorded |
| `plan-atomic-todos.md` | How finely a plan step is cut |
| `plan-yaml-frontmatter.md` | After plan edits, YAML-parse Cursor frontmatter before claiming todos are healthy |
| `no-plan-copies.md` | One topic, one plan file |
| `plans-live-in-a-plans-repo.md` | Where plan documents live and how they are published |
| `plan-mode-edit-plans.md` | Plan files are edited without asking permission — and what the harness's own permission gate does to that |
| `ui-rendered-files-use-write-tool.md` | Which tool writes a file the UI renders |
| `file-links-must-resolve.md` | How a file reference is written so the link resolves from the UI's project root |
| `shared-state-between-agents.md` | Concurrency between agent sessions sharing one checkout, branch, or pull request |
| `migration-apply-confirmation.md` | Database migrations are never applied without an explicit yes |
| `third-party-skills.md` | How a third-party skill interacts with the rules here — which side wins on each disagreement, and the six skills that are meant to be on demand only |

## Vendored skills

`vendor/` holds nine pinned copies of other people's skill sets — 36 skills in all. Each set's
`vendor/<name>/UPSTREAM` records the upstream repo, the ref asked for and the resolved 40-hex sha;
that sha identifies the tree exactly (check it out upstream to see what was vendored), but
`update-vendor.sh <name> [<ref>]` takes a branch or tag, never a sha — three sets record
`ref: main`, so a bare re-pin takes whatever `main` points at then and writes a new sha. They are
vendored rather than installed as plugins so that every upgrade is a reviewed diff, and so that no
upstream hook or marketplace wiring arrives with them. Four skills ship an upstream
`agents/openai.yaml` — OpenAI/Codex metadata rather than an agent definition, though `iterate-pr`'s
also carries a `policy:` block opting into implicit invocation. The files sit *inside* the linked
directories, so they do arrive at `~/.agents/skills/<dir>/agents/`; what keeps them inert is that no
host used here reads an OpenAI interface file out of a skill directory — whether one that did would
honour that `policy` key is unverified. No upstream agent arrives at all: the
two that `differential-review` and `sharp-edges` dispatch are parts of an upstream *plugin*, so
those dispatches fail at runtime (the catalogue has the detail). Ponytail's hooks are the one set
that is wired, explicitly, by `wire-ponytail-hooks.sh`. `install.sh` links each
`vendor/*/skills/<dir>` into the same three places as `skills/*`, by **directory** name.

- `vendor/ponytail/` — 6 skills **and hooks**, the only set with any; it has its own scripts and
  its own section below.
- Eight skills-only sets, 30 skills: superpowers (15), getsentry (4), hashicorp (4), trailofbits
  (3), anthropics (1), playwright-cli (1), supabase (1), vercel (1).

**[`vendor/README.md`](vendor/README.md) is the catalogue** — one entry per skill in the eight
skills-only sets (what it fires on, what it writes or runs, what it pre-approves, which of our rules
modify it), the six skills that are meant to be on demand only, what was deliberately not adopted,
and the per-source bump, per-skill removal and whole-set rollback procedures. It deliberately does
not cover ponytail, which has its own section below. `rules/third-party-skills.md` is the
always-apply rule those skills defer to.

| Command | What it does |
| --- | --- |
| `bash update-vendor.sh <name> [<ref>]` | Re-pins one of the eight skills-only sets: copies exactly the `path:` lines in `vendor/<name>/SOURCE` and nothing else, replaces `skills/` and `LICENSE` wholesale so a file deleted upstream goes too, rewrites `UPSTREAM`, then runs `check-vendor.sh` and `sanitize-check.sh`. With no `<ref>` it re-pins the ref recorded in `SOURCE`; with one it uses that tag or branch and leaves `SOURCE` alone |
| `bash check-vendor.sh [--root <dir>]` | Read-only checks across every set: P1, no vendored directory name or frontmatter `name:` shadows one of our skills, another vendored skill, or a skill Claude Code ships itself; P5, every populated set's `UPSTREAM` names a 40-hex sha. A `vendor/<name>/` with no `skills/` yet is skipped by name, not failed |

Neither update script ever commits, and **both refuse to run on `main` or in the main worktree** —
the installed symlinks point at the main checkout, so an update run there would go live before
anyone read the diff. Upgrade on a branch in a worktree, review the diff, then merge. Both share
the same exit codes: 0 updated and checks passed, 1 a structural check or the clone/copy failed,
2 refused or bad usage, 3 only `sanitize-check.sh` failed. `--help` prints their own header text.

## Vendored: ponytail

`vendor/ponytail/` is a pinned copy of the upstream
[ponytail](https://github.com/DietrichGebert/ponytail) hooks and six skills, and the hooks are why
it has its own scripts rather than going through `update-vendor.sh`. A plugin plus these hooks would
inject the ruleset twice: **never install the marketplace plugin.**

| Command | What it does |
| --- | --- |
| `bash update-ponytail.sh [<ref>]` | Copies an allow-listed set of files from the newest upstream `v*` tag (or `<ref>`) into `vendor/ponytail/`, rewrites `UPSTREAM`, then runs three checks — `check-ponytail.sh`, `check-vendor.sh` and `sanitize-check.sh`. Never commits. Exit 0 ok, 1 a structural check or the copy failed, 2 refused or bad usage, 3 only `sanitize-check.sh` failed |
| `bash check-ponytail.sh [--root <dir>]` | Read-only conflict checks P1–P5, ponytail-specific: its skills' names against ours, hook events, the mode tracker's gate, the subagent matcher variable, a pinned sha. It compares ponytail against `skills/*` only — `check-vendor.sh` is the script that sees every set, so that is what catches a collision between ponytail and another vendored set, or with a name Claude Code ships |
| `bash wire-ponytail-hooks.sh [--dry-run \| --uninstall]` | Adds (or refreshes) ponytail's entries in the Claude Code, Cursor and Codex hook files, leaving every other entry alone. Each target is copied to `<file>.bak-ponytail-<YYYYMMDD>` before its first write |

**Subagents.** On Claude Code the `SubagentStart` hook runs with
`PONYTAIL_SUBAGENT_MATCHER='^general-purpose$'`, so only implementer-type subagents get the
ruleset. Reviewers (`Explore`) must not: its "end your reply with one or two lines" instruction
would land after the `Verdict:` line the reviewer contract treats as the reply's last element, and
inside saved review files. Codex gets no `SubagentStart` hook at all: the hook fails open on an
unknown payload and Codex's agent-type names are not Claude's, so the matcher could not be trusted
there. Cursor has no subagent injection upstream.

**Upgrading.** Do it in this order:

1. Create a worktree on a new branch. `update-ponytail.sh` refuses to run on `main` or in the main
   worktree, because the hooks execute from the main checkout and an update run there would go live
   before anyone reviewed it.
2. `bash update-ponytail.sh <tag>`.
3. Read the diff. It is the review.
4. If `sanitize-check.sh` flags a new, harmless string (exit 3), add it to `.sanitize-allow`.
5. Commit, open a PR, merge.
6. In the main checkout, re-run `bash install.sh` only if a skill was added or removed upstream.

**Re-wiring.** Every hook command starts with the absolute `node` found at wiring time, because
GUI-launched hosts do not see a shell's `PATH`. If `node` moves, re-run `wire-ponytail-hooks.sh`
from the main checkout. Codex records trust against each hook's hash: after wiring, and after any
upgrade that changes a hook command, review and trust the hooks with `/hooks` in the Codex CLI
(the ChatGPT app bundles one at `/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex`),
and restart Codex.

## Contributing to this repo

- **Keep `SKILL.md` under ~200 lines.** Detail goes in a sibling `.md` linked from it —
  `plan-finish/CHECKLIST.md`, `migrate/RULES.md`. One level of references, no deeper. The
  exceptions are named here rather than left for a contributor to rediscover and mistake for drift,
  and each is a single hop into a sibling directory, never a chain. The `plan-*` skills read
  `plan-shared/`, where the conventions, the stop-list and the claims script each live once, and
  they read `plan-build`'s contract files — `RULES.md`, `EXECUTION.md`, `DISPATCH.md`,
  `scripts/row-snapshot.sh` and, for the concurrency check `plan-continue` defers to, `plan-build`'s
  own `SKILL.md` §2 — because the execution contract, the dispatch tiers and the run
  directory are written once for the whole family instead of copied into every skill that runs a
  plan. The close-outs reach sideways too: `plan-build`'s reads `plan-finish`'s files, and
  `plan-add`'s reads `plan-review`'s, because a skill cannot invoke a sibling that sets
  `disable-model-invocation: true`.
- **Run `bash check-plan-skills.sh` after touching any `plan-*` skill, `plan-shared/`, or the plan
  rules.** It checks line counts, frontmatter, that the ladder and stop-list live in one place,
  links, time-sensitive wording, the severity scale, `RULES.md`'s pinned headings, the dispatch
  prompts' status tokens and placeholders, and the standing orders, then runs `sanitize-check.sh`. `--root <dir>` points it at a copy of the repo.
- **Bundle a skill's helper scripts inside that skill** and resolve their paths at runtime. A
  hardcoded install path breaks the moment someone clones this somewhere else.
- **Rules stay short — most under ~50 lines.** A rule governing a recurring artifact (the Progress
  table, ticket tracking) earns more, but every line past that should be a failure mode, not a
  restatement. State the failure mode, not just the rule, and say which sibling rule owns the
  neighbouring concern so the two never drift into contradiction.
- **Keep the frontmatter.** `alwaysApply: true` on rules is what makes Cursor load them; Claude
  ignores it harmlessly.
- **Edit the repo copy, never a symlink.**

## Sanitization

**This repo is public.** Nothing here may name a private workspace, project, hostname, ticket
identifier, or absolute path. One command checks it:

```bash
bash sanitize-check.sh
```

It scans tracked files **and new files not yet staged** (`git ls-files -co --exclude-standard`).
Tracked-only would be a blind spot exactly where leaks arrive — a brand-new file is invisible to
`git ls-files` until it is staged, so the scan would pass right up to the moment the content became
committable. Ignored files are excluded, so a deliberately-local file does not trip it every run.

Three inputs:

| Input | Where | Published |
| --- | --- | --- |
| Generic shapes — home paths, tracker-style ids, a git host | built into the script | yes, and harmless |
| The actual names this checkout must not leak | `.sanitize-terms`, gitignored | no |
| Strings that legitimately *look* private | `.sanitize-allow`, tracked | yes |

`.sanitize-terms` is one extended-regex per line and is absent on a fresh clone — the generic check
still applies, and nobody else's machine needs the file. Keeping those terms out of a tracked file is
the point: a scan pattern that names the thing it protects publishes it.

`.sanitize-allow` is the opposite — fixed strings, one per line, for content that trips the generic
pattern but is not a leak: a documented placeholder like `ABC-123`, or Apache's `LICENSE-2.0`. It is
tracked, because it describes this repo's own content rather than anything private. Add to it only
when you have confirmed the match is genuinely harmless; it is the one file that can silence the
gate. The script also skips itself, since it necessarily contains every pattern it searches for.

`~/.claude/settings.json` is deliberately **not** in this repo — it carries org-internal hosts and
inventory paths. `skills/migrate/examples/tap-api-v1-to-v2.md` is a filled profile for a private
workspace; it is gitignored and stays local. The generic worked example that ships instead is
`skills/migrate/examples/express-v1-to-nest-v2.md`.
