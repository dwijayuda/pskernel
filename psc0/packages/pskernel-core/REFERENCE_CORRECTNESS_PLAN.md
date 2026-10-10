# Reference checker and the full correctness target

Status: reference cache isolation, local binder/function model bridges, and
checked symbolic annotation agreement validated. Public annotation provenance,
full-kernel metatheory and relative consistency remain unfinished.

## Validated evidence

[Proof run 38050725364](https://github.com/dwijayuda/pskernel/actions/runs/38050725364) at
`06a488e20f9ae0215d1c77e94a195b9e988f072c` passed **247 build jobs**, all **84 companion files** and the
**212-declaration** semantic axiom audit. The **133-module** dependency closure
contains only the 12 allowed Con Leche pure-math modules, with zero legacy
judgment or production assurance imports. The reference-policy audit again
checked **1,821 definitions** with zero cached-default fallbacks.

The earlier cache-isolation and executable receipts remain:

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
Arena modes. Full-corpus performance is not a gate for this milestone.

## Recovery point

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
   semantic soundness and actual sort-visit bridges. The public checker does not
   yet invoke this guard or produce validated annotation readings.
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

## Current local results and smallest next proof task

The six modules documented in
[the binder/function proof boundary](RESEARCH_AND_MIGRATION.md#binder-and-function-proof-boundary--2026-10-10)
establish annotation/function validity transport and exact successful
forall, checked application and checked lambda traces. Forall validity is built
from the actual visited sort checks. Application follows its actual comparison
route. Lambda follows its cheap-beta-reduced body type and actual fresh-name
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

These operations are assurance infrastructure. Public raw-expression acceptance
does not yet run the extra guard or produce validated annotations. Recursive
typing/reduction/equality, lambda body-type preservation and full admission
soundness remain open. No new axiom or stronger foundation assumption was added.

The next task is to derive coherent readings from checker visits across the
joint inference/reduction/equality recursion, including type exposure and
infer-only preconditions. In particular, discharge the application bridge's
structural `RegimesAgree` premise at its actual accepting path and the lambda
bridge's regime and body-type reduction premises. `checkedExprEq_sound` now
removes the former semantic premise when its executable guard succeeds, but the
public raw comparator's success alone does not imply that guard succeeded.
Do not infer a body-sort visit that lambda inference never performs, or assume
every inferred type has a sort. If explicit runtime
annotation validation is needed, it must be specified, proved, and checked
against the pinned Lean corpus with any declines visible.

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
