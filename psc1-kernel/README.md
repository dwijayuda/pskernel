# PSC1 Lean kernel

This directory is a new source-oriented implementation of the ProofScript kernel.

## Semantic authority

The target is **final Lean 4.34.0 kernel behavior**, especially:

- `study/lean4-4.34.0/src/kernel/level.cpp`
- `expr.cpp`
- `instantiate.cpp`
- `abstract.cpp`
- `type_checker.cpp`
- `environment.cpp`
- `declaration.cpp`
- `inductive.cpp`
- `quot.cpp`

The mature TypeScript kernel is an independent differential oracle, not the
specification for this source tree. Lean4Lean is an implementation/proof
reference only; final Lean 4.34 behavior wins on any disagreement.

## Bootstrap model

These files are authored now in bounded Lean intended for PSC1 and are checked
by real Lean 4.34 immediately. We do not wait for the PSC1 compiler to finish.

The intended later executable path is:

```text
PSC1Kernel/*.lean
  -> PSC1
  -> checked core / verified IR
  -> TypeScript
  -> pinned tsc
  -> JavaScript
```

The source therefore avoids tactics, arbitrary macros, unsafe pointer identity,
environment extensions and Lean metaprogramming. Runtime caches and JS-specific
optimizations are not part of kernel semantics.

## Equivalence criterion

We target observable kernel behavior, not generated-TypeScript text identity.

For supported declaration streams, the eventual acceptance criterion is:

```text
Lean 4.34 accepts  <=> PSC1Kernel accepts
Lean 4.34 rejects  <=> PSC1Kernel rejects
```

The first oracle directly compares Level equivalence/order and Expr
lift/instantiation against final Lean 4.34.

## Milestones

- K0: Name, Level, Expr, substitution/lifting/abstraction.
- K1: declarations, local context and immutable environment.
- K2: WHNF and type inference. **IN PROGRESS** — separate Lean-faithful `whnfCore` (beta/let/fvar/projection only) and full `whnf` (core → Nat → delta), Lean-4.34 Nat literal normalization (`succ`, add/sub/mul/pow/gcd/mod/div/beq/ble), constructor projection reduction, and Lean-4.34-faithful projection typing are implemented; bitwise/shift Nat extensions, resource-size guards, recursor/quotient reduction and full cheap-projection control flow remain.
- K3: definitional equality and exact reduction ordering. **IN PROGRESS** — sort/constant-universe/app/binding/projection cases exist; binding defeq follows Lean 4.34 by ignoring binder annotations and proof irrelevance is implemented. Function eta, non-recursive structure eta, unit-like equality, and Lean-4.34 reducibility-hint-guided lazy delta are implemented. String-literal expansion, exact projection lazy-delta specialization, failure/equivalence caches and resource fuel remain.
- K4: quotient and recursor reduction.
- K5: inductive/nested-inductive admission and generated metadata validation.
- K6: optional/fail-closed native-reduction boundary.
- K7: lean4export replay protocol.
- K8: direct/adversarial/Arena/bounded-corpus acceptance matrix.
- K9: compile the unchanged Lean source through PSC1 to TypeScript/JavaScript.
- K10: generate canonical `.ps` and require checked-core/IR parity.


### WHNF architecture checkpoint

The Lean-authored kernel now preserves the final Lean 4.34 distinction between
`whnfCore` and full `whnf`. `whnfCore` does not delta-unfold definitions
or run Nat/native normalization extensions. Full `whnf` repeatedly performs
core reduction, then the normalization-extension slot (native remains
fail-closed/unimplemented), then Nat reduction, then delta unfolding.

This separation is required for source-faithful lazy-delta definitional
equality and cheap projection reduction.
