import Lake
open Lake DSL

package pskernelCore

-- Assurance-only mathematical dependency, pinned by commit. No production imports.
require «con-leche» from git
  "https://github.com/leanprover/con-leche.git" @ "65e74db49e89ad2bbd1e90aa4f784954db41fa3a"

lean_lib PSC1KernelReferenceFoundations where
  srcDir := "reference"
  roots := #[
    `PSC1Kernel.Name,
    `PSC1Kernel.Level,
    `PSC1Kernel.Expr,
    `PSC1Kernel.Instantiate,
    `PSC1Kernel.Declaration,
    `PSC1Kernel.Environment,
    `PSC1Kernel.LocalContext,
    `PSC1Kernel.TypeChecker,
    `PSC1Kernel.CheckerState,
    `PSC1Kernel.CheckerStateful,
    `PSC1Kernel.CheckerReductionStateful,
    `PSC1Kernel.CheckerLazyDeltaStateful,
    `PSC1Kernel.CheckerDefEqStateful,
    `PSC1Kernel.CheckerDefEqStatefulClosed,
    `PSC1Kernel.CheckerDefEqStatefulReduced,
    `PSC1Kernel.CheckerRecursorStateful,
    `PSC1Kernel.CheckerSession,
    `PSC1Kernel.Quot,
    `PSC1Kernel.Kernel,
    `PSC1Kernel.Inductive,
    `PSC1Kernel.MutualInductive,
    `PSC1Kernel.NestedInductive,
    `PSC1Kernel.Replay,
    `PSC1Kernel.ReplayJson
  ]

lean_lib PsKernelCore where
  srcDir := "src"
  roots := #[
    `Ps.KernelCore.Core.Name,
    `Ps.KernelCore.Core.Level,
    `Ps.KernelCore.Core.SharedMemo,
    `Ps.KernelCore.Core.Expr,
    `Ps.KernelCore.Core.Substitution.ListOps,
    `Ps.KernelCore.Core.Substitution.Lift,
    `Ps.KernelCore.Core.Substitution.Instantiate,
    `Ps.KernelCore.Core.Substitution.Beta,
    `Ps.KernelCore.Core.Substitution.Abstract,
    `Ps.KernelCore.Core.Declaration,
    `Ps.KernelCore.Core.LocalContext,
    `Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex,
    `Ps.KernelCore.Environment.Operations,
    `Ps.KernelCore.Runtime.Acceleration.Cache,
    `Ps.KernelCore.Runtime.Acceleration.CachePolicy,
    `Ps.KernelCore.Runtime.Acceleration.SemanticCache,
    `Ps.KernelCore.Runtime.Capability.Lean434NativeReduction,
    `Ps.KernelCore.Checker.State,
    `Ps.KernelCore.Checker.Context,
    `Ps.KernelCore.Checker.Ops,
    `Ps.KernelCore.Checker.Knot,
    `Ps.KernelCore.Checker.Reduction.PrimitiveData,
    `Ps.KernelCore.Checker.Reduction.PrimitiveNat,
    `Ps.KernelCore.Checker.Reduction.Primitives,
    `Ps.KernelCore.Checker.Reduction.KernelReductions,
    `Ps.KernelCore.Checker.Reduction.WhnfCore,
    `Ps.KernelCore.Checker.Reduction.Whnf,
    `Ps.KernelCore.Checker.Projection,
    `Ps.KernelCore.Checker.Inference.Helpers,
    `Ps.KernelCore.Checker.Inference.Core,
    `Ps.KernelCore.Checker.Inference,
    `Ps.KernelCore.Checker.Recursor.Analysis,
    `Ps.KernelCore.Checker.Recursor.Reduction,
    `Ps.KernelCore.Checker.DefEq.BinderSpines,
    `Ps.KernelCore.Checker.DefEq.Quick,
    `Ps.KernelCore.Checker.DefEq.Support,
    `Ps.KernelCore.Checker.DefEq.DeltaStep,
    `Ps.KernelCore.Checker.DefEq.LazyDelta,
    `Ps.KernelCore.Checker.DefEq.FinalRules,
    `Ps.KernelCore.Checker.DefEq.Shortcuts,
    `Ps.KernelCore.Checker.DefEq.FullShape,
    `Ps.KernelCore.Checker.Session,
    `Ps.KernelCore.Admission.Declaration.Validation,
    `Ps.KernelCore.Admission.Declaration.Admission,
    `Ps.KernelCore.Admission.Quot.Bootstrap,
    `Ps.KernelCore.Admission.Quot.Admission,
    `Ps.KernelCore.Admission.Inductive.Common.Parameters,
    `Ps.KernelCore.Admission.Inductive.Ordinary.Constructor,
    `Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission,
    `Ps.KernelCore.Admission.Inductive.Ordinary.Recursor,
    `Ps.KernelCore.Admission.Inductive.Common.Elimination,
    `Ps.KernelCore.Admission.Inductive.Ordinary.Admission,
    `Ps.KernelCore.Admission.Inductive.Mutual.Analysis,
    `Ps.KernelCore.Admission.Inductive.Mutual.Recursor,
    `Ps.KernelCore.Admission.Inductive.Mutual.Header,
    `Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops,
    `Ps.KernelCore.Admission.Inductive.Mutual.Admission,
    `Ps.KernelCore.Admission.Inductive.Nested.Types,
    `Ps.KernelCore.Admission.Inductive.Nested.ReservedNames,
    `Ps.KernelCore.Admission.Inductive.Nested.Rebase,
    `Ps.KernelCore.Admission.Inductive.Nested.Discover,
    `Ps.KernelCore.Admission.Inductive.Nested.Flatten,
    `Ps.KernelCore.Admission.Inductive.Nested.RestoreExpr,
    `Ps.KernelCore.Admission.Inductive.Nested.Restore,
    `Ps.KernelCore.Admission.Inductive.Nested.Validation,
    `Ps.KernelCore.Admission.Inductive.Nested.Commit,
    `Ps.KernelCore.Admission.Inductive.Nested.Admission,
    `Ps.KernelCore.Admission.Inductive.Types,
    `Ps.KernelCore.Admission.Inductive.Common.Occurrence,
    `Ps.KernelCore.Admission.Inductive.Common.RecursorValidation,
    `Ps.KernelCore.Environment.Semantic,
    `Ps.KernelCore.Environment.Environment,
    `Ps.KernelCore.Environment.Lookup,
    `Ps.KernelCore.Runtime.Capability.Types,
    `Ps.KernelCore.Checker.ResourcePolicy,
    `Ps.KernelCore.API.Outcome,
    `Ps.KernelCore.API.KernelContractV1,
    `Ps.KernelCore.API.Provider,
    `Ps.KernelCore.API.Session,
    `Ps.KernelCore.API.Kernel,
    `Ps.KernelCore.API.Reference,
    `Ps.KernelCore.SelfHost
  ]

lean_lib PsKernelCoreMetatheory where
  srcDir := "metatheory"
  roots := #[
    `Ps.KernelCore.Metatheory.Judgments,
    `Ps.KernelCore.Metatheory.JudgmentAdequacy,
    `Ps.KernelCore.Metatheory.SemanticDomain,
    `Ps.KernelCore.Metatheory.SemanticLevel,
    `Ps.KernelCore.Metatheory.SemanticClassifier,
    `Ps.KernelCore.Metatheory.SemanticSortInference,
    `Ps.KernelCore.Metatheory.SemanticAudit,
    `Ps.KernelCore.Metatheory.SemanticAnnotationValidity,
    `Ps.KernelCore.Metatheory.SemanticFunctionValidity,
    `Ps.KernelCore.Metatheory.SemanticUniverseRegime,
    `Ps.KernelCore.Metatheory.SemanticReferenceBinders,
    `Ps.KernelCore.Metatheory.SemanticReferenceSortChecks,
    `Ps.KernelCore.Metatheory.SemanticReferenceApplication,
    `Ps.KernelCore.Metatheory.SemanticReferenceLambda,
    `Ps.KernelCore.Metatheory.SemanticReference,
    `Ps.KernelCore.Metatheory.ReferencePolicyAudit,
    `Ps.KernelCore.Metatheory.SemanticSetDomain,
    `Ps.KernelCore.Metatheory.SemanticAnnotatedExpr,
    `Ps.KernelCore.Metatheory.SemanticInterpretation,
    `Ps.KernelCore.Metatheory.SemanticContext,
    `Ps.KernelCore.Metatheory.SemanticErasure,
    `Ps.KernelCore.Metatheory.SemanticModelAdequacy,
    `Ps.KernelCore.Metatheory.SemanticDeclarative,
    `Ps.KernelCore.Metatheory.SemanticConcrete,
    `Ps.KernelCore.Metatheory.SemanticExtension,
    `Ps.KernelCore.Metatheory.SemanticStructuralEquality,
    `Ps.KernelCore.Metatheory.SemanticAbstraction,
    `Ps.KernelCore.Metatheory.SemanticScope,
    `Ps.KernelCore.Metatheory.SemanticLevelConstructors,
    `Ps.KernelCore.Metatheory.SemanticUniverseSubstitution,
    `Ps.KernelCore.Metatheory.SemanticConstantInference,
    `Ps.KernelCore.Metatheory.DefEqClassifierTrace,
    `Ps.KernelCore.Metatheory.ExprEq,
    `Ps.KernelCore.Metatheory.Comparator,
    `Ps.KernelCore.Metatheory.BootstrapStringObligations,
    `Ps.KernelCore.Metatheory.CacheHash,
    `Ps.KernelCore.Metatheory.CacheIndexRefinement,
    `Ps.KernelCore.Metatheory.CacheSemantic,
    `Ps.KernelCore.Metatheory.EnvironmentIndexHash,
    `Ps.KernelCore.Metatheory.EnvironmentIndexRefinement,
    `Ps.KernelCore.Metatheory.EnvironmentIndexCanonical,
    `Ps.KernelCore.Metatheory.NativeReduction,
    `Ps.KernelCore.Metatheory.PrimitiveNatReduction,
    `Ps.KernelCore.Metatheory.QuotReduction,
    `Ps.KernelCore.Metatheory.RecursorReduction,
    `Ps.KernelCore.Metatheory.RecursorBoundedConfiguration,
    `Ps.KernelCore.Metatheory.Substitution,
    `Ps.KernelCore.Metatheory.SubstitutionRefinement,
    `Ps.KernelCore.Metatheory.Admission,
    `Ps.KernelCore.Metatheory.AdmissionRefinement,
    `Ps.KernelCore.Metatheory.AdmissionIndexConfiguration,
    `Ps.KernelCore.Metatheory.EnvironmentReplaceIndexConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionQuotIndexConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionInductiveConstructorConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionConstructorTypingConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionConstructorHistoryConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionConstructorSemanticHistoryConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionOrdinaryTransactionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionOrdinaryFinishConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionOrdinaryInductivePipelineConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionRecursorSemanticConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualRecursorSemanticConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualRecursorPublicationConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionEliminationNameConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionEliminationConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionConstructorParamsConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionInductiveHeaderConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionUniformOccurrenceConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionUniformPreflightConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionNoTargetOccurrenceConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualOccurrenceConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualRecursiveArgumentConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualFieldConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualConstructorSemanticHistoryConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualTransactionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualRecursorTransactionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualRecursorContinuationConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionRecursiveArgumentConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionHeaderSpineConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionParameterConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionNestedHeaderConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionNestedNoAuxConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualHeaderConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualHeaderSpineConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualInductiveIndexConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualConstructorConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionMutualConfiguration,
    `Ps.KernelCore.Metatheory.EnvironmentSemanticTransport,
    `Ps.KernelCore.Metatheory.SessionRefinement,
    `Ps.KernelCore.Metatheory.Delta,
    `Ps.KernelCore.Metatheory.ReductionCongruence,
    `Ps.KernelCore.Metatheory.ProjectionReduction,
    `Ps.KernelCore.Metatheory.WhnfCoreProjection,
    `Ps.KernelCore.Metatheory.WhnfCoreApplication,
    `Ps.KernelCore.Metatheory.WhnfCoreConfiguration,
    `Ps.KernelCore.Metatheory.WhnfConfiguration,
    `Ps.KernelCore.Metatheory.BetaSpine,
    `Ps.KernelCore.Metatheory.Inductive,
    `Ps.KernelCore.Metatheory.Context,
    `Ps.KernelCore.Metatheory.ContextState,
    `Ps.KernelCore.Metatheory.CheckerContracts,
    `Ps.KernelCore.Metatheory.DefEqBinderConfiguration,
    `Ps.KernelCore.Metatheory.DefEqEtaConfiguration,
    `Ps.KernelCore.Metatheory.DefEqQuickConfiguration,
    `Ps.KernelCore.Metatheory.DefEqApplicationConfiguration,
    `Ps.KernelCore.Metatheory.DefEqFullShapeConfiguration,
    `Ps.KernelCore.Metatheory.DefEqReflectionConfiguration,
    `Ps.KernelCore.Metatheory.DefEqFinalConfiguration,
    `Ps.KernelCore.Metatheory.DefEqLazyConfiguration,
    `Ps.KernelCore.Metatheory.DefEqLazyContinuation,
    `Ps.KernelCore.Metatheory.DefEqLazyFuelConfiguration,
    `Ps.KernelCore.Metatheory.DefEqProjectionShortcutConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotPreparation,
    `Ps.KernelCore.Metatheory.DefEqKnotEntryConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotQuickConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotReflectionConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotCoreConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotPropositionConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotLazyConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotProjectionConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotFullWhnfConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotFinalConfiguration,
    `Ps.KernelCore.Metatheory.DefEqKnotConfiguration,
    `Ps.KernelCore.Metatheory.CheckerKnotConfiguration,
    `Ps.KernelCore.Metatheory.SessionConcreteRefinement,
    `Ps.KernelCore.Metatheory.PublicKernelConfiguration,
    `Ps.KernelCore.Metatheory.PublicQuotAdmissionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionDefinitionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionHeaderConfiguration,
    `Ps.KernelCore.Metatheory.CheckerInitialConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionOrdinaryConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionDefinitionTransactionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionValueConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionPropositionConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionTheoremConfiguration,
    `Ps.KernelCore.Metatheory.AdmissionUnsafeConfiguration,
    `Ps.KernelCore.Metatheory.ProjectionConfiguration,
    `Ps.KernelCore.Metatheory.CheckedProjectionConfiguration,
    `Ps.KernelCore.Metatheory.ProjectionSemantics,
    `Ps.KernelCore.Metatheory.InferenceConfiguration,
    `Ps.KernelCore.Metatheory.CheckedInferenceConfiguration,
    `Ps.KernelCore.Metatheory.CheckerComposition,
    `Ps.KernelCore.Metatheory.InferenceTyping
  ]

lean_lib PsKernelCoreTestSupport where
  srcDir := "test"
  roots := #[
    `KernelCore.Foundation.KernelContract,
    `KernelCore.Foundation.CheckerOps,
    `KernelCore.Foundation.Core,
    `KernelCore.Foundation.Checking,
    `KernelCore.Foundation.DefEqNested,
    `KernelCore.Foundation.AdmissionRuntime,
    `KernelCore.Bench.Foundation,
    `KernelCore.Bench.Inference,
    `KernelCore.Bench.Inductive,
    `KernelCore.Bench.Nested,
    `KernelCore.Bench.CrossRuntime
  ]

lean_exe psc1_kernel_core_foundation_tests where
  srcDir := "test"
  root := `PsKernelCoreFoundationTests

lean_lib PsKernelCoreArenaHost where
  srcDir := "host"
  roots := #[`Ps.Host.KernelCoreArena.CoreIntern, `Ps.Host.KernelCoreArena.Replay]

lean_exe psc_kernel_core_arena where
  srcDir := "host"
  root := `Ps.Host.KernelCoreArena.Main

lean_exe pskernel_nat_dispatch_tests where
  srcDir := "test"
  root := `NatDispatchTests

lean_exe pskernel_projection_fuel_tests where
  srcDir := "test"
  root := `ProjectionFuelTests

lean_exe pskernel_cache_mode_tests where
  srcDir := "test"
  root := `CacheModeTests


lean_exe pskernel_shared_syntax_tests where
  srcDir := "test"
  root := `SharedSyntaxTests

lean_exe pskernel_reference_cache_tests where
  srcDir := "test"
  root := `ReferenceCacheTests
