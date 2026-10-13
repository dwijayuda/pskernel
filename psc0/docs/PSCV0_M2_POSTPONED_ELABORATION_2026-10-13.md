# M2: scoped postponed elaboration

Implementation in progress; no qualification claim yet.

The missing capability is a common scheduling boundary: an early argument,
projection or tactic may require information supplied by a later argument.
Eagerly completing each inner application loses that opportunity.

The Meta synthetic worklist is now payload-polymorphic, preserving its original
transactional budget, deterministic order, progress detection and default phase.
Elaboration owns a mixed queue of checked Core constraints and saved source jobs.
Saved jobs contain lexical environment, local variables, instance registry,
structural-recursion authority and universe names; they use the current checked
metavariable assignments on resumption. Opaque result holes cannot be guessed by
unification. Scope exit retains work and fresh local identities; ordinary delayed
abstraction closes captured locals only when their actual assignments are known.

Only inference-dependent failures are postponable. Unknown names, invalid syntax,
resource errors and structural recursion refusals stay immediate. Numerals with
unknown expected types wait for ordinary constraints before their Nat fallback.
Tactic goals must be fixed before execution. Failed retries commit no state.
Declaration-facing term elaboration drains the same queue and refuses blocked
work with the responsible elaborator diagnostic. No pending syntax reaches Core,
kernel checking, erasure or a backend.

Pinned reference: Lean RC4
[SyntheticMVars.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/SyntheticMVars.lean).
Portable code retains PSCV0's closed language and no-sorry policy.

One combined fixture covers later-inferred records, a captured lambda projection,
a delayed tactic, expected Int numerals, Nat fallback and named arguments.
Negative cases retain invalid field/proof refusal. Existing scope, synthetic
rollback, kernel and backend integration checks remain required.
