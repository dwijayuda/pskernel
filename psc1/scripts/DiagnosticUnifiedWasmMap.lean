import Ps.CompilerUnified.Service
def mapEmit (module : PsValidatedIrModule) (publicNames : List String) :
    Except Ps.Internal.CompilerService.Error (Prod String (List String)) :=
  match psWasmLowerSpecializedModule (PsWasmTargetProfile.mk PsWasmWordSize.wasm32) module.raw with
  | .error _ => .error (Ps.Internal.CompilerService.failure "diagnostic-map" "lowering")
  | .ok lowered =>
    let target := psWasmServiceTransport lowered publicNames
    match psWasmIrValidateModule target with
    | .error _ => .error (Ps.Internal.CompilerService.failure "diagnostic-map" "validation")
    | .ok _ => .ok (psJsonArray (psListMap (fun f => psJsonQuote f.name) target.functions), [])
def main (args : List String) : IO Unit := do
  match args with
  | [input, output] =>
    let text <- IO.FS.readFile input
    match psJsonParse text with
    | .ok (.array [_, _, .array values]) =>
      IO.FS.writeFile output (Ps.Internal.UnifiedCompilerService.run PsBackendTarget.wasmCore mapEmit values)
    | _ => throw (IO.userError "invalid diagnostic input")
  | _ => throw (IO.userError "usage: input output")
