# PSKernel Core: Lean 4.35 repairs and architecture review

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

**Most recent code candidate**: `bd32e4fcb64cc6c2b6c6555b39ad308ad9c4309a`,
workflow audit trigger
`566d1c88dc3ac997a2f4d1f76810036529db8d2a`,
[run 38066810266](https://github.com/dwijayuda/pskernel/actions/runs/38066810266):
pending at this documentary checkpoint. The preceding
[run 38066469877](https://github.com/dwijayuda/pskernel/actions/runs/38066469877)
failed because `scoped` was used as a Lean proof-variable identifier in
`binderChild_opened_frame`; this was renamed to `openedScoped` in the
candidate. Do not claim the candidate is green before completed logs confirm it.

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


Date: 2026-10-10 (Asia/Jakarta). Work was performed through GitHub and cloud CI.

## Owned local contexts and sort-visit provenance — 2026-10-10

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

Recovery checkpoint: `checkpoint/pskernel-core-before-owned-acceptance-20261010`
at **4a162b2056658155001828d0c17a426b000a3a2d**.

| Module | Checked scope |
| --- | --- |
| `AnnotatedLocalContextErasure` | Shared maps, exact first lookup, shadowing, indices and local/let insertion commute with erasure. |
| `SemanticInferenceBoundary` | Fixed expression/type results and forall views erase exactly; lambda construction reuses one tag; application substitutes the argument expression. |
| `SemanticCheckedReading` | Typing plus both hereditary predicates for fixed term/type readings; local-context model definition. These predicates alone do not certify provenance. |
| `SemanticReferenceLocalContext` | Actual reference fvar success in both grades returns the exact stored annotated type, given parent context erasure/model. |
| `SemanticLocalContextExtension` | Construct local and let context models using checked fixed readings, syntactic freshness, scope and value interpretation. |
| `SemanticReferenceBinderContext` | Connect constructed context models to actual binder-child erasure and the actual fvar run in that child; not whole-binder soundness. |
| `SemanticSortVisitProvenance` | All-input projection equations and execution-derived, valuation-independent same-visit selection and non-clash. |

### Next proof slice

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


### Broader evidence remains source-specific

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

## Runtime annotation representation and coherent transport — 2026-10-10

The annotated expression representation, binder-regime decision procedure and
guarded structural comparator now live in the production Core library:
`Core/AnnotatedExpr.lean`, `Core/UniverseRegime.lean` and
`Core/AnnotatedEquality.lean`. The metatheory imports those exact definitions;
it no longer owns a second implementation of their executable operations.
The new modules import no model, legacy judgments or upstream checker.

This is a representation migration, not migration of public acceptance.
`Checker/Inference`, WHNF, equality and admitted environments still exchange
raw `PsKernelExpr`. Moving a sound guard into `src` does not establish that
an accepting raw comparison actually ran it. Binder annotations remain
untrusted data until tied to the actual sort checks. The next architectural
step must carry these particular readings through the shared recursive
operations and environment storage, and validate binder tags at their visits.

`SemanticAnnotationCoherence.lean` proves that guarded structural equality is
exactly the constructor-by-constructor `Coherent` relation. The relation is
reflexive, symmetric and transitive, and the executable comparator remains
successful after lifting, term substitution, local-name closing and universe
instantiation. Binder names and binder-info fields are ignored just as in the
existing raw comparator; ordinary sort levels, constant universe lists,
metadata, let nondependency flags and projection names/indices remain checked.
These are structural-equality laws, not transitivity of kernel definitional
equality, subject reduction or equality completeness.

The proof also exposes a necessary boundary:
`regimes_alone_not_substitution_stable` is a formal counterexample to using
the annotation guard without the raw shape check. Substitution can replace a
variable with a binder and reveal conflicting tags that the old shape-mismatched
guard did not compare. The combined comparator includes the required shape
evidence. This is an invalid prospective proof shortcut, not an exhibited
public-kernel exploit.

`SemanticCoherentValidity.lean` proves that guarded comparison preserves both
hereditary annotation and function validity, as well as the existing denotation
equality. `application_trace_checked_reading` fixes the exact application and
substituted result type and proves typing plus all four hereditary validity
facts together. Its structural branch still explicitly requires the annotation
guard; its conversion branch still needs preservation by the recorded recursive
equality call. No arbitrary annotation witness, cache validity or global
checker-soundness axiom discharges those remaining obligations.

The representation design follows the pinned Con Leche
[annotated expression](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Expr.lean)
and [annotation/checker pipeline](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Core.lean).
PSKernel retains its own raw syntax, annotations, guards and proofs; only the
previously allowed pure set mathematics is imported. Con Leche's annotation
pipeline is design evidence, not a proof of PSKernel's acceptance behavior.

Cloud validation: [Proof job 114228540945](https://github.com/dwijayuda/pskernel/actions/runs/38057387016/job/114228540945) at
`9cf6d802ea9bc33fabd220abfb38b3fe432495ba` passed **254 build jobs**, all **84 companion files**,
the **242-declaration** semantic axiom audit and **12 native annotated-syntax cases**.
The 140-module dependency closure contains exactly 12 allowed Con Leche
pure-math modules, zero legacy-judgment imports and zero production-assurance
imports. The reference-policy audit checked 1,824 definitions with zero cached
fallbacks. The complete workflow passed. The first attempt failed because the moved
universe-regime code had relied on an indirectly imported name-equality
instance; the source now imports its existing runtime owner explicitly.
Two subsequent attempts exposed proof-script reduction issues; explicit index/name
cases and Nat.lt_irrefl repaired them. All failed runs and the final success are
preserved in MIGRATION_EVIDENCE.json. [Raw-binary identity job 114227668195](https://github.com/dwijayuda/pskernel/actions/runs/38057087757/job/114227668195)
at `ec410d5ff6614c815ba8d640f148cbeb133e2dc6` rebuilt the raw Arena
checker in 218 jobs and matched the runtime-tested `e600c3ac` binary exactly:
`dc710ab555596a973a1bb301e52da1f5adf414ade63aeb691ba2cb6717016ce6`.
Only a proof file and the workflow changed between that identity source and
the green source above; runtime/host source did not change. The identity run's
proof job failed before the final proof repair; its binary job passed.
Native regressions, Arena and fresh exports were not rerun in this stage.
Their earlier source-specific receipts, including the reference Int64 timeout,
remain below. Binary identity does not establish generated PSC0 qualification.

Recovery branch: `checkpoint/pskernel-core-before-runtime-annotations-20261010`
at `0c7f63b446bfd4b0847ece437b76bccd40ac3fb9`.
No new axiom or stronger foundation is introduced. The explicit
`[ConLeche.SetTheory V]` relative assumption remains, without a constructed
instance or existence theorem. Full-kernel checker/admission soundness and
public consistency remain unfinished. Generated PSC0 qualification, full
Init/Std/Mathlib conformance and the reference Int64 timeout remain open.

## Checked lambda codomain evidence — 2026-10-10

Checked lambda inference now re-infers its returned body type at the infer-only
grade, then exposes that result as a sort before returning the function type.
This is part of the shared checked lambda rule in both cache modes. The
reference specialization cannot bypass it through a cache hit. Infer-only
lambda inference retains its separate validity precondition; cached hits still
require the separate cache invariant.

The new visit computes the information that the prior local proof had to take
as an arbitrary selected regime and a proof-valued-fibre premise. It does not
assume that every inferred type always has a sort. A failed extra certification
declines conservatively, while resource failures preserve their existing
resource-exhaustion classification. Scope exit uses the state after the new
visit and retains the existing parent-cache restoration discipline.

`LambdaTrace` now records both the actual inference of the body type and its
sort exposure, including their contexts, states and returned level.
`SemanticLambdaCodomain.lean` derives the codomain's set membership from those
visits. Its `lambda_trace_checked_reading` theorem fixes **the same concrete
execution-derived level** on the lambda and its returned function type and
establishes their exact raw erasures, typing, and all four hereditary
annotation/function validity facts. It has no caller-chosen lambda level and no
separate proof-valued-fibre hypothesis.

The remaining local premises are the soundness/validity facts at recorded
recursive calls and the scope/freshness invariant. These have not yet been
discharged by a joint checker induction. The runtime does not yet carry
validated annotated expressions through every operation, and the raw
structural-equality path does not run the annotation-agreement guard. This
stage therefore does not establish global annotation coherence or full-kernel
metatheory/consistency.

The design follows the explicit codomain-sort visit in
[pinned Con Leche](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Core.lean#L1216).
Its source rejects assuming universal inferred-type validity. PSKernel currently
performs this extra check at every checked lambda, without Con Leche's
annotation-carrying chain optimization. The
[pinned Lean implementation](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp#L125)
does not perform this certification visit; stricter behavior and additional
work are real compatibility/performance boundaries and must be reported.

Before changing production, checkpoint
`checkpoint/pskernel-core-before-lambda-sort-evidence-20261010` was created at
`ffd56473b9c42ff641a29e94094920e3322c4fef`. No new axiom or stronger foundation
assumption is introduced; all mathematical foundation assumptions remain
explicit. Full recursive checking, admission, allowed-axiom models, public
statement preservation and generated PSC0 qualification remain open.

[Proof job 114221834109](https://github.com/dwijayuda/pskernel/actions/runs/38055104083/job/114221834109)
at `2baa33e165f914d14f635d68934293e3fcea89ed` passed **249 build jobs**,
all **84 companion files** and the **221-declaration** semantic axiom audit.
The **135-module** dependency closure contains only the 12 allowed Con Leche
pure-math modules, zero legacy judgment imports and zero production assurance
imports. The reference-policy audit checked **1,824 definitions** with zero
cached-default fallbacks. The complete final audit workflow passed.

[Native and conformance run 38054667785](https://github.com/dwijayuda/pskernel/actions/runs/38054667785)
at `e600c3ac862e68009511f778203758415838a9df` passed the native suites,
lambda type/conversion/admission tests and the new checked-only certification,
decline and resource-classification cases. Both Arena modes passed
**141/141 tutorial and 18/18 bug cases**, with zero declines.

Fresh exact 4.35 Prelude/UTF8/XOR/Int64 closures all passed in cached mode.
Reference mode passed Prelude/UTF8/XOR, then **timed out on Int64 at 180 seconds,
exit 124**. That check remains unresolved; the runtime workflow failed overall
on this timeout. Full Init/Std/Mathlib were not rerun, and their earlier
qualification gaps remain open. No general compatibility, mode-equivalence or
performance claim follows from these focused checks.

The final source adds an explicit local type annotation required by PSC0's
authoring guide. Its [cloud rebuild](https://github.com/dwijayuda/pskernel/actions/runs/38055104083/job/114221834301)
matched the runtime-tested binary's SHA-256 exactly:
`dc710ab555596a973a1bb301e52da1f5adf414ade63aeb691ba2cb6717016ce6`.
The final audit above therefore applies to the final typed source, with
executable evidence tied to the matching binary. Generated PSC0 qualification
remains separate.

## Direct lambda types and validity transport — 2026-10-10

Historical receipt: the subsequently added checked codomain-sort visit is
documented above. The earlier missing-visit statements below describe the
pre-certification revision.

The shared production lambda branch now closes the body type returned by its
recursive inference directly. Previously it first applied
`psKernelExprCheapBetaReduce`. This change applies to checked and infer-only
inference under both cache policies. It removes that extra normalization and
the preservation premise it required in the lambda model bridge. It does not
prove the old pass sound or remove reduction obligations elsewhere.

`SemanticValidityScope.lean` proves that `AnnotationValid` and
`FunctionValid` depend only on the variables within a term's scope, and
transports both invariants through closing a fresh free variable.
`lambda_trace_type_validity` then constructs the actual returned function
type with both invariants from recursive domain/body-type evidence and an
explicit selected-regime premise. The existing lambda term model theorem no
longer accepts a separately reduced body type or its preservation assumption.

The production regression uses
`fun (P : Sort u) (h : (fun (Q : Sort u) => Q) P) => h`.
It checks that checked and infer-only inference retain the raw codomain redex,
that conversion to `forall P, P -> P` succeeds, that public admission accepts
this declared type, and that the invalid `forall P, P` type is rejected.
All four combinations of cached/reference and Prop/Type are checked.

**Research basis.** The pinned
[Lean lambda implementation](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp#L125)
performs this extra cheap reduction. The
[pinned Con Leche checked lambda](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/Core.lean#L1216)
returns the abstracted inferred type directly. That supports the architectural
choice; it does not prove PSKernel compatible. Our inferred raw syntax can now
differ from Lean's, and fuel/timeout behavior can differ. Actual conversion and
declaration acceptance are tested separately.

Con Leche also checks the lambda annotation against a computed codomain sort,
once at the innermost lambda of a chain, and checks agreement along the chain.
Its source explicitly rejects assuming that every inferred type has a sort.
PSKernel does not yet perform those annotation checks. The next substantial
architecture task is to connect actual checking evidence, validated annotations,
and the shared inference/WHNF/equality recursion. Merely adding a sort check
without carrying coherent annotations would leave the main proof gap open.

No new axiom or stronger foundation assumption was added. The proofs remain
relative to explicit `SetTheory V`; foundation existence is unconstructed.
Full recursive checking, accepted annotation provenance, safe admission,
allowed-axiom models and public statement preservation remain unfinished.
The legacy operational judgments were adjusted to the new return syntax only;
they remain quarantined and inadequate as a soundness specification.

A recovery branch was created before the production edit:
`checkpoint/pskernel-core-before-lambda-type-simplification-20261010` at
`5e3fa749d18441d7d35d1be9555c93cad78974cb`.

[Proof job 114214647274](https://github.com/dwijayuda/pskernel/actions/runs/38052617458/job/114214647274) at
`52eb8e72c2f20b5328cbf531a6be119947efb946` passed **248 build jobs**, all
**84 companion files** and the **219-declaration** semantic axiom audit.
The **134-module** dependency closure contains only the 12 allowed Con Leche
pure-math modules, with zero legacy judgment or production assurance imports.
The reference-policy audit checked **1,821 definitions** with zero cached-default
fallbacks. The overall workflow failed only its separate baseline-diagnostic
setup; this proof job passed. The diagnostic was rerun independently.

[Native tests and focused runtime checks](https://github.com/dwijayuda/pskernel/actions/runs/38051925196)
at `2a34f8299060fc6e91d2fc79a18ab8fcd9d4f0cf` passed the existing native
suites plus lambda raw-type, conversion and admission tests in all four
cache-mode/sort-regime combinations. Both Arena modes passed **141/141
tutorial and 18/18 bug cases**, with zero declines. The binary SHA-256 was
`51383d1c27a78d0496b99ec29b710d9e0491c6bea1211237b436145efc87f77d`.

Fresh exact 4.35 Prelude, UTF8, XOR and Int64 closures all passed in cached
mode. Reference mode passed Prelude, UTF8 and XOR, then **timed out on Int64
at 180 seconds (exit 124)**. That is an unresolved check, not acceptance or
a logical rejection. The runtime workflow therefore failed overall; its
native/Arena jobs passed. Its old lambda companion-proof failure was repaired
in the proof job above. No runtime source changed between the native-tested
revision and the final proof revision.

Full Init/Std/Mathlib were not rerun. Their earlier timeouts and missing
qualification remain open. Small-suite success does not prove cached/reference
equivalence, universal Lean compatibility, or full-kernel soundness.

The [controlled Int64 comparison](https://github.com/dwijayuda/pskernel/actions/runs/38052827877/job/114215267947)
built checkpoint `5e3fa749` and candidate `0aa3d403` on the same runner and
fed both the identical export. **Both reference checks timed out at 180
seconds**, exit 124. Their binary hashes match the recorded pre-change and
new runtime binaries. The timeout therefore predates the lambda change; this
bounded experiment does not establish equal performance or acceptance.
The diagnostic job is green because it preserved both timeout results as data,
not because Int64 passed.

## Checked annotation agreement (previous stage) — 2026-10-10

Three assurance modules remove an assumed coherence premise from guarded
structural comparison and connect the guard to actual sort-exposure visits.
They do not yet change the public checker.

| Module | Checked result | Boundary still open |
| --- | --- | --- |
| `SemanticUniverseRegime.lean` | An executable exact decision procedure for equality of universe-zero conditions over all parameter and metavariable assignments; preserved by the production universe substitution. The production `psKernelLevelIsNotZero` test is exactly uniform positivity. | A zero-condition comparison does not equate universe levels; it is used only for binder annotations. |
| `SemanticCheckedAnnotations.lean` | Raw structural comparison plus the annotation guard implies equal interpretations for every reading, without an assumed `RegimesAgree` premise. Guard transport through lifting, closing and universe substitution is proved. | The public raw comparator does not run this guard, and the guard alone does not establish typing or annotation provenance. |
| `SemanticCheckedAnnotationVisits.lean` | The executable validation step succeeds exactly when the actual sort exposure succeeds and its returned level matches the annotation's zero condition. Forall trace/model and positive-beta bridges use this evidence. | Recursive inference/reduction soundness and hereditary validity remain explicit premises. No fictional lambda body-sort visit is assumed. |

The universe-zero condition is either impossible or a finite conjunction saying
that selected variables are zero. The implementation compares those finite
variable lists by mutual membership, ignoring order and duplicates. Parameters
and metavariables with the same name stay distinct. This follows the mathematical
boundary of pinned [Con Leche PropWhen](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Kernel/PropWhen.lean)
and its [checked bit semantics](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Annot/Bit.lean),
without importing either checker module.

The exactness proof covers every valuation, including absent or duplicate
universe-substitution entries as handled by the production lookup. It does not
rely on finite example tests. The checked sort comparator still rejects distinct
sort levels even when both have the same nonzero regime. Conflicting zero and
positive binder annotations are formally rejected, including the class of
empty-domain counterexamples found in the preceding stage.

No custom axiom, `sorry`, global foundation instance, or stronger mathematical
foundation assumption was added. The existing explicit `SetTheory V` parameter
remains the basis of relative model claims. Its existence is not constructed by
this stage.

### Validation and completion boundary

[Proof run 38050725364](https://github.com/dwijayuda/pskernel/actions/runs/38050725364) at
`06a488e20f9ae0215d1c77e94a195b9e988f072c` passed **247 build jobs**, all **84 companion files** and the
**212-declaration** semantic axiom audit. The **133-module** dependency closure
contains only the 12 allowed Con Leche pure-math modules, with zero legacy
judgment or production assurance imports. The reference-policy audit again
checked **1,821 definitions** with zero cached-default fallbacks.

The recovery branch
`checkpoint/pskernel-core-before-checked-annotations-20261010` at
`9943eed674b6de039e70fdde355aad248a6bfff4` preserves the preceding state.

Only assurance source, Lake registration, the correctness-workflow label and
documentation change. Prior native/Arena binary receipts remain unchanged.
There is no new whole-corpus, performance or generated-PSC0 claim.

**Full-kernel metatheory and relative consistency remain unfinished.** The next
architectural obligation is to make successful public checking produce coherent
annotated readings and preserve them through the joint inference/WHNF/equality
recursion. A theorem conditional on the new guard is not evidence that the
existing raw checker performs it. Full safe environment admission, the allowed
axiom/initial-model policy and public statement preservation remain required.
These obligations must be proved, not postulated.

## Binder and function proof boundary — 2026-10-10

Historical receipt: the lambda reduction described in this stage was later
retired by the direct-lambda-type change documented above. Its old preservation
premise is not an outstanding premise of the current lambda bridge.

Six new assurance modules connect the set interpretation to additional reference
checker branches. These are checked local theorems, not a completed recursive
soundness or full-kernel consistency theorem.

| Module | Proved result | Remaining premise |
| --- | --- | --- |
| `SemanticAnnotationValidity.lean` | Hereditary product-bit condition; preservation through lifting, substitution, opening/closing and universe substitution; application and typed beta under that condition. | Establish valid annotations from the entire successful checker, including infer-only paths. |
| `SemanticFunctionValidity.lean` | Hereditary application/lambda evidence; preservation under syntax transport; positive-regime beta recovers the lambda domain; general beta retains an explicit argument-domain premise. | Full term validity, recursor/projection meaning and coherent readings of raw syntax. |
| `SemanticReferenceBinders.lean` | Inverts successful reference forall inference in both modes, recording the exact recursive calls, two sort checks and fresh local context. | Semantic validity of the recursive calls. |
| `SemanticReferenceSortChecks.lean` | Identifies actual sort-exposure paths and constructs the product model from the returned type readings and visited sort results. | Preservation by the particular WHNF calls, recursive typing, freshness and opened-body validity. |
| `SemanticReferenceApplication.lean` | Inverts checked application; follows its structural/equality comparison and exact production substitution to a typed result. | Function-type exposure, recursive typing, regime agreement on the structural route and semantic equality on the actual defeq route. |
| `SemanticReferenceLambda.lean` | Inverts checked lambda inference and models its actual cheap-beta-reduced, freshly closed body type; constructs hereditary lambda evidence. | Recursive body typing/validity, preservation by that type reduction, closedness and justification of the selected regime. |

The lambda branch does **not** visit a sort check on its inferred body type.
The theorem records the extra obligation instead of claiming that such a visit
occurred. The application theorem covers checked inference; the infer-only
application spine is a separate remaining proof.

### Why another validity predicate is not a completion shortcut

`hereditary_validity_not_erasure_coherence` proves a stronger adequacy
counterexample: two annotated lambdas can erase to exactly the same expression
and satisfy both new hereditary predicates, yet have different interpretations.
Its domain is the empty product `Π P : Prop, P`; the fibre premises are then
vacuous. This does not exhibit acceptance of False by the executable. It proves
that the two predicates alone cannot discharge the structural comparator's
`RegimesAgree` requirement.

Annotation provenance must therefore remain tied to actual checked visits and
universe substitution. Adding a blanket coherence hypothesis to the final
acceptance theorem would leave the requested proof unfinished. The immediate
remaining task is a checked-reading invariant that supplies this evidence and
is preserved through the joint inference/reduction/equality recursion.

The design follows the distinct bit and function obligations in pinned
[Con Leche annotation validity](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Annot/Valid.lean)
and [kinded hereditary denotation](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Semantics/WellDenoted.lean).
Only the existing pure mathematics dependency is imported. No upstream
checker theorem, custom soundness axiom, or global set-model instance was added.

### Validation boundary

[Proof run 38037497460](https://github.com/dwijayuda/pskernel/actions/runs/38037497460) at
`44e4f1a7d0385343309895138a896ef156cb7666` passed **244 build jobs**, all **84 companion files** and the
**175-declaration** semantic axiom audit. The **130-module** dependency closure
contains only the 12 allowed Con Leche pure-math modules, with zero legacy
judgment or production assurance imports. The reference-policy audit again
checked **1,821 definitions** with zero cached-default fallbacks.

This stage changes assurance modules, their Lake registration, the correctness
workflow label and documentation. It changes no production checker, host,
native tests, frozen reference, compiler seed or provider selection. Previous
native/Arena receipts retain their original identities; this proof stage makes
no new full-corpus or performance claim. The pre-refactor checkpoint remains
available. Full semantic metatheory, admission-model preservation and public
relative consistency remain open.

## Correctness-first reference specialization — 2026-10-10

The pre-refactor state is preserved on
`checkpoint/pskernel-core-before-cache-free-reference-20261010` at
`32fb55d651cc8228794216ae298872978f3be0f9`.

The shared checker now takes an explicit semantic-cache policy throughout
inference, reduction, equality, callbacks, sessions and declaration admission
(101 functions in the initial 29-file dependency closure). Fixed reference API
aliases supply the disabled policy. Cache lookups miss and insertions are
no-ops even for an incoming state containing forged entries. Cached mode stays
available with its existing obligations. No rule weakening or fallback kernel
was added; structural sharing and lookup indexes remain.

`SemanticReference.lean` proves actual reference sort and constant inference
bridges without cache-coherence premises. The latter still requires the selected
declaration's semantic model at its actual universe instantiation.
`ReferencePolicyAudit.lean` checks the elaborated call graph for default-policy
fallbacks and direct bypasses of the cache gates. It is a structural audit.

This follows the reference-first separation documented by pinned Con Leche and
Con Ron. It does not import their checker soundness or establish equivalent
acceptance. In particular, Con Leche's annotation validity comes from actual
checker visits; our existing annotation counterexamples remain unresolved
requirements for the next stage. The complete sources, proof milestones and
relative assumptions are in [REFERENCE_CORRECTNESS_PLAN.md](REFERENCE_CORRECTNESS_PLAN.md).

Native regressions at `6b7395c1af7cc85181bc8ada4b9feb975fea8bb9`
([run 38033599176](https://github.com/dwijayuda/pskernel/actions/runs/38033599176))
passed all existing executable suites plus forged inference/reduction/equality
cache checks, dependent binder traversal, valid and invalid admission, empty
ordinary-inductive admission and fuel-exhaustion classification. That run's
proof step failed; later proof repairs are recorded separately.

The reference-capable binary at `c0c02dd2a8c73eeca9b12256c6773064342f36a8`
([run 38034307491](https://github.com/dwijayuda/pskernel/actions/runs/38034307491))
built in 218 jobs; SHA-256
`06ef88828d72bc705787f8aa9613d243313389a62e4b4d3ae6a625b38fbfba02`.
Both cache policies passed the same pinned historical Arena tutorial 141/141
and bugs 18/18, with zero declines. This stage did not rerun full Init, Std,
Mathlib or the fresh 4.35 exporter corpus. Earlier receipts retain their
original executable identities.

The final [proof run 38034714932](https://github.com/dwijayuda/pskernel/actions/runs/38034714932)
at `f635419041d4a2e0da133c5c5b6c24fdaa2d3ce0` passed all **238 build jobs**,
all **84 companion files**, the **136-declaration** semantic axiom gate and the
dependency fence (12 pure mathematical modules, 124-module closure, no legacy
judgments or production assurance imports). The elaborated reference audit
traced **1,821 definitions**, with zero cached-default fallbacks or raw bypasses.
Only proofs/workflow changed after the passing native regression; no runtime
source changed. No theorem statement was weakened to accommodate the policy.

**Full recursive checker soundness, inductive/quotient admission, allowed
axioms and public end-to-end consistency remain open.** Cached refinement,
large-corpus throughput and generated PSC0 qualification remain separate.
Performance is not an exit condition for the reference model proof.

## Relative set model and dependent-function metatheory — 2026-10-10

The assurance layer now uses actual universe sets and dependent functions,
relative to an explicit mathematical foundation. It contains a proved
declarative dependent-function fragment and exact bridges for production
substitution. **Full kernel metatheory and public kernel consistency remain
unproved.** This result must not be substituted for those remaining obligations.

### Constructed results

| Module | Result and boundary |
| --- | --- |
| `SemanticSetDomain.lean` | Instantiates `ProofDomain` using actual set membership. Derives sort successors, non-self-membership, dependent-product closure at `imax`, impredicative Prop, typed beta, eta, and emptiness of the contradictory product. |
| `SemanticAnnotatedExpr.lean` | PSKernel-owned annotated readings retain every original constructor, name, binder flag, symbolic level, let, metadata and projection. Binders gain a semantic codomain-sort annotation. Erasure preserves the original expression representation. |
| `SemanticInterpretation.lean` | Total interpretation under explicit universe/local/global/projection tables; proved weakening, single substitution at every binder depth, scoped valuation independence and closed valuation independence. Arbitrary tables or arbitrary annotations are not certified models. |
| `SemanticContext.lean` | Satisfying dependent contexts; derived sort, function, application, let, conversion, proof-irrelevance, beta/eta/zeta, weakening and typed substitution rules. Empty-context satisfiability is constructed explicitly. |
| `SemanticErasure.lean` | All-constructor correspondence with actual `psKernelExprLiftLooseBVars` and `psKernelExprInstantiateAtChanged`; public `psKernelExprInstantiate1` includes its closed-expression fast path. These do not rely on the legacy judgments. |
| `SemanticDeclarative.lean` | A syntactic dependent-function judgment with actual typing premises. `Declarative.sound` is proved by induction over its rules. `identity_derives` supplies a closed derivation. `no_allProps` and `no_empty` establish relative consistency for this fragment. `fragmentReading` constructs a reading and `relative_consistency` discharges the interpretation parameter, leaving the explicit set foundation. |
| `SemanticConstantInference.lean` | Actual constant-inference result sources and semantic typing, in both modes and including cache hits, under explicit selected-cache and instantiated-declaration membership facts. Environment admission and state publication remain separate. |
| `SemanticConcrete.lean` | Actual uncached sort-inference success has a reading in the set model. Production single substitution supplies typed beta/zeta readings with the required term/type premises. Complete WHNF and cache publication are not inferred from these results. |
| `SemanticExtension.lean` | Constructs a one-constant interpretation extension and proves preservation of existing readings, dependent contexts and typings under explicit non-occurrence conditions. A new constant requires actual membership of its supplied value in its declared type, at the stated universe instantiation. |
| `SemanticAbstraction.lean` | Exact singleton free-variable abstraction, semantic opening under explicit freshness, and closing locally closed inferred types. |
| `SemanticScope.lean` | Scope preservation for lifting/substitution/abstraction; actual allocation yields freshness under a counter bound; allocation plus opening preserves the child frame. |
| `SemanticLevelConstructors.lean` | Production zero/nonzero tests, successor offsets, and `mkMax`/`mkIMax` preserve universe valuations. Full normalization is still separate. |
| `SemanticUniverseSubstitution.lean` | Production level substitution commutes with valuation and full-expression interpretation, including binder annotations; exact erasure and dependent-context typing transport. |
| `SemanticStructuralEquality.lean` | The actual structural expression comparator preserves interpretation when corresponding binder annotations agree on their Prop/Type regime. Deriving that agreement from checker validity remains open. |
| `SemanticModelAdequacy.lean` | A valid closed identity interpretation; checked counterexamples show that erasure equality alone, or even semantic typing plus universe-valued types, does not establish binder-annotation coherence. |

The new declarative fragment has **no rules for global constants, free-variable
declarations, literals, projections, quotients or inductive admission**. Those
constructors exist in the annotated representation and the structural transport
proofs, but that is not a proof of their typing or admission. The fragment's
semantic equality is transitive; PSKernel's algorithmic equality and pair cache
are not claimed transitive.

### Mathematical assumptions and dependency boundary

The Lake dependency is pinned to Con Leche commit
`65e74db49e89ad2bbd1e90aa4f784954db41fa3a` (Apache-2.0).
The imported closure is only [SetTheory](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/SetTheory/Core.lean)
and the [two-regime function constructions](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/SetModel/Ops.lean):
12 pure mathematical modules. Con Leche's checker, acceptance theorem,
preprocessor and executable are not imported into the semantic proof closure.

The theorem parameter `[ConLeche.SetTheory V]` supplies membership,
extensionality, pairing, union, power sets, regularity, a Lean-level replacement
scheme and an omega-chain of Grothendieck universes. **Existence of such a
foundation is assumed, not constructed inside this package.** Choice,
propositional extensionality and quotient soundness are the allowed host
foundation. No custom axiom assumes checker soundness or the final consistency
theorem. The axiom audit checks global dependencies; local theorem parameters,
including the set foundation, remain separate and explicit.

The dependency's upstream toolchain is 4.35.0-rc3. The imported mathematical
closure is rebuilt and checked with this package's exact 4.35.0-rc4 target.
`check-model-dependencies.mjs` checks the dependency commit, forbids assurance
imports from production source, and excludes the legacy collapsed judgments
and non-mathematical Con Leche modules from the new proof closure.
This is an assurance dependency, not a runtime kernel fallback.

### Architectural consequences of the research

Con Leche's [inference proof](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Rules/InferSound.lean)
carries framing, coherent contexts and hereditary grading. Its binder reading
chooses between erased proofs and function graphs using validated annotations.
Our checked `erasure_is_not_semantic_coherence` counterexample demonstrates why
that distinction matters in PSKernel too: identical erased syntax is not enough
to pick arbitrary annotations safely. At this historical stage the representation was assurance-only.
It now lives in runtime Core as described above; actual public annotation
carriage and validation remain unfinished.

The [official Lean reference](https://lean-lang.org/doc/reference/latest/The-Type-System/)
also distinguishes the actual algorithm from ideal conversion properties.
The new proofs use on-domain typed beta and explicit validity premises; they
do not assume unrestricted subject reduction, termination or transitivity of
the executable equality algorithm. Increasing a timeout supplies none of these
proof obligations.

### Remaining route to full completion

1. Establish scope, coherent annotations and hereditary valid-input evidence
   for every actual checked-inference constructor. Use the now-proved
   free-variable opening/closing, allocator frame and universe-substitution
   transport; derive inferred-type and annotation validity from actual runs.
2. Prove infer-only inference on the actual valid inputs, including application
   skipping, telescope transport and all selected-cache invariants.
3. Prove the complete recursive WHNF/reduction and defeq knot, including primitive
   computation, projections, function/structure eta, unit shortcuts, quotients,
   recursors, level normalization and semantic cache publication/restoration.
4. Construct the initial safe environment model and satisfy its trusted axiom
   interpretations; prove full ordinary/mutual/nested inductive and quotient
   admission, positivity, generated constructors/recursors and universe rules.
5. Connect those results to the public admission/checking API and Arena
   transport. Only then derive the public no-False corollary, relative to
   satisfying interpretations of admitted axioms and the mathematical foundation.

A proof of a rule, a callback contract, a model-side extension, or a passing
corpus run does not discharge the other items. The legacy-collapse counterexample
remains checked and intentionally visible. Production behavior, corpus budgets,
compiler seed, default provider and merge status have not changed.

### Why semantic membership is not the checker-validity invariant

The stronger checked counterexample
`membership_is_not_annotation_coherence` gives two readings with the same
erased term and the same erased type. Both have semantic typing, and both types
belong to a universe. Their lambda values nevertheless differ: one is a graph
and one is the proof point. Thus even "term has a semantic type and that type
has a universe" does not establish the annotation coherence needed by
structural comparison. This is a counterexample to a proposed proof interface,
not an executable false-acceptance example.

The pinned Con Leche implementation has additional validated binder data:
[Bit.lean](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Annot/Bit.lean)
reads canonical `PropWhen` annotations from stored expressions, and
[Valid.lean](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Annot/Valid.lean)
establishes their semantic validity at concrete checker visit sites. Its
[WellDenoted.lean](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Semantics/WellDenoted.lean)
also carries hereditary application and lambda-fibre facts.
[Frame.lean](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Semantics/Frame.lean)
separates scope transport from semantic facts. These proof structures are
research references; none of these modules is imported by PSKernel.

PSKernel's current expression representation has no such validated binder
datum. The new proof-only annotations therefore cannot simply be treated as
Con Leche certificates. The next bridge must derive and preserve a coherent
reading from actual checked runs, across local contexts, type conversion,
universe substitution, structural comparison and cache publication. The existing
`I.WellTyped` callback contracts are local interfaces, not a proof that plain
set membership suffices to instantiate the full checker contract. There is no
claim that generic type validity or subject reduction discharges this gap.

The current design keeps these obligations in the assurance layer. A future
proposal to add validated metadata or rechecks to production must additionally
prove its correspondence with the pinned Lean behavior; importing the other
checker's theorem or adding an unchecked annotation cannot discharge it.

### Validation

[Cloud proof run 38031021780](https://github.com/dwijayuda/pskernel/actions/runs/38031021780) checked commit
`1442f3242dea69ac50a6020cca4ebf7fd5cbc1cd` with the exact pinned Lean hash. The full metatheory
build passed **234 build jobs**, all **84 companion files** passed, and the
semantic axiom gate passed **125 declarations**. The source-import gate checked
the 12 pure mathematical dependencies and 82-module proof closure, with zero
production assurance imports and zero legacy-judgment imports.

Failed proof attempts are retained in `MIGRATION_EVIDENCE.json`; the repairs
changed proofs rather than weakening their conclusions or changing production
acceptance. The final source comparison against executable repair
`c78590556fca75f9ee080e32cbb0d0cd82f16b92` has no production `src/` changes.

A fresh [executable regression run 38029044702](https://github.com/dwijayuda/pskernel/actions/runs/38029044702)
rebuilt the same binary hash
`a7c43dc302ee6f51435c33e7cb6d1350c8290aecc561edca855c8475fcdd3827`.
It passed the 241-job executable build, focused regressions, tutorial 141/141,
bugs 18/18, and fresh Prelude/UTF8/XOR/Int64. Full historical Init timed out at
500.03 seconds (last progress: 2,799,999 records and 21,944 declarations); Std
timed out at 590.08 seconds (1,999,999 records and 14,314 declarations).
Mathlib was skipped by the failed prerequisites. The diagnostic profile job
completed, recording a 600-second checker timeout, exit 124 and 174,696 KiB
maximum RSS. These are separate corpus limits, not semantic proof results.

## Earlier local semantic foundation — 2026-10-10

The new `PsKernelSemantics` modules begin a replacement semantic target.
They do not import the legacy typing/equality judgments, and they do not remove
or conceal the checked legacy-collapse counterexample.

- `SemanticDomain.lean` defines typing by actual denotation and type membership.
  Equality requires a shared **defined** value; two undefined expressions do not
  compare equal. Conversion and proof irrelevance are proved with both terms'
  actual typing premises. A concrete proposition algebra interprets truth,
  falsity, erased proofs, impredicative products into Prop, and the successor
  chain of sorts. Checked adequacy witnesses distinguish True from False, exclude
  an inhabitant of the empty denotation, and exclude a sort inhabiting itself.
- `SemanticLevel.lean` interprets levels under arbitrary parameter/metavariable
  valuations and proves the executable zero-level test sound, including `imax`.
- `SemanticClassifier.lean` proves the actual proposition classifier's positive
  result semantically meaningful **under explicit semantic callback contracts**.
  The proof-irrelevance call sequence threads every intermediate state and
  connects both terms to the types actually returned by inference. A deliberately
  dishonest inference callback gives a checked counterexample to the claim that
  an operational trace alone suffices.
- `SemanticSortInference.lean` connects the actual core sort-inference case to
  this target, for both checked and infer-only modes. Cache hits require semantic
  correctness of the selected cache's answer; misses use the sort-successor rule.
  The uncached case is instantiated with the concrete proposition/sort algebra
  without any callback-soundness assumption.

### Scope and assumptions

The concrete algebra is a model of the **local proof/conversion/sort fragment**,
not of the complete dependent type theory. Its sort tokens do not construct
universe sets closed under dependent functions or inductives. The interpretation
witness is a partial local valuation; it is not an interpretation of an admitted
PSKernel environment. The theorem about the empty denotation is therefore not
the final theorem that the public checker rejects every proof of Lean's False.

`ProofDomain` has value-level membership and proof-irrelevance laws and an empty
value; its inhabitant is constructed in the file. It has no field asserting
checker soundness. Generic theorems expose their domain/interpretation hypotheses.
The classifier bridge additionally exposes the missing inference, WHNF and
recursive-defeq semantic obligations. Existing configuration preservation
theorems cannot discharge these hypotheses. No custom axioms or unfinished
proof declarations are introduced.

No production checker behavior, timeout, admitted-axiom policy, compiler seed,
or default provider changes in this stage. The previous executable evidence
continues to refer to its original source and binary hash.

### Next semantic construction

Extend the interpretation to scoped contexts and dependent functions, prove
substitution/valuation transport, then prove lambda/application/forall inference
against it. Infer-only shortcuts must receive their actual validity evidence;
if that evidence cannot be established, add justified checks or annotations.
Only after the remaining reduction/equality rules and declaration-admission
transactions preserve this interpretation can the full model theorem and
public no-False corollary be claimed. Full metatheory completion remains false.

### Checked validation

[Cloud run 38026130891](https://github.com/dwijayuda/pskernel/actions/runs/38026130891)
at `2248f88b61c9f8f311e6e980db91995e9d45c2bc` passed all **206 build jobs**
and **84 companion proof files**, using the exact pinned Lean hash.
`SemanticAudit.lean` checked **35 declarations** and rejected any dependency
outside `propext`, `Classical.choice` and `Quot.sound`; the audit passed.
The generic conversion-fragment proof-irrelevance and empty-denotation lemmas
report no axiom dependencies. The concrete empty witness uses `propext`.
The full printed dependency inventory and local callback assumptions remain
distinct: absence of custom axioms does not discharge theorem parameters.

The sort-inference proof source is `6b28936c94f61575afb8d7083fe22f91d9f5368f`;
the subsequent validation commit changes only the dedicated CI workflow label.
The executable remains the previously tested source/binary documented below.


## Correctness audit and model-proof direction — 2026-10-10

Correctness now takes priority over performance. The metatheory is **not
complete**, and the present operational judgments cannot support a consistency
proof. This is stronger than an unfilled lemma: the current specification
admits a machine-checked counterexample.

### Confirmed specification failure

`JudgmentAdequacy.lean` proves, for every environment and local context:

- `PsKernelDefEqJudgment environment context left right` for arbitrary terms.
- `PsKernelTypingJudgment environment context (sort zero) type` for every type.
- Consequently, no interpretation with an empty type can validate all these
  typing derivations.

The cause is `proofIrrelevanceAlgorithmic` in `Judgments.lean`. It accepts
candidate types and a proposition-classification reduction, but has no premise
connecting the left term to its candidate type, the right term to its candidate
type, or the left candidate type to the second inferred type. Choose the candidate
types identically, choose the second type to be `Sort 0`, and its premises are
reflexive. The unrestricted conversion constructor then collapses typing.
Environment well-formedness alone cannot fix this counterexample, because the
construction works in every environment.

These are theorems **about the specification**, not successful runs of
`psKernelV1CheckExpression`. Existing refinement results establish only the
forward implication from executable success to the legacy judgment. Their
converse is neither stated nor proved. This audit therefore does not exhibit
an executable proof of False; it invalidates using those relations as evidence
that the executable is semantically sound.

The other algorithmic shortcuts, including unit-like structures and structure
eta, also need a typed-input and inference-connection audit. Repairing only the
single demonstrated constructor would not justify declaring the theory sound.

### Comparison with the actual reference proofs

| Implementation and exact research revision | What was checked | Consequence for PSKernel |
| --- | --- | --- |
| Official Lean `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` | [Proof irrelevance calls actual type inference, proposition classification, and type comparison](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp). | Keep the actual term-to-type connections in the proof. An implementation-shaped rule with omitted inference premises is insufficient. |
| Lean4Lean `8223d223ed98661882e95d9d6a7126df7097cd76` | [The typed rule](https://github.com/digama0/lean4lean/blob/8223d223ed98661882e95d9d6a7126df7097cd76/Lean4Lean/Theory/Typing/Basic.lean) requires a proposition and both terms to inhabit it; [the checker proof](https://github.com/digama0/lean4lean/blob/8223d223ed98661882e95d9d6a7126df7097cd76/Lean4Lean/Verify/TypeChecker/IsDefEq.lean) carries translated, well-formed input evidence into infer-only calls. | Separate typed semantic equality from the incomplete comparison algorithm. This pinned verification file still contains unfinished structure-eta and unit-like proofs; it is not a completed proof we can import wholesale. |
| Con Leche `65e74db49e89ad2bbd1e90aa4f784954db41fa3a` | [Rule soundness](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Rules/Sound.lean) recursively retains inference premises. [Infer-only application](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Rules/InferSound.lean) uses semantic input evidence and binder classification; not every application may skip its argument check. | A model-directed checker may need justified annotations or extra checks. Its syntax, inductive treatment, and axiom policy differ from PSKernel, so its model theorem does not transfer by similarity. |
| Con Ron `64a2172a01276aa049220200bac11c075316230f` | [The capstone](https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/proof/ConRon/Capstone.lean) composes Rust-to-twin and twin-to-Con-Leche refinement, with explicit successful pipeline calls, complete worker coverage, chunk-source correspondence, and a set-theory foundation. | A storage rewrite needs its own simulation and input/output correspondence. Hash-consing performance does not establish kernel correctness. The extraction and runtime boundary remains distinct from the mathematical model. |
| Nanoda `4c544ed4099c8227f07d5de77ad1e69fb0740a27` | [Infer/check separation and proof irrelevance](https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/tc.rs) and [configurable axiom admission](https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/README.md). | Useful independent implementation evidence, not a substitute for the missing PSKernel model proof. |

The separate [Lean4Lean model target](https://github.com/digama0/lean4lean-model/blob/27fb3b656c0d536469f6817cf277904dee8eb5ca/Lean4LeanModel/Consistency.lean),
at `27fb3b656c0d536469f6817cf277904dee8eb5ca`, explicitly contains an unfinished
consistency theorem. Its statement and foundation are useful references;
the unfinished theorem cannot be used as a proof dependency.

### Actual primitive repair

The active `psKernelStringEq` now uses `decide (left = right)`, whose
[Lean 4.35 definition](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Prelude.lean)
decides equality of the represented UTF-8 bytes. The all-input theorem
`psKernelStringEq_true_iff` connects a positive result to actual string
equality, discharging `PsKernelStringEqSoundLaw` without a custom axiom.
Fresh-name and universe-parameter uniqueness consequences can now instantiate
that law with a theorem. Hash-coherence proofs use equality substitution, so
they no longer need the old cursor implementation to establish equal hashes.

This deliberately replaces the old implementation's opaque-read proof
obligation with a specified operation; equivalence to the old opaque worker
is not claimed. The worker remains for compatibility proofs but is no longer
called by public string equality. Native execution uses Lean's
`lean_string_dec_eq` runtime override, which remains in the existing
compiler/runtime TCB. Generated PSC0 qualification has not been established for
this implementation. No independent speedup is claimed from this change.


Validation for the specified string equality and adequacy audit is recorded at
`c78590556fca75f9ee080e32cbb0d0cd82f16b92`:
[run 38007755710](https://github.com/dwijayuda/pskernel/actions/runs/38007755710)
passed the 241-job executable build, the 200-job existing metatheory build,
all 84 companion files, foundation/cache/sharing regressions, all 141 tutorial
verdicts and all 18 Arena bug verdicts with no declines. Fresh Prelude, UTF8,
XOR and Int64 exports passed. The positive StringEq soundness theorem reports
**no axioms**; the equivalence lemma reports `propext`, and the freshness
corollary reports only the three standard host axioms. The classifier trace and its refactored caller subsequently passed
[run 38008230732](https://github.com/dwijayuda/pskernel/actions/runs/38008230732)
at `aea996799b986091a4c8fbf6e1ce28f578609348`: 201 build jobs and all 84
companion files. This later change affects assurance code and Lake registration,
not the production implementation tested at `c7859055`.

The current executable still times out on historical Init at 500.012 seconds
and Std at 590.085 seconds under the unchanged Arena budgets. The dependent
Mathlib gate is skipped. The separate 600-second Init profile also times out
(exit 124; peak RSS 174,868 KiB; last entered record 2,414,950). Its diagnostic
job succeeds at preserving that evidence, not at checking the whole corpus.
The string-equality change is therefore not presented as a performance fix
or complete-corpus qualification.

### Retained classifier evidence

`DefEqClassifierTrace.lean` now states the exact positive proposition-classifier
contract as an equivalence with an operational trace. That trace includes the
input expression's inference result, the intermediate checker state, the
WHNF call on that exact inferred type, the final state, and the zero-level
sort result. The legacy refinement helper derives its weaker result through
this trace. The primary trace interface therefore preserves the connections
needed for a future model proof instead of throwing them away.

This remains operational evidence. The trace's inference operation must still
be proved semantically sound on its actual valid inputs. The legacy equality
constructor is not repaired by adding this interface, and the adequacy
counterexample remains an intentional build target.

### Required model theorem and explicit assumptions

The compatibility API admits well-typed user axioms. Such an axiom need not
be true: admitting an axiom of type False cannot imply unconditional consistency.
The model theorem must therefore preserve a model of the safe logical
environment **relative to a satisfying interpretation of admitted axioms**.
A separate restricted consistency mode could instead enforce an exact axiom
policy with proved interpretations; changing that policy is not part of this
primitive repair. Unsafe/partial declarations and their accessibility from
safe checking also require an explicit semantic boundary.

The intended theorem is: given the mathematical foundation, a model of the
initial safe environment, interpretations of the admitted axioms, and a
successful actual safe admission run, construct a model of the resulting
safe environment which preserves earlier interpretations and validates the
new declarations. The no-False corollary additionally fixes the intended empty
interpretation of False. This is a target, not a theorem currently implemented.

Con Leche's [actual model theorem](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean)
has a `SetTheory V` hypothesis. Its
[foundation interface](https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/SetTheory/Core.lean)
includes an increasing countable hierarchy of universes. This is a stated
relative-consistency assumption, not an implementation soundness axiom.
The standard host axioms reported by `#print axioms` do not list such local
hypotheses, so both must be audited. PSKernel has not constructed this model
or adopted an extra foundation axiom in the kernel.

### Architecture and completion gates

1. Define an independent typed or semantic relation with scoped contexts,
   universe valuations, sound constant lookup, and valid environments.
   Retain inference connections and input validity at every shortcut.
2. Prove checked inference establishes that relation. Prove infer-only results
   under their actual well-typed-input premises; configuration preservation
   alone is insufficient. Carry the obligations through reduction, caches,
   proof irrelevance, eta, projection, quotient and recursor paths.
3. Establish complete admission model preservation, including ordinary,
   mutual and nested inductive transactions, positivity, generated recursors,
   quotient bootstrap, safety restrictions, and axiom interpretation.
4. Connect the exact public checker and stream adapter to those results.
   Prove input fidelity and complete coverage. Construct the model and derive
   the no-False corollary; audit all assumptions and runtime dependencies.

Do not assume generic subject reduction or transitivity of the executable
comparison. A semantic equality can be transitive without making the
algorithm's positive cache a transitive closure. Resource exhaustion may
reject or decline; the consistency proof concerns successful checking and
does not require proving all inputs terminate within an Arena budget.

These gates are unfinished. A successful build of the existing proof files
does not close them. No shortcut rule, arbitrary model-soundness premise,
`sorry`, custom axiom, unchecked cast, or fallback checker is an acceptable
substitute.

### Extended Init results and reporting correction

The old executable `e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4`, SHA256
`74609c21967988d5cee861001a3a3334bd204a381b4cfa4b928e5aff4457c54e`,
accepted both full Init exports in
[extended run 38004337520](https://github.com/dwijayuda/pskernel/actions/runs/38004337520):

| Input | Records | Declarations | Wall seconds | Peak RSS KiB |
| --- | ---: | ---: | ---: | ---: |
| Fresh 4.35-rc4 Init | 6,452,982 | 57,919 | 1,647.02 | 319,028 |
| Historical 4.34.1 Init | 6,487,065 | 58,170 | 2,141.76 | 317,308 |

Both checker processes exited zero and emitted a final acceptance covering
every input record. The workflow jobs are recorded as failures because the
original monitor searched stdout while the adapter emits acceptance on stderr.
The monitor is corrected in `a3c9436e0b4a89c9434a72594e810aeccb1e93a0`.
The evidence receipt preserves the original job status and raw-log provenance
alongside the corrected interpretation; it does not relabel the original run
green or weaken the exit/coverage requirements.

These runs precede the specified string-equality repair. They do not validate
the new binary, prove semantic soundness, or pass the unchanged 500-second
Arena Init budget.

The remaining extended jobs have now completed on that same **older binary**:

| Input | Wall limit / elapsed seconds | Result | Last reported records / declarations |
| --- | --- | --- | --- |
| Fresh 4.35 Std | 3600 / 3600.04 | Timeout, exit 124 | 2,899,999 / 20,723 |
| Historical Std | 3600 / 3600.03 | Timeout, exit 124 | 2,999,999 / 21,381 |
| Historical Mathlib | 14400 / 14400.09 | Timeout, exit 124 | 6,499,999 / 49,946 |

Their full raw-log receipts, input hashes and job IDs are preserved in
`MIGRATION_EVIDENCE.json`. Mathlib's input contains 109,790,519 records;
the progress counter is not a completed-corpus result. Raising the wall limit
allowed Init to finish, but did not establish complete Std or Mathlib acceptance.
These timeout conclusions come from actual exit code 124, not the earlier
stdout/stderr acceptance-reporting bug. No new performance experiment was run
for the semantic foundation stage.


## Prior sharing stage: decision and scope

The active package is `psc0/packages/pskernel-core`, targeting the user-selected
Lean **4.35.0-rc4**, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
The repair stage addressed reduction order, resource accounting and cache
modes/scope. The authorized architectural stage now implements certified native
sharing and reusable hash metadata. It does not yet establish complete Arena or
Mathlib conformance. Exact checked results are recorded below and in
[MIGRATION_EVIDENCE.json](MIGRATION_EVIDENCE.json).

The remaining performance problem is architectural: PSKernel preserves
sharing when reading an export, but its semantic operations often traverse
that shared graph as an expanded tree. The implementation must preserve sharing while proving that execution returns
the specified result. This stage follows Con Leche's intrinsic-entry proof
pattern in safe Lean, retains the original expression specification and avoids
a simultaneous rewrite of checker judgments. Its runtime dependence is explicit:
this is a native experiment, not the separately planned portable graph/backend
qualification. No timeout or declaration-specific acceptance exception is added.

## Source ownership and exact comparison pins

The migration combines the latest inspected proof source
`85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62` with the Arena adapter and bounded
cache work from `132d817071cd62c23a70c15984d6c73e14d6e856`. The initial
PSC0 base was `e356162ddf1d0780337b2f510925455c70fb658d`; its later
`4c79a2e921b3b3c27e3be477f7646f89b6b3526a` update concerned compiler
proof-workspace documentation. Historical receipts from either old kernel
branch do not certify this combined source.

| Reference | Inspected identity | Role |
|---|---|---|
| Official Lean | `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364` | Selected 4.35.0-rc4 semantics/toolchain |
| Official development head | `5e96ee1153f945234f126ed024043a0697c9d6f3` | Research only; not the target |
| Con Leche | `65e74db49e89ad2bbd1e90aa4f784954db41fa3a` | Current cached implementation and proofs |
| Con Ron | `64a2172a01276aa049220200bac11c075316230f` | Current explicit DAG implementation and refinement |
| Nanoda | `4c544ed4099c8227f07d5de77ad1e69fb0740a27` | Interned expressions and binder traversal |
| Lean4Lean, Arena reference | `bce3448115f7819fc12d647fadd3bb090666637e` | Checker organization and theory |
| Kha/lean4lean, bundle tag | `456abe5015fc8f54ea595561fc39523d7733c93f` | Separate 4.35 bundle reference inspected |
| Kernel Arena | `b83254de5146ef34147ab82a48edbe1856b0edcc` | Frozen tutorial/bugs/Init/Std/Mathlib inputs |
| lean4export | `05d43a2bc773b40ecfdebb32294192a5ef756951` | Fresh 4.35 exports |

Do not conflate these with the checker versions bundled by rc4.
Its [CMake source][bundle] pins Con Leche at `67f04630d88718e81aa4d07ab64501f68f105398`,
Con Ron at `dd8d8218892c871276b1e569d3decbb368bba1b6`, and Nanoda at
`3a2407216ee84a75f9e1aead6803d0578be06ae7`. The comparison above includes
newer implementations. Reported upstream benchmark times are not controlled
speed ratios against our cloud runners.

## Arena branch audit

These are the extant Arena branch heads rechecked during this continuation.
The last column is workflow completion, **not** a kernel conformance verdict.

| Branch | Head | Latest inspected workflow | Workflow result |
|---|---|---|---|
| `pscv/pskernel-core-arena-budget-study-v1` | `ecf7dd801aaf43e7bbbb15970487c781084585c4` | [PSKernel Core Init proof DAG analysis](https://github.com/dwijayuda/pskernel/actions/runs/37933228241) | success |
| `pscv/pskernel-core-arena-cache-ab` | `9dab024b28697ed1233e4d8f9198d16cfe40c1a4` | [PSKernel Core Arena bounded-cache A/B experiment](https://github.com/dwijayuda/pskernel/actions/runs/37923962388) | success |
| `pscv/pskernel-core-arena-cache-order-ab` | `a178c619bce5ef415d2cb578f3169c4b5d17989c` | [PSKernel Core Arena cache-order A/B experiment](https://github.com/dwijayuda/pskernel/actions/runs/37924378742) | success |
| `pscv/pskernel-core-arena-cache-upper-sweep-v1` | `f6566e47744c87b1335e973fb3b96ce14fb6571f` | [PSKernel Core hot theorem cache-size upper sweep](https://github.com/dwijayuda/pskernel/actions/runs/37943616245) | success |
| `pscv/pskernel-core-arena-eligibility-fast-v1` | `35db6068579798402c1a78c3d909c6d8117b5a42` | [PSKernel Core proof](https://github.com/dwijayuda/pskernel/actions/runs/37943016615) | failure |
| `pscv/pskernel-core-arena-equality-ab` | `3beec6b575e452f23d6cb76d780218d5149398e8` | [PSKernel Core Arena equality A/B experiment](https://github.com/dwijayuda/pskernel/actions/runs/37923775015) | success |
| `pscv/pskernel-core-arena-optimized-v3` | `132d817071cd62c23a70c15984d6c73e14d6e856` | [PSKernel Core Arena focused UTF8 theorem diagnostic](https://github.com/dwijayuda/pskernel/actions/runs/37932815530) | success |
| `pscv/pskernel-core-arena-phase-profile-v1` | `0214fd67cb2a2d9a4ae24f0b549ab4adbe09ccac` | [PSKernel Core proof](https://github.com/dwijayuda/pskernel/actions/runs/37941957359) | success |
| `pscv/pskernel-core-arena-synced-v2` | `e1166c00c3e1e92bf3e67149c4b85b85461db35d` | [PSKernel Core Arena v2 hotspot profile](https://github.com/dwijayuda/pskernel/actions/runs/37922810339) | success |
| `pscv/pskernel-core-arena-v1` | `756f4b9175edc11adf19b6b50586af762d296edc` | [PSKernel Core Arena controlled native comparison](https://github.com/dwijayuda/pskernel/actions/runs/37676544921) | success |

The optimized-v3 branch's [complete Init/Std run 37930905868](https://github.com/dwijayuda/pskernel/actions/runs/37930905868)
failed even though its neighboring proof, readiness, and soundness workflows
were green. The [soundness job 113821083110](https://github.com/dwijayuda/pskernel/actions/runs/37930905967/job/113821083110)
reported 17 correct bug rejections and one decline. The v1
[controlled comparison](https://github.com/dwijayuda/pskernel/actions/runs/37676544921)
checked 200,000- and 362,100-record Init prefixes; it was not full Init or
Mathlib acceptance. The new workflow requires complete verdict counts and
does not allow the old known-decline exception.

The budget-study branch also supplies concrete sharing evidence:
[run 37933228241](https://github.com/dwijayuda/pskernel/actions/runs/37933228241)
measured the proof at historical Init record 361,999,
`Array.extract_append_extract._proof_1_1`, as **24,520 unique nodes versus
12,501,779 expanded tree nodes**, depth 85. Its direct proof DAG contained
neither `reduceNat` nor `reduceBool`; that observation alone does not bound
work after unfolding constants. It supports the traversal diagnosis without
assuming that every slow proof has the same cause.

## Implemented repairs

| Component | Defect | General repair |
|---|---|---|
| Nat evaluation | Both operands normalized before checking whether a name was a Nat primitive | Dispatch first; stop when the left operand is nonliteral |
| 4.35 native reduction | Old compiler callbacks could still participate in logical reduction | Native reduction always returns none; theorem and poisoned-callback check |
| Projection shortcut | Expression node count used as fuel for unfolding referenced definitions | Pass remaining checker fuel; small syntax no longer imposes a false unfolding bound |
| Core WHNF cache | Cheap-recursion results could be published as full results | Suppress publication when either cheap-recursion or cheap-projection mode is active |
| Recursive occurrence diagnostics | Stuck-recursion positivity failure classified as unsupported nested induction | Precise invalid-shape diagnostic; `rec-missing-ih` is a rejection, with no allowed decline |
| Lambda spine | Full type/body node count calculated just to select applied binders | Bound the peel by argument count |
| Equality lookup | Success lookup hashed a pair before applying publication's eligibility rule | Apply the bounded eligibility rule before lookup |
| Open expression caches | All expressions containing local variables refused memoization | Permit bounded open keys within the existing checker configuration and scope rollback discipline |
| Inference eligibility | Checked app/lam/forall and literal refusal paid an unnecessary expression scan | Refuse these shapes before traversing the key |
| Instantiation | Full tree count supplied a fuel wrapper before a second tree walk | Direct structural instantiation with a proof of equality to the reference |

No theorem-name special case or increased Arena time limit is part of these
repairs. Tests exercise the invariants: delayed unfolding, mode separation,
open-cache scope isolation, and giant shared inputs at the bounded lookup and
spine-selection boundaries. Structural instantiation has an all-input
refinement theorem, not just sample agreement.

The existing configuration/metatheory contracts remain. Some companion
operational equations had specifically asserted that fvar keys were never
cached. Those equations now express the scoped hit/miss behavior. In
particular, the raw-state unknown-fvar equation requires a cache miss;
a separate theorem proves unconditional unknown-fvar rejection for a fresh,
empty checker state. This is not a claim that arbitrary caller-supplied
cache contents are trusted input.

## Measured causes, with limits on the evidence

### Symbolic reduction recomputation

At `ad13026571931c0151b7ae53f468cd5363bef391`, a fresh 4.35
`Int64.toBitVec_div` closure (16,206 records, 405 declarations, 497 constants)
exceeded 180 seconds. [Trace run 37986278855][trace] showed repeated
symbolic `Nat.shiftRight`, `Nat.div`, and `Nat.ble` reduction around
`BitVec.msb`.

An [isolated experiment][open-experiment] allowed open keys in bounded caches
on that same source/export. Budgets of 256 and 4,096 took 0.30 and 0.38 seconds,
respectively. These diagnostic binaries are not production receipts. The
initial production WHNF-only repair subsequently took 0.36–0.37 seconds
with the full metatheory and all 84 companion files checked. The later
candidate extends scoped open caching to the other bounded caches.

### Traversal and allocation across the corpus

The [full Init profile report][profile-report] at the earlier scoped-WHNF
revision contains 366 slow declarations, totaling 446,874 milliseconds of
reported declaration time. The largest recorded costs include:

| Declaration family | Recorded elapsed time |
|---|---:|
| `Array.toList_reverse.go._unary` | 100,030 ms |
| `Array.extract_append._proof_1_1` | 29,772 ms |
| `Array.extract_append_extract._proof_1_1` | 21,676 ms |
| `Array.extract_extract._proof_1_1` | 13,719 ms |

The run reached well beyond the original Int64 stall, but did not complete
Init. [Worker-thread stack samples][samples] repeatedly showed instantiation,
tree node counting, structural equality, universe-parameter rebuilding,
eligibility traversal/allocation, and scope cleanup. Eleven samples identify
credible hot paths; they are not enough to assign precise CPU percentages.

A [four-way experiment][traversal-experiment] used the identical first
1,000,000 records, SHA-256
`735d43733b70c51d86d9c4365ea433abcdb76a9f94dfe09a7a7dfc4605699878`.
Baseline, structural instantiation alone, and open caching alone each hit
240 seconds. The combination accepted that prefix in 203.30 seconds,
with 8,507 declarations / 9,199 constants and 332,508 KiB maximum RSS.
This is interaction evidence for the combined change, not full Init
acceptance or a general speedup ratio.

### Why the current cost model remains wrong

Let a shared expression be `e(k+1) = app(e(k), e(k))`. It has O(k) distinct
nodes, but an un-memoized structural walk satisfies
T(k+1) = 2 T(k) + O(1). Returning unchanged nodes preserves memory sharing
after the walk; it does not prevent exponentially many visits during it.

The host adapter already interns export references and preserves physical
sharing. Reworking only JSON parsing therefore misses the measured semantic
walks. The 256-expression-node cache limit prevents some large expression
hashes, but it is a tactical policy, not constant-time metadata. It also
does not bound the cost of large names, universe levels, strings, or bignum
payloads inside an expression node. Lifting and abstraction still retain
node-count prepasses, and universe instantiation still rebuilds recursively.

The inference core opens and closes one lambda/forall at a time. A long
telescope can repeatedly traverse the whole remaining body. For k binders
and a residual body of size N, this introduces O(kN) work before considering
shared subgraphs. Batched telescopes avoid the repeated body substitutions;
dependent domains still require their own substitutions and checks.

## What the other implementations actually do

| Component | Primary-source observation | Consequence for PSKernel |
|---|---|---|
| Official Lean | [`replace_fn`][replace] memoizes shared nodes by address and binder offset; [instantiation][instantiate] cuts off using stored loose-variable metadata and reuses unchanged nodes | Repeated walks need a node identity and cursor-aware memo, not recursive hash preparation |
| Official Lean | [Checker][official] batches lambda, forall, and let telescopes and caches instantiated constant heads before applying arguments | Separate reusable constant work from call-specific arguments; batch binding operations |
| Con Leche | [Expression operations][con-ops] use metadata cutoffs and validated address/cursor memo hits, with each entry carrying its equality to the pure result | Study the refinement discipline; raw addresses are not evidence of equality |
| Con Leche | [Node layer][con-nodes] uses compiler-provided computed fields and distinguishes proved compiler simplifications from runtime/compiler assumptions | This mechanism is native-Lean-specific until PSC0 implements and qualifies an equivalent |
| Nanoda | [Expressions][nano-expr] use interned handles, stored hashes/variable summaries, and per-operation `(expression, offset)` memo tables; [checker][nano-tc] batches lambda/forall inference | Explicit handles are an alternative to raw pointers, with a clear memo lifetime |
| Current Con Ron | [Store][ron-store] has persistent/scratch tiers and per-constructor arrays; [walks][ron-ops] use handle/cursor memos and a Lean twin | Representation and proof boundaries can be designed together for the actual target runtime |
| Lean4Lean | [Checker][l4l] separates infer/check caches and gives the recursive checker explicit method contracts; its theory distinguishes checking from infer-only preconditions | Preserve the existing PSKernel method/configuration proof structure during representation changes |

A correction to broad comparisons is necessary: the inspected Lean4Lean
Arena and bundle revisions still contain an [`EquivManager` union-find][l4l-eq].
Official rc4 uses successful pair queries, and Con Leche uses pair results.
Therefore “all other kernels use only pair caches” is false. PSKernel should
retain its current pair discipline; do not copy an older equivalence manager
without proving its contextual and algorithmic premises. Incompleteness alone
does not make logical equality non-transitive. [Lean #14806][eq-fix] explains
the stronger problem: transitive closure may contain only true equalities,
yet change the algorithm's answer after earlier queries. Recursor construction
can then classify the same field differently while building its type and its
computation rule. Thus a semantic equality certificate alone is insufficient:
memoization must also preserve the algorithm's observable query behavior
where consumers rely on repeatability. This is an architectural invariant,
not merely an exploit-specific test.

Current Con Ron is materially different from the older web-indexed README
describing a close reference-counted Rust port. Its [current README][ron-readme]
describes the DAG rewrite. Its [capstone][ron-capstone] relates successful
Rust stages and complete pending-check coverage to a set model; the driver,
runtime assumptions, and the coverage premises remain relevant. It is a
refinement pattern to study, not a proof that a PSKernel port would be correct.

## Theory and trust obligations

The [Lean4Lean paper][paper] separates abstract typed judgments from the
concrete locally nameless representation and from the executable checker.
Its recursive-method contracts require well-typed input for infer-only
inference and reduction. This matters to cache transport: an unchecked
inference result is not automatically a typing certificate.

The same paper explains why a syntactic tree-size measure cannot justify
general reduction termination. Structural descent and checker fuel solve
different problems. Keep reduction/depth/resource exhaustion explicit;
never interpret a budget failure as a successful judgment. Formal refinement,
absence of false acceptance, conformance to a pinned algorithm, and predictable
runtime are separate obligations.

Con Leche's [`model_exists`][con-main] is accepting-direction consistency
relative to its set-theory interface and checker/axiom policy. PSKernel's
configuration and substitution proofs do not yet constitute the same theorem.
No end-to-end consistency claim is made here.

The [2026 nested-inductive postmortem][postmortem] gives another architectural
lesson: information erased by a transformation can escape validation.
PSKernel must check original declarations and all their arguments before
normalizing them into a more convenient representation. Projection type names,
phantom/non-uniform parameters, and recursor positivity obligations must remain
visible. Shared implementation ancestry is not independent evidence.

## Certified native execution architecture

The current implementation keeps the original pure syntax in `Core/Expr/Basic`.
A single cursor-aware fold specifies syntax operations. Its executed walker
carries entries with an intrinsic equation `value = fold algebra node cursor`;
there is no external table invariant to assume. A hit validates the stored
input and cursor. Each substitution operation fixes its parameters for the
table's lifetime. Keys are non-semantic hints; they cannot authorize a value.

Cursor advancement belongs to each operation's algebra. Instantiation, lifting,
abstraction and both loose-variable queries advance at binders. Node counts,
free-variable queries, structural hashes and universe substitution keep their
cursor fixed: the same node reached at different binder depths must not acquire
redundant entries for a context it does not depend on. Exact bound-variable
occurrence uses this same certified fold, including negative searches.

The design uses the [Con Leche entry discipline][con-ops], but does not import
its exclusivity primitive or its constructor metadata. This distinction matters
to performance: a safe always-memoized traversal can cost more on an ordinary
unshared tree. Small bounded shapes use direct pure execution. Boolean queries
preserve early exits through certificates proving the remaining children cannot
change the result. Native compiler specialization removes the operation
dictionary callbacks; generated C is inspected in CI.

Lifting and free-variable abstraction now use structural descent, with all-input
refinements to the existing reference definitions; term instantiation already
had that refinement. Rebuilding keeps unchanged nodes. Substitution arguments
are prepared once: a checked closedness fact proves lifting is the identity at
every binder depth. Open arguments retain the ordinary lifting operation.
The argument preparation condition is outside the returned closure in generated
C. Empty universe substitutions return the original node under an unconditional
identity theorem.

Exact syntactic equality has a separate pair memo and a proved reflexive pointer
shortcut. Only successful pair results are retained: a false comparison already
terminates that conjunction. This is not the checker's definitional-equality
cache, and it does not infer additional pairs by transitivity.

Hash metadata has a longer lifetime than a substitution memo. A profile of the
first retained-metadata candidate caught whole bucket-array copying and release
costs: four of eleven sparse worker samples were inside array copying under memo
insertion. Retaining a parent state aliases the mutable-array-backed table, so
the expected in-place insertion cost did not apply. The corrected storage uses
Lean's [persistent hash trie][persistent-map], with bounded-width path copying.
A subsequent worker profile still found temporary variable-query memos paying
persistent-trie insertion costs. The current design separates an operation-local
`Std.HashMap` scratch delta from its persistent checkpoint. Only updates that
publish metadata freeze the delta into the checkpoint; read-only cache queries
return the exact hash without publishing. Scalar mixed keys avoid a pair
allocation per probe; collisions remain validated. Each semantic map
or pair set retains a `Squash` of intrinsically certified structural hashes.
The cached result still equals the original hash; the logically unobservable
memo can change without changing a returned cache record. Four compiler
simplification theorems preserve complete map/set operations, including misses.
This is stronger than claiming that cache hits are sound. A separate full
state-equality theorem proves that certified context-free hash metadata could be
retained across scope exit. That theorem is deliberately not installed as a
compiler rewrite: the retention experiment reached 982,096 KiB peak RSS in the
600-second Init profile, versus 153,152 KiB in the preceding trie-only profile.
These are separate-run measurements, not a controlled speed comparison, but they
expose a lifetime risk. Executed scope exit restores the entire parent cache.
No environment-dependent semantic fact is moved into syntax metadata.

The code introduces no project-defined unsafe implementation, cast or axiom.
It relies on Lean's existing pointer-hint contracts, compiler simplification,
proof erasure, `Squash` and `Lean.PersistentHashMap`. These are native execution dependencies,
not features established for the current PSC0 bounded frontend/backend.
`package.json` therefore records `portable: false`,
`Lean-4.35-native-experimental` and `jointSelfhostQualified: false`.
The portable target remains the current PSC0 profile, not either old PSC1 profile.

General tests cover constructor variants and binder cursors, forced memo-key
collisions, open and closed substitution arguments, independently rebuilt equal
DAGs, hash reuse, symmetric pair lookup and failed lookup. A depth-32 shared
family denotes 8,589,934,591 expanded nodes. Passing that family demonstrates
sharing-sensitive execution; it is not a claim that all Arena terms are fast.

The revised worker sample at [run 38000670791](https://github.com/dwijayuda/pskernel/actions/runs/38000670791)
contained no top-frame whole-table copy among eleven samples. It still showed
repeated bounded cache-eligibility scans, structural name hashing, substitution
allocation, semantic-index lookup and scope cleanup. Absence from eleven sparse
samples is not proof that a cost vanished. The two eligibility specifications
now share one scalar-code execution worker: zero means exhaustion and successor
n means n remaining nodes. A decode theorem proves equality for every expression
and budget, and full-function compiler equations preserve all eligibility
decisions and the unchanged 256-node policy. For the bounded native path this
removes per-node Option-result allocations.

## Portable representation and remaining checker work

The native layer above does not implement or qualify the following portable
storage and context-transport obligations:

1. **Retain a pure expression specification; introduce an explicit internal
   graph with a proved denotation.** Use separate typed handles for names,
   levels, level lists, and expressions. Validate handle origin/range and
   acyclicity. Parsed IDs and serialized metadata are untrusted; derive
   metadata from validated constructor inputs.
2. **Make construction establish the invariant.** Store hashes and exact or
   safely saturated variable/level summaries from child summaries.
   Prove erasure/denotation preservation, metadata agreement, and collision
   handling. Hash agreement never proves expression equality. A saturated
   bound may suppress an optimization; it may not authorize an unsound cutoff.
3. **Choose storage against the real PSC0 backend.** Current TS Array push/set
   copy arrays. A naive ever-growing immutable array can make construction
   quadratic. Benchmark a portable persistent/chunked structure, or qualify
   a versioned runtime storage primitive first. Do not borrow Rust Vec or
   Lean reference-count uniqueness costs by assumption.
4. **Unify binding-sensitive walks.** Instantiation, lifting, abstraction,
   and universe substitution need operation-local memo tables keyed by
   handle and every varying semantic cursor. A substitution environment
   may be omitted from the key only when it is fixed for the table's entire
   lifetime. Preserve unchanged handles; prove each accelerated result
   denotes the existing pure result.
5. **Batch telescopes with a context relation.** Accumulate fresh locals,
   instantiate each domain as needed, open the residual body once, and
   close the result in one pass. Prove substitution composition, variable
   freshness, weakening/context transport, and result correspondence.
   Account for changed recursion-depth consumption explicitly.
6. **Scope semantic caches and graph lifetimes together.** Associate caches
   with environment, local context, checking/reduction mode, and graph epoch.
   Preserve query repeatability as well as accepting-direction soundness;
   do not derive extra answers by closing successful pairs transitively.
   Parent scope restoration and fresh declaration state remain required
   until a proved selective transport replaces them. Persistent objects
   must not retain discarded scratch handles.
7. **Separate constant-head work from applications.** Cache universe-instantiated
   declaration types/values by constant plus levels in an immutable environment;
   apply arguments afterward. No-universe/identity substitutions should
   reuse the original term under a proved identity law.
8. **Integrate through one production semantic path.** Preserve existing method
   contracts and admission checks. An internal refined representation is
   acceptable; an unverified second checker or fallback accepting path is not.

The current richer [PSC0 authoring profile][psc0-guide] permits ordinary
structural workers with supported changing parameters. The old
PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 profiles are not imposed.
The selected generated compiler still needs to consume and qualify the exact
new source. General `do`, computed fields, pointer operations, Std maps,
and constant-time mutable arrays are not implied by that profile.

### Validation follows the design

- Prove representation/metadata and traversal refinements for all inputs
  in their stated domains, including resource-failure behavior.
- Exercise graph families with sharing, the same node under different
  binder depths, hash collisions, name/level payload growth, nested dependent
  telescopes, and scope/epoch reuse. Measure node visits and allocations,
  not just the time of one theorem.
- Replay the complete pinned tutorial, bugs, Init, Std, and Mathlib streams
  at their original limits. Keep fresh 4.35 exports separate from historical
  inputs. A prefix, skipped job, or green diagnostic job is not conformance.
- Qualify actual generated PSC0 kernel products and the compiler/kernel
  combination separately before selecting this package as the default provider.

## Native architectural checkpoint

Checked source: `e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4`.
[Main cloud run 38001623085](https://github.com/dwijayuda/pskernel/actions/runs/38001623085).
Native binary SHA-256:
`74609c21967988d5cee861001a3a3334bd204a381b4cfa4b928e5aff4457c54e`.

The native build (241 jobs), full metatheory (199 jobs), all 84 companion files,
foundations, resource/cache/scope regressions and shared-syntax tests pass.
Tutorial has 141 correct verdicts and zero declines; bugs have 18 correct
rejections and zero accepts/declines. Fresh 4.35 Prelude, UTF8, XOR and Int64
closures all pass. Their separate-run wall times are 1.12, 13.50, 16.75 and
0.28 seconds respectively; these are not controlled speed ratios.

The final historical Arena run still times out: Init at 500.014 seconds,
with last progress 2,399,999 records / 18,883 declarations; Std at 590.073
seconds, with last progress 1,999,999 / 14,314. Mathlib is skipped because
both prerequisite gates failed.

[Final diagnostic/fresh run 38001895321](https://github.com/dwijayuda/pskernel/actions/runs/38001895321)
verifies the same binary SHA-256. Complete fresh 4.35 Init and Std also time out
at the unchanged 500/590-second limits, both with exit code 124:

| Complete fresh input | Records in input | Last progress records / declarations | Peak RSS KiB |
|---|---:|---:|---:|
| Init | 6,452,982 | 2,299,999 / 18,434 | 175,280 |
| Std | 10,193,568 | 1,999,999 / 14,186 | 161,416 |

Their input hashes match the preceding sharing experiment recorded below.
These progress counters are not full acceptance. The separate 600-second Init
profile also times out (exit 124), with 175,428 KiB maximum RSS; its last entered
declaration is record 2,414,950,
`String.Slice.Pattern.Model.ForwardSliceSearcher.Invariants.isValidSearchFrom_toList`.
The 180-second worker diagnostic exits 124 at record 497,392 and 108,552 KiB.
Three of eleven sparse top-frame samples show the scalar eligibility traversal;
other samples include substitution/variable traversal, names, persistent lookup
and inference. This confirms the scalar worker is executed; it does not establish
time percentages or eliminate repeated scans.

The final controlled job uses the same 500,000-record historical Init prefix,
one runner, verified binary hashes, and the order baseline, candidate, candidate,
baseline:

| Final controlled variant | Wall seconds | Peak RSS KiB | Result |
|---|---:|---:|---|
| Repair baseline, first | 143.53 | 331,876 | Accepted prefix |
| Final sharing candidate, first | 180.00 | 99,232 | Timeout, exit 124 |
| Final sharing candidate, second | 180.00 | 98,552 | Timeout, exit 124 |
| Repair baseline, second | 142.83 | 332,012 | Accepted prefix |

The final candidate fails this performance comparison. Its lower observed RSS
is censored by timeout, so it is not a memory ratio for equal completed work.
This comparison measures the entire sharing layer against the repair baseline;
it does not isolate the scalar scan from the preceding sharing revision.
The candidate remains an unmerged native experiment and is not eligible for
default-provider promotion.

The preceding scratch/checkpoint revision,
`2e2068774b73b9affcc0852ed14caf96319d29e8`, provides a controlled warning
against equating sharing with speed. [Run 38000670791](https://github.com/dwijayuda/pskernel/actions/runs/38000670791)
ran the exact repair baseline and that candidate on one machine in the order
baseline, candidate, candidate, baseline. The same 500,000-record historical
Init prefix has SHA-256
`0d32781169f0374862e712910eb062568a8f1263aad42608b847ac353a91eb2c`.

| Earlier controlled variant | Wall seconds | Peak RSS KiB | Result |
|---|---:|---:|---|
| Repair baseline, first | 109.06 | 332,416 | Accepted prefix |
| Sharing/checkpoint candidate, first | 160.39 | 100,708 | Accepted prefix |
| Sharing/checkpoint candidate, second | 163.55 | 99,772 | Accepted prefix |
| Repair baseline, second | 109.74 | 332,024 | Accepted prefix |

The candidate reduced memory but was slower. Still earlier retained-Std.HashMap
and all-persistent-trie/cross-scope candidates timed out twice at 180 seconds on
that same prefix while their paired baselines completed in 143–145 seconds.
All these outcomes, including the abandoned storage/lifetime policies, remain
in the JSON receipt. They do not justify provider promotion.

The earlier sharing revision also timed out on complete fresh 4.35 exports:
Init contained 6,452,982 records (SHA-256
`42a17cf35c87380eb76c483de4cf3205d278a5a612047a6f90e8bd35c0a10164`);
Std contained 10,193,568 records (SHA-256
`c12663bb14aba57c4bd01699c4c90634a4432921d08f794b6736429522126dc3`).
The unchanged 500/590-second limits were enforced. Historical regression mode
and strict 4.35 mode are separate tests, not interchangeable evidence.

The architectural result is a proved execution layer and a clearer cost model,
not complete conformance. Stored constructor/name/level metadata, operation
cutoffs and batched binder transport remain the material gap from the reference
kernels. Overlay memo tables alone do not supply those properties. The next
representation/backend stage must address them with its denotation, lifetime
and context proofs; it is not claimed complete by this native checkpoint.

## Prior repair baseline

Code/proof revision: `e8ed888bb4f16153b9aac335872d770ac19bbb11`.
[Cloud run 37990758789](https://github.com/dwijayuda/pskernel/actions/runs/37990758789); native binary SHA-256
`9490526abc27b5a5e57f931613b027d1deeb72ae22787f5bf4189265f389660f`.

| Check | Result |
|---|---|
| Native foundations and reduction/cache/scope regressions | Passed |
| Existing metatheory proof suite | Passed, 195 build jobs |
| Companion proofs | 84/84 files passed |
| Tutorial | 141 correct verdicts, zero declines |
| Historical bugs | 18 correct rejections, zero accepts or declines |
| Fresh 4.35 Prelude | Accepted; 65,406 records / 1,840 declarations / 2,121 constants; 0.62 s |
| Fresh 4.35 UTF8 closure | Accepted; 159,345 / 2,146 / 2,353; 8.50 s |
| Fresh 4.35 XOR closure | Accepted; 333,731 / 3,413 / 3,752; 14.57 s |
| Fresh 4.35 Int64 closure | Accepted; 16,206 / 405 / 497; 0.21 s |
| Full historical Init | Timeout at 500.023 s; last progress 2,099,999 records / 17,010 declarations |
| Full historical Std | Timeout at 590.011 s; last progress 2,599,999 records / 19,259 declarations |
| Mathlib | Skipped because Init and Std gates failed |

The diagnostic Init job exits its checker with timeout code 124 after 600
seconds, although the workflow step succeeds to preserve its logs. Its last
entered declaration was record 4,188,018, `BitVec.getLsbD_srem`; maximum RSS
was 518,552 KiB. An entered declaration is not a completed check.

Timing/progress varies substantially across cloud runners: the runtime-equivalent
`d9b2e3e2da53406aeb727c05333f9ae0fe8e6127` run reached 3,199,999
Init records at its 500-second limit, and the same executable at
`dd354f30135b006f2f8342c866d82263d432b343` took 24.75 seconds for XOR
and 0.36 seconds for Int64. The two commits after d9b changed only proof files;
the dd354 and final e8ed native binary hashes agree. These measurements
establish focused acceptance and continuing corpus timeouts, not a stable
whole-corpus speedup.

The original migration checkpoint at
`05542332ab589314917cd67a7eb7b74e80557770` is retained as history in the JSON
receipt. Its 17-rejection/one-decline bug result and XOR reduction-budget
failure are superseded by the checks above. No merge, default-provider
promotion, selected-compiler change, joint self-host qualification, or
end-to-end consistency result is included.

That was the earlier requested stage boundary. Subsequent user authorization
started the native architectural work described above. Full Init/Std/Mathlib
conformance, portable graph/backend qualification and telescope transport remain
open requirements; proof success or a green diagnostic workflow does not close them.


[bundle]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/CMakeLists.txt
[official]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/type_checker.cpp
[replace]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/replace_fn.cpp
[instantiate]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/kernel/instantiate.cpp
[con-ops]: https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Cached/ExprOpsC.lean
[con-nodes]: https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Cached/ExprNodes.lean
[con-main]: https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean
[nano-expr]: https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/expr.rs
[nano-tc]: https://github.com/ammkrn/nanoda_lib/blob/4c544ed4099c8227f07d5de77ad1e69fb0740a27/src/tc.rs
[l4l]: https://github.com/digama0/lean4lean/blob/bce3448115f7819fc12d647fadd3bb090666637e/Lean4Lean/TypeChecker.lean
[l4l-eq]: https://github.com/digama0/lean4lean/blob/bce3448115f7819fc12d647fadd3bb090666637e/Lean4Lean/EquivManager.lean
[eq-fix]: https://github.com/leanprover/lean4/pull/14806
[ron-readme]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/README.md
[ron-store]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/crates/con-ron-core/src/arena/store.rs
[ron-ops]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/crates/con-ron-core/src/arena/expr_ops.rs
[ron-capstone]: https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/proof/ConRon/Capstone.lean
[paper]: https://arxiv.org/html/2403.14064v1
[postmortem]: https://leodemoura.github.io/blog/2026-8-1-postmortem-for-kernel-soundness-bug-14576/
[psc0-guide]: ../../docs/selfhost-language/CURRENT.md
[trace]: https://github.com/dwijayuda/pskernel/actions/runs/37986278855
[open-experiment]: https://github.com/dwijayuda/pskernel/actions/runs/37986835891
[profile-report]: https://github.com/dwijayuda/pskernel/actions/runs/37989139275
[samples]: https://github.com/dwijayuda/pskernel/actions/runs/37988687879
[traversal-experiment]: https://github.com/dwijayuda/pskernel/actions/runs/37988845542

[persistent-map]: https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Data/PersistentHashMap.lean
