import Ps.BackendJs.Model
import Ps.Bridge.Json
import Ps.Foundation.List
import Ps.Foundation.Name

inductive PsJsLowerError where
  | fuelExhausted
  | importsUnsupported
  | structuresUnsupported
  | inductivesUnsupported
  | genericDeclarationUnsupported (name : String)
  | unsupportedType
  | unsupportedLiteral
  | unsupportedExpression
  | unsupportedIntrinsic
  | intrinsicArity
  | typeArgumentsUnsupported
  | unsupportedName (name : String)

def psJsNatInRange
    (value lower upper : Nat) : Bool :=
  if Nat.ble lower value then
    Nat.ble value upper
  else
    false

def psJsIdentifierFirstCharAllowed
    (char : Char) : Bool :=
  let value : Nat := Char.toNat char;
  if psJsNatInRange value 65 90 then
    true
  else if psJsNatInRange value 97 122 then
    true
  else if Nat.beq value 95 then
    true
  else
    Nat.beq value 36

def psJsIdentifierRestCharAllowed
    (char : Char) : Bool :=
  let value : Nat := Char.toNat char;
  if psJsIdentifierFirstCharAllowed char then
    true
  else
    psJsNatInRange value 48 57

def psJsIdentifierRestSupported
    (chars : List Char) : Bool :=
  match chars with
  | List.nil => true
  | List.cons char rest =>
      if psJsIdentifierRestCharAllowed char then
        psJsIdentifierRestSupported rest
      else
        false

def psJsIdentifierKeyword
    (value : String) : Bool :=
  if psStringEq value "arguments" then true
  else if psStringEq value "await" then true
  else if psStringEq value "break" then true
  else if psStringEq value "case" then true
  else if psStringEq value "catch" then true
  else if psStringEq value "class" then true
  else if psStringEq value "const" then true
  else if psStringEq value "continue" then true
  else if psStringEq value "debugger" then true
  else if psStringEq value "default" then true
  else if psStringEq value "delete" then true
  else if psStringEq value "do" then true
  else if psStringEq value "else" then true
  else if psStringEq value "enum" then true
  else if psStringEq value "export" then true
  else if psStringEq value "eval" then true
  else if psStringEq value "extends" then true
  else if psStringEq value "false" then true
  else if psStringEq value "finally" then true
  else if psStringEq value "for" then true
  else if psStringEq value "function" then true
  else if psStringEq value "if" then true
  else if psStringEq value "implements" then true
  else if psStringEq value "import" then true
  else if psStringEq value "in" then true
  else if psStringEq value "interface" then true
  else if psStringEq value "instanceof" then true
  else if psStringEq value "let" then true
  else if psStringEq value "new" then true
  else if psStringEq value "null" then true
  else if psStringEq value "package" then true
  else if psStringEq value "private" then true
  else if psStringEq value "protected" then true
  else if psStringEq value "public" then true
  else if psStringEq value "return" then true
  else if psStringEq value "static" then true
  else if psStringEq value "super" then true
  else if psStringEq value "switch" then true
  else if psStringEq value "this" then true
  else if psStringEq value "throw" then true
  else if psStringEq value "true" then true
  else if psStringEq value "try" then true
  else if psStringEq value "typeof" then true
  else if psStringEq value "var" then true
  else if psStringEq value "void" then true
  else if psStringEq value "while" then true
  else if psStringEq value "with" then true
  else
    psStringEq value "yield"

def psJsIdentifierSupported
    (value : String) : Bool :=
  match psJsonStringToChars value with
  | List.nil => false
  | List.cons first rest =>
      if psJsIdentifierFirstCharAllowed first then
        if psJsIdentifierRestSupported rest then
          if psJsIdentifierKeyword value then
            false
          else
            true
        else
          false
      else
        false

def psJsPrimitiveTypeSupported
    (type : PsVerifiedIrPrimitiveType) : Bool :=
  match type with
  | PsVerifiedIrPrimitiveType.nat => true
  | PsVerifiedIrPrimitiveType.int => true
  | PsVerifiedIrPrimitiveType.uint8 => true
  | PsVerifiedIrPrimitiveType.uint16 => true
  | PsVerifiedIrPrimitiveType.uint32 => true
  | PsVerifiedIrPrimitiveType.uint64 => true
  | PsVerifiedIrPrimitiveType.int8 => true
  | PsVerifiedIrPrimitiveType.int16 => true
  | PsVerifiedIrPrimitiveType.int32 => true
  | PsVerifiedIrPrimitiveType.int64 => true
  | PsVerifiedIrPrimitiveType.float => true
  | PsVerifiedIrPrimitiveType.float32 => true
  | PsVerifiedIrPrimitiveType.bool => true
  | PsVerifiedIrPrimitiveType.char => true
  | PsVerifiedIrPrimitiveType.string => true
  | PsVerifiedIrPrimitiveType.unit => true
  | _ => false

def psJsTypeSupportedWithFuel
    (fuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_type : PsVerifiedIrType) => false
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Bool :=
        psJsTypeSupportedWithFuel remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.primitive primitive =>
            psJsPrimitiveTypeSupported primitive
        | PsVerifiedIrType.function parameters result =>
            if psVerifiedIrListAll smaller parameters then
              smaller result
            else
              false
        | _ => false

def psJsTypeSupported
    (type : PsVerifiedIrType) : Bool :=
  psJsTypeSupportedWithFuel 64 type

def psJsLowerMachineIntegerType
    (type : PsVerifiedIrMachineIntegerType) :
    Except PsJsLowerError PsJsIrMachineIntegerType :=
  match type with
  | PsVerifiedIrMachineIntegerType.uint8 =>
      Except.ok PsJsIrMachineIntegerType.uint8
  | PsVerifiedIrMachineIntegerType.uint16 =>
      Except.ok PsJsIrMachineIntegerType.uint16
  | PsVerifiedIrMachineIntegerType.uint32 =>
      Except.ok PsJsIrMachineIntegerType.uint32
  | PsVerifiedIrMachineIntegerType.uint64 =>
      Except.ok PsJsIrMachineIntegerType.uint64
  | PsVerifiedIrMachineIntegerType.int8 =>
      Except.ok PsJsIrMachineIntegerType.int8
  | PsVerifiedIrMachineIntegerType.int16 =>
      Except.ok PsJsIrMachineIntegerType.int16
  | PsVerifiedIrMachineIntegerType.int32 =>
      Except.ok PsJsIrMachineIntegerType.int32
  | PsVerifiedIrMachineIntegerType.int64 =>
      Except.ok PsJsIrMachineIntegerType.int64
  | PsVerifiedIrMachineIntegerType.usize =>
      Except.error PsJsLowerError.unsupportedType
  | PsVerifiedIrMachineIntegerType.isize =>
      Except.error PsJsLowerError.unsupportedType

def psJsLowerIntegerBinaryOp
    (operation : PsVerifiedIrIntegerBinaryOp) :
    PsJsIrIntegerBinaryOp :=
  match operation with
  | PsVerifiedIrIntegerBinaryOp.add => PsJsIrIntegerBinaryOp.add
  | PsVerifiedIrIntegerBinaryOp.sub => PsJsIrIntegerBinaryOp.sub
  | PsVerifiedIrIntegerBinaryOp.mul => PsJsIrIntegerBinaryOp.mul
  | PsVerifiedIrIntegerBinaryOp.bitAnd => PsJsIrIntegerBinaryOp.bitAnd
  | PsVerifiedIrIntegerBinaryOp.bitOr => PsJsIrIntegerBinaryOp.bitOr
  | PsVerifiedIrIntegerBinaryOp.bitXor => PsJsIrIntegerBinaryOp.bitXor

def psJsLowerIntegerCompareOp
    (operation : PsVerifiedIrIntegerCompareOp) :
    PsJsIrIntegerCompareOp :=
  match operation with
  | PsVerifiedIrIntegerCompareOp.eq => PsJsIrIntegerCompareOp.eq
  | PsVerifiedIrIntegerCompareOp.ne => PsJsIrIntegerCompareOp.ne
  | PsVerifiedIrIntegerCompareOp.lt => PsJsIrIntegerCompareOp.lt
  | PsVerifiedIrIntegerCompareOp.le => PsJsIrIntegerCompareOp.le
  | PsVerifiedIrIntegerCompareOp.gt => PsJsIrIntegerCompareOp.gt
  | PsVerifiedIrIntegerCompareOp.ge => PsJsIrIntegerCompareOp.ge

def psJsLowerFloatingType
    (type : PsVerifiedIrFloatingType) :
    PsJsIrFloatingType :=
  match type with
  | PsVerifiedIrFloatingType.float => PsJsIrFloatingType.float
  | PsVerifiedIrFloatingType.float32 => PsJsIrFloatingType.float32

def psJsLowerFloatBinaryOp
    (operation : PsVerifiedIrFloatBinaryOp) :
    PsJsIrFloatBinaryOp :=
  match operation with
  | PsVerifiedIrFloatBinaryOp.add => PsJsIrFloatBinaryOp.add
  | PsVerifiedIrFloatBinaryOp.sub => PsJsIrFloatBinaryOp.sub
  | PsVerifiedIrFloatBinaryOp.mul => PsJsIrFloatBinaryOp.mul
  | PsVerifiedIrFloatBinaryOp.div => PsJsIrFloatBinaryOp.div

def psJsLowerFloatCompareOp
    (operation : PsVerifiedIrFloatCompareOp) :
    PsJsIrFloatCompareOp :=
  match operation with
  | PsVerifiedIrFloatCompareOp.eq => PsJsIrFloatCompareOp.eq
  | PsVerifiedIrFloatCompareOp.ne => PsJsIrFloatCompareOp.ne
  | PsVerifiedIrFloatCompareOp.lt => PsJsIrFloatCompareOp.lt
  | PsVerifiedIrFloatCompareOp.le => PsJsIrFloatCompareOp.le
  | PsVerifiedIrFloatCompareOp.gt => PsJsIrFloatCompareOp.gt
  | PsVerifiedIrFloatCompareOp.ge => PsJsIrFloatCompareOp.ge

def psJsLowerLiteral
    (literal : PsVerifiedIrLiteral) :
    Except PsJsLowerError PsJsIrLiteral :=
  match literal with
  | PsVerifiedIrLiteral.natural value =>
      Except.ok (PsJsIrLiteral.natural value)
  | PsVerifiedIrLiteral.integer value =>
      Except.ok (PsJsIrLiteral.integer value)
  | PsVerifiedIrLiteral.string value =>
      Except.ok (PsJsIrLiteral.string value)
  | PsVerifiedIrLiteral.bool value =>
      Except.ok (PsJsIrLiteral.bool value)
  | PsVerifiedIrLiteral.unit =>
      Except.ok PsJsIrLiteral.unit
  | PsVerifiedIrLiteral.machineInteger type value =>
      match psJsLowerMachineIntegerType type with
      | Except.error error => Except.error error
      | Except.ok loweredType =>
          Except.ok
            (PsJsIrLiteral.machineInteger
              loweredType
              value)

def psJsLowerParameterNames
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      if psJsIdentifierSupported parameter.name then
        if psJsTypeSupported parameter.type then
          match psJsLowerParameterNames rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons parameter.name loweredRest)
        else
          Except.error PsJsLowerError.unsupportedType
      else
        Except.error
          (PsJsLowerError.unsupportedName parameter.name)

def psJsLowerUnaryWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (operation : PsJsIrUnaryOp)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  match arguments with
  | List.nil =>
      Except.error PsJsLowerError.intrinsicArity
  | List.cons value rest =>
      match rest with
      | List.nil =>
          match lower value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok (PsJsIrExpr.unary operation lowered)
      | List.cons _ _ =>
          Except.error PsJsLowerError.intrinsicArity

def psJsLowerBinaryWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (operation : PsJsIrBinaryOp)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  match arguments with
  | List.nil =>
      Except.error PsJsLowerError.intrinsicArity
  | List.cons left rest =>
      match rest with
      | List.nil =>
          Except.error PsJsLowerError.intrinsicArity
      | List.cons right tail =>
          match tail with
          | List.nil =>
              match lower left with
              | Except.error error => Except.error error
              | Except.ok loweredLeft =>
                  match lower right with
                  | Except.error error => Except.error error
                  | Except.ok loweredRight =>
                      Except.ok
                        (PsJsIrExpr.binary
                          operation
                          loweredLeft
                          loweredRight)
          | List.cons _ _ =>
              Except.error PsJsLowerError.intrinsicArity

def psJsLowerRuntimeUnaryWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (operation : PsJsIrRuntimeOp)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  match arguments with
  | List.nil =>
      Except.error PsJsLowerError.intrinsicArity
  | List.cons value rest =>
      match rest with
      | List.nil =>
          match lower value with
          | Except.error error => Except.error error
          | Except.ok lowered =>
              Except.ok
                (PsJsIrExpr.runtime
                  operation
                  (List.cons lowered List.nil))
      | List.cons _ _ =>
          Except.error PsJsLowerError.intrinsicArity

def psJsLowerRuntimeBinaryWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (operation : PsJsIrRuntimeOp)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  match arguments with
  | List.nil =>
      Except.error PsJsLowerError.intrinsicArity
  | List.cons left rest =>
      match rest with
      | List.nil =>
          Except.error PsJsLowerError.intrinsicArity
      | List.cons right tail =>
          match tail with
          | List.nil =>
              match lower left with
              | Except.error error => Except.error error
              | Except.ok loweredLeft =>
                  match lower right with
                  | Except.error error => Except.error error
                  | Except.ok loweredRight =>
                      Except.ok
                        (PsJsIrExpr.runtime
                          operation
                          [
                            loweredLeft,
                            loweredRight
                          ])
          | List.cons _ _ =>
              Except.error PsJsLowerError.intrinsicArity

def psJsLowerIdentityWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  match arguments with
  | List.cons value rest =>
      match rest with
      | List.nil => lower value
      | List.cons _ _ =>
          Except.error PsJsLowerError.intrinsicArity
  | List.nil =>
      Except.error PsJsLowerError.intrinsicArity

def psJsLowerExprWithFuel
    (fuel : Nat) :
    PsVerifiedIrExpr ->
      Except PsJsLowerError PsJsIrExpr :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsVerifiedIrExpr) =>
        Except.error PsJsLowerError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsVerifiedIrExpr ->
            Except PsJsLowerError PsJsIrExpr :=
        psJsLowerExprWithFuel remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.literal literal =>
            match psJsLowerLiteral literal with
            | Except.error error => Except.error error
            | Except.ok value =>
                Except.ok (PsJsIrExpr.literal value)
        | PsVerifiedIrExpr.var name =>
            if psJsIdentifierSupported name then
              Except.ok (PsJsIrExpr.var name)
            else
              Except.error (PsJsLowerError.unsupportedName name)
        | PsVerifiedIrExpr.intrinsic
            operation
            typeArguments
            arguments =>
            if psListIsEmpty typeArguments then
              match operation with
              | PsVerifiedIrIntrinsic.machineIntBinary type integerOperation =>
                  match psJsLowerMachineIntegerType type with
                  | Except.error error => Except.error error
                  | Except.ok loweredType =>
                      psJsLowerBinaryWith
                        smaller
                        (PsJsIrBinaryOp.machineInt
                          loweredType
                          (psJsLowerIntegerBinaryOp integerOperation))
                        arguments
              | PsVerifiedIrIntrinsic.machineIntCompare type integerOperation =>
                  match psJsLowerMachineIntegerType type with
                  | Except.error error => Except.error error
                  | Except.ok _ =>
                      psJsLowerBinaryWith
                        smaller
                        (PsJsIrBinaryOp.machineIntCompare
                          (psJsLowerIntegerCompareOp integerOperation))
                        arguments
              | PsVerifiedIrIntrinsic.uint8OfNat =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.uint8OfNat arguments
              | PsVerifiedIrIntrinsic.floatBinary type floatOperation =>
                  psJsLowerBinaryWith
                    smaller
                    (PsJsIrBinaryOp.floatBinary
                      (psJsLowerFloatingType type)
                      (psJsLowerFloatBinaryOp floatOperation))
                    arguments
              | PsVerifiedIrIntrinsic.floatCompare _ floatOperation =>
                  psJsLowerBinaryWith
                    smaller
                    (PsJsIrBinaryOp.floatCompare
                      (psJsLowerFloatCompareOp floatOperation))
                    arguments
              | PsVerifiedIrIntrinsic.natAdd =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintAdd arguments
              | PsVerifiedIrIntrinsic.natSub =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.natSub arguments
              | PsVerifiedIrIntrinsic.natMul =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintMul arguments
              | PsVerifiedIrIntrinsic.natDiv =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.natDiv arguments
              | PsVerifiedIrIntrinsic.natMod =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.natMod arguments
              | PsVerifiedIrIntrinsic.natEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintEq arguments
              | PsVerifiedIrIntrinsic.natNe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintNe arguments
              | PsVerifiedIrIntrinsic.natLe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLe arguments
              | PsVerifiedIrIntrinsic.natLt =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLt arguments
              | PsVerifiedIrIntrinsic.intOfNat =>
                  psJsLowerIdentityWith smaller arguments
              | PsVerifiedIrIntrinsic.intRepr =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.intRepr arguments
              | PsVerifiedIrIntrinsic.intNegSucc =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.intNegSucc arguments
              | PsVerifiedIrIntrinsic.intNeg =>
                  psJsLowerUnaryWith
                    smaller PsJsIrUnaryOp.bigintNeg arguments
              | PsVerifiedIrIntrinsic.intAdd =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintAdd arguments
              | PsVerifiedIrIntrinsic.intSub =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintSub arguments
              | PsVerifiedIrIntrinsic.intMul =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintMul arguments
              | PsVerifiedIrIntrinsic.intEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintEq arguments
              | PsVerifiedIrIntrinsic.intLe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLe arguments
              | PsVerifiedIrIntrinsic.intLt =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.bigintLt arguments
              | PsVerifiedIrIntrinsic.boolNot =>
                  psJsLowerUnaryWith
                    smaller PsJsIrUnaryOp.boolNot arguments
              | PsVerifiedIrIntrinsic.boolAnd =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolAnd arguments
              | PsVerifiedIrIntrinsic.boolOr =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolOr arguments
              | PsVerifiedIrIntrinsic.boolEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolEq arguments
              | PsVerifiedIrIntrinsic.boolNe =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.boolNe arguments
              | PsVerifiedIrIntrinsic.charOfNat =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.charOfNat arguments
              | PsVerifiedIrIntrinsic.charToNat =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.charToNat arguments
              | PsVerifiedIrIntrinsic.stringPush =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringConcat arguments
              | PsVerifiedIrIntrinsic.stringSingleton =>
                  psJsLowerIdentityWith smaller arguments
              | PsVerifiedIrIntrinsic.stringLength =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.stringLength arguments
              | PsVerifiedIrIntrinsic.stringAppend =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringConcat arguments
              | PsVerifiedIrIntrinsic.stringEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringEq arguments
              | _ =>
                  Except.error PsJsLowerError.unsupportedIntrinsic
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.lambda
            parameters
            resultType
            body =>
            if psJsTypeSupported resultType then
              match psJsLowerParameterNames parameters with
              | Except.error error => Except.error error
              | Except.ok names =>
                  match smaller body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      Except.ok
                        (PsJsIrExpr.lambda
                          names
                          loweredBody)
            else
              Except.error PsJsLowerError.unsupportedType
        | PsVerifiedIrExpr.call fn typeArguments arguments =>
            if psListIsEmpty typeArguments then
              match smaller fn with
              | Except.error error => Except.error error
              | Except.ok loweredFn =>
                  match psListMapExcept smaller arguments with
                  | Except.error error => Except.error error
                  | Except.ok loweredArguments =>
                      Except.ok
                        (PsJsIrExpr.call
                          loweredFn
                          loweredArguments)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.letE
            name
            type
            value
            body =>
            if psJsIdentifierSupported name then
              if psJsTypeSupported type then
                match smaller value with
                | Except.error error => Except.error error
                | Except.ok loweredValue =>
                    match smaller body with
                    | Except.error error => Except.error error
                    | Except.ok loweredBody =>
                        Except.ok
                          (PsJsIrExpr.letE
                            name
                            loweredValue
                            loweredBody)
              else
                Except.error PsJsLowerError.unsupportedType
            else
              Except.error
                (PsJsLowerError.unsupportedName name)
        | PsVerifiedIrExpr.ifE
            condition
            thenBranch
            elseBranch =>
            match smaller condition with
            | Except.error error => Except.error error
            | Except.ok loweredCondition =>
                match smaller thenBranch with
                | Except.error error => Except.error error
                | Except.ok loweredThen =>
                    match smaller elseBranch with
                    | Except.error error => Except.error error
                    | Except.ok loweredElse =>
                        Except.ok
                          (PsJsIrExpr.ifE
                            loweredCondition
                            loweredThen
                            loweredElse)
        | _ =>
            Except.error PsJsLowerError.unsupportedExpression

def psJsLowerExpr
    (expr : PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  psJsLowerExprWithFuel 4096 expr

def psJsLowerParameters
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List PsJsIrParameter) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      if psJsIdentifierSupported parameter.name then
        if psJsTypeSupported parameter.type then
          match psJsLowerParameters rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (List.cons
                  (PsJsIrParameter.mk parameter.name)
                  loweredRest)
        else
          Except.error PsJsLowerError.unsupportedType
      else
        Except.error
          (PsJsLowerError.unsupportedName parameter.name)

def psJsLowerDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    Except PsJsLowerError PsJsIrDeclaration :=
  if psJsIdentifierSupported declaration.name then
    if psListIsEmpty declaration.typeParameters then
      if psJsTypeSupported declaration.resultType then
        match psJsLowerParameters declaration.parameters with
        | Except.error error => Except.error error
        | Except.ok parameters =>
            match psJsLowerExpr declaration.body with
            | Except.error error => Except.error error
            | Except.ok body =>
                Except.ok
                  (PsJsIrDeclaration.mk
                    declaration.name
                    parameters
                    body)
      else
        Except.error PsJsLowerError.unsupportedType
    else
      Except.error
        (PsJsLowerError.genericDeclarationUnsupported
          declaration.name)
  else
    Except.error
      (PsJsLowerError.unsupportedName declaration.name)

def psJsLowerDeclarations
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsJsLowerError (List PsJsIrDeclaration) :=
  match declarations with
  | List.nil =>
      Except.ok List.nil
  | List.cons declaration rest =>
      match psJsLowerDeclaration declaration with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match psJsLowerDeclarations rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

def psJsLowerValidatedModule
    (validated : PsValidatedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  let module := validated.raw;
  if psListIsEmpty module.imports then
    if psListIsEmpty module.structures then
      if psListIsEmpty module.inductives then
        match psJsLowerDeclarations module.declarations with
        | Except.error error => Except.error error
        | Except.ok declarations =>
            Except.ok (PsJsIrModule.mk declarations)
      else
        Except.error PsJsLowerError.inductivesUnsupported
    else
      Except.error PsJsLowerError.structuresUnsupported
  else
    Except.error PsJsLowerError.importsUnsupported
