#!/usr/bin/env bash
#
# Link this repo's skills and rules into every agent directory on this machine.
#
# The repo is the single source of truth. Each agent dir gets a symlink pointing here,
# so editing a file in this checkout changes what every agent loads. Idempotent and
# non-destructive: anything it displaces is moved to a dated backup root, and it refuses
# to touch content that differs from the repo copy.
#
#   bash install.sh            link everything
#   bash install.sh --dry-run  say what it would do, change nothing
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.agents-config-backup-$(date +%Y%m%d)"
TILDE="~"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

linked=0; skipped=0; relinked=0; backed_up=0; conflicts=0
declare -a CREATED=()

say()  { printf '%s\n' "$*"; }
run()  { if (( DRY_RUN )); then say "    would: $*"; else "$@"; fi; }

# link <target-in-repo> <destination>
link() {
  local target="$1" dest="$2" name="${2/#$HOME/$TILDE}"

  if [[ ! -e "$target" ]]; then
    say "!!  $name -> missing in repo ($target), skipped"
    conflicts=$((conflicts + 1)); return
  fi

  # 1. already correct
  if [[ -L "$dest" && "$(readlink "$dest")" == "$target" ]]; then
    say "==  $name (already linked)"; skipped=$((skipped + 1))
    CREATED+=("$dest"); return
  fi

  # 2. a symlink pointing somewhere else — relink, record the old target.
  #    No content backup: a symlink holds none, and the tree it pointed at is already in the repo.
  if [[ -L "$dest" ]]; then
    local old; old="$(readlink "$dest")"
    say "->  $name (relinking; was $old)"
    if (( ! DRY_RUN )); then
      mkdir -p "$BACKUP"
      printf '%s\t%s\n' "$dest" "$old" >> "$BACKUP/relinked.txt"
    fi
    run rm "$dest"
    run ln -s "$target" "$dest"
    relinked=$((relinked + 1)); CREATED+=("$dest"); return
  fi

  # 3. real file or directory — only displace it if it is byte-identical to the repo copy
  if [[ -e "$dest" ]]; then
    if diff -r -q "$dest" "$target" >/dev/null 2>&1; then
      local sub; sub="$(backup_subdir "$dest")"
      say "++  $name (identical; backing up to ${BACKUP/#$HOME/$TILDE}/$sub)"
      run mkdir -p "$BACKUP/$sub"
      run mv "$dest" "$BACKUP/$sub/"
      run ln -s "$target" "$dest"
      backed_up=$((backed_up + 1)); linked=$((linked + 1)); CREATED+=("$dest"); return
    fi
    say "!!  $name DIFFERS from the repo copy — not touched. Diff:"
    { diff -r "$dest" "$target" 2>&1 | sed 's/^/      /' | head -30; } || true
    conflicts=$((conflicts + 1)); return
  fi

  # 0. nothing there — just link
  say "++  $name"
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$target" "$dest"
  linked=$((linked + 1)); CREATED+=("$dest")
}

# mirror where a displaced item came from, so the rollback is obvious
backup_subdir() {
  case "$1" in
    "$HOME"/.claude/*) echo "claude" ;;
    "$HOME"/.cursor/*) echo "cursor" ;;
    "$HOME"/.agents/*) echo "agents" ;;
    *)                 echo "other"  ;;
  esac
}

say "repo:   $REPO"
say "backup: $BACKUP"
(( DRY_RUN )) && say "MODE:   dry run — nothing will change"
say ""

say "skills"
mkdir -p "$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.agents/skills"
for dir in "$REPO"/skills/*/; do
  name="$(basename "$dir")"
  link "$REPO/skills/$name" "$HOME/.claude/skills/$name"
  link "$REPO/skills/$name" "$HOME/.cursor/skills/$name"
  link "$REPO/skills/$name" "$HOME/.agents/skills/$name"
done

say ""
say "rules"
mkdir -p "$HOME/.claude/rules" "$HOME/.cursor/rules"
for file in "$REPO"/rules/*.md; do
  name="$(basename "$file" .md)"
  link "$REPO/rules/$name.md" "$HOME/.claude/rules/$name.md"
  link "$REPO/rules/$name.md" "$HOME/.cursor/rules/$name.mdc"   # Cursor needs the .mdc extension
done

say ""
say "global instructions"
link "$REPO/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# every link must resolve, or the skill/rule silently stops loading
say ""
say "verifying"
broken=0
for dest in "${CREATED[@]}"; do
  if (( DRY_RUN )); then continue; fi
  if [[ ! -e "$dest" ]]; then
    say "!!  BROKEN: ${dest/#$HOME/$TILDE} -> $(readlink "$dest" 2>/dev/null || echo '?')"
    broken=$((broken + 1))
  fi
done
(( broken == 0 )) && say "    all ${#CREATED[@]} links resolve"

say ""
say "linked $linked · relinked $relinked · already ok $skipped · backed up $backed_up · conflicts $conflicts · broken $broken"

if (( conflicts > 0 || broken > 0 )); then
  say ""
  say "Nothing was overwritten. Reconcile the differing paths above, then re-run."
  exit 1
fi
