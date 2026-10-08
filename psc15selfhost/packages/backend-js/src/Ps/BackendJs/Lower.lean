import Ps.BackendJs.Model
import Ps.CompilerIr.Specialize
import Ps.Bridge.Json
import Ps.Foundation.List
import Ps.Foundation.Name

inductive PsJsLowerError where
  | fuelExhausted
  | importsUnsupported
  | structuresUnsupported
  | inductivesUnsupported
  | specializationFailed (error : PsIrSpecializeError)
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
  if psStringEq value "__ps$utf8" then true
  else if psStringEq value "__ps$utf8Cache" then true
  else if psStringEq value "arguments" then true
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

def psJsImportNameSupported
    (value : String) : Bool :=
  match psJsonStringToChars value with
  | List.nil => false
  | List.cons first rest =>
      if psJsIdentifierFirstCharAllowed first then
        psJsIdentifierRestSupported rest
      else
        false

def psJsProfileHasWordSize
    (profile : Option PsJsTargetProfile) : Bool :=
  match profile with
  | Option.none => false
  | Option.some _ => true

def psJsPrimitiveTypeSupportedWithProfile
    (profile : Option PsJsTargetProfile)
    (type : PsVerifiedIrPrimitiveType) : Bool :=
  match type with
  | PsVerifiedIrPrimitiveType.nat => true
  | PsVerifiedIrPrimitiveType.int => true
  | PsVerifiedIrPrimitiveType.uint8 => true
  | PsVerifiedIrPrimitiveType.uint16 => true
  | PsVerifiedIrPrimitiveType.uint32 => true
  | PsVerifiedIrPrimitiveType.uint64 => true
  | PsVerifiedIrPrimitiveType.usize =>
      psJsProfileHasWordSize profile
  | PsVerifiedIrPrimitiveType.int8 => true
  | PsVerifiedIrPrimitiveType.int16 => true
  | PsVerifiedIrPrimitiveType.int32 => true
  | PsVerifiedIrPrimitiveType.int64 => true
  | PsVerifiedIrPrimitiveType.isize =>
      psJsProfileHasWordSize profile
  | PsVerifiedIrPrimitiveType.float => true
  | PsVerifiedIrPrimitiveType.float32 => true
  | PsVerifiedIrPrimitiveType.bool => true
  | PsVerifiedIrPrimitiveType.char => true
  | PsVerifiedIrPrimitiveType.string => true
  | PsVerifiedIrPrimitiveType.unit => true

def psJsPrimitiveTypeSupported
    (type : PsVerifiedIrPrimitiveType) : Bool :=
  psJsPrimitiveTypeSupportedWithProfile Option.none type

def psJsTypeSupportedWithPolicyAndFuel
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (fuel : Nat) :
    PsVerifiedIrType -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_type : PsVerifiedIrType) => false
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Bool :=
        psJsTypeSupportedWithPolicyAndFuel
          profile uniform
          remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.primitive primitive =>
            psJsPrimitiveTypeSupportedWithProfile
              profile
              primitive
        | PsVerifiedIrType.function parameters result =>
            if psVerifiedIrListAll smaller parameters then
              smaller result
            else
              false
        | PsVerifiedIrType.named name arguments =>
            if psStringEq name "Array" then
              match arguments with
              | List.nil => false
              | List.cons elementType rest =>
                  match rest with
                  | List.nil => smaller elementType
                  | List.cons _ _ => false
            else
              if uniform then psVerifiedIrListAll smaller arguments
              else psListIsEmpty arguments
        | PsVerifiedIrType.typeParameter _ => uniform
        | _ => false

-- Existing callers keep the closed specialization contract.
def psJsTypeSupportedWithProfileAndFuel
    (profile : Option PsJsTargetProfile)
    (fuel : Nat) :
    PsVerifiedIrType -> Bool :=
  psJsTypeSupportedWithPolicyAndFuel profile false fuel

def psJsTypeSupportedWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (type : PsVerifiedIrType) : Bool :=
  psJsTypeSupportedWithPolicyAndFuel
    profile uniform
    64
    type

-- Existing callers keep the closed specialization contract.
def psJsTypeSupportedWithProfile
    (profile : Option PsJsTargetProfile)
    (type : PsVerifiedIrType) : Bool :=
  psJsTypeSupportedWithPolicy profile false type

def psJsTypeSupported
    (type : PsVerifiedIrType) : Bool :=
  psJsTypeSupportedWithProfile Option.none type

-- Uniform lowering erases only statically checked type arguments. The strict
-- wrapper still requires no arguments after closed monomorphization.
def psJsErasedTypeArgumentsSupported
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (arguments : List PsVerifiedIrType) : Bool :=
  if uniform then
    let supported : PsVerifiedIrType -> Bool :=
      psJsTypeSupportedWithPolicy profile uniform;
    psVerifiedIrListAll supported arguments
  else psListIsEmpty arguments

def psJsDeclarationTypeParametersSupported
    (uniform : Bool)
    (parameters : List PsVerifiedIrTypeParameter) : Bool :=
  if uniform then true else psListIsEmpty parameters

def psJsOneTypeArgumentSupportedWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (arguments : List PsVerifiedIrType) : Bool :=
  match arguments with
  | List.nil => false
  | List.cons value rest =>
      match rest with
      | List.nil =>
          psJsTypeSupportedWithPolicy profile uniform value
      | List.cons _ _ => false

-- Existing callers keep the closed specialization contract.
def psJsOneTypeArgumentSupportedWithProfile
    (profile : Option PsJsTargetProfile)
    (arguments : List PsVerifiedIrType) : Bool :=
  psJsOneTypeArgumentSupportedWithPolicy profile false arguments

def psJsOneTypeArgumentSupported
    (arguments : List PsVerifiedIrType) : Bool :=
  psJsOneTypeArgumentSupportedWithProfile
    Option.none
    arguments

def psJsTwoTypeArgumentsSupportedWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (arguments : List PsVerifiedIrType) : Bool :=
  match arguments with
  | List.nil => false
  | List.cons first rest =>
      match rest with
      | List.nil => false
      | List.cons second tail =>
          match tail with
          | List.nil =>
              if
                  psJsTypeSupportedWithPolicy
                    profile uniform
                    first then
                psJsTypeSupportedWithPolicy
                  profile uniform
                  second
              else
                false
          | List.cons _ _ => false

-- Existing callers keep the closed specialization contract.
def psJsTwoTypeArgumentsSupportedWithProfile
    (profile : Option PsJsTargetProfile)
    (arguments : List PsVerifiedIrType) : Bool :=
  psJsTwoTypeArgumentsSupportedWithPolicy profile false arguments

def psJsTwoTypeArgumentsSupported
    (arguments : List PsVerifiedIrType) : Bool :=
  psJsTwoTypeArgumentsSupportedWithProfile
    Option.none
    arguments

def psJsLowerMachineIntegerTypeWithProfile
    (profile : Option PsJsTargetProfile)
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
  | PsVerifiedIrMachineIntegerType.usize =>
      match profile with
      | Option.none =>
          Except.error PsJsLowerError.unsupportedType
      | Option.some target =>
          match target.wordSize with
          | PsJsWordSize.bits32 =>
              Except.ok PsJsIrMachineIntegerType.uint32
          | PsJsWordSize.bits64 =>
              Except.ok PsJsIrMachineIntegerType.uint64
  | PsVerifiedIrMachineIntegerType.int8 =>
      Except.ok PsJsIrMachineIntegerType.int8
  | PsVerifiedIrMachineIntegerType.int16 =>
      Except.ok PsJsIrMachineIntegerType.int16
  | PsVerifiedIrMachineIntegerType.int32 =>
      Except.ok PsJsIrMachineIntegerType.int32
  | PsVerifiedIrMachineIntegerType.int64 =>
      Except.ok PsJsIrMachineIntegerType.int64
  | PsVerifiedIrMachineIntegerType.isize =>
      match profile with
      | Option.none =>
          Except.error PsJsLowerError.unsupportedType
      | Option.some target =>
          match target.wordSize with
          | PsJsWordSize.bits32 =>
              Except.ok PsJsIrMachineIntegerType.int32
          | PsJsWordSize.bits64 =>
              Except.ok PsJsIrMachineIntegerType.int64

def psJsLowerMachineIntegerType
    (type : PsVerifiedIrMachineIntegerType) :
    Except PsJsLowerError PsJsIrMachineIntegerType :=
  psJsLowerMachineIntegerTypeWithProfile
    Option.none
    type

def psJsMachineIntegerLiteralCanonicalForProfile
    (profile : Option PsJsTargetProfile)
    (type : PsVerifiedIrMachineIntegerType)
    (value : Int) : Bool :=
  let parts : Bool × Nat :=
    psVerifiedIrIntNegativeMagnitude value;
  let negative : Bool := Prod.fst parts;
  let magnitude : Nat := Prod.snd parts;
  match type with
  | PsVerifiedIrMachineIntegerType.usize =>
      if negative then
        false
      else
        match profile with
        | Option.none => false
        | Option.some target =>
            match target.wordSize with
            | PsJsWordSize.bits32 =>
                Nat.ble magnitude 4294967295
            | PsJsWordSize.bits64 =>
                Nat.ble magnitude 18446744073709551615
  | PsVerifiedIrMachineIntegerType.isize =>
      match profile with
      | Option.none => false
      | Option.some target =>
          match target.wordSize with
          | PsJsWordSize.bits32 =>
              if negative then
                Nat.ble magnitude 2147483648
              else
                Nat.ble magnitude 2147483647
          | PsJsWordSize.bits64 =>
              if negative then
                Nat.ble magnitude 9223372036854775808
              else
                Nat.ble magnitude 9223372036854775807
  | _ =>
      psVerifiedIrMachineIntegerLiteralCanonical
        type
        value


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

def psJsLowerLiteralWithProfile
    (profile : Option PsJsTargetProfile)
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
      if
          psJsMachineIntegerLiteralCanonicalForProfile
            profile
            type
            value then
        match
            psJsLowerMachineIntegerTypeWithProfile
              profile
              type with
        | Except.error error => Except.error error
        | Except.ok loweredType =>
            Except.ok
              (PsJsIrLiteral.machineInteger
                loweredType
                value)
      else
        Except.error PsJsLowerError.unsupportedLiteral

def psJsLowerLiteral
    (literal : PsVerifiedIrLiteral) :
    Except PsJsLowerError PsJsIrLiteral :=
  psJsLowerLiteralWithProfile Option.none literal

def psJsLowerParameterNamesWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      if psJsIdentifierSupported parameter.name then
        if
            psJsTypeSupportedWithPolicy
              profile uniform
              parameter.type then
          match
              psJsLowerParameterNamesWithPolicy
                profile uniform
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (List.cons parameter.name loweredRest)
        else
          Except.error PsJsLowerError.unsupportedType
      else
        Except.error
          (PsJsLowerError.unsupportedName parameter.name)

-- Existing callers keep the closed specialization contract.
def psJsLowerParameterNamesWithProfile
    (profile : Option PsJsTargetProfile)
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List String) :=
  psJsLowerParameterNamesWithPolicy profile false parameters

def psJsLowerParameterNames
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List String) :=
  psJsLowerParameterNamesWithProfile
    Option.none
    parameters

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

def psJsLowerRuntimeTernaryWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (operation : PsJsIrRuntimeOp)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  match arguments with
  | List.nil =>
      Except.error PsJsLowerError.intrinsicArity
  | List.cons first rest =>
      match rest with
      | List.nil =>
          Except.error PsJsLowerError.intrinsicArity
      | List.cons second tail =>
          match tail with
          | List.nil =>
              Except.error PsJsLowerError.intrinsicArity
          | List.cons third finalTail =>
              match finalTail with
              | List.cons _ _ =>
                  Except.error PsJsLowerError.intrinsicArity
              | List.nil =>
                  match lower first with
                  | Except.error error => Except.error error
                  | Except.ok loweredFirst =>
                      match lower second with
                      | Except.error error => Except.error error
                      | Except.ok loweredSecond =>
                          match lower third with
                          | Except.error error => Except.error error
                          | Except.ok loweredThird =>
                              Except.ok
                                (PsJsIrExpr.runtime
                                  operation
                                  [
                                    loweredFirst,
                                    loweredSecond,
                                    loweredThird
                                  ])

def psJsLowerRuntimeExactArityWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (operation : PsJsIrRuntimeOp)
    (arity : Nat)
    (arguments : List PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  if Nat.beq (psListLength arguments) arity then
    match psListMapExcept lower arguments with
    | Except.error error => Except.error error
    | Except.ok loweredArguments =>
        Except.ok
          (PsJsIrExpr.runtime
            operation
            loweredArguments)
  else
    Except.error PsJsLowerError.intrinsicArity

def psJsLowerFieldsWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (fields : List (String × PsVerifiedIrExpr)) :
    Except PsJsLowerError (List (String × PsJsIrExpr)) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match field with
      | Prod.mk name value =>
          match lower value with
          | Except.error error => Except.error error
          | Except.ok loweredValue =>
              match psJsLowerFieldsWith lower rest with
              | Except.error error => Except.error error
              | Except.ok loweredRest =>
                  Except.ok
                    (List.cons
                      (Prod.mk name loweredValue)
                      loweredRest)

def psJsLowerMatchBindingsWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsJsLowerError (List PsJsIrMatchBinding) :=
  match bindings with
  | List.nil =>
      Except.ok List.nil
  | List.cons binding rest =>
      if psJsIdentifierSupported binding.name then
        if
            psJsTypeSupportedWithPolicy
              profile uniform
              binding.type then
          match
              psJsLowerMatchBindingsWithPolicy
                profile uniform
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok
                (List.cons
                  (PsJsIrMatchBinding.mk
                    binding.field
                    binding.name)
                  loweredRest)
        else
          Except.error PsJsLowerError.unsupportedType
      else
        Except.error
          (PsJsLowerError.unsupportedName binding.name)

-- Existing callers keep the closed specialization contract.
def psJsLowerMatchBindingsWithProfile
    (profile : Option PsJsTargetProfile)
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsJsLowerError (List PsJsIrMatchBinding) :=
  psJsLowerMatchBindingsWithPolicy profile false bindings

def psJsLowerMatchBindings
    (bindings : List PsVerifiedIrMatchBinding) :
    Except PsJsLowerError (List PsJsIrMatchBinding) :=
  psJsLowerMatchBindingsWithProfile
    Option.none
    bindings

def psJsLowerMatchAlternativesWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except
      PsJsLowerError
      (List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :=
  match alternatives with
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      match alternative with
      | Prod.mk constructorName detail =>
          match detail with
          | Prod.mk bindings body =>
              match
                  psJsLowerMatchBindingsWithPolicy
                    profile uniform
                    bindings with
              | Except.error error => Except.error error
              | Except.ok loweredBindings =>
                  match lower body with
                  | Except.error error => Except.error error
                  | Except.ok loweredBody =>
                      match
                          psJsLowerMatchAlternativesWithPolicy
                            profile uniform
                            lower
                            rest with
                      | Except.error error => Except.error error
                      | Except.ok loweredRest =>
                          Except.ok
                            (List.cons
                              (Prod.mk
                                constructorName
                                (Prod.mk
                                  loweredBindings
                                  loweredBody))
                              loweredRest)

-- Existing callers keep the closed specialization contract.
def psJsLowerMatchAlternativesWithProfile
    (profile : Option PsJsTargetProfile)
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except
      PsJsLowerError
      (List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :=
  psJsLowerMatchAlternativesWithPolicy profile false lower alternatives

def psJsLowerMatchAlternativesWith
    (lower : PsVerifiedIrExpr -> Except PsJsLowerError PsJsIrExpr)
    (alternatives :
      List
        (String ×
          List PsVerifiedIrMatchBinding ×
          PsVerifiedIrExpr)) :
    Except
      PsJsLowerError
      (List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :=
  psJsLowerMatchAlternativesWithProfile
    Option.none
    lower
    alternatives

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

def psJsLowerExprWithPolicyAndFuel
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
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
        psJsLowerExprWithPolicyAndFuel
          profile uniform
          remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.literal literal =>
            match
                psJsLowerLiteralWithProfile
                  profile
                  literal with
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
                  match
                      psJsLowerMachineIntegerTypeWithProfile
                        profile
                        type with
                  | Except.error error => Except.error error
                  | Except.ok loweredType =>
                      psJsLowerBinaryWith
                        smaller
                        (PsJsIrBinaryOp.machineInt
                          loweredType
                          (psJsLowerIntegerBinaryOp integerOperation))
                        arguments
              | PsVerifiedIrIntrinsic.machineIntCompare type integerOperation =>
                  match
                      psJsLowerMachineIntegerTypeWithProfile
                        profile
                        type with
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
              | PsVerifiedIrIntrinsic.stringUtf8ByteSize =>
                  psJsLowerRuntimeUnaryWith
                    smaller PsJsIrRuntimeOp.stringUtf8ByteSize arguments
              | PsVerifiedIrIntrinsic.stringNext =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.stringNext arguments
              | PsVerifiedIrIntrinsic.stringGet =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.stringGet arguments
              | PsVerifiedIrIntrinsic.stringAtEnd =>
                  psJsLowerRuntimeBinaryWith
                    smaller PsJsIrRuntimeOp.stringAtEnd arguments
              | PsVerifiedIrIntrinsic.stringExtract =>
                  psJsLowerRuntimeTernaryWith
                    smaller PsJsIrRuntimeOp.stringExtract arguments
              | PsVerifiedIrIntrinsic.stringEq =>
                  psJsLowerBinaryWith
                    smaller PsJsIrBinaryOp.stringEq arguments
              | _ =>
                  Except.error PsJsLowerError.unsupportedIntrinsic
            else
              match operation with
              | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayEmptyWithCapacity
                      1
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arraySize =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arraySize
                      1
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayPush =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayPush
                      2
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayGet =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayGet
                      2
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayGetD =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayGetD
                      3
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arraySet =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arraySet
                      3
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arraySetIfInBounds =>
                  if
                      psJsOneTypeArgumentSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arraySetIfInBounds
                      3
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayMap =>
                  if
                      psJsTwoTypeArgumentsSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayMap
                      2
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | PsVerifiedIrIntrinsic.arrayFoldl =>
                  if
                      psJsTwoTypeArgumentsSupportedWithPolicy
                        profile uniform
                        typeArguments then
                    psJsLowerRuntimeExactArityWith
                      smaller
                      PsJsIrRuntimeOp.arrayFoldl
                      5
                      arguments
                  else
                    Except.error PsJsLowerError.typeArgumentsUnsupported
              | _ =>
                  Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.lambda
            parameters
            resultType
            body =>
            if
                psJsTypeSupportedWithPolicy
                  profile uniform
                  resultType then
              match
                  psJsLowerParameterNamesWithPolicy
                    profile uniform
                    parameters with
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
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
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
              if
                  psJsTypeSupportedWithPolicy
                    profile uniform
                    type then
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
        | PsVerifiedIrExpr.record
            _structureName
            typeArguments
            fields =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match psJsLowerFieldsWith smaller fields with
              | Except.error error => Except.error error
              | Except.ok loweredFields =>
                  Except.ok
                    (PsJsIrExpr.record loweredFields)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.projection
            _structureName
            typeArguments
            target
            field =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match smaller target with
              | Except.error error => Except.error error
              | Except.ok loweredTarget =>
                  Except.ok
                    (PsJsIrExpr.projection
                      loweredTarget
                      field)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.constructor
            _inductiveName
            constructorName
            typeArguments
            fields =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match psJsLowerFieldsWith smaller fields with
              | Except.error error => Except.error error
              | Except.ok loweredFields =>
                  Except.ok
                    (PsJsIrExpr.constructor
                      constructorName
                      loweredFields)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
        | PsVerifiedIrExpr.matchE
            _inductiveName
            typeArguments
            scrutinee
            alternatives =>
            if psJsErasedTypeArgumentsSupported profile uniform typeArguments then
              match smaller scrutinee with
              | Except.error error => Except.error error
              | Except.ok loweredScrutinee =>
                  match
                      psJsLowerMatchAlternativesWithPolicy
                        profile uniform
                        smaller
                        alternatives with
                  | Except.error error => Except.error error
                  | Except.ok loweredAlternatives =>
                      Except.ok
                        (PsJsIrExpr.matchE
                          loweredScrutinee
                          loweredAlternatives)
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported

-- Existing callers keep the closed specialization contract.
def psJsLowerExprWithProfileAndFuel
    (profile : Option PsJsTargetProfile)
    (fuel : Nat) :
    PsVerifiedIrExpr ->
      Except PsJsLowerError PsJsIrExpr :=
  psJsLowerExprWithPolicyAndFuel profile false fuel

def psJsLowerExprWithFuel
    (fuel : Nat)
    (expr : PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  psJsLowerExprWithProfileAndFuel
    Option.none
    fuel
    expr

def psJsLowerExprWithTargetProfile
    (profile : PsJsTargetProfile)
    (expr : PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  psJsLowerExprWithProfileAndFuel
    (Option.some profile)
    4096
    expr

def psJsLowerExpr
    (expr : PsVerifiedIrExpr) :
    Except PsJsLowerError PsJsIrExpr :=
  psJsLowerExprWithFuel 4096 expr

def psJsLowerParametersWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List PsJsIrParameter) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      if psJsIdentifierSupported parameter.name then
        if
            psJsTypeSupportedWithPolicy
              profile uniform
              parameter.type then
          match
              psJsLowerParametersWithPolicy
                profile uniform
                rest with
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

-- Existing callers keep the closed specialization contract.
def psJsLowerParametersWithProfile
    (profile : Option PsJsTargetProfile)
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List PsJsIrParameter) :=
  psJsLowerParametersWithPolicy profile false parameters

def psJsLowerParameters
    (parameters : List PsVerifiedIrParameter) :
    Except PsJsLowerError (List PsJsIrParameter) :=
  psJsLowerParametersWithProfile
    Option.none
    parameters

def psJsLowerImportWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (importInfo : PsVerifiedIrExternalImport) :
    Except PsJsLowerError PsJsIrImport :=
  if psJsIdentifierSupported importInfo.localName then
    if psJsImportNameSupported importInfo.importedName then
      if
          psJsTypeSupportedWithPolicy
            profile uniform
            importInfo.type then
        Except.ok
          (PsJsIrImport.mk
            importInfo.localName
            importInfo.source
            importInfo.importedName)
      else
        Except.error PsJsLowerError.unsupportedType
    else
      Except.error
        (PsJsLowerError.unsupportedName
          importInfo.importedName)
  else
    Except.error
      (PsJsLowerError.unsupportedName
        importInfo.localName)

-- Existing callers keep the closed specialization contract.
def psJsLowerImportWithProfile
    (profile : Option PsJsTargetProfile)
    (importInfo : PsVerifiedIrExternalImport) :
    Except PsJsLowerError PsJsIrImport :=
  psJsLowerImportWithPolicy profile false importInfo

def psJsLowerImport
    (importInfo : PsVerifiedIrExternalImport) :
    Except PsJsLowerError PsJsIrImport :=
  psJsLowerImportWithProfile
    Option.none
    importInfo

def psJsLowerImportsWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (imports : List PsVerifiedIrExternalImport) :
    Except PsJsLowerError (List PsJsIrImport) :=
  match imports with
  | List.nil =>
      Except.ok List.nil
  | List.cons importInfo rest =>
      match
          psJsLowerImportWithPolicy
            profile uniform
            importInfo with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psJsLowerImportsWithPolicy
                profile uniform
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

-- Existing callers keep the closed specialization contract.
def psJsLowerImportsWithProfile
    (profile : Option PsJsTargetProfile)
    (imports : List PsVerifiedIrExternalImport) :
    Except PsJsLowerError (List PsJsIrImport) :=
  psJsLowerImportsWithPolicy profile false imports

def psJsLowerImports
    (imports : List PsVerifiedIrExternalImport) :
    Except PsJsLowerError (List PsJsIrImport) :=
  psJsLowerImportsWithProfile
    Option.none
    imports

def psJsLowerDeclarationWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsJsLowerError PsJsIrDeclaration :=
  if psJsIdentifierSupported declaration.name then
    if psJsDeclarationTypeParametersSupported uniform declaration.typeParameters then
      if
          psJsTypeSupportedWithPolicy
            profile uniform
            declaration.resultType then
        match
            psJsLowerParametersWithPolicy
              profile uniform
              declaration.parameters with
        | Except.error error => Except.error error
        | Except.ok parameters =>
            match
                psJsLowerExprWithPolicyAndFuel
                  profile uniform
                  4096
                  declaration.body with
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

-- Existing callers keep the closed specialization contract.
def psJsLowerDeclarationWithProfile
    (profile : Option PsJsTargetProfile)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsJsLowerError PsJsIrDeclaration :=
  psJsLowerDeclarationWithPolicy profile false declaration

def psJsLowerDeclaration
    (declaration : PsVerifiedIrDeclaration) :
    Except PsJsLowerError PsJsIrDeclaration :=
  psJsLowerDeclarationWithProfile
    Option.none
    declaration

def psJsLowerDeclarationsWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsJsLowerError (List PsJsIrDeclaration) :=
  match declarations with
  | List.nil =>
      Except.ok List.nil
  | List.cons declaration rest =>
      match
          psJsLowerDeclarationWithPolicy
            profile uniform
            declaration with
      | Except.error error => Except.error error
      | Except.ok lowered =>
          match
              psJsLowerDeclarationsWithPolicy
                profile uniform
                rest with
          | Except.error error => Except.error error
          | Except.ok loweredRest =>
              Except.ok (List.cons lowered loweredRest)

-- Existing callers keep the closed specialization contract.
def psJsLowerDeclarationsWithProfile
    (profile : Option PsJsTargetProfile)
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsJsLowerError (List PsJsIrDeclaration) :=
  psJsLowerDeclarationsWithPolicy profile false declarations

def psJsLowerDeclarations
    (declarations : List PsVerifiedIrDeclaration) :
    Except PsJsLowerError (List PsJsIrDeclaration) :=
  psJsLowerDeclarationsWithProfile
    Option.none
    declarations

def psJsLowerSpecializedModuleWithPolicy
    (profile : Option PsJsTargetProfile)
    (uniform : Bool)
    (module : PsVerifiedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  match
      psJsLowerImportsWithPolicy
        profile uniform
        module.imports with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match
          psJsLowerDeclarationsWithPolicy
            profile uniform
            module.declarations with
      | Except.error error => Except.error error
      | Except.ok declarations =>
          Except.ok
            (PsJsIrModule.mk imports declarations)

-- Existing callers keep the closed specialization contract.
def psJsLowerSpecializedModuleWithProfile
    (profile : Option PsJsTargetProfile)
    (module : PsVerifiedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  psJsLowerSpecializedModuleWithPolicy profile false module

def psJsLowerSpecializedModule
    (module : PsVerifiedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  psJsLowerSpecializedModuleWithProfile
    Option.none
    module

def psJsLowerSpecializedValidatedModuleWithProfile
    (profile : Option PsJsTargetProfile)
    (specialized : PsSpecializedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  psJsLowerSpecializedModuleWithProfile
    profile
    specialized.raw

def psJsLowerValidatedModuleWithProfile
    (profile : Option PsJsTargetProfile)
    (validated : PsValidatedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  match psIrSpecializeValidatedModule validated with
  | Except.error error =>
      Except.error (PsJsLowerError.specializationFailed error)
  | Except.ok specialized =>
      psJsLowerSpecializedValidatedModuleWithProfile
        profile
        specialized

def psJsLowerValidatedModuleWithTargetProfile
    (profile : PsJsTargetProfile)
    (validated : PsValidatedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  psJsLowerValidatedModuleWithProfile
    (Option.some profile)
    validated

def psJsLowerValidatedModule
    (validated : PsValidatedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  psJsLowerValidatedModuleWithProfile
    Option.none
    validated

-- Uniform representation is an explicit different specialization selection,
-- never a relaxation of PsSpecializedIrModule's closed-instance contract.
def psJsLowerUniformSpecializedModuleWithProfile
    (profile : Option PsJsTargetProfile)
    (specialized : PsUniformSpecializedIrModule) :
    Except PsJsLowerError PsJsIrModule :=
  if psListIsEmpty specialized.raw.imports then
    psJsLowerSpecializedModuleWithPolicy profile true specialized.raw
  else Except.error PsJsLowerError.importsUnsupported
