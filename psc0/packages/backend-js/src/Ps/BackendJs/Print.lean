import Ps.BackendJs.Lower
import Ps.BackendJs.Validate
import Ps.BackendJs.TailAlias
import Ps.Bridge.Json
import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.Foundation.Text

inductive PsJsEmitError where
  | lower (error : PsJsLowerError)
  | targetValidation (error : PsJsIrValidationError)
  | fuelExhausted
  | malformedIr

def psJsJoin
    (separator : String)
    (values : List String) : String :=
  psTextJoin separator values


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
      Except.ok (psJsJoin "" ["__ps$utf8(", value, ").size"])
  | PsJsIrRuntimeOp.arrayEmptyWithCapacity =>
      Except.ok
        (psJsJoin
          ""
          ["(() => { void (", value, "); return []; })()"])
  | PsJsIrRuntimeOp.arraySize =>
      Except.ok
        (psJsJoin
          ""
          ["BigInt((", value, ").length)"])
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
      Except.ok (psJsJoin ""
        ["((__ps_s, __ps_p) => __ps_p + (__ps$utf8(__ps_s).entries.get(__ps_p)?.[1] ?? 1n))(",
         left, ", ", right, ")"])
  | PsJsIrRuntimeOp.stringGet =>
      Except.ok (psJsJoin ""
        ["((__ps_s, __ps_p) => __ps$utf8(__ps_s).entries.get(__ps_p)?.[0] ?? \"A\")(",
         left, ", ", right, ")"])
  | PsJsIrRuntimeOp.stringAtEnd =>
      Except.ok (psJsJoin ""
        ["((__ps_s, __ps_p) => __ps_p >= __ps$utf8(__ps_s).size)(",
         left, ", ", right, ")"])
  | PsJsIrRuntimeOp.arrayPush =>
      Except.ok
        (psJsJoin
          ""
          ["[...(", left, "), ", right, "]"])
  | PsJsIrRuntimeOp.arrayGet =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i) => __ps_a[Number(__ps_i)])(",
            left,
            ", ",
            right,
            ")"
          ])
  | PsJsIrRuntimeOp.arrayMap =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_f, __ps_a) => __ps_a.map((__ps_x) => __ps_f(__ps_x)))(",
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
  | PsJsIrRuntimeOp.arrayGetD =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i, __ps_fallback) => (__ps_i < BigInt(__ps_a.length) ? ",
            "__ps_a[Number(__ps_i)] : __ps_fallback))(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | PsJsIrRuntimeOp.arraySet =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i, __ps_v) => { const __ps_out = [...__ps_a]; ",
            "__ps_out[Number(__ps_i)] = __ps_v; return __ps_out; })(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | PsJsIrRuntimeOp.arraySetIfInBounds =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_a, __ps_i, __ps_v) => { if (__ps_i >= BigInt(__ps_a.length)) return __ps_a; ",
            "const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; ",
            "return __ps_out; })(",
            first,
            ", ",
            second,
            ", ",
            third,
            ")"
          ])
  | _ =>
      Except.error PsJsEmitError.malformedIr

def psJsRuntimeFive
    (operation : PsJsIrRuntimeOp)
    (first second third fourth fifth : String) :
    Except PsJsEmitError String :=
  match operation with
  | PsJsIrRuntimeOp.arrayFoldl =>
      Except.ok
        (psJsJoin
          ""
          [
            "((__ps_f, __ps_init, __ps_a, __ps_start, __ps_stop) => { ",
            "const __ps_size = BigInt(__ps_a.length); ",
            "const __ps_end = __ps_stop <= __ps_size ? __ps_stop : __ps_size; ",
            "let __ps_acc = __ps_init; ",
            "for (let __ps_i = __ps_start; __ps_i < __ps_end; __ps_i += 1n) { ",
            "__ps_acc = __ps_f(__ps_acc, __ps_a[Number(__ps_i)]); } ",
            "return __ps_acc; })(",
            first,
            ", ",
            second,
            ", ",
            third,
            ", ",
            fourth,
            ", ",
            fifth,
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
              | List.cons fourth afterFourth =>
                  match afterFourth with
                  | List.nil =>
                      Except.error PsJsEmitError.malformedIr
                  | List.cons fifth finalTail =>
                      match finalTail with
                      | List.nil =>
                          psJsRuntimeFive
                            operation
                            first
                            second
                            third
                            fourth
                            fifth
                      | List.cons _ _ =>
                          Except.error PsJsEmitError.malformedIr

def psJsExprUsesNameWithFuel
    (fuel : Nat) :
    PsJsIrExpr -> String -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsJsIrExpr) (_name : String) => true
  | Nat.succ remaining =>
      let smaller : PsJsIrExpr -> String -> Bool :=
        psJsExprUsesNameWithFuel remaining;
      fun (expr : PsJsIrExpr) (name : String) =>
        let uses : PsJsIrExpr -> Bool :=
          fun (value : PsJsIrExpr) =>
            smaller value name;
        let nameUses : String -> Bool :=
          fun (value : String) =>
            psStringEq value name;
        let fieldUses :
            (String × PsJsIrExpr) -> Bool :=
          fun (field : String × PsJsIrExpr) =>
            uses (Prod.snd field);
        let bindingUses :
            PsJsIrMatchBinding -> Bool :=
          fun (binding : PsJsIrMatchBinding) =>
            psStringEq binding.name name;
        let alternativeUses :
            (String ×
              List PsJsIrMatchBinding ×
              PsJsIrExpr) -> Bool :=
          fun
            (alternative :
              String ×
                List PsJsIrMatchBinding ×
                PsJsIrExpr) =>
            let detail := Prod.snd alternative;
            if psListAny bindingUses (Prod.fst detail) then
              true
            else
              uses (Prod.snd detail);
        match expr with
        | PsJsIrExpr.literal _ => false
        | PsJsIrExpr.var value =>
            psStringEq value name
        | PsJsIrExpr.unary _ value =>
            uses value
        | PsJsIrExpr.binary _ left right =>
            if uses left then true else uses right
        | PsJsIrExpr.runtime _ arguments =>
            psListAny uses arguments
        | PsJsIrExpr.lambda parameters body =>
            if psListAny nameUses parameters then
              true
            else
              uses body
        | PsJsIrExpr.call fn arguments =>
            if uses fn then true else psListAny uses arguments
        | PsJsIrExpr.letE localName value body =>
            if psStringEq localName name then
              true
            else if uses value then
              true
            else
              uses body
        | PsJsIrExpr.ifE condition thenBranch elseBranch =>
            if uses condition then
              true
            else if uses thenBranch then
              true
            else
              uses elseBranch
        | PsJsIrExpr.record fields =>
            psListAny fieldUses fields
        | PsJsIrExpr.projection target _ =>
            uses target
        | PsJsIrExpr.constructor _ fields =>
            psListAny fieldUses fields
        | PsJsIrExpr.matchE scrutinee alternatives =>
            if uses scrutinee then
              true
            else
              psListAny alternativeUses alternatives

def psJsFreshMatchTempWorker
    (expr : PsJsIrExpr)
    (attempts : Nat) :
    Nat -> String :=
  match attempts with
  | Nat.zero =>
      fun (_index : Nat) => "__ps$match$overflow"
  | Nat.succ remaining =>
      let smaller : Nat -> String :=
        psJsFreshMatchTempWorker expr remaining;
      fun (index : Nat) =>
        let candidate : String :=
          String.Internal.append
            "__ps$match$"
            (psNatToString index);
        if psJsExprUsesNameWithFuel 4096 expr candidate then
          smaller (Nat.succ index)
        else
          candidate

def psJsFreshMatchTemp
    (expr : PsJsIrExpr) : String :=
  psJsFreshMatchTempWorker expr 4096 0

def psJsFreshTailMatchTempWorker
    (expr : PsJsIrExpr)
    (attempts : Nat) :
    Nat -> String :=
  match attempts with
  | Nat.zero =>
      fun (index : Nat) =>
        psJsConcat2
          "__ps$tail$match$"
          (psNatToString index)
  | Nat.succ remaining =>
      let smaller : Nat -> String :=
        psJsFreshTailMatchTempWorker expr remaining;
      fun (index : Nat) =>
        let candidate : String :=
          psJsConcat2
            "__ps$tail$match$"
            (psNatToString index);
        if psJsExprUsesNameWithFuel 4096 expr candidate then
          smaller (Nat.succ index)
        else
          candidate

def psJsFreshTailMatchTemp
    (expr : PsJsIrExpr)
    (depth : Nat) : String :=
  psJsFreshTailMatchTempWorker expr 4096 depth

def psJsPrintFieldWith
    (print : PsJsIrExpr -> Except PsJsEmitError String)
    (field : String × PsJsIrExpr) :
    Except PsJsEmitError String :=
  match field with
  | Prod.mk name value =>
      match print value with
      | Except.error error => Except.error error
      | Except.ok printedValue =>
          Except.ok
            (psJsJoin
              ""
              [
                "[",
                psJsonQuote name,
                "]: ",
                printedValue
              ])

def psJsPrintFieldsWith
    (print : PsJsIrExpr -> Except PsJsEmitError String)
    (fields : List (String × PsJsIrExpr)) :
    Except PsJsEmitError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match psJsPrintFieldWith print field with
      | Except.error error => Except.error error
      | Except.ok printedField =>
          match psJsPrintFieldsWith print rest with
          | Except.error error => Except.error error
          | Except.ok printedRest =>
              Except.ok
                (List.cons printedField printedRest)

def psJsPrintMatchBinding
    (temp : String)
    (binding : PsJsIrMatchBinding) : String :=
  psJsJoin
    ""
    [
      "const ",
      binding.name,
      " = ",
      temp,
      "[\"$ps$fields\"][",
      psJsonQuote binding.field,
      "];"
    ]

def psJsPrintMatchBindings
    (temp : String)
    (bindings : List PsJsIrMatchBinding) :
    List String :=
  match bindings with
  | List.nil => List.nil
  | List.cons binding rest =>
      List.cons
        (psJsPrintMatchBinding temp binding)
        (psJsPrintMatchBindings temp rest)

def psJsPrintMatchAlternativeWith
    (print : PsJsIrExpr -> Except PsJsEmitError String)
    (temp : String)
    (alternative :
      String ×
        List PsJsIrMatchBinding ×
        PsJsIrExpr) :
    Except PsJsEmitError String :=
  let constructorName : String :=
    Prod.fst alternative;
  let detail :
      List PsJsIrMatchBinding × PsJsIrExpr :=
    Prod.snd alternative;
  let bindings : List PsJsIrMatchBinding :=
    Prod.fst detail;
  let body : PsJsIrExpr :=
    Prod.snd detail;
  match print body with
  | Except.error error => Except.error error
  | Except.ok printedBody =>
      let printedBindings : List String :=
        psJsPrintMatchBindings temp bindings;
      let bindingSeparator : String :=
        if psListIsEmpty printedBindings then "" else " ";
      Except.ok
        (psJsJoin
          ""
          [
            "case ",
            psJsonQuote constructorName,
            ": { ",
            psJsJoin " " printedBindings,
            bindingSeparator,
            "return ",
            printedBody,
            "; }"
          ])

def psJsPrintMatchAlternativesWith
    (print : PsJsIrExpr -> Except PsJsEmitError String)
    (temp : String)
    (alternatives :
      List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :
    Except PsJsEmitError (List String) :=
  match alternatives with
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      match
          psJsPrintMatchAlternativeWith
            print temp alternative with
      | Except.error error => Except.error error
      | Except.ok printedAlternative =>
          match
              psJsPrintMatchAlternativesWith
                print temp rest with
          | Except.error error => Except.error error
          | Except.ok printedRest =>
              Except.ok
                (List.cons
                  printedAlternative
                  printedRest)

def psJsPrintExprWithModeAndFuel
    (stackTarget : Option String)
    (fuel : Nat) :
    PsJsIrExpr -> Except PsJsEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsJsIrExpr) =>
        Except.error PsJsEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          PsJsIrExpr -> Except PsJsEmitError String :=
        psJsPrintExprWithModeAndFuel stackTarget remaining;
      fun (expr : PsJsIrExpr) =>
        let stackContext : Bool :=
          match stackTarget with
          | Option.none => false
          | Option.some _ => true;
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
                if stackContext then
                  Except.ok
                    (psJsJoin
                      ""
                      [
                        "__ps$wrap(function*(",
                        psJsJoin ", " parameters,
                        ") { return ",
                        printedBody,
                        "; })"
                      ])
                else
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
                    if stackContext then
                      let suffix : String :=
                        if psListIsEmpty printedArguments then
                          ""
                        else
                          psJsConcat2
                            ", "
                            (psJsJoin ", " printedArguments);
                      Except.ok
                        (psJsJoin
                          ""
                          [
                            "(yield* __ps$invoke(",
                            printedFn,
                            suffix,
                            "))"
                          ])
                    else
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
                    if stackContext then
                      Except.ok
                        (psJsJoin
                          ""
                          [
                            "(yield* (function*(",
                            name,
                            ") { return ",
                            printedBody,
                            "; })(", printedValue, "))"
                          ])
                    else
                      Except.ok
                        (psJsJoin
                          ""
                          [
                            "((",
                            name,
                            ") => ",
                            printedBody,
                            ")(", printedValue, ")"
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
        | PsJsIrExpr.record fields =>
            match psJsPrintFieldsWith smaller fields with
            | Except.error error => Except.error error
            | Except.ok printedFields =>
                Except.ok
                  (psJsJoin
                    ""
                    [
                      "({ ",
                      psJsJoin ", " printedFields,
                      " })"
                    ])
        | PsJsIrExpr.projection target field =>
            match smaller target with
            | Except.error error => Except.error error
            | Except.ok printedTarget =>
                Except.ok
                  (psJsJoin
                    ""
                    [
                      "(",
                      printedTarget,
                      ")[",
                      psJsonQuote field,
                      "]"
                    ])
        | PsJsIrExpr.constructor constructorName fields =>
            match psJsPrintFieldsWith smaller fields with
            | Except.error error => Except.error error
            | Except.ok printedFields =>
                let payload : String :=
                  psJsJoin
                    ""
                    [
                      "{ ",
                      psJsJoin ", " printedFields,
                      " }"
                    ];
                Except.ok
                  (psJsJoin
                    ""
                    [
                      "({ \"$ps$tag\": ",
                      psJsonQuote constructorName,
                      ", \"$ps$fields\": ",
                      payload,
                      " })"
                    ])
        | PsJsIrExpr.matchE scrutinee alternatives =>
            match smaller scrutinee with
            | Except.error error => Except.error error
            | Except.ok printedScrutinee =>
                let temp : String :=
                  psJsFreshMatchTemp expr;
                match
                    psJsPrintMatchAlternativesWith
                      smaller
                      temp
                      alternatives with
                | Except.error error => Except.error error
                | Except.ok printedAlternatives =>
                    if stackContext then
                      Except.ok
                        (psJsJoin
                          ""
                          [
                            "(yield* (function*() { const ",
                            temp,
                            " = ",
                            printedScrutinee,
                            "; switch (",
                            temp,
                            "[\"$ps$tag\"]) { ",
                            psJsJoin " " printedAlternatives,
                            " } throw new Error(\"invalid ProofScript constructor tag\"); })())"
                          ])
                    else
                      Except.ok
                        (psJsJoin
                          ""
                          [
                            "((",
                            temp,
                            ") => { switch (",
                            temp,
                            "[\"$ps$tag\"]) { ",
                            psJsJoin " " printedAlternatives,
                            " } throw new Error(\"invalid ProofScript constructor tag\"); })(",
                            printedScrutinee,
                            ")"
                          ])

def psJsPrintExpr
    (expr : PsJsIrExpr) :
    Except PsJsEmitError String :=
  psJsPrintExprWithModeAndFuel Option.none 4096 expr

def psJsPrintExprStackSafe
    (recursiveName : String)
    (expr : PsJsIrExpr) :
    Except PsJsEmitError String :=
  psJsPrintExprWithModeAndFuel
    (Option.some recursiveName)
    4096
    expr

def psJsPrintImport
    (importInfo : PsJsIrImport) : String :=
  let alias : String :=
    if psStringEq importInfo.importedName importInfo.localName then
      ""
    else
      String.Internal.append
        " as "
        importInfo.localName;
  psJsJoin
    ""
    [
      "import { ",
      importInfo.importedName,
      alias,
      " } from ",
      psJsonQuote importInfo.source,
      ";\n"
    ]

def psJsPrintImports
    (imports : List PsJsIrImport) : String :=
  psTextJoin "" (psListMap psJsPrintImport imports)


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

-- Generated coordinates are separate from parser positions: UTF-8 byte
-- offsets plus zero-based ECMAScript lines and UTF-16 columns.
structure PsJsGeneratedPosition where
  byteOffset : Nat
  line : Nat
  column : Nat
  previousCR : Bool

def psJsGeneratedPositionZero : PsJsGeneratedPosition :=
  PsJsGeneratedPosition.mk 0 0 0 false

def psJsAdvanceGeneratedChar
    (position : PsJsGeneratedPosition)
    (char : Char)
    (byteWidth : Nat) : PsJsGeneratedPosition :=
  let codePoint : Nat := Char.toNat char;
  let nextByte : Nat := Nat.add position.byteOffset byteWidth;
  if Nat.beq codePoint 10 then
    if position.previousCR then
      PsJsGeneratedPosition.mk nextByte position.line 0 false
    else
      PsJsGeneratedPosition.mk nextByte (Nat.succ position.line) 0 false
  else if Nat.beq codePoint 13 then
    PsJsGeneratedPosition.mk nextByte (Nat.succ position.line) 0 true
  else if Nat.beq codePoint 8232 then
    PsJsGeneratedPosition.mk nextByte (Nat.succ position.line) 0 false
  else if Nat.beq codePoint 8233 then
    PsJsGeneratedPosition.mk nextByte (Nat.succ position.line) 0 false
  else if Nat.ble codePoint 65535 then
    PsJsGeneratedPosition.mk nextByte position.line (Nat.succ position.column) false
  else
    PsJsGeneratedPosition.mk nextByte position.line (Nat.add position.column 2) false

def psJsAdvanceGeneratedTextWorker
    (fuel : Nat) :
    String -> Nat -> PsJsGeneratedPosition ->
    Except PsJsEmitError PsJsGeneratedPosition :=
  match fuel with
  | Nat.zero =>
      fun (text : String) (offset : Nat) (position : PsJsGeneratedPosition) =>
        if String.Internal.atEnd text (String.Pos.Raw.mk offset) then Except.ok position
        else Except.error PsJsEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> PsJsGeneratedPosition ->
          Except PsJsEmitError PsJsGeneratedPosition :=
        psJsAdvanceGeneratedTextWorker remaining;
      fun (text : String) (offset : Nat) (position : PsJsGeneratedPosition) =>
        if String.Internal.atEnd text (String.Pos.Raw.mk offset) then Except.ok position
        else
          let char : Char := String.Internal.get text (String.Pos.Raw.mk offset);
          let next : Nat := String.Pos.Raw.byteIdx
            (String.Internal.next text (String.Pos.Raw.mk offset));
          smaller text next (psJsAdvanceGeneratedChar position char (Nat.sub next offset))

def psJsAdvanceGeneratedText
    (position : PsJsGeneratedPosition)
    (text : String) : Except PsJsEmitError PsJsGeneratedPosition :=
  psJsAdvanceGeneratedTextWorker (Nat.succ (String.utf8ByteSize text)) text 0 position

structure PsJsGeneratedDeclarationSpan where
  name : String
  start : PsJsGeneratedPosition
  stop : PsJsGeneratedPosition

structure PsJsPrintedModule where
  text : String
  spans : List PsJsGeneratedDeclarationSpan

def psJsEncodeGeneratedPosition (position : PsJsGeneratedPosition) : String :=
  psJsonArray [
    psNatToString position.byteOffset,
    psNatToString position.line,
    psNatToString position.column
  ]

def psJsEncodeGeneratedSpan (span : PsJsGeneratedDeclarationSpan) : String :=
  psJsonArray [
    psJsonQuote span.name,
    psJsEncodeGeneratedPosition span.start,
    psJsEncodeGeneratedPosition span.stop
  ]

def psJsEncodeGeneratedPositions (spans : List PsJsGeneratedDeclarationSpan) : String :=
  psJsonArray [
    psJsonQuote "psc-js-generated-positions/1",
    psJsonQuote "declaration-emission-chunk",
    psJsonArray (psListMap psJsEncodeGeneratedSpan spans)
  ]

-- One actual printing fold. Legacy callers collect no spans and do not scan
-- text for coordinates. Observed callers measure each actual chunk once.
def psJsPrintDeclarationsObservedWith
    (print : PsJsIrDeclaration -> Except PsJsEmitError String)
    (declarations : List PsJsIrDeclaration) :
    Bool -> PsTextBuilder -> PsJsGeneratedPosition ->
    List PsJsGeneratedDeclarationSpan -> Except PsJsEmitError PsJsPrintedModule :=
  match declarations with
  | List.nil =>
      fun (_observe : Bool) (builder : PsTextBuilder)
          (_position : PsJsGeneratedPosition) (spansRev : List PsJsGeneratedDeclarationSpan) =>
        Except.ok
          (PsJsPrintedModule.mk (psTextBuilderFinish builder) (psListReverse spansRev))
  | List.cons declaration rest =>
      let smaller :
          Bool -> PsTextBuilder -> PsJsGeneratedPosition ->
          List PsJsGeneratedDeclarationSpan -> Except PsJsEmitError PsJsPrintedModule :=
        psJsPrintDeclarationsObservedWith print rest;
      fun (observe : Bool) (builder : PsTextBuilder)
          (position : PsJsGeneratedPosition) (spansRev : List PsJsGeneratedDeclarationSpan) =>
        match print declaration with
        | Except.error error => Except.error error
        | Except.ok printed =>
            let nextBuilder : PsTextBuilder := psTextBuilderAppend builder printed;
            if observe then
              match psJsAdvanceGeneratedText position printed with
              | Except.error error => Except.error error
              | Except.ok nextPosition =>
                  smaller true nextBuilder nextPosition
                    (List.cons
                      (PsJsGeneratedDeclarationSpan.mk declaration.name position nextPosition)
                      spansRev)
            else smaller false nextBuilder position spansRev

def psJsPrintDeclarationsWith
    (print : PsJsIrDeclaration -> Except PsJsEmitError String)
    (declarations : List PsJsIrDeclaration) :
    PsTextBuilder -> Except PsJsEmitError String :=
  fun (builder : PsTextBuilder) =>
    match
        psJsPrintDeclarationsObservedWith print declarations
          false builder psJsGeneratedPositionZero List.nil with
    | Except.error error => Except.error error
    | Except.ok product => Except.ok product.text

def psJsPrintDeclarations
    (declarations : List PsJsIrDeclaration) :
    Except PsJsEmitError String :=
  psJsPrintDeclarationsWith
    psJsPrintDeclaration declarations psTextBuilderEmpty


def psJsStringRuntimeSupport : String :=
  "let __ps$utf8Cache;\nfunction __ps$utf8(source) { if (__ps$utf8Cache?.source === source) return __ps$utf8Cache; const entries = new Map(); let size = 0n; for (const char of source) { const cp = char.codePointAt(0) ?? 0; const width = BigInt(cp <= 0x7f ? 1 : cp <= 0x7ff ? 2 : cp <= 0xffff ? 3 : 4); entries.set(size, [char, width]); size += width; } return (__ps$utf8Cache = { source, entries, size }); }\n"

def psJsStackRuntimeSupport : String :=
  psJsJoin
    ""
    [
      "const __ps$implementations = new WeakMap();\n",
      "function __ps$run(root) { const pending = [root]; let value = undefined; while (pending.length !== 0) { const next = pending[pending.length - 1].next(value); if (next.done) { pending.pop(); value = next.value; } else { const { fn, args } = next.value; const implementation = __ps$implementations.get(fn); if (implementation) { pending.push(Reflect.apply(implementation, undefined, args)); value = undefined; } else { value = Reflect.apply(fn, undefined, args); } } } return value; }\n",
      "function __ps$wrap(implementation) { const fn = (...args) => __ps$run(implementation(...args)); __ps$implementations.set(fn, implementation); return fn; }\n",
      "function* __ps$invoke(fn, ...args) { const implementation = __ps$implementations.get(fn); if (implementation) return (yield { fn, args }); return fn(...args); }\n"
    ]

def psJsImplementationName
    (name : String) : String :=
  psJsConcat2 "__ps$impl$" name

def psJsTailPrintNonRecursive
    (recursiveName : String)
    (expr : PsJsIrExpr) : Option String :=
  if psJsExprUsesNameWithFuel 4096 expr recursiveName then
    Option.none
  else
    match psJsPrintExpr expr with
    | Except.error _ => Option.none
    | Except.ok printed => Option.some printed

def psJsTailPrintArguments
    (recursiveName : String)
    (arguments : List PsJsIrExpr) :
    Option (List String) :=
  match arguments with
  | List.nil => Option.some List.nil
  | List.cons argument rest =>
      let smaller : Option (List String) :=
        psJsTailPrintArguments recursiveName rest;
      match
          psJsTailPrintNonRecursive
            recursiveName
            argument with
      | Option.none => Option.none
      | Option.some printed =>
          match smaller with
          | Option.none => Option.none
          | Option.some printedRest =>
              Option.some
                (List.cons printed printedRest)

def psJsTailParameterNames
    (parameters : List PsJsIrParameter) : List String :=
  psListMap psJsParameterName parameters

def psJsTailBindingsShadow
    (recursiveName : String)
    (bindings : List PsJsIrMatchBinding) : Bool :=
  let shadows : PsJsIrMatchBinding -> Bool :=
    fun (binding : PsJsIrMatchBinding) =>
      psStringEq binding.name recursiveName;
  psListAny shadows bindings

def psJsTailPrintAlternativeWith
    (emit : PsJsIrExpr -> Option String)
    (recursiveName temp : String)
    (alternative :
      String ×
        List PsJsIrMatchBinding ×
        PsJsIrExpr) : Option String :=
  let constructorName : String :=
    Prod.fst alternative;
  let detail :
      List PsJsIrMatchBinding × PsJsIrExpr :=
    Prod.snd alternative;
  let bindings : List PsJsIrMatchBinding :=
    Prod.fst detail;
  let body : PsJsIrExpr :=
    Prod.snd detail;
  if psJsTailBindingsShadow recursiveName bindings then
    Option.none
  else
    match emit body with
    | Option.none => Option.none
    | Option.some printedBody =>
        let printedBindings : List String :=
          psJsPrintMatchBindings temp bindings;
        let separator : String :=
          if psListIsEmpty printedBindings then "" else " ";
        Option.some
          (psJsJoin
            ""
            [
              "case ",
              psJsonQuote constructorName,
              ": { ",
              psJsJoin " " printedBindings,
              separator,
              printedBody,
              " }"
            ])

def psJsTailPrintAlternativesWith
    (emit : PsJsIrExpr -> Option String)
    (recursiveName temp : String)
    (alternatives :
      List
        (String ×
          List PsJsIrMatchBinding ×
          PsJsIrExpr)) :
    Option (List String) :=
  match alternatives with
  | List.nil => Option.some List.nil
  | List.cons alternative rest =>
      let smaller : Option (List String) :=
        psJsTailPrintAlternativesWith
          emit
          recursiveName
          temp
          rest;
      match
          psJsTailPrintAlternativeWith
            emit
            recursiveName
            temp
            alternative with
      | Option.none => Option.none
      | Option.some printed =>
          match smaller with
          | Option.none => Option.none
          | Option.some printedRest =>
              Option.some
                (List.cons printed printedRest)

def psJsTailEmitWithFuel
    (declaration : PsJsIrDeclaration)
    (available : String -> Bool)
    (fuel : Nat) :
    Nat -> PsJsIrExpr -> Option String :=
  match fuel with
  | Nat.zero =>
      fun (_matchDepth : Nat) (_expr : PsJsIrExpr) =>
        Option.none
  | Nat.succ remaining =>
      let smaller :
          Nat -> PsJsIrExpr -> Option String :=
        psJsTailEmitWithFuel
          declaration
          available
          remaining;
      fun (matchDepth : Nat) (expr : PsJsIrExpr) =>
        let sameDepth : PsJsIrExpr -> Option String :=
          smaller matchDepth;
        let nested : PsJsIrExpr -> Option String :=
          smaller (Nat.succ matchDepth);
        match expr with
        | PsJsIrExpr.call fn arguments =>
            match fn with
            | PsJsIrExpr.var name =>
                if psStringEq name declaration.name then
                  if
                      Nat.beq
                        (psListLength declaration.parameters)
                        (psListLength arguments) then
                    match
                        psJsTailPrintArguments
                          declaration.name
                          arguments with
                    | Option.none => Option.none
                    | Option.some printedArguments =>
                        Option.some
                          (psJsJoin
                            ""
                            [
                              "__ps$tail$state = [",
                              psJsJoin ", " printedArguments,
                              "]; continue;"
                            ])
                  else
                    Option.none
                else
                  match
                      psJsTailPrintNonRecursive
                        declaration.name
                        expr with
                  | Option.none => Option.none
                  | Option.some printed =>
                      Option.some
                        (psJsConcat3
                          "return "
                          printed
                          ";")
            | _ =>
                match
                    psJsTailPrintNonRecursive
                      declaration.name
                      expr with
                | Option.none => Option.none
                | Option.some printed =>
                    Option.some
                      (psJsConcat3
                        "return "
                        printed
                        ";")
        | PsJsIrExpr.letE name value body =>
            if psStringEq name declaration.name then
              Option.none
            else
              match
                  psJsTailPrintNonRecursive
                    declaration.name
                    value with
              | Option.none => Option.none
              | Option.some printedValue =>
                  match sameDepth body with
                  | Option.none => Option.none
                  | Option.some printedBody =>
                      let temp := String.Internal.append "__ps$tail$value$" (psNatToString remaining);
                      if available temp then
                        Option.some
                          (psJsJoin
                            ""
                            [
                              "{ const ", temp, " = ", printedValue,
                              "; { const ", name, " = ", temp, "; ", printedBody, " } }"
                            ])
                      else Option.none
        | PsJsIrExpr.ifE condition thenBranch elseBranch =>
            match
                psJsTailPrintNonRecursive
                  declaration.name
                  condition with
            | Option.none => Option.none
            | Option.some printedCondition =>
                match sameDepth thenBranch with
                | Option.none => Option.none
                | Option.some printedThen =>
                    match sameDepth elseBranch with
                    | Option.none => Option.none
                    | Option.some printedElse =>
                        Option.some
                          (psJsJoin
                            ""
                            [
                              "if (",
                              printedCondition,
                              ") { ",
                              printedThen,
                              " } else { ",
                              printedElse,
                              " }"
                            ])
        | PsJsIrExpr.matchE scrutinee alternatives =>
            match
                psJsTailPrintNonRecursive
                  declaration.name
                  scrutinee with
            | Option.none => Option.none
            | Option.some printedScrutinee =>
                let temp : String :=
                  psJsFreshTailMatchTemp
                    expr
                    matchDepth;
                match
                    psJsTailPrintAlternativesWith
                      nested
                      declaration.name
                      temp
                      alternatives with
                | Option.none => Option.none
                | Option.some printedAlternatives =>
                    Option.some
                      (psJsJoin
                        ""
                        [
                          "const ",
                          temp,
                          " = ",
                          printedScrutinee,
                          "; switch (",
                          temp,
                          "[\"$ps$tag\"]) { ",
                          psJsJoin " " printedAlternatives,
                          " } throw new Error(\"invalid ProofScript constructor tag\");"
                        ])
        | _ =>
            match
                psJsTailPrintNonRecursive
                  declaration.name
                  expr with
            | Option.none => Option.none
            | Option.some printed =>
                Option.some
                  (psJsConcat3
                    "return "
                    printed
                    ";")

def psJsPrintTailLoop
    (declaration : PsJsIrDeclaration) : Option String :=
  match declaration.parameters with
  | List.nil => Option.none
  | List.cons _ _ =>
      let names := psJsTailParameterNames declaration.parameters;
      let uses : PsJsIrExpr -> String -> Bool := psJsExprUsesNameWithFuel 4096;
      let available : String -> Bool := fun (name : String) =>
        if psStringEq name declaration.name then false
        else if psJsTailContains names name then false
        else if uses declaration.body name then false else true;
      if uses declaration.body declaration.name then
        if available "__ps$tail$state" then
          match psJsTailRewriteWithFuel declaration uses available 4096 names List.nil declaration.body with
          | Option.none => Option.none
          | Option.some rewritten =>
              match psJsTailEmitWithFuel declaration available 4096 0 rewritten with
              | Option.none => Option.none
              | Option.some printedBody =>
                  let parameters := psJsJoin ", " names;
                  Option.some
                    (psJsJoin "" [
                      "export function ", declaration.name, "(", parameters,
                      ") { let __ps$tail$state = [", parameters,
                      "]; while (true) { const [", parameters,
                      "] = __ps$tail$state; ", printedBody, " } }\n"
                    ])
        else Option.none
      else Option.none

def psJsPrintDeclarationStackSafe
    (declaration : PsJsIrDeclaration) :
    Except PsJsEmitError String :=
  match psJsPrintTailLoop declaration with
  | Option.some printed =>
      Except.ok printed
  | Option.none =>
      if
          psJsExprUsesNameWithFuel
            4096
            declaration.body
            declaration.name then
        match
            psJsPrintExprStackSafe
              declaration.name
              declaration.body with
        | Except.error error => Except.error error
        | Except.ok body =>
            match declaration.parameters with
            | List.nil =>
                Except.ok
                  (psJsJoin
                    ""
                    [
                      "export const ",
                      declaration.name,
                      " = __ps$run((function*() { return ",
                      body,
                      "; })());\n"
                    ])
            | List.cons _ _ =>
                let parameters :=
                  psListMap
                    psJsParameterName
                    declaration.parameters;
                let joinedParameters : String :=
                  psJsJoin ", " parameters;
                let implementation : String :=
                  psJsImplementationName declaration.name;
                Except.ok
                  (psJsJoin
                    ""
                    [
                      "export function ",
                      declaration.name,
                      "(",
                      joinedParameters,
                      ") { return __ps$run(",
                      implementation,
                      "(",
                      joinedParameters,
                      ")); }\n",
                      "function* ",
                      implementation,
                      "(",
                      joinedParameters,
                      ") { return ",
                      body,
                      "; }\n",
                      "__ps$implementations.set(",
                      declaration.name,
                      ", ",
                      implementation,
                      ");\n"
                    ])
      else
        psJsPrintDeclaration declaration

def psJsPrintDeclarationsStackSafe
    (declarations : List PsJsIrDeclaration) :
    Except PsJsEmitError String :=
  psJsPrintDeclarationsWith
    psJsPrintDeclarationStackSafe declarations psTextBuilderEmpty


def psJsPrintStackSafePrelude (module : PsJsIrModule) : String :=
  psJsJoin "" [
    "// generated by ProofScript direct JsIR v1 stack-safe\n",
    psJsPrintImports module.imports,
    psJsStringRuntimeSupport,
    psJsStackRuntimeSupport
  ]

def psJsPrintModuleStackSafeWithPositions
    (module : PsJsIrModule) : Except PsJsEmitError PsJsPrintedModule :=
  let prelude : String := psJsPrintStackSafePrelude module;
  match psJsAdvanceGeneratedText psJsGeneratedPositionZero prelude with
  | Except.error error => Except.error error
  | Except.ok position =>
      psJsPrintDeclarationsObservedWith psJsPrintDeclarationStackSafe module.declarations
        true (psTextBuilderAppend psTextBuilderEmpty prelude) position List.nil

def psJsPrintModuleStackSafe
    (module : PsJsIrModule) :
    Except PsJsEmitError String :=
  match psJsPrintDeclarationsStackSafe module.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations =>
      Except.ok (psJsConcat2 (psJsPrintStackSafePrelude module) declarations)

def psJsPrintModule
    (module : PsJsIrModule) :
    Except PsJsEmitError String :=
  match psJsPrintDeclarations module.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations =>
      let imports : String :=
        psJsPrintImports module.imports;
      Except.ok
        (psJsJoin
          ""
          [
            "// generated by ProofScript direct JsIR v1\n",
            imports,
            psJsStringRuntimeSupport,
            declarations
          ])

def psJsEmitValidatedModuleStackSafeWithTargetProfile
    (profile : PsJsTargetProfile)
    (module : PsValidatedIrModule) :
    Except PsJsEmitError String :=
  match
      psJsLowerValidatedModuleWithTargetProfile
        profile
        module with
  | Except.error error =>
      Except.error (PsJsEmitError.lower error)
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error error =>
          Except.error (PsJsEmitError.targetValidation error)
      | Except.ok _ =>
          psJsPrintModuleStackSafe jsIr

def psJsEmitValidatedModuleWithTargetProfile
    (profile : PsJsTargetProfile)
    (module : PsValidatedIrModule) :
    Except PsJsEmitError String :=
  match
      psJsLowerValidatedModuleWithTargetProfile
        profile
        module with
  | Except.error error =>
      Except.error (PsJsEmitError.lower error)
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error error =>
          Except.error (PsJsEmitError.targetValidation error)
      | Except.ok _ =>
          psJsPrintModule jsIr

def psJsEmitValidatedModule
    (module : PsValidatedIrModule) :
    Except PsJsEmitError String :=
  match psJsLowerValidatedModule module with
  | Except.error error =>
      Except.error (PsJsEmitError.lower error)
  | Except.ok jsIr =>
      match psJsValidateModule jsIr with
      | Except.error error =>
          Except.error (PsJsEmitError.targetValidation error)
      | Except.ok _ =>
          psJsPrintModule jsIr
