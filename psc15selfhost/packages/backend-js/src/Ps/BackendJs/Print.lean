import Ps.BackendJs.Lower
import Ps.Bridge.Json
import Ps.Foundation.List
import Ps.Foundation.Name

inductive PsJsEmitError where
  | lower (error : PsJsLowerError)
  | fuelExhausted
  | malformedIr

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

def psJsPrintUnary
    (operation : PsJsIrUnaryOp)
    (value : String) : String :=
  match operation with
  | PsJsIrUnaryOp.bigintNeg =>
      psJsJoin "" ["(-(", value, "))"]
  | PsJsIrUnaryOp.boolNot =>
      psJsJoin "" ["(!", value, ")"]

def psJsPrintBinary
    (operation : PsJsIrBinaryOp)
    (left right : String) : String :=
  match operation with
  | PsJsIrBinaryOp.bigintAdd =>
      psJsJoin "" ["(", left, " + ", right, ")"]
  | PsJsIrBinaryOp.bigintSub =>
      psJsJoin "" ["(", left, " - ", right, ")"]
  | PsJsIrBinaryOp.bigintMul =>
      psJsJoin "" ["(", left, " * ", right, ")"]
  | PsJsIrBinaryOp.bigintEq =>
      psJsJoin "" ["(", left, " === ", right, ")"]
  | PsJsIrBinaryOp.bigintNe =>
      psJsJoin "" ["(", left, " !== ", right, ")"]
  | PsJsIrBinaryOp.bigintLe =>
      psJsJoin "" ["(", left, " <= ", right, ")"]
  | PsJsIrBinaryOp.bigintLt =>
      psJsJoin "" ["(", left, " < ", right, ")"]
  | PsJsIrBinaryOp.boolAnd =>
      psJsJoin "" ["(", left, " && ", right, ")"]
  | PsJsIrBinaryOp.boolOr =>
      psJsJoin "" ["(", left, " || ", right, ")"]
  | PsJsIrBinaryOp.boolEq =>
      psJsJoin "" ["(", left, " === ", right, ")"]
  | PsJsIrBinaryOp.boolNe =>
      psJsJoin "" ["(", left, " !== ", right, ")"]
  | PsJsIrBinaryOp.stringConcat =>
      psJsJoin "" ["(", left, " + ", right, ")"]
  | PsJsIrBinaryOp.stringEq =>
      psJsJoin "" ["(", left, " === ", right, ")"]

def psJsRuntimeUnary
    (operation : PsJsIrRuntimeOp)
    (value : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.intNegSucc =>
      Except.ok
        (psJsJoin "" ["(-(", value, " + 1n))"])
  | PsJsIrRuntimeOp.intRepr =>
      Except.ok
        (psJsJoin "" ["(", value, ").toString()"])
  | PsJsIrRuntimeOp.charOfNat =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_n) => ((__ps_n < 0xd800n || (__ps_n > 0xdfffn && __ps_n < 0x110000n)) ",
            "? String.fromCodePoint(Number(__ps_n)) : \"\\0\"))(",
            value,
            ")"
          ])
  | PsJsIrRuntimeOp.charToNat =>
      Except.ok
        (psJsJoin
          ""
          ["((__ps_c) => BigInt(__ps_c.codePointAt(0) ?? 0))(", value, ")"])
  | PsJsIrRuntimeOp.stringLength =>
      Except.ok
        (psJsJoin
          ""
          ["((__ps_s) => BigInt(Array.from(__ps_s).length))(", value, ")"])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsRuntimeBinary
    (operation : PsJsIrRuntimeOp)
    (left right : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.natSub =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_b) => (__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.natDiv =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_b) => (__ps_b === 0n ? 0n : __ps_a / __ps_b))(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.natMod =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_b) => (__ps_b === 0n ? __ps_a : __ps_a % __ps_b))(",
            left,
            ", ",
            right,
            ")"
          ])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsPrintRuntime
    (operation : PsJsIrRuntimeOp)
    (arguments : List String) :
    Except PsJsEmitError String :=
  match arguments with
  | List.nil =>
      Except.error PsJsEmitError.malformedIr
  | List.cons first rest =>
      match rest with
      | List.nil =>
          psJsRuntimeUnary operation first
      | List.cons second tail =>
          match tail with
          | List.nil =>
              psJsRuntimeBinary operation first second
          | List.cons _ _ =>
              Except.error PsJsEmitError.malformedIr

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
        | PsJsIrExpr.unary operation value =>
            match smaller value with
            | Except.error error => Except.error error
            | Except.ok printed =>
                Except.ok (psJsPrintUnary operation printed)
        | PsJsIrExpr.binary operation left right =>
            match smaller left with
            | Except.error error => Except.error error
            | Except.ok printedLeft =>
                match smaller right with
                | Except.error error => Except.error error
                | Except.ok printedRight =>
                    Except.ok
                      (psJsPrintBinary
                        operation
                        printedLeft
                        printedRight)
        | PsJsIrExpr.runtime operation arguments =>
            match psListMapExcept smaller arguments with
            | Except.error error => Except.error error
            | Except.ok printedArguments =>
                psJsPrintRuntime operation printedArguments
        | PsJsIrExpr.lambda parameters body =>
            match smaller body with
            | Except.error error => Except.error error
            | Except.ok printedBody =>
                Except.ok
                  (psJsJoin
                    ""
                    [
                      "((",
                      psJsJoin ", " parameters,
                      ") => ",
                      printedBody,
                      ")"
                    ])
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
        | PsJsIrExpr.letE name value body =>
            match smaller value with
            | Except.error error => Except.error error
            | Except.ok printedValue =>
                match smaller body with
                | Except.error error => Except.error error
                | Except.ok printedBody =>
                    Except.ok
                      (psJsJoin
                        ""
                        [
                          "(() => { const ",
                          name,
                          " = ",
                          printedValue,
                          "; return ",
                          printedBody,
                          "; })()"
                        ])
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
