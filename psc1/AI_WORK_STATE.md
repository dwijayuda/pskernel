# PSC1 current work state — Practical Core v7.2 continuation

Updated 2026-10-20. Branch: `feature/psc1-v7.2-practical-core-v1`.

## Authorized work and preserved lineage

Continue the repaired PSC1 implementation with **PSC1 Practical Core — v7.2 subset**:
retained supported functionality plus exactly fourteen approved feature families.
The selected reference is `PSC1_LANGUAGE_REFERENCE_v7.2.md`; the acceptance
matrix is `docs/PSC1_PRACTICAL_CORE_STATUS.json`.

PR #162 is still open at `a2778be648850a1f6a2381e28babcd4a6e783e31`, targeting
`psc1/direct-multibackend-v1`. Its scoped run 39333660822 is successful.
This continuation branches from that actual repaired head. Its parent implementation
`f933691a1d6fa578c59623636afbb02119909837` was qualified by run 39332460452.
Comparison confirms the following parent commit changed only three documentation
files. Historical repair documents/evidence remain unchanged; the prior work state
is preserved in `docs/history/AI_WORK_STATE_BEFORE_PRACTICAL_CORE_2026-10-20.md`.

## Current implementation/evidence boundary

Native source pin migration implemented; isolated Linux qualification is pending.
No new language implementation has been qualified.
The governing reference blob is `694115223777599ba28ee175e14bb642b7b6aa4b`
from PSC0 commit `33676076bcda7b0de5ec1f9803f49b8b1d28a058`; PSC0 is read-only
for this workstream.

Normative Lean target is stable 4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The active source now pins that exact compiler and provider commit, verifies both
native launcher identity and bundle provenance, and refuses the removed native
reduction capability. The separate migration run must qualify these changes before
language implementation is included. Historical 4.34 assets keep their original pins. Do not label this transitional state
completed v7.2 conformance.

Source audit found reusable inferred lets, implicit unification, products and typed
Array operations. It also found expected result constraints reach call arguments
too late; native do only expands to old CompilerM helpers while PS do rejects;
namespace scopes/literal collection syntax/control loops are absent; partial
declarations are rejected by canonical independent admission. Parsing partial
bodies is not useful ordinary checked execution.

## Next dependency-coherent slices

1. Separately migrate active pins to stable 4.35.0 and run the preserved focused
   compiler/provider/owned-kernel/backend suite.
2. Complete contextual call inference; qualify existing inferred locals; add
   bounded operators and product/collection syntax through existing checked paths.
3. Implement shared typed do/state/return control lowering; finite iteration and
   partial/while runtime paths only with sound logical/runtime assurance separation.
4. Finish admitted tuple/array/pattern/indexing, typed-error, namespace and bounded
   IO paths; qualify real target execution and negative interactions.

All fourteen families remain explicitly incomplete until specified, parsed,
elaborated, independently checked where applicable and executed on each claimed
target with fresh exact commit/run evidence. A green subset is not all-scope
completion. Full v7.2 and unrestricted .lean support are not claimed.

## Architecture invariants and execution rules

Preserve captured immutable source closure, exact admitted graph/runtime identity,
specialization rechecks, source ownership, collision-aware symbols, implementation/
.d.ts agreement, useful maps with unmapped generated regions, and transactional
target publication. Direct admission uses official Lean; the owned kernel remains
separately native-tested. Component public ABI remains Bool-only. No hidden TS
compiler in DirectJS or compiler logic in JS host helpers.

Use connected GitHub and focused Linux cloud CI only. No local checkout/build/test,
full self-host generation/census/fixed-point tests, package publication, releases,
merge into main, force updates, kernel fuel increases or new assumption allowlist.
Read actual HEAD before writes and use non-force expected-HEAD updates.
Keep the repair PR separate and open/update a continuation draft PR.
