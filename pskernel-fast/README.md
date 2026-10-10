# PSKernel-Fast V3

A **new-generation** proof-kernel research program that prioritizes Lean 4.35 compatibility, sound positive results, high performance, small trusted computing base and explicit resources. **No obligation exists to preserve legacy PSKernel implementation or proof interfaces.**

- [Authoritative V3 architecture](PSKERNEL_FAST_ARCHITECTURE_V3.md)
- [MVP scope / correctness contract](MVP_SCOPE.md)
- [Live work state and evidence](AI_WORK_STATE.md)

## Current executable state

Only the **non-authoritative scoped term-store prototype** exists: `src/PSKernelFast/TermStore.lean` encodes a tiny closed expression subset into collision-checked interned nodes and decodes them with bounded fuel. It is **not a Lean kernel, does not type-check declarations and cannot accept a proof**. This deliberate restriction prevents a partially built checker from being mistaken for an authoritative soundness mechanism.

Native experiment uses Lean `v4.35.0-rc4`:

```bash
cd pskernel-fast
lake build pskernel_fast_smoke
lake exe pskernel_fast_smoke
```

Research branch: `research/pskernel-fast-clean-v3-20261011`. The active PSKernel proof branch and PR #89 are not changed. GitHub Actions workflow `pskernel-fast-v3.yml` is the cloud validation gate for this prototype. The [first successful source checkpoint](https://github.com/dwijayuda/pskernel/actions/runs/38094070233) built six targets and passed the focused smoke; the source still cannot accept proofs.

## Next

Develop a precise scoped term-store specification and prove encode/decode and interning invariants. Benchmark representative node-sharing and beta-heavy workloads on identical input/runners. Only then introduce independent checked-inference/WHNF/DefEq prototypes and complete versioned Lean 4.35 semantics. Keep any proof-acceptance entry point **absent** until a legitimate fully checked admission layer exists.
