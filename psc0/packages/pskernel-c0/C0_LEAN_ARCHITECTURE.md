# PSKernel-C0 Lean-native performance architecture

This work is in `src/Ps/KernelCore/**/*.lean`, not the experimental Rust engine.
The original `psc0/packages/pskernel-core` and PSC0 compiler are unchanged.

## Radix-16 cache index

`Runtime/Acceleration/Cache.lean` now implements a single generic, persistent, array-backed radix-16 trie used by both the expression-result map and expression-pair equality sets. The prior implementation duplicated a radix-2 binary trie for both uses.

- The bounded 16-bit C0 expression hash is split into four nibbles, so the lookup path uses four levels rather than sixteen.
- The small-cache list path remains in place (up to eight entries).
- Hash collisions are always resolved by the existing `psKernelExprEq` / `psKernelExprPairEq`. Hash equality is not proof of definitional equality.
- The semantic cache APIs and accepting kernel operation are unchanged.
- The radix trie is a structural performance experiment, not a measured improvement yet. Benchmark native Lean workloads before making speedup claims.

A standalone C0 `lakefile.lean` and a focused GitHub Actions build validate the native Lean semantic closure without running any self-host/compiler/bootstrap checks.

## Next architectural steps

- Remove redundant substitution prepasses for actual beta/zeta hot paths.
- Reduce repeated full-term hashing with a stronger shared metadata representation or context-scoped indexed terms.
- Measure cache loads, cold/warm WHNF/DefEq, allocation and peak RSS against the copied original kernel.
- Build toward a compact Lean-authored term DAG/handle execution representation only with a lossless bridge and semantic qualification.

Metatheory and consistency proofs are not part of the performance sprint; no change may cause false acceptance of malformed terms.
