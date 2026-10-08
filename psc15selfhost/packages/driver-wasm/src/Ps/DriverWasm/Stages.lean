import Ps.DriverWasm.Bootstrap
import Ps.CompilerIr.Encode
import Ps.BackendWasm.Encode
import Ps.BackendWasm.ValidateIr

inductive PsCompilerWasmStagesError where
  | compiler (error : PsCompilerError)
  | specialize (error : PsIrSpecializeError)
  | lower (error : PsWasmLowerError)
  | targetValidation (error : PsWasmIrValidationError)
  | targetSnapshot (error : PsWasmIrEncodeError)
  | encode (error : PsWasmEncodeError)
  | snapshot (error : PsIrEncodeError)

structure PsCompilerWasmStages where
  wasm : List UInt8
  runtimeIr : String
  verifiedIr : String
  specializedIr : String
  wasmIr : String
  erasureCorrespondence : String

-- A single execution retains the module values actually used for emission.
-- Checked host authority is required before production access to this API.
def psCompilerWasmStagesFromSpecialized
    (profile : PsWasmTargetProfile) (runtime verified erasureCorrespondence : String)
    (specialized : PsSpecializedIrModule) : Except PsCompilerWasmStagesError PsCompilerWasmStages :=
  match psValidateErasedIrModule (PsErasedIrModule.mk specialized.raw) with
  | Except.error error =>
      Except.error (PsCompilerWasmStagesError.compiler (PsCompilerError.irValidation error))
  | Except.ok _ =>
      match psIrEncodeModule specialized.raw with
      | Except.error error => Except.error (PsCompilerWasmStagesError.snapshot error)
      | Except.ok encoded =>
          match psWasmLowerSpecializedValidatedModule profile specialized with
          | Except.error error =>
              Except.error (PsCompilerWasmStagesError.lower error)
          | Except.ok lowered =>
              let module : PsWasmModule :=
                psWasmAddSelfHostGcAbi lowered;
              match psWasmIrValidateModule module with
              | Except.error error =>
                  Except.error
                    (PsCompilerWasmStagesError.targetValidation
                      error)
              | Except.ok _ =>
                  match psWasmIrEncodeModule module with
                  | Except.error error =>
                      Except.error
                        (PsCompilerWasmStagesError.targetSnapshot
                          error)
                  | Except.ok targetIr =>
                      match psWasmEncodeModule module with
                      | Except.error error =>
                          Except.error
                            (PsCompilerWasmStagesError.encode
                              error)
                      | Except.ok output =>
                          Except.ok
                            (PsCompilerWasmStages.mk
                              output
                              runtime
                              verified
                              encoded
                              targetIr
                              erasureCorrespondence)

def psCompilerWasmStagesFromValidated
    (profile : PsWasmTargetProfile) (runtime verified erasureCorrespondence : String)
    (validated : PsValidatedIrModule) : Except PsCompilerWasmStagesError PsCompilerWasmStages :=
  match psIrSpecializeValidatedModule validated with
  | Except.error error => Except.error (PsCompilerWasmStagesError.specialize error)
  | Except.ok specialized => psCompilerWasmStagesFromSpecialized profile runtime verified erasureCorrespondence specialized

-- Both private and Canonical export paths consume this one prepared-source
-- transformation. Neither path can substitute host-provided IR for these values.
structure PsCompilerWasmSpecializedInputs where
  runtimeIr : String
  verifiedIr : String
  erasureCorrespondence : String
  specialized : PsSpecializedIrModule

def psCompilerWasmSpecializedInputsFromPrepared
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerWasmStagesError PsCompilerWasmSpecializedInputs :=
  match psCompilerErasureProductFromPrepared prepared with
  | Except.error error => Except.error (PsCompilerWasmStagesError.compiler error)
  | Except.ok product =>
      match psIrEncodeModule product.erased.raw with
      | Except.error error => Except.error (PsCompilerWasmStagesError.snapshot error)
      | Except.ok runtime =>
          match psValidateErasedIrModule product.erased with
          | Except.error error =>
              Except.error (PsCompilerWasmStagesError.compiler (PsCompilerError.irValidation error))
          | Except.ok validated =>
              match psIrEncodeModule validated.raw with
              | Except.error error => Except.error (PsCompilerWasmStagesError.snapshot error)
              | Except.ok verified =>
                  match psIrSpecializeValidatedModule validated with
                  | Except.error error => Except.error (PsCompilerWasmStagesError.specialize error)
                  | Except.ok specialized =>
                      Except.ok (PsCompilerWasmSpecializedInputs.mk
                        runtime verified product.correspondence specialized)

def psCompilerWasmStagesFromPrepared
    (profile : PsWasmTargetProfile)
    (prepared : PsCompilerAdmissionReadyModule) : Except PsCompilerWasmStagesError PsCompilerWasmStages :=
  match psCompilerWasmSpecializedInputsFromPrepared prepared with
  | Except.error error => Except.error error
  | Except.ok inputs =>
      psCompilerWasmStagesFromSpecialized profile inputs.runtimeIr inputs.verifiedIr
        inputs.erasureCorrespondence inputs.specialized
