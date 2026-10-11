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

## Current executable state

The V3 research package has completed narrowly checked G1 scoped representation, G2 beta-only evaluator experiments, G3 structural preflight, G4.0 sound-but-incomplete symbolic level equality, G4.1 an UNTRUSTED candidate catalog, G4.2 Sort/Pi formation, and G4.3 structural binder/substitution proof work. **G4.3b** now additionally includes a **non-authoritative, source-rule-certified fragment** for Sort, bound variables, general-domain dependent Pi, lambda, exact-argument-type application and restricted let. The new `inferClosedGeneralPiCertified` entry validates BOTH source and inferred-result structural scope and carries an actual independent fragment-rule witness. **It is not a complete Lean type checker, definitional-equality engine, theorem-admission kernel or model-soundness theorem.**

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`, Lean pinned to `v4.35.0-rc4`. **Latest qualified P1e proof/CI source**: `8de790e40c0ecacea1ff80390f7b636bb9cffd63`, [Actions #38126457033](https://github.com/dwijayuda/pskernel/actions/runs/38126457033), **86 green Lake jobs, 38 independent Lean files audited, 84 reviewed theorem receipts**. P1e adds an actual proposition-subset set interpreter, successful executing-source-to-denotation proofs for `∀P:Prop,P` (false) and `∀P:Prop,P→P` (true), and a reusable checked `Pi` annotation relation with source-faithful erasure and conditional model membership. **Critical new finding:** the original P1d truth carrier has a proved proof-point collision. An alternate V2 carrier proves point-in-True and point-not-in-Prop with two distinct truth values, but it **does not yet satisfy required disjointness from writable graphs/numerals/quotients** and has NOT replaced the canonical candidate. [Detailed P1e evidence](P1E_CHECKED_DENOTATION_EVIDENCE.md). **No full Lean type/DefEq soundness, a finished proof-irrelevant model, conditional consistency theorem or theorem-admission capability exists**.

## Next

**P1e next:** prove a distinguished model proof point disjoint from the *entire* writable data representation, not merely proposition values; then migrate `sortSet` and the proposition interpreter to that qualified representation and recheck the two executed-source cases. Prove general semantic fibre validity from actual recursive typed premises, a hereditary `WellDenoted` theorem, Type-valued dependent `Pi`, proof irrelevance and beta/let denotation; only then complete G4.4 typed DefEq, checked declarations, relative consistency, official Lean 4.35 differential acceptance and real kernel-only benchmarks. The G4.3b executable checker remains unchanged and theorem admission disabled.
