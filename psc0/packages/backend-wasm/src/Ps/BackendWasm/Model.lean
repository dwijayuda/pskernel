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
  | i32Clz
  | i32DivU
  | i32RemU
  | i32Shl
  | i64DivU
  | i64RemU
  | i64Shl
  | i64ShrU
  | i32WrapI64
  | i64ExtendI32U

structure PsWasmWordInstruction where
  mnemonic : String
  opcode : UInt8
  parameters : List PsWasmValueType
  result : PsWasmValueType

def psWasmWordInstruction : PsWasmWordOp → PsWasmWordInstruction
  | .i32Clz => { mnemonic := "i32.clz", opcode := 103, parameters := [.i32], result := .i32 }
  | .i32DivU => { mnemonic := "i32.div_u", opcode := 110, parameters := [.i32, .i32], result := .i32 }
  | .i32RemU => { mnemonic := "i32.rem_u", opcode := 112, parameters := [.i32, .i32], result := .i32 }
  | .i32Shl => { mnemonic := "i32.shl", opcode := 116, parameters := [.i32, .i32], result := .i32 }
  | .i64DivU => { mnemonic := "i64.div_u", opcode := 128, parameters := [.i64, .i64], result := .i64 }
  | .i64RemU => { mnemonic := "i64.rem_u", opcode := 130, parameters := [.i64, .i64], result := .i64 }
  | .i64Shl => { mnemonic := "i64.shl", opcode := 134, parameters := [.i64, .i64], result := .i64 }
  | .i64ShrU => { mnemonic := "i64.shr_u", opcode := 136, parameters := [.i64, .i64], result := .i64 }
  | .i32WrapI64 => { mnemonic := "i32.wrap_i64", opcode := 167, parameters := [.i64], result := .i32 }
  | .i64ExtendI32U => { mnemonic := "i64.extend_i32_u", opcode := 173, parameters := [.i32], result := .i64 }

-- Memory operations are admitted only in explicitly marked ABI modules.
inductive PsWasmMemoryOp where
  | load32
  | load8
  | load16
  | store32
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
  | .load32 => { mnemonic := "i32.load", bytes := [40, 2, 0], parameters := [.i32], results := [.i32] }
  | .load8 => { mnemonic := "i32.load8_u", bytes := [45, 0, 0], parameters := [.i32], results := [.i32] }
  | .load16 => { mnemonic := "i32.load16_u", bytes := [47, 1, 0], parameters := [.i32], results := [.i32] }
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
