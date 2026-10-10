# PSKernel Core architecture for PSC0

This is the current guidance for `psc0/packages/pskernel-core`.
The user-selected semantic target is Lean **4.35.0-rc4** at
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The source authority is handwritten Lean. The portable target is
[PSC0's current bounded self-host language](../../docs/selfhost-language/CURRENT.md);
the current certified sharing layer is a Lean-native experiment.
The former PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 profiles do not
constrain this migration.

## Runtime annotation and observation ownership

Shared local declarations and contexts now have one implementation
parameterized by their expression representation. The model uses the same
lookup, shadowing and insertion operations as the raw checker. Exact erasure
and fixed stored-reading theorems connect an actual reference free-variable
visit to its stored annotated type. Binder/let context model construction
still requires the parent's model, fixed checked domain/value, freshness and
scope premises.

Actual checked-lambda and forall sort visits use a shared helper carrying the
type and level produced by inference and sort exposure. Infer-only lambda is
explicitly unchecked, with no fabricated level. Projection theorems recover
the old helper pipelines, including errors and full state; same-visit
provenance prevents conflicting universe regimes even on empty domains.

Public recursive results and admitted declarations still use raw expressions.
The local lambda visit carrier is projected at that boundary. Full annotation
transport, guarded accepting shortcuts, joint inference/WHNF/defeq soundness,
full admission and public relative consistency remain unfinished.

Canonical runtime owners:
`Core/AnnotatedExpr.lean`, `Core/UniverseRegime.lean`,
`Core/AnnotatedEquality.lean`, `Core/AnnotatedSpines.lean`,
`Core/LocalContext.lean`, `Core/AnnotatedLocalContext.lean`,
`Core/InferenceBoundary.lean`, and `Core/AnnotatedInference.lean`.
Actual sort-observation carriers/helpers belong to
`Checker/Inference/Helpers.lean` and are called by the existing
`Checker/Inference/Core.lean` recursion. These modules import no semantic model.

Same-visit selection is an intensional invariant recorded outside satisfying
valuations. `CheckedReading` and `ModelsLocalContext` remain semantic
predicates on fixed syntax and cannot replace provenance. The binder-context
constructors retain parent model, scope and freshness requirements; they are
not whole-binder checking theorems.

[Final cloud job 114243521453](https://github.com/dwijayuda/pskernel/actions/runs/38062528401/job/114243521453) at
`35cef8c29358ecac8a3e89df540e0fdce72fcbca` passed **266 build jobs**, all **84
companion-proof files**, the **298-declaration semantic axiom audit** and
all **seven native test executables**. This includes **31 annotated-syntax
cases** and **8 sort-visit cases** (1 unchecked, 2 observed, 5 failure cases).
The 152-module model closure contains exactly 12 allowed Con Leche
pure-math modules, zero legacy-judgment imports and zero production-assurance
imports. The reference-policy audit checked 1,840 definitions with zero
cached fallbacks. The complete focused workflow passed; standalone binary,
Arena and fresh-export jobs were skipped. These checks validate the stated
local results and dependencies, not the open public-acceptance theorem.

See [the work state](AI_WORK_STATE.md) for exact remaining ownership and proof
entry points, and [evidence](MIGRATION_EVIDENCE.json) for failed attempts and
source-qualified native/corpus results.

## Correctness architecture

The legacy operational judgment is inadequate as a semantic target:
`JudgmentAdequacy.lean` proves arbitrary equality and arbitrary typing in it.
Do not equate the existing checker-configuration proofs with kernel soundness.
The repair must retain actual inference connections and valid-input premises,
introduce a justified typed or semantic target, and prove model preservation
for complete admission transactions. Axiom interpretations and safe/unsafe
accessibility belong in the model theorem's explicit scope.

The specified Lean 4.35 string equality decision closes the positive StringEq
law without a custom axiom. Its native runtime override remains in the Lean
execution TCB; generated PSC0 qualification remains open. Performance work
must preserve the specified behavior and cannot substitute for these proofs.
See `RESEARCH_AND_MIGRATION.md` for exact upstream comparisons and obligations.

The runtime Core annotated expression representation preserves every production
constructor and carries binder codomain-sort annotations. Set interpretation,
scoped substitution, exact production erasure correspondence, dependent-context
rules and a declarative dependent-function fragment are proved independently
of the legacy judgment. Annotation validity and the full checker/admission
correspondence remain mandatory obligations.

The pinned Con Leche dependency supplies only mathematical set constructions.
Its checker and soundness theorem are not used as a PSKernel fallback.
`scripts/check-model-dependencies.mjs` enforces the import and revision boundary;
`SemanticAudit.lean` audits proof dependencies. Relative set-theory assumptions
must remain explicit even when the global axiom audit passes.

## Source and semantic authority

Keep one production semantic implementation rooted at `Ps.KernelCore.SelfHost`.
Core owns expressions, levels, declarations and substitution; Environment owns
semantic declarations and derived lookup structures; Checker owns inference,
reduction, recursors and definitional equality with one recursive wiring owner
in Checker/Knot; Admission owns declaration transactions; API owns
KernelContract-v1. Runtime/Acceleration may preserve an existing judgment but
must not create a semantic fact.

Host transport, reference kernels, tests and metatheory stay outside the
production closure. Import fences and ownership are recorded in
`PSKERNEL_ARCHITECTURE.json`. GitHub remains canonical; follow
`GITHUB_FIRST_WORKFLOW.md` and the user's cloud-only execution instruction.

## Current profile and preservation requirements

Use the qualified PSC0 frontend's actual finite capabilities. Structural workers
may carry changing arguments around their decreasing Nat/List argument. Explicit
types, flat matches, immutable records and Except/Option remain appropriate.
General do notation, computed fields, host pointer operations and arbitrary Std
collections are not made portable by using a newer Lean compiler.

The migrated source has not yet earned joint generated compiler/kernel
qualification. Preserve the selected PSC0 compiler seed and existing provider
selection until their separate exact-source qualification and explicit selection.
This package has its own Lake toolchain so that 4.35 kernel work does not silently
repin the 4.34 compiler recovery path.

## Trust and compatibility

Fail closed on invalid input, unsupported cases, exhaustion and internal errors.
Never substitute an alternate checker after failure. Hash equality is not term
equality. Cache validity must include local context, environment and checking
mode; the definitional-equality cache must not infer transitivity from pair tests.

Lean 4.35 removes compiler-backed Lean.reduceBool/Lean.reduceNat reduction.
`psKernelReduceNative` is therefore inert regardless of legacy evaluator fields.
The historical helper is retained for source compatibility and proof history,
not as an active 4.35 capability. `PSKERNEL_TCB.json` records this distinction.

The frozen reference and LEAN_4_34 inventories are historical comparison material.
They do not override the 4.35 target. The target delta and exact upstream source
identities are in `RESEARCH_AND_MIGRATION.md`. No end-to-end consistency theorem
is claimed while the final semantic refinement obligations remain open.

## Evidence and next stage

Require the entire metatheory suite, all 84 companion proofs, foundation tests and
evaluation-order regressions for coherent kernel changes. Report complete Arena
coverage and verdicts, including declines and timeouts. Historical exports use an
explicit adapter mode; fresh 4.35 exports use exact version and commit checks.
An accepted prefix does not certify Init, Std or Mathlib.

The migration includes target-compatibility, dispatch and certified-sharing
repairs. The current correctness stage connects exact stored readings and
actual sort observations to the owned model. Its next small proof obligation
is a maintained syntactic local-frame invariant; the wider integration must
transport selected readings through the shared recursive checker and admission.
Portable stored variable summaries, graph lifetimes and generated execution
remain separate work. Their representation and erasure invariants must
accompany implementation. Generated JavaScript must never be patched to change
kernel semantics.

## Sharing execution experiment

This native architectural checkpoint has been implemented and proof-checked. The native candidate uses one certified
cursor-aware syntax fold for node counts, variable queries, lifting, term and
universe substitution, and free-variable abstraction. Every memo entry carries
an equality to the pure fold. Address/cursor keys select candidates only; a hit
checks the actual node and cursor. A memo belongs to one fixed operation and its
parameters. No semantic checker, admission rule, cache transitivity rule or
timeout changes in this experiment. Exact syntactic pair equality is memoized
separately, with a proved reflexive pointer shortcut.

Core/Expr/Basic retains the pure expression definitions. Core/Expr/Shared and
Core/SharedMemo contain safe Lean proofs and compiler-simplification equalities,
so native calls execute the proved traversal. This uses Lean's existing
withPtrAddr/withPtrEqDecEq contracts, Squash, operation-local Std.HashMap scratch
and persistent Lean.PersistentHashMap checkpoints. It introduces no
project-defined unsafe code or unchecked cast.

Expression maps and pair sets retain certified hash metadata in a logically
unobservable field. Full-operation equations preserve their results and misses;
hashes still do not prove syntactic or definitional equality. Scope exit restores the whole parent cache, including metadata. Although
cross-scope hash retention has a full state-equality theorem, its compiler rewrite
is disabled after the experiment exposed excessive retained memory. Substitution
arguments carry a proved closed-lifting path prepared once per operation.

This is **native-only experimental support**, not evidence that the current
PSC0 bounded frontend/backend supports those primitives. Joint generated
qualification remains false. The portable pure definitions are still the
semantic specification; promoting this execution layer to generated PSC0
requires explicit runtime support and preservation/qualification evidence.
The explicit portable graph/storage design in the research report remains the
alternative if that extension cannot be qualified. Neither path may silently
replace the default provider.

The scalar cache-eligibility worker also has an all-input decode theorem and
complete function equations; the policy's 256-node bound remains unchanged.
[Run 38001623085](https://github.com/dwijayuda/pskernel/actions/runs/38001623085)
at `e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4` verifies the metatheory,
all 84 companion files and native constructor/cursor/DAG tests. Full conformance
and generated PSC0 qualification are separate requirements; see the exact
receipt, including failed performance experiments, in `MIGRATION_EVIDENCE.json`.
