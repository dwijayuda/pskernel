# PSKernel Core proof work state

Snapshot: 2026-10-10 UTC. Read the live branch before continuing; this document
is a handoff, not a claim that the full proof is finished.

## Objective and authority

Continue toward successful-checking soundness, full-kernel metatheory and an
end-to-end relative model/consistency theorem for PSKernel Core. Correctness has
priority over performance. Repair discovered bugs or architecture when required.
Do not substitute test passing, fragment consistency or conditional helper lemmas
for a full public-acceptance theorem. Strong normalization, termination of all
equality runs and equality completeness are distinct, larger targets.

The user authorized autonomous work, architectural fixes and cloud validation,
with checkpoints before architecture changes. The user requested this work
state and a reusable prompt for continuation in a new regular chat. Keep both
documents current after subsequent validated stages.

## Repository and hard constraints

- Repository: https://github.com/dwijayuda/pskernel
- Active branch: `psc0/pskernel-core-lean435-arena-v1`.
- Active package: `psc0/packages/pskernel-core`.
- Draft PR: https://github.com/dwijayuda/pskernel/pull/89 (already attached).
- Target selected by the user: Lean **4.35.0-rc4**, exact commit
  `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- GitHub/cloud only. Do not clone, read/write a local working tree, use a local
  shell, or run local builds/tests. Use remote repository APIs and GitHub Actions.
- Read the live branch before work and immediately before every ref update.
  Use the observed head as `expected_sha`; inspect concurrent changes rather
  than overwriting them. Keep updates fast-forward.
- Keep the PR draft. Do not merge, promote a default provider, change PSC0's
  selected compiler seed, or repin its separate compiler-recovery toolchain.
- No new custom axioms, `sorry`, hidden stronger foundation, fallback checker,
  or falsified validation evidence. Preserve failures and declines.
- No new chat/thread, recurring automation, goal or subagent has been requested.
- Read applicable AGENTS files, package `GITHUB_FIRST_WORKFLOW.md`, and
  `psc0/docs/selfhost-language/CURRENT.md` before substantive work.
  Root/PSC0/package AGENTS were absent at the preceding inspection.
- The current PSC0 authoring profile is broader than the old PSC1 profiles.
  This kernel remains Lean-native experimental; generated PSC0 qualification
  has not been established. Explicit local types on match-valued expressions
  remain important.

## Exact resume point

Latest fully validated source/audit trigger:
`9cf6d802ea9bc33fabd220abfb38b3fe432495ba`.
Documentation-only commits may follow it; read the live branch and comparison.

[Proof job 114228540945](https://github.com/dwijayuda/pskernel/actions/runs/38057387016/job/114228540945) at
`9cf6d802ea9bc33fabd220abfb38b3fe432495ba` passed **254 build jobs**, all **84 companion files**,
the **242-declaration** semantic axiom audit and **12 native annotated-syntax cases**.
The 140-module dependency closure contains exactly 12 allowed Con Leche
pure-math modules, zero legacy-judgment imports and zero production-assurance
imports. The reference-policy audit checked 1,824 definitions with zero cached
fallbacks. The complete workflow passed.

[Raw-binary identity job 114227668195](https://github.com/dwijayuda/pskernel/actions/runs/38057087757/job/114227668195)
at `ec410d5ff6614c815ba8d640f148cbeb133e2dc6` rebuilt the raw Arena
checker in 218 jobs and matched the runtime-tested `e600c3ac` binary exactly:
`dc710ab555596a973a1bb301e52da1f5adf414ade63aeb691ba2cb6717016ce6`.
Only a proof file and the workflow changed between that identity source and
the green source above; runtime/host source did not change. The identity run's
proof job failed before the final proof repair; its binary job passed.
Native regressions, Arena and fresh exports were not rerun in this stage.
Their earlier source-specific receipts, including the reference Int64 timeout,
remain below. Binary identity does not establish generated PSC0 qualification.

The completed stage moved 17 unchanged executable definitions from metatheory
into runtime Core, proved guarded structural coherence/transport and hereditary
validity transport, and strengthened `application_trace_checked_reading`.
The public checker and admission remain raw-expression based. Full-kernel
metatheory and consistency remain unfinished.

Three earlier attempts failed before this green source: missing the existing
name-equality import (run 38056276397), non-progressing simplification
(run 38056606291), and an equal-index substitution branch needing
`Nat.lt_irrefl` (run 38057087757). All were repaired; retain them as historical
evidence, not current instructions to fix already-corrected code.

**Next task:** checkpoint the validated state, then migrate carried annotations
through the shared recursive interfaces, local context and admitted environment.
Tie selected binder tags to actual sort visits and preserve them through every
accepting shortcut and synthesized term. The focused source inventory below
identifies several paths; it is not exhaustive. Do not create a second checker
or treat an isolated Quick guard as completion. Afterwards discharge the joint
recursive/admission obligations and the public-acceptance theorem.

## Recovery checkpoints

Most recent checkpoint, before the active representation change:
`checkpoint/pskernel-core-before-runtime-annotations-20261010`
at **0c7f63b446bfd4b0847ece437b76bccd40ac3fb9**.

Earlier checkpoints:
- `checkpoint/pskernel-core-before-lambda-sort-evidence-20261010`
  at `ffd56473b9c42ff641a29e94094920e3322c4fef`.
- `checkpoint/pskernel-core-before-lambda-type-simplification-20261010`
  at `5e3fa749d18441d7d35d1be9555c93cad78974cb`.
- `checkpoint/pskernel-core-before-checked-annotations-20261010`
  at `9943eed674b6de039e70fdde355aad248a6bfff4`.
- `checkpoint/pskernel-core-before-cache-free-reference-20261010`
  at `32fb55d651cc8228794216ae298872978f3be0f9`.

Recover by a recovery branch or reviewed revert; no force push is needed.

## Prior validated lambda-codomain stage

The preceding completed stage is lambda codomain-sort certification, preserved by
the current checkpoint at `0c7f63b4`.

Shared checked lambda inference now:
1. Checks the domain and infers the opened body.
2. Re-infers the actual returned body type at infer-only grade.
3. Exposes that result's sort.
4. Closes the unchanged body type and returns the corresponding forall.

The previous opportunistic cheap-beta reduction of lambda body types was
removed. Let-body normalization remains. Resource errors retain their exact
classification; non-resource codomain-certification failures decline.
Infer-only lambda calls skip the extra gate and retain validity preconditions.
Cached hits separately require cache invariants.

`SemanticReferenceLambda.LambdaTrace` records the actual type-of-body-type
and sort-exposure calls, codomain level and resulting state.
`SemanticLambdaCodomain.lambda_trace_checked_reading` fixes the actual
returned level on both lambda and function-type readings, with exact erasure,
typing and their four hereditary-validity facts under explicit recursive
premises. It no longer asks for an arbitrary level or a separate proof-fibre
premise. Global provenance/coherence remains open.

Validated receipts:
- [Proof audit 38055104083](https://github.com/dwijayuda/pskernel/actions/runs/38055104083/job/114221834109)
  at `2baa33e165f914d14f635d68934293e3fcea89ed`:
  **249 build jobs, 84 companion files, 221 semantic axiom targets**.
  Import closure: 135 modules, exactly 12 allowed Con Leche pure-math modules,
  zero legacy-judgment and zero production-assurance imports.
  Reference audit: 1,824 definitions, zero cached fallbacks.
- Native/conformance [run 38054667785](https://github.com/dwijayuda/pskernel/actions/runs/38054667785)
  at `e600c3ac862e68009511f778203758415838a9df`:
  native job **114220568884** passed all suites.
  Both Arena modes passed **141/141 tutorial + 18/18 bugs**, zero declines.
  Arena jobs: cached **114221065854**, reference **114221065799**.
  Corpus pin `b83254de5146ef34147ab82a48edbe1856b0edcc`, historical adapter.
- The final explicitly typed source rebuilt to the same Arena binary SHA-256:
  **dc710ab555596a973a1bb301e52da1f5adf414ade63aeb691ba2cb6717016ce6**.
  Identity job **114221834301** in run 38055104083 passed.
- Fresh exact 4.35 exports use exporter
  `05d43a2bc773b40ecfdebb32294192a5ef756951`.
  Cached job **114221065867** passed Prelude/UTF8/XOR/Int64.
  Reference job **114221065827** passed Prelude/UTF8/XOR, then
  **Int64.toBitVec_div timed out at 180 seconds, exit 124**.
  The runtime workflow therefore failed overall. Do not hide this.
- Full Init/Std/Mathlib were not rerun; full-corpus qualification remains open.
  Historical timeout comparisons do not prove current performance equivalence.

## Architecture and proof boundaries

There is one shared checking/admission implementation. A Boolean semantic-cache
policy specializes it to cached or reference mode. Reference APIs explicitly fix
the disabled policy throughout recursive calls, sessions and admission. Disabled
lookups always miss even in poisoned states; insertions are no-ops. Structural
sharing remains through exact-result proofs. Cached mode is not silently
covered by the reference soundness target.

The legacy `Judgments.lean` is mathematically inadequate: its equality and
typing relations collapse. `JudgmentAdequacy.lean` proves that defect.
Those operational results are quarantined from the new semantic model.
They do not exhibit an executable acceptance of False.

The new model uses PSKernel's own annotated syntax and a relative set-theoretic
universe/function model. A declarative dependent-function fragment is sound
and relatively consistent. Full-kernel soundness has not been proved.

Foundation: explicit **[ConLeche.SetTheory V]**. There is no global instance or
constructed existence theorem. Allowed host axioms are only propext,
Classical.choice and Quot.sound. The semantic audit rejects sorryAx and custom
axioms; passing it does not eliminate theorem hypotheses.

Only pure set mathematics is imported from Con Leche at
**65e74db49e89ad2bbd1e90aa4f784954db41fa3a**:
ConLeche.SetTheory.* and ConLeche.SetModel.Ops (12 modules).
No upstream checker, checker soundness or acceptance theorem is imported.

`AnnotatedExpr` mirrors every raw constructor, with rangeSort on lam/forall.
`AnnotationValid` and `FunctionValid` are hereditary semantic predicates.
Formal counterexamples prove that identical raw erasure plus both predicates
does not imply coherent annotations over empty domains. Never select an
arbitrary positive annotation merely to make a Prop obligation vacuous.

`UniverseRegime.check` exactly compares zero conditions over all universe
parameter/metavariable valuations. It is not equality of universe levels.
`checkedExprEq` combines raw structural equality with this annotation guard.
The public raw comparator does not yet run that guard.

Active new files:
- src/Ps/KernelCore/Core/AnnotatedExpr.lean
- src/Ps/KernelCore/Core/UniverseRegime.lean
- src/Ps/KernelCore/Core/AnnotatedEquality.lean
- metatheory/Ps/KernelCore/Metatheory/SemanticAnnotationCoherence.lean
- metatheory/Ps/KernelCore/Metatheory/SemanticCoherentValidity.lean
- test/AnnotatedSyntaxTests.lean

The coherence relation mirrors the executable comparator and establishes
its equivalence laws and closure under lifting, substitution, local closing
and universe instantiation. Its transitivity is structural equality, not kernel
definitional equality. A new counterexample shows that checkRegimes alone,
without the raw shape check, is not stable under substitution.

## Remaining completion obligations

1. Carry the selected annotations through actual shared infer/WHNF/defeq,
   local contexts and stored declarations. Validate their provenance at binder
   sort visits. Prove coherent structural shortcuts for the actual acceptance
   path, not merely a separate assurance guard.
2. Discharge a joint graded recursive theorem for checked inference, infer-only
   under its validity premises, WHNF and definitional equality. Include beta,
   projections, primitive reductions, eta, proof irrelevance and recursors.
   Do not assume that every inferred type has a sort: that is false in the
   relevant generality.
3. Construct/preserve environment models for definitions, theorems, opaques,
   ordinary/mutual/nested inductives, generated eliminators and quotients.
   Justify literal and primitive capabilities and universe assignments.
4. State an allowed-axiom/model policy and modeled initial environment.
   Arbitrary admitted axioms can include an axiom of False, so they cannot
   imply unconditional consistency.
5. Connect actual public reference acceptance and input translation to the
   original statement, then derive the empty-False corollary. Internal callback,
   annotation and admission soundness must be discharged, not assumed.
6. Cached refinement, generated PSC0 execution and broad conformance remain
   separate qualifications. Performance is not the current proof exit gate.

## Research anchors

Read pinned sources, not assumptions about the latest moving branch:
- Official Lean type checker:
  https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp
- Con Leche expression/annotation/checker:
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Expr.lean
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Core.lean
- Its explicit theorem/foundation boundary:
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/SetTheory/Core.lean
- Con Ron representation/refinement:
  https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/README.md

Con Leche carries annotated syntax, checks binder regimes and licenses selected
reductions in its verified mode. Its trusted/shipped modes and verified theorem
scope must be distinguished. PSKernel cannot borrow its acceptance theorem.

## Cloud workflow mechanics

Workflow: `.github/workflows/psc0-pskernel-core-correctness.yml`.
Its push trigger watches its own path on the active branch. Source changes use
`[skip ci]` to avoid unrelated expensive workflows; then a meaningful workflow
update triggers the audit. The manual runtime_checks input enables native,
Arena and focused exports. Do not bypass proof or axiom gates.

Core commands run **only in GitHub Actions**:
- `npm run test:proofs`: build production/metatheory, check dependency fence,
  check all 84 companion files.
- `lake exe pskernel_annotated_syntax_tests`: current new native syntax cases.
- `npm test`: native regression suites, now also includes annotated syntax.
- `lake build psc_kernel_core_arena`: reference-capable binary.

Use remote API file/tree/commit/ref operations. Create a tree from the observed
base tree, create a commit with the observed parent, re-read the live branch,
then update the ref with expected_sha. Fetch Actions jobs/logs and preserve
exact source/run/job identities. Do not claim pass until the completed logs
confirm it.

Before ending a stage, update this file, AI_CONTINUATION_PROMPT.md,
REFERENCE_CORRECTNESS_PLAN.md, RESEARCH_AND_MIGRATION.md, relevant architecture/
TCB/evidence documents and the draft PR description. Keep unfinished claims
false, preserve historical evidence with its original revision, and identify
the smallest genuine next proof obligation.

## Next migration entry points inspected in the current source

This is a focused inventory, not an exhaustive checker-coverage claim. Paths
below are under src/Ps/KernelCore; they were read at the active branch's
9cf6d802ea9bc33fabd220abfb38b3fe432495ba revision.

| Site | Why an isolated guard patch is insufficient |
| --- | --- |
| Checker/Ops.lean and Checker/Knot.lean | All callbacks still exchange raw expressions. Knot has its own accepting raw-equality shortcut (line 357), before Quick is called. |
| Checker/DefEq/Quick.lean:36 | A second direct structural-accept path also needs carried readings. Updating this function alone leaves the Knot shortcut. |
| Checker/DefEq/BinderSpines.lean:140 and :313 | Lambda/forall domain shortcuts compare before opening. Coherent substitution transport is needed through their shared instantiation spine, plus binder-regime agreement. |
| Checker/Inference/Core.lean | Checked applications have their own raw-type shortcut. Lambda/forall visits already compute useful sort evidence, but discard the annotation from runtime results. |
| Checker/DefEq/Shortcuts.lean:126 and :201 | Both eta directions fabricate a lambda from an exposed forall. The chosen range annotation must follow that actual forall reading and pass the lambda-versus-product regime obligation. |
| Core/LocalContext.lean | Local declarations store raw types and optional values. Converting expression nodes alone will not preserve the types retrieved at free-variable visits. |
| Admission/Declaration/Admission.lean | Definitions/theorems/opaques and mutual work environments store raw types/values. Stored readings must survive actual admission transactions. |
| Checker/Reduction/WhnfCore.lean | Beta consumes an application spine through InstantiateRev and ApplyArgsCheap. Carry the chosen annotations through these transformations and justify the proof-regime argument checks. |

Proceed with a coordinated representation/recursive-interface migration in the
shared implementation, with exact input erasure and trace connections. Do not
create an independent fallback checker or insert a superficial guard in only
one entry point. Audit synthesized terms, stored types/rules, eta and recursors
alongside imported expressions. A whole-kernel consistency claim still needs
the joint recursive and admission theorems after the migration.
