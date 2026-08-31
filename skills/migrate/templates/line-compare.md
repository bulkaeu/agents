# Line compare: `<id>`

Source of truth is the source files. Verdicts: `kept` / `relocated` / `framework` / `exception`;
`missing` and `silent-change` fail the stage.

Skipped by rule: blanks, comments, imports, route registration, ORM lifecycle boilerplate,
out-of-scope handlers in the same file.

| source file:line | behavior | verdict | target symbol / note |
| --- | --- | --- | --- |

## Result

- `missing`: 0
- `silent-change`: 0
- **verdict:** pass | FAIL → return to `port`
