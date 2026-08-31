---
name: update-js-libs
description: >-
  Update specified npm/yarn/pnpm libraries (or all) in a JS/TS project safely.
  Detect available updates, classify semver bumps, apply codemods or research
  breaking changes for majors, then run the project's lint/type/test/build
  checks and fix issues. Use when the user asks to update, upgrade, or bump
  npm packages, yarn dependencies, or "all libraries".
---

# Update JS libraries

Safe dependency updates for JavaScript/TypeScript projects (npm, yarn, pnpm, bun).

**Locations:** project `.claude/skills/update-js-libs/` (bundled with repo) or personal `~/.claude/skills/update-js-libs/`. Works in Claude Code and Cursor (Cursor loads `.claude/skills/` via compatibility).

## Hard rules

- **Never run git commands** (no commit, branch, stash, push, revert via git).
- **Never modify** `.github/workflows/**` or other CI config to make checks pass.
- **Never downgrade** or pin below the agreed target without explicit user approval.
- If a major bump cannot pass checks after reasonable effort, **stop and report** — do not silently revert `package.json` or lockfile.

## Preconditions

If the working tree has uncommitted changes, warn the user they should be able to revert manually (you will not use git). Proceed when they want to continue.

## Inputs

- **Explicit list:** package names (e.g. `axios`, `@types/node`).
- **`all`:** every key in `dependencies` and `devDependencies` from project `package.json`.

Normalize scoped names (`@scope/pkg`). Ignore packages not listed in `package.json`.

## Detect package manager

From project root, by lockfile (first match wins):

| Lockfile | PM | Install | Run script |
|----------|-----|---------|------------|
| `yarn.lock` | yarn | `yarn install` | `yarn run <script>` |
| `pnpm-lock.yaml` | pnpm | `pnpm install` | `pnpm run <script>` |
| `package-lock.json` | npm | `npm install` | `npm run <script>` |
| `bun.lockb` | bun | `bun install` | `bun run <script>` |

Respect `packageManager` in `package.json` when present. Use immutable install flags if the repo documents them (e.g. `yarn install --immutable`).

## Discover updates

Resolve the check script from **project root**:

1. `.claude/skills/update-js-libs/scripts/check-updates.mjs` if it exists
2. Else `~/.claude/skills/update-js-libs/scripts/check-updates.mjs`

Run:

```bash
node <resolved-path>/check-updates.mjs <pkg>...
node <resolved-path>/check-updates.mjs --all
```

Output: JSON array of `{ name, currentSpec, installed, latest, latestMinor, bumpType }` where `bumpType` is `patch` | `minor` | `major` | `none` | `not-found` | `error`.

Present a short summary table. **Ask for approval** before editing files.

## Plan waves

Split packages by `bumpType` (relative to **installed** version when available, else parsed spec):

- **Wave A:** `patch` and `minor` — may be applied together in one `package.json` edit.
- **Wave B:** `major` — **one package at a time** (expand grouped packages — see below — as one unit per wave).

Skip `none`. Report `error` / `not-found` without blocking other packages unless the user cares.

User may defer a major and use `latestMinor` from the script to stay on current major line.

## Grouped packages

When updating one member, bump **all siblings in the same group** to compatible versions:

| Group | Packages |
|-------|----------|
| React | `react`, `react-dom`, `react-is`, `@types/react`, `@types/react-dom` |
| TypeScript ESLint | `@typescript-eslint/eslint-plugin`, `@typescript-eslint/parser` |
| Vite | `vite`, `@vitejs/plugin-react`, other `@vitejs/*` in the project |
| Vitest | `vitest`, `@vitest/coverage-v8`, `@vitest/ui`, other `@vitest/*` |
| ESLint stack | `eslint`, `@eslint/js`, plugins/configs that declare `eslint` peer |

Check each package’s peerDependencies on npm when unsure.

## Wave A — patch and minor

1. Update version ranges in `package.json` (preserve range style: `^`, `~`, or exact as appropriate).
2. Run **install**, then **full check suite** (below).
3. Fix failures in application/source code and config the project owns — not CI workflows.
4. Re-run checks until green or blocked.

## Wave B — major (per package or group)

1. Read [BREAKING-CHANGES.md](BREAKING-CHANGES.md).
2. Research breaking changes (codemods first, then release notes / changelog / web).
3. Grep the codebase for affected APIs; list files likely to change.
4. Bump version(s) in `package.json` → install.
5. Run official codemods when available; then manual fixes.
6. Run **full check suite**; fix until green or report blocked.

## Full check suite

Discover scripts from `package.json` → `scripts`. Prefer project scripts; fall back only if missing.

**Order** (fix after each step before continuing):

1. **Install** — `<pm> install` (with repo’s flags if any)
2. **Typecheck** — script named `type`, `typecheck`, or `tsc`; else `npx tsc --noEmit` if TypeScript project
3. **Lint** — script named `lint`; else `npx eslint .` if eslint config exists
4. **Test** — script named `test` (not `test:watch` unless user asks)
5. **Build** — script named `build` if present

Also run when present and relevant: `format:check`, `coverage` — only if the user or repo treats them as required (e.g. CI runs them).

**Never** disable rules, skip tests, or delete assertions to pass. Fix code or legitimate config in the repo.

## Version range guidance

- Prefer matching existing range style in `package.json`.
- For minors/patches within same major: `^` on latest compatible is typical.
- For majors: set range to the target major the user approved (often `^<new-major>.0.0` or exact pin if the repo pins).

Update the lockfile via the package manager install — do not hand-edit lockfiles unless the project convention requires it and install fails.

## Reporting template

End with:

```markdown
## Dependency update report

### Updated
| Package | From | To | Bump |
|---------|------|-----|------|
| ... | ... | ... | patch/minor/major |

### Skipped (already latest)
- ...

### Blocked / deferred
- ... (reason)

### Codemods
- ...

### Checks
| Step | Result |
|------|--------|
| install | pass/fail |
| type | pass/fail/skip |
| lint | pass/fail/skip |
| test | pass/fail/skip |
| build | pass/fail/skip |

### Files touched (high level)
- ...
```

## Examples

**User:** "update axios and recharts"

→ Run check script for both → propose Wave A/B → on approval, edit `package.json`, install, run checks, fix, report.

**User:** "update all"

→ `check-updates.mjs --all` → group by bump type → confirm waves → execute Wave A then Wave B majors one by one.

## Additional resources

- Major bumps: [BREAKING-CHANGES.md](BREAKING-CHANGES.md)
