import Ps.BackendRust.Type

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
  | PsVerifiedIrIntrinsic.intToNat =>
      match psRustExactOneArgument arguments with
      | Option.some value => Except.ok (psRustConcat3 "__ps_int_to_nat(&(" value "))")
      | Option.none => Except.error PsRustEmitError.intrinsicArity
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
      match arguments with
      | [value, char] => .ok ("__ps_string_push(" ++ value ++ ", " ++ char ++ ")")
      | _ => .error .intrinsicArity
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
      match arguments with
      | [left, right] => .ok ("__ps_string_append(" ++ left ++ ", &(" ++ right ++ "))")
      | _ => .error .intrinsicArity
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
  | PsVerifiedIrIntrinsic.arrayBuild =>
      match arguments with
      | [count, seed, head, tail] =>
          .ok ("__ps_array_build(&(" ++ count ++ "), " ++ seed ++ ", " ++ head ++ ", " ++ tail ++ ")")
      | _ => .error .intrinsicArity
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
      match arguments with
      | [array, value] => .ok ("__ps_array_push(" ++ array ++ ", " ++ value ++ ")")
      | _ => .error .intrinsicArity
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
      match arguments with
      | [array, index, value] => .ok ("__ps_array_set(" ++ array ++ ", &(" ++ index ++ "), " ++ value ++ ")")
      | _ => .error .intrinsicArity
  | PsVerifiedIrIntrinsic.arraySetIfInBounds =>
      match arguments with
      | [array, index, value] => .ok ("__ps_array_set_if_in_bounds(" ++ array ++ ", &(" ++ index ++ "), " ++ value ++ ")")
      | _ => .error .intrinsicArity
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


def psRustIntrinsicConsumes (op : PsVerifiedIrIntrinsic) (index : Nat) : Bool :=
  match op with
  | .arrayBuild => index != 0
  | .arrayPush => true
  | .arraySet | .arraySetIfInBounds => index == 0 || index == 2
  | .arrayMap | .arrayFoldl | .stringPush | .stringAppend => index == 0
  | _ => false
