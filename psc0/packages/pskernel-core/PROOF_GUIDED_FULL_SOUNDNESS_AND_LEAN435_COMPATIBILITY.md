# PSKernel Core — Proof-Guided Full Soundness and Lean 4.35 Compatibility

**Decision:** keep Lean 4.35 compatibility authoritative; define the *successful-acceptance implies model* theorem first, then modify the existing executable implementation only where that theorem requires maintained evidence. Preserve a single checking/admission algorithm. This is a technical execution reference, **not** a claim that full soundness or consistency has already been proved.

**Repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel). **Development branch:** `psc0/pskernel-core-lean435-arena-v1`; **draft PR:** [#89](https://github.com/dwijayuda/pskernel/pull/89). **Code:** `psc0/packages/pskernel-core`.

**Normative Lean target:** Lean **4.35.0-rc4** at exact commit
[`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364).
Never substitute a moving Lean master or a previous Lean 4.34 result for this target. If the user later chooses another version, explicitly repin the behavioral reference and independently requalify it.

**Mathematical dependency:** [Con Leche](https://github.com/leanprover/con-leche/tree/65e74db49e89ad2bbd1e90aa4f784954db41fa3a) at `65e74db49e89ad2bbd1e90aa4f784954db41fa3a`, **only** `ConLeche.SetTheory.*` and `ConLeche.SetModel.Ops`. The external checker, annotation validity and `MainTheorem` are research references; their correctness theorems **must not** become PSKernel proof premises.

## 1. Architectural ruling

Do **not** choose between (a) proving a pleasant but disconnected type calculus and (b) building a large unproved checker, or restart the project around either one.

Use *proof-guided co-design*:

1. **Specify the theorem and trusted assumptions now.** State the model, environment model, proof/definition admission scope, allowed axioms, safe/unsafe policy, universe valuations and failure/decline cases.
2. **Use the existing PSKernel-owned executable as the proof subject.** Prove results about its concrete reference-mode path, not a structurally similar paper checker. The reference mode fixes `psKernelReferenceCachePolicy` and bypasses semantic caches; it is **not** a verified mode merely because of its name.
3. **Carry execution-derived certificates in the same code path.** For every successful binder sort visit, reduction, inference result and equality success, preserve the *specific* annotated term/type, regime, environment and local frame that the actual execution selected. Raw syntactic erasure, membership in a possibly empty semantic domain, or a separately guessed annotation cannot supply this evidence.
4. **Close one joint accepting-direction recursive theorem** over the existing fuelled inference, WHNF, definitional equality and their callbacks. Do not require strong normalization, equality completeness, unrestricted subject reduction or transitivity of the algorithmic equality relation.
5. **Prove every admitted environment extension** (ordinary definitions/theorems/opaques; safe and unsafe discipline; mutual/nested inductives, generated recursors, quotients, native reductions, and the permitted logical axioms).
6. **Compose public session/receipt/dispatch contracts** and derive a scoped relative-consistency corollary. Only then prove cached/reference simulation and portability/backends as *separate* results.

A representation refactor is justified when the invariant cannot be established from the actual data carried by the operation. Preserve each operation's previous raw projection and error/decline/fuel semantics by a theorem and differential evidence. Avoid an alternate checker, a fallback on failed proof checks, or a parallel second implementation of logical rules.

## 2. The fundamental compatibility versus consistency distinction

Lean legitimately accepts `axiom impossible : False` as a **user assumption**. The kernel cannot prove unconditional nonacceptance of that input and remain compatible with Lean.

Maintain separate contracts:

- **Lean-compatible acceptance:** the official pinned kernel's rules and observable accept/reject/decline behavior are the authority. Arbitrary axioms may be admitted as assumptions where Lean allows them; they are not independently proved. Current resource bounds and unsupported features must have distinct, observable decline status.
- **Verified reference acceptance:** a *separately labeled* assurance claim can be made only when the accepted declaration's actual proof/semantic-reading steps have been certified, and every axiom it depends on has an explicit model interpretation or belongs to a proved allowed basis. A verified-only policy may decline an unmodeled axiom; that cannot silently change the normal Lean-compatible mode.
- **Relative consistency:** under explicit `[ConLeche.SetTheory V]`, a modeled initial environment and allowed modeled extensions, no *derived theorem* inhabits the model's empty `False`. A proof *relative to a strong set-theoretic assumption* respects Gödel's incompleteness theorem and is not a theorem of Lean's own unconditional consistency.
- **Unsafe/partial declarations:** spell out their exact accessibility, recursion, code-generation and semantic policy. A value that only compiles and is never a trusted proof cannot be used to establish the consistency corollary.

Do not pass an arbitrary environment/model assumption to a final public theorem without demonstrating that the real admission/initialization path establishes and preserves it.

### Proposed public mathematical shape (design target, not existing Lean declarations)

```lean
-- Names below are design placeholders, NOT proven declarations.
theorem referenceAdmissionPreservesModel
    (V : Type u) [ConLeche.SetTheory V]
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest)
    (result : PsKernelAdmissionResult)
    (initialModel : KernelEnvModel V session.environment)
    (allowed : ModeledDeclarationPolicy V session.environment request)
    (accepted :
      psKernelReferenceAdmitDeclaration session request = .ok result) :
    KernelEnvModel V result.session.environment

theorem referenceSequencePreservesModel
    (V : Type u) [ConLeche.SetTheory V]
    (initial : PsKernelKernelSession)
    (requests : List PsKernelDeclarationRequest)
    (final : PsKernelKernelSession)
    (initialModel : KernelEnvModel V initial.environment)
    (modeledStream : StreamAxiomsModeled V initial requests)
    (accepted : AdmitSequenceReference initial requests = .ok final) :
    KernelEnvModel V final.environment

theorem noFalseTheoremFromModeledStream
    (V : Type u) [ConLeche.SetTheory V] ... :
    ¬ AdmittedDerivedTheoremOfFalse final.environment
```

`AdmitSequenceReference`, `KernelEnvModel`, `ModeledDeclarationPolicy`, `StreamAxiomsModeled` and `AdmittedDerivedTheoremOfFalse` are **not implemented yet**. Their implementation must be grounded in actual `PsKernelKernelSession`, `PsKernelDeclarationRequest`, `PsKernelAdmissionResult`, `psKernelV1CheckedEnvironment` and `psKernelReferenceAdmitDeclaration`, not introduced as soundness axioms or vacuous aliases. If normal mode accepts arbitrary axioms, the modeled-stream premise is necessary; dropping it is invalid.

The end proof also needs a pinned, non-colliding meaning for `False` and reserved primitives, not just text equality of arbitrary user-defined constant names.

## 3. Source-level research and lessons

| Source | Verified/implemented technique | What PSKernel should adopt or avoid |
|---|---|---|
| [Official Lean `type_checker.cpp`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp) | `infer_lambda` checks the binder domain before extending locals, `infer_pi` derives `imax` of domain/body sort levels, and fully checked `infer_app` checks the argument type/defeq; infer-only is a separate algorithmic grade | Mirror *actual checked and infer-only branches*, their error conditions and scope/typing premises. Do not assume an arbitrary inferred type has a sort. |
| [Lean inductive checker](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/inductive.cpp) | Positivity, uniform parameters, recursor construction, elimination restrictions and mutual/nested processing have interacting invariants | Prove admission transactions and *generated* constructor/recursor model laws; flat declaration-header proofs alone are insufficient. |
| [Con Leche `MainTheorem.lean`](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean) | `checkDecls .verified` success implies `Nonempty (Model V env)` under `[SetTheory V]`, then a source-level `False` rejection corollary | Target a concrete public accepting-run implication. The parser/input bridge and full model fold are indispensable; copying the final theorem's text is not a proof. |
| [Con Leche core](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Core.lean) and [pure knot](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/TypeChecker.lean) | Core bodies parameterized over one open-recursion record, fuel in the knot, semantic claims over the pure checker | Existing PSKernel `InferOperation`/`DefEqOperation` callbacks and common core are a starting point. Refactor selectively to expose a *joint graded fuel induction*, not to create two implementations. |
| [Con Leche semantic claims](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Claims.lean) | Successful inference, WHNF and equality each preserve an execution-related interpreted *annotated* reading and well-denotedness; the mutual claims discharge together | Prefer model-only accepting direction with concrete provenance; a legacy syntactic relation whose equality/typing collapses cannot justify executable acceptance. |
| [Con Leche model fold](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Verify/Cached/MainC.lean) | Full-check environment is modeled, then `no_proof_of_False_cached` is derived | Treat admitted environments and their order/pins/capabilities as first-class proof objects. |
| [Con Leche `PropWhen`](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/PropWhen.lean) | Canonical symbolic zero-ness conditions for binder regimes; comparing their representation also compares all valuations | PSKernel's `UniverseRegime.check_spec` is mathematically relevant, but checker acceptance must *use a justified regime* on the actual structural/eta/equality path. |
| [Con Ron](https://github.com/leanprover/con-ron/tree/64a2172a01276aa049220200bac11c075316230f) | Lean twin refines pure Con Leche, then Aeneas-derived Rust semantics refines the twin (successful direction), retaining Con Leche's consistency result | Design later optimized JS/Wasm/Rust/native backends as separate, explicit refinement/TCB questions; one backend succeeding does not prove another. |
| [Lean4Lean](https://arxiv.org/abs/2403.14064) and Carneiro, *The Type Theory of Lean* | Independent executable checking and analysis of Lean's real conversion/typing subtleties | Use as conformance/negative-conformance research, not a shortcut to proof of PSKernel execution. |

The verified Con Leche source is a *different executable*. Even when it shares mathematical semantics or importable models, its `MainTheorem` cannot imply PSKernel soundness without a complete refinement proof. Also, the upstream checker makes extra verified-mode checks; any such new PSKernel gate must have explicit compatibility evidence.

## 4. Evidence already in PSKernel (no promotion by file count)

- `SemanticSetDomain.lean`: relative set tower, impredicative product and model-level contradiction type. This is **not** a public checker acceptance theorem.
- `SemanticDeclarative.lean`: soundness and relative consistency of a deliberately limited dependent-function judgement. Constants, inductive admission and actual checker execution are outside the fragment.
- `JudgmentAdequacy.lean`: proves the *legacy* operational judgement is collapsed/inadequate. Keep it quarantined from soundness.
- `SemanticUniverseRegime.lean`, `SemanticAnnotationCoherence.lean`, `SemanticCheckedReading.lean`: symbolic binder regimes and fixed annotated semantics, still with an executable-selection/provenance gap.
- `SemanticReferenceLocalContext.lean`, `SemanticReferenceBinderContext.lean`, `SemanticSortVisitProvenance.lean`: real reference free-variable result, local binder model under stated premises, and actual same-visit regime witnesses; none proves *cross-visit* or full recursive soundness.
- `SemanticLocalContextExtension.lean`, `SemanticScope.lean`: scoped numeric/local/let frame and actual binder-opening lemmas, validated at [run 38066810266](https://github.com/dwijayuda/pskernel/actions/runs/38066810266).
- **New candidate** `SemanticPublicEntry.lean`: relate actual `psKernelCheckNoMVarNoFVar` acceptance to the numeric-name bound, and `psKernelMkCheckerSession` to the empty local frame. Candidate source [`89292f66`](https://github.com/dwijayuda/pskernel/commit/89292f667c42d208884e1705a4383a72e67367d1); check exact subsequent GitHub CI before claiming validation.

These assets are useful. But `checkedRaw : PsKernelExpr` and the actual checker still drop the selected annotated reading at several recursive/acceptance boundaries. That is a **representation-level proof obstruction**; proving a bigger collection of conditional lemmas without repairing this will not close the public theorem.

## 5. Formal theorem stack, in priority order

| Gate | Execution source / proof invariant | Proof obligation and condition for closure |
|---|---|---|
| P0 — specification | This document, `KERNEL_THEORY.md`, pinned Lean C++ reference | Freeze kernel behaviors, permitted assumptions, observable errors/declines, proof mode and target API statements. No contradiction between Lean parity and model policy. |
| P1 — public input | `Admission/Declaration/Validation.lean`, `Checker/Session.lean`, `SemanticPublicEntry.lean` | Admission's actual no-fvar/no-mvar guards and generated initial state imply a valid syntactic starting frame. **Do not** generalize to arbitrary user-created `PsKernelKernelSession` holding unverified constants. |
| P2 — frame preservation | `Checker/Inference/Core.lean`, `Checker/State.lean`, `SemanticScope.lean` | One graded invariant preserved across *every* callback, inferred result, child binder/let context, fresh allocator update and parent exit, with exact original and final states. |
| P3 — fixed annotations | `Core/AnnotatedInference.lean`, `Checker/Inference/Helpers.lean`, `SemanticSortVisitProvenance.lean` | Every accepted judgment carries the **same chosen** expr/type/level/regime reading through the full data flow. No arbitrary positive tag and no vacuous-model inference. |
| P4 — joint inference/reduction/equality | `Checker/Knot.lean`, `Checker/DefEq/*`, `Checker/Reduction/*` | Complete mutual fuel induction: successful checked inference gives interpreted typing, successful WHNF preserves interpretation, true DefEq gives semantic equality with precisely justified validity premises. Validate beta, delta, zeta, eta, proof irrelevance, K-like, projections, recursor, primitive literal and quotient branches. |
| P5 — reference state/caches | `Runtime/Acceleration/SemanticCache.lean`, `SemanticReference.lean` | Cache-disabled reference does not consume/produce unverified semantic answers in any accepting recursive path. A method-level no-op lemma alone is not whole-checker independence. |
| P6 — environment model | `Environment/*`, `Admission/Declaration/*`, `Admission/Inductive/*`, `Admission/Quot/*` | Every successful complete admission transaction carries a model from its input environment to its actual output environment. Include reserved builtins, generated recursor rules, safety/mutual/recursive declarations and resource/rollback boundaries. |
| P7 — primitive and axiom policy | `Runtime/Capability/*`, `KERNEL_THEORY.md`, new explicit modeled-axiom interface | No opaque custom axiom sneaks into the theorem. Prove the model for allowed `propext`, `Classical.choice`, `Quot.sound`/other exact pinned policy; distinguish Lean-accepted external assumptions and trusted runtime native reductions. |
| P8 — full public API | `API/Session.lean`, `API/Kernel.lean`, `API/Reference.lean` | From real input initialization/preflight/dispatch/receipt/continuation, successful trusted/verified admission implies `KernelEnvModel`; then no derived theorem `: False`. Check original-statement mapping and reserved-name semantics. |
| P9 — optimized/executable refinement | `Checker/Knot`, `Runtime/Acceleration`, JS/Wasm/Rust ports | Prove every *optimized accepting run* simulates a modeled reference accepting run, or explicitly say that it is not formally certified. No runtime/backend promotion without an exact bridge. |
| P10 — compatibility exit | Official pinned Lean tests/exports, Arena, independent checkers, negative conformance | Differential classification of all supported rules. Every mismatch is understood and fixed at the root, with corrected evidence from identical source/binary/pinned test data. Full corpus resource timeouts are not successes. |

**Ordering:** P0/P1 and the theorem's assumption policy can be formalized before any refactor. P2 and P3 are coordinated representation work; prioritize **one data-preserving interface migration** over dozens of test-specific proof patches. P4 then becomes the essential kernel proof. P6 can be built in parallel from semantic environment blocks but cannot be called complete before P4. P8 is the decisive completion criterion. P9 must not be a condition that blocks proving reference soundness, but it is required for a soundness guarantee about optimized shipping binaries.

### Paired graded recursion: minimum invariant fields

Every success proposition at a particular fuel and checker context must carry (or reconstruct from exact operations, **not assume**) all of:

1. The *actual* expression and result type, annotated regime and erasure equations.
2. Input/output environment identity; exact local context/selected declarations; numeric fresh-counter bound, scoped opening/closing and monotonic scope exit.
3. Input/output semantic validity, interpreting constant/universe level valuations and allowed axioms.
4. Typed domain/body semantics for lambda, forall, let and app, including the actual sort/exposed-Π visit and proof-irrelevance/eta evidence when invoked.
5. Same-call and cross-call coherence exactly where structural equality or a cache shortcut can accept; raw equality alone is insufficient.
6. Error/fuel paths that cannot produce a successful certificate, and an explicit distinction between `inferOnly` and fully checked inference.
7. Environment snapshots for safe and unsafe declarations, and admissible native evaluation capabilities.

A strengthened return record or typed mutual callback contract may be necessary. The *one* production algorithm must choose the evidence; the theorem must not simply assume all the correct annotations already exist.

## 6. Compatibility gates: prove soundness, measure fidelity

The official 4.35 kernel source remains the compatibility authority for:

- Sorts, universe variables and `max`/`imax`, parameter instantiation and symbolic Prop/Type regimes.
- Variables, applications, dependent products, lambdas, let and local scope, infer-only versus checked grades.
- WHNF, lazy delta, beta/zeta, eta, proof irrelevance, structure eta and K-like reduction under their actual guards.
- Inductive positivity, elimination permissions, indices, mutual/nested declaration transactions, recursor computation and quotient primitives.
- Native `Nat`/`Int`/fixed-int and `String`/literals, reductions gated by the exact pinned Lean version, and runtime capability boundaries.
- Axiom, `sorryAx`, unsafe/partial, declaration freshness, transparency, resource limits, import/export provenance and trust receipts.

For each family maintain: official rule/source locator → PS owned operation → claimed semantic lemma → negative/conformance fixture → outcome from pinned native Lean and PS reference/cached mode → currently proved/runtime-covered/declined status. Avoid overclaiming “100% parity” from passing a bounded Arena fixture.

**Important:** a verified reference checker may be sound but **incomplete** relative to Lean. It must report unsupported/uncertified as a *decline* rather than silently accept without proof. Full Lean compatibility remains a distinct goal and should drive future proof-compatible certified features, not the removal of proof obligations.

## 7. Proof trust boundary and assurance rules

- Keep `[ConLeche.SetTheory V]` explicit; do not fake or globally postulate an inhabitant of the full ω-universe model. Mathematical foundations and checker soundness must have separate imports and axiom reports.
- No `sorry`, `admit`, hidden stronger hypotheses, `unsafe` axioms or external checker “model_exists” shortcut. Inspect `#print axioms`, the dependency fence, the 84 companion files and all newly introduced declarations.
- Keep `psKernelReferenceCachePolicy` fixed in the theorem's subject. No semantic fallback on failure.
- Treat arbitrary input sessions and custom axioms as **untrusted model inputs**; prove their admissibility if they are in scope. The model cannot be inferred from a Python/JavaScript wrapper's success.
- Keep separate identity of Lean reference version, original PS source, proof source, compiled binary, compiler/provider, cloud CI job, corpus snapshot and exported data. A green proof job does not qualify generated PSC0 JS/Wasm.
- Preserve failed proof variants, counterexamples and timeouts as evidence, and state which exact hypotheses remain at every checkpoint.
- No force push, history deletion, automatic merge or provider/seed promotion without explicit authorization.

## 8. Immediate next work after the public-entry candidate

1. Close `SemanticPublicEntry` in CI, including source alignment with the *actual* declaration guard. Do not weaken its theorem statement to bypass failure.
2. Prove `psKernelKernelSessionChecker` initializes the same frame from the public `PsKernelKernelSession` when the environment is already modeled; separate arbitrary constructed sessions from ones returned by `psKernelKernelSessionEmpty`.
3. Prove a *composed* one-binder step from the source's no-fvar guard through the real state allocator, domain/body source constraints and the concrete child-local/context-creation code. Preserve exact inferred-body provenance and no capture. Avoid assuming that an arbitrary recursive callback returns a sound annotated type.
4. Introduce a single, explicitly graded proof contract for the actual inference/WHNF/DefEq open-recursion callbacks. Inventory each unchecked shortcut before altering Core signatures.
5. Move one complete operation family (sort/fvar/one binder) through the new carried-result interface with an **all-input erasure/result/error-state equality theorem**, then repeat mechanically for remaining families. If the new interface cannot preserve both Lean parity and sound semantics, redesign once at the shared boundary.
6. Build the declaration-model fold and axiom basis *while* the joint theorem develops; pin negative cases `axiom bad : False`, `sorryAx`, unsafe dependencies and reserved-name spoofing.
7. After the complete accepting-direction and public theorem, separately qualify caches and backends. Only a completed proof with no unmet assumptions triggers a “consistent kernel” claim.

## 9. Exit definition

**Reference theorem complete** only when the exact public acceptance → environment-model → no-derived-False chain compiles with allowed foundational assumptions, no unchecked semantic premise, an actual modeled initial environment and an explicit permitted-axiom policy. **Full kernel metatheory complete** needs the complete rule/admission families, not merely the dependent-function fragment. **Lean compatibility established** requires the pin-specific differential/conformance matrix plus all required corpora, with declines/timeouts reported. **Shipping optimized kernel certified** additionally requires completed cached/native/JS/Wasm refinement or an explicit separate trusted-checker boundary.

Current checked ledger and tasks: [AI_WORK_STATE.md](AI_WORK_STATE.md), [REFERENCE_CORRECTNESS_PLAN.md](REFERENCE_CORRECTNESS_PLAN.md), [MIGRATION_EVIDENCE.json](MIGRATION_EVIDENCE.json), [PSKERNEL_TCB.json](PSKERNEL_TCB.json), and [draft PR #89](https://github.com/dwijayuda/pskernel/pull/89).

**Never replace the final theorem with a percentage, an AI assessment, the number of proved lemmas, a successful demo, or an attractive architecture diagram.**
