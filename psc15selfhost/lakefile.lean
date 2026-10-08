import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
    `Ps.Foundation.List,
    `Ps.Foundation.Name,
    `Ps.Foundation.Text,
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
    `Ps.CompilerIr.PublicApi,
    `Ps.CompilerIr.PublicApiEncode,
    `Ps.CompilerIr.SourceSignature,
    `Ps.CompilerIr.SourceSignatureEncode,
    `Ps.CompilerIr.Model,
    `Ps.CompilerIr.Encode,
    `Ps.CompilerIr.Decode,
    `Ps.CompilerIr.LinkArtifact,
    `Ps.CompilerIr.ValidateArtifact,
    `Ps.CompilerIr.InterfaceArtifact,
    `Ps.CompilerIr.Validate,
    `Ps.CompilerIr.Interface,
    `Ps.CompilerIr.JsAbi,
    `Ps.CompilerIr.Link,
    `Ps.CompilerIr.Pass,
    `Ps.CompilerIr.Specialize
  ]

lean_lib PsInterfaceTs where
  srcDir := "packages/interface-ts/src"
  roots := #[`Ps.InterfaceTs.Declarations, `Ps.InterfaceTs.Request]

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
    `Ps.BackendTs.Module
  ]

lean_lib PsBackendJs where
  srcDir := "packages/backend-js/src"
  roots := #[
    `Ps.BackendJs.Model,
    `Ps.BackendJs.Lower,
    `Ps.BackendJs.Validate,
    `Ps.BackendJs.Encode,
    `Ps.BackendJs.Print,
    `Ps.BackendJs.TailAlias
  ]

lean_lib PsDriverTs where
  srcDir := "packages/driver-ts/src"
  roots := #[`Ps.DriverTs.Compiler, `Ps.DriverTs.Bootstrap, `Ps.DriverTs.Stages]

lean_lib PsDriverJs where
  srcDir := "packages/driver-js/src"
  roots := #[`Ps.DriverJs.Compiler, `Ps.DriverJs.Bootstrap, `Ps.DriverJs.Stages, `Ps.DriverJs.Declarations]

lean_lib PsDriverWasm where
  srcDir := "packages/driver-wasm/src"
  roots := #[`Ps.DriverWasm.Compiler, `Ps.DriverWasm.Bootstrap, `Ps.DriverWasm.Stages, `Ps.DriverWasm.Canonical, `Ps.DriverWasm.SelfHostProgress]

lean_lib PsBootstrap where
  srcDir := "packages/bootstrap/src"
  roots := #[`Ps.Bootstrap.SelfHost, `Ps.Bootstrap.SelfHostJs, `Ps.Bootstrap.SelfHostWasm, `Ps.Bootstrap.SelfHostRust]

lean_lib PsBackendRust where
  srcDir := "packages/backend-rust/src"
  roots := #[
    `Ps.BackendRust.Identifier,
    `Ps.BackendRust.Type,
    `Ps.BackendRust.Expr,
    `Ps.BackendRust.Tail,
    `Ps.BackendRust.TailAlias,
    `Ps.BackendRust.ValueRefs,
    `Ps.BackendRust.Captures,
    `Ps.BackendRust.Runtime,
    `Ps.BackendRust.Module
  ]

lean_lib PsDriverRust where
  srcDir := "packages/driver-rust/src"
  roots := #[`Ps.DriverRust.Compiler, `Ps.DriverRust.Bootstrap, `Ps.DriverRust.Stages]

lean_lib PsBackendWasm where
  srcDir := "packages/backend-wasm/src"
  roots := #[
    `Ps.BackendWasm.Model,
    `Ps.BackendWasm.TailCalls,
    `Ps.BackendWasm.Type,
    `Ps.BackendWasm.LowerInt,
    `Ps.BackendWasm.LowerFloat,
    `Ps.BackendWasm.RuntimeNat,
    `Ps.BackendWasm.IntUtil,
    `Ps.BackendWasm.RuntimeInt,
    `Ps.BackendWasm.RuntimeString,
    `Ps.BackendWasm.RuntimeIntRepr,
    `Ps.BackendWasm.Binary,
    `Ps.BackendWasm.Encode,
    `Ps.BackendWasm.Lower,
    `Ps.BackendWasm.Validate,
    `Ps.BackendWasm.ValidateStructure,
    `Ps.BackendWasm.ValidateTyping,
    `Ps.BackendWasm.ValidateIr,
    `Ps.BackendWasm.LiteralEvidence,
    `Ps.BackendWasm.CanonicalExports,
    `Ps.BackendWasm.CanonicalRequest,
    `Ps.BackendWasm.SelfHostAbi
  ]

lean_lib PsHost where
  srcDir := "host/src"
  roots := #[
    `Ps.Host.TypeScriptCompiler,
    `Ps.Host.ProjectCompiler,
    `Ps.Host.ProjectQuery,
    `Ps.Host.RustCoverage,
    `Ps.Host.CompilerDriver
  ]

lean_lib PsProject where
  srcDir := "packages/project/src"
  roots := #[
    `Ps.Project.ModuleGraph,
    `Ps.Project.ModuleInterface,
    `Ps.Project.QueryGraph,
    `Ps.Project.QueryGraphV2
  ]

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
  srcDir := "packages/pskernel-core.old3/src"
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

lean_lib PsCli where
  srcDir := "packages/cli/src"
  roots := #[`PsCli]

@[default_target]
lean_exe psc1 where
  srcDir := "packages/cli/src"
  root := `Main

-- Production-named native compiler. `psc1` remains as the bootstrap/compatibility
-- executable while both targets are built from the same pinned Lean 4.34 sources.
lean_exe psc where
  srcDir := "packages/cli/src"
  root := `PscMain

lean_exe psc1_tests where
  srcDir := "test"
  root := `BootstrapTests

lean_exe psc1_translation_tests where
  srcDir := "test"
  root := `TranslationTests

lean_exe psc1_project_query_graph_tests where
  srcDir := "test"
  root := `ProjectQueryGraphTests

lean_exe pscv_query_graph_v2_tests where
  srcDir := "test"
  root := `QueryGraphV2Tests

lean_exe pscv_wasm_literal_validation_tests where
  srcDir := "test"
  root := `WasmLiteralValidationTests

lean_exe psc1_host_project_query_tests where
  srcDir := "test"
  root := `HostProjectQueryTests

lean_exe psc1_bridge_tests where
  srcDir := "test"
  root := `BridgeTests

lean_exe psc1_backend_ts_tests where
  srcDir := "test"
  root := `BackendTsTests

lean_lib PsBackendJsTestSupport where
  srcDir := "test"
  roots := #[`BackendJsFixture, `BackendJsTailFixture, `BackendJsPropertyFixture]

lean_exe psc1_backend_js_tests where
  srcDir := "test"
  root := `BackendJsTests

lean_exe psc1_backend_js_validate_tests where
  srcDir := "test"
  root := `BackendJsValidateTests

lean_exe psc1_backend_js_diff_fixture where
  srcDir := "test"
  root := `BackendJsDifferentialFixture

lean_exe psc1_backend_wasm_tests where
  srcDir := "test"
  root := `BackendWasmTests

lean_exe psc1_backend_wasm_ir_tests where
  srcDir := "test"
  root := `BackendWasmIrTests

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

lean_exe psc1_wasm_string_runtime_fixture where
  srcDir := "test"
  root := `WasmStringRuntimeFixture

lean_exe psc1_backend_wasm_binary_smoke where
  srcDir := "test"
  root := `WasmBinarySmoke

lean_exe psc1_erasure_tests where
  srcDir := "test"
  root := `ErasureTests

lean_exe psc1_verified_ir_strict_tests where
  srcDir := "test"
  root := `VerifiedIrStrictTests

lean_exe pscv_interface_ir_tests where
  srcDir := "test"
  root := `InterfaceIrTests

lean_exe pscv_js_abi_tests where
  srcDir := "test"
  root := `JsAbiTests

lean_exe pscv_ir_encoding_tests where
  srcDir := "test"
  root := `IrEncodingTests

lean_exe psc2_minimal_selfhost_tests where
  srcDir := "test"
  root := `MinimalSelfHostTests

lean_exe psc2_prod_match_selfhost_tests where
  srcDir := "test"
  root := `ProdMatchSelfHostTests

lean_exe psc1_kernel_core_foundation_tests where
  srcDir := "test"
  root := `PsKernelCoreFoundationTests

lean_exe psc1_kernel_core_bench where
  srcDir := "test"
  root := `PsKernelCoreBench

lean_exe psc1_kernel_cross_runtime_bench where
  srcDir := "test"
  root := `PsKernelCrossRuntimeBench

-- Host-only diagnostics; this executable is not a portable bootstrap module.
lean_exe psc2_joint_closure_inventory where
  srcDir := "scripts"
  root := `JointClosureInventory

lean_exe psc2_selfhost_replay_audit where
  srcDir := "scripts"
  root := `SelfhostReplayAudit

-- M4 host adapter; deliberately outside the portable semantic kernel closure.
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


lean_lib PsPscvTheory where
  srcDir := "packages/pscv-theory/src"
  roots := #[
    `Ps.Theory.Core
  ]

lean_lib PsPscvTheoryProof where
  srcDir := "packages/pscv-theory/proof"
  roots := #[
    `Ps.Theory.Refinement,
    `Ps.Theory.ParserCursor
  ]

lean_exe pscv_theory_seed_tests where
  srcDir := "packages/pscv-theory/test"
  root := `TheorySeedTests


lean_lib PsTheoryBridge where
  srcDir := "packages/theory-bridge/src"
  roots := #[
    `Ps.TheoryBridge.Model,
    `Ps.TheoryBridge.Translate
  ]

lean_lib PsInterfaceIr where
  srcDir := "packages/interface-ir/src"
  roots := #[`Ps.InterfaceIr.Model, `Ps.InterfaceIr.Validate, `Ps.InterfaceIr.Encode, `Ps.InterfaceIr.Wit, `Ps.InterfaceIr.CanonicalAbi]

lean_exe pscv_foreign_interface_tests where
  srcDir := "packages/interface-ir/test"
  root := `ForeignInterfaceTests

lean_exe pscv_theory_bridge_tests where
  srcDir := "packages/theory-bridge/test"
  root := `TheoryBridgeTests

lean_exe pscv_ir_replay where
  srcDir := "host/src"
  root := `Ps.Host.IrReplay

lean_exe pscv_canonical_abi_tests where
  srcDir := "test"
  root := `CanonicalAbiTests

lean_exe pscv_wasm_canonical_exports_tests where
  srcDir := "test"
  root := `WasmCanonicalExportsTests
