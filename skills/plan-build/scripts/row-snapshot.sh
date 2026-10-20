#!/usr/bin/env bash
#
# Record where a row started, and package what it changed, once per repository in scope.
#
#   row-snapshot.sh dir  <plan.md>
#   row-snapshot.sh base <plan.md> <row-id> [--repo <dir>]...
#   row-snapshot.sh diff <plan.md> <row-id> [<ref>] [--repo <dir>]...
#
# dir   Print the run directory, ~/.claude/plan-runs/<plan stem>/, creating nothing: base and diff
#       create what they write. Everything a row produces (base, brief, report, diff, review)
#       lives there, outside every repository, so none of it can reach a commit.
# base  Per repo: record a commit holding the tree as it stands (`git stash create`, or HEAD when
#       the tree is clean) and copy every untracked file, which no commit holds. Never HEAD~1: a
#       row may make several commits. Use the row id `run` for the run base.
# diff  Write <run dir>/rows/<row-id>/diff-<n>.patch and print its path: one section per repo,
#       the tree against the recorded base, commits and uncommitted work alike. A file untracked at
#       base is diffed against its copy; a file new since base is shown in full, which plain
#       `git diff` omits. A fix round's diff is taken from the same base, so it shows the whole row.
#       With <ref>, diff against that ref instead (a stage review uses @{upstream}); every
#       untracked file is then shown in full, as it is with no recorded base.
#       With no recorded base, the row id `run` uses its merge-base with the remote default branch
#       (origin/HEAD, else origin/main), and any other row uses HEAD, its partial work being
#       uncommitted. The header names the base used.
#       Each repo's header, and one stderr line, give its status: `changed` (it has hunks),
#       `plan file only`, or `no changes since base`.
#
# --repo  a repository in scope; repeatable. Default: the cwd's repository.
# The plan file itself is excluded from every diff. A diff over ROW_SNAPSHOT_MAX_LINES (default
# 4000) lines is truncated with a note. Exit 0 on success, 2 on a usage error, 3 when a base cannot
# be recorded (mid-rebase, no commits) or used (not an ancestor of HEAD), or when no repo is
# `changed`, so no patch is written: run inline. Exit 3 also when `run` has no recorded base and no
# remote default branch to take a merge-base with: pass a ref.
set -euo pipefail

usage() { sed -n '3,32p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
die() { echo "row-snapshot: $2" >&2; exit "$1"; }

[[ $# -ge 2 ]] || usage
cmd="$1" plan="$2"; shift 2
[[ -f "$plan" ]] || die 2 "no such plan: $plan"
plan_abs="$(cd "$(dirname "$plan")" && pwd)/$(basename "$plan")"
stem="$(basename "$plan" .md)"
run_dir="${ROW_SNAPSHOT_HOME:-$HOME/.claude/plan-runs}/$stem"
max_lines="${ROW_SNAPSHOT_MAX_LINES:-4000}"

row="" ref="" repos=()
case "$cmd" in
  dir) ;;
  base|diff)
    [[ $# -ge 1 && "$1" != --* ]] || usage
    row="$1"; shift
    [[ "$row" =~ ^[A-Za-z0-9._-]+$ ]] || die 2 "row id '$row' must be [A-Za-z0-9._-]"
    if [[ "$cmd" == diff && $# -ge 1 && "$1" != --* ]]; then ref="$1"; shift; fi
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --repo) [[ $# -ge 2 ]] || usage; repos+=("$2"); shift 2 ;;
        *) usage ;;
      esac
    done ;;
  *) usage ;;
esac

if [[ "$cmd" == dir ]]; then echo "$run_dir"; exit 0; fi

row_dir="$run_dir/rows/$row"
if [[ ${#repos[@]} -eq 0 ]]; then
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || die 2 "cwd is not in a repository; pass --repo"
  repos=("$top")
fi

# A repo's key: its toplevel with / made safe, so two repos with one basename never collide.
key_of() { printf '%s' "$1" | tr '/ ' '__'; }
toplevel() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || die 2 "not a repository: $1"; }
# The plan's path relative to <top>, if the plan lives in that repo; empty otherwise.
plan_in() { case "$plan_abs" in "$1"/*) printf '%s' "${plan_abs#"$1"/}" ;; esac; }

record_base() { # <toplevel>
  local top="$1" key sha f
  key="$(key_of "$top")"
  for f in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD; do
    (cd "$top" && [[ -e "$(git rev-parse --git-path "$f")" ]]) \
      && die 3 "$top is mid-operation ($f) — run the row inline, labelled"
  done
  sha="$(git -C "$top" stash create 2>/dev/null)" \
    || die 3 "cannot record a base in $top (mid-rebase, or no commits) — run the row inline, labelled"
  [[ -n "$sha" ]] || sha="$(git -C "$top" rev-parse HEAD 2>/dev/null)" \
    || die 3 "cannot record a base in $top (no commits) — run the row inline, labelled"
  rm -rf "${row_dir:?}/untracked/$key" "$row_dir/untracked-$key.list"
  mkdir -p "$row_dir/untracked/$key"
  git -C "$top" ls-files -o --exclude-standard -z >"$row_dir/untracked-$key.list"
  while IFS= read -r -d '' f; do
    mkdir -p "$row_dir/untracked/$key/$(dirname "$f")"
    cp -p "$top/$f" "$row_dir/untracked/$key/$f"
  done <"$row_dir/untracked-$key.list"
  printf '%s\t%s\t%s\n' "$top" "$sha" "$key" >>"$row_dir/base.tsv"
  echo "base $row · $top · ${sha:0:12} · $(tr -cd '\0' <"$row_dir/untracked-$key.list" | wc -c | tr -d ' ') untracked copied"
}

# Reject a base that cannot yield a meaningful range. A wrong-branch or wrong-checkout HEAD gives a
# range unrelated to the base, which diffs plausibly but wrongly. An empty range is not rejected
# here: it is one repo's status, and only a package with no `changed` repo is refused.
check_base() { # <toplevel> <sha>
  local top="$1" sha="$2"
  # A `git stash create` base has two parents and its first is the HEAD it was taken from, so it is
  # still usable once HEAD has moved on; a real commit has one parent and must be an ancestor itself.
  if ! git -C "$top" merge-base --is-ancestor "$sha" HEAD 2>/dev/null; then
    # Stash-shaped is >1 parent, so `rev-list --parents -n1` prints >2 fields (the sha, then each).
    # Parent count alone cannot tell a stash from a merge commit, and `base` records either — a clean
    # tree makes the base whatever HEAD is — so the subject `git stash create` writes is required too.
    if (( $(git -C "$top" rev-list --parents -n1 "$sha" 2>/dev/null | wc -w) < 3 )) \
      || [[ "$(git -C "$top" log -1 --format=%s "$sha")" != 'WIP on '* ]] \
      || ! git -C "$top" merge-base --is-ancestor "$sha^1" HEAD 2>/dev/null; then
      die 3 "base ${sha:0:12} is not an ancestor of HEAD in $top (wrong branch or checkout?) — run inline"
    fi
  fi
}

# A repo's status. `changed`: its section has a hunk. `plan file only`: no hunk, but the plan file
# (excluded from every diff) differs from base — tracked and changed, or untracked and either new
# since base or no longer matching its base copy.
repo_status() { # <toplevel> <sha> <key> <section file>
  local top="$1" sha="$2" key="$3" plan_rel copy
  if grep -q '^diff --git' "$4"; then echo changed; return; fi
  plan_rel="$(plan_in "$top")"
  if [[ -n "$plan_rel" ]]; then
    if ! git -C "$top" diff --quiet "$sha" -- "$plan_rel"; then echo 'plan file only'; return; fi
    if [[ -n "$(git -C "$top" ls-files -o --exclude-standard -- "$plan_rel")" ]]; then
      copy="$row_dir/untracked/$key/$plan_rel"
      if [[ -z "$key" || ! -f "$copy" ]] || ! cmp -s "$copy" "$top/$plan_rel"; then
        echo 'plan file only'; return
      fi
    fi
  fi
  echo 'no changes since base'
}

# Diff one repo against <sha>. <key> names its base copies; empty means none recorded.
diff_repo() { # <toplevel> <sha> <key> <label>
  local top="$1" sha="$2" key="$3" label="$4" skip f copy_root copy_esc
  local excl=()
  skip="$(plan_in "$top")"
  [[ -n "$skip" ]] && excl+=(":(exclude)$skip")
  echo "=== repo: $top · against $label"
  if [[ -n "$key" && -f "$row_dir/untracked-$key.list" ]]; then
    while IFS= read -r -d '' f; do excl+=(":(exclude)$f"); done <"$row_dir/untracked-$key.list"
  fi
  git -C "$top" diff --no-color "$sha" -- . ${excl[@]+"${excl[@]}"}
  # Files untracked at base: diff each against its copy, labelled as the base.
  if [[ -n "$key" && -f "$row_dir/untracked-$key.list" ]]; then
    copy_root="$row_dir/untracked/$key"
    copy_esc="$(printf '%s' "$copy_root" | sed 's/[][\.*^$/]/\\&/g')"
    while IFS= read -r -d '' f; do
      [[ "$f" == "$skip" ]] && continue
      if [[ -e "$top/$f" ]]; then
        cmp -s "$copy_root/$f" "$top/$f" && continue   # unchanged: skip the git spawn
        (cd "$top" && git diff --no-index --no-color "$copy_root/$f" "$f") || true
      else
        (cd "$top" && git diff --no-index --no-color "$copy_root/$f" /dev/null) || true
      fi
    done <"$row_dir/untracked-$key.list" | sed "s/$copy_esc/\/(base)/g"
  fi
  # Files untracked now and not at base: new, shown in full. One sorted pass (`comm` reads both
  # lists whole, so no reader exits early on a list over the pipe buffer). Newline in a name: unsupported.
  local now base_list=/dev/null
  [[ -n "$key" && -f "$row_dir/untracked-$key.list" ]] && base_list="$row_dir/untracked-$key.list"
  now="$(cd "$top" && git ls-files -o --exclude-standard -z | tr '\0' '\n' | LC_ALL=C sort)"
  LC_ALL=C comm -23 <(printf '%s\n' "$now") <(tr '\0' '\n' <"$base_list" | LC_ALL=C sort) \
    | while IFS= read -r f; do
      [[ -z "$f" || "$f" == "$skip" ]] && continue
      (cd "$top" && git diff --no-index --no-color /dev/null "$f") || true
    done
}

if [[ "$cmd" == base ]]; then
  mkdir -p "$row_dir"
  rm -f "$row_dir/base.tsv"
  for r in "${repos[@]}"; do record_base "$(toplevel "$r")"; done
  exit 0
fi

# diff
mkdir -p "$row_dir"
n=1; while [[ -e "$row_dir/diff-$n.patch" ]]; do n=$((n + 1)); done
out="$row_dir/diff-$n.patch"
trap 'rm -f "$out.full" "$out.sec"' EXIT   # check_base can exit 3 part-way through the write below
{
  for r in "${repos[@]}"; do
    top="$(toplevel "$r")" key=""
    if [[ -n "$ref" ]]; then
      sha="$(git -C "$top" rev-parse --verify -q "$ref^{commit}")" || die 2 "ref '$ref' does not resolve in $top"
      check_base "$top" "$sha"
      label="$ref (${sha:0:12})"
    elif line="$(grep -F "$top"$'\t' "$row_dir/base.tsv" 2>/dev/null | head -1)" && [[ -n "$line" ]]; then
      IFS=$'\t' read -r _ sha key <<<"$line"
      check_base "$top" "$sha"
      label="recorded base ${sha:0:12}"
    elif [[ "$row" == run ]]; then   # HEAD would hide every commit the run made
      d=origin/HEAD
      git -C "$top" rev-parse --verify -q "$d^{commit}" >/dev/null || d=origin/main
      sha="$(git -C "$top" merge-base HEAD "$d" 2>/dev/null)" \
        || die 3 "no recorded base and no remote default branch in $top — pass a ref"
      check_base "$top" "$sha"
      label="merge-base ${sha:0:12} with $d — no recorded base; every untracked file counts as new"
    else
      sha="$(git -C "$top" rev-parse HEAD)"
      label="HEAD ${sha:0:12} — no recorded base; every untracked file counts as new"
    fi
    diff_repo "$top" "$sha" "$key" "$label" >"$out.sec"
    status="$(repo_status "$top" "$sha" "$key" "$out.sec")"
    printf '%s · %s\n' "$(head -n 1 "$out.sec")" "$status"   # the `=== repo:` header, with status
    tail -n +2 "$out.sec"
    echo "row-snapshot: $top: $status" >&2
  done
} >"$out.full"
# Tested before truncation, on every branch above: the EXIT trap removes the hunk-less package.
grep -q '^diff --git' "$out.full" \
  || die 3 "no repository changed since its base (wrong branch or checkout?) — run inline"
total="$(wc -l <"$out.full" | tr -d ' ')"
if (( total > max_lines )); then
  head -n "$max_lines" "$out.full" >"$out"
  echo "… truncated: $max_lines of $total lines shown; read the tree for the rest" >>"$out"
else
  mv "$out.full" "$out"
fi
rm -f "$out.full"
echo "$out"
