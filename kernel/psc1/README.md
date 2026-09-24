# PSC1-authored Lean 4.34 kernel

This tree is a **new kernel implementation authored in Lean source**, intended
to become compilable by PSC1 to TypeScript and then JavaScript.

The semantic target is the pinned **original Lean 4.34 kernel**, not the
existing hand-written TypeScript pskernel implementation.

## Authority order

1. pinned Lean 4.34 kernel sources under `study/lean4-4.34.0/src/kernel/`;
2. direct executable parity against Lean 4.34 APIs where those APIs expose the
   same kernel operation;
3. Lean Kernel Arena / existing oracle evidence;
4. the existing TypeScript pskernel as an independent differential
   implementation.

The TypeScript implementation is intentionally **not** a source template for
this tree. JavaScript-specific caches, WeakMaps, object freezing, object
identity, GC behavior, and other runtime optimizations are not kernel
semantics.

## Bootstrap strategy

We do not wait for the PSC1 compiler to be finished.

Today:

```text
kernel/*.lean
  -> Lean 4.34 compiler/checker
  -> direct parity tests against original Lean kernel operations
```

Later, without rewriting the source:

```text
kernel/*.lean
  -> PSC1
  -> checked core / verified IR
  -> TypeScript
  -> tsc
  -> JavaScript
```

The source is therefore written conservatively in the intended PSC1
implementation subset: ordinary inductives, structures/data, functions,
pattern matching, recursion, `Nat`, `Bool`, `String`, `List`, and
`Option`. Lean-specific test adapters are kept outside the implementation
modules.

## Milestones

- **K0 (current):** Name, Level, core Expr subset, loose-bvar range,
  lift/instantiate/instantiateRev, single-fvar abstraction.
- K1: exact remaining Expr representation including mdata/KVMap semantics,
  literals/projections and full structural equality/update behavior.
- K2: declarations, local context, immutable environment.
- K3: universe equivalence/order and level substitution.
- K4: inference.
- K5: WHNF and delta/beta/zeta/projection reduction.
- K6: definitional equality.
- K7: declaration admission.
- K8: inductives/constructors/recursors/projections.
- K9: quotients and kernel primitive hooks.
- K10: Arena/oracle parity and PSC1-generated TypeScript/JavaScript bootstrap.

Native compiler-IR reduction remains an explicit optional provider and is not
required for the first portable kernel.

## K0 source mapping

K0 is derived directly from:

- `study/lean4-4.34.0/src/kernel/level.cpp`;
- `study/lean4-4.34.0/src/kernel/expr.cpp`;
- `study/lean4-4.34.0/src/kernel/instantiate.cpp`;
- `study/lean4-4.34.0/src/kernel/abstract.cpp`;
- the public operation contracts in `study/lean4-4.34.0/src/Lean/Expr.lean`
  and `Lean/Level.lean`.

K0 deliberately excludes `Expr.mdata` from the portable expression
representation. That is an explicit incomplete slice, not a compatibility
claim. Exact mdata/KVMap representation and equality belong to K1.
