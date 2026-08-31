#!/usr/bin/env bash
#
# Refuse to publish private identifiers. This repo is public.
#
# Scans TRACKED files only — never the working tree, so a deliberately-ignored local
# file (a filled migration profile, a personal tracker config) does not trip the gate
# on every run.
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
hits="$(git ls-files -z | xargs -0 grep -IniE "$pattern" 2>/dev/null || true)"

if [[ -n "$hits" ]]; then
  echo "SANITIZE FAILED — private or absolute-path identifiers in tracked files:"
  printf '  %s\n' "${hits//$'\n'/$'\n'  }"
  echo
  echo "Remove them, or add the file to .gitignore if it is meant to stay local."
  exit 1
fi

echo "sanitize clean — $(git ls-files | wc -l | tr -d ' ') tracked files, $local_count local term(s) applied"
