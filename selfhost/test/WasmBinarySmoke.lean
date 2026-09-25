import Ps.BackendWasm.Binary

def psWasmSmokeModule : PsWasmModule :=
  {
    functions := [
      {
        name := "answer"
        parameters := []
        results := [PsWasmValueType.i32]
        body := [PsWasmInstruction.i32Const 42]
      }
    ]
    exports := [("answer", "answer")]
  }

def psWasmByteStrings : List UInt8 -> List String
  | [] => []
  | byte :: rest =>
      toString byte.toNat :: psWasmByteStrings rest

def psWasmJoinComma : List String -> String
  | [] => ""
  | [value] => value
  | value :: rest =>
      value ++ "," ++ psWasmJoinComma rest

def main : IO Unit := do
  match psWasmEncodeModule psWasmSmokeModule with
  | Except.error _ =>
      throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: encode failed")
  | Except.ok bytes =>
      IO.println (psWasmJoinComma (psWasmByteStrings bytes))
