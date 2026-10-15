import Ps.CompilerIr.Model

inductive PsWasmWordSize where
  | wasm32
  | wasm64

structure PsWasmTargetProfile where
  wordSize : PsWasmWordSize

inductive PsWasmValueType where
  | i32
  | i64
  | f32
  | f64
  | refT (name : String)
  | funcRef
  | noValue
  deriving BEq

inductive PsWasmStorageType where
  | value (type : PsWasmValueType)
  | packedI8
  | packedI16

structure PsWasmLoweredType where
  valueType : PsWasmValueType
  storageType : PsWasmStorageType

-- Word operations needed by the limb runtime. A single descriptor supplies
-- their mnemonic, binary opcode and stack signature to all target consumers.
inductive PsWasmWordOp where
  | f32ConvertI32S
  | f32ConvertI32U
  | f32ConvertI64S
  | f32ConvertI64U
  | f64ConvertI32S
  | f64ConvertI32U
  | f64ConvertI64S
  | f64ConvertI64U
  | i32TruncSatF32S
  | i32TruncSatF32U
  | i32TruncSatF64S
  | i32TruncSatF64U
  | i64TruncSatF32S
  | i64TruncSatF32U
  | i64TruncSatF64S
  | i64TruncSatF64U
  | f32Abs
  | f32Neg
  | f64Abs
  | f64Neg
  | i32ReinterpretF32
  | i64ReinterpretF64
  | f32ReinterpretI32
  | f64ReinterpretI64
  | i32Clz
  | i32DivS
  | i32DivU
  | i32RemS
  | i32RemU
  | i32Shl
  | i32ShrS
  | i64DivS
  | i64DivU
  | i64RemS
  | i64RemU
  | i64Shl
  | i64ShrS
  | i64ShrU
  | i32WrapI64
  | i64ExtendI32U

structure PsWasmWordInstruction where
  mnemonic : String
  bytes : List UInt8
  parameters : List PsWasmValueType
  result : PsWasmValueType

def psWasmWordInstruction : PsWasmWordOp → PsWasmWordInstruction
  | .f32ConvertI32S => { mnemonic := "f32.convert_i32_s", bytes := [178], parameters := [.i32], result := .f32 }
  | .f32ConvertI32U => { mnemonic := "f32.convert_i32_u", bytes := [179], parameters := [.i32], result := .f32 }
  | .f32ConvertI64S => { mnemonic := "f32.convert_i64_s", bytes := [180], parameters := [.i64], result := .f32 }
  | .f32ConvertI64U => { mnemonic := "f32.convert_i64_u", bytes := [181], parameters := [.i64], result := .f32 }
  | .f64ConvertI32S => { mnemonic := "f64.convert_i32_s", bytes := [183], parameters := [.i32], result := .f64 }
  | .f64ConvertI32U => { mnemonic := "f64.convert_i32_u", bytes := [184], parameters := [.i32], result := .f64 }
  | .f64ConvertI64S => { mnemonic := "f64.convert_i64_s", bytes := [185], parameters := [.i64], result := .f64 }
  | .f64ConvertI64U => { mnemonic := "f64.convert_i64_u", bytes := [186], parameters := [.i64], result := .f64 }
  | .i32TruncSatF32S => { mnemonic := "i32.trunc_sat_f32_s", bytes := [252, 0], parameters := [.f32], result := .i32 }
  | .i32TruncSatF32U => { mnemonic := "i32.trunc_sat_f32_u", bytes := [252, 1], parameters := [.f32], result := .i32 }
  | .i32TruncSatF64S => { mnemonic := "i32.trunc_sat_f64_s", bytes := [252, 2], parameters := [.f64], result := .i32 }
  | .i32TruncSatF64U => { mnemonic := "i32.trunc_sat_f64_u", bytes := [252, 3], parameters := [.f64], result := .i32 }
  | .i64TruncSatF32S => { mnemonic := "i64.trunc_sat_f32_s", bytes := [252, 4], parameters := [.f32], result := .i64 }
  | .i64TruncSatF32U => { mnemonic := "i64.trunc_sat_f32_u", bytes := [252, 5], parameters := [.f32], result := .i64 }
  | .i64TruncSatF64S => { mnemonic := "i64.trunc_sat_f64_s", bytes := [252, 6], parameters := [.f64], result := .i64 }
  | .i64TruncSatF64U => { mnemonic := "i64.trunc_sat_f64_u", bytes := [252, 7], parameters := [.f64], result := .i64 }
  | .f32Abs => { mnemonic := "f32.abs", bytes := [139], parameters := [.f32], result := .f32 }
  | .f32Neg => { mnemonic := "f32.neg", bytes := [140], parameters := [.f32], result := .f32 }
  | .f64Abs => { mnemonic := "f64.abs", bytes := [153], parameters := [.f64], result := .f64 }
  | .f64Neg => { mnemonic := "f64.neg", bytes := [154], parameters := [.f64], result := .f64 }
  | .i32ReinterpretF32 => { mnemonic := "i32.reinterpret_f32", bytes := [188], parameters := [.f32], result := .i32 }
  | .i64ReinterpretF64 => { mnemonic := "i64.reinterpret_f64", bytes := [189], parameters := [.f64], result := .i64 }
  | .f32ReinterpretI32 => { mnemonic := "f32.reinterpret_i32", bytes := [190], parameters := [.i32], result := .f32 }
  | .f64ReinterpretI64 => { mnemonic := "f64.reinterpret_i64", bytes := [191], parameters := [.i64], result := .f64 }
  | .i64ShrS => { mnemonic := "i64.shr_s", bytes := [135], parameters := [.i64, .i64], result := .i64 }
  | .i64RemS => { mnemonic := "i64.rem_s", bytes := [129], parameters := [.i64, .i64], result := .i64 }
  | .i64DivS => { mnemonic := "i64.div_s", bytes := [127], parameters := [.i64, .i64], result := .i64 }
  | .i32ShrS => { mnemonic := "i32.shr_s", bytes := [117], parameters := [.i32, .i32], result := .i32 }
  | .i32RemS => { mnemonic := "i32.rem_s", bytes := [111], parameters := [.i32, .i32], result := .i32 }
  | .i32DivS => { mnemonic := "i32.div_s", bytes := [109], parameters := [.i32, .i32], result := .i32 }
  | .i32Clz => { mnemonic := "i32.clz", bytes := [103], parameters := [.i32], result := .i32 }
  | .i32DivU => { mnemonic := "i32.div_u", bytes := [110], parameters := [.i32, .i32], result := .i32 }
  | .i32RemU => { mnemonic := "i32.rem_u", bytes := [112], parameters := [.i32, .i32], result := .i32 }
  | .i32Shl => { mnemonic := "i32.shl", bytes := [116], parameters := [.i32, .i32], result := .i32 }
  | .i64DivU => { mnemonic := "i64.div_u", bytes := [128], parameters := [.i64, .i64], result := .i64 }
  | .i64RemU => { mnemonic := "i64.rem_u", bytes := [130], parameters := [.i64, .i64], result := .i64 }
  | .i64Shl => { mnemonic := "i64.shl", bytes := [134], parameters := [.i64, .i64], result := .i64 }
  | .i64ShrU => { mnemonic := "i64.shr_u", bytes := [136], parameters := [.i64, .i64], result := .i64 }
  | .i32WrapI64 => { mnemonic := "i32.wrap_i64", bytes := [167], parameters := [.i64], result := .i32 }
  | .i64ExtendI32U => { mnemonic := "i64.extend_i32_u", bytes := [173], parameters := [.i32], result := .i64 }

-- Memory operations are admitted only in explicitly marked ABI modules.
inductive PsWasmMemoryOp where
  | loadF32
  | loadF64
  | storeF32
  | storeF64
  | load32
  | load64
  | load8
  | load16
  | store32
  | store64
  | store8
  | store16
  | size
  | grow
  | copy

structure PsWasmMemoryInstruction where
  mnemonic : String
  bytes : List UInt8
  parameters : List PsWasmValueType
  results : List PsWasmValueType

def psWasmMemoryInstruction : PsWasmMemoryOp → PsWasmMemoryInstruction
  | .loadF32 => { mnemonic := "f32.load", bytes := [42, 2, 0], parameters := [.i32], results := [.f32] }
  | .loadF64 => { mnemonic := "f64.load", bytes := [43, 3, 0], parameters := [.i32], results := [.f64] }
  | .storeF32 => { mnemonic := "f32.store", bytes := [56, 2, 0], parameters := [.i32, .f32], results := [] }
  | .storeF64 => { mnemonic := "f64.store", bytes := [57, 3, 0], parameters := [.i32, .f64], results := [] }
  | .load64 => { mnemonic := "i64.load", bytes := [41, 3, 0], parameters := [.i32], results := [.i64] }
  | .load32 => { mnemonic := "i32.load", bytes := [40, 2, 0], parameters := [.i32], results := [.i32] }
  | .load8 => { mnemonic := "i32.load8_u", bytes := [45, 0, 0], parameters := [.i32], results := [.i32] }
  | .load16 => { mnemonic := "i32.load16_u", bytes := [47, 1, 0], parameters := [.i32], results := [.i32] }
  | .store64 => { mnemonic := "i64.store", bytes := [55, 3, 0], parameters := [.i32, .i64], results := [] }
  | .store32 => { mnemonic := "i32.store", bytes := [54, 2, 0], parameters := [.i32, .i32], results := [] }
  | .store8 => { mnemonic := "i32.store8", bytes := [58, 0, 0], parameters := [.i32, .i32], results := [] }
  | .store16 => { mnemonic := "i32.store16", bytes := [59, 1, 0], parameters := [.i32, .i32], results := [] }
  | .size => { mnemonic := "memory.size", bytes := [63, 0], parameters := [], results := [.i32] }
  | .grow => { mnemonic := "memory.grow", bytes := [64, 0], parameters := [.i32], results := [.i32] }
  | .copy => { mnemonic := "memory.copy", bytes := [252, 10, 0, 0], parameters := [.i32, .i32, .i32], results := [] }

inductive PsWasmInstruction where
  | memory (operation : PsWasmMemoryOp)
  | globalGet (index : Nat)
  | globalSet (index : Nat)
  | word (operation : PsWasmWordOp)
  | localGet (index : Nat)
  | localSet (index : Nat)
  | drop
  | unreachable
  | call (name : String)
  | returnCall (name : String)
  | return_
  | ifStart (result : Option PsWasmValueType)
  | else_
  | end_
  | i32Const (value : Int)
  | i64Const (value : Int)
  | f32ConstBits (bits : UInt32)
  | f64ConstBits (bits : UInt64)
  | i32Add
  | i32Sub
  | i32Mul
  | i32And
  | i32Or
  | i32Xor
  | i32ShrU
  | i32Extend8S
  | i32Extend16S
  | i32Eq
  | i32Ne
  | i32LtS
  | i32LtU
  | i32LeS
  | i32LeU
  | i32GtS
  | i32GtU
  | i32GeS
  | i32GeU
  | i64Add
  | i64Sub
  | i64Mul
  | i64And
  | i64Or
  | i64Xor
  | i64Eq
  | i64Ne
  | i64LtS
  | i64LtU
  | i64LeS
  | i64LeU
  | i64GtS
  | i64GtU
  | i64GeS
  | i64GeU
  | f32Add
  | f32Sub
  | f32Mul
  | f32Div
  | f32Eq
  | f32Ne
  | f32Lt
  | f32Le
  | f32Gt
  | f32Ge
  | f64Add
  | f64Sub
  | f64Mul
  | f64Div
  | f64Eq
  | f64Ne
  | f64Lt
  | f64Le
  | f64Gt
  | f64Ge
  | structNew (typeName : String)
  | structGet (typeName : String) (fieldIndex : Nat)
  | structGetS (typeName : String) (fieldIndex : Nat)
  | structGetU (typeName : String) (fieldIndex : Nat)
  | arrayNew (typeName : String)
  | arrayNewDefault (typeName : String)
  | arrayNewFixed (typeName : String) (length : Nat)
  | arrayGet (typeName : String)
  | arrayGetS (typeName : String)
  | arrayGetU (typeName : String)
  | arraySet (typeName : String)
  | arrayLen
  | arrayCopy (destinationType : String) (sourceType : String)
  | refTest (typeName : String)
  | refCast (typeName : String)
  | refFunc (functionName : String)
  | refCastFunction (typeName : String)
  | callRef (typeName : String)
  | returnCallRef (typeName : String)

structure PsWasmStructField where
  name : String
  storageType : PsWasmStorageType

structure PsWasmStructType where
  name : String
  superType : Option String
  isFinal : Bool
  fields : List PsWasmStructField

structure PsWasmArrayType where
  name : String
  elementType : PsWasmStorageType
  mutable : Bool

structure PsWasmFunctionType where
  name : String
  parameters : List PsWasmValueType
  results : List PsWasmValueType

structure PsWasmFunction where
  name : String
  typeName : Option String
  parameters : List PsWasmValueType
  results : List PsWasmValueType
  locals : List PsWasmValueType
  body : List PsWasmInstruction

structure PsWasmModule where
  abiMemory : Bool := false
  abiGlobals : List (String × Int) := []
  structures : List PsWasmStructType
  arrays : List PsWasmArrayType
  functionTypes : List PsWasmFunctionType
  functions : List PsWasmFunction
  functionRefs : List String
  exports : List (String × String)

def psWasmModuleEmpty : PsWasmModule :=
  {
    structures := []
    arrays := []
    functionTypes := []
    functions := []
    functionRefs := []
    exports := []
  }
