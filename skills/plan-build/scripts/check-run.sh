#!/usr/bin/env bash
#
# Run a check and record the exact tree it ran against, so a later step can reuse the result
# instead of running the same suite again on the same files.
#
#   check-run.sh run <out-file> [--repo <dir>]... -- <command> [<arg>...]
#   check-run.sh current <out-file>
#
# run      Record each repo's tree identity, run the command (output to the terminal and <out-file>),
#          then record its exit status and the identity again. Exits with the command's status.
#          One record per file: an existing <out-file> is refused (exit 2), so a second check can
#          never overwrite the first. A tree that changed during the run is marked, and `current`
#          never accepts it. Put any environment variable that changes what the check does inside
#          the command (`-- env NAME=value <command>`), where the record's `# cmd` line shows it.
# current  Is <out-file>'s result still about the tree as it is now? Exit 0: every repo's tree is
#          identical. Exit 4: only Markdown files (*.md) changed — reusable unless the check reads
#          Markdown. Exit 1: anything else changed, the tree moved during the run, or a recorded
#          tree is gone. Exit 2: unreadable file or bad usage. It prints the changed paths.
#
# The identity is the git tree of the working copy as it stands — commits, staged and unstaged
# edits and untracked files alike, ignored files excluded — built in a throwaway index, so the real
# index is never touched. Unlike `git stash create`, whose sha changes on every call, the same files
# always give the same identity. --repo defaults to the cwd's repository.
# shortcut: untracked files are re-hashed on every call; a tree holding gigabytes of untracked,
# un-ignored files makes each call slow — ignore them in .gitignore if that bites.
set -uo pipefail

die() { echo "check-run: $2" >&2; exit "$1"; }

toplevel() { git -C "$1" rev-parse --show-toplevel 2>/dev/null || die 2 "not a git repository: $1"; }

tree_id() { # <toplevel> — print the tree of the working copy as it stands
  local top="$1" idx src tree
  idx="$(mktemp)" || die 2 "mktemp failed"
  src="$(git -C "$top" rev-parse --git-path index)"
  [[ "$src" == /* ]] || src="$top/$src"
  # Start from a copy of the real index so tracked files keep their stat cache.
  if [[ -f "$src" ]]; then cp "$src" "$idx"; else rm -f "$idx"; fi
  GIT_INDEX_FILE="$idx" git -C "$top" add -A >/dev/null 2>&1 || { rm -f "$idx"; die 2 "cannot hash $top"; }
  tree="$(GIT_INDEX_FILE="$idx" git -C "$top" write-tree)" || { rm -f "$idx"; die 2 "cannot write a tree for $top"; }
  rm -f "$idx"
  printf '%s' "$tree"
}

parse_repos() { # fills TOPS from --repo args up to `--` or the end; sets REST to what follows
  TOPS=() REST=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) [[ -n "${2:-}" ]] || die 2 "--repo needs a directory"; TOPS+=("$(toplevel "$2")") || exit 2; shift 2 ;;
      --) shift; REST=("$@"); break ;;
      *) die 2 "unexpected argument: $1" ;;
    esac
  done
  [[ ${#TOPS[@]} -gt 0 ]] || { TOPS=("$(toplevel .)") || exit 2; }
}

cmd="${1:-}"; shift || true
case "$cmd" in
  run)
    out="${1:-}"; shift || true
    [[ -n "$out" ]] || die 2 "usage: check-run.sh run <out-file> [--repo <dir>]... -- <command>"
    [[ ! -e "$out" ]] || die 2 "$out exists: one record per file — name a new one"
    parse_repos "$@"
    [[ ${#REST[@]} -gt 0 ]] || die 2 "no command after --"
    mkdir -p "$(dirname "$out")" || die 2 "cannot create $(dirname "$out")"
    before=()
    for top in "${TOPS[@]}"; do before+=("$(tree_id "$top")") || exit 2; done
    {
      echo "# check-run 1"
      echo "# started $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "# cwd $PWD"
      printf '# cmd'; printf ' %q' "${REST[@]}"; echo
      for i in "${!TOPS[@]}"; do echo "# repo ${before[i]} ${TOPS[i]}"; done
      echo "# end-header"
    } >"$out"
    "${REST[@]}" 2>&1 | tee -a "$out"
    status="${PIPESTATUS[0]}"
    [[ -z "$(tail -c 1 "$out")" ]] || echo >>"$out" # output without a final newline would swallow the footer
    {
      echo "# exit $status"
      echo "# finished $(date -u +%Y-%m-%dT%H:%M:%SZ)"
      for i in "${!TOPS[@]}"; do
        after="$(tree_id "${TOPS[i]}")"
        [[ "$after" == "${before[i]}" ]] || echo "# tree-changed-during-run ${TOPS[i]}"
      done
    } >>"$out"
    exit "$status"
    ;;

  current)
    out="${1:-}"
    [[ -n "$out" && -r "$out" ]] || die 2 "usage: check-run.sh current <out-file> (readable)"
    head -1 "$out" | grep -qx '# check-run 1' || die 2 "$out was not written by check-run.sh run"
    grep -qx '# end-header' "$out" || die 2 "$out has no header end"
    # The footer is everything after the last output line; read it from the end, where output cannot reach.
    footer="$(tail -n "$(( $(grep -c '^# repo ' "$out") + 2 ))" "$out")"
    grep -q '^# exit ' <<<"$footer" || die 1 "$out has no exit line: the run did not finish"
    if grep -q '^# tree-changed-during-run ' <<<"$footer"; then
      grep '^# tree-changed-during-run ' <<<"$footer" | sed 's/^# tree-changed-during-run /changed during the run: /'
      exit 1
    fi
    worst=0
    while read -r _ _ old top; do
      [[ -d "$top" ]] || { echo "gone: $top"; worst=1; continue; }
      now="$(tree_id "$top")" || exit 2
      [[ "$now" == "$old" ]] && continue
      if ! git -C "$top" cat-file -e "$old^{tree}" 2>/dev/null; then
        echo "recorded tree no longer in $top"; worst=1; continue
      fi
      # -z: unquoted paths, so a non-ASCII `.md` name still ends in `.md`.
      only_md=1
      while IFS= read -r -d '' p; do
        echo "changed in $top: $p"
        [[ "$p" == *.md ]] || only_md=0
      done < <(git -C "$top" diff -z --name-only "$old" "$now")
      if [[ $only_md -eq 0 ]]; then worst=1; elif [[ $worst -eq 0 ]]; then worst=4; fi
    done < <(awk '/^# end-header$/ {exit} /^# repo /' "$out") # the header only: output cannot add a repo
    [[ $worst -eq 0 ]] && echo "current"
    exit "$worst"
    ;;

  *) die 2 "usage: check-run.sh run <out> [--repo <dir>]... -- <command> | current <out>" ;;
esac
