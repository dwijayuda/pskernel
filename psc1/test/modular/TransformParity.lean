import Ps.Host.SourceOwnership
import Ps.BackendJs.Print
import Ps.BackendTs.Module
import Ps.CompilerIr.WorkerFusion
import Lean.Data.Json

/-! This harness imports only APIs present at PR#195. CI runs this exact file
against that immutable checkout and compares complete transform/target bytes. -/

open Ps.Internal.CompilerService

def parityLift {α ε : Type} (value : Except ε α) (label : String) : IO α :=
  match value with
  | .ok result => pure result
  | .error _ => throw (IO.userError label)

def main (args : List String) : IO UInt32 := do
  try
    let [file] := args | throw (IO.userError "parity request path")
    let text ← IO.FS.readFile file
    if text.utf8ByteSize > 1024 * 1024 then throw (IO.userError "parity request bound")
    let portable ← parityLift (psJsonParse text) "parity JSON"
    let .array fields := portable | throw (IO.userError "parity array")
    let request ← parityLift (decodeRequestFieldsForProtocol "psc1-modular-pilot/2" 7 fields) "parity request"
    let (captured, _) ← parityLift (psOwnershipCapture request) "parity capture"
    let semantic ← parityLift (psOwnershipPrepare request captured) "parity prepare"
    let original ← parityLift (psStrictValidateModule semantic.raw) "parity original IR"
    let specialized ← parityLift (psIrSpecializeValidatedModule original) "parity specialize"
    let fused ← parityLift (psFuseClosedWorkers (.mk specialized.raw)) "parity fusion"
    let js ← parityLift (psJsLowerSpecializedModule fused.raw) "parity JS lower"
    let _ ← parityLift (psJsValidateModule js) "parity JS validate"
    let referenceJs ← parityLift (psJsPrintModuleStackSafe js) "parity JS print"
    let referenceTs ← parityLift (psTsEmitModule fused.raw) "parity TS print"
    let originalText ← parityLift (psIrEncodeModule semantic.raw) "parity original encoding"
    let specializedText ← parityLift (psIrEncodeModule specialized.raw) "parity specialized encoding"
    let transformedText ← parityLift (psIrEncodeModule fused.raw) "parity fused encoding"
    let originalJson ← parityLift (Lean.Json.parse originalText) "parity original JSON"
    let specializedJson ← parityLift (Lean.Json.parse specializedText) "parity specialized JSON"
    let transformedJson ← parityLift (Lean.Json.parse transformedText) "parity transformed JSON"
    let output := Lean.Json.mkObj [
      ("originalIr", originalJson), ("specializedIr", specializedJson), ("transformedIr", transformedJson),
      ("admissions", .str semantic.admissions), ("referenceJs", .str referenceJs), ("referenceTs", .str referenceTs),
      ("leanVersion", .str Lean.versionString), ("leanCommit", .str Lean.githash)]
    if output.compress.utf8ByteSize > 32 * 1024 * 1024 then throw (IO.userError "parity response bound")
    IO.println output.compress
    return 0
  catch error =>
    (← IO.getStderr).putStrLn error.toString
    return 1
