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

## Current executable state

The independent prototype includes G1 scoped storage, G2 beta-only evaluator comparisons, G3 proved structural preflight, G4.0 sound-but-incomplete symbolic universe positive comparisons, G4.1 an untrusted candidate catalog, G4.2 certified restricted Sort/Pi formation, and G4.3 certified structural binder frames, capture-avoiding lifting, current-context domain lookup, scope-preserving substitution, and a further **restricted dependent Sort/Pi formation fragment** for verified Sort-only binder contexts.  None of these is a full dependent checker or proof-admission mechanism. The original G1 **non-authoritative scoped term-store prototype** `src/PSKernelFast/TermStore.lean` encodes a tiny closed expression subset into collision-checked interned nodes and decodes them with bounded fuel. None is **a Lean proof-checking kernel**; the package still does not type-check declarations or accept proofs. This deliberate restriction prevents a partially built checker from being mistaken for an authoritative soundness mechanism.

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`. The active PSKernel proof branch and PR #89 are not changed. GitHub Actions workflow `pskernel-fast-v3.yml` is the cloud validation gate for this prototype. The [latest independently inspected green code checkpoint](https://github.com/dwijayuda/pskernel/actions/runs/38115500178) is `35ce306421368e8b8689b143e8e70ce0a4b03d73`: 49 successful Lake build jobs, 20 audited independent V3 Lean files, all G1–G4.3 focused smokes and new dependent Sort/Pi formation fixtures. See [exact dependent-fragment evidence](G4_DEPENDENT_SORT_EVIDENCE.md), alongside the prior [binder scope/substitution proof evidence](G4_BINDER_EVIDENCE.md). This is **not** a general checked typing or proof-admission kernel.

## Next

The G4.3 binder operations and first **restricted dependent Sort/Pi** rule fragment are implemented and green. Next, implement a **separate general well-typed context and genuinely dependent fully-checked inference** for arbitrary well-typed domains (not only syntactic `Sort u`), with exact binder-sort observations and a sound typed conversion strategy. Maintain strict separation from untrusted G4.1 candidate declarations. Complete symbolic universe equivalence/`isGEq`, WHNF/DefEq and a protected checked environment before any theorem-admission interface. Measure performance only on representative real checker operations.
