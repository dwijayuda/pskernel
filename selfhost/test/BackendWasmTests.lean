import Ps.BackendWasm.Lower

def psWasmProfile32 : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm32 }

def psWasmProfile64 : PsWasmTargetProfile :=
  { wordSize := PsWasmWordSize.wasm64 }

def psWasmIsI32 : PsWasmValueType -> Bool
  | .i32 => true
  | _ => false

def psWasmIsI64 : PsWasmValueType -> Bool
  | .i64 => true
  | _ => false

def psWasmIsF32 : PsWasmValueType -> Bool
  | .f32 => true
  | _ => false

def psWasmIsF64 : PsWasmValueType -> Bool
  | .f64 => true
  | _ => false

def psWasmIsPackedI8 : PsWasmStorageType -> Bool
  | .packedI8 => true
  | _ => false

def psWasmIsPackedI16 : PsWasmStorageType -> Bool
  | .packedI16 => true
  | _ => false

def psWasmIsNatRef : PsWasmValueType -> Bool
  | .refT name => name == "ProofScript.Nat"
  | _ => false

def psTestWasmScalarLowering : Bool :=
  psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .uint8)
    && psWasmIsPackedI8 (psWasmStorageTypeOfPrimitive psWasmProfile32 .uint8)
    && psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .int16)
    && psWasmIsPackedI16 (psWasmStorageTypeOfPrimitive psWasmProfile32 .int16)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile32 .uint64)
    && psWasmIsF32 (psWasmValueTypeOfPrimitive psWasmProfile32 .float32)
    && psWasmIsF64 (psWasmValueTypeOfPrimitive psWasmProfile32 .float)
    && psWasmIsNatRef (psWasmValueTypeOfPrimitive psWasmProfile32 .nat)

def psTestWasmWordProfiles : Bool :=
  psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .usize)
    && psWasmIsI32 (psWasmValueTypeOfPrimitive psWasmProfile32 .isize)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile64 .usize)
    && psWasmIsI64 (psWasmValueTypeOfPrimitive psWasmProfile64 .isize)

def psWasmIsUInt8Add : List PsWasmInstruction -> Bool
  | .i32Add :: .i32Const value :: .i32And :: [] =>
      value == 255
  | _ => false

def psWasmIsInt8Add : List PsWasmInstruction -> Bool
  | .i32Add :: .i32Extend8S :: [] => true
  | _ => false

def psWasmIsUInt64Xor : List PsWasmInstruction -> Bool
  | .i64Xor :: [] => true
  | _ => false

def psWasmIsInt16Lt : List PsWasmInstruction -> Bool
  | .i32LtS :: [] => true
  | _ => false

def psWasmIsUInt16Lt : List PsWasmInstruction -> Bool
  | .i32LtU :: [] => true
  | _ => false

def psWasmIsUSize64Add : List PsWasmInstruction -> Bool
  | .i64Add :: [] => true
  | _ => false

def psWasmIsUInt8Literal : List PsWasmInstruction -> Bool
  | .i32Const value :: .i32Const mask :: .i32And :: [] =>
      value == 255 && mask == 255
  | _ => false

def psWasmIsUInt64Literal : List PsWasmInstruction -> Bool
  | .i64Const value :: [] => value == 42
  | _ => false

def psTestWasmMachineIntegerLiterals : Bool :=
  psWasmIsUInt8Literal
      (psWasmLowerMachineIntegerLiteral
        psWasmProfile32
        .uint8
        255)
    && psWasmIsUInt64Literal
      (psWasmLowerMachineIntegerLiteral
        psWasmProfile32
        .uint64
        42)

def psTestWasmMachineIntegerOps : Bool :=
  psWasmIsUInt8Add
      (psWasmLowerMachineIntegerBinary
        psWasmProfile32
        .uint8
        .add)
    && psWasmIsInt8Add
      (psWasmLowerMachineIntegerBinary
        psWasmProfile32
        .int8
        .add)
    && psWasmIsUInt64Xor
      (psWasmLowerMachineIntegerBinary
        psWasmProfile32
        .uint64
        .bitXor)
    && psWasmIsInt16Lt
      (psWasmLowerMachineIntegerCompare
        psWasmProfile32
        .int16
        .lt)
    && psWasmIsUInt16Lt
      (psWasmLowerMachineIntegerCompare
        psWasmProfile32
        .uint16
        .lt)
    && psWasmIsUSize64Add
      (psWasmLowerMachineIntegerBinary
        psWasmProfile64
        .usize
        .add)

def psWasmAddU32IrModule : PsVerifiedIrModule :=
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
    ]
  }

def psWasmIsAddU32Function : PsWasmFunction -> Bool
  | {
      name := name,
      parameters := [.i32, .i32],
      results := [.i32],
      body := [.localGet 0, .localGet 1, .i32Add]
    } => name == "addU32"
  | _ => false

def psTestWasmVerifiedIrLowering : Bool :=
  match psWasmLowerModule psWasmProfile32 psWasmAddU32IrModule with
  | Except.error _ => false
  | Except.ok module =>
      match module.functions with
      | [function] =>
          psWasmIsAddU32Function function
            && module.exports == [("addU32", "addU32")]
      | _ => false

def psWasmAnswerModule : PsWasmModule :=
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

def psWasmExpectedAnswerBytes : List UInt8 := [
  psWasmByte 0,
  psWasmByte 97,
  psWasmByte 115,
  psWasmByte 109,
  psWasmByte 1,
  psWasmByte 0,
  psWasmByte 0,
  psWasmByte 0,
  psWasmByte 1,
  psWasmByte 5,
  psWasmByte 1,
  psWasmByte 96,
  psWasmByte 0,
  psWasmByte 1,
  psWasmByte 127,
  psWasmByte 3,
  psWasmByte 2,
  psWasmByte 1,
  psWasmByte 0,
  psWasmByte 7,
  psWasmByte 10,
  psWasmByte 1,
  psWasmByte 6,
  psWasmByte 97,
  psWasmByte 110,
  psWasmByte 115,
  psWasmByte 119,
  psWasmByte 101,
  psWasmByte 114,
  psWasmByte 0,
  psWasmByte 0,
  psWasmByte 10,
  psWasmByte 6,
  psWasmByte 1,
  psWasmByte 4,
  psWasmByte 0,
  psWasmByte 65,
  psWasmByte 42,
  psWasmByte 11
]

def psTestWasmUleb : Bool :=
  psWasmEncodeUleb 624485 ==
    [psWasmByte 229, psWasmByte 142, psWasmByte 38]

def psTestWasmSignedLeb : Bool :=
  psWasmEncodeI32Constant (-1) == [psWasmByte 127]
    && psWasmEncodeI32Constant 4294967295 == [psWasmByte 127]
    && psWasmEncodeI64Constant (-1) == [psWasmByte 127]
    && psWasmEncodeI64Constant 18446744073709551615 ==
      [psWasmByte 127]

def psTestWasmBinaryModule : Bool :=
  match psWasmEncodeModule psWasmAnswerModule with
  | Except.error _ => false
  | Except.ok bytes => bytes == psWasmExpectedAnswerBytes

def main : IO Unit := do
  if psTestWasmScalarLowering
      && psTestWasmWordProfiles
      && psTestWasmMachineIntegerOps
      && psTestWasmMachineIntegerLiterals
      && psTestWasmVerifiedIrLowering
      && psTestWasmUleb
      && psTestWasmSignedLeb
      && psTestWasmBinaryModule then
    IO.println "PSC1_BACKEND_WASM_TESTS: PASS"
  else
    throw (IO.userError "PSC1_BACKEND_WASM_TESTS: FAIL")
