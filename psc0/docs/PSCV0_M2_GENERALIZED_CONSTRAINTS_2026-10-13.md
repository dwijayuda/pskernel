# M2+A: generalized answers and shared synthetic constraints

**Subsequent qualification:** [checked equality/defaults](PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md)
at `d7e28a3870cdc399eca3c63c6d305b10109d2eca`, [Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663).
This adds selected DecidableEq, proof-field BEq, structure defaults and shared
typed proof conversion. The historical evidence below remains revision-specific;
the latest Standard has 294 declarations / 14 classes / 52 instances.

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

Global instance registration now checks parameter information flow before
adding a declaration to the ordered registry: result inputs determine
parameters, ready dictionary inputs enable their outputs, and dependencies in
parameter types close transitively. Stuck dependency orders and undetermined
result outputs are refused. This is distinct from a well-typed polymorphic
local dictionary, which may produce a generalized answer for its consumers.

## Reference design

Pinned Lean 4.35.0-rc4 commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`:

- [Meta/AbstractMVars.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/AbstractMVars.lean):
  dependency-aware abstraction and fresh opening.
- [Meta/SynthInstance.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean):
  generator/consumer answer propagation and root term-parameter closure.
- [Elab/SyntheticMVars.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Elab/SyntheticMVars.lean):
  progress-based retry and phase separation. Its default-instance phase is
  broader than this milestone's mandatory optParam-value phase.
- [Meta/Instances.lean](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/Instances.lean):
  registration-time synthesis-order and concrete-output validation.

These are design references, not imported host elaborator dependencies.

## Qualification

Qualified executable `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279`;
[Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335),
job `115343717813`, **success**.

- 182 portable / 190 native modules; profile `pscv0-v7-native-bounded/48`.
- 263 shared observations on direct JS, TypeScript, Rust and V8/Wasmtime GC
  core/components; four shared panic contracts preserved.
- Official RC4 kernel and independent source oracle; all 92 existing
  phase-specific semantic refusals, do/opacity, module and deriving boundaries.
- Generalized graph: 6 generators, 6 answers, 1 generalized answer and
  1 freshened shared answer across two independent type specializations.
- Existing widths 1/8/32: 2 generators, 3 candidate checks, 7/21/69 transitions.
- Strict IR, WAT/binary parity, WIT/Canonical ABI, repeated component calls and
  post-return; declaration consumer/maps and project integration passed.
- 591 declaration mappings / 26 generated-parent origins; still declaration
  precision. The backend architecture and all prior observations are preserved.
- Standard remains 292 declarations / 14 classes / 52 instances,
  FNV `fnv1a64:5949916575031563783`,
  SHA-256 `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

The retained M1 measurement reports 3/20 ms median indexed elaboration at
16/128 declarations, versus 1/4 ms direct-return controls, with 10 ms prelude
initialization. Generated-JS/native-Lean ratios are roughly 480–3881x for these
small runtime batches. This uncontrolled run does not establish a speedup,
regression, general search complexity bound or performance parity.
The CI artifact retains samples/checksums. Build timings were 5951 ms with
restored cache and 429 ms warm; these are not cold-build measurements.

Focused additions exercise dependent term/universe freshening, scoped refusal,
synthetic-obligation refusal, shared polymorphic local dictionaries specialized to Nat
and Bool by later subgoals, mandatory-default conflict, resource rollback after prior successful assignments,
and expected/default/instance wake-up. Global arbitrary-output instances are
refused, matching the pinned registration oracle. Three runtime observations extend the
shared target table. Runtime answer sharing uses distinct Nat output indices;
type-polymorphic local dictionaries are independently kernel-qualified and
explicitly refused at erasure because higher-rank runtime functions are outside
the current IR. `PsVerifiedIrType.function` has monomorphic parameter/result
types, and `psEraseCanonicalArguments` refuses local reified-type applications.
Supporting the type-polymorphic case therefore needs a shared IR/representation
decision, not a target-specific escape hatch.
Neither this new boundary nor any previous refusal is relaxed.
The independent pinned Lean oracle covers the same source semantics. Existing cycle/diamond/growth and all prior acceptance criteria remain.

## Remaining boundaries

This closes a selected answer-template/application-queue slice, not all M2 or A.
Arbitrary postponed syntax, full tactic scheduling/metavariable-depth parity,
more general scoped answer abstraction, higher-rank runtime dictionary values,
and broader elaboration/search performance qualification remain open. Repr/DecidableEq/Hashable and other Phase A gaps stay
on M2+A. Dependent/indexed/recursive deriving and the associated matching work
remain M3+B. C5 source provenance follows the semantic owners; no printer is
reimplemented here. No formal compiler preservation or performance parity claim.
