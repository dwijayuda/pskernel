import Ps.Compiler.Api
import Ps.BackendRust.Module
import Ps.BackendRust.Coverage

inductive PsCompilerRustError where
  | compiler (error : PsCompilerError)
  | emit (error : PsRustEmitError)

def psCompilerRustEmitErrorCode
    (error : PsRustEmitError) : String :=
  match error with
  | PsRustEmitError.fuelExhausted => "emit.fuel-exhausted"
  | PsRustEmitError.intrinsicArity => "emit.intrinsic-arity"
  | PsRustEmitError.externalImportUnsupported =>
      "emit.external-import"
  | PsRustEmitError.genericValueUnsupported name =>
      String.Internal.append "emit.generic-value:" name
  | PsRustEmitError.functionResultUnsupported name =>
      String.Internal.append "emit.function-result:" name
  | PsRustEmitError.functionStorageUnsupported name =>
      String.Internal.append "emit.function-storage:" name
  | PsRustEmitError.nestedFunctionParameterUnsupported name =>
      String.Internal.append "emit.nested-function-parameter:" name
  | PsRustEmitError.lambdaFunctionParameterUnsupported name =>
      String.Internal.append "emit.lambda-function-parameter:" name
  | PsRustEmitError.lambdaFunctionResultUnsupported =>
      "emit.lambda-function-result"
  | PsRustEmitError.unknownStructure name =>
      String.Internal.append "emit.unknown-structure:" name
  | PsRustEmitError.unknownInductive name =>
      String.Internal.append "emit.unknown-inductive:" name
  | PsRustEmitError.namedTypeArity name =>
      String.Internal.append "emit.named-type-arity:" name
  | PsRustEmitError.unknownRuntimeType =>
      "emit.unknown-runtime-type"

def psCompilerRustErrorCode
    (error : PsCompilerRustError) : String :=
  match error with
  | PsCompilerRustError.compiler _ => "compiler"
  | PsCompilerRustError.emit emitError =>
      psCompilerRustEmitErrorCode emitError

def psCompilerRustFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerRustError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok ir =>
      match psRustEmitValidatedModule ir with
      | Except.error error =>
          Except.error (PsCompilerRustError.emit error)
      | Except.ok output =>
          Except.ok output

def psCompilerRustFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerRustError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok prepared =>
      psCompilerRustFromPrepared prepared

def psCompilerRustSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerRustError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok prepared =>
      psCompilerRustFromPrepared prepared

def psCompilerRustCoverageFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerRustError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok validated =>
      Except.ok
        (psRustCoverageReport
          (psRustCoverageModule validated.raw))

def psCompilerRustCoverageFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerRustError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok prepared =>
      psCompilerRustCoverageFromPrepared prepared

def psCompilerRustProofScriptSources
    (sources : List String) :
    Except PsCompilerRustError String :=
  match
      psCompilerPrepareSources
        PsCompilerSourceKind.proofScript
        sources with
  | Except.error error =>
      Except.error (PsCompilerRustError.compiler error)
  | Except.ok prepared =>
      psCompilerRustFromPrepared prepared
