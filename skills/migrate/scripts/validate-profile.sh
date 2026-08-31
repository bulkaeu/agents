#!/bin/sh
# validate-profile.sh — hard gate for /migrate.
#
# POSIX sh only: no jq, no yq, no node. The profile frontmatter is a restricted
# YAML subset (flat dotted scalar keys, space-separated lists) precisely so this
# can be parsed with grep/sed/awk without silently misreading. Nesting and [a,b]
# sequences are REJECTED rather than best-guessed.
#
# Validates the mechanical frontmatter only. Prose sections are judgment and are
# checked by the stage that consumes them.
#
# Usage: validate-profile.sh <profile.md>     Exit: 0 ok, 1 invalid, 2 usage
set -u

rc=0
fail() { echo "FAIL [$1]: $2" >&2; rc=1; }

PROFILE="${1:-}"
[ -n "$PROFILE" ] || { echo "usage: validate-profile.sh <profile.md>" >&2; exit 2; }
[ -f "$PROFILE" ] || { echo "FAIL: profile not found: $PROFILE" >&2; exit 2; }

# Profile root = dir containing the .agents/.claude/.cursor dir holding the profile.
# Layout: <root>/.agents/migrations/<name>.md
PDIR=$(cd "$(dirname "$PROFILE")" 2>/dev/null && pwd) || exit 2

# The root derivation below walks up exactly two levels, so verify the layout
# actually is <root>/<dot-dir>/migrations/<file>.md before trusting it. Without
# this, a profile placed anywhere else silently resolves every path against the
# wrong directory -- the failure mode this gate exists to prevent.
PBASE=$(basename "$PDIR")
PPARENT=$(basename "$(dirname "$PDIR")")
if [ "$PBASE" != "migrations" ]; then
    echo "FAIL: profile must live in a 'migrations' directory, found '$PBASE'" >&2
    echo "      expected <root>/.agents/migrations/<name>.md (or .claude/, .cursor/)" >&2
    exit 2
fi
case "$PPARENT" in
    .agents|.claude|.cursor) ;;
    *) echo "FAIL: 'migrations' must sit inside .agents/, .claude/ or .cursor/, found '$PPARENT'" >&2
       exit 2 ;;
esac

ROOT=$(cd "$PDIR/../.." 2>/dev/null && pwd) || {
    echo "FAIL: cannot resolve profile root above $PDIR" >&2; exit 2; }

# --- frontmatter ------------------------------------------------------------
FM=$(awk 'NR==1 && $0=="---" {f=1; next} f && $0=="---" {exit} f {print}' "$PROFILE")
[ -n "$FM" ] || { echo "FAIL: no YAML frontmatter (file must start with ---)" >&2; exit 1; }

# Comment-stripped view. Structural checks MUST run on this, not on $FM:
# comments are legal YAML and routinely contain the very syntax we reject
# (an annotated profile explaining "no [a, b]" must not fail on its own prose).
FMC=$(printf '%s\n' "$FM" \
    | sed -E 's/[[:space:]]+#.*$//' \
    | grep -vE '^[[:space:]]*#' \
    | grep -vE '^[[:space:]]*$')

# Structural rejects: nesting and sequences make shell parsing unreliable.
if printf '%s\n' "$FMC" | grep -qE '^[[:space:]]+[^[:space:]]'; then
    fail "frontmatter" "indented/nested key found; use flat dotted keys (a.b.c: value)"
fi
# '[][]' is a POSIX bracket expression matching [ or ]. Do NOT use '\[\|\]':
# BRE alternation is a GNU/ugrep extension and silently stops matching on a
# stock BSD grep, which would let [a, b] sequences through unnoticed.
if printf '%s\n' "$FMC" | grep -q '[][]'; then
    fail "frontmatter" "YAML sequence [..] found; use space-separated values on one line"
fi

esc() { printf '%s' "$1" | sed 's/\./\\./g'; }

# Value of a key: strip the key, any trailing " # comment", and surrounding space.
getkey() {
    printf '%s\n' "$FM" \
      | grep -E "^$(esc "$1"):" \
      | head -n1 \
      | sed -E "s/^$(esc "$1"):[[:space:]]*//; s/[[:space:]]+#.*$//; s/[[:space:]]+$//"
}
countkey() { printf '%s\n' "$FM" | grep -cE "^$(esc "$1"):" || true; }

for k in name source.root target.root staff_dir commands.test \
         source.label target.label source.discovery.http source.discovery.cron \
         target.discovery.http target.discovery.cron commands.lint commands.typecheck \
         commit_prefix worktree_policy schema_policy.guide schema_policy.stop_before \
         skills.tdd skills.code_review; do
    [ "$(countkey "$k")" -gt 1 ] && fail "$k" "key appears more than once"
done

# --- required keys ----------------------------------------------------------
for k in name source.root target.root staff_dir commands.test; do
    [ -n "$(getkey "$k")" ] || fail "$k" "required key missing or empty"
done
[ "$rc" -eq 0 ] || exit "$rc"

SRC=$(getkey source.root); TGT=$(getkey target.root); STAFF=$(getkey staff_dir)

# --- roots exist AND stay inside the profile root ---------------------------
# The schema promises every path is relative to the profile root. Concatenating
# blindly does not enforce that: "../../../.." walks out of the workspace and an
# absolute "/etc" turns into "$ROOT//etc", which fails with a path the user never
# wrote. Reject both explicitly, then confirm the *resolved* path is under $ROOT.
resolve_under_root() {
    _key="$1"; _val="$2"
    case "$_val" in
        /*) fail "$_key" "must be relative to the profile root, got absolute path: $_val"
            return 1 ;;
    esac
    _cand="$ROOT/$_val"
    if [ ! -d "$_cand" ]; then
        fail "$_key" "not a directory under profile root: $_cand"
        return 1
    fi
    _real=$(cd "$_cand" 2>/dev/null && pwd) || { fail "$_key" "cannot resolve: $_cand"; return 1; }
    case "$_real" in
        "$ROOT"|"$ROOT"/*) ;;
        *) fail "$_key" "resolves outside the profile root: $_real (root $ROOT)"
           return 1 ;;
    esac
    return 0
}

resolve_under_root source.root "$SRC" || true
resolve_under_root target.root "$TGT" || true
if resolve_under_root staff_dir "$STAFF"; then
    [ -w "$ROOT/$STAFF" ] || fail "staff_dir" "not writable: $ROOT/$STAFF"
elif [ ! -e "$ROOT/$STAFF" ]; then
    echo "      hint: staff_dir holds the engine's bookkeeping and must exist before the first" >&2
    echo "            run; create it with: mkdir -p \"$ROOT/$STAFF\"" >&2
fi

# --- discovery paths expand to at least one existing path -------------------
check_discovery() {
    key="$1"; base="$2"
    val=$(getkey "$key")
    [ -n "$val" ] || return 0
    [ -d "$base" ] || return 0   # root failure already reported
    for tok in $val; do
        # Unquoted expansion below intentionally applies globbing; if nothing
        # matches, $1 stays the literal pattern and the -e test fails.
        if ! ( set -- $base/$tok; [ -e "$1" ] ); then
            fail "$key" "no existing path matches: $tok (under $base)"
        fi
    done
}
check_discovery source.discovery.http "$ROOT/$SRC"
check_discovery source.discovery.cron "$ROOT/$SRC"
check_discovery target.discovery.http "$ROOT/$TGT"
check_discovery target.discovery.cron "$ROOT/$TGT"

# --- commands ---------------------------------------------------------------
TESTCMD=$(getkey commands.test)
case "$TESTCMD" in
    *'{paths}'*) ;;
    *) fail "commands.test" "must contain the {paths} token, else the red/green gates run the whole suite" ;;
esac

LINTCMD=$(getkey commands.lint)
if [ -n "$LINTCMD" ]; then
    case "$LINTCMD" in
        *'{paths}'*) ;;
        *) fail "commands.lint" "must contain the {paths} token when present" ;;
    esac
fi

for k in commands.test commands.lint commands.typecheck; do
    v=$(getkey "$k"); [ -n "$v" ] || continue
    first=$(printf '%s\n' "$v" | cut -d' ' -f1)
    command -v "$first" >/dev/null 2>&1 || fail "$k" "executable not found on PATH: $first"
done

# --- schema policy is all-or-nothing ---------------------------------------
SG=$(getkey schema_policy.guide); SS=$(getkey schema_policy.stop_before)
if { [ -n "$SG" ] && [ -z "$SS" ]; } || { [ -z "$SG" ] && [ -n "$SS" ]; }; then
    fail "schema_policy" "set both .guide and .stop_before, or neither (neither = no schema changes allowed)"
fi

if [ "$rc" -eq 0 ]; then
    echo "OK: $(getkey name) — source=$SRC target=$TGT staff_dir=$STAFF (root $ROOT)"
fi
exit "$rc"
