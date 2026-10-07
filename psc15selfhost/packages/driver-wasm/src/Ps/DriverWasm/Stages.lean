import Ps.DriverWasm.Bootstrap
import Ps.CompilerIr.Encode

inductive PsCompilerWasmStagesError where
  | compiler (error : PsCompilerError)
  | specialize (error : PsIrSpecializeError)
  | lower (error : PsWasmLowerError)
  | encode (error : PsWasmEncodeError)
  | snapshot (error : PsIrEncodeError)

structure PsCompilerWasmStages where
  wasm : List UInt8
  runtimeIr : String
  verifiedIr : String
  specializedIr : String

-- A single execution retains the module values actually used for emission.
-- Checked host authority is required before production access to this API.
def psCompilerWasmStagesFromSpecialized
    (profile : PsWasmTargetProfile) (runtime verified : String)
    (specialized : PsSpecializedIrModule) : Except PsCompilerWasmStagesError PsCompilerWasmStages :=
  match psValidateErasedIrModule (PsErasedIrModule.mk specialized.raw) with
  | Except.error error =>
      Except.error (PsCompilerWasmStagesError.compiler (PsCompilerError.irValidation error))
  | Except.ok _ =>
      match psIrEncodeModule specialized.raw with
      | Except.error error => Except.error (PsCompilerWasmStagesError.snapshot error)
      | Except.ok encoded =>
          match psWasmLowerSpecializedValidatedModule profile specialized with
          | Except.error error => Except.error (PsCompilerWasmStagesError.lower error)
          | Except.ok module =>
              match psWasmEncodeModule (psWasmAddSelfHostGcAbi module) with
              | Except.error error => Except.error (PsCompilerWasmStagesError.encode error)
              | Except.ok output => Except.ok (PsCompilerWasmStages.mk output runtime verified encoded)

def psCompilerWasmStagesFromValidated
    (profile : PsWasmTargetProfile) (runtime verified : String)
    (validated : PsValidatedIrModule) : Except PsCompilerWasmStagesError PsCompilerWasmStages :=
  match psIrSpecializeValidatedModule validated with
  | Except.error error => Except.error (PsCompilerWasmStagesError.specialize error)
  | Except.ok specialized => psCompilerWasmStagesFromSpecialized profile runtime verified specialized

def psCompilerWasmStagesFromPrepared
    (profile : PsWasmTargetProfile)
    (prepared : PsCompilerAdmissionReadyModule) : Except PsCompilerWasmStagesError PsCompilerWasmStages :=
  match psCompilerErasedIrFromPrepared prepared with
  | Except.error error => Except.error (PsCompilerWasmStagesError.compiler error)
  | Except.ok erased =>
      match psIrEncodeModule erased.raw with
      | Except.error error => Except.error (PsCompilerWasmStagesError.snapshot error)
      | Except.ok runtime =>
          match psValidateErasedIrModule erased with
          | Except.error error =>
              Except.error (PsCompilerWasmStagesError.compiler (PsCompilerError.irValidation error))
          | Except.ok validated =>
              match psIrEncodeModule validated.raw with
              | Except.error error => Except.error (PsCompilerWasmStagesError.snapshot error)
              | Except.ok verified => psCompilerWasmStagesFromValidated profile runtime verified validated
