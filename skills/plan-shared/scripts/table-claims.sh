#!/usr/bin/env bash
#
# Check what a plan's Progress table claims against git and disk. Reports only; never edits.
#
# For every Progress row: its id and icon, each commit sha in its Notes (resolves in some repo in
# scope, or missing), and each backticked path in its Notes (exists, or missing).
#
#   table-claims.sh <plan.md> [--repo <dir>]... [--root <dir>]
#
#   --repo  a repository in scope; repeatable. Default: the plan's own repo and the cwd's, if any.
#   --root  a directory relative paths may also resolve under — typically a workspace holding
#           several checkouts. Default: the parent of the plan's repo toplevel.
#
# A sha counts as present if `git cat-file` resolves it as a commit in ANY repo in scope. A path
# counts as present if it exists as given (after ~ expansion), under any repo in scope, or under
# the root. Only tokens containing a `/` are paths: bare file names, slash commands (`/name`), git
# refs (`origin/main`), globs, variables and placeholders (`*`, `$`, `<`, `{`) are skipped.
#
# Output: one line per row, then a tally. Exit 0 always on a readable plan; 2 on a usage error.
set -euo pipefail

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

plan=""
root=""
repos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || usage; repos+=("$2"); shift 2 ;;
    --root) [[ $# -ge 2 ]] || usage; root="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) [[ -z "$plan" ]] || usage; plan="$1"; shift ;;
  esac
done
[[ -n "$plan" && -r "$plan" ]] || usage

plan_dir="$(cd "$(dirname "$plan")" && pwd)"
plan_top="$(git -C "$plan_dir" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ ${#repos[@]} -eq 0 ]]; then
  [[ -n "$plan_top" ]] && repos+=("$plan_top")
  cwd_top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$cwd_top" && "$cwd_top" != "$plan_top" ]] && repos+=("$cwd_top")
fi
if [[ -z "$root" ]]; then
  if [[ -n "$plan_top" ]]; then root="$(dirname "$plan_top")"; else root="$plan_dir"; fi
fi

sha_ok() {
  local r
  for r in "${repos[@]+"${repos[@]}"}"; do
    git -C "$r" cat-file -e "$1^{commit}" 2>/dev/null && return 0
  done
  return 1
}

is_ref() {
  local r
  for r in "${repos[@]+"${repos[@]}"}"; do
    git -C "$r" rev-parse --verify --quiet "$1" >/dev/null 2>&1 && return 0
  done
  return 1
}

path_ok() {
  local p="$1" r
  [[ "$p" == \~/* ]] && p="$HOME/${p#\~/}"
  if [[ "$p" == /* ]]; then [[ -e "$p" ]]; return; fi
  for r in "${repos[@]+"${repos[@]}"}" "$root" "$plan_dir"; do
    [[ -e "$r/$p" ]] && return 0
  done
  return 1
}

rows=0 sha_good=0 sha_bad=0 path_good=0 path_bad=0
row_re='^\| *([A-Za-z0-9§.-]+) (⬜|🟡|✅|⛔|⏭️) *\|'

while IFS= read -r line; do
  [[ "$line" =~ $row_re ]] || continue
  id="${BASH_REMATCH[1]}"
  icon="${BASH_REMATCH[2]}"
  rows=$((rows + 1))
  notes="${line%|}"
  notes="${notes##*|}"
  out="$id $icon"

  while IFS= read -r sha; do
    [[ -z "$sha" || "$sha" =~ ^[0-9]+$ ]] && continue
    if sha_ok "$sha"; then out+=" · sha $sha ok"; sha_good=$((sha_good + 1))
    else out+=" · sha $sha MISSING"; sha_bad=$((sha_bad + 1)); fi
  done < <(grep -oE '\b[0-9a-f]{7,40}\b' <<<"$notes" || true)

  while IFS= read -r tok; do
    tok="${tok//\`/}"
    [[ -z "$tok" || "$tok" == *[\ \*\$\<\{]* ]] && continue
    [[ "$tok" == */* && ! "$tok" =~ ^/[A-Za-z0-9_-]+$ ]] || continue
    is_ref "$tok" && continue
    if path_ok "$tok"; then out+=" · path $tok ok"; path_good=$((path_good + 1))
    else out+=" · path $tok MISSING"; path_bad=$((path_bad + 1)); fi
  done < <(grep -oE '`[^`]+`' <<<"$notes" || true)

  echo "$out"
done < "$plan"

echo "rows $rows · shas ok $sha_good missing $sha_bad · paths ok $path_good missing $path_bad"
