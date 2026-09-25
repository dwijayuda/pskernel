import Ps.BackendWasm.Type

def psWasmMachineIntegerIsSigned :
    PsVerifiedIrMachineIntegerType -> Bool
  | .uint8 => false
  | .uint16 => false
  | .uint32 => false
  | .uint64 => false
  | .usize => false
  | .int8 => true
  | .int16 => true
  | .int32 => true
  | .int64 => true
  | .isize => true

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
      PsWasmInstruction.i32Const value
  constant :: psWasmNormalizeMachineInteger type

def psWasmMachineIntegerBinaryInstruction
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp) :
    PsWasmInstruction :=
  if psWasmMachineIntegerIs64 profile type then
    match operation with
    | .add => .i64Add
    | .sub => .i64Sub
    | .mul => .i64Mul
    | .bitAnd => .i64And
    | .bitOr => .i64Or
    | .bitXor => .i64Xor
  else
    match operation with
    | .add => .i32Add
    | .sub => .i32Sub
    | .mul => .i32Mul
    | .bitAnd => .i32And
    | .bitOr => .i32Or
    | .bitXor => .i32Xor

def psWasmLowerMachineIntegerBinary
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp) :
    List PsWasmInstruction :=
  psWasmMachineIntegerBinaryInstruction profile type operation
    :: psWasmNormalizeMachineInteger type

def psWasmMachineIntegerCompareInstruction
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerCompareOp) :
    PsWasmInstruction :=
  let signed := psWasmMachineIntegerIsSigned type
  if psWasmMachineIntegerIs64 profile type then
    match operation with
    | .eq => .i64Eq
    | .ne => .i64Ne
    | .lt => if signed then .i64LtS else .i64LtU
    | .le => if signed then .i64LeS else .i64LeU
    | .gt => if signed then .i64GtS else .i64GtU
    | .ge => if signed then .i64GeS else .i64GeU
  else
    match operation with
    | .eq => .i32Eq
    | .ne => .i32Ne
    | .lt => if signed then .i32LtS else .i32LtU
    | .le => if signed then .i32LeS else .i32LeU
    | .gt => if signed then .i32GtS else .i32GtU
    | .ge => if signed then .i32GeS else .i32GeU

def psWasmLowerMachineIntegerCompare
    (profile : PsWasmTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerCompareOp) :
    List PsWasmInstruction :=
  [psWasmMachineIntegerCompareInstruction profile type operation]
