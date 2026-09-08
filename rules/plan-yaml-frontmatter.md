---
description: "After plan edits, YAML-parse frontmatter before claiming todos are healthy"
alwaysApply: true
---

# Plan YAML frontmatter — parse after every edit

Applies whenever creating or editing a plan that **starts with YAML frontmatter** — primarily
Cursor session plans (`~/.cursor/plans/*.plan.md`, `.cursor/plans/*.plan.md`). Skip when the file
has no frontmatter (typical Claude/Codex / Progress-only markdown).

## The failure mode

Cursor’s todo panel is driven by YAML frontmatter (`name`, `overview`, `todos`). An unquoted value
with an embedded `:` (e.g. `overview: … Next: …`) makes the frontmatter fail to parse; the UI then
shows a mangled todo list. Progress-table cosmetics and TodoWrite sync do **not** prove the panel
is healthy.

## The rule

- **After every create/edit** of a frontmatter-bearing plan, parse the frontmatter before claiming
  todos are fixed or “aligned.”
- Use `python3`. If `import yaml` fails, say so and do **not** claim the panel is healthy.
- `yaml.safe_load` the first `---` … `---` block. Fail the claim on parse errors, or if `todos` is
  present and not a list.
- Quote `overview` and any todo `content` that contains `:`, `#`, `{`, `[`, or leading special chars.

```bash
python3 -c "import yaml, pathlib, sys
p = pathlib.Path(sys.argv[1]); t = p.read_text()
assert t.startswith('---'), 'no frontmatter'
data = yaml.safe_load(t.split('---', 2)[1])
todos = data.get('todos')
assert todos is None or isinstance(todos, list), type(todos)
print('OK', len(todos or []), 'todos')" PLAN_PATH
```

## Ownership

This rule owns **parse-before-claim for Cursor plan frontmatter**. Siblings own the rest:

- `ui-rendered-files-use-write-tool.md` — which tool edits the plan.
- `plan-atomic-todos.md` — todo granularity.
- `plans-live-in-a-plans-repo.md` — durable copy (including rules/skills plans), not session-only.

<!-- Canonical copy: bulkaeu/agents → rules/plan-yaml-frontmatter.md. install.sh links it to
     ~/.claude/rules/plan-yaml-frontmatter.md and ~/.cursor/rules/plan-yaml-frontmatter.mdc. Edit the
     repo copy, never a symlink. Keep the frontmatter — it is what makes alwaysApply work in Cursor. -->
