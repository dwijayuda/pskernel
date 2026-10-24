import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
    `Ps.Foundation.List,
    `Ps.Foundation.Name,
    `Ps.Foundation.StringSet,
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
    `Ps.Syntax.ParseBinding,
    `Ps.Syntax.ParseDo,
    `Ps.Syntax.ParseData,
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
    `Ps.Environment.SelfHostProd,
    `Ps.Environment.Control,
    `Ps.Environment.Order
  ]

lean_lib PsBridge where
  srcDir := "packages/bridge/src"
  roots := #[
    `Ps.Bridge.Json,
    `Ps.Bridge.CheckedAdmissions,
    `Ps.Bridge.Codec,
    `Ps.Bridge.Protocol,
    `Ps.Bridge.CompilerHost
  ]

lean_lib PsCompilerIr where
  srcDir := "packages/compiler-ir/src"
  roots := #[
    `Ps.CompilerIr.Model,
    `Ps.CompilerIr.Encode,
    `Ps.CompilerIr.Construct,
    `Ps.CompilerIr.CheckTypes,
    `Ps.CompilerIr.CheckSize,
    `Ps.CompilerIr.Check,
    `Ps.CompilerIr.Specialize,
    `Ps.CompilerIr.Validate,
    `Ps.CompilerIr.WorkerFusion
  ]

lean_lib PsBackendCommon where
  srcDir := "packages/backend-common/src"
  roots := #[`Ps.BackendCommon.Plan, `Ps.BackendCommon.StateExcept, `Ps.BackendCommon.Source]

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
  roots := #[`Ps.Compiler, `Ps.Compiler.Api, `Ps.Compiler.Ordinary, `Ps.Compiler.Sh1, `Ps.Compiler.Service]

lean_lib PsBackendTs where
  srcDir := "packages/backend-ts/src"
  roots := #[
    `Ps.BackendTs.Type,
    `Ps.BackendTs.Expr,
    `Ps.BackendTs.Module,
    `Ps.BackendTs.Checked,
    `Ps.BackendTs.Sh1Target,
    `Ps.BackendTs.Sh1,
    `Ps.BackendTs.Compiler,
    `Ps.BackendTs.CompilerService
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
    `Ps.BackendJs.Print,
    `Ps.BackendJs.CompilerService
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
    `Ps.BackendRust.Module,
    `Ps.BackendRust.CompilerService
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
    `Ps.BackendWasm.BinaryBytes,
    `Ps.BackendWasm.Binary,
    `Ps.BackendWasm.RuntimePlan,
    `Ps.BackendWasm.ValidateStructure,
    `Ps.BackendWasm.ValidateTyping,
    `Ps.BackendWasm.ValidateIr,
    `Ps.BackendWasm.Component,
    `Ps.BackendWasm.StringAbi,
    `Ps.BackendWasm.StringComponent,
    `Ps.BackendWasm.ServiceAbi,
    `Ps.BackendWasm.CompilerService
  ]

lean_lib PsBackendPython where
  srcDir := "packages/backend-python/src"
  roots := #[`Ps.BackendPython.Runtime, `Ps.BackendPython.Portable, `Ps.BackendPython.Module, `Ps.BackendPython.CompilerService]

lean_lib PsBackendPhp where
  srcDir := "packages/backend-php/src"
  roots := #[`Ps.BackendPhp.Runtime, `Ps.BackendPhp.Portable, `Ps.BackendPhp.Module, `Ps.BackendPhp.CompilerService]

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
    `Ps.Host.BackendNativeInstances,
    `Ps.Host.TypeScriptCompiler,
    `Ps.Host.ProjectCompiler,
    `Ps.Host.SourceSnapshot,
    `Ps.Host.ArtifactBundle,
    `Ps.Host.CompilerDriver,
    `Ps.Host.LeanChecked,
    `Ps.Host.DirectSourceMap,
    `Ps.Host.DirectBackend,
    `Ps.Host.ScriptBackend,
    `Ps.Host.WasmComponent,
    `Ps.Host.WasmString
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
    `Ps.Elab.Data,
    `Ps.Elab.DoLoop,
    `Ps.Elab.DoLoopLift,
    `Ps.Elab.DoForLift,
    `Ps.Elab.DoBase,
    `Ps.Elab.DoFor,
    `Ps.Elab.DoWhile,
    `Ps.Elab.DoTry,
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

lean_lib PsPracticalTestSupport where
  srcDir := "test"
  roots := #[`PracticalExecution]

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

lean_exe psc1_script_ir_tests where
  srcDir := "test"
  root := `BackendScriptTests

lean_exe psc1_data_tests where
  srcDir := "test"
  root := `DataTests

lean_exe psc1_while_tests where
  srcDir := "test"
  root := `WhileTests

lean_lib PsTypedErrorReference where
  srcDir := "test"
  roots := #[`TypedErrorFixtures, `TypedErrorWhileFixture]

lean_exe psc1_typed_error_oracle where
  srcDir := "test"
  root := `TypedErrorOracle

lean_exe psc1_typed_error_tests where
  srcDir := "test"
  root := `TypedErrorTests

lean_exe psc1_namespace_tests where
  srcDir := "test"
  root := `NamespaceTests

lean_exe psc1_source_census_probe where
  srcDir := "scripts"
  root := `SourceCensusProbe

lean_exe psc1_independent_checker where
  srcDir := "packages/pskernel-lean/provider"
  root := `PsKernelLean.Main

lean_exe psc1_census_normalization_tests where
  srcDir := "test"
  root := `CensusNormalizationTests

lean_exe psc1_backend_normalization_tests where
  srcDir := "test"
  root := `BackendNormalizationTests

lean_exe psc1_ir_encoding_tests where
  srcDir := "test"
  root := `IrEncodingTests

lean_exe psc1_js_service_seed where
  srcDir := "scripts"
  root := `JsServiceSeed

lean_exe psc1_js_service_tests where
  srcDir := "test"
  root := `JsServiceTests

lean_exe psc1_specialize_queue_benchmark where
  srcDir := "scripts"
  root := `SpecializeQueueBenchmark

lean_exe psc1_compiler_profile where
  srcDir := "scripts"
  root := `CompilerStageProfile

lean_exe psc1_json_quote_tests where
  srcDir := "test"
  root := `JsonQuoteTests

lean_exe psc1_worker_fusion_tests where
  srcDir := "test"
  root := `WorkerFusionTests

lean_exe psc1_wasm_string_abi_tests where
  srcDir := "test"
  root := `WasmStringAbiTests

lean_exe psc1_ts_continuation_tests where
  srcDir := "test"
  root := `TsContinuationTests

lean_exe psc1_php_utf8_tests where
  srcDir := "test"
  root := `PhpUtf8Tests

lean_exe psc1_target_service_seed where
  srcDir := "scripts"
  root := `TargetServiceSeed

lean_exe psc1_ts_service_normalization_tests where
  srcDir := "test"
  root := `TsServiceNormalizationTests

lean_exe psc1_cursor_normalization_tests where
  srcDir := "test"
  root := `CursorNormalizationTests

lean_exe psc1_target_plan_profile_tests where
  srcDir := "test"
  root := `TargetPlanProfileTests

lean_exe psc1_lexer_normalization_tests where
  srcDir := "test"
  root := `LexerNormalizationTests

lean_exe psc1_codec_static_schema_tests where
  root := `CodecStaticSchemaTests
  srcDir := "test"

lean_exe psc1_json_escape_predicate_tests where
  srcDir := "test"
  root := `JsonEscapePredicateTests

lean_exe psc1_bridge_lookup_normalization_tests where
  srcDir := "test"
  root := `BridgeLookupNormalizationTests

lean_exe psc1_ts_utf8_view_tests where
  srcDir := "test"
  root := `TsUtf8ViewTests

lean_exe psc1_erasure_worker_normalization_tests where
  srcDir := "test"
  root := `ErasureWorkerNormalizationTests


lean_exe psc1_ir_encoder_worker_normalization_tests where
  srcDir := "test"
  root := `IrEncoderWorkerNormalizationTests


lean_exe psc1_text_lookup_worker_normalization_tests where
  srcDir := "test"
  root := `TextLookupWorkerNormalizationTests

lean_lib PsWasmBinaryCarrierReference where
  srcDir := "test"
  roots := #[`WasmBinaryReference, `WasmBinaryCarrierTests]

lean_exe psc1_direct_selfhost_preflight_tests where
  srcDir := "test"
  root := `DirectSelfHostPreflightTests

lean_lib PsJsStatementReference where
  srcDir := "test"
  roots := #[`JsStatementReference]

lean_exe psc1_js_statement_tests where
  srcDir := "test"
  root := `JsStatementTests

lean_lib PsWasmPrefixReference where
  srcDir := "test"
  roots := #[`WasmPrefixReference, `WasmPrefixTests]

lean_lib PsOrdinaryExpansionReference where
  srcDir := "test"
  roots := #[`OrdinaryExpansionReference, `OrdinaryExpansionTests]

lean_lib PsCheckedSpineReference where
  srcDir := "test"
  roots := #[`CheckedSpineReference, `CheckedSpineTests]

lean_lib PsErasureSpineReference where
  srcDir := "test"
  roots := #[`ErasureSpineReference, `ErasureSpineTests]

lean_lib PsFoundationListReference where
  srcDir := "test"
  roots := #[`FoundationListReference, `FoundationListTests]

lean_lib PsWasmLowerExprPrefixReference where
  srcDir := "test"
  roots := #[`WasmLowerExprPrefixReference, `WasmLowerExprPrefixTests]

lean_lib PsSharedLookupPrefixReference where
  srcDir := "test"
  roots := #[`SharedLookupPrefixReference, `SharedLookupPrefixTests]

lean_lib PsWasmEncodingSpineReference where
  srcDir := "test"
  roots := #[`WasmEncodingSpineReference, `WasmEncodingSpineTests]

lean_lib PsJsAppliedPrefixReference where
  srcDir := "test"
  roots := #[`JsAppliedPrefixReference, `JsAppliedPrefixTests]

lean_lib PsScriptRuntimeReference where
  srcDir := "test"
  roots := #[`ScriptRuntimeReference]

lean_exe psc1_script_runtime_normalization_tests where
  srcDir := "test"
  root := `ScriptRuntimeNormalizationTests

lean_lib PsBackendStateReference where
  srcDir := "test"
  roots := #[`BackendStateReference]

lean_exe psc1_backend_state_correspondence_tests where
  srcDir := "test"
  root := `BackendStateCorrespondenceTests

lean_lib PsScriptEmitterReference where
  srcDir := "test"
  roots := #[`ScriptEmitterReference]

lean_exe psc1_script_emitter_normalization_tests where
  srcDir := "test"
  root := `ScriptEmitterNormalizationTests

lean_exe psc1_php_capture_tests where
  srcDir := "test"
  root := `PhpCaptureScopeTests

lean_exe psc1_php_packed_tests where
  srcDir := "test"
  root := `PhpPackedLayoutTests

lean_exe psc1_python_utf8_tests where
  srcDir := "test"
  root := `PythonUtf8CacheTests
