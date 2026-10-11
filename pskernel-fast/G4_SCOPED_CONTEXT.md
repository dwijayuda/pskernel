# G4.3 — Proof-carrying structural binder stack

This module introduces a **structural-only** context represented by
`ScopedFrame params depth`. Its constructors require a proof that every new
domain satisfies the *actual G3 declarative* `KExpr.StructurallyValid params
depth` judgment. Runtime extension through `AnyScopedFrame.extend` checks the
real executable `KExpr.validAt` and uses the independently compiled
`KExpr.validAt_sound` theorem to obtain the required evidence.

This is a **correctness-oriented foundation** for a fast dependent-type checker:
the chain is immutable, extensions are O(1), and the only raw lookup returns
the precise domain stored at its original depth. The new theorem
`AnyScopedFrame.extend_depth` establishes exact depth advancement on success,
while `ScopedFrame.rawDomainAt_top` shows no change to the stored top domain.

**Critical limitation:** a domain retrieved from its original binder context
is *not* a valid current-context inferred type without de Bruijn shifting,
substitution, checked sort observations, level parameter validity, and a real
typing judgment. No public checker may treat the result of `rawDomainAt` as a
verified type. No declaration or proof acceptance is implemented.

The next stage is an exact lifting/opening/closing model and a scoped
environment-backed `infer/check` engine with proper type validation, resource
classification and immutable admission. G4.0's positive-only symbolic level
normalizer remains conservative; G4.1's candidate catalog remains untrusted;
G4.2's Sort/Pi fragment is not the general inference engine.

CI state: pending implementation-source validation. No full Lean compatibility,
metatheory consistency or self-host status claimed.

## Validated G4.3 structural-binder checkpoint

Source `df800d5f390e36a0c807bd88397221adce488394` passed [CI 38110413629](https://github.com/dwijayuda/pskernel/actions/runs/38110413629): 45 native build jobs and the structural binder-scope test including three nested domains. This validates only structural scope; `rawDomainAt` is **not a type judgment**. See [G4_SCOPED_EVIDENCE.md](G4_SCOPED_EVIDENCE.md).
