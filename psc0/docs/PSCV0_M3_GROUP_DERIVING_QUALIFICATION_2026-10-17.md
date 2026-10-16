# Direct group deriving and ordered recursive hypotheses — qualified

**Compiler/test:** `01d762eb02eab1d2f795e5338cb3586cd1d1ace0`. **Selected slices ACCEPTED; full M3+B OPEN.** 17 October 2026 (Jakarta reporting).

This exact compiler/test commit adds direct group deriving and constructor-order protection to the previously accepted group elimination, measured recursion and ordinary P0 baseline `e03a99d1f45f2127372ee556ffe866d304d103e3`. The earlier [group/recursion/P0 receipt](PSCV0_M3_GROUP_RECURSION_P0_QUALIFICATION_2026-10-17.md) retains that accumulated scope and its historical evidence.

## Five qualifications on the same commit

| Gate | Workflow | Exact result |
| --- | --- | --- |
| Full native Linux | [38967030820](https://github.com/dwijayuda/pskernel/actions/runs/38967030820) | SUCCESS; job `117196341777`, all 33 reported steps successful, none skipped |
| F1 canonical model | [38967031191](https://github.com/dwijayuda/pskernel/actions/runs/38967031191) | SUCCESS |
| F2 logical operations | [38967030836](https://github.com/dwijayuda/pskernel/actions/runs/38967030836) | SUCCESS |
| F3/F4/platform | [38967030843](https://github.com/dwijayuda/pskernel/actions/runs/38967030843) | SUCCESS |
| Focused source/kernel/native oracle and five targets | [38967030789](https://github.com/dwijayuda/pskernel/actions/runs/38967030789) | SUCCESS; job `117195929444`, all 15 reported steps successful, none skipped |

| Retained artifact | ID | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Native | [12076410509](https://github.com/dwijayuda/pskernel/actions/runs/38967030820/artifacts/12076410509) | 6,705,681 | `05bd0ef960a3a1f7ac8f906d24f9ab498df5fb7f42c4af514f7d5c0f179f8843` |
| Focused | [12075436187](https://github.com/dwijayuda/pskernel/actions/runs/38967030789/artifacts/12075436187) | 1,282,442 | `b6f326b65f9c931903e69cbea45657937d8dd28d5ee252e8fd6dd56a1560a981` |

Run metadata, completed job steps, full native/focused logs and artifact metadata were inspected. Every workflow record names the compiler/test SHA above.

## Accepted deriving construction

`Ps.Elab.DerivingContext` specializes the actual complete group recursor through the shared `Ps.Elab.GroupElimination` argument cursor. It constructs every family motive and constructor minor, retains each family's own indices and checks each recursive hypothesis against the actual child's closed motive and index arguments. No sibling instance is assumed while constructing a group.

Hashable and Repr support the selected direct indexed groups. BEq supports direct nonindexed groups using left induction and right case inspection; right-side cases do not invent a second recursive dictionary. The native group handler checks ordered source ownership and builds every instance as an ordinary definition against the original environment. Existing compiler preparation then constructs checked captured companion definitions, and runtime erasure validates their retained equations and identities.

The native fixture exercises dependent common `A/a` parameters and alpha-renamed corresponding parameters in the other family, two equal-typed recursive children in one constructor, indexed families with unequal index counts, generic hash equations, constructor equality equations, nonreflexive field dictionaries and exact native Repr text at width 40 with two root precedences. Ten derived instances require ten complete two-worker groups with the actual type/value/dictionary capture telescope.

Native Lean's `mixHash` is opaque for this purpose. Generic logical hash laws are checked by the fresh official kernel; numerical hashing behavior is compared with executed independent native oracles. No closed numerical `rfl` theorem is fabricated to bypass that distinction.

Six fixture exports cover group Hashable, Repr, BEq, a nonreflexive field comparison, and indexed Hashable/Repr. Direct JavaScript, strict compiled TypeScript, locked Rust, V8 GC core and Wasmtime components all match the independent native observations.

## Ordered recursive-field identity

`psConstructorRecursiveFieldsOrdered` in `Ps.Core.InductiveGroup` requires strictly increasing, bounded retained recursive-field positions. Elaboration, deriving, portable iota reduction, runtime recursor inspection and canonical admission encoding consume that one predicate.

Constructor order matters even when two child hypotheses have the same type. The canonical wire format retains constructor declarations, while the official kernel reconstructs recursive hypotheses from actual field order; an unordered retained list cannot be transported as though that association were unchanged. The fixture reverses the real two-child metadata and checks that reduction, recursor inspection and canonical encoding refuse it. Additional typed deriving checks reject a missing direct child, a mismatched group and incomplete source provenance.

These checks support the selected actual constructor/group metadata. They do not claim arbitrary forged environment metadata is independently certified by the ordering predicate alone.

## Repair and integration evidence

Production candidate `0d17a6ca9dc5ceb5ceed4c40ffcc3ffabfd1be19` compiled the changed production modules but the new fixture failed compilation. Repair `01d762eb02eab1d2f795e5338cb3586cd1d1ace0` adds the explicit `PsKernelLean.Admission` import, the mandatory source spans on six handler-name records, and the existing `PsReduceAppView`/explicit Core lambda pattern in the two-child probe. Assertions, source workloads, exports and expected observations are unchanged by that repair.

The same commit makes all five primary workflows watch M3 Lean fixtures and M3 runner scripts. Fixture-only repairs therefore receive complete qualification on one SHA. Job commands, pins, timeouts and workload/budget definitions are unchanged by the trigger repair.

Full native source/Standard qualification, modules, GC/components, JS/TS/Rust, repeated Wasmtime calls and the original M1 measurement step pass. The original runtime workload still records 1,069 shared observations. This is selected execution and integration evidence, with no new general backend-preservation or performance-parity claim.

## Remaining scope and engineering assessment

Nested specialization motives/traversal, deriving through those nested fields, dependent ordinary runtime deriving fields, indexed BEq/DecidableEq, broader total/WF recursion, complete compatible mutual strategy dispatch and local `where` capture closure remain work. Default source induction on mutual/nested types retains pinned Lean's refusal without an explicitly selected eliminator; no new `using` grammar is introduced. Source `mutual` remains def/function-only.

The accepted engineering estimate is approximately **60%**, with a broad **50–70% uncertainty interval**. It is a planning estimate, not a measured conformance percentage. The approximate weighted contribution is 58 points: data/elimination/deriving 17 of 30, source strategies 10 of 15, total recursion 10 of 20, P0 13 of 15, P1 1 of 10, integration 7 of 10. All six exits remain in the denominator; later unqualified recursion/nested implementations add no accepted points.

Pinned `Lean.Order.fix`, `CCPO.csup` and their equations require `Classical.choice`. Approved assumptions remain only `propext` and `Quot.sound`; P1 fails closed at that exact dependency and has no accepted construction.

## Fixed authority

Native portable `.lean`; official Lean **4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The only forward source specification is `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, blob `694115223777599ba28ee175e14bb642b7b6aa4b`.

The checked group construction follows the pinned [kernel inductive implementation](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/inductive.cpp) and [mutual inductive elaboration](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/MutualInductive.lean). Earlier receipts retain the independently inspected recursion and partial-construction references.

Original benchmarks, counts, checksums, budgets, dependency pins and historical receipts remain intact. No pskernel-core, replacement kernel, self-hosting, source migration, LLVM integration or later milestone promotion is included. PR #109 stays draft/open/unmerged on its original base.
