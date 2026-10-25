import Ps.Host.BackendProviderInstances
import Ps.CompilerIr.Encode

-- Native tuple transport only; no elaborator, optimizer, admission or publisher.
-- Every accepted value must round-trip through the existing canonical encoder.
namespace Ps.Host.PortableIr

def rows (value : Lean.Json) : Except String (List Lean.Json) :=
  return (← value.getArr?).toList

def string (value : Lean.Json) : Except String String := value.getStr?

def primitive (value : Lean.Json) : Except String PsVerifiedIrPrimitiveType := do
  match ← string value with
  | "nat" => return .nat
  | "int" => return .int
  | "uint8" => return .uint8
  | "uint16" => return .uint16
  | "uint32" => return .uint32
  | "uint64" => return .uint64
  | "usize" => return .usize
  | "int8" => return .int8
  | "int16" => return .int16
  | "int32" => return .int32
  | "int64" => return .int64
  | "isize" => return .isize
  | "float" => return .float
  | "float32" => return .float32
  | "bool" => return .bool
  | "char" => return .char
  | "string" => return .string
  | "unit" => return .unit
  | _ => throw "PSC1_PORTABLE_IR_PRIMITIVE"

def type (fuel : Nat) (value : Lean.Json) : Except String PsVerifiedIrType := do
  match fuel with
  | 0 => throw "PSC1_PORTABLE_IR_DEPTH"
  | fuel + 1 =>
    match ← rows value with
    | [.str "unknown"] => return .unknown
    | [.str "typeParameter", name] => return .typeParameter (← string name)
    | [.str "primitive", name] => return .primitive (← primitive name)
    | [.str "function", parameters, result] =>
      return .function (← (← rows parameters).mapM (type fuel)) (← type fuel result)
    | [.str "named", name, arguments] =>
      return .named (← string name) (← (← rows arguments).mapM (type fuel))
    | _ => throw "PSC1_PORTABLE_IR_TYPE"

def integer (value : Lean.Json) : Except String Int := do
  let some result := (← string value).toInt? | throw "PSC1_PORTABLE_IR_INTEGER"
  return result

def literal (value : Lean.Json) : Except String PsVerifiedIrLiteral := do
  match ← rows value with
  | [.str "natural", number] =>
    let some result := (← string number).toNat? | throw "PSC1_PORTABLE_IR_NATURAL"
    return .natural result
  | [.str "integer", number] => return .integer (← integer number)
  | [.str "machineInteger", kind, number] => return .machineInteger (← Lean.fromJson? kind) (← integer number)
  | [.str "string", text] => return .string (← string text)
  | [.str "bool", flag] => return .bool (← flag.getBool?)
  | [.str "unit"] => return .unit
  | _ => throw "PSC1_PORTABLE_IR_LITERAL"

def intrinsic (value : Lean.Json) : Except String PsVerifiedIrIntrinsic := do
  match ← rows value with
  | [.str "machineIntBinary", kind, operation] => return .machineIntBinary (← Lean.fromJson? kind) (← Lean.fromJson? operation)
  | [.str "machineIntCompare", kind, operation] => return .machineIntCompare (← Lean.fromJson? kind) (← Lean.fromJson? operation)
  | [.str "floatBinary", kind, operation] => return .floatBinary (← Lean.fromJson? kind) (← Lean.fromJson? operation)
  | [.str "floatCompare", kind, operation] => return .floatCompare (← Lean.fromJson? kind) (← Lean.fromJson? operation)
  | [.str "natAdd"] => return .natAdd
  | [.str "natSub"] => return .natSub
  | [.str "natMul"] => return .natMul
  | [.str "natDiv"] => return .natDiv
  | [.str "natMod"] => return .natMod
  | [.str "natEq"] => return .natEq
  | [.str "natNe"] => return .natNe
  | [.str "natLe"] => return .natLe
  | [.str "natLt"] => return .natLt
  | [.str "intOfNat"] => return .intOfNat
  | [.str "intRepr"] => return .intRepr
  | [.str "intNegSucc"] => return .intNegSucc
  | [.str "intNeg"] => return .intNeg
  | [.str "intAdd"] => return .intAdd
  | [.str "intSub"] => return .intSub
  | [.str "intMul"] => return .intMul
  | [.str "intEq"] => return .intEq
  | [.str "intLe"] => return .intLe
  | [.str "intLt"] => return .intLt
  | [.str "boolNot"] => return .boolNot
  | [.str "boolAnd"] => return .boolAnd
  | [.str "boolOr"] => return .boolOr
  | [.str "boolEq"] => return .boolEq
  | [.str "boolNe"] => return .boolNe
  | [.str "charOfNat"] => return .charOfNat
  | [.str "charToNat"] => return .charToNat
  | [.str "stringPush"] => return .stringPush
  | [.str "stringSingleton"] => return .stringSingleton
  | [.str "stringLength"] => return .stringLength
  | [.str "stringAppend"] => return .stringAppend
  | [.str "stringUtf8ByteSize"] => return .stringUtf8ByteSize
  | [.str "stringNext"] => return .stringNext
  | [.str "stringGet"] => return .stringGet
  | [.str "stringAtEnd"] => return .stringAtEnd
  | [.str "stringExtract"] => return .stringExtract
  | [.str "stringEq"] => return .stringEq
  | [.str "arrayEmptyWithCapacity"] => return .arrayEmptyWithCapacity
  | [.str "arraySize"] => return .arraySize
  | [.str "arrayPush"] => return .arrayPush
  | [.str "arrayGet"] => return .arrayGet
  | [.str "arrayGetD"] => return .arrayGetD
  | [.str "arraySet"] => return .arraySet
  | [.str "arraySetIfInBounds"] => return .arraySetIfInBounds
  | [.str "arrayMap"] => return .arrayMap
  | [.str "arrayFoldl"] => return .arrayFoldl
  | _ => throw "PSC1_PORTABLE_IR_INTRINSIC"

def parameter (value : Lean.Json) : Except String PsVerifiedIrParameter := do
  match ← rows value with
  | [name, kind] => return { name := ← string name, type := ← type 4096 kind }
  | _ => throw "PSC1_PORTABLE_IR_PARAMETER"

def binding (value : Lean.Json) : Except String PsVerifiedIrMatchBinding := do
  match ← rows value with
  | [field, name, kind] => return { field := ← string field, name := ← string name, type := ← type 4096 kind }
  | _ => throw "PSC1_PORTABLE_IR_BINDING"

def expr (fuel : Nat) (value : Lean.Json) : Except String PsVerifiedIrExpr := do
  match fuel with
  | 0 => throw "PSC1_PORTABLE_IR_DEPTH"
  | fuel + 1 =>
    let types := fun value => do (← rows value).mapM (type 4096)
    let fields := fun value => do
      (← rows value).mapM fun field => do
        match ← rows field with
        | [name, body] => return (← string name, ← expr fuel body)
        | _ => throw "PSC1_PORTABLE_IR_FIELD"
    match ← rows value with
    | [.str "literal", data] => return .literal (← literal data)
    | [.str "var", name] => return .var (← string name)
    | [.str "intrinsic", operation, arguments, values] =>
      return .intrinsic (← intrinsic operation) (← types arguments) (← (← rows values).mapM (expr fuel))
    | [.str "lambda", parameters, result, body] =>
      return .lambda (← (← rows parameters).mapM parameter) (← type 4096 result) (← expr fuel body)
    | [.str "call", fn, arguments, values] =>
      return .call (← expr fuel fn) (← types arguments) (← (← rows values).mapM (expr fuel))
    | [.str "letE", name, kind, value, body] =>
      return .letE (← string name) (← type 4096 kind) (← expr fuel value) (← expr fuel body)
    | [.str "ifE", condition, yes, no] =>
      return .ifE (← expr fuel condition) (← expr fuel yes) (← expr fuel no)
    | [.str "record", name, arguments, values] => return .record (← string name) (← types arguments) (← fields values)
    | [.str "projection", name, arguments, value, field] =>
      return .projection (← string name) (← types arguments) (← expr fuel value) (← string field)
    | [.str "constructor", owner, name, arguments, values] =>
      return .constructor (← string owner) (← string name) (← types arguments) (← fields values)
    | [.str "matchE", name, arguments, value, alternatives] =>
      let alternatives ← (← rows alternatives).mapM fun alternative => do
        match ← rows alternative with
        | [name, bindings, body] => return (← string name, ← (← rows bindings).mapM binding, ← expr fuel body)
        | _ => throw "PSC1_PORTABLE_IR_ALTERNATIVE"
      return .matchE (← string name) (← types arguments) (← expr fuel value) alternatives
    | _ => throw "PSC1_PORTABLE_IR_EXPRESSION"

def typeParameters (value : Lean.Json) : Except String (List PsVerifiedIrTypeParameter) := do
  (← rows value).mapM fun name => return { name := ← string name }

def structureField (value : Lean.Json) : Except String PsVerifiedIrStructureField := do
  let p ← parameter value
  return { name := p.name, type := p.type }

def structureRow (value : Lean.Json) : Except String PsVerifiedIrStructure := do
  match ← rows value with
  | [name, parameters, fields] =>
    return { name := ← string name, typeParameters := ← typeParameters parameters, fields := ← (← rows fields).mapM structureField }
  | _ => throw "PSC1_PORTABLE_IR_STRUCTURE"

def constructorField (value : Lean.Json) : Except String PsVerifiedIrConstructorField := do
  let p ← parameter value
  return { name := p.name, type := p.type }

def constructorRow (value : Lean.Json) : Except String PsVerifiedIrConstructor := do
  match ← rows value with
  | [name, fields] => return { name := ← string name, fields := ← (← rows fields).mapM constructorField }
  | _ => throw "PSC1_PORTABLE_IR_CONSTRUCTOR"

def inductiveRow (value : Lean.Json) : Except String PsVerifiedIrInductive := do
  match ← rows value with
  | [name, parameters, constructors] =>
    return { name := ← string name, typeParameters := ← typeParameters parameters, constructors := ← (← rows constructors).mapM constructorRow }
  | _ => throw "PSC1_PORTABLE_IR_INDUCTIVE"

def declaration (value : Lean.Json) : Except String PsVerifiedIrDeclaration := do
  match ← rows value with
  | [name, parameters, arguments, result, body] =>
    return { name := ← string name, typeParameters := ← typeParameters parameters,
      parameters := ← (← rows arguments).mapM parameter, resultType := ← type 4096 result, body := ← expr 4096 body }
  | _ => throw "PSC1_PORTABLE_IR_DECLARATION"

def imported (value : Lean.Json) : Except String PsVerifiedIrExternalImport := do
  match ← rows value with
  | [name, source, imported, kind] =>
    return { localName := ← string name, source := ← string source, importedName := ← string imported, type := ← type 4096 kind }
  | _ => throw "PSC1_PORTABLE_IR_IMPORT"

def decode (value : Lean.Json) : Except String PsVerifiedIrModule := do
  let result ← match ← rows value with
    | [.str "psc1-ir/1", imports, structures, inductives, declarations] =>
      pure { imports := ← (← rows imports).mapM imported,
        structures := ← (← rows structures).mapM structureRow,
        inductives := ← (← rows inductives).mapM inductiveRow,
        declarations := ← (← rows declarations).mapM declaration : PsVerifiedIrModule }
    | _ => throw "PSC1_PORTABLE_IR_MODULE"
  let encoded ← match psIrEncodeModule result with
    | .ok encoded => pure encoded
    | .error _ => throw "PSC1_PORTABLE_IR_ENCODE_DEPTH"
  if (← Lean.Json.parse encoded) != value then throw "PSC1_PORTABLE_IR_NONCANONICAL"
  return result

end Ps.Host.PortableIr
