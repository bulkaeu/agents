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
#       untracked file is then shown in full. With no recorded base, HEAD is used and said so.
#
# --repo  a repository in scope; repeatable. Default: the cwd's repository.
# The plan file itself is excluded from every diff. A diff over ROW_SNAPSHOT_MAX_LINES (default
# 4000) lines is truncated with a note. Exit 0 on success, 2 on a usage error, 3 when a base cannot
# be recorded (mid-rebase, no commits): the row then runs inline, labelled.
set -euo pipefail

usage() { sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
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
        (cd "$top" && git diff --no-index --no-color "$copy_root/$f" "$f") || true
      else
        (cd "$top" && git diff --no-index --no-color "$copy_root/$f" /dev/null) || true
      fi
    done <"$row_dir/untracked-$key.list" | sed "s/$copy_esc/\/(base)/g"
  fi
  # Files untracked now and not at base: new, shown in full.
  (cd "$top" && git ls-files -o --exclude-standard -z) | while IFS= read -r -d '' f; do
    [[ "$f" == "$skip" ]] && continue
    if [[ -n "$key" && -f "$row_dir/untracked-$key.list" ]] \
      && tr '\0' '\n' <"$row_dir/untracked-$key.list" | grep -qxF -- "$f"; then continue; fi
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
{
  for r in "${repos[@]}"; do
    top="$(toplevel "$r")"
    if [[ -n "$ref" ]]; then
      sha="$(git -C "$top" rev-parse --verify -q "$ref^{commit}")" || die 2 "ref '$ref' does not resolve in $top"
      diff_repo "$top" "$sha" "" "$ref (${sha:0:12})"
    elif line="$(grep -F "$top"$'\t' "$row_dir/base.tsv" 2>/dev/null | head -1)" && [[ -n "$line" ]]; then
      IFS=$'\t' read -r _ sha key <<<"$line"
      diff_repo "$top" "$sha" "$key" "recorded base ${sha:0:12}"
    else
      sha="$(git -C "$top" rev-parse HEAD)"
      diff_repo "$top" "$sha" "" "HEAD ${sha:0:12} — no recorded base; every untracked file counts as new"
    fi
  done
} >"$out.full"
total="$(wc -l <"$out.full" | tr -d ' ')"
if (( total > max_lines )); then
  head -n "$max_lines" "$out.full" >"$out"
  echo "… truncated: $max_lines of $total lines shown; read the tree for the rest" >>"$out"
else
  mv "$out.full" "$out"
fi
rm -f "$out.full"
echo "$out"
