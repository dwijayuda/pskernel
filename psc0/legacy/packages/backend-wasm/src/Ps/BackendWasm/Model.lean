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

inductive PsWasmInstruction where
  | localGet (index : Nat)
  | localSet (index : Nat)
  | drop
  | unreachable
  | call (name : String)
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
