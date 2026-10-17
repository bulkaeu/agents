#!/usr/bin/env bash
#
# Refresh one vendored third-party source under vendor/<name>/ from its upstream repo.
#
# vendor/<name>/SOURCE holds the input: `repo:`, `ref:`, an optional `license:` path and one
# `path:` line per skill directory to adopt. This script copies those and nothing else.
#
# Never commits: the diff it leaves in the working tree is what you review. It refuses to
# run on `main` or in the main worktree, because skills link into the main checkout and an
# update run there would go live before anyone reviewed it. Upgrade on a branch in a
# worktree, then review and merge.
#
#   bash update-vendor.sh <name>          re-pin to the ref recorded in vendor/<name>/SOURCE
#   bash update-vendor.sh <name> <ref>    use a tag or branch instead (SOURCE is not edited)
#   bash update-vendor.sh --help          show this text
#
# Exit codes:
#   0  updated, checks passed
#   1  check-vendor.sh failed (or is missing), or the clone/copy failed
#   2  refused (main branch or main worktree) or bad usage (including an unknown <name>)
#   3  only sanitize-check.sh failed: expected until the vendored prose is cleared of licence
#      ids and spec numbers that trip its generic pattern, otherwise a new false positive
#
# skills/ and LICENSE are replaced wholesale, so a file deleted upstream goes too. Each
# `path:` lands at vendor/<name>/skills/<its last component>. vendor/<name>/UPSTREAM records
# the repo URL, the ref used and the resolved 40-hex sha, with no timestamp. The sha is what
# identifies the tree: re-pinning an immutable ref — a tag or a commit — reproduces it byte
# for byte, while re-pinning a branch ref takes whatever the branch points at then and writes
# a new sha. `git clone --branch` takes no sha, so a branch-pinned set cannot be re-pinned to
# its recorded one through this script; there the sha is for verification only.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { sed -n '3,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//; /^#$/s/#//'; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*)        echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  "")        echo "missing <name>" >&2; usage >&2; exit 2 ;;
esac
if [[ $# -gt 2 ]]; then echo "too many arguments" >&2; exit 2; fi
NAME="$1"
[[ "$NAME" =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || { echo "bad vendor name: $NAME" >&2; exit 2; }
DEST="$REPO/vendor/$NAME"
[[ -f "$DEST/SOURCE" ]] || { echo "no vendor/$NAME/SOURCE" >&2; exit 2; }

# Optional keys go through sed, never grep: a grep with no match exits 1 and kills this script.
src_key() { sed -n "s/^$1: //p" "$DEST/SOURCE" | head -n 1; }
UPSTREAM_URL="$(src_key repo)"
REF="${2:-$(src_key ref)}"
LICENSE_PATH="$(src_key license)"
[[ -n "$UPSTREAM_URL" && -n "$REF" ]] || { echo "vendor/$NAME/SOURCE needs repo: and ref:" >&2; exit 2; }
PATHS=()
while IFS= read -r line; do PATHS+=("$line"); done < <(sed -n 's/^path: //p' "$DEST/SOURCE")
(( ${#PATHS[@]} > 0 )) || { echo "vendor/$NAME/SOURCE lists no path: lines" >&2; exit 2; }

# Every path: and license: value is joined onto the clone directory below, and tested only
# with -d/-f — so an absolute value, or one with a `..` segment, would resolve outside the
# clone and be copied in from the machine. SOURCE is reviewed input, so this is a guard
# against a typo or a bad bump, not a live hole.
for p in "${PATHS[@]}" "$LICENSE_PATH"; do
  [[ -n "$p" ]] || continue
  [[ "$p" != /* ]] \
    || { echo "vendor/$NAME/SOURCE: path must be relative to the clone, got: $p" >&2; exit 2; }
  [[ "/$p/" != */../* ]] \
    || { echo "vendor/$NAME/SOURCE: path must not contain a .. segment, got: $p" >&2; exit 2; }
done

# --- 0. refuse on main or in the main worktree -------------------------------------
branch="$(git -C "$REPO" symbolic-ref --short -q HEAD || true)"
toplevel="$(git -C "$REPO" rev-parse --show-toplevel)"
main_wt="$(git -C "$REPO" worktree list --porcelain | sed -n 's/^worktree //p' | head -n 1)"
# worktree list prints the path as given, rev-parse prints it resolved (/var vs /private/var
# on macOS), so compare physical paths.
toplevel="$(cd "$toplevel" && pwd -P)"
main_wt="$(cd "$main_wt" && pwd -P)"
if [[ "$branch" == "main" ]]; then
  echo "refusing: current branch is main. Skills link into the main checkout, so an" >&2
  echo "update here goes live before review. Run this on a branch in a worktree." >&2
  exit 2
fi
if [[ "$toplevel" == "$main_wt" ]]; then
  echo "refusing: $toplevel is the main worktree. Skills link from here, so an update" >&2
  echo "goes live before review. Run this on a branch in a separate worktree." >&2
  exit 2
fi

# --- 1. shallow-clone the ref ------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet --depth 1 --branch "$REF" -- "$UPSTREAM_URL" "$TMP/src" \
  || { echo "clone of $UPSTREAM_URL at $REF failed" >&2; exit 1; }
SRC="$TMP/src"
SHA="$(git -C "$SRC" rev-parse HEAD)"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "could not resolve a 40-hex sha (got: $SHA)" >&2; exit 1; }

# Previous pin, for the range printed at the end. Empty on the first vendoring.
OLD_SHA=""
if [[ -f "$DEST/UPSTREAM" ]]; then
  OLD_SHA="$(sed -n 's/^sha: //p' "$DEST/UPSTREAM" | head -n 1)"
fi

# --- 2. replace skills/ and the licence --------------------------------------------
rm -rf "$DEST/skills" "$DEST/LICENSE"
mkdir -p "$DEST/skills"

for p in "${PATHS[@]}"; do
  [[ -d "$SRC/$p" ]] || { echo "upstream is missing required $p/" >&2; exit 1; }
  d="$DEST/skills/$(basename "$p")"
  [[ ! -e "$d" ]] || { echo "two path: lines end in $(basename "$p")" >&2; exit 1; }
  cp -Rp "$SRC/$p" "$d"
done

if [[ -n "$LICENSE_PATH" ]]; then
  [[ -f "$SRC/$LICENSE_PATH" ]] || { echo "upstream is missing required $LICENSE_PATH" >&2; exit 1; }
  # Always lands as plain LICENSE, even when upstream's is nested (skills/x/LICENSE.txt).
  cp -p "$SRC/$LICENSE_PATH" "$DEST/LICENSE"
fi

printf 'repo: %s\nref: %s\nsha: %s\n' "$UPSTREAM_URL" "$REF" "$SHA" > "$DEST/UPSTREAM"
echo "vendored $UPSTREAM_URL at $REF ($SHA)"

# --- 3. checks ---------------------------------------------------------------------
if [[ ! -f "$REPO/check-vendor.sh" ]]; then
  echo "check-vendor.sh is missing" >&2; exit 1
fi
if ! bash "$REPO/check-vendor.sh"; then
  echo "check-vendor.sh FAILED" >&2; exit 1
fi
if ! bash "$REPO/sanitize-check.sh"; then
  echo "sanitize-check.sh FAILED (check-vendor.sh passed): see the exit codes in --help" >&2
  exit 3
fi

# --- 4. report, never commit -------------------------------------------------------
echo
git -C "$REPO" status --short -- "vendor/$NAME"
echo
if [[ -n "$OLD_SHA" && "$OLD_SHA" != "$SHA" ]]; then
  echo "upstream range: $OLD_SHA..$SHA"
  echo "  $UPSTREAM_URL/compare/$OLD_SHA...$SHA"
elif [[ "$OLD_SHA" == "$SHA" ]]; then
  echo "upstream unchanged at $SHA"
else
  echo "first vendoring at $SHA"
fi
echo "Nothing is committed. Review the changes above, then commit on this branch."
