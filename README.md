# agents

Skills and rules shared by every coding agent I use — Claude Code, Cursor, and anything that reads
`~/.agents/skills/`. This repo is the **single source of truth**: each agent directory holds a
symlink pointing here, so editing a file in this checkout changes what every agent loads, with no
copy step and nothing to keep in sync.

## Layout

```
skills/            one directory per skill, each with a SKILL.md
rules/             always-apply rules, one .md each
claude/            CLAUDE.md — global instructions for Claude Code
install.sh         links all of the above into ~/.claude, ~/.cursor and ~/.agents
sanitize-check.sh  refuses to publish private identifiers — see Sanitization
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
| `~/.claude/rules/<name>.md` | `rules/<name>.md` |
| `~/.cursor/rules/<name>.mdc` | `rules/<name>.md` |
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |

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
| `plan-summary` | One-page summary of a plan: what, how, and — from its Progress table — exactly where it stands. Read-only. |
| `plan-finish` | Finishes a plan: audits the check suite, commit state, docs, cleanup and plan state — then fixes what it found and reports what it did. Stops only for destructive, gated, or ambiguous work. |
| `plan-review` | Reviews and refines a plan until only Very Low findings remain. |
| `verify-changes` | Stages conversation-related changes, runs code review per repo, summarizes. |
| `migrate` | Ports HTTP endpoints or cron jobs between two codebases, driven by a per-project profile. |
| `update-js-libs` | Updates npm/yarn/pnpm dependencies, classifies the bumps, runs the project's checks. |

## Rules

Every `.md` in `rules/` is loaded automatically by both agents, always-apply. They are deliberately
short and each one owns exactly one thing.

| Rule | Owns |
| --- | --- |
| `plan-progress-section.md` | Every plan opens with a `## Progress` table, and how it is kept current |
| `plan-ticket-tracking.md` | Whether a plan is tracked in an issue tracker, and how the answer is recorded |
| `plan-atomic-todos.md` | How finely a plan step is cut |
| `no-plan-copies.md` | One topic, one plan file |
| `plan-mode-edit-plans.md` | Plan files are edited without asking permission |
| `ui-rendered-files-use-write-tool.md` | Which tool writes a file the UI renders |
| `migration-apply-confirmation.md` | Database migrations are never applied without an explicit yes |

## Contributing to this repo

- **Keep `SKILL.md` under ~200 lines.** Detail goes in a sibling `.md` linked from it —
  `plan-finish/CHECKLIST.md`, `migrate/RULES.md`. One level of references, no deeper.
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
