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

def psJsPrintMachineIntegerLiteral
    (type : PsJsIrMachineIntegerType)
    (value : Int) : String :=
  let printed : String :=
    String.Internal.append (Int.repr value) "n";
  match type with
  | PsJsIrMachineIntegerType.uint8 =>
      psJsJoin "" ["Number(BigInt.asUintN(8, ", printed, "))"]
  | PsJsIrMachineIntegerType.uint16 =>
      psJsJoin "" ["Number(BigInt.asUintN(16, ", printed, "))"]
  | PsJsIrMachineIntegerType.uint32 =>
      psJsJoin "" ["Number(BigInt.asUintN(32, ", printed, "))"]
  | PsJsIrMachineIntegerType.uint64 =>
      psJsJoin "" ["BigInt.asUintN(64, ", printed, ")"]
  | PsJsIrMachineIntegerType.int8 =>
      psJsJoin "" ["Number(BigInt.asIntN(8, ", printed, "))"]
  | PsJsIrMachineIntegerType.int16 =>
      psJsJoin "" ["Number(BigInt.asIntN(16, ", printed, "))"]
  | PsJsIrMachineIntegerType.int32 =>
      psJsJoin "" ["Number(BigInt.asIntN(32, ", printed, "))"]
  | PsJsIrMachineIntegerType.int64 =>
      psJsJoin "" ["BigInt.asIntN(64, ", printed, ")"]

def psJsNormalizeMachineInteger
    (type : PsJsIrMachineIntegerType)
    (value : String) : String :=
  match type with
  | PsJsIrMachineIntegerType.uint8 =>
      psJsJoin "" ["((", value, ") & 255)"]
  | PsJsIrMachineIntegerType.uint16 =>
      psJsJoin "" ["((", value, ") & 65535)"]
  | PsJsIrMachineIntegerType.uint32 =>
      psJsJoin "" ["((", value, ") >>> 0)"]
  | PsJsIrMachineIntegerType.uint64 =>
      psJsJoin "" ["BigInt.asUintN(64, (", value, "))"]
  | PsJsIrMachineIntegerType.int8 =>
      psJsJoin "" ["(((", value, ") << 24) >> 24)"]
  | PsJsIrMachineIntegerType.int16 =>
      psJsJoin "" ["(((", value, ") << 16) >> 16)"]
  | PsJsIrMachineIntegerType.int32 =>
      psJsJoin "" ["((", value, ") | 0)"]
  | PsJsIrMachineIntegerType.int64 =>
      psJsJoin "" ["BigInt.asIntN(64, (", value, "))"]

def psJsMachineIntegerBinaryRaw
    (type : PsJsIrMachineIntegerType)
    (operation : PsJsIrIntegerBinaryOp)
    (left right : String) : String :=
  match operation with
  | PsJsIrIntegerBinaryOp.add =>
      psJsJoin "" ["(", left, " + ", right, ")"]
  | PsJsIrIntegerBinaryOp.sub =>
      psJsJoin "" ["(", left, " - ", right, ")"]
  | PsJsIrIntegerBinaryOp.mul =>
      match type with
      | PsJsIrMachineIntegerType.uint8 =>
          psJsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | PsJsIrMachineIntegerType.uint16 =>
          psJsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | PsJsIrMachineIntegerType.uint32 =>
          psJsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | PsJsIrMachineIntegerType.int8 =>
          psJsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | PsJsIrMachineIntegerType.int16 =>
          psJsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | PsJsIrMachineIntegerType.int32 =>
          psJsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | _ =>
          psJsJoin "" ["(", left, " * ", right, ")"]
  | PsJsIrIntegerBinaryOp.bitAnd =>
      psJsJoin "" ["(", left, " & ", right, ")"]
  | PsJsIrIntegerBinaryOp.bitOr =>
      psJsJoin "" ["(", left, " | ", right, ")"]
  | PsJsIrIntegerBinaryOp.bitXor =>
      psJsJoin "" ["(", left, " ^ ", right, ")"]

def psJsPrintMachineIntegerBinary
    (type : PsJsIrMachineIntegerType)
    (operation : PsJsIrIntegerBinaryOp)
    (left right : String) : String :=
  psJsNormalizeMachineInteger
    type
    (psJsMachineIntegerBinaryRaw type operation left right)

def psJsPrintIntegerCompare
    (operation : PsJsIrIntegerCompareOp)
    (left right : String) : String :=
  match operation with
  | PsJsIrIntegerCompareOp.eq =>
      psJsJoin "" ["(", left, " === ", right, ")"]
  | PsJsIrIntegerCompareOp.ne =>
      psJsJoin "" ["(", left, " !== ", right, ")"]
  | PsJsIrIntegerCompareOp.lt =>
      psJsJoin "" ["(", left, " < ", right, ")"]
  | PsJsIrIntegerCompareOp.le =>
      psJsJoin "" ["(", left, " <= ", right, ")"]
  | PsJsIrIntegerCompareOp.gt =>
      psJsJoin "" ["(", left, " > ", right, ")"]
  | PsJsIrIntegerCompareOp.ge =>
      psJsJoin "" ["(", left, " >= ", right, ")"]

def psJsPrintFloatBinary
    (type : PsJsIrFloatingType)
    (operation : PsJsIrFloatBinaryOp)
    (left right : String) : String :=
  let raw : String :=
    match operation with
    | PsJsIrFloatBinaryOp.add =>
        psJsJoin "" ["(", left, " + ", right, ")"]
    | PsJsIrFloatBinaryOp.sub =>
        psJsJoin "" ["(", left, " - ", right, ")"]
    | PsJsIrFloatBinaryOp.mul =>
        psJsJoin "" ["(", left, " * ", right, ")"]
    | PsJsIrFloatBinaryOp.div =>
        psJsJoin "" ["(", left, " / ", right, ")"];
  match type with
  | PsJsIrFloatingType.float => raw
  | PsJsIrFloatingType.float32 =>
      psJsJoin "" ["Math.fround(", raw, ")"]

def psJsPrintFloatCompare
    (operation : PsJsIrFloatCompareOp)
    (left right : String) : String :=
  match operation with
  | PsJsIrFloatCompareOp.eq =>
      psJsJoin "" ["(", left, " === ", right, ")"]
  | PsJsIrFloatCompareOp.ne =>
      psJsJoin "" ["(", left, " !== ", right, ")"]
  | PsJsIrFloatCompareOp.lt =>
      psJsJoin "" ["(", left, " < ", right, ")"]
  | PsJsIrFloatCompareOp.le =>
      psJsJoin "" ["(", left, " <= ", right, ")"]
  | PsJsIrFloatCompareOp.gt =>
      psJsJoin "" ["(", left, " > ", right, ")"]
  | PsJsIrFloatCompareOp.ge =>
      psJsJoin "" ["(", left, " >= ", right, ")"]

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
  | PsJsIrLiteral.machineInteger type value =>
      psJsPrintMachineIntegerLiteral type value
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
  | PsJsIrBinaryOp.machineInt type integerOperation =>
      psJsPrintMachineIntegerBinary
        type integerOperation left right
  | PsJsIrBinaryOp.machineIntCompare integerOperation =>
      psJsPrintIntegerCompare integerOperation left right
  | PsJsIrBinaryOp.floatBinary type floatOperation =>
      psJsPrintFloatBinary type floatOperation left right
  | PsJsIrBinaryOp.floatCompare floatOperation =>
      psJsPrintFloatCompare floatOperation left right

def psJsRuntimeUnary
    (operation : PsJsIrRuntimeOp)
    (value : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.uint8OfNat =>
      Except.ok
        (psJsJoin
          ""
          ["Number(BigInt.asUintN(8, ", value, "))"])
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
  | PsJsIrRuntimeOp.stringUtf8ByteSize =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_s) => { let __ps_n = 0n; for (const __ps_c of __ps_s) { ",
            "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ",
            "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : __ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ",
            "__ps_n += __ps_w; } return __ps_n; })(",
            value,
            ")"
          ])
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
  | PsJsIrRuntimeOp.stringNext =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_s, __ps_p) => { let __ps_i = 0n; for (const __ps_c of __ps_s) { ",
            "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ",
            "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : __ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ",
            "if (__ps_i === __ps_p) return __ps_p + __ps_w; ",
            "if (__ps_i > __ps_p) return __ps_p + 1n; ",
            "__ps_i += __ps_w; } return __ps_p + 1n; })(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.stringGet =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_s, __ps_p) => { let __ps_i = 0n; for (const __ps_c of __ps_s) { ",
            "if (__ps_i === __ps_p) return __ps_c; ",
            "if (__ps_i > __ps_p) return \"A\"; ",
            "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ",
            "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : __ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ",
            "__ps_i += __ps_w; } return \"A\"; })(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.stringAtEnd =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_s, __ps_p) => { let __ps_n = 0n; for (const __ps_c of __ps_s) { ",
            "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ",
            "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : __ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ",
            "__ps_n += __ps_w; } return __ps_p >= __ps_n; })(",
            left,
            ", ",
            right,
            ")"
          ])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsRuntimeTernary
    (operation : PsJsIrRuntimeOp)
    (first second third : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.stringExtract =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_s, __ps_b, __ps_e) => { if (__ps_b >= __ps_e) return \"\"; ",
            "let __ps_i = 0n; let __ps_started = false; let __ps_out = \"\"; ",
            "for (const __ps_c of __ps_s) { ",
            "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ",
            "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : __ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ",
            "if (!__ps_started) { if (__ps_i === __ps_b) __ps_started = true; ",
            "else { __ps_i += __ps_w; continue; } } ",
            "if (__ps_i === __ps_e) return __ps_out; ",
            "__ps_out += __ps_c; __ps_i += __ps_w; } return __ps_out; })(",
            first,
            ", ",
            second,
            ", ",
            third,
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
          | List.cons third finalTail =>
              match finalTail with
              | List.nil =>
                  psJsRuntimeTernary
                    operation first second third
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
