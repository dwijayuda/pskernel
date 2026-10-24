import Ps.BackendRust.Module

namespace RustStringOwnershipReference


def psRustCloneExprPrinted (expr : PsVerifiedIrExpr) (printed : String) : String :=
  match expr with
  | PsVerifiedIrExpr.var _ => printed
  | _ => psRustClonePrinted printed

def psRustEmitExprListWith
    (emitExpr :
      PsVerifiedIrExpr ->
      Except PsRustEmitError String)
    (expressions : List PsVerifiedIrExpr) :
    Except PsRustEmitError (List String) :=
  match expressions with
  | List.nil =>
      Except.ok List.nil
  | List.cons expr rest =>
      match emitExpr expr with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          match psRustEmitExprListWith emitExpr rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok
                (List.cons
                  (psRustCloneExprPrinted expr printed)
                  printedRest)

-- These slots are passed to read-only String helpers by shared reference.
-- Borrow only immutable local values. Computed operands and owned call/field
-- arguments retain their original evaluation and cloning rules.
def psRustIntrinsicBorrowsStringArgument
    (operation : PsVerifiedIrIntrinsic) (index : Nat) : Bool :=
  match operation with
  | PsVerifiedIrIntrinsic.stringAppend => Nat.ble index 1
  | PsVerifiedIrIntrinsic.stringEq => Nat.ble index 1
  | PsVerifiedIrIntrinsic.stringPush => Nat.beq index 0
  | PsVerifiedIrIntrinsic.stringLength => Nat.beq index 0
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize => Nat.beq index 0
  | PsVerifiedIrIntrinsic.stringNext => Nat.beq index 0
  | PsVerifiedIrIntrinsic.stringGet => Nat.beq index 0
  | PsVerifiedIrIntrinsic.stringAtEnd => Nat.beq index 0
  | PsVerifiedIrIntrinsic.stringExtract => Nat.beq index 0
  | _ => false

def psRustEmitIntrinsicArgumentsWith
    (emitExpr : PsVerifiedIrExpr -> Except PsRustEmitError String)
    (locals : List String) (operation : PsVerifiedIrIntrinsic)
    (expressions : List PsVerifiedIrExpr) :
    Nat -> Except PsRustEmitError (List String) :=
  match expressions with
  | List.nil => fun (_index : Nat) => Except.ok List.nil
  | List.cons expr rest =>
      let smaller : Nat -> Except PsRustEmitError (List String) :=
        psRustEmitIntrinsicArgumentsWith emitExpr locals operation rest;
      fun (index : Nat) =>
        -- Emit first even for a borrowed local, preserving all fuel/error checks.
        match emitExpr expr with
        | Except.error error => Except.error error
        | Except.ok printed =>
            let selected : String :=
              match expr with
              | PsVerifiedIrExpr.var name =>
                  if psRustIntrinsicBorrowsStringArgument operation index &&
                      psRustStringListContains locals name then
                    psRustIdentifier name
                  else psRustCloneExprPrinted expr printed
              | _ => psRustCloneExprPrinted expr printed;
            match smaller (Nat.succ index) with
            | Except.error error => Except.error error
            | Except.ok printedRest => Except.ok (List.cons selected printedRest)

def psRustEmitFieldListWith
    (emitExpr :
      PsVerifiedIrExpr ->
      Except PsRustEmitError String)
    (fields : List (Prod String PsVerifiedIrExpr)) :
    Except PsRustEmitError (List String) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match emitExpr (Prod.snd field) with
      | Except.error error =>
          Except.error error
      | Except.ok printed =>
          let rendered : String :=
            psRustConcat3
              (psRustIdentifier (Prod.fst field))
              ": std::rc::Rc::new("
              (psRustConcat2
                (psRustCloneExprPrinted (Prod.snd field) printed)
                ")");
          match psRustEmitFieldListWith emitExpr rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitParameterList
    (parameters : List PsVerifiedIrParameter) :
    Except PsRustEmitError (List String) :=
  match parameters with
  | List.nil =>
      Except.ok List.nil
  | List.cons parameter rest =>
      let printedTypeResult : Except PsRustEmitError String :=
        match parameter.type with
        | PsVerifiedIrType.function _ _ =>
            psRustEmitClosureValueType parameter.type
        | _ =>
            psRustEmitType parameter.type;
      match printedTypeResult with
      | Except.error error =>
          Except.error error
      | Except.ok printedType =>
          let rendered :=
            psRustConcat3
              (psRustIdentifier parameter.name)
              ": "
              printedType;
          match psRustEmitParameterList rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustParameterTypes
    (parameters : List PsVerifiedIrParameter) :
    List PsVerifiedIrType :=
  match parameters with
  | List.nil =>
      List.nil
  | List.cons parameter rest =>
      List.cons
        parameter.type
        (psRustParameterTypes rest)

def psRustEmitMachineIntegerBinary
    (operation : PsVerifiedIrIntegerBinaryOp)
    (left right : String) : String :=
  match operation with
  | PsVerifiedIrIntegerBinaryOp.add =>
      psRustConcat4
        "(("
        left
        ").wrapping_add("
        (psRustConcat2 right "))")
  | PsVerifiedIrIntegerBinaryOp.sub =>
      psRustConcat4
        "(("
        left
        ").wrapping_sub("
        (psRustConcat2 right "))")
  | PsVerifiedIrIntegerBinaryOp.mul =>
      psRustConcat4
        "(("
        left
        ").wrapping_mul("
        (psRustConcat2 right "))")
  | PsVerifiedIrIntegerBinaryOp.bitAnd =>
      psRustConcat4 "((" left ") & (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerBinaryOp.bitOr =>
      psRustConcat4 "((" left ") | (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerBinaryOp.bitXor =>
      psRustConcat4 "((" left ") ^ (" (psRustConcat2 right "))")

def psRustEmitMachineIntegerCompare
    (operation : PsVerifiedIrIntegerCompareOp)
    (left right : String) : String :=
  match operation with
  | PsVerifiedIrIntegerCompareOp.eq =>
      psRustConcat4 "((" left ") == (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerCompareOp.ne =>
      psRustConcat4 "((" left ") != (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerCompareOp.lt =>
      psRustConcat4 "((" left ") < (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerCompareOp.le =>
      psRustConcat4 "((" left ") <= (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerCompareOp.gt =>
      psRustConcat4 "((" left ") > (" (psRustConcat2 right "))")
  | PsVerifiedIrIntegerCompareOp.ge =>
      psRustConcat4 "((" left ") >= (" (psRustConcat2 right "))")

def psRustEmitFloatBinary
    (operation : PsVerifiedIrFloatBinaryOp)
    (left right : String) : String :=
  match operation with
  | PsVerifiedIrFloatBinaryOp.add =>
      psRustConcat4 "((" left ") + (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatBinaryOp.sub =>
      psRustConcat4 "((" left ") - (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatBinaryOp.mul =>
      psRustConcat4 "((" left ") * (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatBinaryOp.div =>
      psRustConcat4 "((" left ") / (" (psRustConcat2 right "))")

def psRustEmitFloatCompare
    (operation : PsVerifiedIrFloatCompareOp)
    (left right : String) : String :=
  match operation with
  | PsVerifiedIrFloatCompareOp.eq =>
      psRustConcat4 "((" left ") == (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatCompareOp.ne =>
      psRustConcat4 "((" left ") != (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatCompareOp.lt =>
      psRustConcat4 "((" left ") < (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatCompareOp.le =>
      psRustConcat4 "((" left ") <= (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatCompareOp.gt =>
      psRustConcat4 "((" left ") > (" (psRustConcat2 right "))")
  | PsVerifiedIrFloatCompareOp.ge =>
      psRustConcat4 "((" left ") >= (" (psRustConcat2 right "))")

def psRustExactOneArgument
    (arguments : List String) :
    Option String :=
  match arguments with
  | List.nil =>
      Option.none
  | List.cons value rest =>
      match rest with
      | List.nil =>
          Option.some value
      | List.cons _ _ =>
          Option.none

def psRustExactThreeArguments
    (arguments : List String) :
    Option (Prod String (Prod String String)) :=
  match arguments with
  | List.nil =>
      Option.none
  | List.cons first rest =>
      match rest with
      | List.nil =>
          Option.none
      | List.cons second afterSecond =>
          match afterSecond with
          | List.nil =>
              Option.none
          | List.cons third tail =>
              match tail with
              | List.nil =>
                  Option.some
                    (Prod.mk first (Prod.mk second third))
              | List.cons _ _ =>
                  Option.none

def psRustExactFiveArguments
    (arguments : List String) :
    Option
      (Prod String
        (Prod String
          (Prod String
            (Prod String String)))) :=
  match arguments with
  | List.nil =>
      Option.none
  | List.cons first rest =>
      match rest with
      | List.nil =>
          Option.none
      | List.cons second afterSecond =>
          match afterSecond with
          | List.nil =>
              Option.none
          | List.cons third afterThird =>
              match afterThird with
              | List.nil =>
                  Option.none
              | List.cons fourth afterFourth =>
                  match afterFourth with
                  | List.nil =>
                      Option.none
                  | List.cons fifth tail =>
                      match tail with
                      | List.nil =>
                          Option.some
                            (Prod.mk
                              first
                              (Prod.mk
                                second
                                (Prod.mk
                                  third
                                  (Prod.mk fourth fifth))))
                      | List.cons _ _ =>
                          Option.none

def psRustExactTwoArguments
    (arguments : List String) :
    Option (Prod String String) :=
  match arguments with
  | List.nil =>
      Option.none
  | List.cons first rest =>
      match rest with
      | List.nil =>
          Option.none
      | List.cons second tail =>
          match tail with
          | List.nil =>
              Option.some (Prod.mk first second)
          | List.cons _ _ =>
              Option.none

def psRustEmitIntrinsicFromPrinted
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List String) :
    Except PsRustEmitError String :=
  match operation with
  | PsVerifiedIrIntrinsic.machineIntBinary _ integerOperation =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustEmitMachineIntegerBinary
              integerOperation
              left
              right)
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.machineIntCompare _ integerOperation =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustEmitMachineIntegerCompare
              integerOperation
              left
              right)
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.floatBinary _ floatOperation =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustEmitFloatBinary
              floatOperation
              left
              right)
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.floatCompare _ floatOperation =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustEmitFloatCompare
              floatOperation
              left
              right)
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natAdd =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_nat_add(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natSub =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_nat_sub(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natMul =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_nat_mul(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natDiv =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_nat_div(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natMod =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_nat_mod(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natEq =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") == ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natNe =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") != ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natLe =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") <= ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.natLt =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") < ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intOfNat =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_int_of_nat(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intRepr =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok (psRustConcat3 "(" value ").to_string()")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intNegSucc =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_int_neg_succ(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intNeg =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_int_neg(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intAdd =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_int_add(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intSub =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_int_sub(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intMul =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_int_mul(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intEq =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") == ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intLe =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") <= ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intLt =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") < ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolNot =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3 "(!(" value "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolAnd =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") && ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolOr =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") || ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolEq =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") == ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.boolNe =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "(("
              left
              ") != ("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.charOfNat =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_char_of_nat(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.charToNat =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_char_to_nat("
              value
              ")")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringPush =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_push(&("
              left
              "), "
              (psRustConcat2 right ")"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringSingleton =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_string_singleton("
              value
              ")")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringLength =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_string_length(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringAppend =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_append(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringUtf8ByteSize =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_string_utf8_byte_size(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringNext =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let value : String := Prod.fst pair;
          let position : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_next(&("
              value
              "), &("
              (psRustConcat2 position "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringGet =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let value : String := Prod.fst pair;
          let position : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_get(&("
              value
              "), &("
              (psRustConcat2 position "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringAtEnd =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let value : String := Prod.fst pair;
          let position : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_at_end(&("
              value
              "), &("
              (psRustConcat2 position "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringExtract =>
      match psRustExactThreeArguments arguments with
      | Option.some triple =>
          let value : String := Prod.fst triple;
          let pair : Prod String String := Prod.snd triple;
          let begin : String := Prod.fst pair;
          let endPos : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_extract(&("
              value
              "), &("
              (psRustConcat4
                begin
                "), &("
                endPos
                "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringEq =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let left : String := Prod.fst pair;
          let right : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_string_eq(&("
              left
              "), &("
              (psRustConcat2 right "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arrayEmptyWithCapacity =>
      match psRustExactOneArgument arguments with
      | Option.some capacity =>
          Except.ok
            (psRustConcat3
              "__ps_array_empty_with_capacity(&("
              capacity
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arraySize =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_array_size(&("
              value
              "))")
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arrayPush =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let array : String := Prod.fst pair;
          let value : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_array_push(&("
              array
              "), &("
              (psRustConcat2 value "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arrayGet =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let array : String := Prod.fst pair;
          let index : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_array_get(&("
              array
              "), &("
              (psRustConcat2 index "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arrayGetD =>
      match psRustExactThreeArguments arguments with
      | Option.some triple =>
          let array : String := Prod.fst triple;
          let pair : Prod String String := Prod.snd triple;
          let index : String := Prod.fst pair;
          let fallback : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_array_get_d(&("
              array
              "), &("
              (psRustConcat4
                index
                "), &("
                fallback
                "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arraySet =>
      match psRustExactThreeArguments arguments with
      | Option.some triple =>
          let array : String := Prod.fst triple;
          let pair : Prod String String := Prod.snd triple;
          let index : String := Prod.fst pair;
          let value : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_array_set(&("
              array
              "), &("
              (psRustConcat4
                index
                "), &("
                value
                "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arraySetIfInBounds =>
      match psRustExactThreeArguments arguments with
      | Option.some triple =>
          let array : String := Prod.fst triple;
          let pair : Prod String String := Prod.snd triple;
          let index : String := Prod.fst pair;
          let value : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_array_set_if_in_bounds(&("
              array
              "), &("
              (psRustConcat4
                index
                "), &("
                value
                "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arrayMap =>
      match psRustExactTwoArguments arguments with
      | Option.some pair =>
          let fnValue : String := Prod.fst pair;
          let array : String := Prod.snd pair;
          Except.ok
            (psRustConcat4
              "__ps_array_map("
              fnValue
              ", &("
              (psRustConcat2 array "))"))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arrayFoldl =>
      match psRustExactFiveArguments arguments with
      | Option.some quintuple =>
          let fnValue : String := Prod.fst quintuple;
          let tail1 : Prod String (Prod String (Prod String String)) :=
            Prod.snd quintuple;
          let init : String := Prod.fst tail1;
          let tail2 : Prod String (Prod String String) := Prod.snd tail1;
          let array : String := Prod.fst tail2;
          let tail3 : Prod String String := Prod.snd tail2;
          let start : String := Prod.fst tail3;
          let stop : String := Prod.snd tail3;
          Except.ok
            (psRustConcat4
              "__ps_array_foldl("
              fnValue
              ", &("
              (psRustConcat4
                init
                "), &("
                array
                (psRustConcat4
                  "), &("
                  start
                  "), &("
                  (psRustConcat2 stop "))"))))
      | Option.none =>
          Except.error PsRustEmitError.intrinsicArity

def psRustMatchBindingTemp
    (index : Nat) : String :=
  psRustConcat2
    "__ps_internal_match_"
    (psNatToString index)

def psRustEmitMatchBindingsPatternWorker
    (bindings : List PsVerifiedIrMatchBinding) :
    Nat -> String :=
  match bindings with
  | List.nil =>
      fun (_index : Nat) =>
        ""
  | List.cons binding rest =>
      let smaller : Nat -> String :=
        psRustEmitMatchBindingsPatternWorker rest;
      fun (index : Nat) =>
        let current : String :=
          psRustConcat3
            (psRustIdentifier binding.field)
            ": "
            (psRustMatchBindingTemp index);
        match rest with
        | List.nil =>
            current
        | List.cons _ _ =>
            psRustConcat3
              current
              ", "
              (smaller (Nat.succ index))

def psRustEmitMatchBindingsPattern
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  psRustEmitMatchBindingsPatternWorker bindings 0

def psRustEmitMatchBindingLetsWorker
    (bindings : List PsVerifiedIrMatchBinding) :
    Nat -> String :=
  match bindings with
  | List.nil =>
      fun (_index : Nat) =>
        ""
  | List.cons binding rest =>
      let smaller : Nat -> String :=
        psRustEmitMatchBindingLetsWorker rest;
      fun (index : Nat) =>
        psRustConcat4
          "let "
          (psRustIdentifier binding.name)
          " = (*"
          (psRustConcat4
            (psRustMatchBindingTemp index)
            ").clone(); "
            (smaller (Nat.succ index))
            "")

def psRustEmitMatchBindingLets
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  psRustEmitMatchBindingLetsWorker bindings 0

def psRustEmitAlternativeListWith
    (locals : List String)
    (emitExpr :
      List String ->
      PsVerifiedIrExpr ->
      Except PsRustEmitError String)
    (inductiveName : String)
    (alternatives :
      List
        (Prod String
          (Prod
            (List PsVerifiedIrMatchBinding)
            PsVerifiedIrExpr))) :
    Except PsRustEmitError (List String) :=
  match alternatives with
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      let constructorName : String := Prod.fst alternative;
      let payload : Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr :=
        Prod.snd alternative;
      let bindings : List PsVerifiedIrMatchBinding :=
        Prod.fst payload;
      let body : PsVerifiedIrExpr :=
        Prod.snd payload;
      match emitExpr (psRustAddBindingNames bindings locals) body with
      | Except.error error =>
          Except.error error
      | Except.ok printedBody =>
          let pattern : String :=
            psRustConcat4
              (psRustIdentifier inductiveName)
              "::"
              (psRustIdentifier constructorName)
              (psRustConcat3
                " { "
                (psRustEmitMatchBindingsPattern bindings)
                " }");
          let rendered : String :=
            psRustConcat4
              pattern
              " => { "
              (psRustEmitMatchBindingLets bindings)
              (psRustConcat2 printedBody " }");
          match psRustEmitAlternativeListWith
              locals
              emitExpr
              inductiveName
              rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitExprWorker
    (declarations : List PsVerifiedIrDeclaration)
    (fuel : Nat) :
    List String ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_expr : PsVerifiedIrExpr) =>
        Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List String -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
        psRustEmitExprWorker declarations remaining;
      fun (locals : List String) (expr : PsVerifiedIrExpr) =>
        let emitNested : PsVerifiedIrExpr -> Except PsRustEmitError String :=
          smaller locals;
        let emitStored : PsVerifiedIrExpr -> Except PsRustEmitError String :=
          psRustEmitStoredExprWith declarations locals emitNested;
        match expr with
        | PsVerifiedIrExpr.literal literal =>
          Except.ok (psRustEmitLiteral literal)
        | PsVerifiedIrExpr.var name =>
          if psRustStringListContains locals name then
            Except.ok (psRustClonePrinted (psRustIdentifier name))
          else
            match psRustFindFunctionArity declarations name with
            | Option.none => Except.ok (psRustClonePrinted (psRustIdentifier name))
            | Option.some arity => Except.ok (psRustEmitGlobalFunctionValue name arity)
        | PsVerifiedIrExpr.intrinsic operation _ arguments =>
          match psRustEmitIntrinsicArgumentsWith emitNested locals operation arguments 0 with
          | Except.error error =>
              Except.error error
          | Except.ok printedArguments =>
              psRustEmitIntrinsicFromPrinted
                operation
                printedArguments
        | PsVerifiedIrExpr.lambda parameters resultType body =>
          let functionType : PsVerifiedIrType :=
            PsVerifiedIrType.function (psRustParameterTypes parameters) resultType;
          if !psRustDirectClosureTypeSupported functionType then
            Except.error PsRustEmitError.lambdaFunctionResultUnsupported
          else
            match psRustEmitParameterList parameters with
            | Except.error error => Except.error error
            | Except.ok printedParameters =>
                match psRustEmitClosureValueType functionType with
                | Except.error error => Except.error error
                | Except.ok closureType =>
                    match psRustEmitClosureValueType resultType with
                    | Except.error error => Except.error error
                    | Except.ok printedResult =>
                        match smaller (psRustAddParameterNames parameters locals) body with
                        | Except.error error => Except.error error
                        | Except.ok printedBody =>
                            let captures : List String :=
                              psRustCollectCapturesWorker locals remaining
                                (psRustParameterNames parameters) body List.nil;
                            Except.ok (psRustJoin ""
                              ["{ ", psRustEmitCaptureClones captures,
                                "let __ps_internal_lambda: ", closureType,
                                " = std::rc::Rc::new(move |", psRustJoin ", " printedParameters,
                                "| -> ", printedResult, " { ", printedBody,
                                " }); __ps_internal_lambda }"])
        | PsVerifiedIrExpr.call fn _ arguments =>
          let emittedFn : Except PsRustEmitError String :=
            match fn with
            | PsVerifiedIrExpr.var name => Except.ok (psRustIdentifier name)
            | _ => emitNested fn;
          match emittedFn with
          | Except.error error =>
              Except.error error
          | Except.ok printedFn =>
              match psRustEmitExprListWith emitNested arguments with
              | Except.error error =>
                  Except.error error
              | Except.ok printedArguments =>
                  Except.ok
                    (psRustConcat4
                      "("
                      printedFn
                      ")("
                      (psRustConcat2
                        (psRustJoin ", " printedArguments)
                        ")"))
        | PsVerifiedIrExpr.letE name type value body =>
          match emitNested value with
          | Except.error error => Except.error error
          | Except.ok printedValue =>
              match smaller (List.cons name locals) body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  match psRustEmitClosureValueType type with
                  | Except.error error => Except.error error
                  | Except.ok printedType =>
                      Except.ok (psRustJoin ""
                        ["{ let ", psRustIdentifier name, ": ", printedType, " = ",
                          psRustCloneExprPrinted value printedValue, "; ", printedBody, " }"])
        | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
          match emitNested condition with
          | Except.error error =>
              Except.error error
          | Except.ok printedCondition =>
              match emitNested thenBranch with
              | Except.error error =>
                  Except.error error
              | Except.ok printedThen =>
                  match emitNested elseBranch with
                  | Except.error error =>
                      Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        (psRustConcat4
                          "(if "
                          printedCondition
                          " { "
                          (psRustConcat4
                            printedThen
                            " } else { "
                            printedElse
                            " })"))
        | PsVerifiedIrExpr.record structureName typeArguments fields =>
          match psRustEmitTypeArguments typeArguments with
          | Except.error error =>
              Except.error error
          | Except.ok generic =>
              match psRustEmitFieldListWith emitStored fields with
              | Except.error error =>
                  Except.error error
              | Except.ok printedFields =>
                  Except.ok
                    (psRustConcat4
                      (psRustConcat2
                        (psRustIdentifier structureName)
                        generic)
                      " { "
                      (psRustJoin ", " printedFields)
                      " }")
        | PsVerifiedIrExpr.projection _ _ target field =>
          match emitNested target with
          | Except.error error =>
              Except.error error
          | Except.ok printedTarget =>
              Except.ok
                (psRustConcat4
                  "(*("
                  (psRustCloneExprPrinted target printedTarget)
                  ")."
                  (psRustConcat2
                    (psRustIdentifier field)
                    ").clone()"))
        | PsVerifiedIrExpr.constructor
          inductiveName
          constructorName
          typeArguments
          fields =>
          match psRustEmitTypeArguments typeArguments with
          | Except.error error =>
              Except.error error
          | Except.ok generic =>
              match psRustEmitFieldListWith emitStored fields with
              | Except.error error =>
                  Except.error error
              | Except.ok printedFields =>
                  match printedFields with
                  | List.nil =>
                      Except.ok
                        (psRustConcat4
                          (psRustConcat2
                            (psRustIdentifier inductiveName)
                            generic)
                          "::"
                          (psRustIdentifier constructorName)
                          "{}")
                  | List.cons _ _ =>
                      Except.ok
                        (psRustConcat4
                          (psRustConcat2
                            (psRustIdentifier inductiveName)
                            generic)
                          "::"
                          (psRustIdentifier constructorName)
                          (psRustConcat3
                            " { "
                            (psRustJoin ", " printedFields)
                            " }"))
        | PsVerifiedIrExpr.matchE
          inductiveName
          _
          scrutinee
          alternatives =>
          match emitNested scrutinee with
          | Except.error error =>
              Except.error error
          | Except.ok printedScrutinee =>
              match psRustEmitAlternativeListWith
                  locals
                  smaller
                  inductiveName
                  alternatives with
              | Except.error error =>
                  Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    (psRustConcat4
                      "(match "
                      (psRustCloneExprPrinted scrutinee printedScrutinee)
                      " { "
                      (psRustConcat2
                        (psRustJoin ", " printedAlternatives)
                        " })"))

def psRustEmitExprWithFuel
    (fuel : Nat) (expr : PsVerifiedIrExpr) : Except PsRustEmitError String :=
  psRustEmitExprWorker List.nil fuel List.nil expr

def psRustEmitExpr
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError String :=
  psRustEmitExprWithFuel 4096 expr


-- The loop carries a tuple so arguments are evaluated before replacement.
-- Recognized eta aliases freeze captures before binding; shadowing hides aliases.
def psRustTailAnyAlternative
    (check : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool)
    (locals : List String) (aliases : List PsRustTailAlias)
    (alternatives : List (Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr))) : Bool :=
  match alternatives with
  | List.nil => false
  | List.cons alternative rest =>
      let payload := Prod.snd alternative;
      let names := psRustAddBindingNames (Prod.fst payload) List.nil;
      if check (psRustAddBindingNames (Prod.fst payload) locals) (psRustTailHideAliases names aliases) (Prod.snd payload) then true
      else psRustTailAnyAlternative check locals aliases rest

def psRustHasTailAliasWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_aliases : List PsRustTailAlias) (_expr : PsVerifiedIrExpr) => false
  | Nat.succ remaining =>
      let smaller : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Bool :=
        psRustHasTailAliasWorker declaration remaining;
      fun (locals : List String) (aliases : List PsRustTailAlias) (expr : PsVerifiedIrExpr) =>
        match psRustTailCallFor declaration locals aliases expr with
        | Option.some _ => true
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name _ value body =>
                smaller (List.cons name locals) (psRustTailEnterAlias declaration locals aliases remaining name value) body
            | PsVerifiedIrExpr.ifE _ thenBranch elseBranch =>
                if smaller locals aliases thenBranch then true else smaller locals aliases elseBranch
            | PsVerifiedIrExpr.matchE _ _ _ alternatives => psRustTailAnyAlternative smaller locals aliases alternatives
            | _ => false

def psRustHasTailWorker (declaration : PsVerifiedIrDeclaration) (fuel : Nat)
    (locals : List String) (expr : PsVerifiedIrExpr) : Bool :=
  psRustHasTailAliasWorker declaration fuel locals List.nil expr

def psRustTailTuple (values : List String) : String :=
  match values with
  | List.nil => "()"
  | List.cons _ _ => psRustConcat3 "(" (psRustJoin ", " values) ",)"

def psRustTailParameterNames (parameters : List PsVerifiedIrParameter) : List String :=
  match parameters with
  | List.nil => List.nil
  | List.cons parameter rest =>
      List.cons (psRustIdentifier parameter.name) (psRustTailParameterNames rest)

def psRustTailLet (name : String) (type : PsVerifiedIrType) (value : PsVerifiedIrExpr)
    (printedValue printedBody : String) : Except PsRustEmitError String :=
  let annotation : Except PsRustEmitError String :=
    match type with
    | PsVerifiedIrType.function _ _ =>
        match psRustEmitClosureValueType type with
        | Except.error error => Except.error error
        | Except.ok printed => Except.ok (psRustConcat2 ": " printed)
    | _ =>
        match psRustEmitType type with
        | Except.error error => Except.error error
        | Except.ok printed => Except.ok (psRustConcat2 ": " printed);
  match annotation with
  | Except.error error => Except.error error
  | Except.ok printedType =>
      Except.ok (psRustJoin ""
        ["{ let ", psRustIdentifier name, printedType, " = ",
         psRustCloneExprPrinted value printedValue, "; ", printedBody, " }"])

def psRustEmitTailWorker (declarations : List PsVerifiedIrDeclaration)
    (declaration : PsVerifiedIrDeclaration) (fuel : Nat) :
    List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_locals : List String) (_aliases : List PsRustTailAlias) (_expr : PsVerifiedIrExpr) => Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : List String -> List PsRustTailAlias -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
        psRustEmitTailWorker declarations declaration remaining;
      fun (locals : List String) (aliases : List PsRustTailAlias) (expr : PsVerifiedIrExpr) =>
        let ordinary : PsVerifiedIrExpr -> Except PsRustEmitError String :=
          psRustEmitExprWorker declarations remaining locals;
        match psRustTailCallFor declaration locals aliases expr with
        | Option.some call =>
            match psRustEmitExprListWith ordinary call.arguments with
            | Except.error error => Except.error error
            | Except.ok printed =>
                Except.ok (psRustConcat3 "{ __ps_internal_tail_state = "
                  (psRustTailTuple (psListAppend call.captured printed)) "; continue; }")
        | Option.none =>
            match expr with
            | PsVerifiedIrExpr.letE name type value body =>
                match ordinary value with
                | Except.error error => Except.error error
                | Except.ok printedValue =>
                    match smaller (List.cons name locals) (psRustTailEnterAlias declaration locals aliases remaining name value) body with
                    | Except.error error => Except.error error
                    | Except.ok printedBody =>
                        match psRustTailLet name type value printedValue printedBody with
                        | Except.error error => Except.error error
                        | Except.ok printedLet =>
                            match psRustTailAliasFor declaration locals remaining name value with
                            | Option.none => Except.ok printedLet
                            | Option.some alias =>
                                Except.ok (psRustJoin "" ["{ ", psRustTailCaptureLets alias.captures, printedLet, " }"])
            | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
                match ordinary condition with
                | Except.error error => Except.error error
                | Except.ok printedCondition =>
                    match smaller locals aliases thenBranch with
                    | Except.error error => Except.error error
                    | Except.ok printedThen =>
                        match smaller locals aliases elseBranch with
                        | Except.error error => Except.error error
                        | Except.ok printedElse =>
                            Except.ok (psRustJoin ""
                              ["if ", printedCondition, " { ", printedThen, " } else { ", printedElse, " }"])
            | PsVerifiedIrExpr.matchE inductiveName _ scrutinee alternatives =>
                match ordinary scrutinee with
                | Except.error error => Except.error error
                | Except.ok printedScrutinee =>
                    let emitAlternative : List String -> PsVerifiedIrExpr -> Except PsRustEmitError String :=
                      fun (nestedLocals : List String) (body : PsVerifiedIrExpr) =>
                        let addedNames := psListTake (Nat.sub (psListLength nestedLocals) (psListLength locals)) nestedLocals;
                        smaller nestedLocals (psRustTailHideAliases addedNames aliases) body;
                    match psRustEmitAlternativeListWith locals emitAlternative inductiveName alternatives with
                    | Except.error error => Except.error error
                    | Except.ok printedAlternatives =>
                        Except.ok (psRustJoin "" ["match ", psRustCloneExprPrinted scrutinee printedScrutinee,
                          " { ", psRustJoin ", " printedAlternatives, " }"])
            | _ =>
                match ordinary expr with
                | Except.error error => Except.error error
                | Except.ok printed => Except.ok (psRustConcat3 "break { " printed " };")

def psRustEmitDeclarationBody (declarations : List PsVerifiedIrDeclaration)
    (declaration : PsVerifiedIrDeclaration) (locals : List String)
    (body : PsVerifiedIrExpr) : Except PsRustEmitError String :=
  if psRustHasTailWorker declaration 4096 locals body then
    match psRustEmitTailWorker declarations declaration 4096 locals List.nil body with
    | Except.error error => Except.error error
    | Except.ok printed =>
        let parameters := psRustTailTuple (psRustTailParameterNames declaration.parameters);
        Except.ok (psRustJoin "" ["let mut __ps_internal_tail_state = ", parameters,
          "; loop { let ", parameters, " = __ps_internal_tail_state; ", printed, " }"])
  else psRustEmitExprWorker declarations 4096 locals body

def psRustEmitDeclarationWithVisibility (isPublic : Bool)
    (allDeclarations : List PsVerifiedIrDeclaration)
    (valueNames : List String)
    (declaration : PsVerifiedIrDeclaration) :
    Except PsRustEmitError String :=
  if psRustDeclarationIsGenericValue declaration then
    Except.error
      (PsRustEmitError.genericValueUnsupported declaration.name)
  else
    match (if isPublic then psRustEmitDeclarationParameterList declaration.parameters
      else psRustEmitPrivateDeclarationParameterList declaration.parameters) with
    | Except.error error =>
        Except.error error
    | Except.ok printedParameters =>
        match (if isPublic then psRustEmitDeclarationResultType declaration
          else psRustEmitPrivateDeclarationResultType declaration) with
        | Except.error error =>
            Except.error error
        | Except.ok printedResult =>
            let locals :=
              psRustAddParameterNames
                declaration.parameters
                List.nil;
            match
                psRustRewriteValueRefs
                  valueNames
                  locals
                  declaration.body with
            | Except.error error =>
                Except.error error
            | Except.ok rewrittenBody =>
                let emittedBody :=
                  psRustEmitDeclarationBody allDeclarations declaration locals rewrittenBody;
                match emittedBody with
                | Except.error error =>
                    Except.error error
                | Except.ok printedBody =>
                    let generic :=
                      psRustGenericNames declaration.typeParameters;
                    Except.ok
                      (psRustConcat4
                        (if isPublic then "pub fn " else "fn ")
                        (psRustIdentifier declaration.name)
                        generic
                        (psRustConcat4
                          "("
                          (psRustJoin ", " printedParameters)
                          ") -> "
                          (psRustConcat4
                            printedResult
                            " { "
                            printedBody
                            " }")))

end RustStringOwnershipReference
