#!/usr/bin/env bash
#
# Conflict check across every vendored third-party skill set (vendor/<name>/) against this
# repo. Run by update-vendor.sh after every refresh; also safe to run by hand. Read-only.
#
#   bash check-vendor.sh                 check this checkout
#   bash check-vendor.sh --root <dir>    check a copy of the repo at <dir>
#
# Prints `FAIL P<n> — <why>` per failure and exits 1 on any; prints `ok — N checks` and
# exits 0 when clean. Exit 2 on bad usage. A vendor/<name>/ with no skills/ directory is not
# vendored yet: it is skipped and named in a `skip` line, which is not a failure.
#
# The check numbers match check-ponytail.sh's, so a failure reads the same in both:
#   P1  no vendored skill directory name or frontmatter `name:` equals a skills/* name,
#       another vendored skill's directory name or `name:`, or a bundled Claude Code skill name
#   P5  every vendor/<name>/UPSTREAM exists and names a 40-hex sha
#
# A skill whose directory name differs from its `name:` is fine; both are checked.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--root" ]]; then
  [[ -n "${2:-}" && -d "$2" ]] || { echo "usage: $0 [--root <dir>]" >&2; exit 2; }
  ROOT="$(cd -- "$2" && pwd)"
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--root <dir>]" >&2; exit 2
fi
# A root missing either directory is a mistyped or partial copy, not a checkout: with no
# skills/ to compare against, P1 would silently pass every first-party collision.
[[ -d "$ROOT/vendor" && -d "$ROOT/skills" ]] \
  || { echo "not a copy of this repo (needs vendor/ and skills/): $ROOT" >&2; exit 2; }

# Skills Claude Code ships itself. Taken from sessions' own skill listings; extended by hand.
# Single space between every name and at both ends: P1 matches on *" $nm "*.
RESERVED=" code-review simplify security-review init loop schedule run update-config \
keybindings-help fewer-permission-prompts plugin-authoring workflow-authoring claude-api \
dataviz artifact-design "

checks=0
failed=0
fail() { echo "FAIL $1 — $2"; failed=$((failed + 1)); }

ours=" "
for d in "$ROOT"/skills/*/; do
  [[ -d "$d" ]] && ours="$ours$(basename "$d") "
done

# One entry per vendored skill: its set, directory name and frontmatter name (empty if none).
sets=() dirs=() names=()
for v in "$ROOT"/vendor/*/; do
  [[ -d "$v" ]] || continue
  vn="$(basename "$v")"
  if [[ ! -d "$v/skills" ]]; then
    echo "skip vendor/$vn — no skills/ yet"
    continue
  fi
  sets+=("$vn") ; dirs+=("") ; names+=("")   # placeholder row per set, for P5 below
  for d in "$v"/skills/*/; do
    [[ -d "$d" ]] || continue
    # frontmatter name: first `name:` line between the opening and closing ---. A CR line
    # ending and a leading BOM are stripped first: upstreams ship both, and either one would
    # otherwise hide the declared name from P1 — the name Claude Code resolves skills by.
    fm="$(awk '{sub(/\r$/,"")} NR==1{sub(/^\357\273\277/,"")} NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} /^name:/{sub(/^name:[ \t]*/,""); gsub(/["'\''\r ]/,""); print; exit}' "$d/SKILL.md" 2>/dev/null)"
    # Any other unreadable encoding is said out loud rather than skipping P1 in silence.
    [[ -f "$d/SKILL.md" && -z "$fm" ]] \
      && echo "warn vendor/$vn/skills/$(basename "$d")/SKILL.md — no frontmatter name: read, only the directory name is checked"
    sets+=("$vn") ; dirs+=("$(basename "$d")") ; names+=("$fm")
  done
done

# --- P1: name collisions ------------------------------------------------------------
checks=$((checks + 1))
n=${#sets[@]}
for ((i = 0; i < n; i++)); do
  [[ -n "${dirs[i]}" ]] || continue
  si="vendor/${sets[i]}/skills/${dirs[i]}"
  first_done=0
  for nm in "${dirs[i]}" "${names[i]}"; do
    [[ -n "$nm" ]] || continue
    [[ "$nm" == "${names[i]}" && "$nm" == "${dirs[i]}" && $first_done == 1 ]] && continue
    first_done=1
    case "$ours" in *" $nm "*) fail P1 "$si uses '$nm', which collides with skills/$nm" ;; esac
    case "$RESERVED" in *" $nm "*) fail P1 "$si uses '$nm', which is a bundled Claude Code skill name" ;; esac
  done
  for ((j = i + 1; j < n; j++)); do
    [[ -n "${dirs[j]}" ]] || continue
    for a in "${dirs[i]}" "${names[i]}"; do
      [[ -n "$a" ]] || continue
      if [[ "$a" == "${dirs[j]}" || "$a" == "${names[j]}" ]]; then
        fail P1 "$si and vendor/${sets[j]}/skills/${dirs[j]} both use '$a'"
        break
      fi
    done
  done
done

# --- P5: pin ------------------------------------------------------------------------
checks=$((checks + 1))
for ((i = 0; i < n; i++)); do
  [[ -z "${dirs[i]}" ]] || continue
  u="$ROOT/vendor/${sets[i]}/UPSTREAM"
  if [[ ! -f "$u" ]]; then
    fail P5 "vendor/${sets[i]}/UPSTREAM is missing"
  elif ! grep -qE '^sha: [0-9a-f]{40}$' "$u"; then
    fail P5 "vendor/${sets[i]}/UPSTREAM has no 'sha: <40-hex>' line"
  fi
done

if (( failed > 0 )); then exit 1; fi
echo "ok — $checks checks"
