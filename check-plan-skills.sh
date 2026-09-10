#!/usr/bin/env bash
#
# Static checks for the plan-skill family: skills/plan-*/ and skills/plan-shared/.
# Turns the audit's mechanical findings into a regression guard. Run it before committing.
#
#   bash check-plan-skills.sh                 check this checkout
#   bash check-plan-skills.sh --root <dir>    check a copy of the repo at <dir>
#
# Prints `FAIL [Kn] file:line — message` per failure and exits 1 on any; prints
# `ok — N checks, M files` and exits 0 when clean. Check ids are K1–K16 (see README).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--root" ]]; then
  [[ -n "${2:-}" && -d "$2" ]] || { echo "usage: $0 [--root <dir>]" >&2; exit 2; }
  ROOT="$(cd "$2" && pwd)"
fi
cd "$ROOT" || exit 2

SKILLS=(plan-build plan-continue plan-finish plan-review plan-status plan-summary)
checks=0
# Failures go to a report file, not a counter: a counter bumped inside a pipeline lives in a
# subshell and is lost (bash 3.2, the macOS default, has no lastpipe).
REPORT="$(mktemp)"
trap 'rm -f "$REPORT"' EXIT

fail() { echo "FAIL [$1] $2 — $3" | tee -a "$REPORT"; }

# Every markdown file in the family, repo-relative.
FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(
  find skills/plan-build skills/plan-continue skills/plan-finish skills/plan-review \
    skills/plan-status skills/plan-summary skills/plan-shared -name '*.md' -type f 2>/dev/null | sort)
[[ ${#FILES[@]} -gt 0 ]] || { echo "FAIL [K0] $ROOT — no plan-skill files found"; exit 1; }

# Grep the family for a pattern, excluding one file; report each hit.
hits_except() { # <id> <exclude-file> <ere> <message>
  local f
  for f in "${FILES[@]}"; do
    [[ "$f" == "$2" ]] && continue
    grep -nE "$3" "$f" 2>/dev/null | while IFS=: read -r n _; do
      echo "FAIL [$1] $f:$n — $4"
    done
  done
}
record() { tee -a "$REPORT"; }

frontmatter() { awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f' "$1"; }
description() {
  frontmatter "$1" | awk '/^description:/ {d=1; sub(/^description: *(>-)? */, ""); if ($0 != "") printf "%s ", $0; next}
    d && /^[a-z-]+:/ {exit} d {sub(/^ +/, ""); printf "%s ", $0}' | sed 's/ $//'
}

# K1 — every family .md is at most 200 lines
checks=$((checks + 1))
for f in "${FILES[@]}"; do
  n=$(wc -l <"$f" | tr -d ' ')
  (( n > 200 )) && fail K1 "$f:$n" "$n lines, over the 200-line ceiling"
done

# K2 — frontmatter keys exact; argument-hint pinned per skill
checks=$((checks + 1))
for s in "${SKILLS[@]}"; do
  f="skills/$s/SKILL.md"
  [[ -f "$f" ]] || { fail K2 "$f:1" "missing"; continue; }
  keys="$(frontmatter "$f" | grep -oE '^[a-z-]+:' | tr -d ':' | sort | tr '\n' ' ')"
  [[ "$keys" == "argument-hint description disable-model-invocation name " ]] \
    || fail K2 "$f:1" "frontmatter keys are '$keys'"
  frontmatter "$f" | grep -qx "name: $s" || fail K2 "$f:1" "name is not $s"
  frontmatter "$f" | grep -qx 'disable-model-invocation: true' || fail K2 "$f:1" "disable-model-invocation is not true"
  case "$s" in
    plan-build|plan-continue) want='argument-hint: "[optional plan path] [--dry-run]"' ;;
    *) want='argument-hint: "[optional plan path]"' ;;
  esac
  frontmatter "$f" | grep -qxF "$want" || fail K2 "$f:1" "argument-hint changed; want $want"
done

# K3 — descriptions: third person, <= 1024 chars, closing "Use when" trigger kept
checks=$((checks + 1))
for s in "${SKILLS[@]}"; do
  f="skills/$s/SKILL.md"; [[ -f "$f" ]] || continue
  d="$(description "$f")"
  (( ${#d} > 1024 )) && fail K3 "$f:3" "description is ${#d} characters"
  first="${d%% *}"
  [[ "$first" =~ ^[A-Z][a-z]+s$ ]] || fail K3 "$f:3" "description opens '$first', not a third-person verb"
  [[ "$d" == *"Use when "* ]] || fail K3 "$f:3" "description lost its 'Use when …' trigger"
done

# K4 — the ladder's rung phrases live only in CONVENTIONS.md; all six skills cite it
checks=$((checks + 1))
hits_except K4 skills/plan-shared/CONVENTIONS.md 'settings\*\.json|ecently modified (plan )?in `~/\.claude/plans/`' \
  "plan ladder restated; cite plan-shared/CONVENTIONS.md" | record
for s in "${SKILLS[@]}"; do
  grep -q 'CONVENTIONS\.md' "skills/$s/SKILL.md" 2>/dev/null || fail K4 "skills/$s/SKILL.md:1" "does not cite CONVENTIONS.md"
done

# K5 — stop rows, the asked-alone list and the harness-prompt rule live only in STOPS.md
checks=$((checks + 1))
hits_except K5 skills/plan-shared/STOPS.md '^\| *(`git push --force`|Database migration apply|Deploying|Publishing to a live surface)' \
  "stop-list row outside STOPS.md" | record
hits_except K5 skills/plan-shared/STOPS.md '[Mm]igration, deploy, publish(,| and) send|migration .{0,20}deploy.{0,20}publish.{0,30}asked' \
  "asked-alone set restated outside STOPS.md" | record
hits_except K5 skills/plan-shared/STOPS.md 'chain it, or wrap it' \
  "harness-prompt rule restated outside STOPS.md" | record
for s in plan-build plan-continue plan-finish; do
  grep -q 'STOPS\.md' "skills/$s/SKILL.md" 2>/dev/null || fail K5 "skills/$s/SKILL.md:1" "does not cite STOPS.md"
done

# K6 — no iconed Progress-table rows in any skill file (the Stop hook would count them as live work)
checks=$((checks + 1))
hits_except K6 '' '^\| *[A-Za-z0-9§.-]+ (⬜|🟡|✅|⛔|⏭️) *\|' "iconed table row in a skill file" | record

# K7 — markdown links and cross-skill paths resolve
checks=$((checks + 1))
resolve_md() { # <file> <target> — succeed if the target resolves from the file, the skills/ dir, or the root
  local dir t="$2"
  dir="$(dirname "$1")"
  t="${t%%#*}"
  [[ -z "$t" ]] && return 0
  [[ -e "$dir/$t" || -e "skills/$t" || -e "$t" ]]
}
for f in "${FILES[@]}"; do
  # markdown links
  grep -noE '\]\([^)]+\)' "$f" | while IFS=: read -r n m; do
    t="${m#](}"; t="${t%)}"
    [[ "$t" == http* || "$t" == \#* || "$t" == *'<'* || "$t" == mailto:* ]] && continue
    resolve_md "$f" "$t" || echo "FAIL [K7] $f:$n — link target '$t' does not resolve"
  done
  # ../<skill>/<file> paths, including ${CLAUDE_SKILL_DIR}/../<skill>/<file>
  grep -noE '\.\./plan-[a-z-]+/[A-Za-z0-9_./-]+' "$f" | while IFS=: read -r n t; do
    t="${t%.}"
    [[ -e "skills/${t#../}" ]] || echo "FAIL [K7] $f:$n — path '$t' does not resolve"
  done
  # backticked *.md names: bare names against siblings, plan-shared/, rules/ and skill dirs
  grep -noE '`[A-Za-z0-9_./-]+\.md`' "$f" | while IFS=: read -r n t; do
    t="${t//\`/}"
    case "$t" in README.md|AGENTS.md|CLAUDE.md|SKILL.md) continue ;; esac
    if [[ "$t" == */* ]]; then
      resolve_md "$f" "$t" || echo "FAIL [K7] $f:$n — '$t' does not resolve"
    else
      [[ -e "$(dirname "$f")/$t" || -e "skills/plan-shared/$t" || -e "rules/$t" ]] \
        || compgen -G "skills/*/$t" >/dev/null \
        || echo "FAIL [K7] $f:$n — '$t' is not a sibling, a plan-shared file, a rule or a skill file"
    fi
  done
done | record

# K8 — time-sensitive wording: anecdotes and dated claims belong in commit messages, not instructions
checks=$((checks + 1))
hits_except K8 '' '[Oo]nce cut|[Hh]as happened|[Pp]romoted from|[Aa] cold reader|[Ii]n one afternoon|[Mm]easured (on|during|in) ' \
  "time-sensitive wording" | record

# K9 — severity words stay within the five-level scale
checks=$((checks + 1))
hits_except K9 '' '\*\*(Important|Minor|Major|Blocker|Trivial|Nit)\*\*|^\| *(Important|Minor|Blocker|Trivial|Nit) *\|' \
  "severity label outside Critical/High/Medium/Low/Very Low" | record

# K10 — the legend in CONVENTIONS.md matches the rule byte for byte
checks=$((checks + 1))
want="$(grep -m1 '^\*\*Legend:\*\*' rules/plan-progress-section.md 2>/dev/null)"
got="$(grep -m1 '^\*\*Legend:\*\*' skills/plan-shared/CONVENTIONS.md 2>/dev/null)"
[[ -n "$want" && "$want" == "$got" ]] || fail K10 "skills/plan-shared/CONVENTIONS.md:1" "legend differs from rules/plan-progress-section.md"

# K11 — RULES.md rules 1–8 keep their headings: Notes in old plans cite them
checks=$((checks + 1))
expected='## 1. Uninterrupted by default
## 2. Park, don'"'"'t halt
## 3. The stop-list
## 4. A harness prompt is not a stop-list item
## 5. One boundary, one edit
## 6. Shared state
## 7. A check you did not run is not a check that passed
## 8. Never bend the plan to make a step pass'
actual="$(grep -E '^## [1-8]\. ' skills/plan-build/RULES.md 2>/dev/null)"
[[ "$actual" == "$expected" ]] || fail K11 "skills/plan-build/RULES.md:1" "rules 1–8 headings changed"

# K14 — plan-shared is not a command; every skill has a README row
checks=$((checks + 1))
[[ -e skills/plan-shared/SKILL.md ]] && fail K14 "skills/plan-shared/SKILL.md:1" "plan-shared must not be a skill"
for d in skills/*/; do
  s="$(basename "$d")"
  [[ -f "$d/SKILL.md" ]] || continue
  grep -qE "^\| \`$s\` \|" README.md 2>/dev/null || fail K14 "README.md:1" "no Skills-table row for $s"
done

# K15 — every script under skills/ parses
checks=$((checks + 1))
while IFS= read -r sh; do
  bash -n "$sh" 2>/dev/null || fail K15 "$sh:1" "bash -n fails"
done < <(find skills -name '*.sh' -type f | sort)

# K16 — the repo's own sanitizer passes
checks=$((checks + 1))
if [[ -f sanitize-check.sh ]]; then
  out="$(bash sanitize-check.sh 2>&1)" || fail K16 "sanitize-check.sh:1" "$(head -3 <<<"$out" | tr '\n' ' ')"
else
  fail K16 "sanitize-check.sh:1" "missing"
fi

fails="$(grep -c '^FAIL' "$REPORT")"
if (( fails > 0 )); then
  echo "$fails failure(s) across $checks checks"
  exit 1
fi
echo "ok — $checks checks, ${#FILES[@]} files"
