import Ps.CompilerIr.Model
import Ps.Bridge.Json
import Ps.BackendJs.Model

def psJsNameHead (value : Char) : Bool :=
  let code := Char.toNat value;
  if psJsonNatInRange code 65 90 then true
  else if psJsonNatInRange code 97 122 then true
  else if Nat.beq code 95 then true
  else Nat.beq code 36

def psJsNameTail (values : List Char) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if psJsNameHead value then psJsNameTail rest
      else if psJsonNatInRange (Char.toNat value) 48 57 then psJsNameTail rest
      else false

def psJsContainsName (values : List String) (name : String) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest =>
      if psJsonStringEq value name then true
      else psJsContainsName rest name

def psJsReservedNames : List String :=
  ["await", "break", "case", "catch", "class", "const", "continue",
   "debugger", "default", "delete", "do", "else", "enum", "export",
   "extends", "false", "finally", "for", "function", "if", "implements",
   "import", "in", "instanceof", "interface", "let", "new", "null",
   "package", "private", "protected", "public", "return", "static",
   "super", "switch", "this", "throw", "true", "try", "typeof", "var",
   "void", "while", "with", "yield", "eval", "arguments"]

def psJsValidExportName (name : String) : Bool :=
  if psJsContainsName psJsReservedNames name then false
  else
    match psJsonStringToChars name with
    | List.nil => false
    | List.cons head tail =>
        if psJsNameHead head then psJsNameTail tail else false

def psJsLowerLiteral (value : PsVerifiedIrLiteral)
    (type : PsVerifiedIrPrimitiveType) : Except PsJsError PsJsLiteral :=
  match value with
  | PsVerifiedIrLiteral.natural number =>
      match type with
      | PsVerifiedIrPrimitiveType.nat => Except.ok (PsJsLiteral.natural number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.integer number =>
      match type with
      | PsVerifiedIrPrimitiveType.int => Except.ok (PsJsLiteral.integer number)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.bool boolean =>
      match type with
      | PsVerifiedIrPrimitiveType.bool => Except.ok (PsJsLiteral.boolean boolean)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.string text =>
      match type with
      | PsVerifiedIrPrimitiveType.string => Except.ok (PsJsLiteral.string text)
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.unit =>
      match type with
      | PsVerifiedIrPrimitiveType.unit => Except.ok PsJsLiteral.undefined
      | _ => Except.error PsJsError.literalTypeMismatch
  | PsVerifiedIrLiteral.machineInteger _ _ =>
      Except.error PsJsError.unsupportedExpression

def psJsLowerBody (type : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) : Except PsJsError PsJsLiteral :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      match body with
      | PsVerifiedIrExpr.literal value => psJsLowerLiteral value primitive
      | _ => Except.error PsJsError.unsupportedExpression
  | _ => Except.error PsJsError.literalTypeMismatch

def psJsLowerConstant (declaration : PsVerifiedIrDeclaration) :
    Except PsJsError PsJsConstant :=
  match declaration.typeParameters with
  | List.cons _ _ => Except.error (PsJsError.unsupportedDeclaration declaration.name)
  | List.nil =>
      match declaration.parameters with
      | List.cons _ _ => Except.error (PsJsError.unsupportedDeclaration declaration.name)
      | List.nil =>
          if psJsValidExportName declaration.name then
            match psJsLowerBody declaration.resultType declaration.body with
            | Except.error error => Except.error error
            | Except.ok value => Except.ok (PsJsConstant.mk declaration.name value)
          else Except.error (PsJsError.invalidExportName declaration.name)

def psJsLowerConstants (declarations : List PsVerifiedIrDeclaration) :
    List String -> Except PsJsError (List PsJsConstant) :=
  match declarations with
  | List.nil => fun (_used : List String) => Except.ok List.nil
  | List.cons declaration rest =>
      let smaller : List String -> Except PsJsError (List PsJsConstant) :=
        psJsLowerConstants rest;
      fun (used : List String) =>
        if psJsContainsName used declaration.name then
          Except.error (PsJsError.duplicateExport declaration.name)
        else
          match psJsLowerConstant declaration with
          | Except.error error => Except.error error
          | Except.ok value =>
              match smaller (List.cons declaration.name used) with
              | Except.error error => Except.error error
              | Except.ok values => Except.ok (List.cons value values)

def psJsLowerModule (module : PsVerifiedIrModule) : Except PsJsError PsJsModule :=
  match module.imports with
  | List.cons _ _ => Except.error PsJsError.unsupportedModule
  | List.nil =>
      match module.structures with
      | List.cons _ _ => Except.error PsJsError.unsupportedModule
      | List.nil =>
          match module.inductives with
          | List.cons _ _ => Except.error PsJsError.unsupportedModule
          | List.nil =>
              match psJsLowerConstants module.declarations List.nil with
              | Except.error error => Except.error error
              | Except.ok constants => Except.ok (PsJsModule.mk constants)
