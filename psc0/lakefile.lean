import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
    `Ps.Foundation.List,
    `Ps.Foundation.Name,
    `Ps.Foundation.Source,
    `Ps.Foundation.Diagnostic
  ]

lean_lib PsSyntax where
  srcDir := "packages/syntax/src"
  roots := #[
    `Ps.Syntax.Token,
    `Ps.Syntax.Cursor,
    `Ps.Syntax.Lexer,
    `Ps.Syntax.Ast,
    `Ps.Syntax.ParserState,
    `Ps.Syntax.ParseCommon,
    `Ps.Syntax.ParseLean,
    `Ps.Syntax.ParseProofScript,
    `Ps.Syntax.PrintCommon,
    `Ps.Syntax.PrintLean,
    `Ps.Syntax.PrintProofScript,
    `Ps.Syntax.Translate
  ]

lean_lib PsCore where
  srcDir := "packages/core/src"
  roots := #[
    `Ps.Core.Level,
    `Ps.Core.Expr,
    `Ps.Core.Abstract,
    `Ps.Core.Builtin,
    `Ps.Core.LevelSubst,
    `Ps.Core.Equality,
    `Ps.Core.Subst,
    `Ps.Core.Declaration
  ]

lean_lib PsEnvironment where
  srcDir := "packages/environment/src"
  roots := #[
    `Ps.Environment.Basic,
    `Ps.Environment.LocalContext,
    `Ps.Environment.Instances,
    `Ps.Environment.Resolve,
    `Ps.Environment.Prelude,
    `Ps.Environment.SelfHostPrelude,
    `Ps.Environment.SelfHostProd
  ]

lean_lib PsBridge where
  srcDir := "packages/bridge/src"
  roots := #[
    `Ps.Bridge.Json,
    `Ps.Bridge.CheckedAdmissions,
    `Ps.Bridge.Codec,
    `Ps.Bridge.Protocol
  ]

lean_lib PsCompilerIr where
  srcDir := "packages/compiler-ir/src"
  roots := #[
    `Ps.CompilerIr.Model,
    `Ps.CompilerIr.Specialize
  ]

lean_lib PsErasure where
  srcDir := "packages/erasure/src"
  roots := #[
    `Ps.Erasure.Basic,
    `Ps.Erasure.Inductive,
    `Ps.Erasure.Structure,
    `Ps.Erasure.StructureRecursor,
    `Ps.Erasure.Expr,
    `Ps.Erasure.Definition
  ]

lean_lib PsCompiler where
  srcDir := "packages/compiler/src"
  roots := #[
    `Ps.Compiler,
    `Ps.Compiler.Api
  ]

lean_lib PsBackendTs where
  srcDir := "packages/backend-ts/src"
  roots := #[
    `Ps.BackendTs.Type,
    `Ps.BackendTs.Expr,
    `Ps.BackendTs.Module,
    `Ps.BackendTs.Compiler
  ]

lean_lib PsBootstrap where
  srcDir := "packages/bootstrap/src"
  roots := #[`Ps.Bootstrap.SelfHost]

lean_lib PsHost where
  srcDir := "host/src"
  roots := #[
    `Ps.Host.TypeScriptCompiler,
    `Ps.Host.ProjectCompiler,
    `Ps.Host.CompilerDriver
  ]

-- Regression-only extension; compiler fixed-point closure never imports Ps.Project.
-- Source is preserved in legacy while BootstrapTests still exercises it.
lean_lib PsProject where
  srcDir := "legacy/packages/project/src"
  roots := #[`Ps.Project.ModuleGraph]

lean_lib PsMeta where
  srcDir := "packages/meta/src"
  roots := #[
    `Ps.Meta.LevelContext,
    `Ps.Meta.Context,
    `Ps.Meta.Reduce,
    `Ps.Meta.Unify,
    `Ps.Meta.SynthInstance,
    `Ps.Meta.Infer
  ]

lean_lib PsElab where
  srcDir := "packages/elab/src"
  roots := #[
    `Ps.Elab.Context,
    `Ps.Elab.Literal,
    `Ps.Elab.Term,
    `Ps.Elab.Declaration
  ]

lean_lib PsKernelCore where
  srcDir := "packages/pskernel-core/src"
  roots := #[
    `Ps.KernelCore.Core.Name,
    `Ps.KernelCore.Core.Level,
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
    `Ps.KernelCore.SelfHost
  ]


-- Host-only native PSKernel Core provider; never imported by the PSC0 fixed-point root.
lean_lib PsKernelCoreProviderHost where
  srcDir := "host/src"
  roots := #[
    `Ps.Host.KernelCoreProvider.Error, `Ps.Host.KernelCoreProvider.Convert,
    `Ps.Host.KernelCoreProvider.Protocol, `Ps.Host.KernelCoreProvider.Prelude,
    `Ps.Host.KernelCoreProvider.Admission, `Ps.Host.KernelCoreProvider.Response
  ]

lean_exe psc_kernel_core_provider where
  srcDir := "host/src"
  root := `Ps.Host.KernelCoreProvider.Main

lean_exe psc_kernel_core_provider_tests where
  srcDir := "test"
  root := `KernelCoreProviderTests



@[default_target]
lean_exe psc1 where
  srcDir := "packages/cli/src"
  root := `Main

lean_exe psc1_tests where
  srcDir := "test"
  root := `BootstrapTests

lean_exe psc1_translation_tests where
  srcDir := "test"
  root := `TranslationTests

lean_exe psc1_bridge_tests where
  srcDir := "test"
  root := `BridgeTests

lean_exe psc1_backend_ts_tests where
  srcDir := "test"
  root := `BackendTsTests

lean_exe psc1_ir_specialize_tests where
  srcDir := "test"
  root := `IrSpecializeTests

lean_exe psc1_erasure_tests where
  srcDir := "test"
  root := `ErasureTests

lean_exe psc2_minimal_selfhost_tests where
  srcDir := "test"
  root := `MinimalSelfHostTests

lean_exe psc2_prod_match_selfhost_tests where
  srcDir := "test"
  root := `ProdMatchSelfHostTests

-- Host-only diagnostics; this executable is not a portable bootstrap module.
lean_exe psc2_joint_closure_inventory where
  srcDir := "scripts"
  root := `JointClosureInventory

lean_exe psc2_selfhost_replay_audit where
  srcDir := "scripts"
  root := `SelfhostReplayAudit
