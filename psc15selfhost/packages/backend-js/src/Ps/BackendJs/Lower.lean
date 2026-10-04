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
  let value := Char.toNat char;
  psJsNatInRange value 65 90
    || psJsNatInRange value 97 122
    || Nat.beq value 95
    || Nat.beq value 36

def psJsIdentifierRestCharAllowed
    (char : Char) : Bool :=
  let value := Char.toNat char;
  psJsIdentifierFirstCharAllowed char
    || psJsNatInRange value 48 57

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
  psStringEq value "await"
    || psStringEq value "break"
    || psStringEq value "case"
    || psStringEq value "catch"
    || psStringEq value "class"
    || psStringEq value "const"
    || psStringEq value "continue"
    || psStringEq value "debugger"
    || psStringEq value "default"
    || psStringEq value "delete"
    || psStringEq value "do"
    || psStringEq value "else"
    || psStringEq value "enum"
    || psStringEq value "export"
    || psStringEq value "extends"
    || psStringEq value "false"
    || psStringEq value "finally"
    || psStringEq value "for"
    || psStringEq value "function"
    || psStringEq value "if"
    || psStringEq value "import"
    || psStringEq value "in"
    || psStringEq value "instanceof"
    || psStringEq value "let"
    || psStringEq value "new"
    || psStringEq value "null"
    || psStringEq value "return"
    || psStringEq value "static"
    || psStringEq value "super"
    || psStringEq value "switch"
    || psStringEq value "this"
    || psStringEq value "throw"
    || psStringEq value "true"
    || psStringEq value "try"
    || psStringEq value "typeof"
    || psStringEq value "var"
    || psStringEq value "void"
    || psStringEq value "while"
    || psStringEq value "with"
    || psStringEq value "yield"

def psJsIdentifierSupported
    (value : String) : Bool :=
  match psJsonStringToChars value with
  | List.nil => false
  | List.cons first rest =>
      if psJsIdentifierFirstCharAllowed first then
        if psJsIdentifierRestSupported rest then
          !psJsIdentifierKeyword value
        else
          false
      else
        false

def psJsPrimitiveTypeSupported
    (type : PsVerifiedIrPrimitiveType) : Bool :=
  match type with
  | PsVerifiedIrPrimitiveType.nat => true
  | PsVerifiedIrPrimitiveType.int => true
  | PsVerifiedIrPrimitiveType.bool => true
  | PsVerifiedIrPrimitiveType.string => true
  | PsVerifiedIrPrimitiveType.unit => true
  | _ => false

def psJsTypeSupported
    (type : PsVerifiedIrType) : Bool :=
  match type with
  | PsVerifiedIrType.primitive primitive =>
      psJsPrimitiveTypeSupported primitive
  | _ => false

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
  | PsVerifiedIrLiteral.machineInteger _ _ =>
      Except.error PsJsLowerError.unsupportedLiteral

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
              | PsVerifiedIrIntrinsic.natAdd =>
                  match arguments with
                  | List.cons left rest =>
                      match rest with
                      | List.cons right tail =>
                          match tail with
                          | List.nil =>
                              match smaller left with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok loweredLeft =>
                                  match smaller right with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok loweredRight =>
                                      Except.ok
                                        (PsJsIrExpr.binary
                                          PsJsIrBinaryOp.bigintAdd
                                          loweredLeft
                                          loweredRight)
                          | List.cons _ _ =>
                              Except.error
                                PsJsLowerError.intrinsicArity
                      | List.nil =>
                          Except.error PsJsLowerError.intrinsicArity
                  | List.nil =>
                      Except.error PsJsLowerError.intrinsicArity
              | _ =>
                  Except.error PsJsLowerError.unsupportedIntrinsic
            else
              Except.error PsJsLowerError.typeArgumentsUnsupported
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
