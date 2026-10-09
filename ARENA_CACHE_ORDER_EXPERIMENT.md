# Cache eligibility short-circuit optimization — isolated experiment

Parent kernel: `f57cdaa907939d442eb0a1b539f108ad149a4460`, with the synchronized proof source inherited unchanged except `CachePolicy.lean`.

## Exact invariant

For infer-only = false, `PsKernelExpr.lit`, `.app`, `.lam` and `.forallE` never publish an inference cache entry (already the existing policy); the original implementation nevertheless recursively evaluated `psKernelExprHasFVar` on their entire expression tree before rejecting. The candidate selects the outer constructor first and returns false immediately for these shapes. All other branches still require the *same* `psKernelSemanticCacheEligible` fvar-scope check, so the mathematical eligibility predicate is unchanged for every input.

No weakening of admission rules, soundness, fvar isolation, fuel, or error classification. The optimization avoids scan work that has no effect on caching.

Do not merge into the ongoing proof branch until same-runner A/B, tutorial 141/141, 18 historical cases, and proof/foundation gates establish equivalence. Full Init/Std and Mathlib are not accepted by a prefix benchmark.
