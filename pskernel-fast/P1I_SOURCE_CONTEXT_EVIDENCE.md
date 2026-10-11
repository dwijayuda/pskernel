# PSKernel-Fast P1i — Source-context validation and exact inferred tagged-model ranks

**Status: GREEN, bounded proof-only accepting-direction semantic refinement.**
**Never read this as full Lean proof checking, arbitrary source soundness, unconditional consistency, real kernel speed or theorem-admission evidence.**

## Exact GitHub/cloud qualification

- Repository `dwijayuda/pskernel`, branch `research/pskernel-fast-clean-v3-20261011`.
- **Qualified source/proof commit:** [`57e15477f82317d29431722aca0ca6130ae29e52`](https://github.com/dwijayuda/pskernel/commit/57e15477f82317d29431722aca0ca6130ae29e52).
- [Actions **38135777941**](https://github.com/dwijayuda/pskernel/actions/runs/38135777941), job **`114459225119`**, completed **SUCCESS**, official pinned **Lean 4.35.0-rc4** source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **98 Lake build jobs**, **46 independent Lean source modules** audited, **152 exactly enumerated theorem-assumption receipts**; fail-closed allowed `propext`, `Classical.choice`, `Quot.sound`, NO `sorryAx`. Previous G1–G4.3b focused source/representation checks and experimental beta benchmark passed.
- First P1i checkpoint [`e955e46cf2721836784beff57c073c9a4b15cca0`](https://github.com/dwijayuda/pskernel/commit/e955e46cf2721836784beff57c073c9a4b15cca0) [CI 38135461558](https://github.com/dwijayuda/pskernel/actions/runs/38135461558) GREEN at **98 builds/46 files/150 receipts**. New type-rank refinement at [`5214bcf`](https://github.com/dwijayuda/pskernel/commit/5214bcf551f76f2044fe461783f18c8538c68db3) initially failed [CI 38135685570](https://github.com/dwijayuda/pskernel/actions/runs/38135685570) because a redundant tactic followed a constructor injection that had ALREADY closed the equality goal; final [`57e1547`](https://github.com/dwijayuda/pskernel/commit/57e15477f82317d29431722aca0ca6130ae29e52) removes only that redundant tactic, same theorem/model, final GREEN at **152** receipts.

## New actual source-to-model contract

[`Proof/SourceTaggedContextBridge.lean`](src/PSKernelFast/Proof/SourceTaggedContextBridge.lean) defines:

1. `TaggedSortContextValid`: a model environment respects *actual source* context entries declared syntactically `Sort u`. A bound value must be in `taggedSortSet V (u.denote ρ)`; source proof-valued binders do not get bogus proposition rankings.
2. `taggedSortContextValid_extend`: for any **checked** annotated binder domain, if a model value is proven in its interpreted semantic domain, extending source and model contexts preserves validity. Its sort annotation is obtained from `CheckedPropAnnotation`, not untrusted frontend metadata.
3. `SourceRankedTagged`: a deliberately small inductive sublanguage of Sort terms, **bound variables whose source domain is genuinely a Sort**, and proposition-valued Pi with the exact G4.3b `GeneralPiRule` for its domain/body and an actual `bodySort.denote ρ = 0`. It does NOT include source bound proof terms x:P, arbitrary Type-valued Pi, app/lam/let, constants or quotients.
4. `sourceRankedTagged_checked` reconstructs the independent certified source annotation; `sourceRankedTagged_wellDenoted` derives a **hereditary** P1h semantic judgment by induction on source-supported syntax and genuine context extension, including **all** semantic Pi fibres; `sourceRankedTagged_model_member` proves membership in the true tagged carrier.
5. `sourceRankedTagged_executed_closed` connects ANY actual successful `inferClosedGeneralPi` run within this sublanguage to its real rule certificate, exact erasure, checked annotation, and tagged semantic membership. This is no longer only two unrelated worked examples: it is an induction for the whole guarded syntax.
6. `sourceRankedTagged_rule_sort_rank` additionally proves **every** `GeneralPiRule` result of a supported source term has an actual `Sort level` whose numeric valuation equals its semantic `rank`. This avoids trusting an annotated rank as though it were an inferred result; even with different symbolic `imax` witnesses, the actual Prop codomain implies the same numerical model rank.
7. `sourceRankedTagged_executed_exact_inferred_model` combines executable success, actual inferred `Sort` shape, level valuation, actual output erasure and semantic model membership of the **actual inferred type** at that valuation.
8. Two independently proved `SourceRankedTagged` witnesses for the REAL executing source expressions `∀(P:Prop),P` (false) and `∀(P:Prop),P→P` (true), followed by reuse of the generic executing-source theorem.

These claims remain `[SetTheoryBasis V]`-**CONDITIONAL**. The fact that theorem assumption receipts omit a caller-supplied typeclass does not construct a set model. No global set-model existence/consistency is obtained by this local bridge, and the old P1d/P1e partial interpreter remains historical.

## Architectural strategy: fewest trusted moving parts, low proof/performance tax

- **One executable positive-acceptance authority.** Prove soundness of actual source-accepting branches and exact model interpretations; allow incomplete checking to DECLINE rather than inventing negative Lean DefEq. Avoid maintaining a second proof checker or duplicating an extensive syntactic metatheory when a direct model-based soundness induction is sufficient.
- **Pure specification + optimized runtime refinement.** Source `Spec/Proof` mathematical modules are separate from runtime `Core`; no runtime model computation, hidden set-theory assumptions, unchecked plugin proof facts, or proof-point collision assumptions. Con-leche's direct accepting-direction model proof is a STUDY BASELINE, not a PSKernel-Fast theorem; con-ron's verified twin/simulation and separately optimized storage is a possible LATER route, not a reason to lock this project's runtime data layout.
- **Performance evidence must be real.** G2 beta-only benchmark comparisons do NOT measure kernel inference/DefEq/Mathlib. Next design and implement a typed G4.4 positive-conversion boundary with explicit `equal | unresolved | malformed/resource` outcomes; integrate official Lean 4.35 differential fixtures and collect typed infer/WHNF/DefEq CPU, peak RSS and allocation baselines before choosing DAG/packed arrays/closures/C++/Rust.
- **Consistency capstone only after checked declarations.** Semantic Type-valued Pi/function graphs, proof-term application/lambda beta/eta, typed quotient writable-slot restrictions, all Lean primitive/inductive rules, model-preserving *immutable checked declaration* extension, model-existence hypothesis and an explicit verified axiom policy are prerequisites. In arbitrary-axiom Lean mode no unconditional consistency is possible.

## Outstanding next tasks (bounded)

1. **G4.4 typed conversion**: one canonical conservative positive-only equality/WHNF contract, actual source environment/typed context identity and resource behavior; prove successful results preserve semantic denotation, not merely scope.
2. **Source/model expansion**: Type-valued dependent function Pi graph membership/app/eta and proof-point-aware checked proof terms; then preserve model denotation across actually executing beta/let.
3. **Typed quotient boundary**: source-checked writable-value disjointness for the ACTUAL encoding only. P1f proves arbitrary images can equal the proof point, and con-leche proves unguarded quotient freshness fails. Never assert blanket `QuotFreshness`.
4. Fully checked immutable declarations/model fold, conditional `no_derived_False`, official Lean/Mathlib conformance, **kernel-only** performance comparisons and independent backend refinement.

**Nothing in this checkpoint edits the executing G4.3b checking algorithm or enables proof admission.** Admitted declarations remain **0**, global soundness and consistency proof flags remain false.
