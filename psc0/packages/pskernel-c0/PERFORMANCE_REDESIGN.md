# PSKernel-C0 — Performance Architecture Exploration

This package is a copy of `psc0/packages/pskernel-core` from `main` (`748ee630e43ee1a89643cbc8cec3e31087788b08`), with an independent npm package identity. The original core is untouched.

## Scope

Prioritize low-level kernel performance, correctness under Lean semantic conformance, and comparative benchmarks. Metatheory and consistency proofs are deferred for this experimental branch; do not claim them as completed or silently relax kernel acceptance.

## Next steps

1. Capture reproducible cold/warm baseline benchmarks (time, peak memory, allocations) for inference, WHNF, conversion, declaration admission, and representative library exports.
2. Inventory term representation, allocation, substitution and caches before modifying algorithms.
3. Prototype compact term handles/hash-consing with declaration-scoped arenas behind a representation boundary.
4. Explore lazy substitution and demand-driven definitional equality without changing acceptance semantics.
5. Benchmark against the unmodified `pskernel-core` and require identical verdicts on positive and negative conformance suites before considering adoption.

## Isolation

Do not modify the existing `pskernel-core`, root package registries, or downstream consumers without an explicit integration decision. Internal namespace paths remain unchanged initially, so the duplicate is isolated by package directory and package identity, not yet a simultaneously linkable Lean module namespace.
