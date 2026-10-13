# M2+A: generalized answers and shared synthetic constraints

## Contract and design

This is the next bounded M2+A milestone in M2+A → M3+B → M4+C/D → M5/E.
The implementation remains native portable Lean, checked by official RC4.
No pskernel-core, self-hosting, source-authority migration or backend redesign.

The generator/consumer graph previously published only meta-closed answers.
That prevented a generic dictionary from being specialized by a consumer's
later instance dependencies. Application elaboration also had independent
expected-type, pending-instance and immediate-default paths; progress in one
could be discarded while another remained blocked.

`Ps.Meta.Abstract` owns scoped answer templates. It orders natural term
parameters by dependencies in their types, records each captured local scope,
abstracts unresolved universe parameters, and allocates fresh parameters on
every shared replay. Template indices are private binders, not donor-context
metavariable IDs. Synthetic and opaque obligations, delayed abstractions and
scope escapes are refused. Receivers re-infer and unify the reconstructed
witness against their complete target; a key match is never evidence.

`Ps.Meta.InstanceSearch` retains generalized answers and waiting consumers,
deduplicating by canonical parameter telescope/result type. Generalized answers
precede a later closed canonical answer for existing and new subscribers.
The unique creating subscription may adopt its descendant context to preserve
assignments in local dictionary types; all other subscriptions open fresh
templates in their own snapshot. Shared keys still require a closed identical
local signature. Roots require no residual term parameters; unconstrained
universe parameters follow RC4's separate treatment and must still be resolved
or generalized by the enclosing declaration rules. Answers now have an
independent resource bound alongside goals, candidates, transitions and height.

`Ps.Meta.Synthetic` owns one deterministic scoped queue for expected-type
equalities, instance holes and omitted default values. Failed attempts discard
their speculative snapshots. Successful items are removed, so productive
rounds are bounded by queue length. Ordinary constraints reach quiescence
before defaults run, then retry after defaults unlock information. An omitted
default uses an opaque placeholder: the caller cannot assign a different
default through expected-type unification. The declared default is inferred,
checked and explicitly assigned. Resource refusal restores the initial queue
and context. Application completion requires an empty queue.

Calls, named arguments, records, expected-result lookahead and proof applications
use this mechanism. The old pending-instance worklist is removed. Proof goals
remain under the proof elaborator; this queue does not fabricate evidence or
claim full tactic/postponed-syntax scheduling.

## Reference design

Pinned Lean 4.35.0-rc4 commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`:

- [Meta/AbstractMVars.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/AbstractMVars.lean):
  dependency-aware abstraction and fresh opening.
- [Meta/SynthInstance.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean):
  generator/consumer answer propagation and root term-parameter closure.
- [Elab/SyntheticMVars.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/SyntheticMVars.lean):
  progress-based retry and default phases.

These are design references, not imported host elaborator dependencies.

## Qualification

Pending Linux build and existing full native/backend qualification at this commit.
Focused additions exercise dependent term/universe freshening, scoped refusal,
synthetic-obligation refusal, shared generic dictionaries specialized to Nat
and Bool by later subgoals, mandatory-default conflict, resource rollback,
and expected/default/instance wake-up. Three runtime observations extend the
shared target table. The independent pinned Lean oracle covers the same source
semantics. Existing cycle/diamond/growth and all prior acceptance criteria remain.

## Remaining boundaries

This closes a selected answer-template/application-queue slice, not all M2 or A.
Arbitrary postponed syntax, full tactic scheduling/metavariable-depth parity,
more general scoped answer abstraction and broader elaboration/search performance
qualification remain open. Repr/DecidableEq/Hashable and other Phase A gaps stay
on M2+A. Dependent/indexed/recursive deriving and the associated matching work
remain M3+B. C5 source provenance follows the semantic owners; no printer is
reimplemented here. No formal compiler preservation or performance parity claim.
