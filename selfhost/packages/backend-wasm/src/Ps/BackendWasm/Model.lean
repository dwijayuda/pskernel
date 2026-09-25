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
  | call (name : String)
  | return_
  | i32Const (value : Int)
  | i64Const (value : Int)
  | f32ConstBits (bits : UInt32)
  | f64ConstBits (bits : UInt64)

structure PsWasmFunction where
  name : String
  parameters : List PsWasmValueType
  results : List PsWasmValueType
  body : List PsWasmInstruction

structure PsWasmModule where
  functions : List PsWasmFunction
  exports : List (String × String)

def psWasmModuleEmpty : PsWasmModule :=
  {
    functions := []
    exports := []
  }
