# Unit registry

Committed log of **units that finished a port**. Not the run plan. Not a catalog of what remains.

The orchestrator appends **one row after merge-back** (under `in-place`, after file-review and docs)
when that unit's map → tests → port → line-compare → file-review → docs path succeeded.
Subagents never write this file. Serialize appends — one writer at a time.

`ported` = green specs + line-compare + file-review + docs + callers listed + this row.
It does **not** mean clients cut over.

For method+path units, `id` and `notes` name the **handler**, not the whole leaf file.

| id | kind | source_surface | target_area | status | unit_doc | notes |
| --- | --- | --- | --- | --- | --- | --- |
