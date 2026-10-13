# M1 checked natural-order closure — 13 October 2026

Qualified executable 064baf31641ff19785feae1416eb353b38737794,
green Linux run 38379674588. This milestone does not claim M1 completion.

## Invariant and dependency order

Every validity proof is a Core term admitted by the official Lean RC4 kernel.
The Nat.le relation uses its real indexed inductive recursor and eliminates
only into Prop. No relation axiom or Bool-to-proof cast is introduced.

StandardNatOrder separates:
- checked structural order proofs, including transitivity, predecessor
  monotonicity, successor inversion and impossible zero upper bounds;
- a checked structural definition replacing the opaque Nat.ble logical model;
- a checked reflection theorem Bool.Reflects (Nat.ble n m) (Nat.le n m);
- Decidable dictionaries whose only computational field is Nat.ble.

The existing reviewed Nat.ble backend primitive remains the runtime
implementation. Proof reflection is erased. This is an explicit primitive
implementation boundary, not a formal compiler equivalence theorem.
The primitive signature audit should lose Nat.ble from its axiom roster.

The next dependencies are universe-aware Option/GetElem? closure, collection
workers with genuinely dependent bounds, checked optimized List optional laws,
Array representation/primitive-contract review, and Fin dictionary adapters.
Full M2 waiter tabling remains outside M1.

## Qualification

The existing kernel, fingerprint, strict IR and multi-target gates are retained.
Focused source tests cover positive and negative reflection, symbolic bounds,
inversion, contradiction and composition. An independent Init oracle checks
the corresponding RC4 declarations. Eight shared runtime observations include
arbitrary-precision bounds; the previous 198 are retained.

A changed registry digest is expected and must be extracted from Linux CI,
reviewed, then pinned explicitly. No automatically accepted candidate digest.
Record the qualified SHA and run in the work-state documents after success.

## References

Pinned upstream Init/Prelude.lean:
https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Prelude.lean
Pinned upstream Init/GetElem.lean:
https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean
