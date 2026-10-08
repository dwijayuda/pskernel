import Ps.CompilerIr.Model
import Ps.Bridge.Json
import Ps.Foundation.List

inductive PsIrEncodeError where
  | depthExhausted

def psIrJsonValues (values : List (Except PsIrEncodeError String)) : Except PsIrEncodeError String :=
  let unwrap : Except PsIrEncodeError String -> Except PsIrEncodeError String :=
    fun (value : Except PsIrEncodeError String) => value;
  match psListMapExcept unwrap values with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

def psIrJsonNode (tag : String) (values : List (Except PsIrEncodeError String)) : Except PsIrEncodeError String :=
  psIrJsonValues (List.cons (Except.ok (psJsonQuote tag)) values)

def psIrJsonText (value : String) : Except PsIrEncodeError String :=
  Except.ok (psJsonQuote value)

def psIrJsonPrimitive (value : PsVerifiedIrPrimitiveType) : String :=
  match value with
  | .nat => psJsonQuote "nat"
  | .int => psJsonQuote "int"
  | .uint8 => psJsonQuote "uint8"
  | .uint16 => psJsonQuote "uint16"
  | .uint32 => psJsonQuote "uint32"
  | .uint64 => psJsonQuote "uint64"
  | .usize => psJsonQuote "usize"
  | .int8 => psJsonQuote "int8"
  | .int16 => psJsonQuote "int16"
  | .int32 => psJsonQuote "int32"
  | .int64 => psJsonQuote "int64"
  | .isize => psJsonQuote "isize"
  | .float => psJsonQuote "float"
  | .float32 => psJsonQuote "float32"
  | .bool => psJsonQuote "bool"
  | .char => psJsonQuote "char"
  | .string => psJsonQuote "string"
  | .unit => psJsonQuote "unit"

def psIrJsonMachine (value : PsVerifiedIrMachineIntegerType) : String :=
  match value with
  | .uint8 => psJsonQuote "uint8"
  | .uint16 => psJsonQuote "uint16"
  | .uint32 => psJsonQuote "uint32"
  | .uint64 => psJsonQuote "uint64"
  | .usize => psJsonQuote "usize"
  | .int8 => psJsonQuote "int8"
  | .int16 => psJsonQuote "int16"
  | .int32 => psJsonQuote "int32"
  | .int64 => psJsonQuote "int64"
  | .isize => psJsonQuote "isize"

def psIrJsonIntegerBinary (value : PsVerifiedIrIntegerBinaryOp) : String :=
  match value with
  | .add => psJsonQuote "add"
  | .sub => psJsonQuote "sub"
  | .mul => psJsonQuote "mul"
  | .bitAnd => psJsonQuote "bitAnd"
  | .bitOr => psJsonQuote "bitOr"
  | .bitXor => psJsonQuote "bitXor"

def psIrJsonIntegerCompare (value : PsVerifiedIrIntegerCompareOp) : String :=
  match value with
  | .eq => psJsonQuote "eq"
  | .ne => psJsonQuote "ne"
  | .lt => psJsonQuote "lt"
  | .le => psJsonQuote "le"
  | .gt => psJsonQuote "gt"
  | .ge => psJsonQuote "ge"

def psIrJsonFloating (value : PsVerifiedIrFloatingType) : String :=
  match value with
  | .float => psJsonQuote "float"
  | .float32 => psJsonQuote "float32"

def psIrJsonFloatBinary (value : PsVerifiedIrFloatBinaryOp) : String :=
  match value with
  | .add => psJsonQuote "add"
  | .sub => psJsonQuote "sub"
  | .mul => psJsonQuote "mul"
  | .div => psJsonQuote "div"

def psIrJsonFloatCompare (value : PsVerifiedIrFloatCompareOp) : String :=
  match value with
  | .eq => psJsonQuote "eq"
  | .ne => psJsonQuote "ne"
  | .lt => psJsonQuote "lt"
  | .le => psJsonQuote "le"
  | .gt => psJsonQuote "gt"
  | .ge => psJsonQuote "ge"

def psIrJsonIntrinsic (value : PsVerifiedIrIntrinsic) : String :=
  match value with
  | .machineIntBinary type op => psJsonArray [psJsonQuote "machineIntBinary", psIrJsonMachine type, psIrJsonIntegerBinary op]
  | .machineIntCompare type op => psJsonArray [psJsonQuote "machineIntCompare", psIrJsonMachine type, psIrJsonIntegerCompare op]
  | .floatBinary type op => psJsonArray [psJsonQuote "floatBinary", psIrJsonFloating type, psIrJsonFloatBinary op]
  | .floatCompare type op => psJsonArray [psJsonQuote "floatCompare", psIrJsonFloating type, psIrJsonFloatCompare op]
  | .uint8OfNat => psJsonArray [psJsonQuote "uint8OfNat"]
  | .natAdd => psJsonArray [psJsonQuote "natAdd"]
  | .natSub => psJsonArray [psJsonQuote "natSub"]
  | .natMul => psJsonArray [psJsonQuote "natMul"]
  | .natDiv => psJsonArray [psJsonQuote "natDiv"]
  | .natMod => psJsonArray [psJsonQuote "natMod"]
  | .natEq => psJsonArray [psJsonQuote "natEq"]
  | .natNe => psJsonArray [psJsonQuote "natNe"]
  | .natLe => psJsonArray [psJsonQuote "natLe"]
  | .natLt => psJsonArray [psJsonQuote "natLt"]
  | .intOfNat => psJsonArray [psJsonQuote "intOfNat"]
  | .intRepr => psJsonArray [psJsonQuote "intRepr"]
  | .intNegSucc => psJsonArray [psJsonQuote "intNegSucc"]
  | .intNeg => psJsonArray [psJsonQuote "intNeg"]
  | .intAdd => psJsonArray [psJsonQuote "intAdd"]
  | .intSub => psJsonArray [psJsonQuote "intSub"]
  | .intMul => psJsonArray [psJsonQuote "intMul"]
  | .intEq => psJsonArray [psJsonQuote "intEq"]
  | .intLe => psJsonArray [psJsonQuote "intLe"]
  | .intLt => psJsonArray [psJsonQuote "intLt"]
  | .boolNot => psJsonArray [psJsonQuote "boolNot"]
  | .boolAnd => psJsonArray [psJsonQuote "boolAnd"]
  | .boolOr => psJsonArray [psJsonQuote "boolOr"]
  | .boolEq => psJsonArray [psJsonQuote "boolEq"]
  | .boolNe => psJsonArray [psJsonQuote "boolNe"]
  | .charOfNat => psJsonArray [psJsonQuote "charOfNat"]
  | .charToNat => psJsonArray [psJsonQuote "charToNat"]
  | .stringPush => psJsonArray [psJsonQuote "stringPush"]
  | .stringSingleton => psJsonArray [psJsonQuote "stringSingleton"]
  | .stringLength => psJsonArray [psJsonQuote "stringLength"]
  | .stringAppend => psJsonArray [psJsonQuote "stringAppend"]
  | .stringUtf8ByteSize => psJsonArray [psJsonQuote "stringUtf8ByteSize"]
  | .stringNext => psJsonArray [psJsonQuote "stringNext"]
  | .stringGet => psJsonArray [psJsonQuote "stringGet"]
  | .stringAtEnd => psJsonArray [psJsonQuote "stringAtEnd"]
  | .stringExtract => psJsonArray [psJsonQuote "stringExtract"]
  | .stringEq => psJsonArray [psJsonQuote "stringEq"]
  | .arrayEmptyWithCapacity => psJsonArray [psJsonQuote "arrayEmptyWithCapacity"]
  | .arraySize => psJsonArray [psJsonQuote "arraySize"]
  | .arrayPush => psJsonArray [psJsonQuote "arrayPush"]
  | .arrayGet => psJsonArray [psJsonQuote "arrayGet"]
  | .arrayGetD => psJsonArray [psJsonQuote "arrayGetD"]
  | .arraySet => psJsonArray [psJsonQuote "arraySet"]
  | .arraySetIfInBounds => psJsonArray [psJsonQuote "arraySetIfInBounds"]
  | .arrayMap => psJsonArray [psJsonQuote "arrayMap"]
  | .arrayFoldl => psJsonArray [psJsonQuote "arrayFoldl"]

def psIrJsonTypeWithFuel (fuel : Nat) : PsVerifiedIrType -> Except PsIrEncodeError String :=
  match fuel with
  | Nat.zero => fun (_value : PsVerifiedIrType) => Except.error PsIrEncodeError.depthExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Except PsIrEncodeError String := psIrJsonTypeWithFuel remaining;
      fun (value : PsVerifiedIrType) =>
        match value with
        | .unknown => psIrJsonNode "unknown" List.nil
        | .typeParameter name => psIrJsonNode "typeParameter" [psIrJsonText name]
        | .primitive type => psIrJsonNode "primitive" [Except.ok (psIrJsonPrimitive type)]
        | .named name arguments => psIrJsonNode "named"
            [psIrJsonText name, psIrJsonValues (psListMap smaller arguments)]
        | .function parameters result => psIrJsonNode "function"
            [psIrJsonValues (psListMap smaller parameters), smaller result]

def psIrJsonType (value : PsVerifiedIrType) : Except PsIrEncodeError String :=
  psIrJsonTypeWithFuel 4096 value

def psIrJsonBool (value : Bool) : String :=
  if value then "true" else "false"

def psIrJsonLiteral (value : PsVerifiedIrLiteral) : Except PsIrEncodeError String :=
  match value with
  | .natural n => psIrJsonNode "natural" [psIrJsonText (psNatToString n)]
  | .integer n => psIrJsonNode "integer" [psIrJsonText (Int.repr n)]
  | .machineInteger type n => psIrJsonNode "machineInteger" [Except.ok (psIrJsonMachine type), psIrJsonText (Int.repr n)]
  | .string text => psIrJsonNode "string" [psIrJsonText text]
  | .bool value => psIrJsonNode "bool" [Except.ok (psIrJsonBool value)]
  | .unit => psIrJsonNode "unit" List.nil

def psIrJsonParameter (value : PsVerifiedIrParameter) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonType value.type]

def psIrJsonParameters (values : List PsVerifiedIrParameter) : Except PsIrEncodeError String :=
  psIrJsonValues (psListMap psIrJsonParameter values)

def psIrJsonBinding (value : PsVerifiedIrMatchBinding) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.field, psIrJsonText value.name, psIrJsonType value.type]

def psIrJsonFieldWith (encode : PsVerifiedIrExpr -> Except PsIrEncodeError String)
    (value : Prod String PsVerifiedIrExpr) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText (Prod.fst value), encode (Prod.snd value)]

def psIrJsonAlternativeWith (encode : PsVerifiedIrExpr -> Except PsIrEncodeError String)
    (value : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) : Except PsIrEncodeError String :=
  let payload := Prod.snd value;
  psIrJsonValues [psIrJsonText (Prod.fst value),
    psIrJsonValues (psListMap psIrJsonBinding (Prod.fst payload)), encode (Prod.snd payload)]

def psIrJsonExprWithFuel (fuel : Nat) : PsVerifiedIrExpr -> Except PsIrEncodeError String :=
  match fuel with
  | Nat.zero => fun (_value : PsVerifiedIrExpr) => Except.error PsIrEncodeError.depthExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Except PsIrEncodeError String := psIrJsonExprWithFuel remaining;
      fun (value : PsVerifiedIrExpr) =>
        match value with
        | .literal literal => psIrJsonNode "literal" [psIrJsonLiteral literal]
        | .var name => psIrJsonNode "var" [psIrJsonText name]
        | .intrinsic op types arguments => psIrJsonNode "intrinsic"
            [Except.ok (psIrJsonIntrinsic op), psIrJsonValues (psListMap psIrJsonType types),
             psIrJsonValues (psListMap smaller arguments)]
        | .lambda parameters result body => psIrJsonNode "lambda"
            [psIrJsonParameters parameters, psIrJsonType result, smaller body]
        | .call fn types arguments => psIrJsonNode "call"
            [smaller fn, psIrJsonValues (psListMap psIrJsonType types), psIrJsonValues (psListMap smaller arguments)]
        | .letE name type value body => psIrJsonNode "let"
            [psIrJsonText name, psIrJsonType type, smaller value, smaller body]
        | .ifE condition yes no => psIrJsonNode "if" [smaller condition, smaller yes, smaller no]
        | .record name types fields => psIrJsonNode "record"
            [psIrJsonText name, psIrJsonValues (psListMap psIrJsonType types),
             psIrJsonValues (psListMap (psIrJsonFieldWith smaller) fields)]
        | .projection name types target field => psIrJsonNode "projection"
            [psIrJsonText name, psIrJsonValues (psListMap psIrJsonType types), smaller target, psIrJsonText field]
        | .constructor name ctor types fields => psIrJsonNode "constructor"
            [psIrJsonText name, psIrJsonText ctor, psIrJsonValues (psListMap psIrJsonType types),
             psIrJsonValues (psListMap (psIrJsonFieldWith smaller) fields)]
        | .matchE name types scrutinee alternatives => psIrJsonNode "match"
            [psIrJsonText name, psIrJsonValues (psListMap psIrJsonType types), smaller scrutinee,
             psIrJsonValues (psListMap (psIrJsonAlternativeWith smaller) alternatives)]

def psIrJsonTypeParameter (value : PsVerifiedIrTypeParameter) : String := psJsonQuote value.name

def psIrJsonTypeParameters (values : List PsVerifiedIrTypeParameter) : Except PsIrEncodeError String :=
  Except.ok (psJsonArray (psListMap psIrJsonTypeParameter values))

def psIrJsonStructureField (value : PsVerifiedIrStructureField) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonType value.type]

def psIrJsonConstructorField (value : PsVerifiedIrConstructorField) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonType value.type]

def psIrJsonConstructor (value : PsVerifiedIrConstructor) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonValues (psListMap psIrJsonConstructorField value.fields)]

def psIrJsonStructure (value : PsVerifiedIrStructure) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonTypeParameters value.typeParameters,
    psIrJsonValues (psListMap psIrJsonStructureField value.fields)]

def psIrJsonInductive (value : PsVerifiedIrInductive) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonTypeParameters value.typeParameters,
    psIrJsonValues (psListMap psIrJsonConstructor value.constructors)]

def psIrJsonImport (value : PsVerifiedIrExternalImport) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.localName, psIrJsonText value.source,
    psIrJsonText value.importedName, psIrJsonType value.type]

def psIrJsonDeclaration (value : PsVerifiedIrDeclaration) : Except PsIrEncodeError String :=
  psIrJsonValues [psIrJsonText value.name, psIrJsonTypeParameters value.typeParameters,
    psIrJsonParameters value.parameters, psIrJsonType value.resultType, psIrJsonExprWithFuel 4096 value.body]

-- Ordered tagged arrays encode every constructor without relying on a host
-- object layout. Integers are canonical decimal strings, preserving arbitrary
-- precision. This encodes construction IR, so unknown/invalid IR can be
-- archived without being asserted to have passed validation.
def psIrEncodeModule (value : PsVerifiedIrModule) : Except PsIrEncodeError String :=
  psIrJsonNode "psc-runtime-ir-json/1" [
    psIrJsonValues (psListMap psIrJsonImport value.imports),
    psIrJsonValues (psListMap psIrJsonStructure value.structures),
    psIrJsonValues (psListMap psIrJsonInductive value.inductives),
    psIrJsonValues (psListMap psIrJsonDeclaration value.declarations)]
