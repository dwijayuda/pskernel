# Native recursor preparation

## Architectural decision

The v7 reference selects dependent matching and primitive-recursive computations.
The current runtime recursion optimization can reuse a declaration only when the
recursor's varying locals do not occur in its minors. Captured explicit folds and
nested recursors violate that invariant. Refusing them is safe but incomplete.

Normalize those computations in portable Core before canonical admission.
Create a helper with dependency-ordered captures followed by fresh family indices
and a fresh major. Keep captured values separate from these varying parameters.
The helper body remains an ordinary recursor application, so existing runtime
lowering can use the helper's recursion equation. No new Core constructor,
recursive IR node, backend-specific recursion or host elaborator service is needed.

## Invariants

- Every new declaration enters the same prepared graph that official Lean checks
  and the host retains through emission.
- Substituting the helper's actual arguments reconstructs the original recursor
  prefix modulo alpha equivalence; lifting cannot change its motive or minors.
- Capture closure includes dependencies in types and preserves declaration order.
  Let values are passed as existing values, not recomputed inside recursive calls.
- Fresh index/major locals cannot alias captured originals.
- Keep safe whole-definition recursion direct. Do not lift unused recursive
  hypotheses or proof/type computations. Traverse application operands using
  the callee telescope, skipping erased domains before visiting their values.
  Ps.Meta.TypeView is shared with erasure; it recovers existing annotations and
  never acts as a substitute for official admission.
- Nested helpers precede users, names are inaccessible and collision checked,
  and traversal/resource exhaustion refuses preparation.
- Direct single-family recursors are the supported contract. Mutual and nested
  recursive-field representations require their own existing admission/runtime
  support, never guessed recursive calls.
- The original source declarations and published grammar remain unchanged.
  Generated helpers are implementation declarations, not source functions.

## Alternatives considered

Extending IR with local recursive bindings would require every backend and IR
consumer to implement closure/recursion semantics. Duplicating recursor lowering
inside TypeScript would violate backend neutrality. Reusing the enclosing function
despite captures would change semantics. Checked Core lifting reuses the current
admission boundary and root-recursion machinery.

## References

- Canonical v7 reference, sections 4 and 5: ../PSCV0_LANGUAGE_REFERENCE.md.
- Lean RC4 closure dependency ordering:
  https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/Closure.lean
- Lean RC4 lambda lifting:
  https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/LambdaLifting.lean

Qualification and measured scope are recorded in ../AI_WORK_STATE.md.
