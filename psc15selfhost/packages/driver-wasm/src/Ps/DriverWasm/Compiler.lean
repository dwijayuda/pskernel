import Ps.Compiler.Api
import Ps.BackendWasm.Lower
import Ps.BackendWasm.Binary
import Ps.BackendWasm.SelfHostAbi

inductive PsCompilerWasmError where
  | compiler (error : PsCompilerError)
  | lower (error : PsWasmLowerError)
  | encode (error : PsWasmEncodeError)

def psCompilerWasm32Target : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

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
      | Except.ok module =>
          match psWasmEncodeModule (psWasmAddSelfHostGcAbi module) with
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
