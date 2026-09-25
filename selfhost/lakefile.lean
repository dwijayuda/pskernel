import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
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
    `Ps.Environment.Prelude
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
    `Ps.Erasure.Expr,
    `Ps.Erasure.Definition
  ]

lean_lib PsBackendTs where
  srcDir := "packages/backend-ts/src"
  roots := #[
    `Ps.BackendTs.Type,
    `Ps.BackendTs.Expr,
    `Ps.BackendTs.Module
  ]

lean_lib PsBackendWasm where
  srcDir := "packages/backend-wasm/src"
  roots := #[
    `Ps.BackendWasm.Model,
    `Ps.BackendWasm.Type,
    `Ps.BackendWasm.RuntimeNat,
    `Ps.BackendWasm.RuntimeInt,
    `Ps.BackendWasm.RuntimeArray,
    `Ps.BackendWasm.RuntimeString,
    `Ps.BackendWasm.LowerInt,
    `Ps.BackendWasm.LowerFloat,
    `Ps.BackendWasm.Binary,
    `Ps.BackendWasm.Lower
  ]

lean_lib PsCompiler where
  srcDir := "packages/compiler/src"
  roots := #[
    `Ps.Compiler,
    `Ps.Compiler.Api
  ]

lean_lib PsHost where
  srcDir := "host/src"
  roots := #[
    `Ps.Host.TypeScriptCompiler,
    `Ps.Host.ProjectCompiler,
    `Ps.Host.CompilerDriver,
    `Ps.Host.KernelBridge
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

lean_exe psc1_backend_wasm_binary_smoke where
  srcDir := "test"
  root := `WasmBinarySmoke

lean_exe psc1_erasure_tests where
  srcDir := "test"
  root := `ErasureTests

lean_exe psc1_bridge_host_tests where
  srcDir := "test"
  root := `BridgeHostTests
