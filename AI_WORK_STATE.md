# AI Work State

## Repository
- Canonical repository: `dwijayuda/pskernel`
- Proof branch: `pscv/prove-pskernel-core-v1`
- Integration branch: `psc2/selfhost-lean-kernel`
- Current proof implementation checkpoint before this state commit: `ca57738b7248b0cb4884fb2cc59745e0a8af21c1`.
- Last green package proof checkpoint: `ca57738b7248b0cb4884fb2cc59745e0a8af21c1` (run #476).
- Run #476 is green for the callback-driven ordinary/Quot recursor configuration/refinement composition. The ordinary reducer now has an explicit prefix dispatcher, independently proved iota tail semantics, and a named optional-reduction postcondition that prevents executable-success proof terms from leaking into semantic theorem types.
- Run #456 remains the earlier green checkpoint for the independent ordinary recursor iota/rule-search metatheory, including executable recursor-rule search refinement.
- Run #420 is green for the registered beta substitution/lowering algebra.
- Run #438 is green for the complete `PsKernelBetaSpineSoundLaw`: the optimized multi-lambda `InstantiateRev` path refines ordinary beta-reduction closure and is no longer an unresolved WHNF assumption.
- Run #381 is green: the registered `WhnfCoreConfiguration.lean` fuel induction and its public `false/false` specialization compile on the full package proof gate.
- Run #396 is green: complete primitive-Nat refinement, `psKernelReduceNatWith` optional-reduction soundness, post-core native/Nat/delta/cache composition, and `psKernelWhnfWithFuel_configuration_sound_contract` all compile as registered metatheory.
- Run #328 validated the eager-reduce context transport fix.
- The checked-inference fuel proof now closes projection recursion through the smaller-fuel induction hypothesis and configuration-aware projection semantics.
- Checked projection is fully registered and green as of run #346.
- `Metatheory/ProjectionReduction.lean` is registered and proves successful `psKernelReduceProjCore` computation refines an independent projection reduction rule under environment-index refinement.
- `Metatheory/CheckerComposition.lean` exposes importable public checked/infer-only wrapper contracts.
- Optional-reduction and recursor-reduction configuration contracts plus the explicit native-reduction TCB law are available for the WHNF checker-knot phase.
- Current integration HEAD last observed: `cae6b6d5fb3d50138889e1aeb74436e7b5ea5316`
- Workflow: GitHub-first only. Do not depend on local/Desktop Commander state.

### Reconciled Arena semantic fixes — 2026-10-07
The Arena/Mathlib lane remains on `pscv/pskernel-core-arena-v1`, but confirmed
production-kernel fixes are reconciled into this proof branch promptly. Arena
transport, hosted-runner workarounds, historical metadata replay, and the
high-fuel empirical compatibility profile remain isolated from the verified
kernel source.

Confirmed fixes now present in this branch:
- **Semantic-cache fvar scope:** reject semantic-cache keys containing fvars;
  this was discovered by metatheory and fixed earlier.
- **Lean-compatible universe max normalization:** distribute a common successor
  offset across normalized `max` branches. Arena first exposed this through
  `Functor.mk`; the exact Functor universe shape is locked by a differential
  regression.
- **Mutual recursive-argument checker fuel:** structural traversal fuel and
  checker/WHNF fuel are now separate. Arena exposed the defect on the nested
  `Lean.Syntax` declaration; the focused multi-unfold regression is green.
- **Raw constructor Pi spine:** ordinary and mutual constructor admission no
  longer WHNF the outer constructor spine to manufacture binders. Binder
  domains may still be checked/reduced as Lean requires. Upstream Lean Kernel
  Arena Tutorial moved from 140/141 to **141/141** after this fix. Proof-side
  equations lock rejection/preservation for non-raw-Pi constructor spines.

Empirical validation for the reconciled semantic source:
- full pinned `Init.Prelude`: accepted;
- upstream Arena Tutorial: **141/141 correct**, zero false accepts/rejects;
- historical bug corpus before historical-metadata replay: zero false accepts
  among evaluated cases; current host-only replay/classification work is
  intentionally not merged into this proof branch.

The full package proof gate is green at run #476. The ordinary recursor prefix
transport/composition frontier is closed. The reconciled constructor/level/
mutual-analysis source modules compile successfully and do not introduce a new
proof blocker. The next semantic frontier is concrete K/structure conversion
soundness plus bounded recursor/checker-knot fuel composition.

## Acceptance criteria
The work is complete only when all of the following hold:

1. **Mechanical closure**
   - Every canonical `pskernel-core/src/**.lean` source has its canonical proof companion.
   - The full recursive PSKernel Core proof gate is green from the final proof HEAD.

2. **Semantic/refinement closure**
   - The Assurance Plane contains independent semantic/refinement judgments for typing, reduction, non-transitive algorithmic definitional equality, environment/history, cache/state soundness, declaration admission, and inductive admission.
   - Canonical modules are upgraded from shallow/control evidence to semantic/refinement evidence where meaningful.
   - Remaining true trust assumptions are explicitly named TCB boundaries rather than hidden assumptions.

3. **Concrete checker soundness**
   - The concrete mutually recursive checker implementation discharges the final configuration/stateful contracts:
     - checked inference returns a typed result and preserves configuration soundness,
     - infer-only preserves configuration soundness,
     - WHNF/reduction returns a valid reduction and preserves configuration soundness,
     - true DefEq is sound and preserves configuration soundness.
   - Cache publication, presentation equality, context extension/weakening, freshness, environment-index refinement, recursion-depth/configuration obligations needed by the knot proof are discharged.

4. **Admission soundness**
   - Successful ordinary declaration admission refines a well-formed semantic environment extension.
   - Quot admission refinement remains closed.
   - Ordinary, mutual, and nested inductive admission/recursor/flatten-restore transaction semantics are connected to explicit Assurance Plane predicates/judgments.

5. **Public composition**
   - Public Kernel/API/session success is connected to the concrete checker/admission soundness theorems, not merely abstract assumptions.
   - A final explicit implementation-refinement theorem/family makes the kernel soundness claim auditable.

6. **Integration reconciliation**
   - Re-sync/rebase/merge the proof work against the current integration branch without discarding proof work.
   - Re-run the full proof/conformance gates after reconciliation.
   - Update the semantic audit to the final state.

## Current semantic audit
Last checked-in audit:
- A: 44
- B: 9
- C: 19
- D: 7
- Total canonical source/proof pairs: 79

The audit is conservative relative to newer cross-module checker-contract/context work. Do not inflate module grades without applying the written A/B/C/D criteria.

## Current checkpoint
- Checked inference + checked projection remain fully registered and green.
- Run #348 green: contextual reduction closure and reduction-congruence metatheory registered.
- Run #350 green: application-spine reconstruction induction validated.
- Run #352 green: string-literal representation reduction plus the optimized beta-spine contract validated.
- Run #354 green: generalized WHNF finish success/refinement helpers validated.
- Run #355 green: optimized beta-spine contract strengthened with the required nonempty application-spine premise.
- Subsequent WHNF work introduced and registered factored application/projection refinement modules plus WHNF-core composition scaffolding.
- Run #369 failed on two localized proof-alignment classes: projection expansion/canonical-result equations and application reduced-head specialization.
- Commits `df33416c...`, `06e70249...`, and `04df1f14...` canonicalize projection expansion consumption and specialize both executable-success and semantic-head handoffs across every WHNF head shape.
- Runs #371-#379 progressively isolated WHNF branch equation alignment; no production semantic defect was found.
- Run #380 is green: `WhnfCoreApplication.lean` and `WhnfCoreProjection.lean` compile together after naming the application-tail operational runs and mirroring production control flow.
- WHNF core is now split into independent Assurance Plane modules for application and projection refinement instead of one monolithic proof.
- `WhnfCoreConfiguration.lean` is registered as a metatheory root and owns the composed fuel induction. It exposes the `false/false` core specialization consumed by public WHNF.
- `PrimitiveNatReduction.lean` now proves the full Nat primitive table, Nat constructor/literal normalization, `psKernelReduceNatWith` state preservation, semantic success refinement, and the optional-reduction configuration contract.
- `WhnfConfiguration.lean` is registered and green. It proves post-core composition and the full public WHNF fuel theorem under explicit recursor, beta-spine, and native-reduction contracts. Native reduction remains an intentional TCB law; beta-spine is now discharged by the green run #438 theorem, leaving concrete recursor soundness as the remaining WHNF knot dependency.
- The semantic audit remains conservatively A=44/B=9/C=19/D=7 until a criteria-based refresh after concrete checker closure.

## Current blocker
Confirmed production-kernel semantic defect:
- Local-scope fvar escape through semantic caches, fixed by `0263c550ec65f558575afd3396ee95a1de168237` and now covered by the green run #312 migration.

Immediate blocker:
- beta-spine is closed: run #438 validates `PsKernelBetaSpineSoundLaw` as a real proof obligation, not a TCB assumption;
- quotient reduction and ordinary recursor iota/rule-search semantics are modeled independently; callback-driven `psKernelReduceInductiveRecWith` and `psKernelReduceRecursorWith` configuration/refinement composition are now green in run #476;
- the next recursor dependency is concrete helper soundness for K-like conversion and non-recursive-structure conversion, followed by `PsKernelRecursorReductionConfigurationSound` for `psKernelReduceRecursorBoundedWithFuel`;
- K/structure conversion must be connected to explicit independent semantic evidence rather than treated as syntactic identity. Lean's K flag is restricted to Prop-valued, single-constructor, zero-field inductive predicates; structure conversion is the non-Prop structure-eta path;
- after helper semantics, build the shared smaller-fuel recursor/WHNF/inference/DefEq knot, instantiate the green public-WHNF theorem, then close concrete DefEq.

Architectural blockers still remaining:
- compose the already-proved checked/infer-only core and public-wrapper contracts with concrete WHNF/DefEq components in the checker knot;
- close public WHNF and concrete DefEq configuration/stateful contracts for the mutually recursive checker knot;
- finish remaining DefEq final/lazy-delta/eta/proof-irrelevance and recursor/iota semantics;
- complete ordinary/mutual/nested inductive transaction refinement;
- compose the concrete checker/admission theorems into the final public implementation-refinement theorem/family;
- reconcile against current integration, rerun final proof/conformance gates, and refresh the semantic audit.

## Immediate plan
1. Prove concrete state/configuration + independent semantic contracts for `psKernelToConstructorWhenK`, `psKernelRecursorIsPropWith`, and `psKernelToConstructorWhenStructure`; model K/structure conversion in the Assurance Plane without restating executable success.
2. Instantiate the green callback-driven recursor theorem for `psKernelReduceRecursorBoundedWithFuel` using one shared fuel/configuration induction over the smaller-fuel WHNF/core-WHNF/inference/DefEq dependencies.
3. Instantiate the public WHNF contract in the concrete checker knot using the proved beta-spine law and bounded recursor theorem.
4. Close remaining concrete DefEq configuration/stateful soundness obligations, prioritizing LazyDelta, FinalRules, eta/proof-irrelevance, recursor computation, and success/failure cache paths.
5. Compose the mutually recursive checker knot and discharge the abstract assumptions already consumed by API/session refinement theorems.
6. Complete ordinary/mutual/nested inductive admission transaction semantics and environment-extension refinement.
7. Add the final explicit implementation-refinement theorem/family, refresh the semantic audit, reconcile against current integration, and rerun the full proof/conformance gates.

## Work discipline
- Preserve GitHub history and concurrent proof work.
- Refresh the real branch tip through GitHub before every write if concurrent work may have landed.
- Prefer dependency-guided reusable lemmas and structural/fuel induction over test/fix hunting.
- Do not change production `pskernel-core/src/**` merely to make proofs easier. If a proof exposes a real implementation defect, document it and make the smallest semantically justified source fix.
- Commit meaningful checkpoints and keep this file updated as milestones/blockers change.

## Confirmed implementation defect: local-scope cache escape
- Proof analysis of the concrete checker knot exposed a PSKernel-specific mismatch with pinned Lean 4.34 cache assumptions.
- Lean 4.34 shares checker caches across local-context scopes because kernel free-variable IDs are globally unique internal identities and `infer_type_core` has a closed-input precondition.
- PSKernel represents `.fvar` IDs as structurally forgeable `PsKernelName` values and its raw checked-expression/session surface can receive such expressions.
- Prior behavior allowed semantic caches to contain expressions mentioning fresh child-scope fvars and later query them outside that scope.
- **Source fix committed:** `0263c550ec65f558575afd3396ee95a1de168237`.
- The fix introduces one shared semantic-cache eligibility policy rejecting keys containing any fvar and applies it consistently to:
  - inference cache lookup/publication,
  - WHNF-core cache lookup/publication,
  - public WHNF cache lookup/publication,
  - delta/unfold cache lookup/publication,
  - DefEq success-cache lookup/publication,
  - DefEq failure-cache lookup/publication.
- Cache-policy regression proofs cover direct and nested fvar keys plus pair-cache ineligibility.
- Run #304 is the first full proof-tree validation of the source fix.
- Do not weaken `PsKernelCheckerStateSemanticSound` to hide cache-scope issues.
