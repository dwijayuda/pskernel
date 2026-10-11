# G4.4b / P1k — Typed multistep joins and same-universe dependent graph spaces

**Qualified 11 October 2026.** These are bounded operational correctness and conditional model-construction results, not full Lean soundness or consistency.

## Exact qualification

Source `4e6a06e1180e504d359b9637d6273d4bb9f8a853`; [GitHub Actions 38140633920](https://github.com/dwijayuda/pskernel/actions/runs/38140633920), job `114473607797`, completed SUCCESS. Official pinned Lean4.35.0-rc4 at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` confirmed in the inspected job log.

Architecture audit: **55** independent Lean source files. Exact theorem-assumption audit: unchanged base **157**, disjoint extension **17** = **174** total (six operational and eleven new model theorems). Both strict audits reuse the reviewed allowlist and reject missing/extra/duplicate receipts and `sorryAx`. Caller-supplied `[SetTheoryBasis V]` remains a genuine mathematical premise even though quantified parameters do not appear as global `#print axioms` names.

The focused new dependency closure completed a 24-job Lake invocation; the existing full closure completed a 109-job invocation, reusing shared outputs. Counts are NOT additive. Existing regressions and the new native-kernel differential stage all passed. No model basis, G4.3b inference rule, legacy branch or admission API was changed.

## 1. Executable conversion is no longer restricted to one directional step

[TypedNormalization.lean](src/PSKernelFast/TypedNormalization.lean) defines independent `WeakHeadStep` beta/zeta/application-spine rules and exact-type `TypedSteps` chains. `stepWeakHead` constructs a reduct with a Prop-valued operational proof. The tail-recursive normalizer rechecks every intermediate term through actual `GeneralPiContext.infer`, declining whenever its type fails to be syntactically identical to the original type. Two normalizations yield equal only with paths to the same syntactic weak-head result.

The retained values are the current/final terms and counters; paths, bounds and final stability are in **Prop**, not Type-valued histories. This avoids designing a proof-trace allocation cost into the runtime. It is not a measured speedup claim, and repeated typechecking/substitution can still be expensive.

Proved results: both endpoints of a typed chain are typed; a supplied per-step semantic law composes over a chain; a positive execution has two bounded typed paths and a stable common result; zero fuel never accepts; total contractions are below twice the per-side fuel. The semantic-composition theorem is conditional on `stepSound` and does not supply the missing full source-model law.

Fuel counts head inspections per side, including final stability inspection: n contractions require at least n+1 units. This bounds reductions, NOT allocation, term size, spine depth, source inference, elapsed time or RSS. Different stable heads and unsupported rules are unresolved, not a negative DefEq judgment.

## 2. Independent native Lean kernel differential, not an agreement vote

[TypedNormalizationSmoke.lean](src/PSKernelFast/TypedNormalizationSmoke.lean) translates a deliberately small test syntax into native Lean expressions, imports Init, and invokes `Lean.Kernel.check`. It builds an application requiring an `Eq.refl` proof to have the type `Eq ty lhs rhs`; the official C++ kernel must validate that conversion. No oracle appears in the production reducer.

The checked log records:

- **15 supported positive equalities**: mixed beta/let chains and two-sided joins, beta application spines, let in function position.
- **2 rejection controls**: an ill-typed application and two unequal functions of the same type.
- **1 intended completeness gap**: reduction under a lambda, officially equal but locally unresolved.

Additional source-runtime tests verify exact step counts in both directions, fuel boundaries and malformed-before-fuel behavior, dependent-context capture avoidance and non-evaluation of a neutral head's argument. These finite fixtures do not prove general Lean compatibility or semantic soundness.

Pinned algorithm reference studied: [official type_checker.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp), notably `whnf_core` beta, function-head and let reduction. The source mapping and oracle remain test infrastructure, not part of proof admission.

## 3. The previous successor-universe limitation is actually removed

[UniverseImageClosure.lean](src/PSKernelFast/Spec/UniverseImageClosure.lean) proves:

1. Separation is constructed from image/union/singleton/empty, with exact membership.
2. A member A of U cannot surject onto U: the diagonal subset `{x in A | x notin g(x)}` is also a member of U and contradicts such a surjection.
3. The supplied Tarski size alternative applied to an image of A now forces that image to be a member of U, because the equinumerous alternative would give the forbidden surjection.
4. The actual Kuratowski function graph is therefore in **the SAME U**, not merely its successor.

[DependentGraphSpace.lean](src/PSKernelFast/Spec/DependentGraphSpace.lean) goes further. A hypothetical bijection from `union A` to U would image A's pieces into a family C in U. Covering C itself creates a two-cycle `C in D in C`, forbidden by regularity. Thus union closure is also derived. No extra closure field or global axiom is introduced.

The model-dependent sum is the set of pairs `(x,y)` with `x in A` and `y in B(x)`. The `modelGraphPi A B` carrier is a separating subset of its powerset, with an exact all-and-only membership characterization by graphs of fibre-respecting functions. **Both dependent-sum and function-space carriers are in U when A and every fibre B(x) are in U.**

This is not yet a complete Lean Type-Pi interpretation: graph application and functional uniqueness, beta/eta, the proof-point/Prop regime, source universes and source-denotation soundness still require proofs.

## 4. Efficient verification provenance

Three substantive source commits, each first-run green without weakening a statement:

| Commit | Exact run | Result |
|---|---|---|
| `fc90e0b365dff0cc6b6d610eb7d617a055582f78` | [38139817827](https://github.com/dwijayuda/pskernel/actions/runs/38139817827) | G4.4b runtime, six receipts, native differential |
| `719b62894761f196915caab3c0cc215870c87e76` | [38140320151](https://github.com/dwijayuda/pskernel/actions/runs/38140320151) | Five separation/image/graph receipts |
| `4e6a06e1180e504d359b9637d6273d4bb9f8a853` | [38140633920](https://github.com/dwijayuda/pskernel/actions/runs/38140633920) | Six union/dependent graph-space receipts |

CI builds the changed dependency closure first and reuses outputs for the existing suite; all earlier acceptance checks remain enabled. Existing warnings remain. The older G4.4a timing harness is unchanged and does not benchmark G4.4b; no new speed, allocation, peak-RSS or matched-official performance claim is made.

## Remaining critical bridge

Prove graph application/uniqueness and beta/eta, then connect the mathematical function carrier and tagged Prop interpretation to actual source typing/substitution. Only a genuine semantic one-step result may discharge the new chain theorem's `stepSound` premise. Full congruence, symbolic universe conversion, proof irrelevance, transparency, quotients/inductives/primitives, checked immutable declaration extension, conditional no-False and representative performance remain open. **Admitted declarations remain zero.**
