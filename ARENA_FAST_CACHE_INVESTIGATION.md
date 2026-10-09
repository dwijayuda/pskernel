# Allocation-free semantic-cache eligibility experiment

Parent proof-derived Arena kernel: `132d817071cd62c23a70c15984d6c73e14d6e856` (previously green full proof tree and 141/141 tutorial).
This experiment changes the implementation of the 256-node cache-eligibility scan only, preserving an independent exact reference implementation in `CachePolicy.lean`.

Invariant to prove: for all expressions `e` and budgets `n`,
`psKernelSemanticCacheRemainingFast e n = 0` iff the reference returns `none`;
otherwise `psKernelSemanticCacheRemainingFast e n = Nat.succ r` iff reference returns `some r`.
No fvar-containing entry is allowed. All semantic checking, admission, resource policies and failure classifications remain unchanged.

A native debugger sample at Actions #37940566847 showed repeated `psKernelSemanticCacheRemaining` stack frames allocating memory, interleaved with WHNF/recursor reduction, on the exact UTF8 theorem. The stage profiler #37940220722 confirmed checked inference is the stalled stage.

Benchmark with exact same-runner baseline/candidate interleaving. Do not claim completion unless formal equivalence, tutorial, historical negative-input corpus, full official Init+Std and Mathlib gates all pass. Until then keep branch isolated.