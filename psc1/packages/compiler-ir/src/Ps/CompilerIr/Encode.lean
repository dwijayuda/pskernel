import Ps.CompilerIr.Model
import Ps.Bridge.Json
import Ps.Foundation.List
import Ps.Foundation.Name

-- Deterministic tagged-tuple transport of actual IR; never a validation token.
inductive PsIrEncodeError where
  | fuelExhausted

def psIrEncodePrimitiveType (value : PsVerifiedIrPrimitiveType) : String :=
  match value with
  | PsVerifiedIrPrimitiveType.nat => psJsonQuote "nat"
  | PsVerifiedIrPrimitiveType.int => psJsonQuote "int"
  | PsVerifiedIrPrimitiveType.uint8 => psJsonQuote "uint8"
  | PsVerifiedIrPrimitiveType.uint16 => psJsonQuote "uint16"
  | PsVerifiedIrPrimitiveType.uint32 => psJsonQuote "uint32"
  | PsVerifiedIrPrimitiveType.uint64 => psJsonQuote "uint64"
  | PsVerifiedIrPrimitiveType.usize => psJsonQuote "usize"
  | PsVerifiedIrPrimitiveType.int8 => psJsonQuote "int8"
  | PsVerifiedIrPrimitiveType.int16 => psJsonQuote "int16"
  | PsVerifiedIrPrimitiveType.int32 => psJsonQuote "int32"
  | PsVerifiedIrPrimitiveType.int64 => psJsonQuote "int64"
  | PsVerifiedIrPrimitiveType.isize => psJsonQuote "isize"
  | PsVerifiedIrPrimitiveType.float => psJsonQuote "float"
  | PsVerifiedIrPrimitiveType.float32 => psJsonQuote "float32"
  | PsVerifiedIrPrimitiveType.bool => psJsonQuote "bool"
  | PsVerifiedIrPrimitiveType.char => psJsonQuote "char"
  | PsVerifiedIrPrimitiveType.string => psJsonQuote "string"
  | PsVerifiedIrPrimitiveType.unit => psJsonQuote "unit"

def psIrEncodeMachineIntegerType (value : PsVerifiedIrMachineIntegerType) : String :=
  match value with
  | PsVerifiedIrMachineIntegerType.uint8 => psJsonQuote "uint8"
  | PsVerifiedIrMachineIntegerType.uint16 => psJsonQuote "uint16"
  | PsVerifiedIrMachineIntegerType.uint32 => psJsonQuote "uint32"
  | PsVerifiedIrMachineIntegerType.uint64 => psJsonQuote "uint64"
  | PsVerifiedIrMachineIntegerType.usize => psJsonQuote "usize"
  | PsVerifiedIrMachineIntegerType.int8 => psJsonQuote "int8"
  | PsVerifiedIrMachineIntegerType.int16 => psJsonQuote "int16"
  | PsVerifiedIrMachineIntegerType.int32 => psJsonQuote "int32"
  | PsVerifiedIrMachineIntegerType.int64 => psJsonQuote "int64"
  | PsVerifiedIrMachineIntegerType.isize => psJsonQuote "isize"

def psIrEncodeIntegerBinaryOp (value : PsVerifiedIrIntegerBinaryOp) : String :=
  match value with
  | PsVerifiedIrIntegerBinaryOp.add => psJsonQuote "add"
  | PsVerifiedIrIntegerBinaryOp.sub => psJsonQuote "sub"
  | PsVerifiedIrIntegerBinaryOp.mul => psJsonQuote "mul"
  | PsVerifiedIrIntegerBinaryOp.bitAnd => psJsonQuote "bitAnd"
  | PsVerifiedIrIntegerBinaryOp.bitOr => psJsonQuote "bitOr"
  | PsVerifiedIrIntegerBinaryOp.bitXor => psJsonQuote "bitXor"

def psIrEncodeIntegerCompareOp (value : PsVerifiedIrIntegerCompareOp) : String :=
  match value with
  | PsVerifiedIrIntegerCompareOp.eq => psJsonQuote "eq"
  | PsVerifiedIrIntegerCompareOp.ne => psJsonQuote "ne"
  | PsVerifiedIrIntegerCompareOp.lt => psJsonQuote "lt"
  | PsVerifiedIrIntegerCompareOp.le => psJsonQuote "le"
  | PsVerifiedIrIntegerCompareOp.gt => psJsonQuote "gt"
  | PsVerifiedIrIntegerCompareOp.ge => psJsonQuote "ge"

def psIrEncodeFloatingType (value : PsVerifiedIrFloatingType) : String :=
  match value with
  | PsVerifiedIrFloatingType.float => psJsonQuote "float"
  | PsVerifiedIrFloatingType.float32 => psJsonQuote "float32"

def psIrEncodeFloatBinaryOp (value : PsVerifiedIrFloatBinaryOp) : String :=
  match value with
  | PsVerifiedIrFloatBinaryOp.add => psJsonQuote "add"
  | PsVerifiedIrFloatBinaryOp.sub => psJsonQuote "sub"
  | PsVerifiedIrFloatBinaryOp.mul => psJsonQuote "mul"
  | PsVerifiedIrFloatBinaryOp.div => psJsonQuote "div"

def psIrEncodeFloatCompareOp (value : PsVerifiedIrFloatCompareOp) : String :=
  match value with
  | PsVerifiedIrFloatCompareOp.eq => psJsonQuote "eq"
  | PsVerifiedIrFloatCompareOp.ne => psJsonQuote "ne"
  | PsVerifiedIrFloatCompareOp.lt => psJsonQuote "lt"
  | PsVerifiedIrFloatCompareOp.le => psJsonQuote "le"
  | PsVerifiedIrFloatCompareOp.gt => psJsonQuote "gt"
  | PsVerifiedIrFloatCompareOp.ge => psJsonQuote "ge"

def psIrEncodeIntrinsic (value : PsVerifiedIrIntrinsic) : String :=
  match value with
  | PsVerifiedIrIntrinsic.machineIntBinary type operation =>
      psJsonArray [psJsonQuote "machineIntBinary", psIrEncodeMachineIntegerType type, psIrEncodeIntegerBinaryOp operation]
  | PsVerifiedIrIntrinsic.machineIntCompare type operation =>
      psJsonArray [psJsonQuote "machineIntCompare", psIrEncodeMachineIntegerType type, psIrEncodeIntegerCompareOp operation]
  | PsVerifiedIrIntrinsic.floatBinary type operation =>
      psJsonArray [psJsonQuote "floatBinary", psIrEncodeFloatingType type, psIrEncodeFloatBinaryOp operation]
  | PsVerifiedIrIntrinsic.floatCompare type operation =>
      psJsonArray [psJsonQuote "floatCompare", psIrEncodeFloatingType type, psIrEncodeFloatCompareOp operation]
  | PsVerifiedIrIntrinsic.natAdd => psJsonArray [psJsonQuote "natAdd"]
  | PsVerifiedIrIntrinsic.natSub => psJsonArray [psJsonQuote "natSub"]
  | PsVerifiedIrIntrinsic.natMul => psJsonArray [psJsonQuote "natMul"]
  | PsVerifiedIrIntrinsic.natDiv => psJsonArray [psJsonQuote "natDiv"]
  | PsVerifiedIrIntrinsic.natMod => psJsonArray [psJsonQuote "natMod"]
  | PsVerifiedIrIntrinsic.natEq => psJsonArray [psJsonQuote "natEq"]
  | PsVerifiedIrIntrinsic.natNe => psJsonArray [psJsonQuote "natNe"]
  | PsVerifiedIrIntrinsic.natLe => psJsonArray [psJsonQuote "natLe"]
  | PsVerifiedIrIntrinsic.natLt => psJsonArray [psJsonQuote "natLt"]
  | PsVerifiedIrIntrinsic.intOfNat => psJsonArray [psJsonQuote "intOfNat"]
  | PsVerifiedIrIntrinsic.intRepr => psJsonArray [psJsonQuote "intRepr"]
  | PsVerifiedIrIntrinsic.intNegSucc => psJsonArray [psJsonQuote "intNegSucc"]
  | PsVerifiedIrIntrinsic.intNeg => psJsonArray [psJsonQuote "intNeg"]
  | PsVerifiedIrIntrinsic.intAdd => psJsonArray [psJsonQuote "intAdd"]
  | PsVerifiedIrIntrinsic.intSub => psJsonArray [psJsonQuote "intSub"]
  | PsVerifiedIrIntrinsic.intMul => psJsonArray [psJsonQuote "intMul"]
  | PsVerifiedIrIntrinsic.intEq => psJsonArray [psJsonQuote "intEq"]
  | PsVerifiedIrIntrinsic.intLe => psJsonArray [psJsonQuote "intLe"]
  | PsVerifiedIrIntrinsic.intLt => psJsonArray [psJsonQuote "intLt"]
  | PsVerifiedIrIntrinsic.boolNot => psJsonArray [psJsonQuote "boolNot"]
  | PsVerifiedIrIntrinsic.boolAnd => psJsonArray [psJsonQuote "boolAnd"]
  | PsVerifiedIrIntrinsic.boolOr => psJsonArray [psJsonQuote "boolOr"]
  | PsVerifiedIrIntrinsic.boolEq => psJsonArray [psJsonQuote "boolEq"]
  | PsVerifiedIrIntrinsic.boolNe => psJsonArray [psJsonQuote "boolNe"]
  | PsVerifiedIrIntrinsic.charOfNat => psJsonArray [psJsonQuote "charOfNat"]
  | PsVerifiedIrIntrinsic.charToNat => psJsonArray [psJsonQuote "charToNat"]
  | PsVerifiedIrIntrinsic.stringPush => psJsonArray [psJsonQuote "stringPush"]
  | PsVerifiedIrIntrinsic.stringSingleton => psJsonArray [psJsonQuote "stringSingleton"]
  | PsVerifiedIrIntrinsic.stringLength => psJsonArray [psJsonQuote "stringLength"]
  | PsVerifiedIrIntrinsic.stringAppend => psJsonArray [psJsonQuote "stringAppend"]
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize => psJsonArray [psJsonQuote "stringUtf8ByteSize"]
  | PsVerifiedIrIntrinsic.stringNext => psJsonArray [psJsonQuote "stringNext"]
  | PsVerifiedIrIntrinsic.stringGet => psJsonArray [psJsonQuote "stringGet"]
  | PsVerifiedIrIntrinsic.stringAtEnd => psJsonArray [psJsonQuote "stringAtEnd"]
  | PsVerifiedIrIntrinsic.stringExtract => psJsonArray [psJsonQuote "stringExtract"]
  | PsVerifiedIrIntrinsic.stringEq => psJsonArray [psJsonQuote "stringEq"]
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity => psJsonArray [psJsonQuote "arrayEmptyWithCapacity"]
  | PsVerifiedIrIntrinsic.arraySize => psJsonArray [psJsonQuote "arraySize"]
  | PsVerifiedIrIntrinsic.arrayPush => psJsonArray [psJsonQuote "arrayPush"]
  | PsVerifiedIrIntrinsic.arrayGet => psJsonArray [psJsonQuote "arrayGet"]
  | PsVerifiedIrIntrinsic.arrayGetD => psJsonArray [psJsonQuote "arrayGetD"]
  | PsVerifiedIrIntrinsic.arraySet => psJsonArray [psJsonQuote "arraySet"]
  | PsVerifiedIrIntrinsic.arraySetIfInBounds => psJsonArray [psJsonQuote "arraySetIfInBounds"]
  | PsVerifiedIrIntrinsic.arrayMap => psJsonArray [psJsonQuote "arrayMap"]
  | PsVerifiedIrIntrinsic.arrayFoldl => psJsonArray [psJsonQuote "arrayFoldl"]

def psIrEncodeLiteral (value : PsVerifiedIrLiteral) : String :=
  match value with
  | PsVerifiedIrLiteral.natural number =>
      psJsonArray [psJsonQuote "natural", psJsonQuote (psNatToString number)]
  | PsVerifiedIrLiteral.integer number =>
      psJsonArray [psJsonQuote "integer", psJsonQuote (Int.repr number)]
  | PsVerifiedIrLiteral.machineInteger type number =>
      psJsonArray [psJsonQuote "machineInteger", psIrEncodeMachineIntegerType type,
        psJsonQuote (Int.repr number)]
  | PsVerifiedIrLiteral.string text => psJsonArray [psJsonQuote "string", psJsonQuote text]
  | PsVerifiedIrLiteral.bool flag =>
      psJsonArray [psJsonQuote "bool", if flag then "true" else "false"]
  | PsVerifiedIrLiteral.unit => psJsonArray [psJsonQuote "unit"]

def psIrEncodeArray {alpha : Type}
    (encode : alpha -> Except PsIrEncodeError String) (values : List alpha) :
    Except PsIrEncodeError String :=
  match psListMapExcept encode values with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

def psIrEncodeTypeWithFuelWorker (fuel : Nat) (type : PsVerifiedIrType) :
    Except PsIrEncodeError String :=
  match fuel with
  | Nat.zero => Except.error PsIrEncodeError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Except PsIrEncodeError String :=
        fun (value : PsVerifiedIrType) => psIrEncodeTypeWithFuelWorker remaining value;
      match type with
      | PsVerifiedIrType.unknown => Except.ok (psJsonArray [psJsonQuote "unknown"])
      | PsVerifiedIrType.typeParameter name =>
          Except.ok (psJsonArray [psJsonQuote "typeParameter", psJsonQuote name])
      | PsVerifiedIrType.primitive name =>
          Except.ok (psJsonArray [psJsonQuote "primitive", psIrEncodePrimitiveType name])
      | PsVerifiedIrType.function parameters result =>
          match psIrEncodeArray smaller parameters with
          | Except.error error => Except.error error
          | Except.ok encodedParameters =>
              match smaller result with
              | Except.error error => Except.error error
              | Except.ok encodedResult =>
                  Except.ok (psJsonArray [psJsonQuote "function", encodedParameters, encodedResult])
      | PsVerifiedIrType.named name arguments =>
          match psIrEncodeArray smaller arguments with
          | Except.error error => Except.error error
          | Except.ok encoded =>
              Except.ok (psJsonArray [psJsonQuote "named", psJsonQuote name, encoded])

def psIrEncodeTypeWithFuel (fuel : Nat) :
    PsVerifiedIrType -> Except PsIrEncodeError String :=
  fun (value : PsVerifiedIrType) => psIrEncodeTypeWithFuelWorker fuel value

def psIrEncodeType (type : PsVerifiedIrType) : Except PsIrEncodeError String :=
  psIrEncodeTypeWithFuel 4096 type

def psIrEncodeParameter (value : PsVerifiedIrParameter) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray [psJsonQuote value.name, encoded])

def psIrEncodeMatchBinding (value : PsVerifiedIrMatchBinding) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded =>
      Except.ok (psJsonArray [psJsonQuote value.field, psJsonQuote value.name, encoded])

def psIrEncodeExprWithFuelWorker (fuel : Nat) (expression : PsVerifiedIrExpr) :
    Except PsIrEncodeError String :=
  match fuel with
  | Nat.zero => Except.error PsIrEncodeError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Except PsIrEncodeError String :=
        fun (value : PsVerifiedIrExpr) => psIrEncodeExprWithFuelWorker remaining value;
      let encodeField : Prod String PsVerifiedIrExpr -> Except PsIrEncodeError String :=
        fun (field : Prod String PsVerifiedIrExpr) =>
          match smaller field.snd with
          | Except.error error => Except.error error
          | Except.ok encoded => Except.ok (psJsonArray [psJsonQuote field.fst, encoded]);
      match expression with
      | PsVerifiedIrExpr.literal value =>
          Except.ok (psJsonArray [psJsonQuote "literal", psIrEncodeLiteral value])
      | PsVerifiedIrExpr.var name =>
          Except.ok (psJsonArray [psJsonQuote "var", psJsonQuote name])
      | PsVerifiedIrExpr.intrinsic operation types arguments =>
          match psIrEncodeArray psIrEncodeType types with
          | Except.error error => Except.error error
          | Except.ok encodedTypes =>
              match psIrEncodeArray smaller arguments with
              | Except.error error => Except.error error
              | Except.ok encodedArguments =>
                  Except.ok (psJsonArray [psJsonQuote "intrinsic", psIrEncodeIntrinsic operation,
                    encodedTypes, encodedArguments])
      | PsVerifiedIrExpr.lambda parameters result body =>
          match psIrEncodeArray psIrEncodeParameter parameters with
          | Except.error error => Except.error error
          | Except.ok encodedParameters =>
              match psIrEncodeType result with
              | Except.error error => Except.error error
              | Except.ok encodedResult =>
                  match smaller body with
                  | Except.error error => Except.error error
                  | Except.ok encodedBody =>
                      Except.ok (psJsonArray [psJsonQuote "lambda", encodedParameters,
                        encodedResult, encodedBody])
      | PsVerifiedIrExpr.call fn types arguments =>
          match smaller fn with
          | Except.error error => Except.error error
          | Except.ok encodedFn =>
              match psIrEncodeArray psIrEncodeType types with
              | Except.error error => Except.error error
              | Except.ok encodedTypes =>
                  match psIrEncodeArray smaller arguments with
                  | Except.error error => Except.error error
                  | Except.ok encodedArguments =>
                      Except.ok (psJsonArray [psJsonQuote "call", encodedFn, encodedTypes,
                        encodedArguments])
      | PsVerifiedIrExpr.letE name type value body =>
          match psIrEncodeType type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              match smaller value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  match smaller body with
                  | Except.error error => Except.error error
                  | Except.ok encodedBody =>
                      Except.ok (psJsonArray [psJsonQuote "letE", psJsonQuote name,
                        encodedType, encodedValue, encodedBody])
      | PsVerifiedIrExpr.ifE condition yes no =>
          match smaller condition with
          | Except.error error => Except.error error
          | Except.ok encodedCondition =>
              match smaller yes with
              | Except.error error => Except.error error
              | Except.ok encodedYes =>
                  match smaller no with
                  | Except.error error => Except.error error
                  | Except.ok encodedNo =>
                      Except.ok (psJsonArray [psJsonQuote "ifE", encodedCondition,
                        encodedYes, encodedNo])
      | PsVerifiedIrExpr.record name types fields =>
          match psIrEncodeArray psIrEncodeType types with
          | Except.error error => Except.error error
          | Except.ok encodedTypes =>
              match psIrEncodeArray encodeField fields with
              | Except.error error => Except.error error
              | Except.ok encodedFields =>
                  Except.ok (psJsonArray [psJsonQuote "record", psJsonQuote name,
                    encodedTypes, encodedFields])
      | PsVerifiedIrExpr.projection name types value field =>
          match psIrEncodeArray psIrEncodeType types with
          | Except.error error => Except.error error
          | Except.ok encodedTypes =>
              match smaller value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  Except.ok (psJsonArray [psJsonQuote "projection", psJsonQuote name,
                    encodedTypes, encodedValue, psJsonQuote field])
      | PsVerifiedIrExpr.constructor owner name types fields =>
          match psIrEncodeArray psIrEncodeType types with
          | Except.error error => Except.error error
          | Except.ok encodedTypes =>
              match psIrEncodeArray encodeField fields with
              | Except.error error => Except.error error
              | Except.ok encodedFields =>
                  Except.ok (psJsonArray [psJsonQuote "constructor", psJsonQuote owner,
                    psJsonQuote name, encodedTypes, encodedFields])
      | PsVerifiedIrExpr.matchE name types value alternatives =>
          match psIrEncodeArray psIrEncodeType types with
          | Except.error error => Except.error error
          | Except.ok encodedTypes =>
              match smaller value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  match psIrEncodeArray
                      (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
                        match psIrEncodeArray psIrEncodeMatchBinding alternative.snd.fst with
                        | Except.error error => Except.error error
                        | Except.ok encodedBindings =>
                            match smaller alternative.snd.snd with
                            | Except.error error => Except.error error
                            | Except.ok encodedBody =>
                                Except.ok (psJsonArray [psJsonQuote alternative.fst,
                                  encodedBindings, encodedBody]))
                      alternatives with
                  | Except.error error => Except.error error
                  | Except.ok encodedAlternatives =>
                      Except.ok (psJsonArray [psJsonQuote "matchE", psJsonQuote name,
                        encodedTypes, encodedValue, encodedAlternatives])

def psIrEncodeExprWithFuel (fuel : Nat) :
    PsVerifiedIrExpr -> Except PsIrEncodeError String :=
  fun (value : PsVerifiedIrExpr) => psIrEncodeExprWithFuelWorker fuel value

def psIrEncodeExpr (expression : PsVerifiedIrExpr) : Except PsIrEncodeError String :=
  psIrEncodeExprWithFuel 4096 expression

def psIrEncodeTypeParameters (values : List PsVerifiedIrTypeParameter) : String :=
  psJsonArray (psListMap (fun (value : PsVerifiedIrTypeParameter) => psJsonQuote value.name) values)

def psIrEncodeStructureField (value : PsVerifiedIrStructureField) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray [psJsonQuote value.name, encoded])

def psIrEncodeStructure (value : PsVerifiedIrStructure) : Except PsIrEncodeError String :=
  match psIrEncodeArray psIrEncodeStructureField value.fields with
  | Except.error error => Except.error error
  | Except.ok fields =>
      Except.ok (psJsonArray [psJsonQuote value.name,
        psIrEncodeTypeParameters value.typeParameters, fields])

def psIrEncodeConstructorField (value : PsVerifiedIrConstructorField) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray [psJsonQuote value.name, encoded])

def psIrEncodeConstructor (value : PsVerifiedIrConstructor) : Except PsIrEncodeError String :=
  match psIrEncodeArray psIrEncodeConstructorField value.fields with
  | Except.error error => Except.error error
  | Except.ok fields => Except.ok (psJsonArray [psJsonQuote value.name, fields])

def psIrEncodeInductive (value : PsVerifiedIrInductive) : Except PsIrEncodeError String :=
  match psIrEncodeArray psIrEncodeConstructor value.constructors with
  | Except.error error => Except.error error
  | Except.ok constructors =>
      Except.ok (psJsonArray [psJsonQuote value.name,
        psIrEncodeTypeParameters value.typeParameters, constructors])

def psIrEncodeDeclaration (value : PsVerifiedIrDeclaration) : Except PsIrEncodeError String :=
  match psIrEncodeArray psIrEncodeParameter value.parameters with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psIrEncodeType value.resultType with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psIrEncodeExpr value.body with
          | Except.error error => Except.error error
          | Except.ok body =>
              Except.ok (psJsonArray [psJsonQuote value.name,
                psIrEncodeTypeParameters value.typeParameters, parameters, result, body])

def psIrEncodeImport (value : PsVerifiedIrExternalImport) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded =>
      Except.ok (psJsonArray [psJsonQuote value.localName, psJsonQuote value.source,
        psJsonQuote value.importedName, encoded])

def psIrEncodeModule (value : PsVerifiedIrModule) : Except PsIrEncodeError String :=
  match psIrEncodeArray psIrEncodeImport value.imports with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match psIrEncodeArray psIrEncodeStructure value.structures with
      | Except.error error => Except.error error
      | Except.ok structures =>
          match psIrEncodeArray psIrEncodeInductive value.inductives with
          | Except.error error => Except.error error
          | Except.ok inductives =>
              match psIrEncodeArray psIrEncodeDeclaration value.declarations with
              | Except.error error => Except.error error
              | Except.ok declarations =>
                  Except.ok (psJsonArray [psJsonQuote "psc1-ir/1", imports,
                    structures, inductives, declarations])
