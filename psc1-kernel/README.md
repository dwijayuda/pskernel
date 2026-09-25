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
- K2: WHNF and type inference. **IN PROGRESS** — separate Lean-faithful `whnfCore` and full `whnf`, independent `cheap_rec`/`cheap_proj` controls, Lean-4.34 Nat literal normalization (`succ`, add/sub/mul/pow/gcd/mod/div/beq/ble/land/lor/xor/shiftLeft/shiftRight`), the default 128 MiB numeral-size guard, exact UINT32 count rejection for `pow`/nonzero `shiftLeft`, exact UINT32 projection-index rejection, scoped `eagerReduce`, constructor projection reduction, ordinary/Nat-literal recursor reduction, quotient lift/ind reduction, and Lean-4.34-faithful projection typing are implemented. Configurable `LEAN_NAT_MAX_SIZE` injection remains. String-literal projection/recursor hooks use the final Lean 4.34 expansion shape; full `strLitProj` end-to-end parity still waits for the real String environment/replay layer.
- K3: definitional equality and exact reduction ordering. **IN PROGRESS** — sort/constant-universe/app cases, opened-binder lambda/forall defeq, proof irrelevance, Nat-offset comparison, function eta, non-recursive structure eta, unit-like equality, scoped eager-reduction behavior, the Lean-4.34 lazy-delta one-step state machine (including projection-headed unfolding and the same-definition regular-hint shortcut), projection lazy-delta field comparison, and the special `String` literal ↔ `String.ofList` expansion are implemented. Pair success/failure caches, deterministic resource fuel, and the native-reduction provider slot remain.
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
equality. The source also keeps Lean 4.34's `cheap_rec` and `cheap_proj`
controls independent: initial defeq uses `(false, true)`, lazy-delta unfolding
uses `(false, true)`, and full core WHNF uses `(false, false)`.
