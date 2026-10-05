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

lean_lib PsBackendRust where
  srcDir := "packages/backend-rust/src"
  roots := #[
    `Ps.BackendRust.Identifier,
    `Ps.BackendRust.Type,
    `Ps.BackendRust.Expr,
    `Ps.BackendRust.ValueRefs,
    `Ps.BackendRust.Runtime,
    `Ps.BackendRust.Module,
    `Ps.BackendRust.Coverage,
    `Ps.BackendRust.Compiler
  ]

lean_lib PsBackendWasm where
  srcDir := "packages/backend-wasm/src"
  roots := #[
    `Ps.BackendWasm.Model,
    `Ps.BackendWasm.Type,
    `Ps.BackendWasm.LowerInt,
    `Ps.BackendWasm.LowerFloat,
    `Ps.BackendWasm.RuntimeNat,
    `Ps.BackendWasm.RuntimeInt,
    `Ps.BackendWasm.Binary,
    `Ps.BackendWasm.Lower
  ]

lean_lib PsHost where
  srcDir := "host/src"
  roots := #[
    `Ps.Host.TypeScriptCompiler,
    `Ps.Host.ProjectCompiler,
    `Ps.Host.CompilerDriver
  ]

lean_lib PsProject where
  srcDir := "packages/project/src"
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

lean_lib PsKernelOwned where
  srcDir := "packages/pskernel-core/src"
  roots := #[
    `Ps.Kernel.Data, `Ps.Kernel.Structural, `Ps.Kernel.Natural,
    `Ps.Kernel.Expr, `Ps.Kernel.Binding, `Ps.Kernel.Order,
    `Ps.Kernel.Universe, `Ps.Kernel.LevelCheck, `Ps.Kernel.LevelInstantiate, `Ps.Kernel.ExprInstantiate, `Ps.Kernel.BuiltinNat, `Ps.Kernel.BuiltinText, `Ps.Kernel.Environment,
    `Ps.Kernel.Reduction, `Ps.Kernel.Conversion, `Ps.Kernel.TypeCheck,
    `Ps.Kernel.Admission, `Ps.Kernel.UnitInductive, `Ps.Kernel.NatInductive, `Ps.Kernel.RecordInductive,
    `Ps.Kernel.EnumInductive, `Ps.Kernel.SumInductive, `Ps.Kernel.AlgebraicData, `Ps.Kernel.AlgebraicReduction, `Ps.Kernel.AlgebraicHeader, `Ps.Kernel.Closing, `Ps.Kernel.Occurrence, `Ps.Kernel.ExpressionEquality, `Ps.Kernel.Positivity, `Ps.Kernel.AlgebraicConstructor, `Ps.Kernel.Parameters, `Ps.Kernel.AlgebraicMinor, `Ps.Kernel.AlgebraicRecursor, `Ps.Kernel.AlgebraicAdmission, `Ps.Kernel.Bootstrap, `Ps.Kernel.JointAdmission, `Ps.Kernel.Bootstrap
  ]

lean_lib PSC1KernelReferenceFoundations where
  srcDir := "packages/pskernel"
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
    `PSC1Kernel.NestedInductive
  ]

lean_lib PsKernelSelfHost where
  srcDir := "packages/pskernel-selfhost/src"
  roots := #[
    `Ps.KernelSelfHost.Name,
    `Ps.KernelSelfHost.Level,
    `Ps.KernelSelfHost.Expr,
    `Ps.KernelSelfHost.Theory.Substitution.ListOps,
    `Ps.KernelSelfHost.Theory.Substitution.Lift,
    `Ps.KernelSelfHost.Theory.Substitution.Instantiate,
    `Ps.KernelSelfHost.Theory.Substitution.Beta,
    `Ps.KernelSelfHost.Theory.Substitution.Abstract,
    `Ps.KernelSelfHost.Instantiate,
    `Ps.KernelSelfHost.Declaration,
    `Ps.KernelSelfHost.LocalContext,
    `Ps.KernelSelfHost.Runtime.Acceleration.EnvironmentIndex,
    `Ps.KernelSelfHost.Runtime.EnvironmentIndex,
    `Ps.KernelSelfHost.Environment,
    `Ps.KernelSelfHost.Runtime.Acceleration.Cache,
    `Ps.KernelSelfHost.Runtime.Acceleration.CachePolicy,
    `Ps.KernelSelfHost.Runtime.Cache,
    `Ps.KernelSelfHost.Runtime.Capability.Lean434NativeReduction,
    `Ps.KernelSelfHost.Runtime.NativeReduction,
    `Ps.KernelSelfHost.Checker.State,
    `Ps.KernelSelfHost.CheckerState,
    `Ps.KernelSelfHost.Checker.Context,
    `Ps.KernelSelfHost.TypeCheckerBase,
    `Ps.KernelSelfHost.Checker.Reduction.PrimitiveData,
    `Ps.KernelSelfHost.Theory.Reduction.PrimitiveData,
    `Ps.KernelSelfHost.Checker.Reduction.PrimitiveNat,
    `Ps.KernelSelfHost.Theory.Reduction.PrimitiveNat,
    `Ps.KernelSelfHost.Checker.Reduction.Primitives,
    `Ps.KernelSelfHost.TypeCheckerPrimitives,
    `Ps.KernelSelfHost.Checker.Reduction.KernelReductions,
    `Ps.KernelSelfHost.Theory.Reduction.KernelReductions,
    `Ps.KernelSelfHost.Checker.Reduction.WhnfCore,
    `Ps.KernelSelfHost.Theory.Reduction.WhnfCore,
    `Ps.KernelSelfHost.Checker.Reduction.Whnf,
    `Ps.KernelSelfHost.TypeCheckerWhnf,
    `Ps.KernelSelfHost.Checker.Projection,
    `Ps.KernelSelfHost.TypeCheckerProjection,
    `Ps.KernelSelfHost.Checker.Inference.Helpers,
    `Ps.KernelSelfHost.Theory.Inference.Helpers,
    `Ps.KernelSelfHost.Checker.Inference.Core,
    `Ps.KernelSelfHost.Theory.Inference.Core,
    `Ps.KernelSelfHost.Checker.Inference,
    `Ps.KernelSelfHost.TypeCheckerInfer,
    `Ps.KernelSelfHost.Checker.Recursor.Analysis,
    `Ps.KernelSelfHost.Theory.Recursor.Analysis,
    `Ps.KernelSelfHost.Checker.Recursor.Reduction,
    `Ps.KernelSelfHost.Theory.Recursor.Reduction,
    `Ps.KernelSelfHost.Checker.Recursor,
    `Ps.KernelSelfHost.TypeCheckerRecursor,
    `Ps.KernelSelfHost.Checker.DefEq.BinderSpines,
    `Ps.KernelSelfHost.Theory.DefEq.BinderSpines,
    `Ps.KernelSelfHost.Checker.DefEq.Quick,
    `Ps.KernelSelfHost.Theory.DefEq.Quick,
    `Ps.KernelSelfHost.Checker.DefEq.Support,
    `Ps.KernelSelfHost.TypeCheckerDefEqSupport,
    `Ps.KernelSelfHost.Checker.DefEq.DeltaStep,
    `Ps.KernelSelfHost.Theory.DefEq.DeltaStep,
    `Ps.KernelSelfHost.Checker.DefEq.LazyDelta,
    `Ps.KernelSelfHost.Theory.DefEq.LazyDelta,
    `Ps.KernelSelfHost.Checker.DefEq.FinalRules,
    `Ps.KernelSelfHost.Theory.DefEq.FinalRules,
    `Ps.KernelSelfHost.Checker.DefEq.Shortcuts,
    `Ps.KernelSelfHost.Theory.DefEq.Shortcuts,
    `Ps.KernelSelfHost.Checker.DefEq.FullShape,
    `Ps.KernelSelfHost.Theory.DefEq.FullShape,
    `Ps.KernelSelfHost.Checker.DefEq,
    `Ps.KernelSelfHost.TypeCheckerDefEq,
    `Ps.KernelSelfHost.Checker.Session,
    `Ps.KernelSelfHost.CheckerSession,
    `Ps.KernelSelfHost.Theory.Admission.Validation,
    `Ps.KernelSelfHost.Theory.Admission.Declarations,
    `Ps.KernelSelfHost.Kernel,
    `Ps.KernelSelfHost.Theory.Quot.Bootstrap,
    `Ps.KernelSelfHost.Theory.Quot.Admission,
    `Ps.KernelSelfHost.Quot,
    `Ps.KernelSelfHost.Inductive,
    `Ps.KernelSelfHost.Theory.Inductive.Constructor,
    `Ps.KernelSelfHost.Theory.Inductive.ConstructorAdmission,
    `Ps.KernelSelfHost.Theory.Inductive.Recursor,
    `Ps.KernelSelfHost.Theory.Inductive.Elimination,
    `Ps.KernelSelfHost.InductiveAdmission,
    `Ps.KernelSelfHost.Theory.Mutual.Analysis,
    `Ps.KernelSelfHost.Theory.Mutual.Recursor,
    `Ps.KernelSelfHost.Theory.Mutual.Header,
    `Ps.KernelSelfHost.Theory.Mutual.AdmissionLoops,
    `Ps.KernelSelfHost.Theory.Mutual.Admission,
    `Ps.KernelSelfHost.MutualInductive,
    `Ps.KernelSelfHost.Theory.Nested.Types,
    `Ps.KernelSelfHost.Theory.Nested.ReservedNames,
    `Ps.KernelSelfHost.Theory.Nested.Rebase,
    `Ps.KernelSelfHost.Theory.Nested.Discover,
    `Ps.KernelSelfHost.Theory.Nested.Flatten,
    `Ps.KernelSelfHost.Theory.Nested.RestoreExpr,
    `Ps.KernelSelfHost.Theory.Nested.Restore,
    `Ps.KernelSelfHost.Theory.Nested.Validation,
    `Ps.KernelSelfHost.Theory.Nested.Commit,
    `Ps.KernelSelfHost.Theory.Nested.Admission,
    `Ps.KernelSelfHost.NestedInductive,
    `Ps.KernelSelfHost.SelfHost
  ]

lean_lib PsKernelSelfHostTestSupport where
  srcDir := "test"
  roots := #[
    `KernelSelfHost.Foundation.Core,
    `KernelSelfHost.Foundation.Checking,
    `KernelSelfHost.Foundation.DefEqNested,
    `KernelSelfHost.Foundation.AdmissionRuntime,
    `KernelSelfHost.Bench.Foundation,
    `KernelSelfHost.Bench.Inference,
    `KernelSelfHost.Bench.Inductive,
    `KernelSelfHost.Bench.Nested
  ]

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

lean_exe psc1_backend_wasm_tests where
  srcDir := "test"
  root := `BackendWasmTests

lean_exe psc1_ir_specialize_tests where
  srcDir := "test"
  root := `IrSpecializeTests

lean_exe psc1_backend_rust_tests where
  srcDir := "test"
  root := `BackendRustTests

lean_exe psc1_backend_rust_let_function_result_tests where
  srcDir := "test"
  root := `BackendRustLetFunctionResultTests

lean_exe psc1_backend_rust_let_function_result_fixture where
  srcDir := "test"
  root := `BackendRustLetFunctionResultFixture

lean_exe psc1_backend_rust_fixture where
  srcDir := "test"
  root := `BackendRustFixture

lean_exe psc1_backend_rust_source_tests where
  srcDir := "test"
  root := `BackendRustSourceTests

lean_exe psc1_backend_diff_fixture where
  srcDir := "test"
  root := `BackendDifferentialFixture

lean_exe psc1_backend_wasm_binary_smoke where
  srcDir := "test"
  root := `WasmBinarySmoke

lean_exe psc1_erasure_tests where
  srcDir := "test"
  root := `ErasureTests

lean_exe psc2_minimal_selfhost_tests where
  srcDir := "test"
  root := `MinimalSelfHostTests

lean_exe psc2_prod_match_selfhost_tests where
  srcDir := "test"
  root := `ProdMatchSelfHostTests

lean_exe psc1_kernel_selfhost_foundation_tests where
  srcDir := "test"
  root := `PsKernelSelfHostFoundationTests

lean_exe psc1_kernel_selfhost_bench where
  srcDir := "test"
  root := `PsKernelSelfHostBench

-- Host-only diagnostics; this executable is not a portable bootstrap module.
lean_exe psc2_joint_closure_inventory where
  srcDir := "scripts"
  root := `JointClosureInventory

lean_exe psc2_selfhost_replay_audit where
  srcDir := "scripts"
  root := `SelfhostReplayAudit
