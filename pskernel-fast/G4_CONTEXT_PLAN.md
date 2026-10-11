# G4.3 planning gate — scoped contexts and real typed checking

**Status:** G4.3 structural scope + substitution, restricted Sort-only dependent Pi, and the new **G4.3b general-domain Pi/lambda/exact-app/restricted-let fragment** have source-matched green CI in their bounded scopes. Latest [G4.3b evidence](G4_GENERAL_PI_EVIDENCE.md): [run 38116916150](https://github.com/dwijayuda/pskernel/actions/runs/38116916150), 54 build jobs. This is NOT a production checked kernel or a proof of type-preserving substitution. Exact Lean 4.35.0-rc4 source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; old PSKernel proof/API preservation remains non-binding.

## Validated bounded precursor

The independent `ScopedFrame params depth` prototype passed [G4.3 scoped-frame evidence](G4_SCOPED_EVIDENCE.md). It validates the exact domain's *structural* scope when pushing a binder and proves top lookup/depth progression. A raw domain read back from its original insertion context is NOT an inferred type. The [new G4.3 binder evidence](G4_BINDER_EVIDENCE.md) now validates precise lifting and executable fail-closed scope-preserving substitution. Even a lifted, scope-certified domain is NOT guaranteed to be a type; only a future genuine typed-context checking relation can grant that authority.

## Required design

The G4.2 source can only infer types for syntactically Sort-shaped closed terms. It does not handle a genuinely dependent term, so future additions need:

- A **validated local context** with stable binder identities or correct de Bruijn lifting, inferred domain types, exact opening/closing and scope exit.
- A **separate fully checked result grade** carrying the term, checked inferred type, environment epoch, universe parameter assumptions, and actual binder-sort observations; `InferOnly` is never silently upgraded.
- A strict **immutable checked environment** independent of the *untrusted* `CandidateCatalog`, and correctly checked constant arities, safety, reducibility hints and primitive rules.
- A **WHNF/DefEq engine** whose positive equality answers are provably sound and compatible with Lean's order-sensitive rules, including proof irrelevance, eta, reduction and symbolic universe equivalence. The current G4.0 `unresolved` result is not inequality.
- Explicit resource/error categories and atomic declaration admission; no partial publications on failure.

## Vertical implementation order

1. **GREEN:** structural binder context, exact source-context lifting, certified scope and capture-avoiding substitution ([binder evidence](G4_BINDER_EVIDENCE.md)).
2. **GREEN in bounded research fragment:** Sort and dependent Pi over Sort-only contexts ([earlier evidence](G4_DEPENDENT_SORT_EVIDENCE.md)); G4.3b extends to well-formed general-domain Pi, lambda, application when arg type is **exactly** the Pi domain, and `nondep=false` let with exact declared-type agreement ([latest source/evidence](G4_GENERAL_PI_EVIDENCE.md)). The `GeneralPiContextWF` premise and `inferClosedGeneralPiCertified` output scope certificates cannot mint a production `FullyChecked` result or admit a theorem.
3. **NEXT G4.4:** architect and prove sound positive typed WHNF/DefEq, exact Lean symbolic universe equality/`isGEq`, proof irrelevance and eta. Keep `unresolved` distinct from negative equality. Prove source-aligned application/let **typing substitution** and integration with actual checked context/environment identity before promotion.
4. Build a protected immutable *checked* constant environment separate from the untrusted G4.1 catalog. Source-matched checked-vs-infer-only modes, opacity, axiom/model policy, recursive recursors/quotients and exact versioned primitive reductions precede any atomic declaration admission.
5. Run actual Lean 4.35 official-positive AND negative differential conformance at each new typed rule; resource-graded behavior, realistic kernel-only time/RSS/allocations and later broader Init/Std/Mathlib. Do not label G4.4 completed based on the current syntactic-conversion fragment.

Until these are met, the most advanced qualified executable success is the **restricted G4.3b general-domain Pi/lambda/exact-application/let fragment**, not a general-purpose Lean kernel.

## P0/P1 independent metatheory status — first checkpoint GREEN

[Soundness contract](PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md) and [exact P1 evidence](P1_SOUNDNESS_EVIDENCE.md) show that every G4.3b fragment-rule conclusion is **structurally well-scoped** when the binder context satisfies an *independently authored* `ContextScoped` predicate; runtime `GeneralPiContextWF` implies that predicate. Full source/result structural scope follows from the real `inferClosedGeneralPi` success, not its post hoc output check. A separately proved equivalence of `validAt` and declarative `StructurallyValid` yields `certified_ne_malformedResult` and `inferred_success_certifiable`. [Cloud run 38118786036](https://github.com/dwijayuda/pskernel/actions/runs/38118786036): **60 green build jobs, 25 files audited, 7 exact theorem-assumption receipts checked** (allowlisted `propext`, `Classical.choice`, `Quot.sound`; no `sorryAx`). Keep defensive output validation present.

These are not **type-preserving substitution**, actual denotational typing, relative consistency, G4.4 WHNF/DefEq, Lean compatibility or theorem admission. Next mathematically indispensable work is a **type-preservation theorem under substitution** for the actual rules, followed by a genuine *set-theoretic* interpretation of `Sort`, dependent `Pi`, proof irrelevance and later conversion/admission; each accepted rule must preserve the same model.

## P1 typed beta/let and variable weakening — bounded GREEN

[Actions #38120030487](https://github.com/dwijayuda/pskernel/actions/runs/38120030487) compiled actual implementation laws and proofs for dependent identity beta preservation, variable-body let/zeta type preservation, shift composition/commutation and one-binder checked variable weakening: **62 Lake jobs, 26 independent V3 Lean files, 15 exact assumption receipts**. See [P1 typed evidence](P1_TYPED_SUBSTITUTION_EVIDENCE.md). These are `GeneralPiRule` derivations, not an independent denotational set model; the generalized context-substitution theorem remains open.

Do not use these bounded results to claim `typedSubstitutionPreservationProved` for the entire kernel. The remaining critical work is arbitrary-body/context substitution OR con-leche-style direct semantic beta/let preservation, then typed positive-sound WHNF/DefEq, complete universe interpretation and model-preserving declaration admission. Keep proof-only modules out of the runtime semantic authority.

## P1c independent erased term semantics — translation GREEN, model OPEN

[Evidence](P1C_SEMANTIC_ERASURE_EVIDENCE.md) / [CI #38121976529](https://github.com/dwijayuda/pskernel/actions/runs/38121976529) proves checked older-variable beta and let/zeta typing preservation; independent ground-universe syntax and actual-to-erased lift/substitution commutation; beta/let erasure; and existence of erased source **and** inferred type after **any** successful G4.3b inference. All **68** Lake jobs, **29** Lean source audit, and **24** theorem assumption receipts are green. The checked inference implementation is unchanged; no internal cache or checker authority was added.

NEXT: design actual `SetTheory V`/dependent-function/proof-irrelevance interpretation over an annotated semantic term tier and validate `PropWhen`-equivalent binder regime information from the actual checking judgments. The current unannotated `ErasedExpr` alone is **insufficient** for Lean's set interpretation; neither `GeneralPiRule` semantic soundness nor full typed substitution or consistency was proved. Keep the immutable checked environment and exact G4.4 DefEq as later separate gates.

## P1d verified set-model basis and Pi Prop semantics — global soundness OPEN

[Source/CI evidence](P1D_SET_MODEL_EVIDENCE.md) [#38124170798](https://github.com/dwijayuda/pskernel/actions/runs/38124170798) validates 76 Lake build jobs and 48 theorem assumptions. The new **proof-only** `SetTheoryBasis V`, derived model universe/empty/powerset lemmas, precise two-valued candidate `Prop` carrier, conditional `Sort` semantic-membership theorem, and proposition-valued `propPi` set-level truth law are independent of the executing G4.3b checker. `PiModelRegime` separately connects actual recursive typing evidence to the correct Prop/Type codomain-regime classification under every universe valuation.

**Not qualified:** a full semantic `interp` that maps checked `ErasedExpr` to set values, certified body-dependent `WellDenoted`, disjoint proof-point/proof irrelevance, Type-valued product graphs, general typed WHNF/DefEq and theorem/model admission. The `Prop` carrier may need a redesign as those proofs reveal constraints; correctness and speed take priority over retaining its initial shape. No more than the conditional, partial model theorem interfaces may be advertised.

## P1e checked annotation and proof-point representation gate — Green, full model open

[Proof/source evidence](P1E_CHECKED_DENOTATION_EVIDENCE.md) ([CI #38126457033](https://github.com/dwijayuda/pskernel/actions/runs/38126457033): 86 jobs, 38 independent Lean sources, 84 exact theorem assumptions) now includes two **actual checked source-to-set-denotation cases**, a proof-only interpreter for explicit Prop-valued Pi, and `CheckedPropAnnotation` carrying genuine recursive checker typing premises and valuation-specific codomain Prop classification. Conditional `Pi` model membership still needs a separately proved `PropPiFibresValid` premise; only the two concrete example fibres are discharged.

**Important model bug found:** the prior P1d True carrier has a proved unavoidable point/truth-value collision. A V2 research carrier establishes point-in-True, point-not-in-Prop and exactly two truth values, but **has not proved independence from writable pair/quotient/graph encodings**. Do not promote either candidate as a complete proof-irrelevant Lean model. Next fix this mathematical representation first, then semantic body/fibre soundness and Type-valued Pi. Preserve current self-host/performance design flexibility and keep proof admission disabled.

## P1f tagged-point and proven pair-closure gate

[Verified P1f evidence](P1F_TAGGED_MODEL_EVIDENCE.md), [Actions #38129546961](https://github.com/dwijayuda/pskernel/actions/runs/38129546961) (94 builds, 42 audited Lean sources, 110 exact theorem receipts), proves a tagged proof point distinct from the model's Kuratowski pairs, graphs, finite numerals and Prop truth values. The tagged Prop universe belongs to Type1, and shifted successor-Sort membership holds at all valuations, **without assuming finite pair closure**: the latter is derived from the Tarski size alternative with a finite pigeonhole argument.

**Open:** a full quotient writable-type guard/semantics. Arbitrary quotient/image freshness is mathematically impossible, and P1f explicitly proves an image can equal the point. The tagged candidate remains independent of the old P1d/P1e source interpreter; it must be migrated and the source-interpretation theorems reproved before any semantic soundness promotion. No kernel checker functionality or performance baseline was changed.
