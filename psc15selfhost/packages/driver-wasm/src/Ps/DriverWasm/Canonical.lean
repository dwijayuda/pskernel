import Ps.DriverWasm.Stages
import Ps.BackendWasm.CanonicalRequest

inductive PsCompilerWasmCanonicalError where
  | request (error : PsWasmCanonicalRequestError)
  | stages (error : PsCompilerWasmStagesError)
  | canonical (error : PsWasmCanonicalError)

structure PsCompilerWasmCanonicalStages where
  wasm : List UInt8
  runtimeIr : String
  verifiedIr : String
  specializedIr : String
  wasmIr : String
  erasureCorrespondence : String
  interfaceJson : String
  bindingJson : String

def psCompilerWasmCanonicalStagesFromInputs (request : PsWasmCanonicalRequest)
    (inputs : PsCompilerWasmSpecializedInputs) :
    Except PsCompilerWasmCanonicalError PsCompilerWasmCanonicalStages :=
  match psIrEncodeModule inputs.specialized.raw with
  | Except.error error =>
      Except.error (PsCompilerWasmCanonicalError.stages (PsCompilerWasmStagesError.snapshot error))
  | Except.ok specialized =>
      match psWasmCompileCanonicalExports request.profile request.selection inputs.specialized with
      | Except.error error => Except.error (PsCompilerWasmCanonicalError.canonical error)
      | Except.ok output =>
          match psWasmIrEncodeModule output.target with
          | Except.error error =>
              Except.error (PsCompilerWasmCanonicalError.stages (PsCompilerWasmStagesError.targetSnapshot error))
          | Except.ok target =>
              Except.ok (PsCompilerWasmCanonicalStages.mk
                output.binary inputs.runtimeIr inputs.verifiedIr specialized target
                inputs.erasureCorrespondence output.interfaceJson output.bindingJson)

-- Bootstrap transform only. Production callers must retain their live checked
-- session, pin the selection bytes, and verify returned projection/signatures.
def psCompilerWasmCanonicalStagesFromPrepared (selectionRequest : String)
    (prepared : PsCompilerAdmissionReadyModule) :
    Except PsCompilerWasmCanonicalError PsCompilerWasmCanonicalStages :=
  match psWasmCanonicalDecodeRequest selectionRequest with
  | Except.error error => Except.error (PsCompilerWasmCanonicalError.request error)
  | Except.ok request =>
      match psCompilerWasmSpecializedInputsFromPrepared prepared with
      | Except.error error => Except.error (PsCompilerWasmCanonicalError.stages error)
      | Except.ok inputs => psCompilerWasmCanonicalStagesFromInputs request inputs
