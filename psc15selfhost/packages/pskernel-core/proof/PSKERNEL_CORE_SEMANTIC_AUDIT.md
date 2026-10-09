# PSKernel Core Semantic Proof Audit

Status baseline: proof branch after the first independent typing metatheory and strengthened Quot/environment/cache work. This audit is deliberately conservative: compilation and proof-file presence do not imply semantic completeness.

## Grade definitions

- **A — semantic/refinement:** a nontrivial theorem relates implementation behavior to an independently stated kernel semantic/refinement property, or proves a semantic-history refinement invariant.
- **B — reusable theory foundation:** substantive algebraic/structural/representation invariants that are prerequisites for A-level refinement, but do not yet establish the whole semantic rule.
- **C — control/branch assurance:** fail-closed, fuel, error propagation, cache isolation, or selected branch equations.
- **D — shallow/base:** wrapper identity, empty/base case, marker, or similarly weak evidence.

## Current counts

| Grade | Modules |
|---|---:|
| A | 51 |
| B | 6 |
| C | 16 |
| D | 6 |
| **Total canonical source/proof pairs** | **79** |

The separate cross-module `Metatheory/Typing.proof.lean` is A-level evidence and is used when grading `Checker/Inference/Core`; it is not one of the 79 canonical source/proof pairs.

## Module audit

| Module | Grade | Current evidence / missing step |
|---|:---:|---|
| `API/Kernel.lean` | **A** | Public check-expression, WHNF, and true-defeq successes now refine independent typing/reduction/defeq judgments under explicit checker-operation soundness contracts; fail-closed orchestration remains proved. |
| `API/KernelContractV1.lean` | **C** | Contract identity/version facts. |
| `API/Outcome.lean` | **C** | Outcome classification/control facts. |
| `API/Provider.lean` | **A** | Under the named positive string soundness law and an unresolved explicit string-reflexivity condition, `psKernelProviderCompatible = true` is equivalent to exact pinned `KernelContract-v1` target identity (Lean 4.34.0 and the pinned commit). |
| `API/Session.lean` | **A** | Session environment construction is proved semantically transparent to native-evaluator installation and preserves `EnvironmentIndexRefines`, alongside fail-closed preflight facts. |
| `Admission/Declaration/Admission.lean` | **A** | Successful checked safe-definition/theorem admission now refines the shared `PsKernelDeclarationExtension`; remaining declaration variants are being closed on the same relation. |
| `Admission/Declaration/Validation.lean` | **A** | Successful definition-body validation refines `PsKernelDefinitionBodyValid`, including closedness, universe-parameter discipline, typing, and declared-type defeq under explicit checker soundness contracts. |
| `Admission/Inductive/Common/Elimination.lean` | **A** | K-target is characterized exactly as Prop/zero-level + one fieldless constructor, and successful elimination-only-at-zero decisions expose the semantic reason large elimination is forbidden. |
| `Admission/Inductive/Common/Occurrence.lean` | **A** | Successful fuel-bounded uniform-occurrence checking refines the fuel-free `PsKernelUniformOccurrenceSafe` predicate; declared occurrences certify exact parameter arity, universe levels, offset, and uniform bvar arguments. |
| `Admission/Inductive/Common/Parameters.lean` | **A** | Cross-module checked header and raw constructor parameter-spine refinement (full proof/native #732). Independent binder typing, context/freshness and exact residual evidence; not full inductive admission. |
| `Admission/Inductive/Common/RecursorValidation.lean` | **A** | Successful recursor-rule validation refines `PsKernelSimpleRecursorRulesValid`, proving each generated rule RHS is typed and definitionally equal to the expected closed motive application under explicit session soundness contracts. |
| `Admission/Inductive/Mutual/Admission.lean` | **C** | Selected rejection/empty transaction behavior. |
| `Admission/Inductive/Mutual/AdmissionLoops.lean` | **A** | Independent per-type and whole-family constructor publication histories (full proof/native #765): closed checked typing, owner-shape suffix provenance, positivity/result evidence, canonical freshness/lookup/index preservation. Full proof/native #779–#780 additionally validate ordered Sort-typed recursor headers, independent typed owner rules, and generated metadata. Final mutual transaction composition remains incomplete. |
| `Admission/Inductive/Mutual/Analysis.lean` | **A** | Independent family-wide occurrence/index exclusion and recursive-argument positive grammar (#759), with distinct traversal/checker fuel and scope-history invariants. Comparator reflexivity is an explicit unresolved condition. |
| `Admission/Inductive/Mutual/Header.lean` | **A** | Checked remaining-header history (#759): closed Sort typing, raw parameter and checked index spines, normalized universe equality, exact declaration/shape/name provenance. Full mutual transaction remains incomplete. |
| `Admission/Inductive/Mutual/Recursor.lean` | **A** | Full proof/native #779–#780: actual rule validation yields independent owner-filtered RHS typing with exact rule exhaustion, selected motive, and preserved context/configuration; generated rules have constructor-name and field-arity provenance. Complete mutual transaction and generated universe freshness remain open. |
| `Admission/Inductive/Nested/Admission.lean` | **C** | Reserved-name failure propagation. |
| `Admission/Inductive/Nested/Commit.lean` | **C** | Commit helper base cases. |
| `Admission/Inductive/Nested/Discover.lean` | **B** | Discovery soundness for returned family template plus list laws. |
| `Admission/Inductive/Nested/Flatten.lean` | **C** | Fuel exhaustion/control only. |
| `Admission/Inductive/Nested/Rebase.lean` | **C** | Lookup/fuel base cases; rebase correctness incomplete. |
| `Admission/Inductive/Nested/ReservedNames.lean` | **C** | Reserved-name checks/base behavior. |
| `Admission/Inductive/Nested/Restore.lean` | **C** | Restore worker base cases plus length law. |
| `Admission/Inductive/Nested/RestoreExpr.lean` | **C** | Lookup/map/fuel base behavior; restoration relation incomplete. |
| `Admission/Inductive/Nested/Types.lean` | **D** | Structure eta only. |
| `Admission/Inductive/Nested/Validation.lean` | **C** | Length/fuel control; restored-type preservation incomplete. |
| `Admission/Inductive/Ordinary/Admission.lean` | **A** | Actual admission success entails independent checked header/constructor-prefix semantics (#759), with canonical lookup extension and indexes. Later final metadata/K-policy (#763) is validated; complete well-formed admission and generated universe freshness are not claimed. |
| `Admission/Inductive/Ordinary/Constructor.lean` | **A** | Successful constructor-result validation refines `PsKernelSimpleConstructorResultValid`: exact datatype head/name, universes, parameter consumption, index arity, and absence of recursive occurrences in result indices; recursive-field positivity remains a downstream obligation. |
| `Admission/Inductive/Ordinary/ConstructorAdmission.lean` | **A** | Independent progressively checked constructor publication history (#737/#765): checked closed typing, raw parameters/fields, positivity and recursive metadata, exact result indices, canonical freshness, ordered publication and semantic lookup/index refinement. |
| `Admission/Inductive/Ordinary/Recursor.lean` | **B** | Recursor helper/list laws; generated-rule semantic validity incomplete. |
| `Admission/Inductive/Types.lean` | **B** | Basic list/name/binder helper laws. |
| `Admission/Quot/Admission.lean` | **A** | Successful Quot initialization refines the shared `PsKernelQuotExtension`, with exact four-declaration semantic history and runtime preservation. |
| `Admission/Quot/Bootstrap.lean` | **A** | Successful reserved-name validation now proves every requested Quot name is absent from authoritative semantic declaration history under `EnvironmentIndexRefines`; binder construction laws remain supporting evidence. |
| `Checker/Context.lean` | **B** | Context construction/freshness/application helper invariants. |
| `Checker/DefEq/BinderSpines.lean` | **A** | Binder-spine configuration and semantic comparison are composed in the concrete knot (#639), preserving parent semantic caches on scope exit and monotone fresh-name state. |
| `Checker/DefEq/DeltaStep.lean` | **A** | Successful delta unfolding and projection-app unfolding now refine `PsKernelReductionClosure` through the shared Delta metatheory; quick equal/cache finish paths also refine `PsKernelDefEqJudgment`. |
| `Checker/DefEq/FinalRules.lean` | **C** | Fuel/control only for final rules. |
| `Checker/DefEq/FullShape.lean` | **A** | Sort/literal, application, binder, reflection, LazyDelta and symmetric function-eta paths are composed in the concrete checker knot (#639); independent algorithmic DefEq has no unrestricted transitivity. |
| `Checker/DefEq/LazyDelta.lean` | **C** | Fuel exhaustion only. |
| `Checker/DefEq/Quick.lean` | **A** | Expression-equality and successful-cache quick paths now refine the independent defeq judgment under explicit `ExprEqSound` / `DefEqCacheSound` invariants; Sort/literal rules are directly bridged. |
| `Checker/DefEq/Shortcuts.lean` | **C** | Selected disabled shortcut behavior. |
| `Checker/DefEq/Support.lean` | **D** | Single empty-list aggregation fact. |
| `Checker/Inference.lean` | **A** | Concrete checked inference refines independent typing under configuration/index and named native/string laws (#639). Infer-only execution preserves its stated configuration/context invariants; its result is not a typing certificate. |
| `Checker/Inference/Core.lean` | **A** | The concrete full checked-inference knot is composed (#639), including application, lambda/Pi/let, dependent projection and checked conversions with scope/freshness/cache invariants. Infer-only results remain separate from typing evidence. |
| `Checker/Inference/Helpers.lean` | **A** | Cache publication now preserves the named checker-state semantic soundness invariant under the isolated inference-cache insertion law; Sort/Pi views and noninterference laws remain. |
| `Checker/Knot.lean` | **A** | Concrete mutually recursive checked inference, WHNF and true DefEq entry points are composed (#639) under configuration/index invariants and explicitly named native-reduction/string-soundness laws. Infer-only execution has preservation contracts, not general typing soundness. |
| `Checker/Ops.lean` | **D** | Eta/wrapper fact only. |
| `Checker/Projection.lean` | **A** | Successful dependent projection inference refines `PsKernelTypingJudgment` and `PsKernelProjectionResultJudgment`; parameter application and dependent-field traversal refine dedicated semantic judgments under WHNF/inference/index soundness. |
| `Checker/Recursor/Analysis.lean` | **A** | Successful recursor-rule lookup proves constructor-name agreement and list membership, and constructor-app recognition refines authoritative semantic-environment constructor metadata under index refinement. |
| `Checker/Recursor/Reduction.lean` | **C** | Selected no-reduction case only. |
| `Checker/Reduction/KernelReductions.lean` | **A** | WHNF-facing Nat succ/add/sub/mul hooks now refine independent primitive reduction steps when normalized literal premises and resource gates succeed; Quot/recursor hooks remain to be bridged. |
| `Checker/Reduction/PrimitiveData.lean` | **C** | Primitive base/control facts. |
| `Checker/Reduction/PrimitiveNat.lean` | **A** | Executable Nat add/sub/mul/mod/div/beq/ble primitive success paths now refine explicit independent primitive reduction rules under their exact gate premises. |
| `Checker/Reduction/Primitives.lean` | **D** | Single aggregation/fuel fact. |
| `Checker/Reduction/Whnf.lean` | **A** | Concrete core/public WHNF and primitive/native/Nat/delta/cache composition refine independent reduction closure in the checker knot (#639), with configuration and authoritative index invariants. |
| `Checker/Reduction/WhnfCore.lean` | **A** | Zeta implementation now bridges to the independent `PsKernelReductionClosure`; additional beta/delta/projection coverage remains. |
| `Checker/ResourcePolicy.lean` | **A** | Successful preflight certifies non-cancellation and nonzero fuel; declaration-size acceptance/denial refine explicit unbounded-or-bounded and overflow arithmetic properties. |
| `Checker/Session.lean` | **A** | Concrete checked-session successes refine independent typing, WHNF and positive DefEq judgments and preserve context/configuration. Infer-only session success supplies preservation evidence, not a typing certificate. |
| `Checker/State.lean` | **A** | Empty checker state now establishes independent inference-cache and successful-defeq-cache soundness invariants; field-isolation/freshness laws support preservation proofs. |
| `Core/Declaration.lean` | **B** | Declaration projection/safety/delta facts. |
| `Core/Expr.lean` | **A** | `psKernelExprEq = true` now refines an independent structural-expression equality relation and therefore the formal non-transitive defeq judgment; spine/fvar/list helper laws remain available. |
| `Core/Level.lean` | **A** | Under the explicit string-runtime comparator soundness law, structural level equality is sound and `psKernelLevelEquivalent = true` implies equality of normalized universe levels; offset/list normalization foundations remain supporting evidence. |
| `Core/LocalContext.lean` | **A** | Successful authoritative local-context lookup is proved to return a declaration present in `context.decls` whose kernel name matches the queried name; add/value structural laws remain as supporting invariants. |
| `Core/Name.lean` | **A** | Name equality now has symmetry/transitivity and, under the named positive string soundness law and an unresolved explicit string-reflexivity condition, `psKernelNameEq = true ↔` actual `PsKernelName` equality. |
| `Core/Substitution/Abstract.lean` | **A** | Production free-variable abstraction now refines a total fuel-free reference semantics; singleton abstraction/instantiation roundtrip is being generalized over the full tree. |
| `Core/Substitution/Beta.lean` | **A** | Single-lambda cheap beta is proved to either preserve the original term or realize the formal `PsKernelReductionStep.beta`; closed-body and identity cases remain as concrete corollaries. |
| `Core/Substitution/Instantiate.lean` | **A** | `InstantiateAt`/`Instantiate`/`Instantiate1`/`InstantiateRev` now refine total fuel-free reference semantics; arbitrary-depth closed instantiation is proved identity. |
| `Core/Substitution/Lift.lean` | **A** | The fuel-bounded production lift worker now refines total structural lifting semantics for every expression under its node-count budget. |
| `Core/Substitution/ListOps.lean` | **B** | Reusable take/drop/reverse algebra. |
| `Environment/Environment.lean` | **A** | Native-evaluator installation is proved to preserve both the authoritative semantic environment view and `EnvironmentIndexRefines`, making runtime capability changes semantically transparent. |
| `Environment/Lookup.lean` | **A** | Under `PsKernelEnvironmentIndexRefines`, indexed lookup is proved equal to authoritative `environment.constants` lookup. |
| `Environment/Operations.lean` | **A** | Explicit semantic-history preservation for add/replace/Quot marking. |
| `Environment/Semantic.lean` | **A** | Successful authoritative declaration-list lookup is proved to return an element of semantic history with a matching kernel name; list-length and replacement algebra remain supporting invariants. |
| `Runtime/Acceleration/Cache.lean` | **A** | Expression-map list→indexed rebuild is lookup-equivalent for every query; insertion preserves the inserted semantic answer across small→indexed promotion, and unordered defeq pair insertion preserves self-membership across the same promotion boundary. |
| `Runtime/Acceleration/CachePolicy.lean` | **C** | Eligibility policy cases. |
| `Runtime/Acceleration/EnvironmentIndex.lean` | **A** | Rebuilding the trie from any authoritative declaration list is proved lookup-equivalent to that list for every name, including same-name updates, different hashes, and hash-collision buckets; routing noninterference is proved separately. |
| `Runtime/Capability/Lean434NativeReduction.lean` | **A** | Any successful native wrapper reduction now refines an explicit `PsKernelTrustedNativeReduction` relation carrying the evaluator result as a TCB premise; evaluator correctness remains intentionally trusted, not internally proved. |
| `Runtime/Capability/Types.lean` | **D** | Empty capability structure fact only. |
| `SelfHost.lean` | **D** | Semantic-root marker only. |

## Upgrade order

1. Core substitution: lift composition, instantiate/lift interaction, general abstraction/instantiation roundtrip, capture avoidance.
2. Acceleration refinement: prove expression-map and environment-index lookup equivalent to authoritative semantic sources under explicit invariants.
3. Typing: extend `PsKernelTypingJudgment` across application, lambda, Pi, let and projection, then prove cache-sound inference refinement.
4. Reduction: formal beta/zeta/delta/projection/Nat/Quot/recursor reduction relation and WHNF reachability/preservation.
5. Defeq: formal non-transitive algorithmic defeq judgment and soundness of quick/delta/eta/proof-irrelevance/final rules.
6. Admission: formal environment-well-formedness/extension judgment for declarations and Quot.
7. Inductives: positivity, constructor result shape, elimination, recursor generation, mutual and nested flatten/restore preservation.
8. Public boundary: compose the above into KernelContract success => semantic judgment / well-formed extension theorems.

## Evidence refresh — 2026-10-08

Counts above apply the stated A/B/C/D criteria to validated cross-module evidence,
as already done for the typing metatheory. Six grades change: three B, two C,
and one D become A. The baseline 44/9/19/7 becomes **50/6/17/6**. Every changed
row names its independent semantic/history theorem family and full CI checkpoint;
no grade changes for companion presence alone. Other rows retain their prior
grades pending the final whole-tree review.

A is evidence of a nontrivial semantic/refinement theorem under its explicitly
named conditions. It does **not** mean unconditional or complete semantic closure
of every executable path. This is a partial evidence refresh, not the final
acceptance audit. The total canonical source/proof pairing remains 79.

Existing named trusted premises are `PsKernelNativeReductionSoundLaw` and
`PsKernelStringEqSoundLaw`. Comparator reflexivity is unresolved and conditional,
rather than an adopted new TCB law. The generated elimination-universe name
requires a checked specification/distinctness bridge for the pinned opaque
bootstrap string operations; that bridge is **unproved**, not assumed.
See ../metatheory/PSKERNEL_CORE_INDUCTIVE_CLOSURE_BLOCKERS.md.

Full ordinary environment well-formedness, mutual recursor/header transaction,
nested flatten/rebase/restore refinement, the final Kernel/API/session theorem
family, integration reconciliation and final conformance gates remain open.

The evidence refresh also removes stale infer-only typing claims and stale full-knot closure notes. These corrections do not change grade counts. Earlier green concrete checker work is preserved; it is not restarted or treated as an unresolved callback assumption.

## Evidence refresh — 2026-10-09

Full proof/native #779 and #780 justify one additional C→A upgrade for
`Admission/Inductive/Mutual/Recursor.lean`. Counts are now **51/6/16/6**.
Decimal injectivity, bounded search counting, and explicit cursor/append
obligation decomposition are also checked at #780; they do not discharge the
actual opaque primitive bridges or justify an unconditional admission claim.
This remains a partial audit, not final acceptance.
