# line-compare

    freedom: LOW — fixed verdict vocabulary
    reads:   {profile_path} · {staff_dir}/units/{unit_id}.md · {source_root}
    writes:  {staff_dir}/units/{unit_id}-line-compare.md

Source of truth is the **source files themselves**, never the port's comments or the mapping's prose.

## Walk

Every file in the mapping's source list — handler, service, validator, helper, plus model/trait methods
the in-scope handlers actually call.

Skip: blank lines, comments, imports, route registration, ORM lifecycle boilerplate, and **out-of-scope
handlers in the same file**.

## Ledger

One row per remaining line, verdict from this fixed set:

| Verdict | Meaning |
| --- | --- |
| `kept` | same condition / branch / side effect, in the named target symbol |
| `relocated` | moved to `file:symbol`, behavior equivalent |
| `framework` | framework glue, equivalent per the profile's `## Framework equivalences` |
| `exception` | listed in `{staff_dir}/EXCEPTIONS.md` and already approved |
| `missing` | **FAIL** — dropped branch or behavior |
| `silent-change` | **FAIL** — flipped condition, different query, lost queue/email/cache write |

Write the ledger to `{staff_dir}/units/{unit_id}-line-compare.md` using `templates/line-compare.md`.

## Done when

Zero `missing` and zero `silent-change`. If any remain, **stop and return fail** — the orchestrator
dispatches `port`, re-passes the green gate, and runs this stage again.
