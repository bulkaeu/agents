# plan-finish — audit commands

Per-area commands for [SKILL.md](SKILL.md), in its audit numbering. Nothing here mutates a repo.

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
# Shell / docs — list the root's scripts and the tracked ones, then run each check among them
ls ./*.sh; git ls-files '*.sh'
git ls-files -z '*.sh' | LC_ALL="$(locale -a | grep -iEm1 'utf-?8$')" xargs -0 shellcheck -S warning
```

| Ecosystem | Where the scripts are | Typical full suite |
| --- | --- | --- |
| JS/TS | `package.json` → `scripts` | `type`/`type-check`, `format:check`, `lint`, `test`, `build` |
| Rust | `Cargo.toml`, CI config | `cargo fmt --check`, `cargo clippy`, `cargo test`, `cargo build` |
| Go | `Makefile`, CI config | `gofmt -l .`, `go vet ./...`, `go test ./...`, `go build ./...` |
| Python | `pyproject.toml`, `tox.ini` | `ruff format --check`, `ruff check`, `mypy`, `pytest` |
| Make-driven | `Makefile` targets | `make check` or the individual targets it calls |
| Shell / docs | no manifest at all | **every check script at the repository root** — `check-*.sh`, `sanitize-check.sh`, whatever the root holds; list them rather than assume. `bash -n` each tracked script, and `shellcheck -S warning` on each (not bare `shellcheck`, whose default level also fails on info and style notes that flag intentional patterns), run with `LC_ALL` set to a UTF8 locale available on the host (`locale -a` lists them) — under the default `C`/`POSIX` locale it can crash printing non-ASCII output from the scripts. Any installer's `--dry-run`; formatter only if one is configured |

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

## Area 3 — Verification

Re-read the plan from disk and find its `## Verification` section. **No section reports *none*, not
green** — a plan with no items has passed nothing. For each item, look for a recorded result first:

```bash
grep -n "<the item's command or number>" "<plan-file>"   # a Progress row whose Notes record it
```

- **Recorded** — a row's Notes hold the item's result: report it from that row, citing the row id
  ("PASS, recorded in row B3's Notes"). **Do not re-run it**; its fixtures may be gone by design.
- **Not recorded** — run it now: PASS or FAIL, with its real output (exit code, count, failing lines).
- **A FAIL on one of the repository's own checks** belongs to area 2: fix an obvious cause, re-run,
  and report the re-run's result here, citing the fix. **Any other FAIL is reported, never fixed** —
  a finding for the plan's own rows or `/plan-continue`, not work for this skill.

## Area 4 — Commits

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
deleted, see area 6), and **real work** (should be committed). Classify rather than lumping them.

## Area 5 — Docs

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
2. **Do the commits and the rows account for each other?** An audit both ways. *Every commit in the
   work's range has a row:*

   ```bash
   git log --reverse --format='%h %s' <plan-start>..HEAD | while read -r c rest; do
     grep -q "$c" "<plan-file>" && echo "ok   $c" || echo "MISS $c  $rest"
   done
   ```

   A commit with no row is work that happened and was never recorded — invisible to the first
   question, because the rows that *do* exist are all ticked. Watch for the near-miss too: a row
   describing the work but naming no hash, which happens when the row is written before the commit.
   **A MISS is a question, not a verdict**: where several agents or plans commit, read the MISSed
   commit first (`git show --stat`). Another plan's commit is excluded, not backfilled — a row for
   it would misattribute their work to this plan. Only this plan's work with no row is the defect.

   *The other way, every sha a row claims resolves* — the claims audit below checks that side.

### Claims audit — what the table cites, against git and disk

```bash
run_dir="$(bash "${CLAUDE_SKILL_DIR}/../plan-build/scripts/row-snapshot.sh" dir "<plan-file>")"
bash "${CLAUDE_SKILL_DIR}/../plan-shared/scripts/table-claims.sh" "<plan-file>" \
  --repo <repo> [--repo <repo>]... --root "$run_dir"
```

Every repository in scope is a `--repo`; the run directory (`row-snapshot.sh dir` prints it) is a
`--root`, so cited review files resolve. A `--root` replaces the default, the plan repo's parent —
pass that too if Notes cite paths relative to it. **Each MISSING is a question, not a verdict**: a
path a row deleted or moved is meant to be absent. A claimed sha or path really absent is drift.

**Re-read the plan from disk before auditing it.** Do not audit a copy carried in context from
earlier in the session — it may predate edits made since, and you will report a defect that was
already fixed, or miss one that was introduced.

### The ticket is a doc too

If the plan carries a `**Ticket:**` line with an identifier, read that issue and compare:

| Plan says | Ticket says | Finding |
| --- | --- | --- |
| every row `✅` | still open / In Progress | Drift — the work is done and the tracker does not know |
| rows still `⬜`/`🟡` | closed | Drift the other way — closed early, or the plan is stale |
| plan has a `## Summary` — **any row state** | description no longer matches the Summary | Drift — the plan's story moved and the tracker still tells the old one; mid-flight drift is the worst kind, since it stands for the rest of the run. **Report-only**: propose the description update; applying it follows `plan-ticket-tracking.md`'s sync line |
| `**Ticket:** none` | — | Nothing to check |
| no `**Ticket:**` line | — | Predates the rule. Note it; do not retro-file |

**Report only.** Moving, closing, or reassigning an issue is a destructive edit and stays gated on an
explicit yes — `plan-ticket-tracking.md` owns that boundary. Propose the transition and the command;
do not perform it as part of the audit.

## Area 6 — Cleanup

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

## Report — evidence per area

The Detail cell of `SKILL.md`'s area table carries the evidence: for each area, the command(s) run
and what they printed — counts, exit codes, failing lines — so a green row can be audited later. A
check not run is written *not run*, with the reason. The icon sits in the Status cell, never first:

```markdown
| Area | Status | Detail |
| ---- | ------ | ------ |
| Checks | ✅ | `bash check-plan-skills.sh` → `ok — 16 checks`, exit 0 · `shellcheck -S warning` 6 scripts, exit 0 · formatter *not run* — none configured |
| Verification | ✅ | 2 items · 1: PASS recorded in row B3's Notes, not re-run · 2: PASS run now, `bash check.sh` exit 0 |
| Commits | ✅ | `git status --porcelain` 0 lines · `git log '@{u}..'` 0 commits |
| Docs | ✅ | commit walk 9 ok, 1 MISS (another plan's, excluded) · `table-claims.sh` → `shas ok 9 missing 0 · paths ok 14 missing 1` — deleted by row C2 |
```
