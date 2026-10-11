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

G4.3 has now also implemented exact binder-aware lifting, scope-certified current-context lookup and substitution with a checked-scope **structural** entry point. See [the source-matched G4.3 continuation evidence](G4_BINDER_EVIDENCE.md), validated at [run 38115032789](https://github.com/dwijayuda/pskernel/actions/runs/38115032789). G4.0's symbolic-level normalizer remains incomplete, G4.1's candidate catalog remains untrusted, and G4.2's Sort/Pi fragment is not a dependent inference engine.

**Remaining hard boundary:** prove typed local-context formation, checked type lookup, WHNF and DefEq for actual Lean 4.35 expression rules, with a sealed checked environment; structural certificates must NEVER authorize theorem acceptance. No complete compatibility, model consistency or self-host status is claimed.

## Validated G4.3 structural-binder checkpoint

Source `df800d5f390e36a0c807bd88397221adce488394` passed [CI 38110413629](https://github.com/dwijayuda/pskernel/actions/runs/38110413629): 45 native build jobs and the structural binder-scope test including three nested domains. This validates only structural scope; `rawDomainAt` is **not a type judgment**. See [G4_SCOPED_EVIDENCE.md](G4_SCOPED_EVIDENCE.md).
