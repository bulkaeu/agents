#!/usr/bin/env bash
#
# Self-check for row-snapshot.sh's --path scope, in throwaway repos under a temp dir.
#
#   bash skills/plan-build/scripts/test-row-snapshot.sh
#
# Replays the shared-checkout case that once halted a run on three peers' files, and checks that an
# unlisted file inside the scope still lands in paths-<n>.txt, where EXECUTION.md halts on it.
# Prints `ok — N checks` and exits 0, or `FAIL …` lines and exits 1.
set -euo pipefail

SNAP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/row-snapshot.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tmp="$(cd "$tmp" && pwd -P)"   # /tmp is /private/tmp on macOS, as git reports it
export ROW_SNAPSHOT_HOME="$tmp/runs"
fails=0 checks=0

expect() { # <name> <file> <expected content>
  checks=$((checks + 1))
  local got; got="$(cat "$2" 2>/dev/null || echo '<missing>')"
  [[ "$got" == "$3" ]] || { echo "FAIL $1"; echo "  want: ${3//$'\n'/ | }"; echo "  got:  ${got//$'\n'/ | }"; fails=$((fails + 1)); }
}
g() { git -C "$repo" "$@" >/dev/null; }
# <row> <kind> <n> [<ext>] → that row file, as row-snapshot.sh names it
rf() { printf '%s/%s/%s-%d.%s' "$run_rows" "$1" "$2" "$3" "${4:-txt}"; }

repo="$tmp/plans"
mkdir -p "$repo/game/design"
git init -q "$repo"
g config user.email t@t; g config user.name t
for f in plan.md game/design/packet.md game/peer-dirty.md game/peer-commit.md game/peer-edit.md; do
  echo base >"$repo/$f"
done
g add -A; g commit -qm init
echo peer-wip >>"$repo/game/peer-dirty.md"            # a peer's edit, already dirty at base
echo untracked >"$repo/game/peer-untracked.md"        # a peer's untracked file at base
plan="$repo/plan.md"
run_rows="$ROW_SNAPSHOT_HOME/$(basename "$(bash "$SNAP" dir "$plan")")/rows"

# G4: the row writes only the packet; peers commit, edit and create other files meanwhile.
bash "$SNAP" base "$plan" G4 --repo "$repo" >/dev/null
echo row >>"$repo/game/design/packet.md"
echo row >>"$plan"
echo more >>"$repo/game/peer-dirty.md"
echo peer >>"$repo/game/peer-commit.md"; g add game/peer-commit.md; g commit -qm peer
echo peer >>"$repo/game/peer-edit.md"
echo peer >>"$repo/game/peer-untracked.md"
echo new >"$repo/game/peer-new.md"
bash "$SNAP" diff "$plan" G4 --repo "$repo" --path "$repo/game/design/packet.md" >/dev/null 2>&1 || true
expect "G4 paths: only the row's file" "$(rf G4 paths 1)" "$repo/game/design/packet.md"
expect "G4 outside: every peer file" "$(rf G4 outside 1)" "$(printf '%s\n' \
  "$repo/game/peer-commit.md" "$repo/game/peer-dirty.md" "$repo/game/peer-edit.md" \
  "$repo/game/peer-new.md" "$repo/game/peer-untracked.md")"
checks=$((checks + 1))
if grep -qs 'peer' "$(rf G4 diff 1 patch)"; then echo "FAIL G4 patch shows a peer file"; fails=$((fails + 1)); fi

# Unlisted file inside the scope: in paths-<n>.txt, so not own, so a foreign path that halts.
bash "$SNAP" base "$plan" R2 --repo "$repo" >/dev/null
echo row >>"$repo/game/design/packet.md"
echo stray >"$repo/game/design/stray.md"
echo peer2 >>"$repo/game/peer-edit.md"
( cd "$repo" && bash "$SNAP" diff "$plan" R2 --path game/design/ >/dev/null 2>&1 || true )
expect "in-scope stray listed (relative --path, from the repo)" "$(rf R2 paths 1)" \
  "$(printf '%s\n' "$repo/game/design/packet.md" "$repo/game/design/stray.md")"

# No --path: the whole tree, as before, and no outside file.
bash "$SNAP" diff "$plan" R2 --repo "$repo" >/dev/null 2>&1 || true
expect "no --path: stray and peer file both listed" "$(rf R2 paths 2)" \
  "$(printf '%s\n' "$repo/game/design/packet.md" "$repo/game/design/stray.md" "$repo/game/peer-edit.md")"
checks=$((checks + 1))
[[ ! -e "$(rf R2 outside 2)" ]] || { echo "FAIL no --path wrote outside list 2"; fails=$((fails + 1)); }

# A second repo with no --path inside it keeps its whole tree in scope.
other="$tmp/code"
git init -q "$other"; git -C "$other" config user.email t@t; git -C "$other" config user.name t
echo a >"$other/a.txt"; git -C "$other" add a.txt; git -C "$other" commit -qm init
bash "$SNAP" base "$plan" R3 --repo "$repo" --repo "$other" >/dev/null
echo b >>"$other/a.txt"
echo row >>"$repo/game/design/packet.md"
bash "$SNAP" diff "$plan" R3 --repo "$repo" --repo "$other" --path "$repo/game/design" >/dev/null 2>&1 || true
expect "repo without --path inside is whole-tree" "$(rf R3 paths 1)" \
  "$(printf '%s\n' "$other/a.txt" "$repo/game/design/packet.md")"

if (( fails )); then echo "$fails of $checks checks failed"; exit 1; fi
echo "ok — $checks checks"
