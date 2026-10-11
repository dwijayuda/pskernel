# PSKernel-Fast P1 — Bounded Typed Substitution Evidence

**Qualification:** first typed-substitution/weakening results for the independent G4.3b six-rule calculus. **Not the general dependent substitution theorem and not set-model consistency or Lean 4.35 kernel soundness.**

- **Exact qualified source/assumption gate:** [`b08feccc8bb06d7f5823636ec6d9f1badbafd6fe`](https://github.com/dwijayuda/pskernel/commit/b08feccc8bb06d7f5823636ec6d9f1badbafd6fe)
- **Completed GitHub Actions:** [run 38120030487](https://github.com/dwijayuda/pskernel/actions/runs/38120030487), job `114412662054`, **SUCCESS**.
- **Toolchain:** pinned Lean 4.35.0-rc4, source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Executed gate:** all 62 Lake build jobs, 26 V3 independent Lean source files checked by the import/placeholder fence, the previous G1–G4.3b functional regressions, and strict assumption receipts for **15 exact P1 theorem names**. The gate's self-tests enforce fail-closed behavior on missing, unexpected and disallowed axiom receipts.

## Exact theorems compiled

Source: [`src/PSKernelFast/Proof/TypedSubstitution.lean`](src/PSKernelFast/Proof/TypedSubstitution.lean), which is a **proof-only** module. Production source `GeneralPiFormation.lean`, `Substitution.lean`, `ScopedContext.lean` and the G4.3b algorithm have not changed. Tests import the new proof module to ensure it is built and audited in CI.

1. `liftBVars_one_instantiate_cancel`: for arbitrary `KExpr`, binder cutoff and replacement, lift free indices by one then instantiate that binder in the actual implementation; the exact result is the original expression.
2. `liftBVars_zero`: shifting any expression by zero at any binder cutoff is the identity.
3. `liftBVars_add`: two successive shifts at the same cutoff compose by **adding** their amounts for all term constructors, including binders, let, metadata and projections.
4. `liftBVars_comm`: shifts at a fixed cutoff commute; this follows from the compositional equation and natural-number addition commutativity.
5. `bound_zero_substitution_preserves_type`: the newest bound variable's type after substituting a checked value is exactly the value's type, within the existing `GeneralPiRule` relation.
6. `dependent_identity_beta_preserves_type`: under a `GeneralPiContextWF`, a checked domain `A : Sort u`, and `v : A`, the actual G4.3b typing rule for `(fun (x : A) => x) v` assigns exactly `A`, and the beta-contracted term `v` also has type `A` (including when `A` depends on prior binders). Uses actual `KExpr.instantiateBVar` for the inferred application type.
7. `dependent_let_variable_zeta_preserves_type`: analogously, `let x : A := v; x` with the supported `nondep=false` flag has inferred type exactly `A`, and replacing `x` with `v` preserves `A`. The theorem uses the real `GeneralPiRule.letE` constructor and actual result-type instantiation.
8. `checked_bound_variable_weakens`: if an existing variable has a checked inferred type in a context, and an additional binder domain has actually been inferred as a Sort, insertion of the new binder yields a certified extended context and preserves typing of the old variable with exact index/type lifting.

These are not just structural-scope invariants. Items 5–8 conclude **typing judgments** in the limited fragment. In particular, items 6 and 7 are genuine subject-reduction cases, and item 8 is a genuine variable-weakening step. They are still not model-based proofs that `GeneralPiRule` itself interprets the same set-theoretic types as Lean.

## Proof provenance and reproducibility

- First `c1ffff2`/integrated `d35e2c2` proof attempt failed Lean elaboration: the implementation's `bvar 0` instantiation returns a zero-lifted value. Added `liftBVars_zero`. The next candidate `aebee55` failed two proof applications that had not yet used the new zero-lift identity. Corrected `3f965a0` passed [run 38119565565](https://github.com/dwijayuda/pskernel/actions/runs/38119565565), 62 jobs, with the dependent beta proof.
- `d1da465` passed [run 38119659587](https://github.com/dwijayuda/pskernel/actions/runs/38119659587) with the variable-body dependent let/zeta subject-reduction lemma, 62 jobs.
- `7b1c613` passed [run 38119759795](https://github.com/dwijayuda/pskernel/actions/runs/38119759795), introducing the first **12-theorem** explicit assumption gate.
- `2e8d9b8` and `355369c` introduced the compositional shift and typed variable weakening proofs. [Run 38119937449](https://github.com/dwijayuda/pskernel/actions/runs/38119937449) successfully compiled all 62 build jobs but correctly **FAILED** the proof-assumption gate because three newly printed theorem names had not yet been registered. The scanner's strictness is intentional. `b08fecc` added precisely those three reviewed names; [run 38120030487](https://github.com/dwijayuda/pskernel/actions/runs/38120030487) passed all 62 jobs and the **15-theorem gate**.
- The recorded assumption allowlist is `propext`, `Classical.choice`, `Quot.sound`; the new substitution/weakening lemmas reported only `propext` and `Quot.sound`. No new project-specific axiom or `sorryAx` is accepted. The audit remains scoped to its 15 named theorems; it is **not** a whole-kernel or binary TCB proof.

## What this does NOT establish

The crucial general substitution theorem
`Γ ⊢ v : A` and `Γ,x:A,Δ ⊢ e : T`
`=> Γ,Δ[x:=v] ⊢ e[x:=v] : T[x:=v]`
is **not proved**. The current proof handles one newest variable as a body, beta/let identity-type subject reduction and one-binder weakening **for variable lookups only**, not arbitrary nested lambda/Pi/application/let typing derivations.

Remaining proof dependencies include generic weakening, context-substitution invariants under arbitrary intervening binders, typed substitution through Pi/lambda/app/let, exact conversion soundness and the set-theoretic denotation of the entire rule fragment. **Do not assume syntactic equality is a complete Lean DefEq decision.** The official Lean 4.35 positive/negative type-checking differential corpus and performance measurements for real checking remain unqualified.

## Recommended next mathematical decision

Before trying a costly global syntactic substitution theorem, evaluate whether a **con-leche-style direct semantic checker-to-denotation proof** bypasses the most expensive syntactic inversion/regularity properties. Both approaches must justify actual beta/let computation and preserve interpretation of checked binder domains. Use the new local theorems as proof ingredients; do not freeze V3's runtime design for their sake.

Retain the P0 [soundness contract](PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md), the [P1 context-scope evidence](P1_SOUNDNESS_EVIDENCE.md), and a separate obligation ledger. **No theorem-admission API** or claim of unconditional consistency is authorized by this checkpoint.
