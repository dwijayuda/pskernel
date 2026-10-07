import Ps.Compiler.Internal
import Ps.BackendWasm.Lower
import Ps.BackendWasm.Binary
import Ps.BackendWasm.ValidateIr
import Ps.BackendWasm.SelfHostAbi

inductive PsCompilerWasmError where
  | compiler (error : PsCompilerError)
  | lower (error : PsWasmLowerError)
  | targetValidation (error : PsWasmIrValidationError)
  | encode (error : PsWasmEncodeError)

def psCompilerWasm32Target : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

def psCompilerWasmLowerErrorCode
    (error : PsWasmLowerError) : String :=
  match error with
  | PsWasmLowerError.unsupportedType => "lower.unsupported-type"
  | PsWasmLowerError.unsupportedTypeContext context =>
      String.Internal.append
        "lower.unsupported-type:"
        context
  | PsWasmLowerError.unsupportedExpression => "lower.unsupported-expression"
  | PsWasmLowerError.unsupportedExpressionContext context reason =>
      String.Internal.append
        "lower.unsupported-expression:"
        (String.Internal.append
          context
          (String.Internal.append ":" reason))
  | PsWasmLowerError.unsupportedIntrinsic => "lower.unsupported-intrinsic"
  | PsWasmLowerError.invalidIntrinsicArity => "lower.invalid-intrinsic-arity"
  | PsWasmLowerError.invalidCallArity => "lower.invalid-call-arity"
  | PsWasmLowerError.unknownVariable name =>
      String.Internal.append "lower.unknown-variable:" name
  | PsWasmLowerError.unknownStructure name =>
      String.Internal.append "lower.unknown-structure:" name
  | PsWasmLowerError.unknownStructureField structureName field =>
      String.Internal.append
        "lower.unknown-structure-field:"
        (String.Internal.append
          structureName
          (String.Internal.append ":" field))
  | PsWasmLowerError.missingRecordField structureName field =>
      String.Internal.append
        "lower.missing-record-field:"
        (String.Internal.append
          structureName
          (String.Internal.append ":" field))
  | PsWasmLowerError.unknownInductive name =>
      String.Internal.append "lower.unknown-inductive:" name
  | PsWasmLowerError.unknownConstructor inductiveName constructorName =>
      String.Internal.append
        "lower.unknown-constructor:"
        (String.Internal.append
          inductiveName
          (String.Internal.append ":" constructorName))
  | PsWasmLowerError.unknownConstructorField inductiveName constructorName field =>
      String.Internal.append
        "lower.unknown-constructor-field:"
        (String.Internal.append
          inductiveName
          (String.Internal.append
            ":"
            (String.Internal.append
              constructorName
              (String.Internal.append ":" field))))
  | PsWasmLowerError.missingConstructorField inductiveName constructorName field =>
      String.Internal.append
        "lower.missing-constructor-field:"
        (String.Internal.append
          inductiveName
          (String.Internal.append
            ":"
            (String.Internal.append
              constructorName
              (String.Internal.append ":" field))))
  | PsWasmLowerError.unsupportedModuleFeature =>
      "lower.unsupported-module-feature"
  | PsWasmLowerError.specializationFailed specializeError =>
      match specializeError with
      | PsIrSpecializeError.fuelExhausted =>
          "lower.specialization:fuel-exhausted"
      | PsIrSpecializeError.unresolvedTypeParameter name =>
          String.Internal.append
            "lower.specialization:unresolved-type-parameter:"
            name
      | PsIrSpecializeError.nonGroundType name =>
          String.Internal.append
            "lower.specialization:non-ground-type:"
            name
      | PsIrSpecializeError.typeArgumentArity name =>
          String.Internal.append
            "lower.specialization:type-argument-arity:"
            name
      | PsIrSpecializeError.unknownTarget name =>
          String.Internal.append
            "lower.specialization:unknown-target:"
            name
      | PsIrSpecializeError.unsupportedGenericCall =>
          "lower.specialization:unsupported-generic-call"

def psCompilerWasmErrorCode
    (error : PsCompilerWasmError) : String :=
  match error with
  | PsCompilerWasmError.compiler _ => "compiler"
  | PsCompilerWasmError.lower lowerError =>
      psCompilerWasmLowerErrorCode lowerError
  | PsCompilerWasmError.targetValidation _ =>
      "target-validation"
  | PsCompilerWasmError.encode _ => "encode"

def psCompilerWasmFromPrepared
    (profile : PsWasmTargetProfile)
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerWasmError (List UInt8) :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | Except.error error =>
      Except.error (PsCompilerWasmError.compiler error)
  | Except.ok ir =>
      match psWasmLowerValidatedModule profile ir with
      | Except.error error =>
          Except.error (PsCompilerWasmError.lower error)
      | Except.ok lowered =>
          let module : PsWasmModule :=
            psWasmAddSelfHostGcAbi lowered;
          match psWasmIrValidateModule module with
          | Except.error error =>
              Except.error
                (PsCompilerWasmError.targetValidation error)
          | Except.ok _ =>
              match psWasmEncodeModule module with
              | Except.error error =>
                  Except.error (PsCompilerWasmError.encode error)
              | Except.ok bytes =>
                  Except.ok bytes

def psCompilerWasmFromElaborated
    (profile : PsWasmTargetProfile)
    (elaborated : PsElabModuleResult) :
    Except PsCompilerWasmError (List UInt8) :=
  match psCompilerPrepareElaborated elaborated with
  | Except.error error =>
      Except.error (PsCompilerWasmError.compiler error)
  | Except.ok prepared =>
      psCompilerWasmFromPrepared profile prepared

def psCompilerWasmSource
    (profile : PsWasmTargetProfile)
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerWasmError (List UInt8) :=
  match psCompilerPrepareSource sourceKind source with
  | Except.error error =>
      Except.error (PsCompilerWasmError.compiler error)
  | Except.ok prepared =>
      psCompilerWasmFromPrepared profile prepared

def psCompilerWasm32ProofScriptSource
    (source : String) :
    Except PsCompilerWasmError (List UInt8) :=
  psCompilerWasmSource
    psCompilerWasm32Target
    PsCompilerSourceKind.proofScript
    source

def psCompilerWasm32ProofScriptBytesOrEmpty
    (source : String) : List UInt8 :=
  match psCompilerWasm32ProofScriptSource source with
  | Except.error _ => List.nil
  | Except.ok bytes => bytes

def psCompilerWasm32ProofScriptSources
    (sources : List String) :
    Except PsCompilerWasmError (List UInt8) :=
  match
      psCompilerPrepareSources
        PsCompilerSourceKind.proofScript
        sources with
  | Except.error error =>
      Except.error (PsCompilerWasmError.compiler error)
  | Except.ok prepared =>
      psCompilerWasmFromPrepared
        psCompilerWasm32Target
        prepared

def psCompilerWasm32ProofScriptSourcesBytesOrEmpty
    (sources : List String) : List UInt8 :=
  match psCompilerWasm32ProofScriptSources sources with
  | Except.error _ => List.nil
  | Except.ok bytes => bytes
