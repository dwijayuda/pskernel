import Ps.BackendWasm.Lower

def psWasmSmokeProfile : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

def psWasmSmokeIrModule : PsVerifiedIrModule :=
  {
    imports := []
    structures := []
    inductives := []
    declarations := [
      {
        name := "addU32"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.uint32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.uint32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.machineIntBinary
              PsVerifiedIrMachineIntegerType.uint32
              PsVerifiedIrIntegerBinaryOp.add)
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      }
,
      {
        name := "addF32"
        typeParameters := []
        parameters := [
          {
            name := "left"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.float32
          },
          {
            name := "right"
            type :=
              PsVerifiedIrType.primitive
                PsVerifiedIrPrimitiveType.float32
          }
        ]
        resultType :=
          PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.float32
        body :=
          PsVerifiedIrExpr.intrinsic
            (PsVerifiedIrIntrinsic.floatBinary
              PsVerifiedIrFloatingType.float32
              PsVerifiedIrFloatBinaryOp.add)
            [
              PsVerifiedIrExpr.var "left",
              PsVerifiedIrExpr.var "right"
            ]
      }
    ]
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
  match psWasmLowerModule psWasmSmokeProfile psWasmSmokeIrModule with
  | Except.error _ =>
      throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: lower failed")
  | Except.ok module =>
      match psWasmEncodeModule module with
      | Except.error _ =>
          throw (IO.userError "PSC1_BACKEND_WASM_BINARY_SMOKE: encode failed")
      | Except.ok bytes =>
          IO.println (psWasmJoinComma (psWasmByteStrings bytes))
