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

## Current executable state

The V3 research package has completed narrowly checked G1 scoped representation, G2 beta-only evaluator experiments, G3 structural preflight, G4.0 sound-but-incomplete symbolic level equality, G4.1 an UNTRUSTED candidate catalog, G4.2 Sort/Pi formation, and G4.3 structural binder/substitution proof work. **G4.3b** now additionally includes a **non-authoritative, source-rule-certified fragment** for Sort, bound variables, general-domain dependent Pi, lambda, exact-argument-type application and restricted let. The new `inferClosedGeneralPiCertified` entry validates BOTH source and inferred-result structural scope and carries an actual independent fragment-rule witness. **It is not a complete Lean type checker, definitional-equality engine, theorem-admission kernel or model-soundness theorem.**

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`. Pinned Lean `v4.35.0-rc4`. The last qualified restricted G4.3b implementation remains `253afb42b477aacab22def288a2dd42d7ca9633b`. **P0/P1 formal-safety checkpoint**: the independent `ContextScoped` spec, G3 executable scope equivalence, proofs that all six G4.3b rule outcomes preserve source and type scope, and proofs that the second runtime output scope check cannot fail after successful inference. [Cloud CI 38118786036](https://github.com/dwijayuda/pskernel/actions/runs/38118786036) passed 60 Lake jobs, audited 25 independent V3 Lean source files, and pinned 7 theorem-assumption receipts to `propext`, `Classical.choice`, `Quot.sound` with fail-closed synthetic tests. Read the exact [P1 evidence](P1_SOUNDNESS_EVIDENCE.md). **No type-preserving substitution, set-theoretic denotational soundness, consistency theorem, general DefEq, real kernel benchmarks or theorem admission has been established.**

## Next

The new P0/P1 proof contracts are green in their **structural** scope, separate from the executing checker. Next formalize and prove the **type-preserving** dependent substitution theorem, then derive a genuinely denotational (set-theoretic) soundness theorem against the executing rules, and develop G4.4 typed WHNF/DefEq. Keep the second runtime output check for defense in depth despite the new proof it is unreachable when first inference succeeds. Preserve old GitHub branches and do not advertise a finished Lean kernel or consistency proof.
