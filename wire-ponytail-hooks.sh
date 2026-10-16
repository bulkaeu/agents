#!/usr/bin/env bash
#
# Wire the vendored ponytail hooks (vendor/ponytail/hooks) into Claude Code, Cursor and Codex.
#
# Every hook command is "<absolute node>" "<this checkout>/vendor/ponytail/hooks/<script>.js".
# node is resolved with `command -v node` at wiring time, because GUI-launched hosts do not
# see a shell's PATH; re-run this script if node moves. The hooks run from the checkout this
# script lives in, so the real run belongs in the main checkout, not a worktree.
#
#   bash wire-ponytail-hooks.sh              add (or refresh) ponytail's entries
#   bash wire-ponytail-hooks.sh --dry-run    print each target's diff, write nothing
#   bash wire-ponytail-hooks.sh --uninstall  remove exactly ponytail's entries, then run
#                                            ponytail's own scripts/uninstall.js
#   bash wire-ponytail-hooks.sh --uninstall --dry-run   show the removal diff only
#   bash wire-ponytail-hooks.sh --help       show this text
#
# Targets:
#   ~/.claude/settings.json  SessionStart, SubagentStart (general-purpose only), UserPromptSubmit
#   ~/.cursor/hooks.json     via upstream scripts/cursor-hooks.js, then node made absolute
#   ~/.codex/hooks.json      SessionStart, UserPromptSubmit (no SubagentStart), PLUGIN_DATA inline
#
# Entries whose command matches /hooks/ponytail-[a-z-]+\.js are replaced on every run, so a
# re-run is idempotent and every other entry is left as it was. JSON is edited with `jq -a`
# only, written through a temp file in the target's directory. Before the first write to an
# existing target it is copied to <file>.bak-ponytail-<YYYYMMDD>; an existing backup is never
# overwritten. ~/.codex/config.toml is never touched.
#
# Exit codes:
#   0  done (or dry run printed)
#   1  node, jq or a vendored file is missing, or a target is not valid JSON
#   2  bad usage
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VENDOR="$REPO/vendor/ponytail"
HOOKS="$VENDOR/hooks"
CURSOR_SCRIPT="$VENDOR/scripts/cursor-hooks.js"
UNINSTALL_SCRIPT="$VENDOR/scripts/uninstall.js"
STAMP="$(date +%Y%m%d)"
PONYTAIL_RE='/hooks/ponytail-[a-z-]+\.js'

CLAUDE_FILE="$HOME/.claude/settings.json"
CURSOR_FILE="$HOME/.cursor/hooks.json"
CODEX_FILE="$HOME/.codex/hooks.json"

usage() { sed -n '3,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//; /^#$/s/#//'; }

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

die() { echo "wire-ponytail-hooks: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq not found"

# --- node, as an absolute physical path ---------------------------------------------
resolve_physical() {
  local p="$1" link
  while [[ -L "$p" ]]; do
    link="$(readlink "$p")"
    case "$link" in
      /*) p="$link" ;;
      *)  p="$(dirname "$p")/$link" ;;
    esac
  done
  printf '%s/%s\n' "$(cd "$(dirname "$p")" && pwd -P)" "$(basename "$p")"
}

NODE_ON_PATH="$(command -v node 2>/dev/null || true)"
[[ -n "$NODE_ON_PATH" && "$NODE_ON_PATH" == /* ]] || die "node not found on PATH"
NODE="$(resolve_physical "$NODE_ON_PATH")"
[[ -x "$NODE" ]] || die "node resolved to $NODE, which is not executable"

for f in ponytail-activate.js ponytail-subagent.js ponytail-mode-tracker.js; do
  [[ -f "$HOOKS/$f" ]] || die "missing $HOOKS/$f"
done
[[ -f "$CURSOR_SCRIPT" ]] || die "missing $CURSOR_SCRIPT"
[[ -f "$UNINSTALL_SCRIPT" ]] || die "missing $UNINSTALL_SCRIPT"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/wire-ponytail.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

# --- the commands ---------------------------------------------------------------------
cmd() { printf '"%s" "%s/%s"' "$NODE" "$HOOKS" "$1"; }
ACTIVATE_CMD="$(cmd ponytail-activate.js)"
SUBAGENT_CMD="PONYTAIL_SUBAGENT_MATCHER='^general-purpose\$' $(cmd ponytail-subagent.js)"
TRACKER_CMD="$(cmd ponytail-mode-tracker.js)"
CODEX_ENV="PLUGIN_DATA=\"$HOME/.codex/ponytail\""

# jq: drop ponytail commands from Claude/Codex-shaped .hooks; leave untouched groups and
# events alone, drop only the ones this emptied, and drop .hooks itself only if it emptied.
JQ_STRIP='
  def isp: (.command? // "") | type == "string" and test($re);
  def strip_groups:
    map(if ((.hooks? // []) | type == "array" and any(.[]; isp))
        then (.hooks |= map(select(isp | not))) | select(.hooks | length > 0)
        else . end);
  if (.hooks | type) == "object" then
    (.hooks | length) as $before
    | .hooks |= with_entries(
        .value as $orig
        | .value |= (if type == "array" then strip_groups else . end)
        | select((.value | length > 0) or ($orig | length == 0)))
    | if (.hooks | length) == 0 and $before > 0 then del(.hooks) else . end
  else . end'

# add <event> <matcher-or-empty> <command>
JQ_ADD='
  .hooks = (.hooks // {})
  | .hooks[$ev] = ((.hooks[$ev] // [])
      + [ (if $m == "" then {} else {matcher: $m} end)
          + {hooks: [{type: "command", command: $c, timeout: 5}]} ])'

# Cursor: make the leading `node ` of ponytail's commands the absolute node.
JQ_CURSOR_NODE='
  .hooks |= with_entries(.value |= map(
    if ((.command? // "") | type == "string" and test($re) and startswith("node "))
    then .command = ($node | tojson) + (.command | ltrimstr("node"))
    else . end))'

json_in() { # print the target's JSON, or {} when missing
  if [[ -f "$1" ]]; then
    jq -a . "$1" >/dev/null 2>&1 || die "$1 is not valid JSON; nothing was changed"
    cat "$1"
  else
    printf '{}\n'
  fi
}

# --- compute the new content of each target into $SCRATCH -----------------------------
build_claude() { # out
  local out="$1"
  json_in "$CLAUDE_FILE" | jq -a --arg re "$PONYTAIL_RE" "$JQ_STRIP" > "$out.1"
  if (( UNINSTALL )); then mv "$out.1" "$out"; return; fi
  jq -a --arg ev SessionStart --arg m 'startup|resume|clear|compact' --arg c "$ACTIVATE_CMD" "$JQ_ADD" "$out.1" \
    | jq -a --arg ev SubagentStart --arg m '' --arg c "$SUBAGENT_CMD" "$JQ_ADD" \
    | jq -a --arg ev UserPromptSubmit --arg m '' --arg c "$TRACKER_CMD" "$JQ_ADD" > "$out"
  rm -f "$out.1"
}

build_codex() { # out
  local out="$1"
  json_in "$CODEX_FILE" | jq -a --arg re "$PONYTAIL_RE" "$JQ_STRIP" > "$out.1"
  if (( UNINSTALL )); then mv "$out.1" "$out"; return; fi
  jq -a --arg ev SessionStart --arg m 'startup|resume|clear|compact' --arg c "$CODEX_ENV $ACTIVATE_CMD" "$JQ_ADD" "$out.1" \
    | jq -a --arg ev UserPromptSubmit --arg m '' --arg c "$CODEX_ENV $TRACKER_CMD" "$JQ_ADD" > "$out"
  rm -f "$out.1"
}

# Cursor goes through upstream's own merger, run against a throwaway HOME holding a copy
# of the target, so the real file is only ever replaced by write_target below.
build_cursor() { # out  (prints nothing to out when the result is "no file")
  local out="$1" fake="$SCRATCH/cursor-home"
  rm -rf "$fake"; mkdir -p "$fake/.cursor"
  if [[ -f "$CURSOR_FILE" ]]; then
    json_in "$CURSOR_FILE" >/dev/null
    cp "$CURSOR_FILE" "$fake/.cursor/hooks.json"
  fi
  local action=install
  (( UNINSTALL )) && action=uninstall
  HOME="$fake" "$NODE" "$CURSOR_SCRIPT" "$action" >/dev/null \
    || die "scripts/cursor-hooks.js $action failed"
  if [[ -f "$fake/.cursor/hooks.json" ]]; then
    if (( UNINSTALL )); then
      # upstream wrote it with JSON.stringify; re-emit with jq -a only if it changed anything
      if [[ -f "$CURSOR_FILE" ]] && cmp -s "$fake/.cursor/hooks.json" "$CURSOR_FILE"; then
        cp "$CURSOR_FILE" "$out"
      else
        jq -a . "$fake/.cursor/hooks.json" > "$out"
      fi
    else
      jq -a --arg re "$PONYTAIL_RE" --arg node "$NODE" "$JQ_CURSOR_NODE" "$fake/.cursor/hooks.json" > "$out"
    fi
  else
    : > "$out.absent"
  fi
}

# --- apply ---------------------------------------------------------------------------
show_diff() { # label target new
  local label="$1" target="$2" new="$3" old
  old="$target"
  [[ -f "$old" ]] || old=/dev/null
  echo "=== $label: $target"
  if [[ -f "$new.absent" ]]; then
    if [[ -f "$target" ]]; then
      echo "(would delete the file: only ponytail entries were in it)"
      diff -u "$target" /dev/null || true
    else
      echo "(no change)"
    fi
  elif cmp -s "$old" "$new"; then
    echo "(no change)"
  else
    diff -u "$old" "$new" || true
  fi
}

backup() { # target
  local b="$1.bak-ponytail-$STAMP"
  if [[ -f "$1" && ! -e "$b" ]]; then
    cp -p "$1" "$b"
    echo "  backed up to $b"
  fi
}

write_target() { # label target new
  local label="$1" target="$2" new="$3" dir tmp
  if [[ -f "$new.absent" ]]; then
    if [[ -f "$target" ]]; then
      backup "$target"
      rm -f "$target"
      echo "$label: removed $target (only ponytail entries were in it)"
    else
      echo "$label: no change"
    fi
    return
  fi
  if [[ -f "$target" ]] && cmp -s "$target" "$new"; then
    echo "$label: no change ($target)"
    return
  fi
  if (( UNINSTALL )) && [[ ! -f "$target" ]]; then
    echo "$label: no change (no $target)"
    return
  fi
  dir="$(dirname "$target")"
  mkdir -p "$dir"
  backup "$target"
  tmp="$(mktemp "$dir/.$(basename "$target").XXXXXX")"
  if [[ -f "$target" ]]; then cp -p "$target" "$tmp"; else chmod 644 "$tmp"; fi
  cat "$new" > "$tmp"
  mv "$tmp" "$target"
  echo "$label: wrote $target"
}

build_claude "$SCRATCH/claude.json"
build_cursor "$SCRATCH/cursor.json"
build_codex  "$SCRATCH/codex.json"

if (( DRY_RUN )); then
  echo "node:  $NODE"
  echo "hooks: $HOOKS"
  show_diff "Claude Code" "$CLAUDE_FILE" "$SCRATCH/claude.json"
  show_diff "Cursor"      "$CURSOR_FILE" "$SCRATCH/cursor.json"
  show_diff "Codex"       "$CODEX_FILE"  "$SCRATCH/codex.json"
  (( UNINSTALL )) && echo "(would then run: node scripts/uninstall.js)"
  echo "dry run: nothing written"
  exit 0
fi

write_target "Claude Code" "$CLAUDE_FILE" "$SCRATCH/claude.json"
write_target "Cursor"      "$CURSOR_FILE" "$SCRATCH/cursor.json"
write_target "Codex"       "$CODEX_FILE"  "$SCRATCH/codex.json"

if (( UNINSTALL )); then
  "$NODE" "$UNINSTALL_SCRIPT"
  echo "ponytail hooks removed. Restart Claude Code, Cursor and Codex."
else
  echo "ponytail hooks wired (node: $NODE). Restart Claude Code, Cursor and Codex;"
  echo "Codex needs the new hooks trusted with /hooks before they run."
fi
