# plan-finish — the footprint audit

Area 6 of [SKILL.md](SKILL.md)'s audit, in five steps: measure, classify, check for only copies,
re-check the docs, report. A run leaves more than commits behind — scratch, captures, toolchains,
worktrees, branches, background processes — and none of it shows in `git status`. A close-out that
reports the clean-up done without measuring it leaves gigabytes on disk that only the user finds.
So every item is measured, every deletion is sized, and whatever needs a yes is asked once.

**What a run leaves to read.** `plan-build` puts temporary files under `<run directory>/scratch/`,
writes a Run log line `created: <path or process> — <what>` for anything else that outlives its row
outside the repositories and that directory, and records `disk: <N> GiB free` in the Run log header. A plan
run before those existed has none of them: measure what can still be found — the run directory, the
session scratchpad, worktrees, branches, `*.orig`/`*.rej` — and report the baseline as
*not recorded*. Never guess what an unrecorded path was for.

`${CLAUDE_SKILL_DIR}` is `plan-finish/`; where unset, the same relative path from this file's directory.

## 1. Measure

Size with `du -sh` and count with `find … | wc -l`, for each item below. Read the plan from disk
first. Its Run log is the source of the `created:` and `disk:` lines — and so is
`<plan stem>-history.md` beside it, where `plan-add` moves finished runs' Run log headers with their
lines once a plan grows long. Shell state does not survive between calls, so each snippet that
reads them names the plan itself and derives the history file, read first: run a snippet whole.

**The run directory**, in three parts — `scratch/`, the records, and media or binaries over 1 MB:

```bash
plan="<plan-file>"; hist="${plan%.md}-history.md"; [ -f "$hist" ] || hist=/dev/null
run_dir="$(bash "${CLAUDE_SKILL_DIR}/../plan-build/scripts/row-snapshot.sh" dir "$plan")"
du -sh "$run_dir/scratch"; find "$run_dir/scratch" -type f | wc -l                   # scratch
records='md|patch|diff|txt|log|json|jsonl|out|err|tsv|csv|list|ya?ml|sh'
notes="$(grep -h '^|' "$hist" "$plan")"             # Progress-table lines: where rows' Notes are
parts="$(find "$run_dir" -path "$run_dir/scratch" -prune -o -type f -print |
  while read -r f; do kb=$(du -k "$f" | cut -f1); class=record
    if [ "$kb" -gt 1024 ] && ! printf '%s\n' "$f" | grep -qiE "\.($records)\$"; then
      case "$notes" in (*"${f#"$run_dir"/}"*) class=cited-media ;; (*) class=uncited-media ;; esac
    fi; printf '%s\t%s\t%s\n' "$class" "$kb" "$f"; done)"
printf '%s\n' "$parts" | awk -F'\t' 'NF { n[$1]++; k[$1] += $2 }
  END { for (c in n) printf "%s: %d files, %.1f MiB\n", c, n[c], k[c] / 1024 }'
printf '%s\n' "$parts" | awk -F'\t' '$1 ~ /media$/ { printf "%s  %.1f MiB  %s\n", $1, $2 / 1024, $3 }'
```

The record types are named; a file over 1 MB of any other type — an image, a capture, an app's
executable, a library, a file with no extension — is media or a binary, asked about, never kept
unseen. A check record is a log, JSON or text file of any size, and stays a record. **The records**
— briefs, reports, reviews, diffs, check records, small files of any type — are the `record` line.
Media is cited only when a Progress-table line holds its path relative to the run directory: a build
named after the product would match a bare name in the plan's title. Cited media is kept, and listed.

**The session scratchpad** — the path the session's environment names: `du -sh` it, and list what
this run put there. Add scratch the plan itself names — throwaway scripts, dumps, fixture files.

**Every `created:` path**, from the Run log and the whole history file. Only a line that *is* a
`created:` entry counts; the value is cut at the *first* ` — ` because the description may hold
another, its backticks are stripped and a leading `~/` is expanded, as `row-snapshot.sh` does for
its `run dir:` line — a home folder written `~/…` is the very case this audit exists for:

```bash
plan="<plan-file>"; hist="${plan%.md}-history.md"; [ -f "$hist" ] || hist=/dev/null
log_lines() { awk -v key="$1" -v home="$HOME" '
  FNR == 1 { h = (FILENAME ~ /-history\.md$/); in_log = 0 }
  /^## / { in_log = ($0 ~ /^## Run log[ \t]*$/); next }
  (h || in_log) && sub("^([-*][ \t]+)?" key ":[ \t]+", "") { gsub(/`/, ""); sub(/ — .*/, "")
    sub(/[ \t]+$/, ""); if (substr($0, 1, 2) == "~/") $0 = home substr($0, 2); print }' "$hist" "$plan"; }
log_lines created          # one path or process per line
log_lines disk | head -1   # the earliest run's baseline, for step 5
```

`du -sh` each path that exists; a missing one is reported *already gone*. **A `created:` path inside
the run directory is counted once, as part of the run directory**, never a second time as its own
item. The Run log rule asks for no such line; older runs wrote some.

**Worktrees this plan made** — a `created:` line, or a worktree on a branch the plan made:

```bash
git worktree list --porcelain
git worktree prune --dry-run
git -C <worktree> status --porcelain | wc -l                      # 0 is a clean tree
git -C <worktree> log --oneline '@{u}..' 2>/dev/null || echo "no upstream — every commit unpushed"
```

**Branches this plan made that are merged upstream**, local and remote, after a fetch:

```bash
git fetch --prune origin
default="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
[ -n "$default" ] ||   # origin/HEAD unset in this clone: ask the remote, read-only
  default="$(git ls-remote --symref origin HEAD | awk '/^ref:/ { sub("refs/heads/", "", $2); print $2 }')"
git branch --merged "origin/$default" | grep -vE '^\*|^[ +] (main|master|develop)$'   # candidates only
git branch -r --merged "origin/$default" | grep -vE "origin/(HEAD|$default)( |$)"      # candidates only
```

**Candidates, not conclusions.** A bare `git branch --merged` lists branches merged into the
*current* branch, not the default branch or upstream; that is why both lines name
`origin/<default>`. Verify each candidate is one this plan made, from its Run log or its rows. A
squash-merged branch is not listed: treat it as unmerged. Never propose deleting an unmerged branch.

**Merge leftovers**, in every repository in scope:

```bash
find . \( -name '*.orig' -o -name '*.rej' \) -not -path './.git/*'
```

**Background processes** a `created:` line names, still alive:

```bash
ps -p <pid> -o pid=,etime=,command=      # no output: it has exited
```

Without a recorded pid, `pgrep -fl '<the command the line names>'` finds candidates — compare each
one's command and start time against the line before calling it this run's.

## 2. Classify

Each measured item goes into exactly one of three. The [stop-list](../plan-shared/STOPS.md) binds
every deletion here; this list sorts items, it does not widen what may be deleted.

**Delete now** — reversible and local, and made by this plan:

- `<run directory>/scratch/`;
- session scratch this run made;
- `*.orig`/`*.rej` this run made;
- a local branch the plan made, verified merged into `origin/<default>`;
- a worktree the plan made, with a clean tree and nothing unpushed;
- its own background processes.

Worktrees come out before the branches they hold, or git refuses the branch and leaves a dangling
registration:

```bash
git worktree remove <path>          # then the branch
git branch -d <branch>              # -d, never -D: git re-checks the merge
kill <pid>                          # only a pid a created: line names and ps confirmed
```

**Ask once, in the batch question**, each item with its size and exact command:

- uncited media in the run directory;
- every toolchain, cache or home-directory folder from a `created:` line;
- a remote branch — its deletion is on the stop-list (`git push origin --delete <branch>`);
- anything this plan did not make — also on the stop-list.

These go into `plan-finish`'s one batch question, where one approval covers the batch
(`STOPS.md`, *Asked alone*). A yes covers the items shown and no others.

**Keep:**

- the run directory's records — briefs, reports, reviews, diffs, check records — which later audits
  and the claims audit (`CHECKLIST.md`, area 5) cite;
- every deliverable. A file a row exists to create is never scratch, wherever it sits.

## 3. Only-copy check

Before deleting anything, look for the only copy of something a row's Notes cite:

```bash
grep -nF "<basename or path of the item>" "<plan-file>"
```

An item the Notes cite with no durable copy elsewhere — committed in a repository, or in the
project's documented asset or media home — is not scratch. It is kept, and reported with where its
durable copy should live. Deleting it would leave a row whose evidence no longer exists.

## 4. Re-check the docs

After a removal, grep the docs that describe what was removed — an inventory, a tools guide, a
README — for its path or name, under area 5 ([CHECKLIST.md](CHECKLIST.md), *Area 5 — Docs*):

```bash
grep -rn "<removed path or name>" README.md AGENTS.md CLAUDE.md docs/ 2>/dev/null
```

A line still describing the removed item as present is drift: fix it with area 5's other fixes.

## 5. Report

A footprint table, one row per measured item, then one disk line. The action is *deleted*,
*asked* or *kept*, with the reason for anything kept or asked:

```markdown
| Item | Size | Action |
| ---- | ---- | ------ |
| run directory `scratch/` (212 files) | 2.4 GB | deleted |
| run directory records (96 files) | 18 MB | kept — the run's records |
| `rows/D3/capture-04.png`, uncited | 6.1 MB | asked — `rm <path>` |
| toolchain folder from `created:` | 1.5 GB | asked — `rm -rf <path>` |
| worktree `<repo>-wt-<name>`, clean, pushed | 140 MB | deleted |
| background process `<pid>` from `created:` | — | deleted — `kill <pid>` |
```

Then the disk line: `df -Pk "$HOME"`, Available in KiB ÷ 1048576, against the earliest `disk:` line (step 1):

```text
disk: <F> GiB free now · <B> GiB at the run's start · <B−F> GiB less, <P> GiB of it this plan's
```

`<P>` is the sum of what this plan made and is still on disk after the deletions — kept and asked
items. Without a `disk:` line, the start is *not recorded* and the line gives free space now alone.
