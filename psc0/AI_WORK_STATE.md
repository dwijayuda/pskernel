# PSCV0 — recursive BEq candidate; M3+B continues

Updated 16 October 2026. **M3+B remains OPEN.** v7.2 alone is the forward `.ps` reference. Reapply the attached user prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before each coherent slice; inspect fresh HEAD/CI/both handoffs and matching pinned Lean source. No legacy mode or restrictions on host `.lean` syntax.

## Current candidate — not qualified yet

This child of ad47b42f112cf473e642181b525ca32059d4f0ba adds direct uniform nonindexed recursive BEq using the existing checked induction builder. Field plans distinguish erased proofs, independent dictionaries and actual recursive child hypotheses. Left induction produces child comparators family -> Bool; right constructor analysis ignores its own hypotheses. No assumed self dictionary, partial fallback, backend-specific equality or erasure change. Read docs/PSCV0_M3_RECURSIVE_BEQ_2026-10-16.md.

The existing recursive-tree fixture now independently derives BEq in native Lean and portable source. Nat/Bool comparison masks cover equal/deep-child/left-child/constructor differences; a deliberately non-reflexive field dictionary guards against assumed reflexivity/pointer equality. A source rfl theorem checks the recursive equation. Three intended-rule BEq refusals are appended. Existing Hashable/Repr exact outputs and six refusals remain. Only the VM driver's export roster changes; ABI/pins/assertions/budgets remain. Fetch this candidate's actual native/F1/F2/F3-F4/focused runs and inspect actual failures/results; no inherited qualification.

Pinned study: Lean4.35.0 eb6cafb Deriving/BEq.lean mkMatchOld/mkMatchNew and tests/elab/3740.lean; PSC0 DerivingContext/Hashable, Meta.Recursor, Erasure.Recursion and recursor/minor erasure. The broader dependent/nested behavior in upstream tests is not claimed here. Exact right-case lowering and no extra recursive traversal must follow actual Core/IR behavior, not a name heuristic.

## Last accepted compiler

Repr compiler/test4501164e5f1c32e00c81ae98d171e7bf201d1907, documentation acceptancead47b42f112cf473e642181b525ca32059d4f0ba. Same-commit native38898123679/job116963430156, F1 38898123552, F2 38898123501, F3/F4/platform38898123787 and focused38898124015/job116963431087 all passed. Native all33 reported steps, none skipped, completed2026-10-16T12:22:03Z. Exact artifacts/digests are in docs/PSCV0_M3_RECURSIVE_REPR_QUALIFICATION_2026-10-16.md: native12044554729, focused12045001218. Do not repeat that completed gate or attach its results to a new compiler.

Direct-recursive Hashable/Repr and parent58d439's capture-avoiding abstracted-motive application/minor checks remain. Repr uses actual child printers Nat -> Format; exact native text for Nat/Bool at root0/1024 and width40 passed all selected VMs. Recursive data stays internal to the unchanged scalar ABI. Historical failed fixtures/diagnostics remain in Git history, not current blockers.

## Remaining boundaries

Recursive DecidableEq, nested/indexed/mutual data/deriving, general elimination/pattern matrices, structural/well-founded total recursion, recursion-strategy ownership, P0 executable assurance and selected P1 fixedpoints remain open. Partial logical checking constructs an independent constructive inhabitant, public opaque self and private typed partial marker; every partial executable still fails shared admission across modules/targets. Never execute the witness, erase the marker, invent body equations/totality, introduce Classical/Nonempty fallback or downgrade a verified request.

v7.2 blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Adoption521a4a66 and whole-reference audit38840967041 are recorded. M2+A original profile73 remains accepted at2a707206/280e1e4e with its immutable receipts. Runtime133af061/paired38840337837/artifact12021226623 remain evidence for9.25–10.11xfromList, smaller head/array gains and unresolved deep-list/reversal. This slice claims no speedup or general preservation theorem.

## Working contract

GitHub connector/cloud Linux ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable `.lean`, official4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No sorry/unchecked admission/weaker tests/larger budgets/pskernel-core/self-hosting/compiler-source migration/immediate C5. GC internal, linear memory explicit ABI. Fresh expected-HEAD/non-force writes, preserve concurrent histories, update BOTH handoffs and exact receipts each slice. PR109 draft/open on psc0/pscv0-v7-m1-parser-ownership-v1; never merge. Continue M3+B -> M4+C/D -> M5+E without fabricated qualification or completion percentages.
