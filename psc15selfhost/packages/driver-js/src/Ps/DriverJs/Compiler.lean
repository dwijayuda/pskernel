import Ps.Compiler.Api
import Ps.BackendJs.Print

inductive PsCompilerJavaScriptError where
  | compiler (error : PsCompilerError)
  | emit (error : PsJsEmitError)


def psCompilerJavaScriptCompilerErrorCode
    (error : PsCompilerError) : String :=
  match error with
  | PsCompilerError.translation _ => "compiler.translation"
  | PsCompilerError.leanFrontend _ => "compiler.lean-frontend"
  | PsCompilerError.proofScriptFrontend _ => "compiler.proofscript-frontend"
  | PsCompilerError.elaboration _ => "compiler.elaboration"
  | PsCompilerError.admission _ => "compiler.admission"
  | PsCompilerError.erasure _ => "compiler.erasure"
  | PsCompilerError.irValidation _ => "compiler.ir-validation"

def psCompilerJavaScriptLowerErrorCode
    (error : PsJsLowerError) : String :=
  match error with
  | PsJsLowerError.fuelExhausted => "lower.fuel-exhausted"
  | PsJsLowerError.importsUnsupported => "lower.imports-unsupported"
  | PsJsLowerError.structuresUnsupported => "lower.structures-unsupported"
  | PsJsLowerError.inductivesUnsupported => "lower.inductives-unsupported"
  | PsJsLowerError.specializationFailed => "lower.specialization-failed"
  | PsJsLowerError.genericDeclarationUnsupported name =>
      String.Internal.append "lower.generic-declaration:" name
  | PsJsLowerError.unsupportedType => "lower.unsupported-type"
  | PsJsLowerError.unsupportedLiteral => "lower.unsupported-literal"
  | PsJsLowerError.unsupportedExpression => "lower.unsupported-expression"
  | PsJsLowerError.unsupportedIntrinsic => "lower.unsupported-intrinsic"
  | PsJsLowerError.intrinsicArity => "lower.intrinsic-arity"
  | PsJsLowerError.typeArgumentsUnsupported => "lower.type-arguments"
  | PsJsLowerError.unsupportedName name =>
      String.Internal.append "lower.unsupported-name:" name

def psCompilerJavaScriptErrorCode
    (error : PsCompilerJavaScriptError) : String :=
  match error with
  | PsCompilerJavaScriptError.compiler compilerError =>
      psCompilerJavaScriptCompilerErrorCode compilerError
  | PsCompilerJavaScriptError.emit emitError =>
      match emitError with
      | PsJsEmitError.lower lowerError =>
          psCompilerJavaScriptLowerErrorCode lowerError
      | PsJsEmitError.fuelExhausted => "emit.fuel-exhausted"
      | PsJsEmitError.malformedIr => "emit.malformed-ir"

def psCompilerJavaScriptTarget64 : PsJsTargetProfile :=
  { wordSize := PsJsWordSize.bits64 }

def psCompilerJavaScriptFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptError String :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok ir =>
      match
          psJsEmitValidatedModuleWithTargetProfile
            psCompilerJavaScriptTarget64
            ir with
      | Except.error error =>
          Except.error (PsCompilerJavaScriptError.emit error)
      | Except.ok output =>
          Except.ok output

def psCompilerJavaScriptFromElaborated
    (elaborated : PsElabModuleResult) :
    Except PsCompilerJavaScriptError String :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerJavaScriptFromPrepared prepared

def psCompilerJavaScriptSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerJavaScriptError String :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerJavaScriptFromPrepared prepared

def psCompilerJavaScriptProofScriptSource
    (source : String) :
    Except PsCompilerJavaScriptError String :=
  psCompilerJavaScriptSource
    PsCompilerSourceKind.proofScript
    source

def psCompilerJavaScriptProofScriptSources
    (sources : List String) :
    Except PsCompilerJavaScriptError String :=
  match
      psCompilerPrepareSources
        PsCompilerSourceKind.proofScript
        sources with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      psCompilerJavaScriptFromPrepared prepared
