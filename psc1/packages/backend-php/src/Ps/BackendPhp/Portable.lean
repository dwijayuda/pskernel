import Ps.CompilerIr.Validate
import Ps.Bridge.Json
import Ps.BackendPhp.Runtime
import Ps.BackendCommon.Plan
import Ps.BackendCommon.Source

structure PsPhpPortableModule where
  source : String
  composer : String
  runtimeSource : String
  runtimeVersion : String
  runtimeRequirements : List String
  declarations : List (Prod String String)
  declarationLines : List (Prod String Nat)

namespace PsPhp

def cat (parts : List String) : String := psTextJoin "" parts
def decimal (value : Nat) : String := Int.repr (Int.ofNat value)

def quoteAcc (chars : List Char) (builder : PsTextBuilder) : String :=
  match chars with
  | List.nil => cat [psTextBuilderFinish builder, "\""]
  | List.cons char rest =>
      let code : Nat := Char.toNat char;
      let text : String :=
        if Nat.beq code 92 then "\\\\"
        else if Nat.beq code 34 then "\\\""
        else if Nat.beq code 36 then "\\$"
        else if Nat.beq code 10 then "\\n"
        else if Nat.beq code 13 then "\\r"
        else if Nat.beq code 9 then "\\t"
        else if Nat.blt code 32 then
          cat ["\\x", psJsonHexDigit (Nat.div code 16), psJsonHexDigit (Nat.mod code 16)]
        else String.singleton char;
      quoteAcc rest (psTextBuilderAppend builder text)

def quote (value : String) : String :=
  quoteAcc (psJsonStringToChars value) (psTextBuilderAppend psTextBuilderEmpty "\"")

def asciiLetter (code : Nat) : Bool :=
  (Nat.ble 65 code && Nat.ble code 90) || (Nat.ble 97 code && Nat.ble code 122)

def asciiDigit (code : Nat) : Bool := Nat.ble 48 code && Nat.ble code 57

def stemAcc (chars : List Char) (builder : PsTextBuilder) : String :=
  match chars with
  | List.nil => psTextBuilderFinish builder
  | List.cons char rest =>
      let code : Nat := Char.toNat char;
      let text : String :=
        if asciiLetter code || asciiDigit code || Nat.beq code 95 then String.singleton char
        else cat ["_u", decimal code, "_"];
      stemAcc rest (psTextBuilderAppend builder text)

def stem (value : String) : String := stemAcc (psJsonStringToChars value) psTextBuilderEmpty

def typeText (fuel : Nat) : PsVerifiedIrType -> Except String String :=
  match fuel with
  | Nat.zero => fun (_type : PsVerifiedIrType) => Except.error "PSC1_PHP_TYPE_BUDGET"
  | Nat.succ remaining =>
      fun (type : PsVerifiedIrType) =>
        let check : PsVerifiedIrType -> Except String String := typeText remaining;
        match type with
        | PsVerifiedIrType.primitive scalar =>
            match scalar with
            | PsVerifiedIrPrimitiveType.nat => Except.ok "\\GMP"
            | PsVerifiedIrPrimitiveType.int => Except.ok "\\GMP"
            | PsVerifiedIrPrimitiveType.bool => Except.ok "bool"
            | PsVerifiedIrPrimitiveType.string => Except.ok "string"
            | PsVerifiedIrPrimitiveType.char => Except.ok "string"
            | PsVerifiedIrPrimitiveType.unit => Except.ok "null"
            | _ => Except.error "PSC1_PHP_TYPE_UNSUPPORTED: machine scalars, floats and unresolved types are not qualified"
        | PsVerifiedIrType.function parameters result => do
            let _ <- psListMapExcept check parameters
            let _ <- check result
            Except.ok "\\Closure"
        | PsVerifiedIrType.named _ arguments => do
            let _ <- psListMapExcept check arguments
            Except.ok "array"
        | _ => Except.error "PSC1_PHP_TYPE_UNSUPPORTED: machine scalars, floats and unresolved types are not qualified"

def typeRequirements (fuel : Nat) : PsVerifiedIrType -> List String :=
  match fuel with
  | Nat.zero => fun (_type : PsVerifiedIrType) => List.nil
  | Nat.succ remaining =>
      fun (type : PsVerifiedIrType) =>
        let visit : PsVerifiedIrType -> List String := typeRequirements remaining;
        match type with
        | PsVerifiedIrType.primitive scalar =>
            match scalar with
            | PsVerifiedIrPrimitiveType.nat => ["gmp"]
            | PsVerifiedIrPrimitiveType.int => ["gmp"]
            | _ => List.nil
        | PsVerifiedIrType.function parameters result =>
            psListAppend (psBackendSourceFlatMap visit parameters) (visit result)
        | PsVerifiedIrType.named _ arguments => psBackendSourceFlatMap visit arguments
        | _ => List.nil

def intrinsicRequirements (operation : PsVerifiedIrIntrinsic) : List String :=
  match operation with
  | PsVerifiedIrIntrinsic.boolNot => List.nil
  | PsVerifiedIrIntrinsic.boolAnd => List.nil
  | PsVerifiedIrIntrinsic.boolOr => List.nil
  | PsVerifiedIrIntrinsic.boolEq => List.nil
  | PsVerifiedIrIntrinsic.boolNe => List.nil
  | PsVerifiedIrIntrinsic.stringPush => List.nil
  | PsVerifiedIrIntrinsic.stringSingleton => List.nil
  | PsVerifiedIrIntrinsic.stringAppend => List.nil
  | PsVerifiedIrIntrinsic.stringEq => List.nil
  | PsVerifiedIrIntrinsic.charOfNat => ["charOfNat"]
  | PsVerifiedIrIntrinsic.charToNat => ["charToNat"]
  | PsVerifiedIrIntrinsic.stringLength => ["unicodeChars", "gmp"]
  | PsVerifiedIrIntrinsic.stringGet => ["stringGet"]
  | PsVerifiedIrIntrinsic.stringNext => ["stringNext"]
  | PsVerifiedIrIntrinsic.stringExtract => ["stringExtract"]
  | PsVerifiedIrIntrinsic.arrayMap => ["calls"]
  | PsVerifiedIrIntrinsic.arrayFoldl => ["calls", "gmp"]
  | _ => ["gmp"]

def exprRequirements (valueNames : List String) (fuel : Nat) :
    List String -> PsVerifiedIrExpr -> List String :=
  match fuel with
  | Nat.zero => fun (_bound : List String) (_expr : PsVerifiedIrExpr) => List.nil
  | Nat.succ remaining =>
      fun (bound : List String) (expr : PsVerifiedIrExpr) =>
        let smaller : List String -> PsVerifiedIrExpr -> List String := exprRequirements valueNames remaining;
        let visit : PsVerifiedIrExpr -> List String := smaller bound;
        match expr with
        | PsVerifiedIrExpr.literal value =>
            match value with
            | PsVerifiedIrLiteral.natural _ => ["gmp"]
            | PsVerifiedIrLiteral.integer _ => ["gmp"]
            | _ => List.nil
        | PsVerifiedIrExpr.var name =>
            if psBackendNameSeen name valueNames && !psBackendNameSeen name bound then ["calls"] else List.nil
        | PsVerifiedIrExpr.intrinsic operation types arguments =>
            psListAppend (intrinsicRequirements operation)
              (psListAppend (psBackendSourceFlatMap (typeRequirements remaining) types)
                (psBackendSourceFlatMap visit arguments))
        | PsVerifiedIrExpr.lambda parameters result body =>
            psListAppend
              (psBackendSourceFlatMap (fun (parameter : PsVerifiedIrParameter) =>
                typeRequirements remaining parameter.type) parameters)
              (psListAppend (typeRequirements remaining result)
                (smaller
                  (psListAppend (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) parameters) bound) body))
        | PsVerifiedIrExpr.call fn _ arguments =>
            List.cons "calls" (psListAppend (visit fn) (psBackendSourceFlatMap visit arguments))
        | PsVerifiedIrExpr.letE name type value body =>
            psListAppend (typeRequirements remaining type)
              (psListAppend (visit value) (smaller (List.cons name bound) body))
        | PsVerifiedIrExpr.ifE condition yes no =>
            psListAppend (visit condition) (psListAppend (visit yes) (visit no))
        | PsVerifiedIrExpr.record _ _ fields =>
            psBackendSourceFlatMap (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields
        | PsVerifiedIrExpr.constructor _ _ _ fields =>
            psBackendSourceFlatMap (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields
        | PsVerifiedIrExpr.projection _ _ target _ => visit target
        | PsVerifiedIrExpr.matchE _ _ target alternatives =>
            psListAppend (visit target)
              (psBackendSourceFlatMap
                (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
                  smaller
                    (psListAppend (psListMap (fun (binding : PsVerifiedIrMatchBinding) => binding.name)
                      alternative.snd.fst) bound) alternative.snd.snd) alternatives)

structure Context where
  globals : List (Prod String String)
  valueNames : List String
  locals : List (Prod String String)
  helpers : List String
  scheduled : Bool

structure EmitState where
  linesRev : List String
  lineCount : Nat
  counter : Nat
  indent : Nat

def Emit (Value : Type) : Type := PsBackendStateExcept EmitState String Value

def withLocals (context : Context) (locals : List (Prod String String)) : Context :=
  Context.mk context.globals context.valueNames locals context.helpers context.scheduled

def padding (count : Nat) (builder : PsTextBuilder) : String :=
  match count with
  | Nat.zero => psTextBuilderFinish builder
  | Nat.succ remaining => padding remaining (psTextBuilderAppend builder "    ")

def line (text : String) : Emit Unit :=
  psBackendStateModify (fun (state : EmitState) =>
    EmitState.mk (List.cons (cat [padding state.indent psTextBuilderEmpty, text]) state.linesRev)
      (Nat.succ state.lineCount) state.counter state.indent)

def indent (increase : Bool) : Emit Unit :=
  psBackendStateModify (fun (state : EmitState) =>
    EmitState.mk state.linesRev state.lineCount state.counter
      (if increase then Nat.succ state.indent else Nat.sub state.indent 1))

def fresh (hint : String) : Emit String :=
  psBackendStateBind (psBackendStateGet Unit.unit) (fun (state : EmitState) =>
    psBackendStateBind
      (psBackendStateSet (EmitState.mk state.linesRev state.lineCount (Nat.succ state.counter) state.indent))
      (fun (_unit : Unit) => psBackendStatePure (cat ["$v", decimal state.counter, "_", stem hint])))

def bindValue (expression : String) : Emit String :=
  psBackendStateBind (fresh "tmp") (fun (name : String) =>
    psBackendStateBind (line (cat [name, " = ", expression, ";"])) (fun (_unit : Unit) => psBackendStatePure name))

def captureValues (values : List String) (seen : List String) : List String :=
  match values with
  | List.nil => seen
  | List.cons value rest =>
      captureValues rest (if psBackendNameSeen value seen then seen else psListAppend seen [value])

def capture (context : Context) : String :=
  let refs : List String := psListMap (fun (pair : Prod String String) => cat ["&", pair.snd]) context.globals;
  let values : List String := captureValues
    (psListAppend (psListMap (fun (pair : Prod String String) => pair.snd) context.locals) context.helpers) List.nil;
  let captures : List String := psListAppend refs values;
  if psListIsEmpty captures then "" else cat [" use (", psTextJoin ", " captures, ")"]

def guardCondition (context : Context) (name : String) (type : PsVerifiedIrType) : String :=
  match type with
  | PsVerifiedIrType.primitive scalar =>
      match scalar with
      | PsVerifiedIrPrimitiveType.nat => cat ["!(", name, " instanceof \\GMP) || gmp_cmp(", name, ", 0) < 0"]
      | PsVerifiedIrPrimitiveType.int => cat ["!(", name, " instanceof \\GMP)"]
      | PsVerifiedIrPrimitiveType.bool => cat ["!is_bool(", name, ")"]
      | PsVerifiedIrPrimitiveType.string =>
          if psBackendNameSeen "$__ps_utf8Valid" context.helpers then
            cat ["!is_string(", name, ") || !$__ps_utf8Valid(", name, ")"]
          else cat ["!is_string(", name, ") || preg_match('//u', ", name, ") !== 1"]
      | PsVerifiedIrPrimitiveType.char => cat ["!is_string(", name, ") || preg_match('/\\A.\\z/us', ", name, ") !== 1"]
      | PsVerifiedIrPrimitiveType.unit => cat [name, " !== null"]
      | _ => "true"
  | PsVerifiedIrType.function _ _ => cat ["!(", name, " instanceof \\Closure)"]
  | PsVerifiedIrType.named _ _ => cat ["!is_array(", name, ")"]
  | _ => "true"

def guard (context : Context) (name : String) (type : PsVerifiedIrType) : Emit Unit :=
  fun (state : EmitState) => do
    let _psc_step_0 <- line (cat ["if (", guardCondition context name type, ") {"]) state
    let state := _psc_step_0.snd
    let _psc_step_1 <- indent true state
    let state := _psc_step_1.snd
    let _psc_step_2 <- line "throw new \\TypeError('PSC1_PHP_ARGUMENT_TYPE');" state
    let state := _psc_step_2.snd
    let _psc_step_3 <- indent false state
    let state := _psc_step_3.snd
    line "}" state

def invoke (context : Context) (fn : String) (args : List String) : String :=
  if context.scheduled then cat ["(yield [", fn, ", [", psTextJoin ", " args, "]])"]
  else cat [fn, "(", psTextJoin ", " args, ")"]

def callText (name : String) (args : List String) : String :=
  cat [name, "(", psTextJoin ", " args, ")"]

def callBind (name : String) (arity : Nat) (args : List String) : Emit String :=
  if Nat.beq (psListLength args) arity then bindValue (callText name args)
  else psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY"

def binary (args : List String) (symbol : String) : Emit String :=
  psBackendSourceArgs2
    (fun (a b : String) =>
      bindValue (cat ["(", a, " ", symbol, " ", b, ")"]))
    (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
    args

def intrinsic (context : Context) (operation : PsVerifiedIrIntrinsic)
    (args : List String) : Emit String :=
  match operation with
  | PsVerifiedIrIntrinsic.natAdd => callBind "gmp_add" 2 args
  | PsVerifiedIrIntrinsic.intAdd => callBind "gmp_add" 2 args
  | PsVerifiedIrIntrinsic.natMul => callBind "gmp_mul" 2 args
  | PsVerifiedIrIntrinsic.intMul => callBind "gmp_mul" 2 args
  | PsVerifiedIrIntrinsic.intSub => callBind "gmp_sub" 2 args
  | PsVerifiedIrIntrinsic.natSub =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") < 0 ? gmp_init(0) : gmp_sub(", a, ", ", b, "))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.natDiv =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", b, ", 0) === 0 ? gmp_init(0) : gmp_div_q(", a, ", ", b, ", GMP_ROUND_ZERO))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.natMod =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", b, ", 0) === 0 ? ", a, " : gmp_mod(", a, ", ", b, "))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.natEq =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") === 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intEq =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") === 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.natNe =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") !== 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.natLe =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") <= 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intLe =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") <= 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.natLt =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") < 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intLt =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", a, ", ", b, ") < 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intOfNat =>
      psBackendSourceArgs1
        (fun (a : String) =>
          psBackendStatePure a)
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intRepr =>
      psBackendSourceArgs1
        (fun (a : String) =>
          bindValue (cat ["gmp_strval(", a, ", 10)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intNegSucc =>
      psBackendSourceArgs1
        (fun (a : String) =>
          bindValue (cat ["gmp_neg(gmp_add(", a, ", 1))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.intNeg => callBind "gmp_neg" 1 args
  | PsVerifiedIrIntrinsic.boolNot =>
      psBackendSourceArgs1
        (fun (a : String) =>
          bindValue (cat ["(!", a, ")"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.boolEq => binary args "==="
  | PsVerifiedIrIntrinsic.stringEq => binary args "==="
  | PsVerifiedIrIntrinsic.boolNe => binary args "!=="
  | PsVerifiedIrIntrinsic.boolAnd => binary args "&&"
  | PsVerifiedIrIntrinsic.boolOr => binary args "||"
  | PsVerifiedIrIntrinsic.charOfNat => callBind "$__ps_charOfNat" 1 args
  | PsVerifiedIrIntrinsic.charToNat => callBind "$__ps_charToNat" 1 args
  | PsVerifiedIrIntrinsic.stringSingleton =>
      psBackendSourceArgs1
        (fun (a : String) =>
          psBackendStatePure a)
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.stringPush => binary args "."
  | PsVerifiedIrIntrinsic.stringAppend => binary args "."
  | PsVerifiedIrIntrinsic.stringLength =>
      psBackendSourceArgs1
        (fun (a : String) =>
          bindValue (cat ["gmp_init(count($__ps_unicodeChars(", a, ")))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize =>
      psBackendSourceArgs1
        (fun (a : String) =>
          bindValue (cat ["gmp_init(strlen(", a, "))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.stringGet => callBind "$__ps_stringGet" 2 args
  | PsVerifiedIrIntrinsic.stringNext => callBind "$__ps_stringNext" 2 args
  | PsVerifiedIrIntrinsic.stringExtract => callBind "$__ps_stringExtract" 3 args
  | PsVerifiedIrIntrinsic.stringAtEnd =>
      psBackendSourceArgs2
        (fun (a b : String) =>
          bindValue (cat ["(gmp_cmp(", b, ", strlen(", a, ")) >= 0)"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity =>
      psBackendSourceArgs1
        (fun (_value : String) =>
          bindValue "[]")
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arraySize =>
      psBackendSourceArgs1
        (fun (a : String) =>
          bindValue (cat ["gmp_init(count(", a, "))"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arrayPush =>
      psBackendSourceArgs2
        (fun (a value : String) =>
          psBackendStateBind (bindValue a) (fun (result : String) =>
            psBackendStateBind (line (cat [result, "[] = ", value, ";"]))
              (fun (_unit : Unit) => psBackendStatePure result)))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arrayGet =>
      psBackendSourceArgs2
        (fun (a index : String) =>
          fun (state : EmitState) => do
            let _psc_step_4 <- line (cat ["if (gmp_cmp(", index, ", 0) < 0 || gmp_cmp(", index, ", count(", a, ")) >= 0) {"]) state
            let state := _psc_step_4.snd
            let _psc_step_5 <- indent true state
            let state := _psc_step_5.snd
            let _psc_step_6 <- line "throw new \\OutOfBoundsException('PSC1_ARRAY_GET_BOUNDS');" state
            let state := _psc_step_6.snd
            let _psc_step_7 <- indent false state
            let state := _psc_step_7.snd
            let _psc_step_8 <- line "}" state
            let state := _psc_step_8.snd
            bindValue (cat [a, "[gmp_intval(", index, ")]"]) state)
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arrayGetD =>
      psBackendSourceArgs3
        (fun (a index fallback : String) =>
          bindValue (cat ["(gmp_cmp(", index, ", 0) >= 0 && gmp_cmp(", index, ", count(", a, ")) < 0 ? ", a, "[gmp_intval(", index, ")] : ", fallback, ")"]))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arraySet =>
      psBackendSourceArgs3
        (fun (a index value : String) =>
          fun (state : EmitState) => do
            let _psc_step_9 <- bindValue a state
            let result := _psc_step_9.fst
            let state := _psc_step_9.snd
            let _psc_step_10 <- line (cat ["if (gmp_cmp(", index, ", 0) >= 0 && gmp_cmp(", index, ", count(", a, ")) < 0) {"]) state
            let state := _psc_step_10.snd
            let _psc_step_11 <- indent true state
            let state := _psc_step_11.snd
            let _psc_step_12 <- line (cat [result, "[gmp_intval(", index, ")] = ", value, ";"]) state
            let state := _psc_step_12.snd
            let _psc_step_13 <- indent false state
            let state := _psc_step_13.snd
            let _psc_step_14 <- line "} else {" state
            let state := _psc_step_14.snd
            let _psc_step_15 <- indent true state
            let state := _psc_step_15.snd
            let _psc_step_16 <- line "throw new \\OutOfBoundsException('PSC1_ARRAY_SET_BOUNDS');" state
            let state := _psc_step_16.snd
            let _psc_step_17 <- indent false state
            let state := _psc_step_17.snd
            let _psc_step_18 <- line "}" state
            let state := _psc_step_18.snd
            Except.ok (Prod.mk result state))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arraySetIfInBounds =>
      psBackendSourceArgs3
        (fun (a index value : String) =>
          fun (state : EmitState) => do
            let _psc_step_19 <- bindValue a state
            let result := _psc_step_19.fst
            let state := _psc_step_19.snd
            let _psc_step_20 <- line (cat ["if (gmp_cmp(", index, ", 0) >= 0 && gmp_cmp(", index, ", count(", a, ")) < 0) {"]) state
            let state := _psc_step_20.snd
            let _psc_step_21 <- indent true state
            let state := _psc_step_21.snd
            let _psc_step_22 <- line (cat [result, "[gmp_intval(", index, ")] = ", value, ";"]) state
            let state := _psc_step_22.snd
            let _psc_step_23 <- indent false state
            let state := _psc_step_23.snd
            let _psc_step_24 <- line "}" state
            let state := _psc_step_24.snd
            Except.ok (Prod.mk result state))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arrayMap =>
      psBackendSourceArgs2
        (fun (fn array : String) =>
          fun (state : EmitState) => do
            let _psc_step_25 <- bindValue "[]" state
            let result := _psc_step_25.fst
            let state := _psc_step_25.snd
            let _psc_step_26 <- fresh "item" state
            let item := _psc_step_26.fst
            let state := _psc_step_26.snd
            let _psc_step_27 <- line (cat ["foreach (", array, " as ", item, ") {"]) state
            let state := _psc_step_27.snd
            let _psc_step_28 <- indent true state
            let state := _psc_step_28.snd
            let _psc_step_29 <- line (cat [result, "[] = ", invoke context fn [item], ";"]) state
            let state := _psc_step_29.snd
            let _psc_step_30 <- indent false state
            let state := _psc_step_30.snd
            let _psc_step_31 <- line "}" state
            let state := _psc_step_31.snd
            Except.ok (Prod.mk result state))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | PsVerifiedIrIntrinsic.arrayFoldl =>
      psBackendSourceArgs5
        (fun (fn initial array start stop : String) =>
          fun (state : EmitState) => do
            let _psc_step_32 <- bindValue initial state
            let result := _psc_step_32.fst
            let state := _psc_step_32.snd
            let _psc_step_33 <- fresh "index" state
            let index := _psc_step_33.fst
            let state := _psc_step_33.snd
            let _psc_step_34 <- bindValue (cat ["gmp_init(count(", array, "))"]) state
            let limit := _psc_step_34.fst
            let state := _psc_step_34.snd
            let _psc_step_35 <- line (cat ["for (", index, " = ", start, "; gmp_cmp(", index, ", ", stop, ") < 0 && gmp_cmp(", index, ", ", limit, ") < 0; ", index, " = gmp_add(", index, ", 1)) {"]) state
            let state := _psc_step_35.snd
            let _psc_step_36 <- indent true state
            let state := _psc_step_36.snd
            let _psc_step_37 <- line (cat [result, " = ",
              invoke context fn [result, cat [array, "[gmp_intval(", index, ")]"]], ";"]) state
            let state := _psc_step_37.snd
            let _psc_step_38 <- indent false state
            let state := _psc_step_38.snd
            let _psc_step_39 <- line "}" state
            let state := _psc_step_39.snd
            Except.ok (Prod.mk result state))
        (psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY")
        args
  | _ => psBackendStateThrow "PSC1_PHP_INTRINSIC_UNSUPPORTED_OR_ARITY"

structure ParameterInfo where
  sourceName : String
  localName : String
  printedType : String
  irType : PsVerifiedIrType

def emitParameter (parameter : PsVerifiedIrParameter) : Emit ParameterInfo :=
  psBackendStateBind (psBackendStateLift (typeText 4096 parameter.type)) (fun (text : String) =>
    psBackendStateBind (fresh parameter.name) (fun (name : String) =>
      psBackendStatePure (ParameterInfo.mk parameter.name name text parameter.type)))

def emitBindings (target : String) (bindings : List PsVerifiedIrMatchBinding)
    (locals : List (Prod String String))
    (state : EmitState) : Except String (Prod (List (Prod String String)) EmitState) :=
    match bindings with
    | List.nil => Except.ok (Prod.mk locals state)
    | List.cons binding rest => do
        let _ <- typeText 4096 binding.type
        let _psc_step_40 <- fresh binding.name state
        let name := _psc_step_40.fst
        let state := _psc_step_40.snd
        let _psc_step_41 <- line (cat [name, " = ", target, "[1][", quote binding.field, "];"]) state
        let state := _psc_step_41.snd
        emitBindings target rest (List.cons (Prod.mk binding.name name) locals) state

def emitAlternatives
    (body : Context -> PsVerifiedIrExpr -> Emit Unit)
    (context : Context) (target : String)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)))
    (first : Bool) (state : EmitState) : Except String (Prod Unit EmitState) :=
    match alternatives with
    | List.nil =>
        if first then line "throw new \\UnexpectedValueException('PSC1_PHP_EMPTY_MATCH');" state
        else do
          let _psc_step_42 <- line "} else {" state
          let state := _psc_step_42.snd
          let _psc_step_43 <- indent true state
          let state := _psc_step_43.snd
          let _psc_step_44 <- line "throw new \\UnexpectedValueException('PSC1_PHP_CONSTRUCTOR_TAG');" state
          let state := _psc_step_44.snd
          let _psc_step_45 <- indent false state
          let state := _psc_step_45.snd
          line "}" state
    | List.cons alternative rest => do
        let _psc_step_46 <- line (cat [if first then "if (" else "} elseif (",
          target, "[0] === ", quote alternative.fst, ") {"]) state
        let state := _psc_step_46.snd
        let _psc_step_47 <- indent true state
        let state := _psc_step_47.snd
        let _psc_step_48 <- emitBindings target alternative.snd.fst context.locals state
        let locals := _psc_step_48.fst
        let state := _psc_step_48.snd
        let _psc_step_49 <- body (withLocals context locals) alternative.snd.snd state
        let state := _psc_step_49.snd
        let _psc_step_50 <- indent false state
        let state := _psc_step_50.snd
        emitAlternatives body context target rest false state

def emitField (emit : PsVerifiedIrExpr -> Emit String) (field : Prod String PsVerifiedIrExpr) : Emit String :=
  psBackendStateBind (emit field.snd) (fun (value : String) =>
    psBackendStatePure (cat [quote field.fst, " => ", value]))

def expression (fuel : Nat) : Context -> PsVerifiedIrExpr -> Emit String :=
  match fuel with
  | Nat.zero =>
      fun (_context : Context) (_expr : PsVerifiedIrExpr) =>
        psBackendStateThrow "PSC1_PHP_LOWERING_BUDGET"
  | Nat.succ remaining =>
      fun (context : Context) (expr : PsVerifiedIrExpr) (state : EmitState) =>
        let smaller : Context -> PsVerifiedIrExpr -> Emit String := expression remaining;
        let emit : PsVerifiedIrExpr -> Emit String := smaller context;
        match expr with
        | PsVerifiedIrExpr.literal value =>
            match value with
            | PsVerifiedIrLiteral.natural number =>
                bindValue (cat ["gmp_init(", quote (decimal number), ", 10)"]) state
            | PsVerifiedIrLiteral.integer number =>
                bindValue (cat ["gmp_init(", quote (Int.repr number), ", 10)"]) state
            | PsVerifiedIrLiteral.bool flag => Except.ok (Prod.mk (if flag then "true" else "false") state)
            | PsVerifiedIrLiteral.string text => Except.ok (Prod.mk (quote text) state)
            | PsVerifiedIrLiteral.unit => Except.ok (Prod.mk "null" state)
            | PsVerifiedIrLiteral.machineInteger _ _ => Except.error "PSC1_PHP_MACHINE_SCALAR_UNSUPPORTED"
        | PsVerifiedIrExpr.var name =>
            match psBackendSourceFind (fun (entry : Prod String String) =>
                psStringEq entry.fst name) context.locals with
            | Option.some entry => Except.ok (Prod.mk entry.snd state)
            | Option.none =>
                match psBackendSourceFind (fun (entry : Prod String String) =>
                    psStringEq entry.fst name) context.globals with
                | Option.none => Except.error (cat ["PSC1_PHP_UNKNOWN_SYMBOL: ", name])
                | Option.some entry =>
                    if psBackendNameSeen name context.valueNames then
                      bindValue (invoke context entry.snd List.nil) state
                    else Except.ok (Prod.mk entry.snd state)
        | PsVerifiedIrExpr.intrinsic operation _ arguments =>
            let fallback : Emit String :=
              fun (input : EmitState) => do
                let pair <- psBackendSourceMapState emit arguments input
                intrinsic context operation pair.fst pair.snd;
            let action : Emit String :=
              match operation with
              | PsVerifiedIrIntrinsic.boolAnd =>
                  psBackendSourceArgs2 (fun (left right : PsVerifiedIrExpr) =>
                    smaller context
                      (PsVerifiedIrExpr.ifE left right (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool false))))
                    fallback arguments
              | PsVerifiedIrIntrinsic.boolOr =>
                  psBackendSourceArgs2 (fun (left right : PsVerifiedIrExpr) =>
                    smaller context
                      (PsVerifiedIrExpr.ifE left (PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.bool true)) right))
                    fallback arguments
              | _ => fallback;
            action state
        | PsVerifiedIrExpr.call fn _ arguments => do
            let _psc_step_52 <- emit fn state
            let value := _psc_step_52.fst
            let state := _psc_step_52.snd
            let _psc_step_53 <- bindValue value state
            let target := _psc_step_53.fst
            let state := _psc_step_53.snd
            let _psc_step_54 <- psBackendSourceMapState emit arguments state
            let printed := _psc_step_54.fst
            let state := _psc_step_54.snd
            bindValue (invoke context target printed) state
        | PsVerifiedIrExpr.letE name type value body => do
            let _ <- typeText 4096 type
            let _psc_step_55 <- emit value state
            let printed := _psc_step_55.fst
            let state := _psc_step_55.snd
            let _psc_step_56 <- fresh name state
            let localName := _psc_step_56.fst
            let state := _psc_step_56.snd
            let _psc_step_57 <- line (cat [localName, " = ", printed, ";"]) state
            let state := _psc_step_57.snd
            smaller (withLocals context (List.cons (Prod.mk name localName) context.locals)) body state
        | PsVerifiedIrExpr.ifE condition yes no => do
            let _psc_step_58 <- emit condition state
            let printedCondition := _psc_step_58.fst
            let state := _psc_step_58.snd
            let _psc_step_59 <- fresh "branch" state
            let result := _psc_step_59.fst
            let state := _psc_step_59.snd
            let _psc_step_60 <- line (cat ["if (", printedCondition, " === true) {"]) state
            let state := _psc_step_60.snd
            let _psc_step_61 <- indent true state
            let state := _psc_step_61.snd
            let _psc_step_62 <- emit yes state
            let printedYes := _psc_step_62.fst
            let state := _psc_step_62.snd
            let _psc_step_63 <- line (cat [result, " = ", printedYes, ";"]) state
            let state := _psc_step_63.snd
            let _psc_step_64 <- indent false state
            let state := _psc_step_64.snd
            let _psc_step_65 <- line "} else {" state
            let state := _psc_step_65.snd
            let _psc_step_66 <- indent true state
            let state := _psc_step_66.snd
            let _psc_step_67 <- emit no state
            let printedNo := _psc_step_67.fst
            let state := _psc_step_67.snd
            let _psc_step_68 <- line (cat [result, " = ", printedNo, ";"]) state
            let state := _psc_step_68.snd
            let _psc_step_69 <- indent false state
            let state := _psc_step_69.snd
            let _psc_step_70 <- line "}" state
            let state := _psc_step_70.snd
            Except.ok (Prod.mk result state)
        | PsVerifiedIrExpr.lambda parameters result body => do
            let _psc_step_71 <- fresh "closure" state
            let target := _psc_step_71.fst
            let state := _psc_step_71.snd
            let _psc_step_72 <- psBackendSourceMapState emitParameter parameters state
            let printedParameters := _psc_step_72.fst
            let state := _psc_step_72.snd
            let resultType <- typeText 4096 result
            let printed : List String := psListMap (fun (parameter : ParameterInfo) =>
              cat ["mixed ", parameter.localName]) printedParameters
            let _psc_step_73 <- line (cat [target, " = ", if context.scheduled then "$__ps_wrap(" else "",
              "static function (", psTextJoin ", " printed, ")", capture context, ": ",
              if context.scheduled then "\\Generator" else resultType, " {"]) state
            let state := _psc_step_73.snd
            let _psc_step_74 <- indent true state
            let state := _psc_step_74.snd
            let _psc_step_75 <- line (cat ["if (func_num_args() !== ", decimal (psListLength parameters),
              ") { throw new \\ArgumentCountError('PSC1_PHP_ARITY'); }"]) state
            let state := _psc_step_75.snd
            let action : Emit Unit :=
              if context.scheduled then line "if (false) { yield; }" else psBackendStatePure Unit.unit
            let _psc_step_76 <- action state
            let state := _psc_step_76.snd
            let _psc_step_77 <- psBackendSourceForState
              (fun (parameter : ParameterInfo) => guard context parameter.localName parameter.irType) printedParameters state
            let state := _psc_step_77.snd
            let locals : List (Prod String String) :=
              psListMap (fun (parameter : ParameterInfo) => Prod.mk parameter.sourceName parameter.localName) printedParameters
            let _psc_step_78 <- smaller
              (withLocals context (psListAppend locals context.locals)) body state
            let value := _psc_step_78.fst
            let state := _psc_step_78.snd
            let _psc_step_79 <- line (cat ["return ", value, ";"]) state
            let state := _psc_step_79.snd
            let _psc_step_80 <- indent false state
            let state := _psc_step_80.snd
            let _psc_step_81 <- line (if context.scheduled then "});" else "};") state
            let state := _psc_step_81.snd
            Except.ok (Prod.mk target state)
        | PsVerifiedIrExpr.record _ _ fields => do
            let _psc_step_82 <- psBackendSourceMapState (emitField emit) fields state
            let values := _psc_step_82.fst
            let state := _psc_step_82.snd
            bindValue (cat ["[", psTextJoin ", " values, "]"]) state
        | PsVerifiedIrExpr.projection _ _ target field => do
            let _psc_step_83 <- emit target state
            let value := _psc_step_83.fst
            let state := _psc_step_83.snd
            bindValue (cat [value, "[", quote field, "]"]) state
        | PsVerifiedIrExpr.constructor _ constructorName _ fields => do
            let _psc_step_84 <- psBackendSourceMapState (emitField emit) fields state
            let values := _psc_step_84.fst
            let state := _psc_step_84.snd
            bindValue (cat ["[", quote constructorName, ", [", psTextJoin ", " values, "]]"]) state
        | PsVerifiedIrExpr.matchE _ _ scrutinee alternatives => do
            let _psc_step_85 <- emit scrutinee state
            let target := _psc_step_85.fst
            let state := _psc_step_85.snd
            let _psc_step_86 <- fresh "match" state
            let result := _psc_step_86.fst
            let state := _psc_step_86.snd
            let body : Context -> PsVerifiedIrExpr -> Emit Unit :=
              fun (inner : Context) (branch : PsVerifiedIrExpr) =>
                psBackendStateBind (smaller inner branch) (fun (value : String) =>
                  line (cat [result, " = ", value, ";"]))
            let _psc_step_87 <- emitAlternatives body context target alternatives true state
            let state := _psc_step_87.snd
            Except.ok (Prod.mk result state)

def directSelfCall (declaration : PsVerifiedIrDeclaration) (bound : List String)
    (expr : PsVerifiedIrExpr) : Option (List PsVerifiedIrExpr) :=
  match expr with
  | PsVerifiedIrExpr.call fn _ arguments =>
      match fn with
      | PsVerifiedIrExpr.var name =>
          if !psListIsEmpty declaration.parameters && psStringEq name declaration.name &&
              !psBackendNameSeen name bound &&
              Nat.beq (psListLength arguments) (psListLength declaration.parameters) then
            Option.some arguments else Option.none
      | _ => Option.none
  | _ => Option.none

def hasDirectSelfTail (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_bound : List String) (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      fun (bound : List String) (expr : PsVerifiedIrExpr) =>
        let smaller : List String -> PsVerifiedIrExpr -> Bool := hasDirectSelfTail declaration remaining;
        match directSelfCall declaration bound expr with
        | Option.some _ => true
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name _ _ body =>
                smaller (List.cons name bound) body
            | PsVerifiedIrExpr.ifE _ yes no =>
                smaller bound yes ||
                  smaller bound no
            | PsVerifiedIrExpr.matchE _ _ _ alternatives =>
                psListAny
                  (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
                    smaller
                      (psListAppend (psListMap (fun (binding : PsVerifiedIrMatchBinding) =>
                        binding.name) alternative.snd.fst) bound) alternative.snd.snd) alternatives
            | _ => false

def assignParameter (pair : Prod String String) : Emit Unit :=
  line (cat [pair.fst, " = ", pair.snd, ";"])

def directSelfTail (declaration : PsVerifiedIrDeclaration) (parameters : List String)
    (fuel : Nat) : Context -> PsVerifiedIrExpr -> Emit Unit :=
  match fuel with
  | Nat.zero =>
      fun (_context : Context) (_expr : PsVerifiedIrExpr) =>
        psBackendStateThrow "PSC1_PHP_LOWERING_BUDGET"
  | Nat.succ remaining =>
      fun (context : Context) (expr : PsVerifiedIrExpr) (state : EmitState) =>
        let smaller : Context -> PsVerifiedIrExpr -> Emit Unit := directSelfTail declaration parameters remaining;
        let emit : PsVerifiedIrExpr -> Emit String := expression remaining context;
        match directSelfCall declaration
            (psListMap (fun (entry : Prod String String) => entry.fst) context.locals) expr with
        | Option.some arguments => do
            let _psc_step_88 <- psBackendSourceMapState
              (fun (argument : PsVerifiedIrExpr) =>
                psBackendStateBind (emit argument) (fun (value : String) => bindValue value)) arguments state
            let values := _psc_step_88.fst
            let state := _psc_step_88.snd
            let _psc_step_89 <- psBackendSourceForState assignParameter (psListZip parameters values) state
            let state := _psc_step_89.snd
            line "continue;" state
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name type value body => do
                let _ <- typeText 4096 type
                let _psc_step_90 <- emit value state
                let printed := _psc_step_90.fst
                let state := _psc_step_90.snd
                let _psc_step_91 <- fresh name state
                let localName := _psc_step_91.fst
                let state := _psc_step_91.snd
                let _psc_step_92 <- line (cat [localName, " = ", printed, ";"]) state
                let state := _psc_step_92.snd
                smaller
                  (withLocals context (List.cons (Prod.mk name localName) context.locals)) body state
            | PsVerifiedIrExpr.ifE condition yes no => do
                let _psc_step_93 <- emit condition state
                let printedCondition := _psc_step_93.fst
                let state := _psc_step_93.snd
                let _psc_step_94 <- line (cat ["if (", printedCondition, " === true) {"]) state
                let state := _psc_step_94.snd
                let _psc_step_95 <- indent true state
                let state := _psc_step_95.snd
                let _psc_step_96 <- smaller context yes state
                let state := _psc_step_96.snd
                let _psc_step_97 <- indent false state
                let state := _psc_step_97.snd
                let _psc_step_98 <- line "} else {" state
                let state := _psc_step_98.snd
                let _psc_step_99 <- indent true state
                let state := _psc_step_99.snd
                let _psc_step_100 <- smaller context no state
                let state := _psc_step_100.snd
                let _psc_step_101 <- indent false state
                let state := _psc_step_101.snd
                line "}" state
            | PsVerifiedIrExpr.matchE _ _ scrutinee alternatives => do
                let _psc_step_102 <- emit scrutinee state
                let target := _psc_step_102.fst
                let state := _psc_step_102.snd
                emitAlternatives smaller context target alternatives true state
            | _ => do
                let _psc_step_103 <- emit expr state
                let value := _psc_step_103.fst
                let state := _psc_step_103.snd
                line (cat ["return ", value, ";"]) state

def parameterLocal (parameter : ParameterInfo) : Prod String String :=
  Prod.mk parameter.sourceName parameter.localName

def emitDeclaration (context : Context) (declaration : PsVerifiedIrDeclaration) : Emit Nat :=
  fun (state : EmitState) => do
    let symbol <- match psBackendSourceFind (fun (entry : Prod String String) =>
        psStringEq entry.fst declaration.name) context.globals with
      | Option.some entry => Except.ok entry.snd
      | Option.none => Except.error "PSC1_PHP_INTERNAL_SYMBOL"
    let _psc_step_104 <- psBackendSourceMapState emitParameter declaration.parameters state
    let parameters := _psc_step_104.fst
    let state := _psc_step_104.snd
    let resultType <- typeText 4096 declaration.resultType
    let _psc_step_105 <- line (cat ["// declaration ", quote declaration.name]) state
    let state := _psc_step_105.snd
    let _psc_step_106 <- psBackendSourceForState
      (fun (parameter : ParameterInfo) => line (cat ["/** @param ", parameter.printedType, " ", parameter.localName, " */"]))
      parameters state
    let state := _psc_step_106.snd
    let _psc_step_107 <- line (cat ["/** @return ",
      if context.scheduled then cat ["\\Generator<mixed, mixed, mixed, ", resultType, ">"] else resultType, " */"]) state
    let state := _psc_step_107.snd
    let declarationLine : Nat := Nat.succ state.lineCount
    let _psc_step_108 <- line (cat [symbol, " = ", if context.scheduled then "$__ps_wrap(" else "",
      "static function (", psTextJoin ", " (psListMap (fun (parameter : ParameterInfo) =>
        cat ["mixed ", parameter.localName]) parameters), ")", capture context, ": ",
      if context.scheduled then "\\Generator" else resultType, " {"]) state
    let state := _psc_step_108.snd
    let _psc_step_109 <- indent true state
    let state := _psc_step_109.snd
    let _psc_step_110 <- line (cat ["if (func_num_args() !== ", decimal (psListLength parameters),
      ") { throw new \\ArgumentCountError('PSC1_PHP_ARITY'); }"]) state
    let state := _psc_step_110.snd
    let generatorAction : Emit Unit :=
      if context.scheduled then line "if (false) { yield; }" else psBackendStatePure Unit.unit
    let _psc_step_111 <- generatorAction state
    let state := _psc_step_111.snd
    let locals : List (Prod String String) := psListMap parameterLocal parameters
    let hasTail : Bool := hasDirectSelfTail declaration 4096
      (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) declaration.parameters) declaration.body
    let loopStart : Emit Unit :=
      if hasTail then psBackendStateBind (line "while (true) {") (fun (_unit : Unit) => indent true)
      else psBackendStatePure Unit.unit
    let _psc_step_112 <- loopStart state
    let state := _psc_step_112.snd
    let _psc_step_113 <- psBackendSourceForState
      (fun (parameter : ParameterInfo) => guard context parameter.localName parameter.irType) parameters state
    let state := _psc_step_113.snd
    let body : Emit Unit :=
      if hasTail then
        directSelfTail declaration (psListMap (fun (parameter : ParameterInfo) => parameter.localName) parameters)
          4096 (withLocals context locals) declaration.body
      else psBackendStateBind (expression 4096 (withLocals context locals) declaration.body)
        (fun (value : String) => line (cat ["return ", value, ";"]))
    let _psc_step_114 <- body state
    let state := _psc_step_114.snd
    let loopEnd : Emit Unit :=
      if hasTail then psBackendStateBind (indent false) (fun (_unit : Unit) => line "}")
      else psBackendStatePure Unit.unit
    let _psc_step_115 <- loopEnd state
    let state := _psc_step_115.snd
    let _psc_step_116 <- indent false state
    let state := _psc_step_116.snd
    let _psc_step_117 <- line (if context.scheduled then "});" else "};") state
    let state := _psc_step_117.snd
    let _psc_step_118 <- line "" state
    let state := _psc_step_118.snd
    Except.ok (Prod.mk declarationLine state)

def publicScalar (type : PsVerifiedIrType) : Bool :=
  match type with
  | PsVerifiedIrType.primitive scalar => psBackendActivePrimitive scalar
  | _ => false

def checkType (type : PsVerifiedIrType) : Except String Unit :=
  match typeText 4096 type with
  | Except.error error => Except.error error
  | Except.ok _ => Except.ok Unit.unit

def checkDeclaration (declaration : PsVerifiedIrDeclaration) : Except String Unit := do
  if !psListIsEmpty declaration.typeParameters then throw "PSC1_PHP_SPECIALIZATION_REQUIRED"
  checkType declaration.resultType
  psBackendSourceForExcept (fun (parameter : PsVerifiedIrParameter) => checkType parameter.type) declaration.parameters

def checkStructure (info : PsVerifiedIrStructure) : Except String Unit := do
  if !psListIsEmpty info.typeParameters then throw "PSC1_PHP_SPECIALIZATION_REQUIRED"
  psBackendSourceForExcept (fun (field : PsVerifiedIrStructureField) => checkType field.type) info.fields

def checkInductive (info : PsVerifiedIrInductive) : Except String Unit := do
  if !psListIsEmpty info.typeParameters then throw "PSC1_PHP_SPECIALIZATION_REQUIRED"
  psBackendSourceForExcept (fun (constructor : PsVerifiedIrConstructor) =>
    psBackendSourceForExcept (fun (field : PsVerifiedIrConstructorField) => checkType field.type) constructor.fields)
    info.constructors

def checkPublics (module : PsVerifiedIrModule) (ioAbi : Bool) (names seen : List String) : Except String Unit :=
  match names with
  | List.nil => Except.ok Unit.unit
  | List.cons name rest => do
      if psBackendNameSeen name seen then throw (cat ["PSC1_PHP_DUPLICATE_PUBLIC_DECLARATION: ", name])
      let declaration <- match psBackendSourceFind (fun (value : PsVerifiedIrDeclaration) =>
          psStringEq value.name name) module.declarations with
        | Option.none => Except.error (cat ["PSC1_PHP_UNKNOWN_PUBLIC_DECLARATION: ", name])
        | Option.some value => Except.ok value
      if !publicScalar declaration.resultType ||
          !psBackendSourceAll (fun (parameter : PsVerifiedIrParameter) =>
            publicScalar parameter.type || (ioAbi && psBackendIoDispatcherType parameter.type)) declaration.parameters then
        throw (cat ["PSC1_PHP_PUBLIC_ABI_UNSUPPORTED: ", name])
      checkPublics module ioAbi rest (List.cons name seen)

def globalEntry (entry : Prod PsVerifiedIrDeclaration Nat) : Prod String String :=
  Prod.mk entry.fst.name (cat ["$g", decimal entry.snd, "_", stem entry.fst.name])

def valueNamesAcc (declarations : List PsVerifiedIrDeclaration) (reversed : List String) : List String :=
  match declarations with
  | List.nil => psListReverse reversed
  | List.cons declaration rest =>
      valueNamesAcc rest
        (if psListIsEmpty declaration.parameters then List.cons declaration.name reversed else reversed)

def countNewlines (chars : List Char) (count : Nat) : Nat :=
  match chars with
  | List.nil => count
  | List.cons char rest =>
      countNewlines rest (if Nat.beq (Char.toNat char) 10 then Nat.succ count else count)

def emitGlobal (entry : Prod String String) : Emit Unit := line (cat [entry.snd, " = null;"])

def emitPublic (context : Context) (name : String) : Emit Unit :=
  fun (state : EmitState) => do
    let symbol <- match psBackendSourceFind (fun (entry : Prod String String) =>
        psStringEq entry.fst name) context.globals with
      | Option.some entry => Except.ok entry.snd
      | Option.none => Except.error "PSC1_PHP_INTERNAL_PUBLIC_SYMBOL"
    line (cat [quote name, " => ", symbol, if psBackendNameSeen name context.valueNames then "()" else "", ","]) state

def emitModule (module : PsVerifiedIrModule) (context : Context) (publicNames : List String) :
    Emit (List (Prod String Nat)) :=
  fun (state : EmitState) => do
    let _psc_step_119 <- psBackendSourceForState emitGlobal context.globals state
    let state := _psc_step_119.snd
    let blank : Emit Unit :=
      if psListIsEmpty context.globals then psBackendStatePure Unit.unit else line ""
    let _psc_step_120 <- blank state
    let state := _psc_step_120.snd
    let _psc_step_121 <- psBackendSourceMapState
      (fun (declaration : PsVerifiedIrDeclaration) =>
        psBackendStateBind (emitDeclaration context declaration) (fun (position : Nat) =>
          psBackendStatePure (Prod.mk declaration.name position))) module.declarations state
    let positions := _psc_step_121.fst
    let state := _psc_step_121.snd
    let _psc_step_122 <- line "return [" state
    let state := _psc_step_122.snd
    let _psc_step_123 <- indent true state
    let state := _psc_step_123.snd
    let _psc_step_124 <- psBackendSourceForState (emitPublic context) publicNames state
    let state := _psc_step_124.snd
    let _psc_step_125 <- indent false state
    let state := _psc_step_125.snd
    let _psc_step_126 <- line "];" state
    let state := _psc_step_126.snd
    let _psc_step_127 <- indent false state
    let state := _psc_step_127.snd
    let _psc_step_128 <- line "})();" state
    let state := _psc_step_128.snd
    Except.ok (Prod.mk positions state)

end PsPhp

def psPhpEmitModuleWithIo (validated : PsValidatedIrModule) (publicNames : List String)
    (ioAbi : Bool) : Except String PsPhpPortableModule := do
  match psStrictValidateModule validated.raw with
  | Except.error _ => throw "PSC1_PHP_IR_VALIDATION_FAILED"
  | Except.ok _ => pure Unit.unit
  let module : PsVerifiedIrModule := validated.raw
  if !psListIsEmpty module.imports then throw "PSC1_PHP_EXTERNAL_IMPORT_UNSUPPORTED"
  psBackendSourceForExcept PsPhp.checkDeclaration module.declarations
  psBackendSourceForExcept PsPhp.checkStructure module.structures
  psBackendSourceForExcept PsPhp.checkInductive module.inductives
  PsPhp.checkPublics module ioAbi publicNames List.nil
  let valueNames : List String := PsPhp.valueNamesAcc module.declarations List.nil
  let requested : List String := psBackendSourceFlatMap
    (fun (declaration : PsVerifiedIrDeclaration) =>
      psListAppend (PsPhp.typeRequirements 4096 declaration.resultType)
        (psListAppend (psBackendSourceFlatMap
          (fun (parameter : PsVerifiedIrParameter) => PsPhp.typeRequirements 4096 parameter.type) declaration.parameters)
          (PsPhp.exprRequirements valueNames 4096
            (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) declaration.parameters) declaration.body)))
    module.declarations
  let requirements : List String := psPhpRuntimeClosure requested
  let runtimeSource : String := psPhpSelectedRuntimeSource requirements
  let globals : List (Prod String String) :=
    psListMap PsPhp.globalEntry (psBackendSourceZipIndex module.declarations)
  let context : PsPhp.Context :=
    PsPhp.Context.mk globals valueNames List.nil (psPhpRuntimeVariables requirements)
      (psBackendNameSeen "calls" requirements)
  let sourcePrefix : String := PsPhp.cat ["<?php\n",
    "// Generated by ProofScript PSC1 DirectPHP. Public API: return value of require.\n",
    "declare(strict_types=1);\n\nreturn (static function (): array {\n", runtimeSource]
  let initial : PsPhp.EmitState :=
    PsPhp.EmitState.mk List.nil (PsPhp.countNewlines (psJsonStringToChars sourcePrefix) 0) 0 1
  let _psc_step_129 <- PsPhp.emitModule module context publicNames initial
  let positions := _psc_step_129.fst
  let state := _psc_step_129.snd
  let composer : String := PsPhp.cat ["{\n  \"type\": \"library\",\n  \"require\": {\n    \"php\": \">=8.5\"",
    if psBackendNameSeen "gmp" requirements then ",\n    \"ext-gmp\": \"*\"" else "", "\n  }\n}\n"]
  Except.ok (PsPhpPortableModule.mk
    (PsPhp.cat [sourcePrefix, psTextJoin "\n" (psListReverse state.linesRev), "\n"])
    composer runtimeSource psPhpRuntimeVersion requirements globals positions)
