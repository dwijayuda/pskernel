# T05 private elimination policy draft — 2026-10-25

This draft follows the private constructor phase at `a49d64ae494d51fdc80b688dab0922dd96403e5e`. Its matching full qualification run is [40137117745](https://github.com/dwijayuda/pskernel/actions/runs/40137117745), attempt 1; the native gate has passed 310 reports, while the full generated routes and actual artifact audit remain pending at this draft's creation. The qualified integration remains `042d3a12d902f821c7b0ad8630c18f9d6d8bf639`.

## Scope

`API/DagOrdinaryElimination.lean` uses the previously qualified header, parameter, annotation and canonical structural equality helpers. It reopens the original constructor parameters, then preserves the frozen V1 elimination helper's WHNF, Check, mandatory EnsureSort, annotation consumption, fresh-local allocation and substitution order. Each telescope successor supplies the predecessor fuel to its callbacks and recursion. Non-Prop fields must occur as complete result application arguments under structural expression equality. The policy uses IsNotZero for its universe fast path and NormalizesToZero for field classification.

The result is a private Bool. Elimination-local caches, freshness and appended nodes do not become the later recursor checker owner. The caller must have established a valid canonical owner and checked original constructors. No statement here certifies arbitrary externally constructed arenas or owners.

The frozen V1 reference is `Admission/Inductive/Common/Elimination.lean`, Git blob `7b896a50da30370d3a185b79f9ffeeaa379bbb9b`, identical at the qualified prerequisite and the current constructor source. The pinned Lean comparison source is [kernel/inductive.cpp](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/inductive.cpp).

## Qualification pending

This production draft has not yet been compiled. Add the native component proofs, frozen-reference runtime matrix and corresponding generated harness, then run the isolated native-first diagnostic before promotion. That diagnostic is preflight evidence only; the changed source must pass the complete expanded source-bound qualification before integration.

Generated recursor validation and atomic publication wait for the prerequisite constructor phase's complete qualification. Public admission and fallback are unchanged. Full T05 remains incomplete; A is scoped qualified, B and D remain OPEN, and C remains FAIL at the historical strict-compatibility checkpoint.
