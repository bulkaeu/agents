# plan-finish — audit commands

Per-area commands for [SKILL.md](SKILL.md). All read-only; nothing here mutates a repo.

## Area 1 — Scope

```bash
git rev-parse --show-toplevel            # is this even a repo?
git worktree list --porcelain            # other trees holding work from this plan
git branch --show-current
```

A plan that names paths in several repos needs one pass per repo. Run every later area once per repo
and label the report by repo when there is more than one.

## Area 2 — Checks

**Enumerate before running.** Do not assume the usual four scripts exist; read the project's own
manifest and run everything CI runs.

```bash
# JS/TS — list what actually exists, then run each
cat package.json | python3 -c 'import json,sys;print("\n".join(json.load(sys.stdin).get("scripts",{})))'
```

| Ecosystem | Where the scripts are | Typical full suite |
| --- | --- | --- |
| JS/TS | `package.json` → `scripts` | `type`/`type-check`, `format:check`, `lint`, `test`, `build` |
| Rust | `Cargo.toml`, CI config | `cargo fmt --check`, `cargo clippy`, `cargo test`, `cargo build` |
| Go | `Makefile`, CI config | `gofmt -l .`, `go vet ./...`, `go test ./...`, `go build ./...` |
| Python | `pyproject.toml`, `tox.ini` | `ruff format --check`, `ruff check`, `mypy`, `pytest` |
| Make-driven | `Makefile` targets | `make check` or the individual targets it calls |
| Shell / docs | no manifest at all | `bash -n` each tracked script, `shellcheck`, any installer's `--dry-run`; formatter only if one is configured |

**No manifest is not no checks.** A repo of shell and markdown still has a runnable suite — syntax
checks, a linter, an idempotent script's dry run. Run what exists and name it. Report "no project
suite" as a finding about the *repo*, never as a reason the Checks row is green by default.

**`format:check` is its own step.** Where ESLint loads `eslint-plugin-prettier`, formatting shows up
as a lint error *for the files ESLint parses* — which makes it easy to believe `lint` covers
formatting. It does not: `format:check` usually also globs `.md` and `.json`, which ESLint never
parses. Any change touching markdown or JSON — README, AGENTS.md, `docs/*.md` — needs
`format:check` even when lint is green.

Report each check by name with its real output. A check that could not run (no such script, missing
tooling) is reported as **not run**, never folded into a green summary.

## Area 3 — Commits

```bash
git status --porcelain                        # modified + untracked
git stash list                                # work parked and forgotten
git log --oneline -5                          # what landed
```

Unpushed commits, without erroring on a branch that has no upstream:

```bash
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  git log --oneline '@{u}..'
elif git rev-parse origin/HEAD >/dev/null 2>&1; then
  git log --oneline origin/HEAD..
else
  echo "no upstream — nothing is pushed"
fi
```

Untracked files split three ways: **build output** (should be gitignored), **scratch** (should be
deleted, see area 5), and **real work** (should be committed). Classify rather than lumping them.

## Area 4 — Docs

```bash
git diff --name-only <plan-start>..HEAD       # or main..HEAD
```

For each changed module, command, flag, or env var name, grep the docs for it:

```bash
grep -rn "<name>" README.md AGENTS.md CLAUDE.md docs/ 2>/dev/null
```

Drift is a doc that names something the diff **renamed or removed**, or a documented command whose
flags changed. A doc that simply does not mention new internals is not drift — do not manufacture
work.

### The plan's own table is a doc too

Two different questions, and the second is the one that finds things:

1. **Is every row resolved?** A row still `⬜`/`🟡` after the work is done is an unfinished step or a
   stale table.
2. **Does every commit have a row?** Walk the commits the work produced and check each is accounted
   for:

   ```bash
   git log --reverse --format='%h %s' <plan-start>..HEAD | while read -r c rest; do
     grep -q "$c" "<plan-file>" && echo "ok   $c" || echo "MISS $c  $rest"
   done
   ```

   A commit with no row is work that happened and was never recorded — invisible to the first
   question, because the rows that *do* exist are all ticked. Watch for the near-miss too: a row
   describing the work but naming no hash, which happens when the row is written before the commit.

**Re-read the plan from disk before auditing it.** Do not audit a copy carried in context from
earlier in the session — it may predate edits made since, and you will report a defect that was
already fixed, or miss one that was introduced.

### The ticket is a doc too

If the plan carries a `**Ticket:**` line with an identifier, read that issue and compare:

| Plan says | Ticket says | Finding |
| --- | --- | --- |
| every row `✅` | still open / In Progress | Drift — the work is done and the tracker does not know |
| rows still `⬜`/`🟡` | closed | Drift the other way — closed early, or the plan is stale |
| `**Ticket:** none` | — | Nothing to check |
| no `**Ticket:**` line | — | Predates the rule. Note it; do not retro-file |

**Report only.** Moving, closing, or reassigning an issue is a destructive edit and stays gated on an
explicit yes — `plan-ticket-tracking.md` owns that boundary. Propose the transition and the command;
do not perform it as part of the audit.

## Area 5 — Cleanup

```bash
git branch --merged | grep -vE '^\*|main|master|develop'   # candidates only
git worktree list --porcelain
git worktree prune --dry-run
find . -name '*.orig' -o -name '*.rej' -not -path './.git/*'
```

Plus scratch the plan itself names — throwaway scripts, dumps, fixture files — and anything left in
the session scratchpad that was meant to be temporary.

**Candidates, not conclusions.** `--merged` lists branches merged into the *current* branch, which
is not the same as merged to the default branch or merged upstream. Verify before proposing a
deletion, and never propose deleting an unmerged branch at all.

Worktrees come out before the branches they hold:

```bash
git worktree remove <path>     # then the branch, separately confirmed
```
