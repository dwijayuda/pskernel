import Ps.BackendJs.Print
import Ps.BackendRust.Module
import Ps.BackendWasm.Lower
import Ps.CompilerIr.Specialize

-- Deliberately forge the public transport wrapper around a body containing
-- an unresolved free variable. Every validated backend must refuse it.
def psForgedIr : PsValidatedIrModule :=
  { raw := {
      imports := []
      structures := []
      inductives := []
      declarations := [
        { name := "forged"
          typeParameters := []
          parameters := []
          resultType := .primitive .uint32
          body := .var "unbound" }
      ]
    } }

def psForgedSpecializationRejected : Bool :=
  match psIrSpecializeValidatedModule psForgedIr with
  | .error .sourceIrRejected => true
  | _ => false

def psForgedUniformRejected : Bool :=
  match psIrSpecializeUniformValidatedModule psForgedIr with
  | .error .sourceIrRejected => true
  | _ => false

def psForgedJsRejected : Bool :=
  match psJsEmitValidatedModuleWithPositions psForgedIr with
  | .error (.lower (.specializationFailed .sourceIrRejected)) => true
  | _ => false

def psForgedWasmRejected : Bool :=
  match psWasmLowerValidatedModule
      { wordSize := PsWasmWordSize.wasm32 } psForgedIr with
  | .error (.specializationFailed .sourceIrRejected) => true
  | _ => false

def psForgedRustRejected : Bool :=
  match psRustEmitValidatedModule psForgedIr with
  | .error .sourceIrRejected => true
  | _ => false

def main : IO Unit := do
  if !(psForgedSpecializationRejected && psForgedUniformRejected &&
      psForgedJsRejected && psForgedWasmRejected && psForgedRustRejected) then
    throw (IO.userError "PSC1_FORGED_VALIDATED_WRAPPER_NOT_REJECTED")
  IO.println "PSC1_VALIDATED_BACKEND_FORGERY_REFUSALS: PASS"
