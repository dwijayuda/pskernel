# Reference checker and the full correctness target

Status: shared raw/annotated storage, actual reference local-variable readings,
constructed binder contexts and production sort-visit provenance validated.
Public annotation transport, full recursive/admission soundness and relative
consistency remain unfinished.

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

## Prior runtime-representation evidence

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

The annotated syntax, universe-regime test and guarded structural comparator
now have a single owner in runtime Core. The model imports those exact
operations. Their structural equivalence and transport through lifting,
substitution, free-name closing and universe instantiation are proved, together
with hereditary-validity transport. The application bridge fixes one concrete
term/result reading with all four validity facts under explicit recursive and
guard premises. Public checking and admission still exchange raw expressions;
carrying and validating these annotations throughout those paths is unfinished.
See [the work state](AI_WORK_STATE.md) and
[the continuation prompt](AI_CONTINUATION_PROMPT.md) for an exact handoff.

## Prior lambda-codomain evidence

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

The earlier cache-isolation and executable receipts remain historical:

- [Final proof run 38034714932](https://github.com/dwijayuda/pskernel/actions/runs/38034714932),
  `f635419041d4a2e0da133c5c5b6c24fdaa2d3ce0`: 238 build jobs and all
  84 companion files passed. The semantic axiom gate checked 136 declarations;
  the pure-math import fence checked a 124-module closure containing exactly
  12 allowed Con Leche mathematics modules, zero legacy-judgment imports and
  zero production assurance imports.
- The same build's reference policy audit traced 1,821 definitions with zero
  cached-default fallbacks or raw cache bypasses. Its structural scope is
  distinct from semantic soundness.
- [Native tests at 6b7395c1](https://github.com/dwijayuda/pskernel/actions/runs/38033599176)
  passed the existing executable suites and the new poisoned-cache, binder,
  admission and exhaustion cases. That run's proof step failed; the final
  proof run above repairs it. No runtime source changed between these runs.
- [Arena at c0c02dd2](https://github.com/dwijayuda/pskernel/actions/runs/38034307491)
  passed 141/141 tutorial and 18/18 bugs with zero declines in **each** mode,
  using one binary and the pinned historical corpus. These are small-suite
  verdicts, not a proof of mode equivalence or full Mathlib conformance.

The correctness workflow runs proofs on its push trigger. Its manual
`runtime_checks` option additionally runs native regressions and both small
Arena modes plus focused exact Lean 4.35 exports. Full-corpus performance is not a gate for this milestone.

## Recovery point

Before shared local storage and sort-visit integration, checkpoint
`checkpoint/pskernel-core-before-owned-acceptance-20261010`
at **4a162b2056658155001828d0c17a426b000a3a2d**.

Before the runtime representation migration, checkpoint
`checkpoint/pskernel-core-before-runtime-annotations-20261010` was created at
`0c7f63b446bfd4b0847ece437b76bccd40ac3fb9`.


Before adding checked lambda codomain certification, checkpoint
`checkpoint/pskernel-core-before-lambda-sort-evidence-20261010` was created at
`ffd56473b9c42ff641a29e94094920e3322c4fef`.

Before simplifying lambda inference, the recovery branch
`checkpoint/pskernel-core-before-lambda-type-simplification-20261010` was created
at `5e3fa749d18441d7d35d1be9555c93cad78974cb`.

Before checked-annotation work, a second recovery branch
`checkpoint/pskernel-core-before-checked-annotations-20261010` was created at
`9943eed674b6de039e70fdde355aad248a6bfff4`. It preserves the previously validated
binder/function stage and its documentation.


Before this refactor, the remote branch
`checkpoint/pskernel-core-before-cache-free-reference-20261010` was created at
`32fb55d651cc8228794216ae298872978f3be0f9`. The code beneath that documentation
head was validated at `1442f3242dea69ac50a6020cca4ebf7fd5cbc1cd`.
The checkpoint preserves the existing implementation, proofs, test configuration,
and performance evidence. Rollback should start a recovery branch from that
commit or revert the subsequent changes; no force-push is necessary.

Lambda inference now closes its recursively inferred body type directly. The
extra cheap-beta normalization of that type was removed from the shared
production branch in both cache modes and both inference modes. The lambda
model bridge therefore no longer assumes preservation by that extra pass.
`SemanticValidityScope.lean` transports both hereditary invariants across
scoped environments and fresh-variable closing; the returned lambda type
inherits them under explicit recursive and regime premises. Let-body
normalization and ordinary WHNF/beta reduction are unchanged.

This removes one operation and its proof obligation. It does not establish
checked annotation provenance, recursive checking soundness, or consistency of
the full kernel. The new checked lambda bridge derives its level from actual codomain-sort
visits; their recursive soundness and global annotation coherence remain open. No new axiom or stronger foundation assumption was
added.

Checked lambda inference now obtains its codomain sort from an additional
infer-only visit to the actual body type followed by sort exposure. The
reference lambda trace records these calls. The new
`lambda_trace_checked_reading` theorem fixes that actual level on both the
lambda and its returned type and proves typing plus their four hereditary
validity facts under the local recursive obligations. It no longer asks for an
arbitrary lambda level or a separate proof-valued-fibre premise.

This certification runs in the shared checked lambda rule in both cache modes.
Infer-only retains its validity precondition, and cached hits retain their
separate cache invariant. Non-resource certification failures decline;
resource failures keep their resource classification. Globally coherent
annotations through raw comparison, joint recursive soundness, and full safe
admission remain open. The public API does not yet return or carry a complete
validated annotated expression.

## Architectural decision

Maintain one set of checking and admission rules. Parameterize its semantic
cache operations using `PsKernelSemanticCachePolicy`. The policy contains only
a Boolean; it cannot supply an arbitrary inference or equality oracle.

The existing default policy enables memoization. The reference API supplies the
disabled policy explicitly through the recursive checker, its callbacks,
sessions, and ordinary/mutual/nested declaration admission. Disabled map/pair
lookups always miss, even for a poisoned incoming state. Insertions return their
input cache unchanged. Structural operations, expression sharing, environment
indexes, fresh-name allocation and resource checks remain in use.

This is semantic cache erasure, not a second hand-maintained checker. The
checker-state representation still has dormant cache fields. A later proof may
quotient reference states by their fresh-name counter; that whole-checker state
independence theorem is not claimed by the operation-level no-op equations.

`API/Reference.lean` fixes the disabled policy at each entry point.
The Arena host exposes `--reference` and `--reference-historical`; ordinary
invocation retains the existing cached mode. There is no fallback to another
kernel and no default-provider promotion.

`ReferencePolicyAudit.lean` inspects elaborated definitions reachable from the
reference API. It rejects the cached default and direct bypasses of the four
cache gates. This is a structural regression audit, not a semantic theorem.
The mathematical audit continues to reject custom axioms and `sorryAx`.

## Why this boundary

Deleting every acceleration would also discard proved syntax-operation
refinements and could cause repeated traversal of shared terms. Keeping those
exact-result refinements while disabling semantic result reuse removes a
distinct class of proof obligations with a smaller implementation change.
A duplicated checker would introduce a second algorithm to maintain and relate.
The fixed-policy specialization avoids that duplication.

The policy is selected at the public reference entry point. An arbitrary caller
cannot supply an oracle through the policy: its only data is a Boolean. The
existing cached API is still explicitly outside the first reference soundness
claim. This does not make the native compiler/runtime or input adapter verified.

## What this saves, and what it does not

Reference-mode soundness need not establish the truth of cache hits, publication
invariants, mode compatibility of stored results, or reuse across local scopes.
The first concrete sort and constant inference bridges therefore have no cache
coherence hypothesis. Constant inference still requires a model of the selected
environment declaration at its actual universe instantiation.

The difficult logical obligations remain: validated annotations, well-scoped
contexts, the infer/reduce/equality recursion, safe inductive and quotient
admission, and preservation of the statement presented to the public API.
Removing memoization does not solve any of these by itself.

Fuel remains a resource bound. A success theorem is conditional on successful
execution, for every supplied fuel. Cached and reference executions need not
have identical resource use or timeout outcomes. Cache-mode equivalence and
full-library performance have not been proved or measured by this refactor.

## Research basis

- Con Leche deliberately adds checked binder annotations and selected argument
  checks to make direct set-model soundness easier than a full syntactic
  metatheory of an unchanged Lean kernel:
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/README.md
- Its annotation validity is established at actual checker visits. It explicitly
  warns against assuming that every inferred type has a sort at arbitrary
  application/equality crossings:
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/Model/Annot/Valid.lean
- Its accepted-environment theorem has an explicit set-theory parameter:
  https://github.com/leanprover/con-leche/blob/65e74db49e89ad2bbd1e90aa4f784954db41fa3a/ConLeche/MainTheorem.lean
- Con Ron separates representation/caching changes from a reference algorithm
  through simulation proofs. Its translation and execution boundaries remain
  explicit:
  https://github.com/leanprover/con-ron/blob/64a2172a01276aa049220200bac11c075316230f/README.md

These are design precedents, not imported evidence that PSKernel is sound.
The existing Con Leche dependency remains restricted to pure set mathematics.
No upstream checker or acceptance theorem is used as a PSKernel proof.

## Required milestones

1. **Reference cache isolation — validated.** Fixed public entry points; policy propagation
   through all checking/admission calls; kernel-checked miss/no-op equations;
   poisoning, binder, declaration and exhaustion regressions. Preserve all
   existing default-mode proof statements and behavioral tests.
2. **Validated semantic readings — in progress.** Hereditary annotation/function
   transport and local forall/application/lambda execution bridges are proved.
   Symbolic annotation agreement now has an executable exact decision procedure,
   semantic soundness and actual sort-visit bridges. The checked lambda rule now computes its codomain sort, and its model bridge
   chooses that actual level. The public raw comparator still does not invoke
   the agreement guard or carry globally coherent validated readings.
   Connect actual checked terms to coherent
   Prop/Type binder annotations under all legal universe substitutions. Establish
   frame/freshness and hereditary validity where infer-only operations need them.
   Use the existing counterexamples as requirements: equal raw erasures and
   semantic membership alone do not establish annotation coherence.
3. **The recursive reference checker.** Prove successful checked inference,
   infer-only inference under its validity premises, WHNF and equality against
   the same model. Cover projections, primitive reductions, function/structure
   eta, proof irrelevance and recursor dispatch. Do not assume algorithmic
   equality transitive, total, or a generally valid subject-reduction theorem.
4. **Environment construction.** Prove definitions, theorems and opaques preserve
   an environment model; justify accepted axiom interpretations; prove positivity,
   generated eliminators, universe constraints, ordinary/mutual/nested inductives
   and quotients. Interpret constants at every admitted universe assignment.
5. **Public acceptance and relative consistency.** Connect the actual reference
   declaration fold and input translation to the original statements. From a
   modeled initial environment and justified axioms, successful safe checking
   must produce a modeled environment, with the intended False empty.
6. **Optimized refinement, separately.** If needed, prove cached acceptance
   refines the reference algorithm or establish its own model invariant.
   Performance is not an exit condition for milestones 1–5.

A theorem about arbitrary axiom declarations cannot imply unconditional
consistency: the raw API can be asked to declare an axiom of False. The final
claim must state an axiom policy or a model hypothesis for those axioms.
Existence of the current set-theoretic universe hierarchy is also an explicit
relative assumption, not a newly hidden soundness axiom.

## Earlier local results and continuing recursive obligations

The six modules documented in
[the binder/function proof boundary](RESEARCH_AND_MIGRATION.md#binder-and-function-proof-boundary--2026-10-10)
establish annotation/function validity transport and exact successful
forall, checked application and checked lambda traces. Forall validity is built
from the actual visited sort checks. Application follows its actual comparison
route. Lambda follows its directly inferred body type and actual fresh-name
closing. Each semantic bridge exposes its remaining recursive hypotheses.

The new checked counterexample
`hereditary_validity_not_erasure_coherence` rules out using the conjunction of
the hereditary predicates as a replacement for checked annotation provenance.
Even both predicates plus identical raw syntax do not determine a unique
interpretation over an empty domain.

The checked-annotation layer now supplies an executable sufficient guard for
structural comparison. It decides whether two binder annotations have the same
zero condition for every universe-parameter and metavariable assignment,
preserves that agreement through universe substitution, and derives semantic
regime agreement on successful guarded comparison. It also validates annotations
against actual sort-exposure visits and characterizes the existing native
positive-universe test exactly.

The executable representation and guards now live in runtime Core, with
coherence and validity transport proved in metatheory. Public raw-expression acceptance
does not yet run the extra guard or produce validated annotations. Recursive
typing/reduction/equality, global annotation coherence and full admission
soundness remain open. No new axiom or stronger foundation assumption was added.

The next task is to derive coherent readings from checker visits across the
joint inference/reduction/equality recursion, including type exposure and
infer-only preconditions. The invariant must describe the particular readings
produced by checking, including their annotations, type validity, scope and
free-variable context. Existence of an arbitrary positive annotation is
insufficient: it would make the proof-regime premise vacuous while failing to
justify later comparison and proof-irrelevance steps. In particular, discharge the application bridge's
structural `RegimesAgree` premise at its actual accepting path and the lambda
bridge's recursive type-of-body-type obligations at its new codomain-sort
visit. The selected level is now fixed by execution in
`lambda_trace_checked_reading`. The extra lambda body-type reduction was
retired; its preservation premise is no longer part of the current bridge. `checkedExprEq_sound` now
removes the former semantic premise when its executable guard succeeds, but the
public raw comparator's success alone does not imply that guard succeeded.
Use the actual checked lambda codomain visit, rather than assuming every
inferred type has a sort. Infer-only still needs its validity preconditions.
Extending annotation validation across other operations must keep the exact
execution, failure/decline classification, and pinned Lean conformance visible.

The economical claim is successful-checking soundness and relative consistency.
Strong normalization, totality of every equality run, equality completeness,
and exact timeout parity are separate claims and are not prerequisites for
that endpoint. A request for all traditional metatheorems would be broader.
Lean compatibility is tracked independently: stricter justified validation may
decline cases, and those declines must stay visible in the conformance results.

## Completion evidence

Full correctness requires the actual reference acceptance theorem with all
internal callback, annotation, cache and environment-admission premises
discharged. Only mathematical foundation/initial-environment/allowed-axiom
assumptions may remain as documented. Fragment theorems, source audits, passing
Arena tests, or a nonempty model interface do not meet that criterion.

The target remains Lean 4.35.0-rc4 at
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
PSC0 generated execution and compiler/runtime correspondence remain separate
qualification obligations. The current executable evidence is Lean-native.
