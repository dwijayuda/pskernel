# PSKernel-Fast V3 — G3 structural Lean 4.35 semantic substrate

**Status:** source-shape / structural-preflight specification only; no type checker, no DefEq, no proof admission. Target pin: Lean 4.35.0-rc4 `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

## Grounding

- [Official Lean 4.35 `src/kernel/level.h`](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/level.h): `zero/succ/max/imax/param/mvar`.
- [Official Lean 4.35 `src/kernel/expr.h`](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/expr.h): bound/free/metavariables, sort, constant, application, lambda, Pi, let, Nat/String literals, metadata, projection, binder annotations (including `Rec`).
- [Official `src/kernel/type_checker.cpp`](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp): checked/infer-only distinction, universe parameter admissibility, literal typing, unsafe/partial declaration constraints. None of these rules is implemented by the G3 preflight.
- [Lean's own `Lean.Nat.imax`](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/Lean/Level.lean): ground `imax u v` returns zero when `v=0`, otherwise `max u v`.

## Implementation

`CoreSyntax.lean` creates PSKernel-owned `KName`, `ULevel`, `BinderStyle`, `KLiteral`, `KExpr`. They **do not import the old PSKernel implementation**. `KExpr.closedInput` rejects escaped bound variables, free/metavariables, undeclared universe parameters, universe metavariables and wrong let/lambda/Pi binder scope. It does **not** verify whether named constants exist or have correct universe arity, nor typing, projection indices, positivity, recursion or quotient rules.

`ULevel.groundEval` computes *numerical* interpretations using an externally supplied valuation. This is **not** Lean's symbolic universe equivalence algorithm: finite ground testing cannot replace `Level.isEquivalent`, `is_geq` or the exact nonlinear `imax` normalization used by Lean. Missing parameters fail as `none`; no finite sample licenses arbitrary symbolic universe equality.

`mdata` currently uses an opaque `Nat` tag; it must be refined with a faithful importer or a proved semantics-preserving erasure before claiming full metadata interchange. The `BinderStyle.recursive` case maps to official `binder_info::Rec`.

The existing G1/G2 `RawExpr` with `Nat` sorts and its three beta-only evaluators are **historical experiments**, not the final V3 logical syntax. They must not become a hidden compatibility constraint.

## Minimum acceptance to move from structural G3 to checked G4

1. Prove the executable structural preflight has the intended scopedness and level-parameter property, with no trusted parser artifact fabricating a checked result.
2. Add a separate strict environment containing typed constants, checked universe parameter arities, safety/opacity, and no forged declaration state.
3. Specify and test the exact kernel judgments for sorts, bound/local variables, Pi/lambda/application, let, literals, and symbolic universe equivalence; match official Lean 4.35 valid and invalid cases before allowing theorem acceptance.
4. Add reductions, proof irrelevance, eta, inductive recursors and quotients by *algorithm family*, preserving fail-closed resource outcomes. Imported checker/tactic extensions remain untrusted.
5. Measure native checking throughput and memory on the *actual* semantic implementation, not just the old beta-only microbenchmark. Add model/refinement evidence for all authoritative positive shortcuts.

**No proof-checking or full Lean-compatibility claim follows from compiling this source.**
