# PSKernel Core proof work state

## Proof-guided Lean 4.35 model strategy and public checker entry — October 10, 2026

Canonical proof strategy: [PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md](PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md). Pinned official Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`) determines actual compatibility. The pinned Con Leche source (`65e74db49e89ad2bbd1e90aa4f784954db41fa3a`) supplies **only pure set mathematics**, not its verified checker or main soundness proof. Con Ron's two-step Rust refinement is a later-stage template for optimized backends, not a present PSKernel correctness theorem.

**Design ruling:** proof-guided co-design. Freeze an end-to-end *successful reference acceptance ⇒ modeled environment ⇒ no derived theorem of False* statement, with an explicit `[SetTheory V]` foundation and an axiom interpretation policy. Preserve Lean-compatible admission of *assumed* axioms in normal mode; verified consistency cannot claim unconditional nonacceptance of `axiom impossible : False`. Modify the one executable checker only where the selected annotated result, binder universe regime or state evidence must be carried through actual recursion. Prove exact behavioral erasure and source compatibility at each such migration. Never infer annotation coherence solely from an empty semantic domain.

**New checked entry proofs:** [`SemanticPublicEntry.lean`](metatheory/Ps/KernelCore/Metatheory/SemanticPublicEntry.lean) proves that the real `psKernelCheckNoMVarNoFVar` declaration guard implies numeric name bounds; real `psKernelMkCheckerSession` starts with empty local frame and counter zero; and guarded lambda/forall/let initial binder constructions preserve exact native opening and frame bounds under explicit `Scoped` hypotheses. Later `publicKernelSession_checker_initial_frame` connects the public `psKernelKernelSessionChecker` API to that same frame, **without modeling arbitrary user-constructed environments**. The latest unvalidated addition `emptyKernelSession_environment` and `emptyKernelSession_checker_initial_frame` uses the real successful `psKernelKernelSessionEmpty` constructor; it does *not* itself prove an initial set model.

Source commits: [`89292f66`](https://github.com/dwijayuda/pskernel/commit/89292f667c42d208884e1705a4383a72e67367d1), [`ab895200`](https://github.com/dwijayuda/pskernel/commit/ab8952001cc95a7804e2462e41b40e3c5cf17b8c), [`29e3ad5e`](https://github.com/dwijayuda/pskernel/commit/29e3ad5e276a15fe9d2ad046c2286245dfd77688), [`3fe5058e`](https://github.com/dwijayuda/pskernel/commit/3fe5058e847d8b99242da1c087cb658079596393) and candidate [`63cdc22d`](https://github.com/dwijayuda/pskernel/commit/63cdc22d339f821be6bdcfa25b5f15e936aafdbf).

**Verified focused source:** [run 38071399079](https://github.com/dwijayuda/pskernel/actions/runs/38071399079) at `3fe5058e847d8b99242da1c087cb658079596393`, 267 build jobs, 84 companion files, **321 explicit semantic-axiom declarations**, 153 model dependency modules (12 pinned math modules, zero production-assurance and legacy-judgment imports), 1,840 reference-policy definitions with zero cached fallbacks, seven native executables, all passed. Previous [run 38071032073](https://github.com/dwijayuda/pskernel/actions/runs/38071032073) at `29e3ad5e` was green with 320 explicit declarations. The **newest two-lemma source** `63cdc22d` triggered [run 38071595259](https://github.com/dwijayuda/pskernel/actions/runs/38071595259); inspect its completed logs before calling it green.

**Broader Lean-compatibility evidence remains separate:** full [run 38070188607](https://github.com/dwijayuda/pskernel/actions/runs/38070188607) passed build, proofs, tutorial, bugs, focused Std and Lean 4.35 jobs, but full **Init** and **Std** timed out (status `timeout`, not acceptance); Mathlib skipped. Init reached about 2.3M records and 18,453 declarations; Std about 2M records and 14,314 declarations before timeouts. Green profiling *job* is not completion of its underlying Init checker (600-second timeout). Do not claim complete Lean compatibility or a newly qualified reference runtime from these runs.

**Still open:** prove a meaningful initial set model, explicit axiom/False pins, actual successful public-session/model entry, one joint graded inference/WHNF/defeq soundness invariant with cross-call annotation provenance, complete inductive/quotient/primitive admission soundness, the end-to-end relative-consistency corollary, cached and shipping-backend refinement, and full pinned Lean conformance. The source changes above are **proof/CI only**, not executable rule changes.


Snapshot: 2026-10-10 UTC. Read the live branch before continuing; this document
is a handoff, not a claim that the full proof is finished.

## Current validated public-entry checkpoint

**Source:** `63cdc22d339f821be6bdcfa25b5f15e936aafdbf`. [Cloud run 38071595259](https://github.com/dwijayuda/pskernel/actions/runs/38071595259), job 114269936326, **passed**. Exactly 267 build jobs, 84 companion files, 323 reviewed semantic declaration axiom targets, 153 dependency modules (12 pinned mathematical modules, no checker-assurance imports), zero cached fallbacks in 1,840 reference definitions and seven native executables passed. The binary, Arena and fresh-export jobs were not run in that focused workflow.

[Public-entry evidence](PUBLIC_ENTRY_EVIDENCE_2026-10-10.md) contains the exact proof scope, source identity, and separately recorded Init/Std timeouts. The accepted public empty-kernel-session constructor has a proved empty environment and initial checker frame. **This is not yet a semantic model of the initial environment, full recursive inference/reduction/equality soundness, complete admission soundness or the public relative-consistency theorem.** The new architecture decision is [proof-guided co-design](PROOF_GUIDED_FULL_SOUNDNESS_AND_LEAN435_COMPATIBILITY.md), with Lean 4.35.0-rc4 compatibility authoritative and an explicit modeled-axiom policy.

**Next actual proof obligations:** model the real initial environment and reserved logical basis; retain the exact annotated term/type, universe regimes, environment snapshot and syntactic frame through the shared graded recursive inference/WHNF/DefEq operations; prove all admission extensions; compose real reference acceptance with the environment model. Do not infer validity from an empty semantic context, drop the allowed-axiom premise, or promote optimized/generated backends without independent refinement.

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
- Do not create a new chat/thread or recurring automation without a user request.
- Read applicable AGENTS files, package `GITHUB_FIRST_WORKFLOW.md`, and
  `psc0/docs/selfhost-language/CURRENT.md` before substantive work.
  Root/PSC0/package AGENTS were absent at the preceding inspection.
- The current PSC0 authoring profile is broader than the old PSC1 profiles.
  This kernel remains Lean-native experimental; generated PSC0 qualification
  has not been established. Explicit local types on match-valued expressions
  remain important.

## Bounded local-frame and actual binder opening — 2026-10-10

Proof-only source commits
[`7f2ff1c8`](https://github.com/dwijayuda/pskernel/commit/7f2ff1c87a3d5f7369243eb5448b1bcf03e12194),
[`93145917`](https://github.com/dwijayuda/pskernel/commit/9314591744c822b68507d438f192a35002839a41)
and parser-only correction
[`bd32e4fc`](https://github.com/dwijayuda/pskernel/commit/bd32e4fcb64cc6c2b6c6555b39ad308ad9c4309a)
add a syntax-level frame invariant over the **actual shared lookup**. `BoundFrame`
bounds numeric identities in the semantic binder list without incorrectly
requiring a dependent context to be closed. `LocalFrame` bounds the selected
stored name, type and let value, and preserves `Scoped 0` for the selected
stored type/value. Empty, weakening, real local/let insertion and native
scope exit are covered.

`boundFrame_fresh` and `localFrame_fresh` derive the actual allocator's
`FreshBoundContext` and `FreshLocalContext` premises syntactically.
`binderChild_localContext_frame`, `letScope_localContext_frame` and
`binderChild_fvar_frame_result` connect those to the existing reference
checker context/model and exact fvar results. `binderChild_opened_frame`
combines the same production fresh-name result, native body instantiation,
`Scoped 0`, and the updated local frame at the advanced counter.
None of these theorems assumes semantic validity to choose an annotation.

**Validated source**: workflow commit
[`37ab7783`](https://github.com/dwijayuda/pskernel/commit/37ab7783212018c5ed1c0b8d43328006c32931ba)
at [run 38066007090](https://github.com/dwijayuda/pskernel/actions/runs/38066007090)
passed 266 build jobs, 84 companion proof files, 298 semantic axiom targets,
the 152-module model import audit (12 pinned pure-math modules) and seven
native test executables. This validation covers the initial bounded-frame
slice through `7f2ff1c8`, **not** the subsequent opening theorem.

**Final validated proof candidate**: `bd32e4fcb64cc6c2b6c6555b39ad308ad9c4309a`
(code), `566d1c88dc3ac997a2f4d1f76810036529db8d2a`
(workflow-only audit trigger),
[run 38066810266 / job 114256009792](https://github.com/dwijayuda/pskernel/actions/runs/38066810266/job/114256009792):
**passed**. The completed cloud log recorded 266 build jobs (221 focused),
all 84 companion files, 298 semantic axiom declarations,
152 model dependency modules including 12 pinned pure-math modules,
0 production-assurance/legacy-judgment imports, 1,840 reference definitions
with 0 cached fallbacks and all seven native regression executables.
The separate binary, Arena and fresh-export jobs were skipped by the
focused workflow. This evidence covers the corrected binder-opening theorem.

The intermediate [run 38066469877](https://github.com/dwijayuda/pskernel/actions/runs/38066469877)
failed from using Lean-reserved variable name `scoped` in
`binderChild_opened_frame`; the isolated rename to `openedScoped`
at `bd32e4fc` repaired compilation. That failed run is retained as a
distinct source revision, not hidden as success.

**Important remaining obligations:** This is a conditional *binder-entry*
invariant, not a proof that arbitrary successful public checker executions
establish or preserve the frame. First establish public-context initialization
and the graded recursive frame invariant across actual infer, WHNF and defeq
callbacks, including allocator, parent restoration and scope exit. Then carry
identical selected annotated readings and provenance through recursive
results, all accepting equality shortcuts and admission transactions.
The allowed-axiom/model policy and the public `False` consistency corollary
remain open. No production checker or model foundation was changed; existing
reference Int64 and full-corpus timeouts remain unresolved. No latest Arena
binary was built by these focused workflows.

## Exact resume point

Latest fully validated source/audit trigger:
`3fe5058e847d8b99242da1c087cb658079596393` (public-entry initial frame; run 38071399079). Earlier gate:
`566d1c88dc3ac997a2f4d1f76810036529db8d2a` (bounded-frame and
actual binder opening, source `bd32e4fcb64cc6c2b6c6555b39ad308ad9c4309a`).
Earlier fully validated checkpoints:
`37ab7783212018c5ed1c0b8d43328006c32931ba` and
`35cef8c29358ecac8a3e89df540e0fdce72fcbca`.
This is still a conditional syntactic and binder-entry proof, not global
successful-checking soundness or relative consistency.
Documentation-only commits may follow it; read the live branch and comparison.

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

## Current owned-checker milestone

The reference-checker route now has one local-declaration/context implementation
parameterized by its expression representation. Raw and annotated contexts use
the same lookup, shadowing, local insertion and let insertion operations.
Erasure preserves the exact first selected declaration, its metadata and
allocation index. Shared inference-result and forall-view data retain fixed
expression/type readings; storing them is not a typing certificate.

The actual reference free-variable branch is connected to that exact stored
annotated type in both inference grades, without WHNF, equality, recursion or
cache-correctness premises for that branch. Semantic context extension is
constructed through the production insertion operations and connected to the
actual binder-child context. Let assignments are constructed from the checked
stored value. Parent models, fixed checked readings, syntactic freshness and
Scoped 0 remain explicit; allocator and recursive scope preservation are open.

The actual checked-lambda and forall sort visits now use a shared runtime
infer-then-sort helper. Its carrier retains the actual inferred type and level;
infer-only lambda has an explicit unchecked constructor with no level.
All-input projection equations recover the previous sort/lambda pipelines,
including failures and complete returned states. Native tests exercise callback
skipping, symbolic levels, state sequencing and failure classification.

SortVisitSelected records the actual successful call and symbolic regime
agreement outside every satisfying-valuation premise. Actual LambdaTrace and
ForallTrace fields construct this provenance. Two claims tied to the same call
cannot select conflicting zero/successor regimes, even over an empty domain.
This does not establish coherence between different calls with equal raw inputs.

The public recursive result and admitted declarations still carry raw expressions.
The lambda's local visit carrier is projected at that raw result boundary.
Complete annotation transport, actual guarded accepting shortcuts, joint
infer/WHNF/defeq soundness, full safe admission and the public relative-consistency
theorem remain unfinished. The explicit SetTheory V foundation is unchanged.

| Module | Checked scope |
| --- | --- |
| `AnnotatedLocalContextErasure` | Shared maps, exact first lookup, shadowing, indices and local/let insertion commute with erasure. |
| `SemanticInferenceBoundary` | Fixed expression/type results and forall views erase exactly; lambda construction reuses one tag; application substitutes the argument expression. |
| `SemanticCheckedReading` | Typing plus both hereditary predicates for fixed term/type readings; local-context model definition. These predicates alone do not certify provenance. |
| `SemanticReferenceLocalContext` | Actual reference fvar success in both grades returns the exact stored annotated type, given parent context erasure/model. |
| `SemanticLocalContextExtension` | Construct local and let context models using checked fixed readings, syntactic freshness, scope and value interpretation. |
| `SemanticReferenceBinderContext` | Connect constructed context models to actual binder-child erasure and the actual fvar run in that child; not whole-binder soundness. |
| `SemanticSortVisitProvenance` | All-input projection equations and execution-derived, valuation-independent same-visit selection and non-clash. |

The preceding live source `4a162b2056658155001828d0c17a426b000a3a2d`
already passed [run 38059022897, job 114233292177](https://github.com/dwijayuda/pskernel/actions/runs/38059022897/job/114233292177):
256 build jobs, all 84 companion files, 255 semantic axiom targets, 21 syntax
cases, a 142-module model closure with 12 allowed pure-math modules, and 1,824
reference definitions with zero cached fallbacks. The documentation then
lagged the code at the earlier `9cf6d802` representation stage; this handoff
reconciles that gap.

Five failed attempts preceded the current green gate:
runs 38060275600 and 38060658281 exposed folded raw projection aliases in old
admission ordinal proofs; run 38061081280 exposed a reserved identifier and
two projection proof reductions; run 38061552694 required explicit Boolean
false reduction in four context-extension branches. Run 38061999713 passed
all 266 production/metatheory build jobs and the 298-target semantic audit, but
two companion files needed explicit raw specialization/helper unfolding.
All native suites passed in those attempts. The exact failures, source revisions and repairs remain in
`MIGRATION_EVIDENCE.json`. The compatibility repairs restore elaboration of the original mathematical
claims; they do not weaken assumptions or alter checker rules.

## Next implementation/proof task

The smallest proof-only continuation is to derive the binder-entry freshness
premises from a maintained local-frame invariant. Reuse `SemanticScope.NamesBelow`,
`allocator_fresh` and `allocated_open_frame`; cover the actual stored names,
types and let values, empty initialization, local/let insertion at the advanced
counter, opening and scope exit. Preserve `Scoped 0` as part of the graded
recursive invariant. Do not infer freshness merely from semantic satisfaction.

The coordinated representation continuation is then to carry the SAME produced
annotated expression/type readings and their intensional provenance across the
existing InferOperation/WHNF/DefEq interfaces and stored declarations. Preserve
them through application argument substitution, exposed forall views, beta
spines, eta synthesis and every accepting structural shortcut. An unchecked
lambda visit cannot supply a default tag. Different visits with equal raw inputs
need an actual coherence guard or an additional proved cross-visit invariant.
Then close joint recursion, admission and the public empty-False corollary.


## Source-specific broader validation

A separate, earlier-source validation ran at
`df830e7cd8b39c699210e631889539f43c064092`:
[workflow 38060658283](https://github.com/dwijayuda/pskernel/actions/runs/38060658283)
built the Arena binary in 247 jobs, SHA-256
`68cf183cd8980a2fcf0d75409cba655e9ff33688cf9a37856b0608a7fbeea8c4`.
Cached historical Arena passed 141/141 tutorial and 18/18 bugs, with zero
declines. Fresh cached Prelude/UTF8/XOR/Int64 exports were accepted. Full Init
timed out at 500 seconds (exit -9), Full Std at 590 seconds (exit -9), and the
Init profiling checker timed out at 600 seconds (exit 124), despite a green
profiling job. Mathlib was skipped. That workflow failed overall, including the
then-unrepaired projection proof. These are intermediate-source receipts:
binder helper integration followed them, so this binary hash and these corpus
results do not identify or qualify the final current runtime. No final Arena
binary hash was measured in the focused semantic workflow.

The older reference Int64 timeout at 180 seconds (exit 124) remains unresolved.
The full corpus, cached/reference refinement, generated PSC0 qualification and
performance claims remain open.

## Recovery checkpoints

Most recent checkpoint, before shared storage and actual sort-visit integration:
`checkpoint/pskernel-core-before-owned-acceptance-20261010`
at **4a162b2056658155001828d0c17a426b000a3a2d**.

Earlier checkpoints:
- `checkpoint/pskernel-core-before-runtime-annotations-20261010`
  at `0c7f63b446bfd4b0847ece437b76bccd40ac3fb9`.
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

This historical stage is lambda codomain-sort certification, preserved by
the representation checkpoint at `0c7f63b4`.

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
- Full Init/Std/Mathlib were not rerun at that historical revision. The later
  intermediate-source Init/Std timeouts are recorded above; full-corpus
  qualification and current performance equivalence remain unestablished.

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
update triggers the audit. The proof job now runs the full native regression command even if its proof
step fails (unless canceled), so failures preserve both kinds of evidence.
The manual runtime_checks input additionally enables the standalone binary,
both small Arena modes and focused exports. Do not bypass proof or axiom gates.

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

## Remaining migration entry points

This focused inventory describes the validated source above; it is not an
exhaustive checker-coverage claim. Paths are under `src/Ps/KernelCore`.

| Site | Remaining obligation |
| --- | --- |
| `Checker/Ops.lean` and `Checker/Knot.lean` | Callbacks still exchange raw expressions. The Knot has an accepting raw-equality shortcut before Quick. Preserve fixed readings across the existing recursion. |
| `Checker/DefEq/Quick.lean` | Its own direct structural-accept path also needs carried readings and an actual coherence guard. |
| `Checker/DefEq/BinderSpines.lean` | Domain shortcuts compare before opening. Preserve coherence through shared instantiation and obtain binder-regime agreement. |
| `Checker/Inference/Core.lean` | Application has a raw-type shortcut. Actual lambda/forall sort helpers now retain observations locally, but the recursive return remains raw. |
| `Checker/DefEq/Shortcuts.lean` | Both eta directions synthesize a lambda from an exposed forall. Its tag must follow that exact reading and satisfy the lambda/product regime obligation. |
| `Core/LocalContext.lean` and `Core/AnnotatedLocalContext.lean` | One generic storage implementation and exact erasure are proved; the actual checker context still chooses its raw specialization. |
| `Core/InferenceBoundary.lean` and `Core/AnnotatedInference.lean` | Fixed carried result/view constructors exist; constructing their data does not certify recursive provenance or typing. |
| `Admission/Declaration/Admission.lean` | Definitions, theorems, opaques and mutual work environments still store raw types/values. Preserve readings and models across whole transactions. |
| `Checker/Reduction/WhnfCore.lean` | Beta consumes an application spine through InstantiateRev and ApplyArgsCheap. Transport annotations and justify proof-regime argument checks. |
| `Checker/State.lean` and `SemanticScope.lean` | Derive and maintain freshness, name bounds and scope for actual storage, allocator, opening and scope exit. |

Proceed within the shared implementation with exact input erasure and execution
connections. Audit stored types/rules, synthesized terms, eta and recursors
alongside imported expressions. The public consistency theorem still requires
joint recursive and admission soundness, an allowed-axiom/model policy and the
original-statement connection. No cached-mode or generated-PSC0 promotion is
part of this milestone.

