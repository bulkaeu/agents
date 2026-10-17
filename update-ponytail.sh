#!/usr/bin/env bash
#
# Refresh the vendored copy of the ponytail hooks and skills under vendor/ponytail/.
#
# Never commits: the diff it leaves in the working tree is what you review. It refuses to
# run on `main` or in the main worktree, because the hooks execute from the main checkout
# and an update run there would go live before anyone reviewed it. Upgrade on a branch in a
# worktree, then review and merge.
#
#   bash update-ponytail.sh           update to the newest upstream v* tag
#   bash update-ponytail.sh <ref>     update to a tag, branch or ref (e.g. v5.2.0, main)
#   bash update-ponytail.sh --help    show this text
#
# Exit codes:
#   0  updated, checks passed
#   1  check-ponytail.sh or the vendor-set check failed (or is missing), or the clone/copy failed
#   2  refused (main branch or main worktree) or bad usage
#   3  only sanitize-check.sh failed: a new false positive, not a structural problem
#
# Only an allowlist is copied (the copy_file calls below); assets, benchmarks, tests, i18n and
# other hosts' manifests are left out. vendor/ponytail/UPSTREAM records the repo URL, the
# ref asked for and the resolved 40-hex sha, with no timestamp, so re-pinning to the same
# ref reproduces the tree byte for byte.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_URL="https://github.com/DietrichGebert/ponytail"
DEST="$REPO/vendor/ponytail"

usage() { sed -n '3,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//; /^#$/s/#//'; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*)        echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then echo "too many arguments" >&2; exit 2; fi
REF="${1:-}"

# --- 0. refuse on main or in the main worktree -------------------------------------
branch="$(git -C "$REPO" symbolic-ref --short -q HEAD || true)"
toplevel="$(git -C "$REPO" rev-parse --show-toplevel)"
main_wt="$(git -C "$REPO" worktree list --porcelain | sed -n 's/^worktree //p' | head -n 1)"
# worktree list prints the path as given, rev-parse prints it resolved (/var vs /private/var
# on macOS), so compare physical paths.
toplevel="$(cd "$toplevel" && pwd -P)"
main_wt="$(cd "$main_wt" && pwd -P)"
if [[ "$branch" == "main" ]]; then
  echo "refusing: current branch is main. The hooks run from the main checkout, so an" >&2
  echo "update here goes live before review. Run this on a branch in a worktree." >&2
  exit 2
fi
if [[ "$toplevel" == "$main_wt" ]]; then
  echo "refusing: $toplevel is the main worktree. The hooks run from here, so an update" >&2
  echo "goes live before review. Run this on a branch in a separate worktree." >&2
  exit 2
fi

# --- 1. resolve the ref and shallow-clone it ---------------------------------------
if [[ -z "$REF" ]]; then
  # Newest v* tag. Annotated tags list twice (name and name^{}); the filter drops the latter.
  REF="$(git ls-remote --tags "$UPSTREAM_URL" 'v*' \
    | sed -n 's#.*refs/tags/\(v[^^]*\)$#\1#p' | sort -V | tail -n 1)"
  [[ -n "$REF" ]] || { echo "no v* tags found at $UPSTREAM_URL" >&2; exit 1; }
  echo "newest upstream tag: $REF"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --quiet --depth 1 --branch "$REF" "$UPSTREAM_URL" "$TMP/src" \
  || { echo "clone of $UPSTREAM_URL at $REF failed" >&2; exit 1; }
SRC="$TMP/src"
SHA="$(git -C "$SRC" rev-parse HEAD)"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "could not resolve a 40-hex sha (got: $SHA)" >&2; exit 1; }

# Previous pin, for the range printed at the end. Empty on the first vendoring.
OLD_SHA=""
if [[ -f "$DEST/UPSTREAM" ]]; then
  OLD_SHA="$(sed -n 's/^sha: //p' "$DEST/UPSTREAM" | head -n 1)"
fi

# --- 2. replace the allowlisted paths ----------------------------------------------
# skills/, hooks/ and scripts/ are replaced wholesale so a file deleted upstream goes too.
rm -rf "$DEST/skills" "$DEST/hooks" "$DEST/scripts"
mkdir -p "$DEST/skills" "$DEST/hooks" "$DEST/scripts"

# need <path>: a file that must exist upstream. optional <glob>: copied if it matches.
copy_file() {
  local rel="$1"
  [[ -f "$SRC/$rel" ]] || { echo "upstream is missing required $rel" >&2; exit 1; }
  mkdir -p "$DEST/$(dirname "$rel")"
  cp -p "$SRC/$rel" "$DEST/$rel"
}

copy_file LICENSE
copy_file AGENTS.md
copy_file hooks/claude-codex-hooks.json
copy_file hooks/cursor-hooks.json
copy_file hooks/ponytail-statusline.sh
copy_file scripts/cursor-hooks.js
copy_file scripts/uninstall.js

n=0
for f in "$SRC"/hooks/*.js; do
  [[ -f "$f" ]] || continue
  cp -p "$f" "$DEST/hooks/"; n=$((n + 1))
done
(( n > 0 )) || { echo "upstream has no hooks/*.js" >&2; exit 1; }

n=0
for f in "$SRC"/skills/ponytail*/SKILL.md; do
  [[ -f "$f" ]] || continue
  d="$(basename "$(dirname "$f")")"
  mkdir -p "$DEST/skills/$d"
  cp -p "$f" "$DEST/skills/$d/SKILL.md"; n=$((n + 1))
done
(( n > 0 )) || { echo "upstream has no skills/ponytail*/SKILL.md" >&2; exit 1; }

printf 'repo: %s\nref: %s\nsha: %s\n' "$UPSTREAM_URL" "$REF" "$SHA" > "$DEST/UPSTREAM"
echo "vendored $UPSTREAM_URL at $REF ($SHA)"

# --- 3. checks ---------------------------------------------------------------------
if [[ ! -f "$REPO/check-ponytail.sh" ]]; then
  echo "check-ponytail.sh is missing" >&2; exit 1
fi
if ! bash "$REPO/check-ponytail.sh" || ! bash "$REPO/check-vendor.sh"; then
  echo "check-ponytail.sh or the vendor-set check FAILED" >&2; exit 1
fi
if ! bash "$REPO/sanitize-check.sh"; then
  echo "sanitize-check.sh FAILED (the structural checks passed): likely a new false positive" >&2
  exit 3
fi

# --- 4. report, never commit -------------------------------------------------------
echo
git -C "$REPO" diff --stat -- vendor/ponytail
echo
if [[ -n "$OLD_SHA" && "$OLD_SHA" != "$SHA" ]]; then
  echo "upstream range: $OLD_SHA..$SHA"
  echo "  $UPSTREAM_URL/compare/$OLD_SHA...$SHA"
elif [[ "$OLD_SHA" == "$SHA" ]]; then
  echo "upstream unchanged at $SHA"
else
  echo "first vendoring at $SHA"
fi
echo "Nothing is committed. Review the diff above, then commit on this branch."
