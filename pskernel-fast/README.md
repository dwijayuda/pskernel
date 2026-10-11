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

## Current executable state

The V3 research package has completed narrowly checked G1 scoped representation, G2 beta-only evaluator experiments, G3 structural preflight, G4.0 sound-but-incomplete symbolic level equality, G4.1 an UNTRUSTED candidate catalog, G4.2 Sort/Pi formation, and G4.3 structural binder/substitution proof work. **G4.3b** now additionally includes a **non-authoritative, source-rule-certified fragment** for Sort, bound variables, general-domain dependent Pi, lambda, exact-argument-type application and restricted let. The new `inferClosedGeneralPiCertified` entry validates BOTH source and inferred-result structural scope and carries an actual independent fragment-rule witness. **It is not a complete Lean type checker, definitional-equality engine, theorem-admission kernel or model-soundness theorem.**

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`; native source toolchain pinned to Lean 4.35.0-rc4. **Latest independently inspected source green:** `253afb42b477aacab22def288a2dd42d7ca9633b`, [GitHub Actions #38116916150](https://github.com/dwijayuda/pskernel/actions/runs/38116916150), **54 successful build jobs**, 22 independent V3 Lean sources audited, all earlier focused regressions and dedicated G4.3b rules/scoped-output tests passed. See [G4.3b evidence](G4_GENERAL_PI_EVIDENCE.md). Other proof branches and draft PR #89 were not modified.

## Next

G4.3b's general-domain Pi/lambda/application/restricted-let experiments are green **only in their explicitly bounded syntactic fragment**. The next gated work is source-sound **typed WHNF/DefEq (G4.4)** with complete symbolic universe rules and strict positive/unknown decisions, followed by an actually protected checked environment and proof-admission refinement/model proofs. The current application/let type-preserving substitution theorem, official-Lean typed differential tests, and resource/heap budgets remain open. No previous proof preservation constraint may compromise performance or correctness.
