import Ps.CompilerIr.Model
import Ps.Bridge.Json

inductive PsRustEmitError where
  | fuelExhausted
  | unsupportedIntrinsic
  | intrinsicArity
  | externalImportUnsupported
  | genericValueUnsupported (name : String)
  | valueDeclarationUnsupported (name : String)
  | unknownStructure (name : String)
  | unknownInductive (name : String)

def psRustConcat2 (a b : String) : String :=
  String.Internal.append a b

def psRustConcat3 (a b c : String) : String :=
  psRustConcat2 (psRustConcat2 a b) c

def psRustConcat4 (a b c d : String) : String :=
  psRustConcat2 (psRustConcat3 a b c) d

def psRustJoin
    (separator : String)
    (values : List String) : String :=
  match values with
  | List.nil =>
      ""
  | List.cons value rest =>
      match rest with
      | List.nil =>
          value
      | List.cons _ _ =>
          psRustConcat3 value separator (psRustJoin separator rest)

def psRustEscapeControl (value : Nat) : String :=
  psRustConcat4
    "\\x"
    (psJsonHexDigit (Nat.div value 16))
    (psJsonHexDigit (Nat.mod value 16))
    ""

def psRustEscapeChar (char : Char) : String :=
  let value : Nat := Char.toNat char;
  if Nat.beq value 9 then
    "\\t"
  else if Nat.beq value 10 then
    "\\n"
  else if Nat.beq value 13 then
    "\\r"
  else if Nat.beq value 34 then
    "\\\""
  else if Nat.beq value 92 then
    "\\\\"
  else if Nat.blt value 32 then
    psRustEscapeControl value
  else
    psJsonStringOfChars (List.cons char List.nil)

def psRustEscapeChars (chars : List Char) : String :=
  match chars with
  | List.nil =>
      ""
  | List.cons char rest =>
      psRustConcat2
        (psRustEscapeChar char)
        (psRustEscapeChars rest)

def psRustQuote (value : String) : String :=
  psRustConcat3
    "\""
    (psRustEscapeChars (psJsonStringToChars value))
    "\""

def psRustEmitPrimitiveType
    (type : PsVerifiedIrPrimitiveType) : String :=
  match type with
  | PsVerifiedIrPrimitiveType.nat => "PsNat"
  | PsVerifiedIrPrimitiveType.int => "PsInt"
  | PsVerifiedIrPrimitiveType.bool => "bool"
  | PsVerifiedIrPrimitiveType.char => "char"
  | PsVerifiedIrPrimitiveType.string => "String"
  | PsVerifiedIrPrimitiveType.unit => "()"

def psRustEmitTypeListWith
    (emitType :
      PsVerifiedIrType ->
      Except PsRustEmitError String) :
    List PsVerifiedIrType ->
    Except PsRustEmitError (List String)
  | List.nil =>
      Except.ok List.nil
  | List.cons type rest =>
      match emitType type with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitTypeListWith emitType rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons printed printedRest)

def psRustEmitTypeWithFuel :
    Nat ->
    PsVerifiedIrType ->
    Except PsRustEmitError String
  | 0, _ =>
      Except.error PsRustEmitError.fuelExhausted
  | fuel + 1, type =>
      match type with
      | PsVerifiedIrType.unknown =>
          Except.ok "()"
      | PsVerifiedIrType.typeParameter name =>
          Except.ok name
      | PsVerifiedIrType.primitive primitive =>
          Except.ok (psRustEmitPrimitiveType primitive)
      | PsVerifiedIrType.function parameters result =>
          let emitNested :=
            fun (nestedType : PsVerifiedIrType) =>
              psRustEmitTypeWithFuel fuel nestedType;
          match psRustEmitTypeListWith emitNested parameters with
          | Except.error error =>
              Except.error error
          | Except.ok printedParameters =>
              match psRustEmitTypeWithFuel fuel result with
              | Except.error error =>
                  Except.error error
              | Except.ok printedResult =>
                  Except.ok
                    (psRustConcat4
                      "fn("
                      (psRustJoin ", " printedParameters)
                      ") -> "
                      printedResult)
      | PsVerifiedIrType.named name arguments =>
          let emitNested :=
            fun (nestedType : PsVerifiedIrType) =>
              psRustEmitTypeWithFuel fuel nestedType;
          match psRustEmitTypeListWith emitNested arguments with
          | Except.error error =>
              Except.error error
          | Except.ok printedArguments =>
              match printedArguments with
              | List.nil =>
                  Except.ok name
              | List.cons _ _ =>
                  Except.ok
                    (psRustConcat4
                      name
                      "<"
                      (psRustJoin ", " printedArguments)
                      ">")

def psRustEmitType
    (type : PsVerifiedIrType) :
    Except PsRustEmitError String :=
  psRustEmitTypeWithFuel 4096 type

def psRustEmitLiteral
    (literal : PsVerifiedIrLiteral) : String :=
  match literal with
  | PsVerifiedIrLiteral.natural value =>
      psRustConcat3
        "__ps_nat_lit("
        (psRustQuote (toString value))
        ")"
  | PsVerifiedIrLiteral.integer value =>
      psRustConcat3
        "__ps_int_lit("
        (psRustQuote (toString value))
        ")"
  | PsVerifiedIrLiteral.string value =>
      psRustConcat3
        "String::from("
        (psRustQuote value)
        ")"
  | PsVerifiedIrLiteral.bool value =>
      if value then "true" else "false"
  | PsVerifiedIrLiteral.unit =>
      "()"
