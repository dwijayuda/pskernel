# PSC1 current work state — compiler census normalization

Updated 2026-10-21. Continuation branch: fix/psc1-census-normalization-20261021.
Parent is qualified draft [PR #169](https://github.com/dwijayuda/pskernel/pull/169),
exact head 6d2cc114f6534a8d56343cfe91a6c966368ccacf. Its qualified source and
all earlier branches/history remain intact. No main merge, release or publication.

## Current change and validation boundary

Replace the unsupported Ast binding-name append notation with a named structural
helper. Preserve left-to-right order, duplicate leaves and source spans. Construct
qualified names explicitly instead of using unsupported record-update syntax.
Normalize the erasure runtime-prelude closure recursive call to its three explicit
binders, binding the returned function before applying the selection. Fuel,
candidate order, metadata retention, dependency selection and fixed-point stopping
are unchanged.

Census diagnostics now retain the failing source declaration/index/span from the
actual elaboration attempt. The census requires Ast parse acceptance and
Erasure.Definition elaboration acceptance while still reporting every other
refusal and blocked import. Native behavioral regressions cover nested duplicate
binding names, qualification spans, direct/transitive runtime dependencies,
unused-definition pruning, metadata order, zero fuel and stabilization.

New source changes are pending Linux CI; do not transfer PR #169 qualification
to them. The focused workflow now builds/runs the behavioral regression and full
source inventory; the scoped workflow retains its existing qualification suite.
Repository development and execution use GitHub/Linux CI only.

## Preserved qualified foundation

PR #169 head 6d2cc114f6534a8d56343cfe91a6c966368ccacf passed
[scoped Linux 39496980943](https://github.com/dwijayuda/pskernel/actions/runs/39496980943)
(all 37 steps) and [focused native 39496981110](https://github.com/dwijayuda/pskernel/actions/runs/39496981110).
Its implementation 5496943a30423269654fffcd7579b3c5dd16b4f9 has its separate
[immutable receipt](docs/PSC1_ULTRA_FOUNDATION_QUALIFICATION_2026-10-21.json).

Previous census: semantic 67/40/35, JS 79/48/41, Rust 83/49/40
(modules/parse accepted/elaboration accepted). First refusals were Ast `++`
and Erasure.Definition `structuralRecursionArity`. New counts await CI.

## Architecture and next boundary

One shared AST/elaborator, canonical Core and checked expression IR remain.
Official Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
is the independent logical admission authority. Ordinary source/body pairing,
strict IR, target/ABI validation, unavailable-verified refusal and atomic publication
remain mandatory. Owned kernel testing is separate.

The census covers Lean parse/elaboration only. Whole-closure independent admission,
IR, generated compiler execution, self-compilation and fixed points remain not-run.
Generated JS/Rust checker transport is not compiler self-hosting. There is no
formal backend-preservation theorem. All fourteen full Practical Core families
remain incomplete; component ABI remains Bool-only.

Continue the [Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md):
finish source normalization with explicit refusal evidence, extend dual-grammar
coverage, then whole-closure admission/IR and actual generated JS/Rust generations.
Efficient optional indexing/finite loops, Rust aggregate callbacks and typed IO
remain open. Historical Lean4.34/PSC2 receipts do not qualify the 4.35 compiler.

Use expected-SHA non-forced updates. Preserve tests and budgets. Record exact
passed/failed/pending evidence here and in the execution status.
