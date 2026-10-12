import Ps.BackendWasm.RuntimeBuilder
import Ps.CompilerIr.CheckTypes

namespace PsWasm

-- Only generic/scalar crossings allocate boxes. All reference-shaped values
-- already extend Value. Arrays are wrapped so generic values need no funcref
-- or scalar/eqref type punning.
def valueName := "__ps_Value"
def valueType : PsWasmValueType := .refT valueName
def scalarBoxName := "__ps_Scalar"
def naturalName := "__ps_Natural"
def limbsName := "__ps_Limbs"
def integerName := "__ps_Integer"
def stringName := "__ps_String"
def bytesName := "__ps_Bytes"
def valuesName := "__ps_Values"
def arrayName := "__ps_Array"
def closureName := "__ps_Closure"

def refType (name : String) : PsWasmValueType := .refT name
def naturalType := refType naturalName
def integerType := refType integerName
def stringType := refType stringName
def arrayType := refType arrayName
def closureType := refType closureName
def limbsType := refType limbsName
def bytesType := refType bytesName
def valuesType := refType valuesName

def representation : PsVerifiedIrType → Except String PsWasmValueType
  | .typeParameter _ => pure valueType
  | .primitive .nat => pure naturalType
  | .primitive .int => pure integerType
  | .primitive .string => pure stringType
  | .primitive .bool | .primitive .char | .primitive .unit => pure .i32
  | .named "Array" [_] => pure arrayType
  | .named name _ => pure (.refT name)
  | .function .. => pure closureType
  | _ => throw "PSCV0-WASM-CAPABILITY: runtime type is not in the checked v7 profile"

def box (type : PsVerifiedIrType) : Except String (List PsWasmInstruction) := do
  match ← representation type with
  | .i32 => return [.structNew scalarBoxName]
  | .refT _ => return []
  | _ => throw "PSCV0-WASM-BOX: unsupported scalar representation"

def unbox (type : PsVerifiedIrType) : Except String (List PsWasmInstruction) := do
  match ← representation type with
  | .i32 => return [.refCast scalarBoxName, .structGet scalarBoxName 0]
  | .refT name => return if name == valueName then [] else [.refCast name]
  | _ => throw "PSCV0-WASM-BOX: unsupported scalar representation"

def genericType : PsVerifiedIrType → Bool
  | .typeParameter _ => true
  | _ => false

def convert (actual expected : PsVerifiedIrType) : Except String (List PsWasmInstruction) :=
  if genericType actual && !genericType expected then unbox expected
  else if !genericType actual && genericType expected then box actual
  else pure []

def valueStructure (name : String) (fields : List (String × PsWasmValueType)) : PsWasmStructType := {
  name, superType := some valueName, isFinal := true
  fields := fields.map fun (name, type) => { name, storageType := .value type } }

def valueStructures : List PsWasmStructType := [
  { name := valueName, superType := none, isFinal := false, fields := [] },
  valueStructure scalarBoxName [("value", .i32)],
  valueStructure naturalName [("limbs", limbsType)],
  valueStructure integerName [("sign", .i32), ("magnitude", naturalType)],
  valueStructure stringName [("bytes", bytesType), ("length", .i32)],
  valueStructure arrayName [("values", valuesType)],
  valueStructure closureName [("code", .funcRef), ("captures", valuesType)]]

def valueArrays : List PsWasmArrayType := [
  { name := limbsName, elementType := .value .i32, mutable := true },
  { name := bytesName, elementType := .packedI8, mutable := true },
  { name := valuesName, elementType := .value valueType, mutable := true }]

def closureCodeName (arity : Nat) := "__ps_ClosureCode_" ++ toString arity
def closureCodeType (arity : Nat) : PsWasmFunctionType := {
  name := closureCodeName arity
  parameters := closureType :: List.replicate arity valueType
  results := [valueType] }

def substitute (parameters : List PsVerifiedIrTypeParameter) (arguments : List PsVerifiedIrType)
    (type : PsVerifiedIrType) : Except String PsVerifiedIrType :=
  (psIrCheckSubstitute 65536 ((parameters.map (·.name)).zip arguments) type).mapError
    (fun e => "PSCV0-WASM-TYPE: " ++ e.code ++ ": " ++ e.detail)

end PsWasm
