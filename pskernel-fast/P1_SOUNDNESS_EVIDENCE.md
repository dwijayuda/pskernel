# PSKernel-Fast P0/P1 — independent scope model and executing checker proof

**Status:** P0 contract committed and the *first bounded P1 metatheory* is **green**. **This is NOT the mathematical typing, set-model soundness, relative consistency or kernel-admission theorem.** Verified assumptions explicitly include Lean's `propext`, `Classical.choice`, `Quot.sound` as reported by `#print axioms` (individual theorems may use fewer). No new project's `axiom`, `sorryAx` or `native_decide` in these seven audited theorem receipts.

**Source/qualification:** independent G4.3b source remains at `253afb42b477aacab22def288a2dd42d7ca9633b`; new P1 proof and reflection source last changed at [`6611504268816d87c2ac5546ef0c52a73247002b`](https://github.com/dwijayuda/pskernel/commit/6611504268816d87c2ac5546ef0c52a73247002b). A separate exact theorem-assumption gate was added by [`b0a1c6503f12d1dbd5a8c6905be193d91f20f6d6`](https://github.com/dwijayuda/pskernel/commit/b0a1c6503f12d1dbd5a8c6905be193d91f20f6d6). [**Actions run 38118786036**](https://github.com/dwijayuda/pskernel/actions/runs/38118786036), job `114409045221`, completed **success** under pinned Lean 4.35.0-rc4 `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. **60 Lake jobs**, architecture fence on **25** independent Lean files, prior G1–G4.3b regression suite and dedicated full theorem-assumption scanner **PASSED**.

## P0 proof structure (NOT the set model)

- [`PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md`](PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md) freezes the relative-consistency, checked admission, axiom-mode and representation-refinement targets, comparing con-leche and con-ron. This is a **design contract**, not a proved acceptance/model statement.
- [`Spec/ContextScope.lean`](src/PSKernelFast/Spec/ContextScope.lean) imports the G3 structural specification but **not** the G4.3b checker. It independently specifies newest-first `ContextScoped` as a recursively inserted context whose each stored domain satisfies the scope predicate at its *introduction depth*. `ContextScoped.lookup_scoped` proves a raw lookup retrieves the correct insertion-depth scoping premise and a strict in-range index.
- [`Spec/ScopeReflection.lean`](src/PSKernelFast/Spec/ScopeReflection.lean) proves the reverse direction of G3 structural preflight: every independently `StructurallyValid` expression passes the *actual executable* `validAt`/closed-input check, across all expression/universe constructors. `closedInput_iff` establishes exact correspondence. This is not type checking.
- [`Proof/GeneralPiScope.lean`](src/PSKernelFast/Proof/GeneralPiScope.lean) imports the independent spec and actual G4.3b implementation. **Runtime checker modules do not import this proof layer**; only the focused smoke suite does.

## P1 machine-checked implementation consequences

1. `generalPiRule_scope`: each of the **six actual G4.3b formation/typing rules**, assuming only the independently scoped context, yields structurally well-scoped **input expression and inferred type**. The application and let cases use the pre-existing **actual implementation** `KExpr.instantiateBVar_top_scoped`, rather than inventing a second substitution. Lambda, Pi, exact-application and let contexts are extended under proved introduction-depth invariants.
2. `generalPiContextWF_scoped`: the **actual** recursively constructed `GeneralPiContextWF` certificate implies the independent `ContextScoped` model.
3. `inferClosedGeneralPi_source_and_result_scoped`: actual closed value-only inference success proves both original input and returned type satisfy structural validity; it no longer relies on post hoc output validation to establish that theorem.
4. `closedInput_iff`: G3 input preflight matches its declarative structural predicate in **both** directions (the former proof existed; P1 adds completeness).
5. `certified_ne_malformedResult`: with these model/rule invariants, `inferClosedGeneralPiCertified` cannot reach the `malformedResult` branch on any source input, though malformed **input** or unsupported terms can still fail. The output check remains **present** in runtime for defense in depth.
6. `inferred_success_certifiable`: if value-only `inferClosedGeneralPi` succeeds, the scope-certified entry also succeeds with the **same exact inferred type**, not merely a convertible guessed result.

These properties are **beyond** `accept ⇒ GeneralPiRule`; they independently constrain lookup validity, every inferred result's scope and a real runtime error branch. They do not show that `GeneralPiRule` itself is sound in a denotational set model or that type substitution preserves general typing. **No theorem is allowed to be marketed as full Lean consistency.**

## Proof-assumption gate

GitHub CI runs `lake env lean` on the independent spec, reflection and cross-layer proof modules and `scripts/audit_axioms.py` checks **seven exact theorem names** against an explicit, narrow allowlist (`propext`, `Classical.choice`, `Quot.sound`). The script fails on omitted/unexpected theorem receipts, `sorryAx`, `native_decide`, any unreviewed axiom, or a modified output line that hides a receipt; synthetic negative examples self-test the gate on every CI run. This is a **bounded theorem assumption audit**, not a whole-project trust audit, compiler correctness or native runtime correctness proof. The previous source regex/import fence also runs.

## Compatibility, model and performance debt

**Still entirely open**: an actual `SetTheory` model/term `Denotes` interpretation for this checker; semantic correctness of typing, reduction, proof irrelevance and dependent substitution; typed WHNF/DefEq and complete symbolic `isEquiv/isGEq`; kernel cache/environment invariants and arbitrary constants; positivity/inductives/quotients/literals; checked declaration admission and model-preserving environment extension; relative consistency `model_exists` and `no_derived_False`; official Lean 4.35 typed positive/negative export replay; kernel-only speed/RSS/allocations; runtime/backend/decoder trust.

Existing G4.3b tests remain experimental and incomplete. **Do not remove the defensive result-scope validation yet** or promote any candidate type into a full `FullyChecked` proof-result constructor. The next true mathematical theorem should be **type-preserving substitution for the supported calculus**, followed by an independent, genuinely denotational (set-theoretic) model and the soundness of positive conversion/fully checked inference against it. Follow the P0 contract for each new accepting rule; keep old proof branches unmodified.
