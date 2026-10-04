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
                      (String.Internal.append
                        "("
                        (String.Internal.append
                          printedLeft
                          (String.Internal.append
                            " + "
                            (String.Internal.append
                              printedRight
                              ")"))))
        | PsJsIrExpr.call fn arguments =>
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok printedFn =>
                match psListMapExcept smaller arguments with
                | Except.error error => Except.error error
                | Except.ok printedArguments =>
                    Except.ok
                      (String.Internal.append
                        printedFn
                        (String.Internal.append
                          "("
                          (String.Internal.append
                            (psJsJoin ", " printedArguments)
                            ")")))
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
                          (String.Internal.append
                            "("
                            (String.Internal.append
                              printedCondition
                              (String.Internal.append
                                " ? "
                                (String.Internal.append
                                  printedThen
                                  (String.Internal.append
                                    " : "
                                    (String.Internal.append
                                      printedElse
                                      ")"))))))

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
            (String.Internal.append
              "export const "
              (String.Internal.append
                declaration.name
                (String.Internal.append
                  " = "
                  (String.Internal.append body ";\n"))))
      | List.cons _ _ =>
          let parameters :=
            psListMap
              psJsParameterName
              declaration.parameters;
          Except.ok
            (String.Internal.append
              "export function "
              (String.Internal.append
                declaration.name
                (String.Internal.append
                  "("
                  (String.Internal.append
                    (psJsJoin ", " parameters)
                    (String.Internal.append
                      ") { return "
                      (String.Internal.append body "; }\n")))))

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
                (String.Internal.append
                  printed
                  printedRest)

def psJsPrintModule
    (module : PsJsIrModule) :
    Except PsJsEmitError String :=
  match psJsPrintDeclarations module.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations =>
      Except.ok
        (String.Internal.append
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
