# PSC1 Lean kernel

This directory is a new source-oriented implementation of the ProofScript kernel.

## Semantic authority

The target is **final Lean 4.34.0 kernel behavior**, especially:

- `study/lean4-4.34.0/src/kernel/level.cpp`
- `expr.cpp`
- `instantiate.cpp`
- `abstract.cpp`
- `type_checker.cpp`
- `environment.cpp`
- `declaration.cpp`
- `inductive.cpp`
- `quot.cpp`

The mature TypeScript kernel is an independent differential oracle, not the
specification for this source tree. Lean4Lean is an implementation/proof
reference only; final Lean 4.34 behavior wins on any disagreement.

## Bootstrap model

These files are authored now in bounded Lean intended for PSC1 and are checked
by real Lean 4.34 immediately. We do not wait for the PSC1 compiler to finish.

The intended later executable path is:

```text
PSC1Kernel/*.lean
  -> PSC1
  -> checked core / verified IR
  -> TypeScript
  -> pinned tsc
  -> JavaScript
```

The source therefore avoids tactics, arbitrary macros, unsafe pointer identity,
environment extensions and Lean metaprogramming. Runtime caches and JS-specific
optimizations are not part of kernel semantics.

## Equivalence criterion

We target observable kernel behavior, not generated-TypeScript text identity.

For supported declaration streams, the eventual acceptance criterion is:

```text
Lean 4.34 accepts  <=> PSC1Kernel accepts
Lean 4.34 rejects  <=> PSC1Kernel rejects
```

The first oracle directly compares Level equivalence/order and Expr
lift/instantiation against final Lean 4.34.

## Milestones

- K0: Name, Level, Expr, substitution/lifting/abstraction.
- K1: declarations, local context and immutable environment.
- K2: WHNF and type inference. **SEMANTIC BASELINE COMPLETE** — separate Lean-faithful `whnfCore` and full `whnf`, independent `cheap_rec`/`cheap_proj` controls, Lean-4.34 Nat literal normalization (`succ`, add/sub/mul/pow/gcd/mod/div/beq/ble/land/lor/xor/shiftLeft/shiftRight`), exact UINT32 count rejection for `pow`/nonzero `shiftLeft`, exact UINT32 projection-index rejection, scoped `eagerReduce`, constructor projection reduction, ordinary/Nat-literal recursor reduction, quotient lift/ind reduction, string-literal projection/recursor expansion, a fail-closed native evaluator callback boundary, and Lean-4.34-faithful projection typing are implemented. The final Lean 4.34 `LEAN_NAT_MAX_SIZE` policy is modeled as explicit portable `maxNatSize` host configuration with the same 128 MiB default; literal admission and computed Nat results are regression-tested at overridden limits.
- K3: definitional equality and exact reduction ordering. **IN PROGRESS** — sort/constant-universe/app cases, opened-binder lambda/forall defeq, proof irrelevance, Nat-offset comparison, function eta, non-recursive structure eta, unit-like equality, scoped eager-reduction behavior, the Lean-4.34 lazy-delta one-step state machine (including projection-headed unfolding and the same-definition regular-hint shortcut), projection lazy-delta field comparison, native-reduction ordering, the special `String` literal ↔ `String.ofList` expansion, and the `is_def_eq_core` recursion-depth boundary are implemented. A direct regression rejects any arbitrary 512-step lazy-delta fuel cap. Lean-style checker-state success/failure pair-cache parity remains the principal K3 maturity gap.
- K4: quotient and recursor reduction. **FOUNDATIONAL SLICE COMPLETE** — checked Lean-4.34-style Quot admission validates the Eq/Eq.refl bootstrap shape, rejects primitive-name collisions, installs all four Quot constants, and is differential-tested against Lean 4.34; quotient lift/ind reduction is wired into WHNF.
- K5: inductive/nested-inductive admission and generated metadata validation. **IN PROGRESS** — checked ordinary admission covers empty datatypes, exact universe-polymorphic recursor naming, shared parameters, per-type indices, constructor fields, direct and functional strictly-positive recursion, recursive hypotheses/calls, Prop/small-elimination selection, K-target metadata and K-like proof reduction, and ordinary mutual declarations with multiple motives/minors and cross-recursive reduction. Nested preprocessing/restoration covers shared-parameter and universe-polymorphic nested families and now also nested occurrences through ordinary outer mutual families; restored metadata/rules are rechecked before publication. Malformed/non-strictly-positive shapes remain fail-closed while broader valid Lean-4.34 nested combinations are still being audited before K5 closure.
- K6: optional/fail-closed native-reduction boundary. **FOUNDATIONAL SLICE COMPLETE** — `NativeEvaluator` exposes only optional Bool/Nat callbacks; absent/unsupported results stay opaque, and the oracle verifies both successful callbacks and fail-closed behavior.
- K7: lean4export replay protocol. **FOUNDATIONAL SLICE COMPLETE** — typed replay covers pinned metadata identity, dense/sequential Name/Level/Expr intern tables, axioms/theorems/opaque/definitions, safe and diagnostic mutual-definition reconstruction, Quot regeneration, and simple/mutual/nested inductive regeneration. The Lean-authored NDJSON boundary rejects duplicate JSON keys and ambiguous record kinds, retains exported constructor/inductive/recursor metadata, and verifies regenerated metadata/rules against the Lean export. CI generates a live pinned-Lean-4.34 stream and replays it through PSC1Kernel, and now also replays the canonical Lean 4.34 `Init.Prelude` fixture end-to-end. Corpus broadening moves to K8.
- K8: direct/adversarial/Arena/bounded-corpus acceptance matrix. **BOUNDED SEMANTIC BASELINE COMPLETE** — the Lean-authored lane is green on canonical `Init.Prelude`, primitive closure, ProofScript text/self-host deltas, Std SAT/CNF, Std Parsec, Std ByteSlice, Lean RBMap, Lean PersistentArray, and Lean PersistentHashMap. Direct Lean-4.34 regressions now lock the two concrete soundness bugs previously exposed by the external Arena sweep (projected-structure validation and sparse/out-of-order export IDs), plus Quot name collision, duplicate mutual-definition names, normalized-`imax` Prop projection/elimination, reserved `_nested` rejection, and deterministic kernel recursion-depth limits with Lean's exact 16× multiplier. The external `round-2026-09` Arena corpus targets Lean 4.29.1, so it is not replayed under the branch's strict 4.34 identity; broader 4.34 adversarial/resource coverage remains.
- K9: compile the unchanged Lean source through PSC1 to TypeScript/JavaScript.
- K10: generate canonical `.ps` and require checked-core/IR parity.


### K5 ordinary-inductive checkpoint

The Lean-authored admission path no longer trusts exported constructor or
recursor metadata. It checks declaration headers and constructor types, opens
shared parameters and per-type indices, validates uniform constructor-result
applications, generates constructors/recursors/rules itself, applies Lean
4.34's strict `infer_implicit(rec_ty, true)` pass, and type-checks generated
recursor types and computation rules before installation.

The single-type path supports direct recursive fields and functional recursive
fields whose function domains are non-recursive, including Lean's
`isReflexive` metadata and generated functional induction hypotheses. Prop
elimination follows Lean 4.34's empty/singleton/multi-constructor rules, and
K-target recursors perform conservative K-like reduction on typed local or
constant proofs.

`MutualInductive.lean` adds a separate ordinary-mutual layer so the stable
single-type path does not need to be rewritten. It shares parameters, tracks
per-type indices, generates one motive per datatype plus one global minor
telescope, supports direct/functional cross-recursion, and emits one recursor
per target datatype. A differential Even/Odd oracle verifies metadata and
actual cross-recursive reduction against Lean 4.34.

Nested-inductive preprocessing/restoration remains a separate layer. The
bounded implementation now restores monomorphic and shared-parameter nested
families and rechecks restored artifacts before publication. Nested occurrences
through an outer mutual family, plus broader adversarial nested combinations,
remain fail-closed; negative and otherwise unsupported recursive occurrences
remain rejected.

### K7 replay checkpoint

`Replay.lean` is the typed protocol/state-machine layer; `ReplayJson.lean`
is a separate fail-closed NDJSON boundary. Metadata must be the first record and
must identify final Lean 4.34.0 plus the pinned git hash and format 3.1.0.
Intern tables follow the canonical lean4export sequential/dense discipline and
reject invalid references or duplicate IDs; end-of-stream rejects incomplete
diagnostic mutual groups.

For inductive records, replay no longer treats regeneration success as enough.
Real decoded streams retain Lean's exported inductive, constructor, recursor,
and computation-rule metadata. After PSC1Kernel regenerates the group, replay
compares universe parameters, types using Lean-style expression equivalence,
ownership/index/field counts, all-lists, nested/recursive/reflexive flags,
recursor arities/K/safety, and every rule constructor/field-count/RHS.

The CI gate also exercises the real producer-consumer boundary: pinned Lean
4.34 compiles `ReplayProbe.lean`, `MiniExport.lean` emits NDJSON, and the
Lean-authored PSC1 kernel replays that exact output. The live mini stream covers
`MiniNat`, polymorphic recursive `MiniList`, and parameterized indexed
`MiniVec` plus ordinary declarations. A second mandatory gate replays the
canonical Lean 4.34 `Init.Prelude` fixture and is green end-to-end. The next
closure layer is K8: direct/adversarial/Arena and broader bounded corpus
acceptance rather than more replay-protocol plumbing.

### K8 acceptance checkpoint

K8 deliberately keeps corpus breadth and adversarial soundness separate.  The
bounded replay ladder now covers every checked-in 4.34 corpus used by the
mature kernel lane, including the heavy ByteSlice/RBMap/PersistentArray jobs in
isolated CI matrix entries.  This is evidence of substantial real-library
coverage, not a claim of exhaustive Std/Lean replay.

The Lean-authored direct oracle also carries 4.34-specific soundness
regressions instead of importing an older Arena artifact under the wrong Lean
identity.  It rejects malformed structure projections, duplicate mutual names,
reserved nested auxiliaries, and data projection from proposition-valued
`Sort (imax 1 0)` structures, while replay intern tables accept valid
out-of-order IDs without allowing duplicates.  Quot primitive collisions were
already locked by K4 admission tests.

Kernel recursion depth is now modeled at the same two entry points as final
Lean 4.34 (`infer_type_core` and `whnf_core`).  A user-facing
`maxRecDepth = 0` remains unlimited; nonzero limits use Lean's kernel factor of
16, and a direct differential definition-admission oracle requires both the
small-limit rejection and larger-limit acceptance to agree with
`Lean.Kernel.Environment.addDeclCore`.

The bounded K8 semantic baseline is now closed and recorded in
`K8_ACCEPTANCE.md`. Final Lean 4.34 installs cumulative heartbeat accounting,
cancellation-token transport, native stack checks, and process-memory checks at
the host/runtime boundary around declaration checking; those operational
controls are therefore documented as host policy rather than copied into the
pure semantic checker. Deterministic `maxRecDepth` behavior remains modeled and
differential-tested in PSC1Kernel. The current upstream Arena release is not
used as direct evidence here because its tests are generated against Lean
4.29.1, not the pinned final 4.34.0 kernel.

### K2 resource-limit checkpoint

Final Lean 4.34 initializes its process-wide Nat numeral limit from
`LEAN_NAT_MAX_SIZE`, falling back to 128 MiB when the variable is absent or
malformed. PSC1Kernel keeps the semantic checker pure by representing the same
limit explicitly as `CheckerContext.maxNatSize`; host code may inject the
configured value when constructing a checker or admitting a declaration.

The limit is applied to source Nat literals and to the same computed reduction
paths guarded by final Lean 4.34. The direct oracle verifies that an 8-byte
limit rejects a 16-byte literal/result while a 16-byte limit accepts both.
The default remains 128 MiB. This separates portable kernel policy from
process-environment lookup without weakening the kernel limit.

### WHNF architecture checkpoint

The Lean-authored kernel now preserves the final Lean 4.34 distinction between
`whnfCore` and full `whnf`. `whnfCore` does not delta-unfold definitions
or run Nat/native normalization extensions. Full `whnf` repeatedly performs
core reduction, then the optional fail-closed native normalization callback,
then Nat reduction, then delta unfolding.

This separation is required for source-faithful lazy-delta definitional
equality. The source also keeps Lean 4.34's `cheap_rec` and `cheap_proj`
controls independent: initial defeq uses `(false, true)`, lazy-delta unfolding
uses `(false, true)`, and full core WHNF uses `(false, false)`.
