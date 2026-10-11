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
