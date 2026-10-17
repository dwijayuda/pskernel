import Ps.BackendWasm.Type

def psWasmMachineIntegerIs64
    (profile : PsWasmTargetProfile) :
    PsVerifiedIrMachineIntegerType -> Bool
  | .uint64 => true
  | .int64 => true
  | .usize =>
      match profile.wordSize with
      | .wasm32 => false
      | .wasm64 => true
  | .isize =>
      match profile.wordSize with
      | .wasm32 => false
      | .wasm64 => true
  | _ => false

def psWasmNormalizeMachineInteger :
    PsVerifiedIrMachineIntegerType -> List PsWasmInstruction
  | .uint8 => [
      PsWasmInstruction.i32Const 255,
      PsWasmInstruction.i32And
    ]
  | .uint16 => [
      PsWasmInstruction.i32Const 65535,
      PsWasmInstruction.i32And
    ]
  | .int8 => [PsWasmInstruction.i32Extend8S]
  | .int16 => [PsWasmInstruction.i32Extend16S]
  | _ => []

def psWasmLowerMachineIntegerLiteral
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (value : Int) :
    List PsWasmInstruction :=
  let constant :=
    if psWasmMachineIntegerIs64 profile type then
      PsWasmInstruction.i64Const value
    else
      PsWasmInstruction.i32Const value;
  List.cons
    constant
    (psWasmNormalizeMachineInteger type)

def psWasmWordDivisionName (wide signed remainder : Bool) : String :=
  "__ps_word_" ++ (if signed then "s" else "u") ++
    (if remainder then "rem" else "div") ++ (if wide then "64" else "32")

def psWasmMachineIntegerBinaryInstruction
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp) :
    PsWasmInstruction :=
  if psWasmMachineIntegerIs64 profile type then
    match operation with
    | .add => PsWasmInstruction.i64Add
    | .sub => PsWasmInstruction.i64Sub
    | .mul => PsWasmInstruction.i64Mul
    | .bitAnd => PsWasmInstruction.i64And
    | .bitOr => PsWasmInstruction.i64Or
    | .bitXor => PsWasmInstruction.i64Xor
    | .div => .call (psWasmWordDivisionName true (psIrMachineIntegerIsSigned type) false)
    | .mod => .call (psWasmWordDivisionName true (psIrMachineIntegerIsSigned type) true)
    | .shiftLeft => .word .i64Shl
    | .shiftRight => .word (if psIrMachineIntegerIsSigned type then .i64ShrS else .i64ShrU)
  else
    match operation with
    | .add => PsWasmInstruction.i32Add
    | .sub => PsWasmInstruction.i32Sub
    | .mul => PsWasmInstruction.i32Mul
    | .bitAnd => PsWasmInstruction.i32And
    | .bitOr => PsWasmInstruction.i32Or
    | .bitXor => PsWasmInstruction.i32Xor
    | .div => .call (psWasmWordDivisionName false (psIrMachineIntegerIsSigned type) false)
    | .mod => .call (psWasmWordDivisionName false (psIrMachineIntegerIsSigned type) true)
    | .shiftLeft => .word .i32Shl
    | .shiftRight => if psIrMachineIntegerIsSigned type then .word .i32ShrS else .i32ShrU

def psWasmLowerMachineIntegerBinary
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp) :
    List PsWasmInstruction :=
  -- The top stack operand is the shift count. Wasm already masks by 32/64;
  -- narrow integers need their own width mask before the same instruction.
  let narrowShift := match operation with
    | .shiftLeft | .shiftRight =>
      match psIrMachineIntegerFixedWidth type with
      | some 8 => [.i32Const 7, .i32And]
      | some 16 => [.i32Const 15, .i32And]
      | _ => []
    | _ => []
  narrowShift ++ [psWasmMachineIntegerBinaryInstruction profile type operation] ++
    psWasmNormalizeMachineInteger type


def psWasmMachineIntegerCompareInstruction
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerCompareOp) :
    PsWasmInstruction :=
  let signed := psIrMachineIntegerIsSigned type;
  if psWasmMachineIntegerIs64 profile type then
    match operation with
    | .eq => PsWasmInstruction.i64Eq
    | .ne => PsWasmInstruction.i64Ne
    | .lt => if signed then PsWasmInstruction.i64LtS else PsWasmInstruction.i64LtU
    | .le => if signed then PsWasmInstruction.i64LeS else PsWasmInstruction.i64LeU
    | .gt => if signed then PsWasmInstruction.i64GtS else PsWasmInstruction.i64GtU
    | .ge => if signed then PsWasmInstruction.i64GeS else PsWasmInstruction.i64GeU
  else
    match operation with
    | .eq => PsWasmInstruction.i32Eq
    | .ne => PsWasmInstruction.i32Ne
    | .lt => if signed then PsWasmInstruction.i32LtS else PsWasmInstruction.i32LtU
    | .le => if signed then PsWasmInstruction.i32LeS else PsWasmInstruction.i32LeU
    | .gt => if signed then PsWasmInstruction.i32GtS else PsWasmInstruction.i32GtU
    | .ge => if signed then PsWasmInstruction.i32GeS else PsWasmInstruction.i32GeU

def psWasmLowerMachineIntegerCompare
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerCompareOp) :
    List PsWasmInstruction :=
  [psWasmMachineIntegerCompareInstruction profile type operation]
