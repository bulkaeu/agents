#!/usr/bin/env bash
#
# Refuse to publish private identifiers. This repo is public.
#
# Scans tracked files AND new files not yet staged (git ls-files -co --exclude-standard).
# Tracked-only would be a blind spot exactly where leaks arrive: a brand-new file is
# invisible to `git ls-files` until it is staged, so the scan would pass right up to the
# moment the leak became committable. Ignored files are excluded, so a deliberately-local
# file does not trip the gate on every run.
#
# Terms come from two places:
#   built-in  generic shapes safe to name in a public file — absolute home paths,
#             tracker-style identifiers, a git host
#   local     .sanitize-terms, gitignored, one extended-regex per line. Holds the
#             names that must not appear here — a workspace, a project, a hostname.
#             Absent on a fresh clone, and the generic check still applies.
#
#   bash sanitize-check.sh          scan; exit 1 on any hit
#   bash sanitize-check.sh --list   show the active pattern without scanning
#
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO" || exit 2

# \b matters: without it, [A-Z]{2,5}-[0-9]+ matches "ENSE-2" inside "LICENSE-2.0".
GENERIC='/Users/|\b[A-Z]{2,5}-[0-9]+|gitlab\.com/'
TERMS_FILE="$REPO/.sanitize-terms"
# Tracked, unlike .sanitize-terms: these are documented placeholders and boilerplate that
# legitimately look like the thing being caught. Fixed strings, one per line.
ALLOW_FILE="$REPO/.sanitize-allow"

pattern="$GENERIC"
local_count=0
if [[ -f "$TERMS_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    pattern="$pattern|$line"
    local_count=$((local_count + 1))
  done < "$TERMS_FILE"
fi

if [[ "${1:-}" == "--list" ]]; then
  echo "generic: $GENERIC"
  echo "local:   $local_count term(s) from .sanitize-terms"
  exit 0
fi

# -I skips binary files; the || true keeps a no-match grep from tripping errexit
# -co --exclude-standard: tracked + untracked-but-not-ignored. See the blind-spot note above.
# This script is excluded: it necessarily contains every pattern it searches for.
hits="$(git ls-files -co --exclude-standard -z \
  | grep -zv '^sanitize-check\.sh$' \
  | xargs -0 grep -IniE "$pattern" 2>/dev/null \
  | { [[ -f "$ALLOW_FILE" ]] && grep -vFf "$ALLOW_FILE" || cat; } || true)"

if [[ -n "$hits" ]]; then
  echo "SANITIZE FAILED — private or absolute-path identifiers in tracked files:"
  printf '  %s\n' "${hits//$'\n'/$'\n'  }"
  echo
  echo "Remove them, or add the file to .gitignore if it is meant to stay local."
  exit 1
fi

echo "sanitize clean — $(git ls-files -co --exclude-standard | wc -l | tr -d ' ') files scanned, $local_count local term(s) applied"
