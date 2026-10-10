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

Current source/audit-trigger head at this snapshot:
`0e7311b0fc775eb99849046971e2c24468dd3838`.

The active stage has moved the annotated syntax and guards into runtime Core,
then added structural-coherence and hereditary-validity proofs. It is **not
fully validated yet**. The latest cloud run failed on two proof-script errors;
the new native syntax tests passed.

- Representation source commit:
  `9ed7e37017c637d5182b0d0f13ef21f0cde55a92`.
- First audit: run **38056276397**, job **114225352796**,
  source `c217d10b601b3b4643a83f471d3c22ac7811cc07`.
  Failed because the moved UniverseRegime module lacked the existing
  DecidableEq instance for PsKernelName.
- Fix plus coherence/validity extension:
  `ffdfe75c680dec701beffcd7613dd8c0a33257cf`.
  UniverseRegime now imports its existing runtime equality owner,
  `Ps.KernelCore.Core.Expr.Shared`.
- Second audit: [run 38056606291](https://github.com/dwijayuda/pskernel/actions/runs/38056606291),
  job **114226291815**, source `0e7311b0fc775eb99849046971e2c24468dd3838`.
  Failed only at the reported compilation stage; it did not complete the
  semantic axiom gate or all companion proofs.
  `SemanticAnnotationCoherence.lean` lines 184 and 206 report
  **simp made no progress**, in the bound-variable case of `Coherent.inst`
  and the free-variable case of `Coherent.close`.
  Replace those fragile simplifier steps with explicit cases on the index/name
  tests and qualified `AnnotatedExpr.inst`/`AnnotatedExpr.close` reductions.
  Do not treat downstream modules as validated merely because no diagnostic
  reached them before this dependency failed.
- The same second run passed
  `PSKERNEL_ANNOTATED_SYNTAX: PASS cases=12 modelImports=0`.
  Reference-policy audit remained 1,824 definitions, zero cached fallbacks.
- No new public-checker behavior or conformance result is claimed by this stage.
- A stronger exact `application_trace_checked_reading` theorem was being
  drafted but is not included at the source head above. Read the live source:
  later commits may already contain it and the compilation repairs.

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

## Last fully validated stage

The last completed stage is lambda codomain-sort certification, preserved by
the current checkpoint at `0c7f63b4`.

Shared checked lambda inference now:
1. Checks the domain and infers the opened body.
2. Re-inferrs the actual returned body type at infer-only grade.
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

The coherence relation mirrors the executable comparator and aims to establish
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
