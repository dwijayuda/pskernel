# PSKernel-Fast V3 — G1 bounded prototype scope

**Purpose:** build a new, independent, correctness-shaped kernel representation foundation. No old checker or metatheory dependency. This is a **prototype**, not a proof kernel.

## Included (at this checkpoint)

- Recursive raw syntax limited to bound variables, sorts, applications and lambdas. Level is a **Nat placeholder**, not full Lean universe algebra.
- Total encoder with binder-depth validation and exact collision-checked interning.
- Functional node store with allocation limit and exact index-handle validation.
- Fuel-bounded decoder rejecting unknown handles or cycles.
- Focused executable smoke test of round-trip, intern reuse, bound-variable rejection, allocation budget, forged index and cycle exhaustion.
- Pinned Lean 4.35.0-rc4 native Lake build (CI evidence must be recorded before “green” claim).

## Deliberately missing

- Actual Lean Name, universe `imax/max`, constants and parameter substitution.
- Term typing, checking grades, proof irrelevance, WHNF, definitional equality.
- Inductive checking, quotients, theorem declaration admission, axiom policy.
- Formal proofs that encode/decode is a round-trip for every input or that interning cannot alias across valid stores.
- Memory-compact constructor-specific arena, lazy closures, NbE, call-by-need.
- Official Lean differential corpus, Mathlib replay, measured performance.
- Source-to-JS/Wasm qualification or full ProofScript self-hosting.

## Hard safety law

The prototype exports **no `accept` or `checkDeclaration` API**. No successful interning, decoder round-trip or `#eval` is evidence that any theorem has been checked. A future admission API must require validated exact context, term/type, version, and policy; every accepting fast shortcut must have a proof or trusted canonical recheck.

## First proof targets

1. `encode_sound`: if `encode` succeeds under validated input, returned node is in range and well-scoped.
2. `intern_lookup`: after insertion under a valid store invariant, lookup at returned ID reconstructs exact input node.
3. `decode_encode`: given sufficient fuel and valid budget, decode of encoded raw input equals the input.
4. `cannot_escape_scratch`: admitted environment cannot retain any temporary-generation handle (once a real environment exists).
5. `no_forged_check_result`: untrusted host input cannot manufacture a checked-grade result (once checking exists).

Keep all status words precise: intended vs implemented vs CI-passed vs formally proved.
