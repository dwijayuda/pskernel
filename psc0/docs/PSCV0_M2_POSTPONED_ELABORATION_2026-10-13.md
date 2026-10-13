# M2: scoped postponed elaboration

Postponement and lookup qualified at `083c3139f95d8ab7fd64b91ad261364eef36d1cd`,
[Linux 38423408362](https://github.com/dwijayuda/pskernel/actions/runs/38423408362).
282 runtime observations; existing kernel/backend/integration gates passed.
The OfNat extension below is in progress and is not yet qualified.

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

## Instance lookup scaling

Global instance entries are indexed once per synthesis invocation by class hash.
Unclassified entries are merged by their original registry positions. Lexical
locals still precede all globals. Generator buckets partition by rigid class
identity and scope only: syntactically different, definitionally equal inputs
must remain shareable, so arbitrary term hashes cannot exclude candidates.
Collision checks retain the existing full key and closed-local-signature tests.
The first matching generator remains authoritative.

The shared persistent bucket implementation is in Foundation.Index; it contains
no semantic equality or proof authority. Measurements cover 1/8/32 distinct-head
goals and the deliberate same-head/different-input comparison workload, alongside
existing cycle/diamond/generalized-answer and resource rollback checks.
Same-head buckets can still require quadratic comparisons; bounded work and
actual operation counts are reported instead of asserting general linearity.

## Type-directed numerals

OfNat is a checked universe-polymorphic structure class with Nat and Int
instances. A numeral with a known non-Nat expected type uses the ordinary
instance graph; its result is checked by the same term inference/conversion path.
An unknown type is postponed before Nat defaulting. No guessed value, coercion
chain or runtime cast is introduced. The selected Nat kernel literal remains
unchanged.

Intentional Standard expansion: exactly five declarations (class, constructor,
projection, Nat/Int dictionaries), one class and two instances. There is no new
axiom, primitive or alias. Update strict registry digests only after reviewing
the independently observed values from Linux qualification.
