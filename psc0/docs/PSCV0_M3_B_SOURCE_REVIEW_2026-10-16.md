# M3+B and performance: implementation source review

16 October 2026. This review accompanies the first M3 runtime implementation, not a declaration that M3+B is complete. The accepted M2+A baseline remains `2a7072064974cb0d051a1773a26caf15fc59838b`.

## Decision

Continue M3+B, with measured runtime work alongside the data and recursion mechanisms it depends on. Do not replace the native `.lean` compiler with TypeScript, postpone every measured bottleneck to M5, or weaken the language semantics to improve a benchmark. Qualify each coherent change and compare original and candidate artifacts on the same runner.

## What was actually inspected

All PSC0 paths below were inspected at `133af061d6aaff0eb6ed990abd341ca2a44d15e9` or its source-identical parent for the relevant path. Upstream Lean sources were inspected at the project's exact `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` pin. This is an owner-oriented review; it is not a claim that every M3 source path has been exhaustively audited.

| Area | Inspected PSC0 owner | Finding and implementation consequence |
| --- | --- | --- |
| Data syntax | `Ps.Syntax.Pscv0.Data` | This reader produces one structure or inductive declaration. A mutual group needs coordinated ownership rather than sequentially pretending each family is already fully declared. |
| Data elaboration | `Ps.Elab.Data` | Existing single-family parameter/index telescopes and motive construction are real capabilities, not new work in this change. The inspected nested-recursion recognizer is restricted to selected List/Option/Array/Prod shapes. General nested/mutual support requires the shared group construction. |
| Core metadata | `Ps.Core.Declaration` | Recursor metadata already has `inductiveNames` and `numMotives`; a group's constructor and family records still need coherent preparation and checking. Do not replace this with unrelated per-handler recursion metadata. |
| Elimination universes | `Ps.Meta.Inductive` | Current singleton/empty-family checks distinguish proof fields from fields exposed as complete result arguments. Preserve these rules when adding groups; a field merely occurring inside an index is not automatically exposed data. |
| Recursion normalization | `Ps.Elab.Recursion` | Existing plans distinguish the structural major, generalized arguments and indices. Preserve local identity, lexical scope and captured-variable checks when extending recursion. |
| Runtime recursion | `Ps.Erasure.Recursion` | Reusing the current worker requires valid varying-local/capture and parameter-position evidence. It preserves current generic arguments and explicit index replacements. Unsupported plans remain refusals. |
| Runtime data layout | `Ps.Erasure.Inductive` | Type/proof fields have no storage; a runtime field depending on an erased existential type is explicitly refused. Full heterogeneous/dependent execution needs a justified representation, not `.unknown`, arbitrary casts or discarded witnesses. |
| Deriving | `Ps.Elab.DerivingContext`, `DerivingInhabited`, `DerivingBEq` | The common preparation rejects indexed deriving; shared field/eliminator builders reject recursive comparison families. Inhabited already searches constructors and handles checked defaults separately. Broader deriving must consume shared motive/recursive-hypothesis machinery rather than remove these refusals in isolation. |
| Runtime optimization | `Ps.BackendEcma.Lower`, `Runtime`, `Sync`; `Ps.BackendTs.Analysis` | The implemented slice removes conservative generic and suspension-related overhead while retaining dynamic/non-tail scheduler fallback. The environment and logical admission roster do not change. |

## What the pinned Lean implementation contributes

- [`Lean/Elab/MutualInductive.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/MutualInductive.lean): elaborate all headers, unify their parameter contexts, then elaborate constructors and finalize the group. Kernel checking precedes final attributes/deriving. This staged architecture is the model for PSC0's group owner, not a reason to import the whole Lean frontend.
- [`src/kernel/inductive.cpp`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/inductive.cpp), inspected constructor/positivity and recursor-universe sections: validate uniform parameter positions, constructor universes, strict positivity and result-family identity; construct coordinated motives for the group. Mutual inductive predicates have different elimination restrictions from a single empty/singleton predicate. The selected compiler must not use the kernel's unsafe bypass.
- [`Lean/Elab/Deriving/BEq.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Deriving/BEq.lean): distinguish proof and dependent fields, build auxiliary functions and compare constructors. Its alternative construction addresses quadratic generated code size. Some upstream contexts use a partial-definition fallback; that is not acceptable evidence of total verified execution under the selected PSC0 policy.
- [`Lean/Compiler/LCNF/ToLCNF.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Compiler/LCNF/ToLCNF.lean) and [`tests/elab/funind_unfolding.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/funind_unfolding.lean): scoped substitution, bound argument preservation, join points and structural/well-founded recursion examples informed the current runtime slice. No upstream test axiom or unchecked elaboration fallback is imported.

## TypeScript comparison: the relevant part is emitted code

The native workflow already qualifies emitted TypeScript with **TypeScript 7.0.2**. The corresponding repository tag resolved to **`1e4744d68260a7cb91b62b12edc3f6a2187faaf1`** when inspected.

In [`src/compiler/transformers/ts.ts`](https://github.com/microsoft/TypeScript/blob/1e4744d68260a7cb91b62b12edc3f6a2187faaf1/src/compiler/transformers/ts.ts), inspected function-declaration/expression/arrow visitors erase type parameters and return annotations but retain the original generator marker and visit the body. They do not turn an arbitrary generator scheduler into a direct call graph. Consequently, passing the current generated scheduler through `tsc` is not a fix for its architecture.

The official [TypeScript design goals](https://github.com/microsoft/TypeScript/wiki/TypeScript-Design-Goals) favor erasable types and recognizable JavaScript; aggressive runtime optimization is explicitly outside their goal. These are useful output-design principles, not a replacement for PSC0's checked erasure, exact arithmetic, persistence or total-recursion obligations. Compiler implementation language/compilation throughput and emitted-program runtime are separate measurements.

## Performance diagnosis and remaining costs

The original benchmark performs only 8–128 calls per runtime sample with one warmup. V8's [tiering architecture](https://v8.dev/blog/maglev) is a reason not to label such measurements steady-state results. The added study therefore uses longer checksummed batches, repeated warmup, absolute times and separate profiler samples. Its longer baseline still measures substantial cost, so insufficient warmup does not explain the warning away.

The actual emitted call chain includes dictionaries, curried applications, numeral evidence, generic Option handling and scheduler requests. The baseline's traversal profiles contain scheduler, closure and garbage-collection work. The first implementation addresses unnecessary generators and uniform generic tail recursion. It does not yet perform interprocedural dictionary specialization or eliminate every wrapper.

The current suspension analysis intentionally remains conservative around nested function bodies. Constructing a suspended closure and invoking it are different events; a later refinement can exploit that distinction while checking each lexical function boundary. This is a remaining optimization opportunity, not a reason to remove the dynamic-call fallback without evidence.

[Lean's runtime](https://lean-lang.org/doc/reference/latest/Run-Time-Code/) and [reference-counting design](https://lean-lang.org/doc/reference/latest/Run-Time-Code/Reference-Counting/) also explain relevant differences: specialized primitives and ownership-aware reuse can avoid work that a straightforward immutable JavaScript translation performs. These current reference pages provide background; implementation choices must still be checked against the project's pinned sources. Globally replacing arbitrary-precision Nat with Number or mutating a shared persistent array is not an acceptable performance fix.

## Next coherent implementation order

1. Qualify the current generic/suspension-aware runtime slice, including the checked generic recursion fixture and all existing backend gates. Obtain its native artifact and measure it against the accepted artifact on one runner. Keep every old benchmark result, including regressions.
2. Add the shared mutual-family/header/constructor and recursor-group path, including positivity/universe/refusal and generated-source ownership. Use this same mechanism for nested lifting; do not grow a collection of unrelated wrapper exceptions.
3. Extend motives, recursive pattern handling and total recursion through the shared group representation. Add explicit existential runtime representation only where the selected source semantics require it; preserve proof/type erasure and cross-target validation.
4. Extend deriving through the actual recursive-hypothesis telescope and checked dictionaries. Avoid an unproved partial fallback and avoid unnecessarily quadratic constructor-comparison code where a shared discriminator mechanism suffices.
5. Continue measured optimization: scope-aware dictionary/closure simplification, justified direct-call groups and runtime representation/ownership improvements. Revalidate transformed IR and preserve evaluation order, panic/failure behavior, capture scope, external boundaries and source provenance. Add representative M3 workloads before a production-performance claim.

This order is a researched execution plan. Only the runtime slice described in `PSCV0_M3_B_RUNTIME_SLICE_2026-10-16.md` has been implemented in this response so far. M3+B's broader data, recursion and deriving exits remain open.
