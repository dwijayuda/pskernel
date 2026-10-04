import Ps.BackendJs.Lower
import Ps.Bridge.Json
import Ps.Foundation.List
import Ps.Foundation.Name

inductive PsJsEmitError where
  | lower (error : PsJsLowerError)
  | fuelExhausted

def psJsJoin
    (separator : String)
    (values : List String) : String :=
  match values with
  | List.nil => ""
  | List.cons value rest =>
      match rest with
      | List.nil => value
      | List.cons _ _ =>
          String.Internal.append
            value
            (String.Internal.append
              separator
              (psJsJoin separator rest))

def psJsConcat2
    (a b : String) : String :=
  String.Internal.append a b

def psJsConcat3
    (a b c : String) : String :=
  psJsConcat2 (psJsConcat2 a b) c

def psJsConcat4
    (a b c d : String) : String :=
  psJsConcat2 (psJsConcat3 a b c) d

def psJsConcat5
    (a b c d e : String) : String :=
  psJsConcat2 (psJsConcat4 a b c d) e

def psJsConcat6
    (a b c d e f : String) : String :=
  psJsConcat2 (psJsConcat5 a b c d e) f

def psJsConcat7
    (a b c d e f g : String) : String :=
  psJsConcat2 (psJsConcat6 a b c d e f) g

def psJsPrintLiteral
    (literal : PsJsIrLiteral) : String :=
  match literal with
  | PsJsIrLiteral.natural value =>
      String.Internal.append
        (psNatToString value)
        "n"
  | PsJsIrLiteral.integer value =>
      String.Internal.append
        (Int.repr value)
        "n"
  | PsJsIrLiteral.string value =>
      psJsonQuote value
  | PsJsIrLiteral.bool value =>
      if value then "true" else "false"
  | PsJsIrLiteral.unit =>
      "(void 0)"

def psJsPrintExprWithFuel
    (fuel : Nat) :
    PsJsIrExpr -> Except PsJsEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsJsIrExpr) =>
        Except.error PsJsEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsJsIrExpr -> Except PsJsEmitError String :=
        psJsPrintExprWithFuel remaining;
      fun (expr : PsJsIrExpr) =>
        match expr with
        | PsJsIrExpr.literal literal =>
            Except.ok (psJsPrintLiteral literal)
        | PsJsIrExpr.var name =>
            Except.ok name
        | PsJsIrExpr.binary
            PsJsIrBinaryOp.bigintAdd
            left
            right =>
            match smaller left with
            | Except.error error => Except.error error
            | Except.ok printedLeft =>
                match smaller right with
                | Except.error error => Except.error error
                | Except.ok printedRight =>
                    Except.ok
                      (psJsConcat5
                        "("
                        printedLeft
                        " + "
                        printedRight
                        ")")
        | PsJsIrExpr.call fn arguments =>
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                match psListMapExcept smaller arguments with
                | Except.error error => Except.error error
                | Except.ok printedArguments =>
                    Except.ok
                      (psJsConcat4
                        printedFn
                        "("
                        (psJsJoin ", " printedArguments)
                        ")")
        | PsJsIrExpr.ifE
            condition
            thenBranch
            elseBranch =>
            match smaller condition with
            | Except.error error => Except.error error
            | Except.ok printedCondition =>
                match smaller thenBranch with
                | Except.error error => Except.error error
                | Except.ok printedThen =>
                    match smaller elseBranch with
                    | Except.error error => Except.error error
                    | Except.ok printedElse =>
                        Except.ok
                          (psJsConcat7
                            "("
                            printedCondition
                            " ? "
                            printedThen
                            " : "
                            printedElse
                            ")")

def psJsPrintExpr
    (expr : PsJsIrExpr) :
    Except PsJsEmitError String :=
  psJsPrintExprWithFuel 4096 expr

def psJsParameterName
    (parameter : PsJsIrParameter) : String :=
  parameter.name

def psJsPrintDeclaration
    (declaration : PsJsIrDeclaration) :
    Except PsJsEmitError String :=
  match psJsPrintExpr declaration.body with
  | Except.error error => Except.error error
  | Except.ok body =>
      match declaration.parameters with
      | List.nil =>
          Except.ok
            (psJsConcat4
              "export const "
              declaration.name
              " = "
              (psJsConcat2 body ";\n"))
      | List.cons _ _ =>
          let parameters :=
            psListMap
              psJsParameterName
              declaration.parameters;
          Except.ok
            (psJsConcat6
              "export function "
              declaration.name
              "("
              (psJsJoin ", " parameters)
              ") { return "
              (psJsConcat2 body "; }\n"))

def psJsPrintDeclarations
    (declarations : List PsJsIrDeclaration) :
    Except PsJsEmitError String :=
  match declarations with
  | List.nil =>
      Except.ok ""
  | List.cons declaration rest =>
      match psJsPrintDeclaration declaration with
      | Except.error error => Except.error error
      | Except.ok printed =>
          match psJsPrintDeclarations rest with
          | Except.error error => Except.error error
          | Except.ok printedRest =>
              Except.ok
                (psJsConcat2
                  printed
                  printedRest)

def psJsPrintModule
    (module : PsJsIrModule) :
    Except PsJsEmitError String :=
  match psJsPrintDeclarations module.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations =>
      Except.ok
        (psJsConcat2
          "// generated by ProofScript direct JsIR v1\n"
          declarations)

def psJsEmitValidatedModule
    (module : PsValidatedIrModule) :
    Except PsJsEmitError String :=
  match psJsLowerValidatedModule module with
  | Except.error error =>
      Except.error (PsJsEmitError.lower error)
  | Except.ok jsIr =>
      psJsPrintModule jsIr
