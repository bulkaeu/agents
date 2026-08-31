# Report templates

Read only when emitting reports. Fill placeholders; no full diff dumps.

## Decision report

```markdown
# Decision: <short title>

**Repo:** <path>
**Files:** <paths>
**Finding:** <one line + severity>

## Why a decision is needed
<2–4 sentences>

## Option A — <name>
- Change: …
- Pros: …
- Cons / risk: …

## Option B — <name>
- Change: …
- Pros: …
- Cons / risk: …

## Option C — <name>   <!-- only if needed -->
- Change: …
- Pros: …
- Cons / risk: …

**Recommendation (optional):** …
**Pick A / B / C before I apply a fix.**
```

Cap ~1–2 short pages. Default to two options.

## Changes report (one per run)

```markdown
# Changes report

## Scope
- Repos: …
- Staged (skill candidates): …
- Excluded pre-staged (not reviewed): …  <!-- or "none" -->
- Secrets skipped / awaiting yes: …  <!-- or "none" -->

## Fixed
| Severity | Location | Fix |
|----------|----------|-----|
| … | `file:line` | one line |

## Open decisions
- …  <!-- or "none" -->

## Very Low / residual
- …  <!-- or "none" -->

## Notes
- Changes are **staged only — not committed**
- Staging permission from this skill run has **ended**
```
