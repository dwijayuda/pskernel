import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
    `Ps.Foundation.List,
    `Ps.Foundation.Name,
    `Ps.Foundation.Source,
    `Ps.Foundation.Diagnostic,
    `Ps.Foundation.Text
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
    `Ps.Syntax.ParseDo,
    `Ps.Syntax.Operators,
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
    `Ps.CompilerIr.Construct,
    `Ps.CompilerIr.CheckTypes,
    `Ps.CompilerIr.CheckSize,
    `Ps.CompilerIr.Check,
    `Ps.CompilerIr.Specialize,
    `Ps.CompilerIr.Validate
  ]

lean_lib PsBackendCommon where
  srcDir := "packages/backend-common/src"
  roots := #[`Ps.BackendCommon.Plan]

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
  roots := #[`Ps.Compiler, `Ps.Compiler.Api, `Ps.Compiler.Ordinary, `Ps.Compiler.Sh1]

lean_lib PsBackendTs where
  srcDir := "packages/backend-ts/src"
  roots := #[
    `Ps.BackendTs.Type,
    `Ps.BackendTs.Expr,
    `Ps.BackendTs.Module,
    `Ps.BackendTs.Checked,
    `Ps.BackendTs.Sh1Target,
    `Ps.BackendTs.Sh1,
    `Ps.BackendTs.Compiler
  ]

-- Target libraries remain outside the portable bootstrap import closure.
lean_lib PsBackendJs where
  srcDir := "packages/backend-js/src"
  roots := #[
    `Ps.BackendJs.Model,
    `Ps.BackendJs.TailAlias,
    `Ps.BackendJs.Encode,
    `Ps.BackendJs.Lower,
    `Ps.BackendJs.Validate,
    `Ps.BackendJs.Print
  ]

lean_lib PsBackendRust where
  srcDir := "packages/backend-rust/src"
  roots := #[
    `Ps.BackendRust.Identifier,
    `Ps.BackendRust.Type,
    `Ps.BackendRust.ValueRefs,
    `Ps.BackendRust.Captures,
    `Ps.BackendRust.Expr,
    `Ps.BackendRust.TailAlias,
    `Ps.BackendRust.Tail,
    `Ps.BackendRust.Runtime,
    `Ps.BackendRust.RuntimePlan,
    `Ps.BackendRust.Module
  ]

lean_lib PsBackendWasm where
  srcDir := "packages/backend-wasm/src"
  roots := #[
    `Ps.BackendWasm.Model,
    `Ps.BackendWasm.IntUtil,
    `Ps.BackendWasm.Type,
    `Ps.BackendWasm.RuntimeNat,
    `Ps.BackendWasm.RuntimeInt,
    `Ps.BackendWasm.RuntimeString,
    `Ps.BackendWasm.RuntimeIntRepr,
    `Ps.BackendWasm.LowerInt,
    `Ps.BackendWasm.LowerFloat,
    `Ps.BackendWasm.TailCalls,
    `Ps.BackendWasm.Lower,
    `Ps.BackendWasm.Encode,
    `Ps.BackendWasm.Binary,
    `Ps.BackendWasm.RuntimePlan
  ]

lean_lib PsBackendPython where
  srcDir := "packages/backend-python/src"
  roots := #[`Ps.BackendPython.Runtime, `Ps.BackendPython.Module]

lean_lib PsBackendPhp where
  srcDir := "packages/backend-php/src"
  roots := #[`Ps.BackendPhp.Runtime, `Ps.BackendPhp.Module]

-- Independent admission is host-only; logical checking is never delegated to
-- formatters, transport code, the elaborator or an unvalidated raw IR wrapper.
lean_lib PsKernelLean where
  srcDir := "packages/pskernel-lean/provider"
  roots := #[`PsKernelLean.Error, `PsKernelLean.Convert, `PsKernelLean.Protocol,
    `PsKernelLean.Prelude, `PsKernelLean.Admission, `PsKernelLean.Main]

lean_lib PsBootstrap where
  srcDir := "packages/bootstrap/src"
  roots := #[`Ps.Bootstrap.SelfHost]

lean_lib PsHost where
  srcDir := "host/src"
  roots := #[
    `Ps.Host.TypeScriptCompiler,
    `Ps.Host.ProjectCompiler,
    `Ps.Host.SourceSnapshot,
    `Ps.Host.ArtifactBundle,
    `Ps.Host.CompilerDriver,
    `Ps.Host.LeanChecked,
    `Ps.Host.DirectSourceMap,
    `Ps.Host.DirectBackend,
    `Ps.Host.ScriptBackend,
    `Ps.Host.WasmComponent
  ]

-- Preserve existing regression and historical bootstrap targets. The scoped
-- correctness workflow deliberately does not run full self-host qualification.
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
    `Ps.Elab.Basic,
    `Ps.Elab.Do,
    `Ps.Elab.Operators,
    `Ps.Elab.Term,
    `Ps.Elab.Recursion,
    `Ps.Elab.Declaration
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

lean_exe psc1_ir_check_tests where
  srcDir := "test"
  root := `IrCheckerTests

lean_exe psc1_ir_specialize_tests where
  srcDir := "test"
  root := `IrSpecializeTests

lean_exe psc1_direct_map_tests where
  srcDir := "test"
  root := `DirectSourceMapTests

lean_exe psc1_lean_kernel_provider_tests where
  srcDir := "packages/pskernel-lean/provider-test"
  root := `PsKernelLeanTests

lean_exe psc1_scoped_tests where
  srcDir := "test"
  root := `ScopedCorrectnessTests

lean_exe psc1_snapshot_tests where
  srcDir := "test"
  root := `SourceSnapshotTests

lean_exe psc1_erasure_tests where
  srcDir := "test"
  root := `ErasureTests

lean_exe psc2_minimal_selfhost_tests where
  srcDir := "test"
  root := `MinimalSelfHostTests

lean_exe psc2_prod_match_selfhost_tests where
  srcDir := "test"
  root := `ProdMatchSelfHostTests

lean_exe psc2_joint_closure_inventory where
  srcDir := "scripts"
  root := `JointClosureInventory

lean_exe psc2_selfhost_replay_audit where
  srcDir := "scripts"
  root := `SelfhostReplayAudit

lean_exe psc1_sh1_compile where
  srcDir := "scripts"
  root := `StrictSourceCompile

lean_exe contextual_inference_tests where
  srcDir := "test"
  root := `ContextualInferenceTests

lean_exe psc1_do_tests where
  srcDir := "test"
  root := `DoTests

lean_exe psc1_operator_tests where
  srcDir := "test"
  root := `OperatorTests

lean_exe psc1_ordinary_tests where
  srcDir := "test"
  root := `OrdinaryExecutionTests

lean_exe psc1_backend_common_tests where
  srcDir := "test"
  root := `BackendCommonTests

lean_exe psc1_runtime_oracle where
  srcDir := "test"
  root := `RuntimeOracle
