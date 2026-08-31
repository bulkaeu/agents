# agents

Skills and rules shared by every coding agent I use — Claude Code, Cursor, and anything that reads
`~/.agents/skills/`. This repo is the **single source of truth**: each agent directory holds a
symlink pointing here, so editing a file in this checkout changes what every agent loads, with no
copy step and nothing to keep in sync.

## Layout

```
skills/     one directory per skill, each with a SKILL.md
rules/      always-apply rules, one .md each
claude/     CLAUDE.md — global instructions for Claude Code
install.sh  links all of the above into ~/.claude, ~/.cursor and ~/.agents
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
| `plan-finish` | Checks a plan is genuinely done: full check suite, nothing uncommitted or unpushed, docs current, workspace cleaned up. Audits first, acts only on approval. |
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
- **Rules stay short.** Under ~50 lines. State the failure mode, not just the rule, and say which
  sibling rule owns the neighbouring concern so the two never drift into contradiction.
- **Keep the frontmatter.** `alwaysApply: true` on rules is what makes Cursor load them; Claude
  ignores it harmlessly.
- **Edit the repo copy, never a symlink.**

## Sanitization

**This repo is public.** Nothing here may name a private workspace's repo layout, hostnames, bucket
names, ticket prefixes, or absolute paths. Before pushing:

```bash
git ls-files -z | xargs -0 grep -niE 'TAP-[0-9]+|/Users/|gitlab\.com/'
```

`~/.claude/settings.json` is deliberately **not** in this repo — it carries org-internal hosts and
inventory paths. `skills/migrate/examples/tap-api-v1-to-v2.md` is a filled profile for a private
workspace; it is gitignored and stays local. The generic worked example that ships instead is
`skills/migrate/examples/express-v1-to-nest-v2.md`.
