import Ps.Compiler.Internal
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
  | PsJsLowerError.specializationFailed specializeError =>
      match specializeError with
      | PsIrSpecializeError.fuelExhausted =>
          "lower.specialization:fuel-exhausted"
      | PsIrSpecializeError.unresolvedTypeParameter name =>
          String.Internal.append "lower.specialization:unresolved-type-parameter:" name
      | PsIrSpecializeError.nonGroundType name =>
          String.Internal.append "lower.specialization:non-ground-type:" name
      | PsIrSpecializeError.typeArgumentArity name =>
          String.Internal.append "lower.specialization:type-argument-arity:" name
      | PsIrSpecializeError.unknownTarget name =>
          String.Internal.append "lower.specialization:unknown-target:" name
      | PsIrSpecializeError.unsupportedGenericCall =>
          "lower.specialization:unsupported-generic-call"
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
      | PsJsEmitError.targetValidation _ =>
          "emit.target-validation"
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
          psJsEmitValidatedModuleStackSafeWithTargetProfile
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


def psCompilerJavaScriptPreparationInitial :
    PsCompilerSourcePreparationState :=
  psCompilerSourcePreparationInitial

def psCompilerJavaScriptPrepareProofScriptSourceStep
    (state : PsCompilerSourcePreparationState)
    (source : String) :
    Except PsCompilerJavaScriptError PsCompilerSourcePreparationState :=
  match
      psCompilerPrepareSourceStep
        PsCompilerSourceKind.proofScript
        state
        source with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok next =>
      Except.ok next

def psCompilerJavaScriptFinishProofScriptPreparation
    (state : PsCompilerSourcePreparationState) :
    Except PsCompilerJavaScriptError PsCompilerAdmissionReadyModule :=
  match psCompilerFinishSourcePreparation state with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      Except.ok prepared

def psCompilerJavaScriptPrepareProofScriptSources
    (sources : List String) :
    Except PsCompilerJavaScriptError PsCompilerAdmissionReadyModule :=
  match
      psCompilerPrepareSources
        PsCompilerSourceKind.proofScript
        sources with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok prepared =>
      Except.ok prepared

def psCompilerJavaScriptValidatedIrFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerJavaScriptError PsValidatedIrModule :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerJavaScriptError.compiler error)
  | Except.ok validated =>
      Except.ok validated

def psCompilerJavaScriptSpecializeValidatedIr
    (validated : PsValidatedIrModule) :
    Except PsCompilerJavaScriptError PsSpecializedIrModule :=
  match psIrSpecializeValidatedModule validated with
  | Except.error error =>
      Except.error
        (PsCompilerJavaScriptError.emit
          (PsJsEmitError.lower
            (PsJsLowerError.specializationFailed error)))
  | Except.ok specialized =>
      Except.ok specialized

def psCompilerJavaScriptEmitSpecialized
    (specialized : PsSpecializedIrModule) :
    Except PsCompilerJavaScriptError String :=
  match
      psJsLowerSpecializedModuleWithProfile
        (Option.some psCompilerJavaScriptTarget64)
        specialized.raw with
  | Except.error error =>
      Except.error
        (PsCompilerJavaScriptError.emit
          (PsJsEmitError.lower error))
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error error =>
          Except.error
            (PsCompilerJavaScriptError.emit
              (PsJsEmitError.targetValidation error))
      | Except.ok _ =>
          match psJsPrintModuleStackSafe jsIr with
          | Except.error error =>
              Except.error (PsCompilerJavaScriptError.emit error)
          | Except.ok output =>
              Except.ok output
