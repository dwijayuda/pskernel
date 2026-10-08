# AI Work State

## Repository
- Canonical repository: `dwijayuda/pskernel`
- Proof branch: `pscv/prove-pskernel-core-v1`
- Integration branch: `psc2/selfhost-lean-kernel`
- Current proof implementation checkpoint before this state commit: `a381b2b330ba632c0a4cd920a514f06d46d14f53`.
- Last green package proof checkpoint: `a381b2b330ba632c0a4cd920a514f06d46d14f53` (run #538).
- Run #485 is green for the refactored Assurance Plane: reduction/DefEq/typing/projection judgments coexist in one uniform environment-indexed mutual block, recursor iota carries explicit major-conversion evidence, context weakening is an explicit admissible semantic rule, and projection consumers remain source-compatible.
- Run #476 is green for the callback-driven ordinary/Quot recursor configuration/refinement composition. The ordinary reducer now has an explicit prefix dispatcher, independently proved iota tail semantics, and a named optional-reduction postcondition that prevents executable-success proof terms from leaking into semantic theorem types.
- Run #538 is green for the current concrete DefEq foundation: scoped lambda/forall binder comparison restores parent semantic caches on scope exit; binder-spine configuration/refinement is registered; Quick DefEq configuration soundness is registered; and the symmetric function-eta metatheory is registered and compiles together with the checker stack.
- Confirmed Arena function-eta fix `0dd5d4db43a78be020f2257c226761ef4849d763`: full-shape DefEq now routes lambda/non-lambda in both orientations. `DefEqEtaConfiguration.lean` proves left-eta and right-eta configuration/refinement plus generic bidirectional full-shape routing; companion regressions cover app/const ↔ lambda shapes. Arena evidence: focused Init/Std targets green, Tutorial 141/141, soundness/readiness green.
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

## Latest checkpoint — 2026-10-07
- Current proof HEAD before this state update: `e5b17a28885149065e37dcd93afb9e3514e62301`.
- Last completed green full proof gate: run **#510** at `10bf4a71fad2f158667406505ef3a67df34c63cc`.
- Run #503 independently validated the reconciled production **symmetric function-eta** fix `0dd5d4db43a78be020f2257c226761ef4849d763`.
- Concrete K conversion, non-recursive structure eta conversion, bounded recursor configuration, and recursor-aware public/core WHNF callback contracts are now proved and registered; runs #499, #502, and #503 are green checkpoints for that closure.
- The Assurance Plane now has explicit left/right function-eta algorithmic judgments. Proof commits `5d8bda7c...` and `6c32bf27...` add symmetric eta-helper refinement plus bidirectional application/constant full-shape dispatch locks.
- The experimental lambda-spine configuration proof was rolled back to its last green proof blob only; the production binder-scope cache restoration fix `d991e72d...` and its semantic judgment changes remain.
- Run **#521** is queued for the combined eta/metatheory state because the parallel `PSKernel Core Arena Init Std` job currently occupies the available runner. This is CI scheduling, not a known proof failure.
- Current semantic frontier: concrete DefEq configuration/state soundness (binder spines, quick/full-shape, proof irrelevance, eta/final rules, LazyDelta, cache publication), then concrete checker-knot composition and admission refinement.
- Later full Init/Std Arena discrepancies remain unclassified; do **not** change metatheory for them unless the Arena lane confirms a production semantic defect.

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
- **Symmetric function eta:** `psKernelDefEqFullShapeWith` now checks the
  right-lambda eta case before non-lambda left-shape dispatch can return.
  This matches Lean 4.34 in both directions and fixes the confirmed false
  rejections `Std.PRange.UpwardEnumerable.succMany?_add` and
  `Nat.Internal.Linear.Expr.denote_toPoly_go`. The Assurance Plane records
  separate left/right eta rules and full-shape regression equations for both
  partial-application orientations.

Empirical validation for the reconciled semantic source:
- full pinned `Init.Prelude`: accepted;
- upstream Arena Tutorial: **141/141 correct**, zero false accepts/rejects;
- historical bug corpus before historical-metadata replay: zero false accepts
  among evaluated cases; current host-only replay/classification work is
  intentionally not merged into this proof branch.

The full package proof gate is green at run #538. Ordinary/Quot recursor composition, concrete K/structure conversion, bounded recursor configuration, recursor-aware WHNF/core-WHNF callbacks, symmetric function eta, binder-spine configuration/refinement, and Quick DefEq configuration are all registered and green together. The next semantic frontier is full-shape/application DefEq, LazyDelta/final rules, and the concrete `psKernelIsDefEqWithFuel` checker-knot theorem.

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
- Run #485 validates the conversion-aware recursor foundation: `PsKernelReductionClosure.recursorIota` now consumes explicit major-conversion evidence rather than pretending all K/structure major changes are ordinary reduction; independent proof-irrelevance and structure-eta DefEq rules are represented in the Assurance Plane.
- `Metatheory/Inductive.lean` now contains independent raw constructor-Π spine judgments. Outer parameters/fields are consumed only from syntactic `forallE` structure, while parameter domains use ordinary DefEq and field domains use ordinary typing/universe semantics. The non-Π case returns the exact raw residual expression; no WHNF-manufactured binders are admitted by the specification.
- The semantic audit remains conservatively A=44/B=9/C=19/D=7 until a criteria-based refresh after concrete checker closure.

## Current blocker
Confirmed production-kernel semantic defect:
- Local-scope fvar escape through semantic caches, fixed by `0263c550ec65f558575afd3396ee95a1de168237` and now covered by the green run #312 migration.

Immediate blocker:
- recursor/K/structure/bounded-WHNF work is closed and green;
- confirmed symmetric function eta is formally incorporated in the registered Assurance Plane and green at run #538;
- binder-scope DefEq now restores parent caches with `psKernelCheckerStateExitLocalScope`; binder-spine configuration/refinement and Quick DefEq are green;
- next close full-shape/application congruence configuration/refinement, then reflection/LazyDelta/projection/full-WHNF/final rules;
- prove `PsKernelDefEqConfigurationSound (psKernelIsDefEqWithFuel fuel)`, then instantiate the already-prepared concrete WHNF/checker-knot composition.

Architectural blockers still remaining:
- compose the already-proved checked/infer-only core and public-wrapper contracts with concrete WHNF/DefEq components in the checker knot;
- close public WHNF and concrete DefEq configuration/stateful contracts for the mutually recursive checker knot;
- finish remaining DefEq final/lazy-delta/eta/proof-irrelevance and recursor/iota semantics;
- complete ordinary/mutual/nested inductive transaction refinement;
- compose the concrete checker/admission theorems into the final public implementation-refinement theorem/family;
- reconcile against current integration, rerun final proof/conformance gates, and refresh the semantic audit.

## Immediate plan
1. Prove application-spine/list DefEq refinement and compose the full-shape helper, reusing the green binder, Quick, and symmetric eta contracts.
2. Close reflection, LazyDelta/projection, proof irrelevance, structure eta, string expansion, and unit-like final-rule configuration/refinement.
3. Prove the concrete fuel induction for `PsKernelDefEqConfigurationSound (psKernelIsDefEqWithFuel fuel)`.
4. Instantiate concrete recursor-aware WHNF, checked inference, infer-only, and public checker contracts from the DefEq theorem.
5. Complete ordinary/mutual/nested inductive admission transaction semantics and environment-extension refinement.
6. Add the final explicit implementation-refinement theorem/family, refresh the semantic audit, reconcile against current integration, and rerun the final proof/conformance gates.

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


## Live DefEq checkpoint — 2026-10-07 late
- Live proof branch observed at `ab8121fa5b6230d82d7f382cc94a924a434f20b8`.
- Run #544 is green at `af35d856989942031040bb6d96d80a9661c688b9`; the follow-up commit registers `DefEqFinalConfiguration.lean`.
- Confirmed Arena function-eta fix `0dd5d4db43a78be020f2257c226761ef4849d763` is fully incorporated in the Assurance Plane: independent left/right eta rules, helper configuration/refinement in both directions, generic full-shape routing in both orientations, and app/const ↔ lambda regression locks.
- Concrete Quick, application, full-shape, reflection, binder-spine, K/structure-recursion, bounded recursor, and recursor-aware WHNF configuration layers are now present.
- Current DefEq frontier is the remaining final-rule family (structure eta fields/core, string expansion, unit-like equality, proof irrelevance), followed by lazy delta and the concrete `psKernelIsDefEqWithFuel` knot theorem.
- Metatheory correction to make during proof-irrelevance closure: `psKernelDefEqIsPropWith` classifies an expression by inferring its type and WHNF-reducing that inferred type to a sort; do not model this as the classified expression itself reducing to `Sort 0`.


## DefEq / LazyDelta verified checkpoint — 2026-10-08
- Last independently confirmed full proof gate: **#579**, commit `10f854bd41ae66688bb05c910ef67e66b635a72b`.
- Run **#578** is also green at `a7aa85153b97a057f51cdbef0485cfc8287f43fc`.
- The full final-stage continuation `psKernelIsDefEqAfterFullShape_configuration_sound` is registered and green. Eta-structure, string expansion, and unit-like equality are composed through explicit original-to-reduced closures, rather than unrestricted DefEq transitivity.
- `psKernelDefEqIsPropWith_true_refines` correctly observes the inferred type of the classified expression and reduces that inferred type to a `Sort`; it does not claim that the classified expression itself reduces to `Sort 0`.
- `DefEqLazyConfiguration.lean` is a new registered semantic module. Its terminal projection-finish theorem refines either a pair of computed projection fields or a major-term comparison to the independent projection DefEq judgment.
- `PsKernelDeltaStepPostcondition` and `psKernelDefEqFinishLazyStep_configuration_sound` are green: a positive lazy-step result has algorithmic DefEq evidence, while continue/unknown/different results carry only reduction closures.
- Current implementation frontier: transport and compose full delta-step operations (one-sided, two-sided, native/Nat branches), prove lazy reduction/projection fuel contracts, and then complete the concrete `PsKernelDefEqConfigurationSound (psKernelIsDefEqWithFuel fuel)` mutually recursive checker knot.
- Admission refinement, final public implementation-refinement theorem, semantic audit refresh, integration reconciliation, and final gates remain open.
- No additional production semantic defect was diagnosed in this checkpoint; no production source was changed for proof convenience.

## Lazy-delta assurance checkpoint — 2026-10-08
- GitHub remains canonical; refresh branch tip and CI before further proof writes.
- Latest independently green full proof gate before this checkpoint: run #588 at
  4330aa6c177f82bdaabdc5dec0e81775daaaf41f. Runs #584-#587 also green.
- Run #585 proves both one-sided lazy-delta steps, transporting positive DefEq
  over explicit projection/delta reduction closures.
- Run #586 proves both ordered reducibility-hint branches without transitivity.
- Run #587 proves psKernelDefEqArgsWithFuel_configuration_sound and wrapper:
  optimized argument comparison refines whole-expression DefEq only under
  independently supplied function-head equality.
- Run #588 proves normalized universe-list guards and name-equality soundness
  for same-definition lazy delta, with PsKernelStringEqSoundLaw explicit.
- Checkpoint 016b99f9d58b2c45e6e7b7a7352a2c3137ac117d adds definition
  lookup provenance and composes metadata, name and universe head guards.
  Its full CI was in flight when this state was authored: verify before claiming green.
- No production semantic defect confirmed, and no production source changed.
- Next: equal-hint optimized argument comparison, failure-cache configuration
  preservation, complete two-definition lazy-step result, then lazy step/fuel
  reduction and projection contracts.
- Later: concrete psKernelIsDefEqWithFuel soundness; mutually recursive
  recursor/WHNF/inference checker-knot proof; ordinary/mutual/nested admission;
  API/session implementation-refinement; audit refresh; integration and gates.
- Preserve non-transitive algorithmic DefEq. No sorry, axioms, hidden trust
  assumptions, acceptance weakening, or Arena host infrastructure leakage.

## Verified LazyDelta Nat frontier — 2026-10-08
- Proof run **#614** is green at `4383b3bf19c08de332741419fe257cc2dd448225`.
- The independent full LazyDelta step dispatcher, optional Nat reducer, and `psKernelDefEqLazyReductionAfterPred_configuration_sound` are registered and compile together.
- The eager-Nat computation is classified by the precise Boolean proposition for `eagerReduce` or absence of local fvars; no source semantics were changed.
- Next proof boundary: the Nat-successor predecessor fast path, complete `psKernelDefEqLazyReductionWithFuel` induction, and concrete DefEq checker-knot composition. Retain exact non-transitive algorithmic DefEq rules.
- The following checkpoint introduces a specific successor representation and predecessor congruence semantic rule; it is not yet independently green until its proof CI passes.


## Nat-successor refinement checkpoint — 2026-10-08
- Full proof run **#616** green at `5bff3bb2bdaea54390feb97b148c3c419a859800`.
- The independent `PsKernelNatSuccessorRep` and executable predecessor-recognition refinement are registered and green. Both Nat literal successors and one-argument Nat.succ constructor forms are supported; the nullary constructor is rejected.
- Next candidate closes the entire bounded `psKernelDefEqLazyReductionWithFuel` contract using specific zero/successor cases and already-verified Nat/native/delta callbacks. Verify the next CI before marking this candidate green.


## Concrete checker-knot soundness checkpoint — 2026-10-08

- Full `PSKernel Core proof` CI run **#639** is **green** at commit
  `a7c8d11a2a28718e4a773ac9d8f9f2883dc5834e`.
- New registered metatheory modules close the concrete `psKernelIsDefEqWithFuel`
  fuel induction. The executable branches are composed from independent
  state/semantic contracts for structural/cache checks, Quick, reflection,
  reduced Quick, proposition classification, lazy delta, projection shortcut,
  second full core-WHNF, changed/recursive comparison, full shape, and
  final-rule continuation. Original-pair success publication is justified by
  explicit reduction closures. **No unrestricted algorithmic DefEq
  transitivity** was introduced.
- `CheckerKnotConfiguration.lean` establishes the concrete public
  checked-inference, infer-only configuration-preservation, WHNF, and DefEq
  contracts from the fuel theorem. The optimized beta-spine law is discharged
  by the existing proof.
- `SessionConcreteRefinement.lean` specializes checked-session typing,
  infer-only configuration preservation, WHNF reduction, and positive DefEq
  refinement to those executable contracts, with a sound initial checker
  configuration as an explicit precondition. Infer-only success is **not**
  claimed to be a typing certificate.
- **Remaining explicit TCB boundaries:** `PsKernelNativeReductionSoundLaw`
  and `PsKernelStringEqSoundLaw`. The current checker theorem is conditional
  on these laws and must not be represented as an unconditional kernel
  metatheory theorem.
- Next semantic frontier: use concrete configured session contracts in
  declaration validation/admission; establish well-formed environment
  extensions for axiom/definition/theorem/opaque admission; complete ordinary,
  mutual, and nested inductive transaction refinement; compose public
  Kernel/API/session implementation-refinement theorem family.
- Preserve current audit A=44, B=9, C=19, D=7 (79 pairs) until criteria-based
  reclassification. Reconcile integration only with explicit cross-branch
  review; no Arena infrastructure or host workarounds in this proof branch.


## Verified ordinary declaration admission — 2026-10-08
- Full PSKernel Core proof gate **#649** is green at
  \`bd41e74cf6c1b9a5b07602e276fdbde5a25b0919\`.
- Registered concrete checked admission proofs:
  \`psKernelAddAxiom_configuration_refines\`;
  \`psKernelAddDefinition_nonunsafe_configuration_refines\` for safe and
  partial definitions;
  \`psKernelAddOpaque_configuration_refines\`; and
  \`psKernelAddTheorem_configuration_refines\`.
  These preserve the exact executable validation order, distinguish the
  checked proof/body from infer-only operations, and establish typing,
  algorithmic DefEq, Sort reduction, and authoritative extension evidence.
- \`psKernelSessionIsProp_true_configuration_refines\` provides the exact
  inferred-type-to-Sort normalization witness, not an invented infer-only
  typing certificate. The theorem-admission proof consumes it alongside a
  separately checked declaration header.
- \`psKernelEnvironmentAdd_success_refines_validated_extension\` establishes
  that successful insertion preserves the declared extension boundary,
  rejected an already-present authoritative declaration name, and rejected
  duplicate universe parameters (assuming the input index refines the
  authoritative environment).
- \`SessionRefinement.lean\` now contains checked/WHNF/infer-only context
  preservation lemmas required for composing independently checked sessions.
- **Still open:** concrete unsafe recursive definition admission and mutual
  work-environment soundness need an index-update preservation theorem.
  A conditional unsafe transaction refinement theorem has been drafted and
  registered in the next checkpoint, but its work-index premise remains an
  explicit separate proof obligation. Do not claim it is discharged by a green
  conditional theorem.
- **Still open:** ordinary/mutual/nested inductive transaction refinement,
  final Kernel/API/session implementation-refinement theorem family,
  criteria-based semantic audit refresh, integration reconciliation, and
  final proof/conformance gates. The last audited A/B/C/D counts remain
  44/9/19/7 until a new evidence-based audit.
- TCB boundaries \`PsKernelNativeReductionSoundLaw\` and
  \`PsKernelStringEqSoundLaw\` remain explicit. Do not replace these with
  unconditional soundness claims.


## Index-preserving recursive admission and checked mutual definitions — 2026-10-08
- Full `PSKernel Core proof` gate **#653** green at `c5665ed1677b4de2bf27d04ac569c6679e8d42cf`. A semantic source fix makes insertion into an externally constructible root-bucket index preserve previously readable declarations; the existing branch/small/empty behavior is unchanged. Canonical index proofs were moved into an importable metatheory module, with a retained proof companion and regression.
- Full gate **#659** green at `7c35cb6f43a33a72f2b8f2a2f0d3119b420e3171`: index insertion refines the authoritative declaration list for all public root forms and hash collisions, checked/unchecked environment insertion preserves index refinement, and the mutual work environment preserves the index invariant by induction. Unsafe single-definition admission now derives its recursive work-index premise from successful checked insertion, rather than assuming it.
- Full gate **#661** green at `1d085f49df113cb4a7bb8dc943f632a7b4ae3a66`: successful mutual-definition validation yields independent typed-header evidence for every member in the original environment, and checked body/DefEq evidence for every member in the completed recursive work environment. A Prop-valued list-evidence judgment is used because the pinned Lean baseline has no `List.Forall` declaration.
- The current follow-up commit is consolidating authoritative environment-extension evidence into the registered mutual-admission metatheory; verify its CI before calling this extra composition green.
- Mechanical inventory at this checkpoint: **79/79** canonical source modules have canonical `.proof.lean` companions; five additional standalone metatheory proof files exist. File pairing is not the same as semantic assurance completion.
- **Still open:** ordinary, mutual and nested inductive admission/refinement and restoration; final public Kernel/API/session refinement composition; explicit TCB inventory and semantic audit refresh; integration reconciliation and final conformance gates. `PsKernelNativeReductionSoundLaw` and `PsKernelStringEqSoundLaw` remain named premises, never unconditional conclusions.


## Inductive transaction index frontier — 2026-10-08 (latest)
- Full PSKernel Core proof gate **#669** is green at `4ab0cc375818e1bde9085f512ee7c7890205bb72`: authoritative environment-index refinement is preserved by replacement when an existing canonical declaration is present. Root-bucket and collision-sensitive insertion evidence remains registered.
- Full gate **#672** is green at `2d39870b62f5ade8871a4ef5a881b786b1281a98`: `psKernelAddSimpleConstructorsWithFuel_index_refines` proves that the complete successful ordinary constructor-admission loop preserves canonical index refinement, across its checked recursive insertions.
- Full gate **#673** is green at `b4f43dd5ea961780f3926a8c2e1a3919902b18eb`: mutual inductive-header and generated-recursors list insertions preserve the same invariant for arbitrary public index-root representations.
- Current candidate: structural index-preservation proofs for mutual constructors within one type and across the mutual type list. Verify its CI before treating the candidate as green.
- These index theorems are prerequisites rather than complete inductive-admission certificates. Still open are validated constructor/header typing, positivity and recursor semantics, replacement-name provenance across the bundle, ordinary/mutual/nested transaction refinement, final Kernel/API/session refinement composition, semantic audit refresh and reconciliation with `psc2/selfhost-lean-kernel`.
- Keep `PsKernelNativeReductionSoundLaw` and `PsKernelStringEqSoundLaw` as explicit conditional trusted premises. No `sorry`, axioms, general DefEq transitivity, or weakening of existing acceptance criteria.

## Checked inductive-header checkpoint — 2026-10-08
- Full proof gates **#674**, **#675**, **#676** and **#678** are green. The mutual constructor-per-type and mutual-type traversal preserve authoritative index refinement; mutual header and recursor insertion folds additionally expose exact reversed declaration-history extensions.
- Run **#678** at `b70516e9e9a2e1c9f4b1398b14e8891bac5a7848` proves `psKernelAddSimpleInductive_success_header_refines`: successful ordinary admission includes a genuinely checked type header in the original environment and reduction of its inferred type to a Sort, rather than an infer-only typing assumption.
- Current candidate composes a reusable checked-header/Sort pipeline and the first nested-inductive header refinement. It is not green until its proof CI passes.
- Still open: full constructor/positivity/recursor semantic refinement, replacement-name provenance and successful final bundle publication for ordinary/mutual/nested inductives, public declaration-API composition, audit reclassification, integration reconciliation and final conformance.
- Native reduction and StringEq remain explicitly named trusted laws, with no weakening of DefEq or checker invariants.


## Checked constructor-history and occurrence-soundness frontier — 2026-10-09

- **Full proof run #690 green** at `a635d6652855363a8ea64f3aae9a88305b378272`: success of ordinary, mutual and nested preflight uniform-occurrence checks entails the independent structural `PsKernelUniformOccurrencesSafe` predicate.
- **Full proof run #691 green** at `0bac4eeddefb25bc65f0839aeac169181da352d0`: successful ordinary constructor admission extracts independently checked constructor-type typing and Sort reduction in the current work environment. This does not upgrade infer-only into a typing certificate.
- **Full proof run #693 green** at `eebe06539d0a8165d97af0437f3f0d5b2fd2e4d0`: `PsKernelCheckedConstructorHeaderHistory` tracks the entire successful constructor loop through its actual incrementally extended authoritative work environments, establishing checked-header evidence for every installed constructor in that history. Constructor-field positivity, recursive-argument analysis, index-result validation, and recursor acceptance are distinct obligations and are NOT yet claimed by this history.
- **New candidate at `b3879fa8cb67dbc257231f78b4c2bd0ef9e59b04`**: `AdmissionNoTargetOccurrenceConfiguration.lean` models independent structural absence of a recursive datatype name and refines successful *negative* constant-occurrence tests to that model. Verify full proof CI #694 before calling this module green.
- **Important next assurance premise:** `PsKernelStringEqSoundLaw` asserts only that a *true* string-comparison result implies equal strings. Proving that `psKernelExprContainsConst target expr = false` excludes a syntactically identical target also requires comparator reflexivity/completeness. The candidate makes `PsKernelStringEqReflexiveLaw` an explicit conditional premise; it is NOT discharged yet. Do not silently replace it with the one-direction soundness law, and do not claim a production semantic defect without separate executable evidence.
- Next composition: strengthen result-index exclusion for accepted constructor results, close field/recursive-argument polarity and positive-occurrence semantics using independent judgments, then prove complete ordinary/mutual/nested constructor and recursor transaction refinement.
- Preserve the two existing checker TCB laws (`PsKernelNativeReductionSoundLaw` and `PsKernelStringEqSoundLaw`). The additional reflexivity requirement is a specific open inductive-admission proof obligation, not a newly accepted unconditional trust boundary.
- The final public Kernel/API/session implementation-refinement theorem family, sound inductive-environment extension, criteria-based audit refresh, reconciliation with `psc2/selfhost-lean-kernel`, and final proof/conformance gates remain open. No production source was modified during this constructor-history or occurrence-refinement checkpoint.


## Constructor result and comparator closure — 2026-10-09

- Live heads verified at start: proof `75afe536f025aa9d37c788f4094273e500fd5c13`,
  integration `cae6b6d5fb3d50138889e1aeb74436e7b5ea5316`.
  Full proof gates #697 and #698 independently confirmed green.
- Full gate **#699 GREEN** at `fabf24e25ab291edf75abace2a98b58958fc6ba2`:
  result-parameter consumption yields an independent structural prefix
  judgment and exact parameter/index suffix length. Raw parameter-spine
  refinement from #698 remains registered.
- Candidate head `b0103c9b690b8f50815132d22d862a64421574d3`, full gate #703
  in progress: byte-fuel induction discharges StringEq reflexivity using
  Lean 4.34's raw cursor strict-advance theorem; structural occurrence and
  accepted constructor-index exclusion consume this proof without a new
  trust premise. Do not call these candidate theorems green before #703.
- The same candidate composes recursor-rule validation through concrete
  checked-session typing and DefEq, preserving configuration between each
  rule. It replaces unrestricted session-soundness assumptions with an
  explicit sound initial configuration and the existing native/StringEq
  soundness laws. This proves rule-validator semantics, not completeness
  of generated recursor metadata or full inductive admission.
- No production source changes, no new axioms or sorry, and no unrestricted
  DefEq transitivity. The existing native-reduction and StringEq soundness
  laws remain explicit conditional TCB boundaries.
- Remaining: field-spine and recursive-argument positivity/configuration
  closure; complete ordinary/mutual/nested environment transaction semantics;
  final Kernel/API/session theorem family; audit; integration reconciliation
  and final conformance gates. Audit remains A/B/C/D = 44/9/19/7.
- Integration comparison is diverged (merge base `97e2ed3437e64a7041a9a6c3cceff2f852d83629`);
  do not blindly replace either branch or merge unrelated work.


### Opaque string boundary and constructor semantic shape — 2026-10-09
- Full gate #703 failed in the attempted StringEq reflexivity discharge:
  `String.Internal.next` and `String.Internal.atEnd` are opaque extern
  primitives in pinned Lean 4.34's Bootstrap module. The proved Raw cursor
  advance theorem does not provide an equality bridge to these primitives.
- The failed discharge and its unconditional wrappers were removed by
  ordinary follow-up commits; history is preserved. Occurrence exclusion
  remains explicitly conditional on `PsKernelStringEqReflexiveLaw`.
  This is an unresolved obligation, not an adopted additional TCB law.
- Constructor result guard lemmas are moved from the standalone proof
  companion into the registered importable parameter metatheory. The
  companion imports them and keeps its control-flow regressions.
- Candidate semantic-shape theorem composes canonical datatype name and
  universe equality, independent structural parameter-prefix evidence,
  index arity, and structural recursive-name exclusion. Positive comparisons
  use StringEq soundness, negative exclusion separately uses reflexivity.
  Neither is silently inferred from the other.
- Concrete configured recursor-rule validator remains a candidate pending
  full proof validation; ordinary/mutual/nested full admission still open.
