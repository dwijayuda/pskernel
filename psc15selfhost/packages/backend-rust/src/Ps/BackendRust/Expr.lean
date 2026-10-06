import Ps.BackendRust.Type

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
                  (psRustClonePrinted printed)
                  printedRest)

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
              ": Box::new("
              (psRustConcat2
                (psRustClonePrinted printed)
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
  | PsVerifiedIrIntrinsic.uint8OfNat =>
      match psRustExactOneArgument arguments with
      | Option.some value =>
          Except.ok
            (psRustConcat3
              "__ps_uint8_of_nat(&("
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
    (index : Nat)
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  match bindings with
  | List.nil =>
      ""
  | List.cons binding rest =>
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
            (psRustEmitMatchBindingsPatternWorker
              (Nat.succ index)
              rest)

def psRustEmitMatchBindingsPattern
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  psRustEmitMatchBindingsPatternWorker 0 bindings

def psRustEmitMatchBindingLetsWorker
    (index : Nat)
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  match bindings with
  | List.nil =>
      ""
  | List.cons binding rest =>
      psRustConcat4
        "let "
        (psRustIdentifier binding.name)
        " = (*"
        (psRustConcat4
          (psRustMatchBindingTemp index)
          ").clone(); "
          (psRustEmitMatchBindingLetsWorker
            (Nat.succ index)
            rest)
          "")

def psRustEmitMatchBindingLets
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  psRustEmitMatchBindingLetsWorker 0 bindings

def psRustEmitAlternativeListWith
    (emitExpr :
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
      match emitExpr body with
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
              emitExpr
              inductiveName
              rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitExprWithFuel
    (fuel : Nat) :
    PsVerifiedIrExpr ->
    Except PsRustEmitError String :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsVerifiedIrExpr) =>
        Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let emitNested :
          PsVerifiedIrExpr ->
          Except PsRustEmitError String :=
        psRustEmitExprWithFuel remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.literal literal =>
          Except.ok (psRustEmitLiteral literal)
        | PsVerifiedIrExpr.var name =>
          Except.ok (psRustIdentifier name)
        | PsVerifiedIrExpr.intrinsic operation _ arguments =>
          match psRustEmitExprListWith emitNested arguments with
          | Except.error error =>
              Except.error error
          | Except.ok printedArguments =>
              psRustEmitIntrinsicFromPrinted
                operation
                printedArguments
        | PsVerifiedIrExpr.lambda parameters resultType body =>
          if psRustTypeContainsFunction resultType then
            Except.error PsRustEmitError.lambdaFunctionResultUnsupported
          else
            match psRustEmitParameterList parameters with
            | Except.error error =>
                Except.error error
            | Except.ok printedParameters =>
                match emitNested body with
                | Except.error error =>
                    Except.error error
                | Except.ok printedBody =>
                    Except.ok
                      (psRustConcat4
                        "|"
                        (psRustJoin ", " printedParameters)
                        "| "
                        printedBody)
        | PsVerifiedIrExpr.call fn _ arguments =>
          match emitNested fn with
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
          | Except.error error =>
              Except.error error
          | Except.ok printedValue =>
              match emitNested body with
              | Except.error error =>
                  Except.error error
              | Except.ok printedBody =>
                  match type with
                  | PsVerifiedIrType.function _ _ =>
                      match psRustEmitClosureValueType type with
                      | Except.error error =>
                          Except.error error
                      | Except.ok closureType =>
                          match value with
                          | PsVerifiedIrExpr.var _ =>
                              Except.ok
                                (psRustConcat4
                                  "{ let "
                                  (psRustIdentifier name)
                                  ": "
                                  (psRustConcat3
                                    closureType
                                    " = "
                                    (psRustConcat4
                                      (psRustClonePrinted printedValue)
                                      "; "
                                      printedBody
                                      " }")))
                          | _ =>
                              Except.ok
                                (psRustConcat4
                                  "{ let "
                                  (psRustIdentifier name)
                                  ": "
                                  (psRustConcat4
                                    closureType
                                    " = std::rc::Rc::new(move "
                                    printedValue
                                    (psRustConcat3
                                      "); "
                                      printedBody
                                      " }")))
                  | _ =>
                    Except.ok
                      (psRustConcat4
                        "{ let "
                        (psRustIdentifier name)
                        " = "
                        (psRustConcat4
                          (psRustClonePrinted printedValue)
                          "; "
                          printedBody
                          " }"))
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
              match psRustEmitFieldListWith emitNested fields with
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
                  (psRustClonePrinted printedTarget)
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
              match psRustEmitFieldListWith emitNested fields with
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
                  emitNested
                  inductiveName
                  alternatives with
              | Except.error error =>
                  Except.error error
              | Except.ok printedAlternatives =>
                  Except.ok
                    (psRustConcat4
                      "(match "
                      (psRustClonePrinted printedScrutinee)
                      " { "
                      (psRustConcat2
                        (psRustJoin ", " printedAlternatives)
                        " })"))

def psRustEmitExpr
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError String :=
  psRustEmitExprWithFuel 4096 expr
