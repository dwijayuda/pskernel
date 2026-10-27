# PSC1 minimal kernel: initial simply typed fragment

`src/Ps/MinKernel/Check.lean` checks Empty/Unit/Nat/simple-arrow terms and sequential
closed definitions. It has no unchecked constant or axiom admission. The separate
proof project at `../../proofs/pskernel-min` imports this exact source; runtime
imports never depend on proofs.

This is an initial research fragment. It does not check PSC1's dependent canonical
admission format or its complete self-hosting closure. The research host adapter
explicitly refuses canonical `min`/`dual` until that bridge is proved and qualified.
Official Lean remains the default production verifier.

Core API (flat names follow the portable source conventions):

```lean
psMinCheckEnvironment : Nat -> Nat -> List PsMinDeclaration -> Option (List PsMinTy)
psMinInfer : Nat -> List PsMinTy -> List PsMinTy -> PsMinExpr -> Option PsMinTy
```

The qualifying entry is `psMinCheckEnvironment`, which starts from an empty
environment. Low-level inference and declaration-fold functions can take supplied
contexts; calling them with arbitrary global types grants no admission authority.
The capstone theorem requires the actual successful environment-check equation;
a list or copied result field is not a transferable certificate.

Constants refer to the most recently admitted declaration at index zero. Bodies
must be closed over locals. An identity on Empty is valid; a closed Empty value is
not. Fuel exhaustion refuses. Fuel bounds recursion depth and declaration count,
not total heap/work or arbitrary generated-JS input; no byte decoder is exposed.

All builds/tests run in Linux GitHub Actions through
`.github/workflows/psc1-minkernel.yml`. It builds the actual consistency proof,
prints theorem axioms, runs native semantic/refusal vectors, compiles the same
executable source with current PSC1, checks its exact canonical source admissions
using official Lean, executes emitted vectors, and measures the complete compiler
graph. Those source compilation checks are not G1/G2/G3 qualification.

See [architecture](../../docs/PSC1_MIN_KERNEL_ARCHITECTURE.md),
[proof status](../../docs/PSC1_MIN_KERNEL_PROOF_STATUS.md),
[coverage](../../docs/PSC1_MIN_KERNEL_COVERAGE.md),
[research](../../docs/PSC1_MIN_KERNEL_RESEARCH.md), and
[continuation state](../../docs/PSC1_MIN_KERNEL_WORK_STATE.md).

The [measured runtime profile](../../docs/PSC1_MIN_KERNEL_RUNTIME_PROFILE.md)
records the qualified scope-proof/source-origin-ledger milestone at57964262,
Linux40455022116, and gives the next R1–R4 proof batches. Its diagnostic frontier
adds no canonical acceptance authority. The actual Core scope proof remains
outside the runtime import graph.
