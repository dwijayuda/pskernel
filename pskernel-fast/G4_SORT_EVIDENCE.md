# G4.2 — Sound formation fragment (exact evidence)

**Source:** [`dc43ce850291dc5527c933a8f5d86c408c40eb27`](https://github.com/dwijayuda/pskernel/commit/dc43ce850291dc5527c933a8f5d86c408c40eb27)  
**Cloud:** [GitHub Actions run 38110171823](https://github.com/dwijayuda/pskernel/actions/runs/38110171823), job `114383914870`, **PASS**.  
**Target:** Lean `4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Coverage:** 40 native build targets; architecture fence for 16 independent Lean source files; all G1/G2/G3/G4.0/G4.1 regressions and the new G4.2 smoke passed.

## What was proved about the executing code

The new `SortFragment.lean` implements `inferSortShape`, which *constructs a dependent certificate* proving `SortFragmentRule expr typeLevel` for exactly two supported syntactic rules:

1. `Sort u : Sort (succ u)`.
2. `forallE x (Sort u) (Sort v) : Sort (imax (succ u) (succ v))`, with only **syntactically Sort** domain/codomain.

The executable `inferClosedSortFragment` returns a type level only after checking the independent G3 closed-input preflight. The theorem `inferClosedSortFragment_sound` connects every successful result to **both** `KExpr.StructurallyValid params 0 expr` and the above explicit `SortFragmentRule`. No old kernel implementation/proofs, new axiom or `sorry` is used.

## Negative cases

Malformed universe names or metavariables, free variables and escaped de Bruijn indices yield `FormationError.malformed`. Structurally valid but unsupported terms—including lambdas, general applications, lets and dependent codomains with bound-variable use—yield `FormationError.unsupported` **rather than a false type-checking success**.

There is no environment-backed general typing, no definitional equality, proof irrelevance, inductives/quotients, unchecked compiler evaluator, model consistency proof, or proof-admission API. Neither catalog entries nor this limited formation type can certify a theorem.

## Next formal/prod obligations

Build exact scoped contexts and versioned constant environments, then extend source-rule families via WHNF + symbolic DefEq with proper resource and scope invariants. Validate the actual checked result (not guessed annotations) and prove the model/accepting environment contract. A result from this narrow fragment cannot be reused as a fully checked universal type certificate.

**Audit warning:** one Lean linter warning about an unused `h` binder appears in `SortFragment.lean`; it does not block the compiled theorem, but can be cleaned up when modifying that function for broader checking.

This checkpoint is **formation-fragment correctness**, not full Lean 4.35 conformance or kernel soundness.
