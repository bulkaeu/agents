# Breaking changes research

Use this when `bumpType` is `major`. Read only for major bumps — do not load for patch/minor waves.

## Research order

1. **Official codemods** — see registry below; run before manual edits.
2. **GitHub release notes** — `https://github.com/<org>/<repo>/releases` for the target major.
3. **CHANGELOG** — `CHANGELOG.md` in the package repo; search for `BREAKING`, `Migration`, `Upgrade`.
4. **Package docs** — upgrade/migration guide linked from npm readme.
5. **Web search** — `"<package> v<major> migration guide"` or `"upgrade <package> <old> to <new>"`.

Record: breaking items that apply to this codebase, codemods used, files changed.

## Codemod registry

Invoke from project root. Prefer package-specific codemods over generic jscodeshift when listed.

| Ecosystem | Package / tool | Example invocation |
|-----------|----------------|-------------------|
| React | `react-codemod` | `npx react-codemod@latest <transform> src/` |
| Next.js | `@next/codemod` | `npx @next/codemod@latest <transform> .` |
| MUI | `@mui/codemod` | `npx @mui/codemod@latest <transform> src/` |
| Vue | `vue-codemod` | `npx vue-codemod <transform> src/` |
| Jest | `jest-codemods` | `npx jest-codemods <transform>` |
| TypeScript ESLint | `@typescript-eslint/eslint-plugin` docs | follow published migration scripts for major bumps |
| Generic | `jscodeshift` | `npx jscodeshift -t <transform.js> src/` |

Before running: check the package’s npm page or GitHub for the canonical codemod name and transform list for your version jump.

## Patterns to grep in the codebase

After reading release notes, search for affected symbols:

- Removed or renamed exports (`from 'pkg'`, `require('pkg')`)
- Renamed props, hooks, or config keys
- Default export → named export (or reverse)
- Peer dependency bumps (e.g. React 18→19, Node `engines`)
- Type-only breaking changes (`@types/*` or package-owned types)
- ESM-only: `import` vs `require`, `"type": "module"`, `exports` map
- Deprecated APIs still in use (warnings in release notes)
- Config file schema changes (`vite.config`, `eslint.config`, `tsconfig`)

```bash
# Examples — adapt terms from release notes
rg "from ['\"]package-name['\"]" --type ts --type tsx
rg "legacyApiName|OldComponent" src/
```

## Verification checklist (after each major)

- [ ] Imports resolve (no missing modules)
- [ ] Typecheck passes
- [ ] Lint passes
- [ ] Tests pass; review snapshot diffs intentionally
- [ ] Production build succeeds
- [ ] No new peer dependency warnings from install
- [ ] Spot-check critical UI/runtime paths if no tests cover them

If codemods + manual fixes cannot get checks green without weakening CI or unrelated hacks, stop and report — do not silently revert the bump.
