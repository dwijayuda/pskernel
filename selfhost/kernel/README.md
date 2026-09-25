# PSC1 Lean-authored Lean 4.34 kernel

This workspace is the source-first rewrite of the Lean 4.34 trusted kernel in a
bounded Lean style intended to become PSC1-compilable.

Semantic reference order:

1. pinned original Lean 4.34 kernel sources under `study/lean4-4.34.0/src/kernel`;
2. public Lean 4.34 kernel-facing APIs used as executable differential oracles;
3. the existing TypeScript pskernel only as an additional JS differential
   implementation.

The TypeScript implementation is **not** the specification for this workspace.

Current target:

```text
PSC1Kernel/*.lean
  -- Lean 4.34 today --> checked source + direct original-kernel parity tests
  -- PSC1 later      --> checked core -> compiler IR -> TypeScript -> JavaScript
```

Do not wait for the self-hosted compiler to author the kernel. Keep source
within the intended PSC1 implementation subset where practical, and record
compiler gaps separately rather than changing kernel semantics.

## Milestones

- K0: universe levels and original-kernel parity.
- K1: expression representation, loose-bvar analysis, structural operations.
- K2: lifting / instantiation / abstraction.
- K3: local contexts and declarations.
- K4: inference and WHNF.
- K5: definitional equality.
- K6: environment admission.
- K7: inductives / recursors / projections.
- K8: quotients and final primitive boundaries.
- K9: full differential acceptance matrix and generated TypeScript/JavaScript
  bootstrap when PSC1 can compile the frozen source.

Pointer identity, hash caches, WeakMaps, mutation, and JS object freezing are
implementation optimizations, not semantic fields of this source kernel.
