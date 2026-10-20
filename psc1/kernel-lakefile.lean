import Lake
open Lake DSL

package proofscriptSelfhost

-- Isolated kernel qualifier: explicitly enumerate native dependencies so
-- Lake compiles this portable source tree independently of compiler targets.
lean_lib PsKernelCore where
  srcDir := "packages/pskernel-core/src"
  roots := #[
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
    `Ps.KernelCore.Research.ExprV2Lift
  ]

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
