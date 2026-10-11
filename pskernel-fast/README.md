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

## Current executable state

The independent prototype includes G1 scoped storage, G2 beta-only evaluator comparisons, G3 proved structural preflight, G4.0 sound-but-incomplete symbolic universe positive comparisons, G4.1 an untrusted candidate catalog, G4.2 certified restricted Sort/Pi formation, and G4.3 a structurally verified binder frame. None of these is a full dependent checker or proof-admission mechanism. The original G1 **non-authoritative scoped term-store prototype** `src/PSKernelFast/TermStore.lean` encodes a tiny closed expression subset into collision-checked interned nodes and decodes them with bounded fuel. None is **a Lean proof-checking kernel**; the package still does not type-check declarations or accept proofs. This deliberate restriction prevents a partially built checker from being mistaken for an authoritative soundness mechanism.

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`. The active PSKernel proof branch and PR #89 are not changed. GitHub Actions workflow `pskernel-fast-v3.yml` is the cloud validation gate for this prototype. The [latest independently inspected green code checkpoint](https://github.com/dwijayuda/pskernel/actions/runs/38110413629) built 45 Lake targets, audited 18 independent Lean source modules, and passed G1–G4.3 focused suites. Later `c22863ba`/`9ddd8ed1` introduce reference binder lifting and tests, but their cloud CI success is **not yet confirmed**. Do not promote those changes as proved/validated until the completed matching job is inspected.

## Next

Verify the new G4.3 lifting candidate in cloud CI, then construct a scope-correct local-domain lookup, exact substitution and genuinely dependent inference; keep the stored domains distinct from checked types. Complete symbolic level equivalence/inequality, guarded DefEq/WHNF and a sealed checked declaration environment before any admission capability. Only evaluate performance on representative *real checker* operations. Keep proof admission **absent** until fully checked admission and associated soundness gates exist.
