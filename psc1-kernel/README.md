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
- K2: WHNF and type inference. **IN PROGRESS** — separate Lean-faithful `whnfCore` and full `whnf`, independent `cheap_rec`/`cheap_proj` controls, Lean-4.34 Nat literal normalization (`succ`, add/sub/mul/pow/gcd/mod/div/beq/ble/land/lor/xor/shiftLeft/shiftRight`), the default 128 MiB numeral-size guard, exact UINT32 count rejection for `pow`/nonzero `shiftLeft`, exact UINT32 projection-index rejection, scoped `eagerReduce`, constructor projection reduction, ordinary/Nat-literal recursor reduction, quotient lift/ind reduction, string-literal projection/recursor expansion, a fail-closed native evaluator callback boundary, and Lean-4.34-faithful projection typing are implemented. Configurable `LEAN_NAT_MAX_SIZE` injection remains.
- K3: definitional equality and exact reduction ordering. **IN PROGRESS** — sort/constant-universe/app cases, opened-binder lambda/forall defeq, proof irrelevance, Nat-offset comparison, function eta, non-recursive structure eta, unit-like equality, scoped eager-reduction behavior, the Lean-4.34 lazy-delta one-step state machine (including projection-headed unfolding and the same-definition regular-hint shortcut), projection lazy-delta field comparison, native-reduction ordering, and the special `String` literal ↔ `String.ofList` expansion are implemented. Pair success/failure caches and deterministic resource fuel remain.
- K4: quotient and recursor reduction. **FOUNDATIONAL SLICE COMPLETE** — checked Lean-4.34-style Quot admission validates the Eq/Eq.refl bootstrap shape, rejects primitive-name collisions, installs all four Quot constants, and is differential-tested against Lean 4.34; quotient lift/ind reduction is wired into WHNF.
- K5: inductive/nested-inductive admission and generated metadata validation. **IN PROGRESS** — checked ordinary admission now covers empty datatypes, universe polymorphism with exact fresh recursor-universe naming, shared parameters, indices, non-recursive constructor fields, generated constructors/recursors/rules, Lean `infer_implicit(rec_ty, true)`, and defensive recursor type/rule checks. Differential oracles cover enum, empty, polymorphic, parameterized, field-bearing, and indexed examples. The current subset is fail-closed outside result universes provably nonzero; small/Prop elimination, direct recursion/positivity, mutual declarations, and nested-inductive restoration remain.
- K6: optional/fail-closed native-reduction boundary. **FOUNDATIONAL SLICE COMPLETE** — `NativeEvaluator` exposes only optional Bool/Nat callbacks; absent/unsupported results stay opaque, and the oracle verifies both successful callbacks and fail-closed behavior.
- K7: lean4export replay protocol.
- K8: direct/adversarial/Arena/bounded-corpus acceptance matrix.
- K9: compile the unchanged Lean source through PSC1 to TypeScript/JavaScript.
- K10: generate canonical `.ps` and require checked-core/IR parity.


### K5 ordinary-inductive checkpoint

The Lean-authored admission path no longer trusts exported constructor or
recursor metadata. It checks the declaration header and constructor types,
opens shared parameters and indices, validates constructor result applications,
generates constructor/recursor metadata itself, applies Lean 4.34's strict
implicit-inference pass to the recursor type, and type-checks the generated
recursor type and computation rules before installation.

This path is intentionally narrower than final Lean 4.34 today. It rejects
small/Prop-elimination cases unless the result universe is statically known
nonzero, and it rejects recursive constructor fields instead of approximating
positivity or recursive-hypothesis generation. Those are the next semantic
extensions; mutual/nested restoration follows after ordinary recursion is
closed.

### WHNF architecture checkpoint

The Lean-authored kernel now preserves the final Lean 4.34 distinction between
`whnfCore` and full `whnf`. `whnfCore` does not delta-unfold definitions
or run Nat/native normalization extensions. Full `whnf` repeatedly performs
core reduction, then the optional fail-closed native normalization callback,
then Nat reduction, then delta unfolding.

This separation is required for source-faithful lazy-delta definitional
equality. The source also keeps Lean 4.34's `cheap_rec` and `cheap_proj`
controls independent: initial defeq uses `(false, true)`, lazy-delta unfolding
uses `(false, true)`, and full core WHNF uses `(false, false)`.
