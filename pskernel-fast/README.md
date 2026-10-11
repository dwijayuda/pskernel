# PSKernel-Fast V3

A **new-generation** proof-kernel research program that prioritizes Lean 4.35 compatibility, sound positive results, high performance, small trusted computing base and explicit resources. **No obligation exists to preserve legacy PSKernel implementation or proof interfaces.**

- [Authoritative V3 architecture](PSKERNEL_FAST_ARCHITECTURE_V3.md)
- [MVP scope / correctness contract](MVP_SCOPE.md)
- [Live work state and evidence](AI_WORK_STATE.md)
- [Machine-readable no-legacy constraint and CI guard](ARCHITECTURE_POLICY.json)
- [G2 three-evaluator evidence and architecture decision](G2_EVALUATION_EVIDENCE.md)
- [G3 structural Lean syntax and proved preflight](G3_EVIDENCE.md)
- [G4 next checker implementation contract](G4_CHECKER_PLAN.md)
- [G4.0 sound symbolic universe evidence](G4_LEVEL_EVIDENCE.md)
- [G4.1 strict untrusted declaration catalog evidence](G4_CATALOG_EVIDENCE.md)
- [G4.2 certified formation evidence](G4_SORT_EVIDENCE.md)
- [Next G4.3 context/typed checker plan](G4_CONTEXT_PLAN.md)
- [G4.3 scoped-frame proof evidence](G4_SCOPED_EVIDENCE.md)
- [G4.3 scope-certified lifting and substitution evidence](G4_BINDER_EVIDENCE.md)
- [First dependent Sort/Pi formation fragment and CI](G4_DEPENDENT_SORT_EVIDENCE.md)
- [G4.3b general-domain Pi/lambda/application/restricted-let evidence](G4_GENERAL_PI_EVIDENCE.md)
- [P0 mathematical/model soundness contract](PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md)
- [P1 independently proved scope metatheory and axiom audit](P1_SOUNDNESS_EVIDENCE.md)
- [P1 bounded typed beta/let substitution and variable weakening evidence](P1_TYPED_SUBSTITUTION_EVIDENCE.md)

## Current executable state

The V3 research package has completed narrowly checked G1 scoped representation, G2 beta-only evaluator experiments, G3 structural preflight, G4.0 sound-but-incomplete symbolic level equality, G4.1 an UNTRUSTED candidate catalog, G4.2 Sort/Pi formation, and G4.3 structural binder/substitution proof work. **G4.3b** now additionally includes a **non-authoritative, source-rule-certified fragment** for Sort, bound variables, general-domain dependent Pi, lambda, exact-argument-type application and restricted let. The new `inferClosedGeneralPiCertified` entry validates BOTH source and inferred-result structural scope and carries an actual independent fragment-rule witness. **It is not a complete Lean type checker, definitional-equality engine, theorem-admission kernel or model-soundness theorem.**

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`; Lean pinned to `v4.35.0-rc4`. The unchanged G4.3b **executing** checker is a restricted six-rule typing fragment, not theorem admission. Latest proof/CI milestone: source and assumption gate through `b08feccc8bb06d7f5823636ec6d9f1badbafd6fe`, [Actions #38120030487](https://github.com/dwijayuda/pskernel/actions/runs/38120030487): **62 successful Lake jobs, 26 independent Lean sources audited and 15 exact theorem-assumption receipts**. Alongside independent structural [P1 scope metatheory](P1_SOUNDNESS_EVIDENCE.md), [P1 bounded typed substitution](P1_TYPED_SUBSTITUTION_EVIDENCE.md) now proves typed dependent-identity beta, variable-body let/zeta reduction and checked-head-binder variable weakening using the actual substitution/lifting algorithms. **General typed substitution, an actual set-theoretic denotational model, consistency, full Lean DefEq and proof admission remain UNPROVED/UNIMPLEMENTED.**

## Next

Continue the **full** dependent substitution/context preservation proof only where its cost supports a future executable soundness result; evaluate con-leche-style direct semantic preservation as the cheaper route around difficult syntactic inversion. Implement a genuine independent set-model interpretation, G4.4 typed positive-sound WHNF/DefEq and a protected checked environment without sacrificing freedom to optimize representation. Keep the second runtime output-scope check as defense in depth. Do not claim a consistency theorem or Lean kernel compatibility based solely on these bounded metatheory proofs.
