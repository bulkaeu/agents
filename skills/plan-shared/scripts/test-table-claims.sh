#!/usr/bin/env bash
#
# Self-check for table-claims.sh's path filter, on a throwaway plan under a temp dir.
#
#   bash skills/plan-shared/scripts/test-table-claims.sh
#
# A resume once printed 37 MISSING lines of which none was drift: ranges, refspecs, package scopes
# and pull-request references read as paths. Checks those are skipped and a real path still counts.
# Prints `ok — N checks` and exits 0, or `FAIL …` lines and exits 1.
set -euo pipefail

CLAIMS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/table-claims.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/src"
: > "$tmp/src/here.txt"
cat > "$tmp/plan.md" <<'EOF'
| # | Step | Notes |
| - | ---- | ----- |
| 1 ✅ | `a` — step | `src/here.txt` and `src/gone.txt` |
| 2 ✅ | `b` — step | `origin/main..HEAD`, `abc1234:refs/heads/x`, `@scope/pkg`, `owner/repo#12` |
EOF
out="$(bash "$CLAIMS" "$tmp/plan.md" --root "$tmp")"
fails=0 checks=0
has() { # <name> <text the output must contain>
  checks=$((checks + 1))
  [[ "$out" == *"$2"* ]] || { echo "FAIL $1 — no '$2' in: ${out//$'\n'/ | }"; fails=$((fails + 1)); }
}
has "a real path counts" "path src/here.txt ok"
has "a missing path is reported" "path src/gone.txt MISSING"
has "ranges, refspecs, scopes and references are skipped" "paths ok 1 missing 1"

[[ $fails -eq 0 ]] || exit 1
echo "ok — $checks checks"
