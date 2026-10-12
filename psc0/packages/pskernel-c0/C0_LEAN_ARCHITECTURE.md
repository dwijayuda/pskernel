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



## Adaptive local binder contexts — measured write/read separation

The generic radix trie remains useful for repeated **deep** lookups but is
too expensive to maintain at every binder extension in short-lived contexts.
End-to-end native controlled ablations established that eager indexing at the
ninth binder caused a checked definition-admission slowdown; merely moving
the threshold to 32 left depth-48 regression visible.

The Lean-native local-context representation is now:

- An authoritative persistent `decls` list and monotonically growing
  `nextIndex` used for local identities and observable ordering.
- For contexts of up to 64 declarations, direct ordered-list lookup only.
- Beyond that, an immutable `index` snapshot plus `pending` recent
  declarations and `pendingCount` (strictly below 16).
- Lookup checks `pending` newest-first, then structurally checks the radix
  bucket. The 16th new pending binder publishes a new index with oldest-first
  insertion; persistent older scopes keep their exact old snapshot.

The index is **never** trusted as a typing/equality verdict. Snapshot
publication and collision handling do not alter acceptance, resource/fuel
exhaustion, local name shadowing, or fresh-name numbering. Explicit ordinary
and mutual inductive continuation constructors preserve all three
index-related fields. Native differential tests compare lookup and shadowing
with the authoritative list around promotion and batching boundaries.

The actual checked 16-/48-binder declaration benchmark recovered parity
with original PSKernel-Core after this redesign. 512-local repeated lookups
retain a large measured advantage relative to linear scanning at the cost of
more expensive index construction. See `C0_BENCHMARKS.md` for exact CI
numbers and limitations. The canonical indexed expression arena is **still
not** used for full accepting evaluation; that separate architecture gate
remains unfinished.
