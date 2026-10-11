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
- [P1c independent erased semantic syntax, beta/let correspondence, and erasure totality](P1C_SEMANTIC_ERASURE_EVIDENCE.md)
- [P1d conditional Sort, two-valued Prop, and proposition-valued Pi set-model evidence](P1D_SET_MODEL_EVIDENCE.md)
- [P1e checked-source Prop denotation, certified annotations and proof-point representation blocker](P1E_CHECKED_DENOTATION_EVIDENCE.md)
- [P1f first-principles tagged proof point, finite-pair universe closure and typed quotient boundary](P1F_TAGGED_MODEL_EVIDENCE.md)

## Current executable state

The V3 research package has completed narrowly checked G1 scoped representation, G2 beta-only evaluator experiments, G3 structural preflight, G4.0 sound-but-incomplete symbolic level equality, G4.1 an UNTRUSTED candidate catalog, G4.2 Sort/Pi formation, and G4.3 structural binder/substitution proof work. **G4.3b** now additionally includes a **non-authoritative, source-rule-certified fragment** for Sort, bound variables, general-domain dependent Pi, lambda, exact-argument-type application and restricted let. The new `inferClosedGeneralPiCertified` entry validates BOTH source and inferred-result structural scope and carries an actual independent fragment-rule witness. **It is not a complete Lean type checker, definitional-equality engine, theorem-admission kernel or model-soundness theorem.**

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`, pinned Lean `v4.35.0-rc4`. **Latest P1f proof/CI qualification**: source `367ddf25d3d97e7fb0b88c86dbeed7410d51dc10`, [Actions #38129546961](https://github.com/dwijayuda/pskernel/actions/runs/38129546961): **94 successful Lake jobs, 42 independent Lean files audited and 110 exact theorem receipts**. The independent tagged-point construction now proves point≠writable model Kuratowski pairs, function graphs, von Neumann numerals and Prop truth values; its Prop carrier has exactly two truth values and belongs to Type1. Crucially, finite-pair universe closure was **derived from the already supplied Tarski size axioms** with a three-vs-two argument, not postulated. Unconditional quotient/image freshness is provably false, so it requires *typed quotient restrictions*. The earlier P1d/P1e interpreters still use the provisional, inadequate carrier and have NOT been migrated. See [P1f evidence](P1F_TAGGED_MODEL_EVIDENCE.md). **No globally consistent Lean kernel, general proof-point/quotient semantics, complete typed DefEq, proof admission or real checking performance demonstration exists.**

## Next

**P1f next:** define a proof-only, versioned Prop model interface that captures the qualified tagged point, Type1 universe membership and typed writable-data restrictions. Migrate the partial `sortSet/propPi/interpProp` mathematics coherently, reprove the two actual checked-source true/false results with the tagged carrier, and then add genuine type-valued dependent functions and `WellDenoted` inheritance. Typed quotient rules must be certified rather than assuming impossible global freshness. Leave G4.4 WHNF/DefEq, model-preserving declaration checking, relative consistency and proof admission gated until soundness is truly established; benchmark only real kernel workloads.
