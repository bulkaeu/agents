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

Also check the plan itself: any row still `⬜` or `🟡` after the work is done is either an unfinished
step or a stale table. Both need resolving before the plan can close.

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
