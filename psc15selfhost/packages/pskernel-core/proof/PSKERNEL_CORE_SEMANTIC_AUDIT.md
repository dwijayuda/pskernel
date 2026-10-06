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
| A | 30 |
| B | 15 |
| C | 26 |
| D | 8 |
| **Total canonical source/proof pairs** | **79** |

The separate cross-module `Metatheory/Typing.proof.lean` is A-level evidence and is used when grading `Checker/Inference/Core`; it is not one of the 79 canonical source/proof pairs.

## Module audit

| Module | Grade | Current evidence / missing step |
|---|:---:|---|
| `API/Kernel.lean` | **A** | Public check-expression, WHNF, and true-defeq successes now refine independent typing/reduction/defeq judgments under explicit checker-operation soundness contracts; fail-closed orchestration remains proved. |
| `API/KernelContractV1.lean` | **C** | Contract identity/version facts. |
| `API/Outcome.lean` | **C** | Outcome classification/control facts. |
| `API/Provider.lean` | **C** | Provider compatibility decision facts. |
| `API/Session.lean` | **A** | Session environment construction is proved semantically transparent to native-evaluator installation and preserves `EnvironmentIndexRefines`, alongside fail-closed preflight facts. |
| `Admission/Declaration/Admission.lean` | **A** | Successful checked safe-definition/theorem admission now refines the shared `PsKernelDeclarationExtension`; remaining declaration variants are being closed on the same relation. |
| `Admission/Declaration/Validation.lean` | **B** | Closedness, universes, body checking and defeq gating; formal validation relation pending. |
| `Admission/Inductive/Common/Elimination.lean` | **C** | Fuel/base control facts only. |
| `Admission/Inductive/Common/Occurrence.lean` | **C** | Selected occurrence/control cases; positivity semantics incomplete. |
| `Admission/Inductive/Common/Parameters.lean` | **B** | Reusable binder/list structure plus opening base case. |
| `Admission/Inductive/Common/RecursorValidation.lean` | **D** | Empty-worker base case only. |
| `Admission/Inductive/Mutual/Admission.lean` | **C** | Selected rejection/empty transaction behavior. |
| `Admission/Inductive/Mutual/AdmissionLoops.lean` | **D** | Empty-worker base case only. |
| `Admission/Inductive/Mutual/Analysis.lean` | **B** | Reusable structural analysis lemmas; mutual positivity relation incomplete. |
| `Admission/Inductive/Mutual/Header.lean` | **B** | Header/list structural invariants. |
| `Admission/Inductive/Mutual/Recursor.lean` | **C** | Recursor worker base/control facts; semantic recursor construction incomplete. |
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
| `Admission/Inductive/Ordinary/Admission.lean` | **C** | Fresh-name empty behavior only. |
| `Admission/Inductive/Ordinary/Constructor.lean` | **B** | Binder/field structural laws; positivity theorem incomplete. |
| `Admission/Inductive/Ordinary/ConstructorAdmission.lean` | **C** | Fuel exhaustion only. |
| `Admission/Inductive/Ordinary/Recursor.lean` | **B** | Recursor helper/list laws; generated-rule semantic validity incomplete. |
| `Admission/Inductive/Types.lean` | **B** | Basic list/name/binder helper laws. |
| `Admission/Quot/Admission.lean` | **A** | Successful Quot initialization refines the shared `PsKernelQuotExtension`, with exact four-declaration semantic history and runtime preservation. |
| `Admission/Quot/Bootstrap.lean` | **C** | Reserved-name branch behavior and binder base case. |
| `Checker/Context.lean` | **B** | Context construction/freshness/application helper invariants. |
| `Checker/DefEq/BinderSpines.lean` | **A** | `psKernelDefEqFinish` now preserves checker-state semantic soundness under the isolated successful-pair cache insertion law; binder-spine congruence itself still needs deeper semantic coverage. |
| `Checker/DefEq/DeltaStep.lean` | **C** | Delta-step result/control cases. |
| `Checker/DefEq/FinalRules.lean` | **C** | Fuel/control only for final rules. |
| `Checker/DefEq/FullShape.lean` | **A** | Full-shape Sort and literal success paths now refine the independent algorithmic defeq judgment; app/binder/eta terminal cases remain to be connected. |
| `Checker/DefEq/LazyDelta.lean` | **C** | Fuel exhaustion only. |
| `Checker/DefEq/Quick.lean` | **A** | Expression-equality and successful-cache quick paths now refine the independent defeq judgment under explicit `ExprEqSound` / `DefEqCacheSound` invariants; Sort/literal rules are directly bridged. |
| `Checker/DefEq/Shortcuts.lean` | **C** | Selected disabled shortcut behavior. |
| `Checker/DefEq/Support.lean` | **D** | Single empty-list aggregation fact. |
| `Checker/Inference.lean` | **A** | Infer-only and checked public inference wrappers now refine `PsKernelTypingJudgment` under the named `PsKernelInferenceCoreSound` contract. |
| `Checker/Inference/Core.lean` | **A** | Independent typing refinement now covers Sort/literals/fvar/const, both checked-application acceptance paths, and checked lambda/Π/let rules with explicit opened-body and freshness premises. |
| `Checker/Inference/Helpers.lean` | **A** | Cache publication now preserves the named checker-state semantic soundness invariant under the isolated inference-cache insertion law; Sort/Pi views and noninterference laws remain. |
| `Checker/Knot.lean` | **A** | Concrete checker infer/check/WHNF/defeq entry points now compose to independent typing/reduction/defeq judgments under explicit lower-layer soundness contracts; full discharge of those contracts remains pending. |
| `Checker/Ops.lean` | **D** | Eta/wrapper fact only. |
| `Checker/Projection.lean` | **C** | Fuel/error control facts; dependent projection typing relation pending. |
| `Checker/Recursor/Analysis.lean` | **A** | Successful recursor-rule lookup proves constructor-name agreement and list membership, and constructor-app recognition refines authoritative semantic-environment constructor metadata under index refinement. |
| `Checker/Recursor/Reduction.lean` | **C** | Selected no-reduction case only. |
| `Checker/Reduction/KernelReductions.lean` | **A** | WHNF-facing Nat succ/add/sub/mul hooks now refine independent primitive reduction steps when normalized literal premises and resource gates succeed; Quot/recursor hooks remain to be bridged. |
| `Checker/Reduction/PrimitiveData.lean` | **C** | Primitive base/control facts. |
| `Checker/Reduction/PrimitiveNat.lean` | **A** | Executable Nat add/sub/mul/mod/div/beq/ble primitive success paths now refine explicit independent primitive reduction rules under their exact gate premises. |
| `Checker/Reduction/Primitives.lean` | **D** | Single aggregation/fuel fact. |
| `Checker/Reduction/Whnf.lean` | **A** | Observable WHNF rules now bridge to the independent `PsKernelReductionClosure` relation for reflexive/metadata cases. |
| `Checker/Reduction/WhnfCore.lean` | **A** | Zeta implementation now bridges to the independent `PsKernelReductionClosure`; additional beta/delta/projection coverage remains. |
| `Checker/ResourcePolicy.lean` | **C** | Fail-closed/resource policy cases. |
| `Checker/Session.lean` | **A** | Session infer/check/WHNF/true-defeq successes now forward the independent semantic judgments while preserving the session context; error propagation remains proved. |
| `Checker/State.lean` | **A** | Empty checker state now establishes independent inference-cache and successful-defeq-cache soundness invariants; field-isolation/freshness laws support preservation proofs. |
| `Core/Declaration.lean` | **B** | Declaration projection/safety/delta facts. |
| `Core/Expr.lean` | **A** | `psKernelExprEq = true` now refines an independent structural-expression equality relation and therefore the formal non-transitive defeq judgment; spine/fvar/list helper laws remain available. |
| `Core/Level.lean` | **B** | Offset/list normalization foundations; full universe semantic equivalence proof pending. |
| `Core/LocalContext.lean` | **A** | Successful authoritative local-context lookup is proved to return a declaration present in `context.decls` whose kernel name matches the queried name; add/value structural laws remain as supporting invariants. |
| `Core/Name.lean` | **B** | Append/list algebra; equality correctness pending. |
| `Core/Substitution/Abstract.lean` | **A** | Production free-variable abstraction now refines a total fuel-free reference semantics; singleton abstraction/instantiation roundtrip is being generalized over the full tree. |
| `Core/Substitution/Beta.lean` | **A** | Single-lambda cheap beta is proved to either preserve the original term or realize the formal `PsKernelReductionStep.beta`; closed-body and identity cases remain as concrete corollaries. |
| `Core/Substitution/Instantiate.lean` | **A** | `InstantiateAt`/`Instantiate`/`Instantiate1`/`InstantiateRev` now refine total fuel-free reference semantics; arbitrary-depth closed instantiation is proved identity. |
| `Core/Substitution/Lift.lean` | **A** | The fuel-bounded production lift worker now refines total structural lifting semantics for every expression under its node-count budget. |
| `Core/Substitution/ListOps.lean` | **B** | Reusable take/drop/reverse algebra. |
| `Environment/Environment.lean` | **A** | Native-evaluator installation is proved to preserve both the authoritative semantic environment view and `EnvironmentIndexRefines`, making runtime capability changes semantically transparent. |
| `Environment/Lookup.lean` | **A** | Under `PsKernelEnvironmentIndexRefines`, indexed lookup is proved equal to authoritative `environment.constants` lookup. |
| `Environment/Operations.lean` | **A** | Explicit semantic-history preservation for add/replace/Quot marking. |
| `Environment/Semantic.lean` | **A** | Successful authoritative declaration-list lookup is proved to return an element of semantic history with a matching kernel name; list-length and replacement algebra remain supporting invariants. |
| `Runtime/Acceleration/Cache.lean` | **B** | Map/pair-cache set/get foundations; whole-cache refinement invariant pending. |
| `Runtime/Acceleration/CachePolicy.lean` | **C** | Eligibility policy cases. |
| `Runtime/Acceleration/EnvironmentIndex.lean` | **B** | Set/find/remove/insert candidate refinement foundations; full authoritative lookup equivalence pending. |
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
