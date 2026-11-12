#!/usr/bin/env bash
#
# Every repository check in one command. Run it before a change is done.
#
#   bash check.sh
#
# Runs, in order, and stops at the first that fails: check-plan-skills.sh (which runs
# sanitize-check.sh), check-vendor.sh, check-ponytail.sh, the row-snapshot test, and ShellCheck
# at warning level over the repository's own shell scripts (vendor/ excluded). Prints
# `FAIL — <name>` naming the failed step and exits 1; prints `ok — all checks` and exits 0 when
# clean. A missing ShellCheck is a failure, not a skip. Exit 2 if run outside a git checkout.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 2
# Without a git checkout the file list below would silently shrink to check.sh alone.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git checkout" >&2; exit 2; }

run() { # run <name> <command...>: run one step, name it and stop if it fails
  local name="$1"; shift
  echo "== $name"
  "$@" || { echo "FAIL — $name" >&2; exit 1; }
}

shellcheck_own() {
  command -v shellcheck >/dev/null || { echo "shellcheck is not installed" >&2; return 1; }
  local files
  # check.sh is listed explicitly so it checks itself before it is tracked
  files="$({ git ls-files '*.sh' | grep -v '^vendor/'; echo check.sh; } | sort -u)" || return 1
  # shellcheck disable=SC2086 # paths in this repository contain no whitespace
  shellcheck -S warning $files
}

run "check-plan-skills.sh" bash check-plan-skills.sh
run "check-vendor.sh" bash check-vendor.sh
run "check-ponytail.sh" bash check-ponytail.sh
run "test-row-snapshot.sh" bash skills/plan-build/scripts/test-row-snapshot.sh
run "ShellCheck" shellcheck_own
echo "ok — all checks"
