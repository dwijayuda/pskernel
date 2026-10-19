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

**Lean 4.35 migration qualified separately** at
`1bd0854f735cf8d0c8f3d07f705195c131acbd61`, Linux run
[39344155280](https://github.com/dwijayuda/pskernel/actions/runs/39344155280).
Actual compiler/provider commit is `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Native identity and bundle provenance verify that commit. Historical 4.34 assets
retain their original pins. The preserved focused suite passed (14 host tests,
IR/map/provider/host-boundary tests, native owned-kernel regressions, 24 backend
groups, four source-edge groups). Earlier migration attempts found and fixed the
removed String.dropRight API and CLI layout; their failed runs are retained.

**Slice 1 implementation is now a candidate, with qualification pending.**
See `docs/PSC1_PRACTICAL_CORE_SLICE_1.md`. It adds transactional contextual call
inference; selected operator precedence/lowering; typed Type0 Id/Except/checked
CompilerM sequencing; and explicit ordinary partial execution with opaque
constructive witnesses and independently checked exact body declarations.
The new test executables and actual JS/TS/Rust/core/component runtime suites
must pass at the implementation commit before any feature is marked qualified.

The ordinary witness constructor has a shared total attempt budget across
product children and failed Except alternatives. This limits compilation work;
it does not impose runtime fuel or alter divergence behavior. The divergence
test uses an external child-process timeout.

The governing v7.2 reference blob remains
`694115223777599ba28ee175e14bb642b7b6aa4b`, PSC0 commit
`33676076bcda7b0de5ec1f9803f49b8b1d28a058`. PSC0 remains read-only.
Every approved family remains explicitly incomplete. In particular ordering
`a < b`, early branch returns, mutation, for/while, collection/pattern syntax,
typed error syntax, namespace declarations and source IO remain later work.

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
