# G4.3 → dependent formation vertical slice: source-matched evidence

**Status:** independently verified **restricted dependent Sort/Pi inference**, NOT general
Lean kernel typing, DefEq, theorem admission or model soundness.

- **Exact green source:** [`35ce306421368e8b8689b143e8e70ce0a4b03d73`](https://github.com/dwijayuda/pskernel/commit/35ce306421368e8b8689b143e8e70ce0a4b03d73)
- **Cloud run:** [38115500178](https://github.com/dwijayuda/pskernel/actions/runs/38115500178), job `114399479495`, **completed success**.
- **Pinned Lean:** 4.35.0-rc4, upstream source `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **Executed gate:** 49 native Lake build jobs; source-import/placeholder fence reports 20 independent Lean modules; G1–G4.3 prior regressions and the new dependent-former tests pass. Only focused corpus; no new kernel-level benchmark.

## Exact code and correctness

`src/PSKernelFast/DependentSortFragment.lean` introduces
`VerifiedSortLevel params`, a dependent value carrying G3 `ULevel.WellFormed`
evidence. It defines **one separate source-level judgment**
`DependentSortRule params ctx expr level`, interpreted as the
strictly **restricted** assertion that the expression's inferred type is
`Sort level` when every context variable has a syntactically `Sort u`
binder domain with a verified universe level.

The judgment has only these rules:

1. `Sort u : Sort (succ u)` for verified `u`.
2. A bound variable in the verified Sort-only context has the precise Sort type from that entry (de Bruijn indexing; levels are independent of term binder depth).
3. `Pi (x : Sort u), body : Sort (imax (succ u) bodyLevel)`, when the codomain is recursively certified in the context extended with the verified `Sort u` binder.

`inferDependentSort` constructs these dependent witnesses from its **actual**
recursive operations; `inferClosedDependentSort` additionally applies the
real G3 closed-input preflight. Compiling theorem
`inferClosedDependentSort_sound` connects every successful executable result
to G3 declarative structural validity **and** this independently stated,
bounded `DependentSortRule`. The theorem does not establish general
type-theoretic soundness beyond these three premises, and the internal
`DependentSortRule` is NOT a certificate to use for theorem admission.

## Executed tests

- `forall (P : Prop), P` with a genuine dependent codomain `bvar 0`.
- Nested dependent Pi, whose codomain reads an outer binder at `bvar 1`.
- Symbolic parameter version `forall (A : Sort u), A`.
- Agreement of the shared syntactic Sort/Pi subset with the earlier G4.2 certified fragment.
- Strict malformed rejection for escaped bound variables and undeclared universe parameters; `lambda` classified unsupported, not validated.

The first integrated test-source commit `7699898` failed because the smoke
harness used an unavailable `BEq (Except ...)` instance and compared different
error types; **the new proof module itself compiled**. The succeeding `35ce306`
uses explicit outcome matching. The logical rules and checker semantics were
not weakened or modified to satisfy the test harness.

## Trust and performance boundaries

The validated context restricts every binder domain to **syntactic `Sort u`**.
It does NOT check arbitrary term domains, lambda/application/let terms, general
constants, transparency, proof irrelevance, WHNF/DefEq, inductives/quotients,
declaration safety/axiom policies, or a relative consistency model. Symbolic
universe equivalence remains the G4.0 *partial positive-only* comparator.
No native/JS/Wasm parity or kernel speedup has been established. The
reference list-context lookup is **not** claimed to be production-optimized.
Resource/cost limits for large expressions and validated input sessions still
need design and measurements.

**Next hard step:** a genuinely typed, protected binder context with validated
sort witnesses from an actual checking engine, checked-vs-infer-only separation,
and source-sound infer/check on non-Sort-domain Pi and lambda/application/let
under typed DefEq. Do not treat the current Sort-only relation, G4.1 candidate
catalog, or structural scoping proofs as general checked type authority.
