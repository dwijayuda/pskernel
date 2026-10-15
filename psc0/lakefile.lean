import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
    `Ps.Foundation.List,
    `Ps.Foundation.Index,
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
    `Ps.Syntax.Translate,
    `Ps.Syntax.Pscv0.Universe,
    `Ps.Syntax.Pscv0.Interpolation,
    `Ps.Syntax.Pscv0.TermParts,
    `Ps.Syntax.Pscv0.ProofRead,
    `Ps.Syntax.Pscv0.DoRead,
    `Ps.Syntax.Pscv0.TermRead,
    `Ps.Syntax.Pscv0.PatternRead,
    `Ps.Syntax.Pscv0.LocalRead, `Ps.Syntax.Pscv0.QuantifierRead, `Ps.Syntax.Pscv0.Operators,
    `Ps.Syntax.Pscv0.Surface,
    `Ps.Syntax.Pscv0.Read,
    `Ps.Syntax.Pscv0.Binders,
    `Ps.Syntax.Pscv0.Data,
    `Ps.Syntax.Pscv0.Commands,
    `Ps.Syntax.Pscv0.Instances,
    `Ps.Syntax.Pscv0.ProgramRead,
    `Ps.Syntax.Pscv0.TypePrint,
    `Ps.Syntax.Pscv0.Module
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
    `Ps.Environment.Logic,
    `Ps.Environment.Connectives,
    `Ps.Environment.Decision,
    `Ps.Environment.Prelude,
    `Ps.Environment.SelfHostPrelude,
    `Ps.Environment.StandardArithmetic,
    `Ps.Environment.StandardIntArithmeticData, `Ps.Environment.StandardIntArithmetic,
    `Ps.Environment.StandardFloatConstructorsData, `Ps.Environment.StandardFloatConstructors,
    `Ps.Environment.StandardEquality,
    `Ps.Environment.StandardCollectionEquality,
    `Ps.Environment.StandardToString,
    `Ps.Environment.StandardOption,
    `Ps.Environment.StandardList,
    `Ps.Environment.StandardInhabited,
    `Ps.Environment.StandardProduct,
    `Ps.Environment.StandardExcept,
    `Ps.Environment.StandardGetElem,
    `Ps.Environment.StandardNatOrder,
    `Ps.Environment.StandardHashable, `Ps.Environment.StandardHashFoundationData, `Ps.Environment.StandardUnsignedFoundationData, `Ps.Environment.StandardUnsigned,
    `Ps.Environment.StandardUnsignedOperationsData, `Ps.Environment.StandardUnsignedOperations,
    `Ps.Environment.StandardFloatIdentityData, `Ps.Environment.StandardFloatIdentity,
    `Ps.Environment.StandardSignedIdentityData, `Ps.Environment.StandardSignedIdentity,
    `Ps.Environment.StandardSignedOperationsData, `Ps.Environment.StandardSignedOperations,
    `Ps.Environment.StandardFloatToBitsData, `Ps.Environment.StandardFloatToBits, `Ps.Environment.StandardFloatCanonical,
    `Ps.Environment.StandardSignedScalar, `Ps.Environment.StandardSignedToInt, `Ps.Environment.StandardSignedOfInt, `Ps.Environment.StandardSignedShift, `Ps.Environment.StandardSignedClamp, `Ps.Environment.StandardSignedAbs, `Ps.Environment.StandardSignedOrder, `Ps.Environment.StandardSignedNumeric, `Ps.Environment.StandardBoolWord, `Ps.Environment.StandardUnsignedOrder, `Ps.Environment.StandardUnsignedPower, `Ps.Environment.StandardUnsignedOfInt, `Ps.Environment.StandardUnsignedClamp, `Ps.Environment.StandardSum, `Ps.Environment.StandardByteArray, `Ps.Environment.StandardByteArrayCollection,
    `Ps.Environment.StandardScalarArithmeticData, `Ps.Environment.StandardScalarArithmetic,
    `Ps.Environment.StandardFin,
    `Ps.Environment.StandardNumeric, `Ps.Environment.StandardCoercion,
    `Ps.Environment.StandardReducibility, `Ps.Environment.StandardInt, `Ps.Environment.StandardString,
    `Ps.Environment.StandardArray, `Ps.Environment.StandardListIndex,
    `Ps.Environment.StandardData,
    `Ps.Environment.StandardFormatData,
    `Ps.Environment.StandardFormatBasic,
    `Ps.Environment.StandardFormatSupport,
    `Ps.Environment.StandardFormatMeasure,
    `Ps.Environment.StandardFormatWork,
    `Ps.Environment.StandardFormatRender,
    `Ps.Environment.StandardFormat,
    `Ps.Environment.StandardClass, `Ps.Environment.StandardFormatClass,
    `Ps.Environment.StandardToFormat,
    `Ps.Environment.StandardRepr,
    `Ps.Environment.StandardFormatString,
    `Ps.Environment.StandardReprCollections,
    `Ps.Environment.SelfHostProd,
    `Ps.Environment.StandardSnapshot
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
    `Ps.CompilerIr.Checked,
    `Ps.CompilerIr.Specialize
  ]

lean_lib PsErasure where
  srcDir := "packages/erasure/src"
  roots := #[
    `Ps.Erasure.Basic,
    `Ps.Erasure.Inductive,
    `Ps.Erasure.Structure,
    `Ps.Erasure.StructureRecursor,
    `Ps.Erasure.Recursion,
    `Ps.Erasure.Array, `Ps.Erasure.Unsigned,
    `Ps.Erasure.Expr,
    `Ps.Erasure.Definition
  ]

lean_lib PsCompiler where
  srcDir := "packages/compiler/src"
  roots := #[
    `Ps.Compiler,
    `Ps.Compiler.Api,
    `Ps.Compiler.RecursorLift,
    `Ps.Compiler.Sh1,
    `Ps.Compiler.Pscv0,
    `Ps.Compiler.Pscv0Modules
  ]

lean_lib PsCodegen where
  srcDir := "packages/codegen/src"
  roots := #[`Ps.Codegen.Captures, `Ps.Codegen.Doc, `Ps.Codegen.Names, `Ps.Codegen.Artifact, `Ps.Codegen.Provenance, `Ps.Codegen.Api, `Ps.Codegen.SourceMap]

lean_lib PsBackendTs where
  srcDir := "packages/backend-ts/src"
  roots := #[
    `Ps.BackendTs.Type,
    `Ps.BackendTs.Analysis,
    `Ps.BackendTs.Expr,
    `Ps.BackendTs.Module,
    `Ps.BackendTs.Readable,
    `Ps.BackendTs.Checked,
    `Ps.BackendTs.Sh1Target,
    `Ps.BackendTs.Sh1,
    `Ps.BackendTs.Compiler
  ]

lean_lib PsBackendEcma where
  srcDir := "packages/backend-ecma/src"
  roots := #[`Ps.BackendEcma.Syntax, `Ps.BackendEcma.Hash, `Ps.BackendEcma.Runtime,
    `Ps.BackendEcma.Intrinsic, `Ps.BackendEcma.Lower, `Ps.BackendEcma.Module]

lean_lib PsBackendRust where
  srcDir := "packages/backend-rust/src"
  roots := #[
    `Ps.BackendRust.Identifier, `Ps.BackendRust.Type,
    `Ps.BackendRust.Intrinsic, `Ps.BackendRust.Captures,
    `Ps.BackendRust.TailAlias, `Ps.BackendRust.Layout,
    `Ps.BackendRust.Expr, `Ps.BackendRust.Tail,
    `Ps.BackendRust.Runtime, `Ps.BackendRust.Module]

lean_lib PsBackendWasm where
  srcDir := "packages/backend-wasm/src"
  roots := #[`Ps.BackendWasm.Model, `Ps.BackendWasm.IntUtil,
    `Ps.BackendWasm.Binary, `Ps.BackendWasm.ValidateStructure,
    `Ps.BackendWasm.ValidateTyping, `Ps.BackendWasm.ValidateIr,
    `Ps.BackendWasm.Wat, `Ps.BackendWasm.Names,
    `Ps.BackendWasm.Component, `Ps.BackendWasm.Module,
    `Ps.BackendWasm.TailCalls, `Ps.BackendWasm.RuntimeBuilder,
    `Ps.BackendWasm.Value, `Ps.BackendWasm.Natural, `Ps.BackendWasm.Integer,
    `Ps.BackendWasm.String, `Ps.BackendWasm.Array, `Ps.BackendWasm.Hash, `Ps.BackendWasm.Intrinsic,
    `Ps.BackendWasm.LowerInt, `Ps.BackendWasm.Word, `Ps.BackendWasm.Type,
    `Ps.BackendWasm.Layout, `Ps.BackendWasm.LowerState, `Ps.BackendWasm.Lower,
    `Ps.BackendWasm.AbiPlan, `Ps.BackendWasm.AbiRuntime, `Ps.BackendWasm.AbiSchema,
    `Ps.BackendWasm.AbiMarshal, `Ps.BackendWasm.AbiComponent]

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
    `Ps.Meta.LevelNormalize,
    `Ps.Meta.LevelContext,
    `Ps.Meta.Context, `Ps.Meta.Abstract,
    `Ps.Meta.Iota,
    `Ps.Meta.Recursor,
    `Ps.Meta.NatReduce, `Ps.Meta.Reduce,
    `Ps.Meta.Unify,
    `Ps.Meta.InstanceTarget,
    `Ps.Meta.InstanceCandidate,
    `Ps.Meta.InstanceSearch,
    `Ps.Meta.Synthetic, `Ps.Meta.SynthInstance,
    `Ps.Meta.Infer,
    `Ps.Meta.Inductive, `Ps.Meta.TypeView
  ]

lean_lib PsElab where
  srcDir := "packages/elab/src"
  roots := #[
    `Ps.Elab.Context,
    `Ps.Elab.Literal,
    `Ps.Elab.Basic,
    `Ps.Elab.Postponed,
    `Ps.Elab.Universe,
    `Ps.Elab.Abstraction,
    `Ps.Elab.Binders,
    `Ps.Elab.Goals,
    `Ps.Elab.GoalSource,
    `Ps.Elab.Elimination,
    `Ps.Elab.Proof,
    `Ps.Elab.Application,
    `Ps.Elab.Record,
    `Ps.Elab.Refinement,
    `Ps.Elab.Equality,
    `Ps.Elab.Match,
    `Ps.Elab.PatternMatrix,
    `Ps.Elab.Conditional,
    `Ps.Elab.Do,
    `Ps.Elab.Term,
    `Ps.Elab.Recursion,
    `Ps.Elab.Data,
    `Ps.Elab.Declaration,
    `Ps.Elab.Class,
    `Ps.Elab.DerivingContext,
    `Ps.Elab.DerivingInhabited,
    `Ps.Elab.DerivingHashable, `Ps.Elab.DerivingBEq,
    `Ps.Elab.DerivingDecEq,
    `Ps.Elab.DerivingRepr,
    `Ps.Elab.Deriving,
    `Ps.Elab.Scope,
    `Ps.Elab.Command
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

-- Native IO adapter for the portable source-owned SH/1 enforcement boundary.
lean_exe psc1_sh1_compile where
  srcDir := "scripts"
  root := `StrictSourceCompile
