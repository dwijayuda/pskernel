import Lake
open Lake DSL

package proofscriptSelfhost

-- Isolated kernel qualifier: explicitly enumerate native dependencies so
-- Lake compiles this portable source tree independently of compiler targets.
lean_lib PsKernelCore where
  srcDir := "packages/pskernel-core/src"
  roots := #[
    `Ps.KernelCore.Core.ExprScalar,
    `Ps.KernelCore.Runtime.Acceleration.ScalarHash,
    `Ps.KernelCore.Core.ExprV2.Node,
    `Ps.KernelCore.Core.ExprV2.Paged,
    `Ps.KernelCore.Core.ExprV2.Builder,
    `Ps.KernelCore.Core.ExprV2.Validation,
    `Ps.KernelCore.Core.ExprV2.Decode,
    `Ps.KernelCore.Core.ExprV2.PairMemo,
    `Ps.KernelCore.Core.ExprV2.Equality,
    `Ps.KernelCore.Core.ExprV2.Lift,
    `Ps.KernelCore.Core.ExprV2.TransformSupport,
    `Ps.KernelCore.Core.ExprV2.ExpandedSize,
    `Ps.KernelCore.Core.ExprV2.Transform,
    `Ps.KernelCore.Core.ExprV2.TransformSpine,
    `Ps.KernelCore.API.DagTypes,
    `Ps.KernelCore.API.DagDeclaration,
    `Ps.KernelCore.API.DagAdmissionGuards,
    `Ps.KernelCore.API.DagOrdinaryHeaderTypes,
    `Ps.KernelCore.API.DagOrdinaryOccurrence,
    `Ps.KernelCore.API.DagOrdinaryAnnotations,
    `Ps.KernelCore.API.DagOrdinaryParameters,
    `Ps.KernelCore.API.DagOrdinaryHeader,
    `Ps.KernelCore.API.DagMutualHeader,
    `Ps.KernelCore.API.DagNestedHeader,
    `Ps.KernelCore.API.DagNestedPreprocess,
    `Ps.KernelCore.API.DagNestedOverlay,
    `Ps.KernelCore.API.DagMutualConstructorResult,
    `Ps.KernelCore.API.DagMutualRecursiveArgument,
    `Ps.KernelCore.API.DagMutualConstructorFields,
    `Ps.KernelCore.API.DagMutualConstructorAnalysis,
    `Ps.KernelCore.API.DagMutualConstructorLoop,
    `Ps.KernelCore.API.DagMutualGenerated,
    `Ps.KernelCore.API.DagMutualRecursorValidation,
    `Ps.KernelCore.API.DagMutualAdmission,
    `Ps.KernelCore.API.DagOrdinaryConstructorParams,
    `Ps.KernelCore.API.DagOrdinaryConstructorResult,
    `Ps.KernelCore.API.DagOrdinaryConstructorTypes,
    `Ps.KernelCore.API.DagOrdinaryRecursiveArgument,
    `Ps.KernelCore.API.DagOrdinaryConstructorFields,
    `Ps.KernelCore.API.DagOrdinaryConstructorAnalysis,
    `Ps.KernelCore.API.DagOrdinaryConstructorLoop,
    `Ps.KernelCore.API.DagOrdinaryElimination,
    `Ps.KernelCore.API.DagOrdinaryGenerated,
    `Ps.KernelCore.API.DagOrdinaryRecursorValidation,
    `Ps.KernelCore.API.DagOrdinaryAdmission,
    `Ps.KernelCore.Checker.ExprV2.AdmissionHelpers,
    `Ps.KernelCore.Checker.ExprV2.Quot,
    `Ps.KernelCore.API.DagGenerated,
    `Ps.KernelCore.Checker.ExprV2.RecursorMajor,
    `Ps.KernelCore.Checker.ExprV2.RecursorK,
    `Ps.KernelCore.Checker.ExprV2.Recursor,
    `Ps.KernelCore.API.DagQuotAdmission,
    `Ps.KernelCore.API.DagAdmission,
    `Ps.KernelCore.API.Dag,
    `Ps.KernelCore.Checker.ExprV2.DefEqPair,
    `Ps.KernelCore.Checker.ExprV2.CheckWhnf,
    `Ps.KernelCore.Checker.ExprV2.CheckLet,
    `Ps.KernelCore.Checker.ExprV2.CheckState,
    `Ps.KernelCore.Checker.ExprV2.CheckCallbacks,
    `Ps.KernelCore.Checker.ExprV2.CheckHelpers,
    `Ps.KernelCore.Checker.ExprV2.CheckApplication,
    `Ps.KernelCore.Checker.ExprV2.InferApplication,
    `Ps.KernelCore.Checker.ExprV2.CheckProjectionHelpers,
    `Ps.KernelCore.Checker.ExprV2.CheckProjection,
    `Ps.KernelCore.Checker.ExprV2.Constant,
    `Ps.KernelCore.Checker.ExprV2.CheckCore,
    `Ps.KernelCore.Checker.ExprV2.Check,
    `Ps.KernelCore.Checker.ExprV2.Terminal,
    `Ps.KernelCore.Checker.ExprV2.Beta,
    `Ps.KernelCore.Checker.ExprV2.Environment,
    `Ps.KernelCore.Checker.ExprV2.WhnfState,
    `Ps.KernelCore.Checker.ExprV2.Delta,
    `Ps.KernelCore.Checker.ExprV2.Nat,
    `Ps.KernelCore.Checker.ExprV2.Projection,
    `Ps.KernelCore.Checker.ExprV2.WhnfOwned,
    `Ps.KernelCore.Checker.ExprV2.Knot,
    `Ps.KernelCore.Checker.ExprV2.Whnf,
    `Ps.KernelCore.Checker.ExprV2.DefEq,
    `Ps.KernelCore.Checker.ExprV2.DefEq.BinderSpines,
    `Ps.KernelCore.Checker.ExprV2.DefEq.Quick,
    `Ps.KernelCore.Checker.ExprV2.DefEq.Prefix,
    `Ps.KernelCore.Checker.ExprV2.DefEq.ProofIrrelevance,
    `Ps.KernelCore.Checker.ExprV2.DefEq.LazyNat,
    `Ps.KernelCore.Checker.ExprV2.DefEq.Args,
    `Ps.KernelCore.Checker.ExprV2.DefEq.DeltaStep,
    `Ps.KernelCore.Checker.ExprV2.DefEq.LazyDelta,
    `Ps.KernelCore.Checker.ExprV2.DefEq.FullShape,
    `Ps.KernelCore.Checker.ExprV2.DefEq.LazyProjection,
    `Ps.KernelCore.Checker.ExprV2.DefEq.FinalRules,
    `Ps.KernelCore.Checker.ExprV2.String,
    `Ps.KernelCore.API.Kernel,
    `Ps.KernelCore.API.KernelContractV1,
    `Ps.KernelCore.API.Outcome,
    `Ps.KernelCore.API.Provider,
    `Ps.KernelCore.API.Session,
    `Ps.KernelCore.Admission.Declaration.Admission,
    `Ps.KernelCore.Admission.Declaration.Validation,
    `Ps.KernelCore.Admission.Inductive.Common.Elimination,
    `Ps.KernelCore.Admission.Inductive.Common.Occurrence,
    `Ps.KernelCore.Admission.Inductive.Common.Parameters,
    `Ps.KernelCore.Admission.Inductive.Common.RecursorValidation,
    `Ps.KernelCore.Admission.Inductive.Mutual.Admission,
    `Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops,
    `Ps.KernelCore.Admission.Inductive.Mutual.Analysis,
    `Ps.KernelCore.Admission.Inductive.Mutual.Header,
    `Ps.KernelCore.Admission.Inductive.Mutual.Recursor,
    `Ps.KernelCore.Admission.Inductive.Nested.Admission,
    `Ps.KernelCore.Admission.Inductive.Nested.Commit,
    `Ps.KernelCore.Admission.Inductive.Nested.Discover,
    `Ps.KernelCore.Admission.Inductive.Nested.Flatten,
    `Ps.KernelCore.Admission.Inductive.Nested.Rebase,
    `Ps.KernelCore.Admission.Inductive.Nested.ReservedNames,
    `Ps.KernelCore.Admission.Inductive.Nested.Restore,
    `Ps.KernelCore.Admission.Inductive.Nested.RestoreExpr,
    `Ps.KernelCore.Admission.Inductive.Nested.Types,
    `Ps.KernelCore.Admission.Inductive.Nested.Validation,
    `Ps.KernelCore.Admission.Inductive.Ordinary.Admission,
    `Ps.KernelCore.Admission.Inductive.Ordinary.Constructor,
    `Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission,
    `Ps.KernelCore.Admission.Inductive.Ordinary.Recursor,
    `Ps.KernelCore.Admission.Inductive.Types,
    `Ps.KernelCore.Admission.Quot.Admission,
    `Ps.KernelCore.Admission.Quot.Bootstrap,
    `Ps.KernelCore.Checker.Context,
    `Ps.KernelCore.Checker.DefEq.BinderSpines,
    `Ps.KernelCore.Checker.DefEq.DeltaStep,
    `Ps.KernelCore.Checker.DefEq.FinalRules,
    `Ps.KernelCore.Checker.DefEq.FullShape,
    `Ps.KernelCore.Checker.DefEq.LazyDelta,
    `Ps.KernelCore.Checker.DefEq.Quick,
    `Ps.KernelCore.Checker.DefEq.Shortcuts,
    `Ps.KernelCore.Checker.DefEq.Support,
    `Ps.KernelCore.Checker.Inference,
    `Ps.KernelCore.Checker.Inference.Constant,
    `Ps.KernelCore.Checker.Inference.Core,
    `Ps.KernelCore.Checker.Inference.Helpers,
    `Ps.KernelCore.Checker.Knot,
    `Ps.KernelCore.Checker.Ops,
    `Ps.KernelCore.Checker.Projection,
    `Ps.KernelCore.Checker.Recursor.Analysis,
    `Ps.KernelCore.Checker.Recursor.Reduction,
    `Ps.KernelCore.Checker.Reduction.KernelReductions,
    `Ps.KernelCore.Checker.Reduction.PrimitiveData,
    `Ps.KernelCore.Checker.Reduction.PrimitiveNat,
    `Ps.KernelCore.Checker.Reduction.Primitives,
    `Ps.KernelCore.Checker.Reduction.Whnf,
    `Ps.KernelCore.Checker.Reduction.WhnfCore,
    `Ps.KernelCore.Checker.ResourcePolicy,
    `Ps.KernelCore.Checker.Session,
    `Ps.KernelCore.Checker.State,
    `Ps.KernelCore.Core.Declaration,
    `Ps.KernelCore.Core.Expr,
    `Ps.KernelCore.Core.Level,
    `Ps.KernelCore.Core.LocalContext,
    `Ps.KernelCore.Core.Name,
    `Ps.KernelCore.Core.Substitution.Abstract,
    `Ps.KernelCore.Core.Substitution.Beta,
    `Ps.KernelCore.Core.Substitution.Instantiate,
    `Ps.KernelCore.Core.Substitution.Lift,
    `Ps.KernelCore.Core.Substitution.ListOps,
    `Ps.KernelCore.Environment.Environment,
    `Ps.KernelCore.Environment.Lookup,
    `Ps.KernelCore.Environment.Operations,
    `Ps.KernelCore.Environment.Semantic,
    `Ps.KernelCore.Runtime.Acceleration.Cache,
    `Ps.KernelCore.Runtime.Acceleration.CachePolicy,
    `Ps.KernelCore.Runtime.Acceleration.CacheAnalysis,
    `Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex,
    `Ps.KernelCore.Runtime.Capability.Lean434NativeReduction,
    `Ps.KernelCore.Runtime.Capability.Types,
    `Ps.KernelCore.SelfHost,
    `Ps.KernelCore.Research.ExprV2,
    `Ps.KernelCore.Research.ExprV2Validation,
    `Ps.KernelCore.Research.ExprV2Index,
    `Ps.KernelCore.Research.ExprV2IndexedBuilder,
    `Ps.KernelCore.Research.ExprV2Chunked,
    `Ps.KernelCore.Research.ExprV2ResearchAll,
    `Ps.KernelCore.Research.ExprV2ChunkedBuilder,
    `Ps.KernelCore.Research.ExprV2Lift,
    `Ps.KernelCore.Research.ExprV2PortableValidation,
    `Ps.KernelCore.Research.ExprV2PortableLift,
    `Ps.KernelCore.Research.ExprV2PortableInstantiate,
    `Ps.KernelCore.Research.ExprV2PortableReduction,
    `Ps.KernelCore.Research.ExprV2PortableHeadSequence,
    `Ps.KernelCore.Research.ExprV2PortableHeadMachine,
    `Ps.KernelCore.Research.ExprV2PortableEquality,
    `Ps.KernelCore.Research.ExprV2PortableEqualityBatch,
    `Ps.KernelCore.Research.ExprV2PortableImport,
    `Ps.KernelCore.Research.ExprV2Paged,
    `Ps.KernelCore.Research.ExprV2PagedBuilder,
    `Ps.KernelCore.Research.ExprV2PagedValidation,
    `Ps.KernelCore.Research.ExprV2PagedLift,
    `Ps.KernelCore.Research.ExprV2PagedInstantiate,
    `Ps.KernelCore.Research.ExprV2PagedHeadMachine,
    `Ps.KernelCore.Research.ExprV2PagedEquality,
    `Ps.KernelCore.Research.ExprV2PagedEqualityBatch,
    `Ps.KernelCore.Research.ExprV2PagedImport,
    `Ps.KernelCore.Research.ExprV2PagedWhnfSubset
  ]

-- Native proof-only module ownership; this test root is outside portable PsKernelCore.
lean_lib PsKernelClosedCacheAnalysisProofs where
  srcDir := "test"
  roots := #[`PsKernelClosedCacheAnalysisRegression]

lean_exe psc1_kernel_regression where
  srcDir := "test"
  root := `PsKernelCoreRegression

-- Optional same-run performance comparison; assertions check semantics,
-- timings are observations and do not override correctness qualification.
lean_exe psc1_kernel_perf where
  srcDir := "test"
  root := `PsKernelCorePerformance

lean_exe psc1_kernel_instantiate_perf where
  srcDir := "test"
  root := `PsKernelInstantiatePerformance

lean_exe psc1_kernel_multi_perf where
  srcDir := "test"
  root := `PsKernelMultiInstantiatePerformance

lean_exe psc1_kernel_lift_perf where
  srcDir := "test"
  root := `PsKernelLiftPerformance

lean_exe psc1_kernel_whole_comparison where
  srcDir := "test"
  root := `PsKernelWholeComparison

-- Read-only Lean 4.35 versus PSC1 hotpath profiling; no kernel implementation changes.
lean_exe psc1_kernel_hotpath where
  srcDir := "test"
  root := `PsKernelHotpathProfiling

-- Compare official Lean 4.35 closed checking operations against PSC1.
lean_exe psc1_kernel_matched_official where
  srcDir := "test"
  root := `PsKernelMatchedNative

-- Isolated smart-metadata experiment; no production kernel paths are modified.
lean_exe psc1_kernel_metadata where
  srcDir := "test"
  root := `PsKernelMetadataExperiment

-- Isolated Expression V2 DAG/invariant qualification; not yet a kernel provider.
lean_exe psc1_kernel_expr_v2_regression where
  srcDir := "test"
  root := `PsKernelExprV2Regression

-- Research-only bridge to the complete trusted PSC1 checker; never a kernel backend.
lean_exe psc1_kernel_expr_v2_checker_bridge where
  srcDir := "test"
  root := `PsKernelExprV2FullCheckerBridge

-- Read-only paged function-head WHNF subset vs complete PSC1 checker.
lean_exe psc1_kernel_expr_v2_whnf_subset_regression where
  srcDir := "test"
  root := `PsKernelExprV2WhnfSubsetRegression

-- Full checked DAG input plus direct terminal-inference parity.
lean_exe psc1_kernel_expr_v2_dag_regression where
  srcDir := "test"
  root := `PsKernelExprV2DagRegression

-- Matched complete public DAG/legacy/official checking, with unchanged resources.
lean_exe psc1_kernel_expr_v2_dag_performance where
  srcDir := "test"
  root := `PsKernelExprV2DagPerformance

-- Exact bounded transform semantics, sharing, and hostile input regression.
lean_exe psc1_kernel_expr_v2_transform_regression where
  srcDir := "test"
  root := `PsKernelExprV2TransformRegression

-- Separate infer-only judgments preserve the checked admission boundary.
lean_exe psc1_kernel_expr_v2_infer_only_regression where
  srcDir := "test"
  root := `PsKernelExprV2InferOnlyRegression

-- Host transport only; all semantic decisions use the independently executing checked kernel.
lean_exe psc1_kernel_provider where
  srcDir := "host/kernel-provider"
  root := `KernelProviderMain

-- DAG proof irrelevance with exact V1 budget/order and independent official fixtures.
lean_exe psc1_kernel_expr_v2_proof_irrelevance_regression where
  srcDir := "test"
  root := `PsKernelExprV2ProofIrrelevanceRegression

-- Ordered Nat lazy-delta prefix with exact cold/warm resource and state parity.
lean_exe psc1_kernel_expr_v2_lazy_nat_regression where
  srcDir := "test"
  root := `PsKernelExprV2LazyNatRegression

-- Ordered lazy delta over admitted DAG body IDs, with exact cache/order/resource controls.
lean_exe psc1_kernel_expr_v2_lazy_delta_regression where
  srcDir := "test"
  root := `PsKernelExprV2LazyDeltaRegression

-- Residual full-WHNF, ordered full-shape and function-eta rules over the owning DAG.
lean_exe psc1_kernel_expr_v2_full_shape_regression where
  srcDir := "test"
  root := `PsKernelExprV2FullShapeRegression

-- Matching projections, structure eta, String translation and unit-like terminal DefEq.
lean_exe psc1_kernel_expr_v2_final_rules_regression where
  srcDir := "test"
  root := `PsKernelExprV2FinalRulesRegression

-- Check DAG admission guards against V1 and official Lean.
lean_exe psc1_kernel_expr_v2_admission_guard_regression where
  srcDir := "test"
  root := `PsKernelExprV2AdmissionGuardRegression

-- Check DAG Quot reduction against V1 and official Lean.
lean_exe psc1_kernel_expr_v2_quot_regression where
  srcDir := "test"
  root := `PsKernelExprV2QuotRegression

-- Check generated recursor ownership and DAG non-K iota against V1 and official Lean.
lean_exe psc1_kernel_expr_v2_recursor_regression where
  srcDir := "test"
  root := `PsKernelExprV2RecursorRegression

-- Checked K-major conversion, callback ownership, exact budgets and official parity.
lean_exe psc1_kernel_expr_v2_recursor_k_regression where
  srcDir := "test"
  root := `PsKernelExprV2RecursorKRegression

-- Complete checker state, callback refusal/error ordering and fixed-budget parity.
lean_exe psc1_kernel_expr_v2_owned_state_regression where
  srcDir := "test"
  root := `PsKernelExprV2OwnedStateRegression

-- Exact comparison workers, Unicode/raw-position parity, and real checked named declarations.
lean_exe psc1_kernel_name_worker_regression where
  root := `PsKernelNameWorkerRegression
  srcDir := "test"

-- Checked same-batch Quot metadata, immutable caller IDs, and exact V1/official parity.
lean_exe psc1_kernel_expr_v2_quot_owner_regression where
  root := `PsKernelExprV2QuotOwnerRegression
  srcDir := "test"

-- Actual pinned String/Char/List declarations, independently admitted native and generated.
lean_exe psc1_kernel_expr_v2_string_environment_regression where
  root := `PsKernelExprV2StringEnvironmentRegression
  srcDir := "test"

-- Native-only T05 header equations stay outside the portable production closure.
lean_lib PsKernelOrdinaryHeaderProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryHeaderStateProofs, `PsKernelOrdinaryOccurrenceProofs]

lean_exe psc1_kernel_ordinary_header_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryHeaderRegression

-- Native-only dependencies for paged storage and constructor correspondence proofs.
lean_lib PsKernelExprV2MetadataNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelExprV2MetadataProofs]

lean_lib PsKernelExprV2PagedModelNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelExprV2PagedModelProofs]

lean_lib PsKernelOrdinaryConstructorNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryConstructorParamsProofs, `PsKernelOrdinaryConstructorResultProofs]

lean_exe psc1_kernel_ordinary_constructor_params_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryConstructorParamsRegression

lean_exe psc1_kernel_ordinary_constructor_result_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryConstructorResultRegression

-- Native-only constructor-field protocols; production remains private.
lean_lib PsKernelOrdinaryFieldsNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryRecursiveArgumentProofs, `PsKernelOrdinaryConstructorFieldsProofs]

lean_exe psc1_kernel_ordinary_constructor_fields_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryConstructorFieldsRegression

-- Private closed-constructor owner fork and analysis sequence.
lean_lib PsKernelOrdinaryAnalysisNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryConstructorAnalysisProofs]

lean_exe psc1_kernel_ordinary_constructor_analysis_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryConstructorAnalysisRegression

-- Private constructor sequence and staged metadata owner.
lean_lib PsKernelOrdinaryLoopNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelExprV2OrdinaryConstructorLoopProofs]

lean_exe psc1_kernel_ordinary_constructor_loop_regression where
  srcDir := "test"
  root := `PsKernelExprV2OrdinaryConstructorLoopRegression

-- Private elimination policy; native diagnostics do not publish admission.
lean_lib PsKernelOrdinaryEliminationNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryEliminationProofs]

lean_exe psc1_kernel_ordinary_elimination_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryEliminationRegression

-- Private recursor checking and complete ordinary-admission native protocols.
lean_lib PsKernelOrdinaryAdmissionNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryAdmissionProofs]

lean_exe psc1_kernel_ordinary_admission_private_regression where
  srcDir := "test"
  root := `PsKernelExprV2OrdinaryAdmissionRegression

-- Atomic ordinary admission handoff; native protocol checks stay outside the portable closure.
lean_lib PsKernelOrdinaryAdmissionPublicNativeProofs where
  srcDir := "test"
  roots := #[`PsKernelOrdinaryAdmissionPublicProofs]

lean_exe psc1_kernel_ordinary_admission_public_regression where
  srcDir := "test"
  root := `PsKernelOrdinaryAdmissionPublicRegression
