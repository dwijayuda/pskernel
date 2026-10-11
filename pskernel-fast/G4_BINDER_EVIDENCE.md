# G4.3 continuation — certified scope, lifting, and substitution

**Status:** independently inspected cloud-green, **structural-only**. Not a type
checker, definitional equality procedure, proof checker, or declaration admission API.

- **Validated exact source:** [`1a86eb4eefe24e37b0747ae0881e66467f39f0ec`](https://github.com/dwijayuda/pskernel/commit/1a86eb4eefe24e37b0747ae0881e66467f39f0ec).
- **Validated run:** [GitHub Actions 38115032789](https://github.com/dwijayuda/pskernel/actions/runs/38115032789), job `114398149274`, **completed success**.
- **Toolchain:** Lean 4.35.0-rc4, pinned source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Executed evidence:** 47 Lake build jobs successful; no-legacy-import/syntactic-placeholder audit reported 19 V3 Lean files; all prior G1–G4.3 smokes and new strict binder tests ran successfully. The audit is **not a complete logical assumption audit**.

## New implementation-specific proof contracts

1. `KExpr.liftBVars_structurallyValid`: the actual capture-avoiding lift preserves structural scope when `cutoff ≤ depth`, including lambda, Pi, let, metadata and projection nesting.
2. `ScopedFrame.rawDomainAt_scoped`: a stored domain read at de Bruijn index `i` was structurally valid in the parent context at depth `currentDepth - (i + 1)`; successful lookup entails `i < currentDepth`.
3. `ScopedFrame.scopedDomainAt` and `AnyScopedFrame.scopedDomainAt`: a successful lookup returns the **exact raw domain lifted by `i+1`** together with a dependent proof of current-context **structural** scope. This does not prove the domain is a type or an inferred type.
4. `KExpr.instantiateBVar_structurallyValid` and `KExpr.instantiateBVar_top_scoped`: the actual structural substitution routine, including index decrement and capture avoidance under binders, preserves scope under its stated premises.
5. `KExpr.instantiateTopScoped`: the actual **executable** boundary first validates both body and replacement using G3 `validAt`; its `Except` outcomes distinguish a malformed body and malformed replacement. Success returns a dependent structural proof for the exact resulting term. It is **not a logical theorem-acceptance API**.

The proofs concern structural well-formedness only; no type preservation, equality
reflection, environment extension, model soundness, or proof irrelevance is derived.
The G4.1 candidate catalog remains **untrusted**, and G4.2 supports only its
previously qualified two-rule Sort/Pi formation fragment.

## Executed negative/positive tests

- Nested binder lifting across lambda/Pi/let, local-vs-outer variable identity, and out-of-range lookups.
- Original-context raw domain versus lifted current-context domain at multiple binder depths.
- Substitution under lambda/Pi/let, through metadata/projections, with correct free-variable decrement.
- Certified-substitution boundary success and fail-closed malformed body, malformed replacement, and undeclared universe parameter.
- G1–G4.2 smoke and the earlier comparative beta-only benchmark were also run by the workflow. That benchmark is **not** a real kernel throughput result.

## Earlier source failures, retained as history

- `c22863ba` and `9ddd8ed1` failed proof elaboration from reversed generalized induction-argument order; `6943309` resolved argument order but exposed natural-number parenthesization, fixed in green `29207f7` ([run 38114530408](https://github.com/dwijayuda/pskernel/actions/runs/38114530408)).
- `d719e1e` initially failed in the `Sort`/`Const` substitution proof cases, whose structural judgments are depth-independent. The proof script was corrected without changing the executable substitution algorithm; `58b8fa4` passed ([run 38114942215](https://github.com/dwijayuda/pskernel/actions/runs/38114942215)).
- `17b5b48`'s intermediate push was superseded before completed qualification. The extended certified lookup and smoke passed at `2648b99` ([run 38114692336](https://github.com/dwijayuda/pskernel/actions/runs/38114692336)).
- Latest green `1a86eb4` adds explicit fail-closed runtime preflight and tests.

## Mandatory next boundary

Build a **distinct fully checked dependent context and kernel judgment**, with
actual well-typed binder domains, validated universe-parameter regime, protected
checked constant environment identity, and independently specified
`Γ ⊢ e : A` rules. Do not cast `scopedDomainAt` into a checked inference
witness. Sound typed conversion/WHNF, proof irrelevance and official-Lean
positive/negative differential tests are separate requirements. **No
declaration/theorem acceptance** until complete qualifying admission gates.
