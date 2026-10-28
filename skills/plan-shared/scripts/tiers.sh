#!/usr/bin/env bash
#
# Print the model each dispatch tier means on one host, read from CONVENTIONS.md's *Model tiers*
# table as it is on disk right now. Reports only; never edits.
#
#   tiers.sh <host>      host: claude-code | cursor | codex | opencode | other
#
# One line, ready to paste as the Run log's `tiers:` line:
#
#   tiers: opencode · agents <sha> · standard `<id>` · strong `<id>` (fallback `<id>`) · strongest …
#
# A run resolves its tiers with this at its start and after a context summary, and dispatches with
# what it printed. A tier line already in a Run log records what that run used; it is not an
# instruction to a later one. `other` prints `inherit` for every tier (CONVENTIONS.md, *Model tiers*).
#
# Exit 0 on success; 1 if the table or the host's column is missing or a cell is empty; 2 on a usage
# error.
set -euo pipefail

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

[[ $# -eq 1 ]] || usage
host="$1"
case "$host" in
  claude-code) col="Claude Code" ;;
  cursor) col="Cursor" ;;
  codex) col="Codex" ;;
  opencode) col="OpenCode" ;;
  other) col="" ;;
  -h | --help) usage ;;
  *) echo "tiers.sh: unknown host '$host'" >&2; usage ;;
esac

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
conventions="$here/../CONVENTIONS.md"
[[ -f "$conventions" ]] || { echo "tiers.sh: $conventions not found" >&2; exit 1; }
sha="$(git -C "$here" rev-parse --short HEAD 2>/dev/null || echo "no-git")"

if [[ -z "$col" ]]; then
  echo "tiers: other · agents $sha · standard inherit · strong inherit · strongest inherit"
  exit 0
fi

# The table: the header row naming `Tier`, then one row per tier. Cells hold no `|`.
cells="$(awk -F'|' -v col="$col" '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  /^\| *Tier *\|/ { for (i = 2; i < NF; i++) if (trim($i) == col) c = i; intable = 1; next }
  intable && /^\| *-/ { next }
  intable && /^\|/ { if (c) print trim($2) "\t" trim($c); next }
  intable { exit }
' "$conventions")"

[[ -n "$cells" ]] || { echo "tiers.sh: no '$col' column in the Model tiers table" >&2; exit 1; }

line="tiers: $host · agents $sha"
for tier in standard strong strongest; do
  cell="$(printf '%s\n' "$cells" | awk -F'\t' -v t="$tier" '$1 == t { print $2; exit }')"
  [[ -n "$cell" ]] || { echo "tiers.sh: no '$tier' row for '$col'" >&2; exit 1; }
  if [[ "$host" == "opencode" ]]; then
    # Pinned ids are the backticked spans: the model, then its fallback when the cell names one.
    ids=()
    while IFS= read -r id; do ids+=("$id"); done < <(printf '%s\n' "$cell" | grep -oE '`[^`]+`' | tr -d '`')
    [[ ${#ids[@]} -gt 0 ]] || { echo "tiers.sh: no model id in the '$tier' cell" >&2; exit 1; }
    line+=" · $tier \`${ids[0]}\`"
    [[ ${#ids[@]} -gt 1 ]] && line+=" (fallback \`${ids[1]}\`)"
  else
    line+=" · $tier $cell"
  fi
done
echo "$line"
