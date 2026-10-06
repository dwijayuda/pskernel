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
              ": "
              (psRustClonePrinted printed);
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
      if psRustTypeContainsFunction parameter.type then
        Except.error
          (PsRustEmitError.lambdaFunctionParameterUnsupported parameter.name)
      else
        match psRustEmitType parameter.type with
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
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_int_of_nat(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.uint8OfNat =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_uint8_of_nat(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intRepr =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok (psRustConcat3 "(" value ").to_string()")
      | _ => Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intNegSucc =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_int_neg_succ(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.intNeg =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_int_neg(&("
              value
              "))")
      | _ =>
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
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3 "(!(" value "))")
      | _ =>
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
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_char_of_nat(&("
              value
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.charToNat =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_char_to_nat("
              value
              ")")
      | _ =>
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
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_string_singleton("
              value
              ")")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.stringLength =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_string_length(&("
              value
              "))")
      | _ =>
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
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_string_utf8_byte_size(&("
              value
              "))")
      | _ =>
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
      match arguments with
      | List.cons value
          (List.cons begin
            (List.cons endPos List.nil)) =>
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
      | _ =>
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
      match arguments with
      | List.cons capacity List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_array_empty_with_capacity(&("
              capacity
              "))")
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arraySize =>
      match arguments with
      | List.cons value List.nil =>
          Except.ok
            (psRustConcat3
              "__ps_array_size(&("
              value
              "))")
      | _ =>
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
      match arguments with
      | List.cons array
          (List.cons index
            (List.cons fallback List.nil)) =>
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
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arraySet =>
      match arguments with
      | List.cons array
          (List.cons index
            (List.cons value List.nil)) =>
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
      | _ =>
          Except.error PsRustEmitError.intrinsicArity
  | PsVerifiedIrIntrinsic.arraySetIfInBounds =>
      match arguments with
      | List.cons array
          (List.cons index
            (List.cons value List.nil)) =>
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
      | _ =>
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
      match arguments with
      | List.cons fnValue
          (List.cons init
            (List.cons array
              (List.cons start
                (List.cons stop List.nil)))) =>
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
      | _ =>
          Except.error PsRustEmitError.intrinsicArity

def psRustEmitMatchBindings
    (bindings : List PsVerifiedIrMatchBinding) : String :=
  match bindings with
  | List.nil =>
      ""
  | List.cons binding rest =>
      let current :=
        psRustConcat3
          (psRustIdentifier binding.field)
          ": "
          (psRustIdentifier binding.name);
      match rest with
      | List.nil =>
          current
      | List.cons _ _ =>
          psRustConcat3
            current
            ", "
            (psRustEmitMatchBindings rest)

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
      let payload :
          Prod
            (List PsVerifiedIrMatchBinding)
            PsVerifiedIrExpr :=
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
                (psRustEmitMatchBindings bindings)
                " }");
          let rendered : String :=
            psRustConcat3
              pattern
              " => "
              printedBody;
          match psRustEmitAlternativeListWith
              emitExpr
              inductiveName
              rest with
          | Except.error error =>
              Except.error error
          | Except.ok printedRest =>
              Except.ok (List.cons rendered printedRest)

def psRustEmitExprWithFuel
    (fuel : Nat)
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError String :=
  match fuel with
  | Nat.zero =>
      Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let emitNested :
          PsVerifiedIrExpr ->
          Except PsRustEmitError String :=
        psRustEmitExprWithFuel remaining;
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
      | PsVerifiedIrExpr.letE name _ value body =>
          match emitNested value with
          | Except.error error =>
              Except.error error
          | Except.ok printedValue =>
              match emitNested body with
              | Except.error error =>
                  Except.error error
              | Except.ok printedBody =>
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
                  "("
                  (psRustClonePrinted printedTarget)
                  ")."
                  (psRustIdentifier field))
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
