#!/usr/bin/env bash
#
# Conflict check for the vendored ponytail hooks and skills (vendor/ponytail/) against this
# repo. Run by update-ponytail.sh after every refresh; also safe to run by hand. Read-only.
#
#   bash check-ponytail.sh                 check this checkout
#   bash check-ponytail.sh --root <dir>    check a copy of the repo at <dir>
#
# Prints `FAIL P<n> — <why>` per failure and exits 1 on any; prints `ok — N checks` and
# exits 0 when clean. Exit 2 on bad usage. Needs `node` (ponytail needs it anyway), used
# only to read the hook manifests and skill frontmatter.
#
#   P1  no vendored skill directory name or `name:` equals a skills/* name
#   P2  hook event names are exactly the set wire-ponytail-hooks.sh knows how to wire
#   P3  mode tracker still gates on ^[/@$]ponytail; deactivation still matches exactly
#   P4  ponytail-subagent.js still reads PONYTAIL_SUBAGENT_MATCHER
#   P5  vendor/ponytail/UPSTREAM exists and names a 40-hex sha
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--root" ]]; then
  [[ -n "${2:-}" && -d "$2" ]] || { echo "usage: $0 [--root <dir>]" >&2; exit 2; }
  ROOT="$(cd "$2" && pwd)"
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--root <dir>]" >&2; exit 2
fi
command -v node >/dev/null 2>&1 || { echo "node is required" >&2; exit 2; }

V="$ROOT/vendor/ponytail"
checks=0
failed=0
fail() { echo "FAIL $1 — $2"; failed=$((failed + 1)); }

# --- P1: name collisions ------------------------------------------------------------
checks=$((checks + 1))
ours=" "
for d in "$ROOT"/skills/*/; do
  [[ -d "$d" ]] && ours="$ours$(basename "$d") "
done
for d in "$V"/skills/*/; do
  [[ -d "$d" ]] || continue
  dn="$(basename "$d")"
  case "$ours" in *" $dn "*) fail P1 "vendored skill directory '$dn' collides with skills/$dn" ;; esac
  # frontmatter name: first `name:` line between the opening and closing ---
  fm="$(awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} /^name:/{sub(/^name:[ \t]*/,""); gsub(/["'\''\r ]/,""); print; exit}' "$d/SKILL.md" 2>/dev/null)"
  if [[ -n "$fm" ]]; then
    case "$ours" in *" $fm "*) fail P1 "vendored skill $dn declares name '$fm', which collides with skills/$fm" ;; esac
  fi
done

# --- P2: hook event names -----------------------------------------------------------
events() { # <json file> -> sorted event names, space separated; empty on error
  node -e 'try{const h=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).hooks;
    console.log(Object.keys(h).sort().join(" "))}catch(e){process.exit(1)}' "$1" 2>/dev/null
}
checks=$((checks + 1))
got="$(events "$V/hooks/claude-codex-hooks.json")" || got="<unreadable>"
want="SessionStart SubagentStart UserPromptSubmit"
[[ "$got" == "$want" ]] || fail P2 "hooks/claude-codex-hooks.json events are [$got], expected [$want]"
got="$(events "$V/hooks/cursor-hooks.json")" || got="<unreadable>"
want="beforeSubmitPrompt sessionStart"
[[ "$got" == "$want" ]] || fail P2 "hooks/cursor-hooks.json events are [$got], expected [$want]"

# --- P3: prompt gating and deactivation ---------------------------------------------
checks=$((checks + 1))
grep -qF '^[/@$]ponytail' "$V/hooks/ponytail-mode-tracker.js" 2>/dev/null \
  || fail P3 "ponytail-mode-tracker.js no longer gates on ^[/@\$]ponytail"
grep -qF "t === 'stop ponytail' || t === 'normal mode'" "$V/hooks/ponytail-config.js" 2>/dev/null \
  || fail P3 "ponytail-config.js no longer matches deactivation as exactly 'stop ponytail' or 'normal mode'"

# --- P4: subagent matcher -----------------------------------------------------------
checks=$((checks + 1))
grep -qF 'PONYTAIL_SUBAGENT_MATCHER' "$V/hooks/ponytail-subagent.js" 2>/dev/null \
  || fail P4 "ponytail-subagent.js no longer reads PONYTAIL_SUBAGENT_MATCHER"

# --- P5: pin ------------------------------------------------------------------------
checks=$((checks + 1))
if [[ ! -f "$V/UPSTREAM" ]]; then
  fail P5 "vendor/ponytail/UPSTREAM is missing"
elif ! grep -qE '^sha: [0-9a-f]{40}$' "$V/UPSTREAM"; then
  fail P5 "vendor/ponytail/UPSTREAM has no 'sha: <40-hex>' line"
fi

if (( failed > 0 )); then exit 1; fi
echo "ok — $checks checks"
