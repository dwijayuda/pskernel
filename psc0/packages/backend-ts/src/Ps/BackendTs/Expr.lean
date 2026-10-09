import Ps.BackendTs.Type

def psTsLookup (entries : List (String × String)) : String -> Option String :=
  match entries with
  | List.nil => fun (_name : String) => Option.none
  | List.cons entry rest =>
      let smaller : String -> Option String := psTsLookup rest;
      fun (name : String) =>
        match entry with
        | Prod.mk key value => if psStringEq key name then Option.some value else smaller name

def psTsExprUsesNameWithFuel (fuel : Nat) : PsVerifiedIrExpr -> String -> Bool :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) (_name : String) => true
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> String -> Bool := psTsExprUsesNameWithFuel remaining;
      fun (expr : PsVerifiedIrExpr) (name : String) =>
        let uses : PsVerifiedIrExpr -> Bool := fun (value : PsVerifiedIrExpr) => smaller value name;
        let parameterUses : PsVerifiedIrParameter -> Bool :=
          fun (parameter : PsVerifiedIrParameter) => psStringEq parameter.name name;
        let bindingUses : PsVerifiedIrMatchBinding -> Bool :=
          fun (binding : PsVerifiedIrMatchBinding) => psStringEq binding.name name;
        let fieldUses : (String × PsVerifiedIrExpr) -> Bool :=
          fun (field : String × PsVerifiedIrExpr) =>
            match field with
            | Prod.mk _ value => smaller value name;
        let alternativeUses : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Bool :=
          fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
            match alternative with
            | Prod.mk _ detail =>
                match detail with
                | Prod.mk bindings body =>
                    if psListAny bindingUses bindings then true else smaller body name;
        match expr with
        | .literal _ => false
        | .var value => psStringEq value name
        | .intrinsic _ _ arguments => psListAny uses arguments
        | .lambda parameters _ body =>
            if psListAny parameterUses parameters then true else smaller body name
        | .call fn _ arguments => if smaller fn name then true else psListAny uses arguments
        | .letE localName _ value body =>
            if psStringEq localName name then true
            else if smaller value name then true else smaller body name
        | .ifE condition thenBranch elseBranch =>
            if smaller condition name then true
            else if smaller thenBranch name then true else smaller elseBranch name
        | .record _ _ fields => psListAny fieldUses fields
        | .projection _ _ target _ => smaller target name
        | .constructor _ _ _ fields => psListAny fieldUses fields
        | .matchE _ _ scrutinee alternatives =>
            if smaller scrutinee name then true else psListAny alternativeUses alternatives

def psTsFreshMatchTempWorker
    (expr : PsVerifiedIrExpr) (attempts : Nat) (index : Nat) : String :=
  match attempts with
  | Nat.zero => "__ps$match$overflow"
  | Nat.succ remaining =>
      let candidate := String.Internal.append "__ps$match$" (psNatToString index);
      if psTsExprUsesNameWithFuel 4096 expr candidate then
        psTsFreshMatchTempWorker expr remaining (Nat.succ index)
      else candidate

def psTsFreshMatchTempLoop (expr : PsVerifiedIrExpr) (index attempts : Nat) : String :=
  psTsFreshMatchTempWorker expr attempts index

def psTsFreshMatchTemp (expr : PsVerifiedIrExpr) : String :=
  psTsFreshMatchTempLoop expr 0 4096

def psTsEmitTypeArguments (arguments : List PsVerifiedIrType) : Except PsTsEmitError String :=
  match psListMapExcept psTsEmitType arguments with
  | Except.error error => Except.error error
  | Except.ok printed =>
      if psListIsEmpty printed then Except.ok ""
      else Except.ok (psTsJoin "" ["<", psTsJoin ", " printed, ">"])

def psTsNormalizeMachineInteger
    (type : PsVerifiedIrMachineIntegerType)
    (value : String) :
    Except PsTsEmitError String :=
  match type with
  | .uint8 =>
      Except.ok (psTsJoin "" ["((", value, ") & 255)"])
  | .uint16 =>
      Except.ok (psTsJoin "" ["((", value, ") & 65535)"])
  | .uint32 =>
      Except.ok (psTsJoin "" ["((", value, ") >>> 0)"])
  | .int8 =>
      Except.ok (psTsJoin "" ["(((", value, ") << 24) >> 24)"])
  | .int16 =>
      Except.ok (psTsJoin "" ["(((", value, ") << 16) >> 16)"])
  | .int32 =>
      Except.ok (psTsJoin "" ["((", value, ") | 0)"])
  | .uint64 =>
      Except.ok (psTsJoin "" ["BigInt.asUintN(64, (", value, "))"])
  | .int64 =>
      Except.ok (psTsJoin "" ["BigInt.asIntN(64, (", value, "))"])
  | .usize =>
      Except.error PsTsEmitError.targetWordSizeRequired
  | .isize =>
      Except.error PsTsEmitError.targetWordSizeRequired

def psTsMachineIntegerBinaryRaw
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp)
    (left right : String) : String :=
  match operation with
  | .add => psTsJoin "" ["(", left, " + ", right, ")"]
  | .sub => psTsJoin "" ["(", left, " - ", right, ")"]
  | .mul =>
      match type with
      | .uint8 => psTsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | .uint16 => psTsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | .uint32 => psTsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | .int8 => psTsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | .int16 => psTsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | .int32 => psTsJoin "" ["Math.imul(", left, ", ", right, ")"]
      | _ => psTsJoin "" ["(", left, " * ", right, ")"]
  | .bitAnd => psTsJoin "" ["(", left, " & ", right, ")"]
  | .bitOr => psTsJoin "" ["(", left, " | ", right, ")"]
  | .bitXor => psTsJoin "" ["(", left, " ^ ", right, ")"]

def psTsEmitMachineIntegerBinary
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp)
    (left right : String) :
    Except PsTsEmitError String :=
  psTsNormalizeMachineInteger
    type
    (psTsMachineIntegerBinaryRaw type operation left right)

def psTsEmitMachineIntegerCompare
    (operation : PsVerifiedIrIntegerCompareOp)
    (left right : String) : String :=
  match operation with
  | .eq => psTsJoin "" ["(", left, " === ", right, ")"]
  | .ne => psTsJoin "" ["(", left, " !== ", right, ")"]
  | .lt => psTsJoin "" ["(", left, " < ", right, ")"]
  | .le => psTsJoin "" ["(", left, " <= ", right, ")"]
  | .gt => psTsJoin "" ["(", left, " > ", right, ")"]
  | .ge => psTsJoin "" ["(", left, " >= ", right, ")"]

def psTsEmitFloatBinary
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatBinaryOp)
    (left right : String) : String :=
  let raw : String :=
    match operation with
    | .add => psTsJoin "" ["(", left, " + ", right, ")"]
    | .sub => psTsJoin "" ["(", left, " - ", right, ")"]
    | .mul => psTsJoin "" ["(", left, " * ", right, ")"]
    | .div => psTsJoin "" ["(", left, " / ", right, ")"];
  match type with
  | .float => raw
  | .float32 => psTsJoin "" ["Math.fround(", raw, ")"]

def psTsEmitFloatCompare
    (operation : PsVerifiedIrFloatCompareOp)
    (left right : String) : String :=
  match operation with
  | .eq => psTsJoin "" ["(", left, " === ", right, ")"]
  | .ne => psTsJoin "" ["(", left, " !== ", right, ")"]
  | .lt => psTsJoin "" ["(", left, " < ", right, ")"]
  | .le => psTsJoin "" ["(", left, " <= ", right, ")"]
  | .gt => psTsJoin "" ["(", left, " > ", right, ")"]
  | .ge => psTsJoin "" ["(", left, " >= ", right, ")"]

def psTsPrinted1 (emit : String -> Except PsTsEmitError String)
    (arguments : List String) : Except PsTsEmitError String :=
  match arguments with
  | List.nil => Except.error PsTsEmitError.intrinsicArity
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => emit arg0
    | List.cons _ _ => Except.error PsTsEmitError.intrinsicArity

def psTsPrinted2 (emit : String -> String -> Except PsTsEmitError String)
    (arguments : List String) : Except PsTsEmitError String :=
  match arguments with
  | List.nil => Except.error PsTsEmitError.intrinsicArity
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => Except.error PsTsEmitError.intrinsicArity
    | List.cons arg1 rest1 =>
      match rest1 with
      | List.nil => emit arg0 arg1
      | List.cons _ _ => Except.error PsTsEmitError.intrinsicArity

def psTsPrinted3 (emit : String -> String -> String -> Except PsTsEmitError String)
    (arguments : List String) : Except PsTsEmitError String :=
  match arguments with
  | List.nil => Except.error PsTsEmitError.intrinsicArity
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => Except.error PsTsEmitError.intrinsicArity
    | List.cons arg1 rest1 =>
      match rest1 with
      | List.nil => Except.error PsTsEmitError.intrinsicArity
      | List.cons arg2 rest2 =>
        match rest2 with
        | List.nil => emit arg0 arg1 arg2
        | List.cons _ _ => Except.error PsTsEmitError.intrinsicArity

def psTsPrinted5 (emit : String -> String -> String -> String -> String -> Except PsTsEmitError String)
    (arguments : List String) : Except PsTsEmitError String :=
  match arguments with
  | List.nil => Except.error PsTsEmitError.intrinsicArity
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => Except.error PsTsEmitError.intrinsicArity
    | List.cons arg1 rest1 =>
      match rest1 with
      | List.nil => Except.error PsTsEmitError.intrinsicArity
      | List.cons arg2 rest2 =>
        match rest2 with
        | List.nil => Except.error PsTsEmitError.intrinsicArity
        | List.cons arg3 rest3 =>
          match rest3 with
          | List.nil => Except.error PsTsEmitError.intrinsicArity
          | List.cons arg4 rest4 =>
            match rest4 with
            | List.nil => emit arg0 arg1 arg2 arg3 arg4
            | List.cons _ _ => Except.error PsTsEmitError.intrinsicArity

def psTsEmitIntrinsicFromPrinted
    (operation : PsVerifiedIrIntrinsic) (arguments : List String) : Except PsTsEmitError String :=
  match operation with
  | .machineIntBinary type integerOperation =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          psTsEmitMachineIntegerBinary type integerOperation left right;
      psTsPrinted2 emit arguments
  | .machineIntCompare _ integerOperation =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok
            (psTsEmitMachineIntegerCompare integerOperation left right);
      psTsPrinted2 emit arguments
  | .floatBinary type floatOperation =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsEmitFloatBinary type floatOperation left right);
      psTsPrinted2 emit arguments
  | .floatCompare _ floatOperation =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsEmitFloatCompare floatOperation left right);
      psTsPrinted2 emit arguments
  | .natAdd =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " + ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natSub =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_a: bigint, __ps_b: bigint) => ", "(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))(", left, ", ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natMul =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " * ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natDiv =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_a: bigint, __ps_b: bigint) => ", "(__ps_b === 0n ? 0n : __ps_a / __ps_b))(", left, ", ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natMod =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_a: bigint, __ps_b: bigint) => ", "(__ps_b === 0n ? __ps_a : __ps_a % __ps_b))(", left, ", ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natEq =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " === ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natNe =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " !== ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natLe =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " <= ", right, ")"]);
      psTsPrinted2 emit arguments
  | .natLt =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " < ", right, ")"]);
      psTsPrinted2 emit arguments
  | .intOfNat =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok value;
      psTsPrinted1 emit arguments
  | .intRepr =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok (psTsJoin "" ["(", value, ").toString()"]);
      psTsPrinted1 emit arguments
  | .intNegSucc =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok (psTsJoin "" ["(-(", value, " + 1n))"]);
      psTsPrinted1 emit arguments
  | .intNeg =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok (psTsJoin "" ["(-(", value, "))"]);
      psTsPrinted1 emit arguments
  | .intAdd =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " + ", right, ")"]);
      psTsPrinted2 emit arguments
  | .intSub =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " - ", right, ")"]);
      psTsPrinted2 emit arguments
  | .intMul =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " * ", right, ")"]);
      psTsPrinted2 emit arguments
  | .intEq =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " === ", right, ")"]);
      psTsPrinted2 emit arguments
  | .intLe =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " <= ", right, ")"]);
      psTsPrinted2 emit arguments
  | .intLt =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " < ", right, ")"]);
      psTsPrinted2 emit arguments
  | .boolNot =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok (psTsJoin "" ["(!", value, ")"]);
      psTsPrinted1 emit arguments
  | .boolAnd =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " && ", right, ")"]);
      psTsPrinted2 emit arguments
  | .boolOr =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " || ", right, ")"]);
      psTsPrinted2 emit arguments
  | .boolEq =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " === ", right, ")"]);
      psTsPrinted2 emit arguments
  | .boolNe =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " !== ", right, ")"]);
      psTsPrinted2 emit arguments
  | .charOfNat =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_n: bigint) => ", "((__ps_n < 0xd800n || (__ps_n > 0xdfffn && __ps_n < 0x110000n)) ", "? String.fromCodePoint(Number(__ps_n)) : \"\\0\"))(", value, ")"]);
      psTsPrinted1 emit arguments
  | .charToNat =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_c: string) => BigInt(__ps_c.codePointAt(0) ?? 0))(", value, ")"]);
      psTsPrinted1 emit arguments
  | .stringPush =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " + ", right, ")"]);
      psTsPrinted2 emit arguments
  | .stringSingleton =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok value;
      psTsPrinted1 emit arguments
  | .stringLength =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_s: string) => BigInt(Array.from(__ps_s).length))(", value, ")"]);
      psTsPrinted1 emit arguments
  | .stringAppend =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " + ", right, ")"]);
      psTsPrinted2 emit arguments
  | .stringUtf8ByteSize =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok
            (psTsJoin "" ["__ps$utf8(", value, ").size"]);
      psTsPrinted1 emit arguments
  | .stringNext =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (value : String) (position : String) =>
          Except.ok
            (psTsJoin "" ["__ps$stringNext(", value, ", ", position, ")"]);
      psTsPrinted2 emit arguments
  | .stringGet =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (value : String) (position : String) =>
          Except.ok
            (psTsJoin "" ["__ps$stringGet(", value, ", ", position, ")"]);
      psTsPrinted2 emit arguments
  | .stringAtEnd =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (value : String) (position : String) =>
          let size :=
            psTsJoin "" ["__ps$utf8(", value, ").size"];
          Except.ok (psTsJoin "" ["(", position, " >= ", size, ")"]);
      psTsPrinted2 emit arguments
  | .stringExtract =>
      let emit : String -> String -> String -> Except PsTsEmitError String :=
        fun (value : String) (start : String) (stop : String) =>
          Except.ok
            (psTsJoin "" ["((__ps_s: string, __ps_b: bigint, __ps_e: bigint) => { ", "if (__ps_b >= __ps_e) return \"\"; let __ps_i = 0n; ", "let __ps_started = false; let __ps_out = \"\"; ", "for (const __ps_c of __ps_s) { ", "const __ps_cp = __ps_c.codePointAt(0) ?? 0; ", "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : ", "__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); ", "if (!__ps_started) { if (__ps_i === __ps_b) __ps_started = true; ", "else { __ps_i += __ps_w; continue; } } ", "if (__ps_i === __ps_e) return __ps_out; ", "__ps_out += __ps_c; __ps_i += __ps_w; } return __ps_out; })(", value, ", ", start, ", ", stop, ")"]);
      psTsPrinted3 emit arguments
  | .stringEq =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (left : String) (right : String) =>
          Except.ok (psTsJoin "" ["(", left, " === ", right, ")"]);
      psTsPrinted2 emit arguments
  | .arrayEmptyWithCapacity =>
      let emit : String -> Except PsTsEmitError String :=
        fun (capacity : String) =>
          Except.ok
            (psTsJoin "" ["(() => { void (", capacity, "); return []; })()"]);
      psTsPrinted1 emit arguments
  | .arraySize =>
      let emit : String -> Except PsTsEmitError String :=
        fun (value : String) =>
          Except.ok (psTsJoin "" ["BigInt((", value, ").length)"]);
      psTsPrinted1 emit arguments
  | .arrayPush =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (array : String) (value : String) =>
          Except.ok (psTsJoin "" ["[...(", array, "), ", value, "]"]);
      psTsPrinted2 emit arguments
  | .arrayGet =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (array : String) (index : String) =>
          Except.ok
            (psTsJoin "" ["(<T>(__ps_a: T[], __ps_i: bigint): T => ", "__ps_a[Number(__ps_i)]!)(", array, ", ", index, ")"]);
      psTsPrinted2 emit arguments
  | .arrayGetD =>
      let emit : String -> String -> String -> Except PsTsEmitError String :=
        fun (array : String) (index : String) (fallback : String) =>
          Except.ok
            (psTsJoin "" ["(<T>(__ps_a: T[], __ps_i: bigint, __ps_fallback: T): T => ", "(__ps_i < BigInt(__ps_a.length) ? ", "__ps_a[Number(__ps_i)]! : __ps_fallback))(", array, ", ", index, ", ", fallback, ")"]);
      psTsPrinted3 emit arguments
  | .arraySet =>
      let emit : String -> String -> String -> Except PsTsEmitError String :=
        fun (array : String) (index : String) (value : String) =>
          Except.ok
            (psTsJoin "" ["(<T>(__ps_a: T[], __ps_i: bigint, __ps_v: T): T[] => {", " const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; ", "return __ps_out; })(", array, ", ", index, ", ", value, ")"]);
      psTsPrinted3 emit arguments
  | .arraySetIfInBounds =>
      let emit : String -> String -> String -> Except PsTsEmitError String :=
        fun (array : String) (index : String) (value : String) =>
          Except.ok
            (psTsJoin "" ["(<T>(__ps_a: T[], __ps_i: bigint, __ps_v: T): T[] => { ", "if (__ps_i >= BigInt(__ps_a.length)) return __ps_a; ", "const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; ", "return __ps_out; })(", array, ", ", index, ", ", value, ")"]);
      psTsPrinted3 emit arguments
  | .arrayMap =>
      let emit : String -> String -> Except PsTsEmitError String :=
        fun (fn : String) (array : String) =>
          Except.ok
            (psTsJoin "" ["(<A, B>(__ps_f: (__ps_x: A) => B, __ps_a: A[]): B[] => ", "__ps_a.map((__ps_x) => __ps_f(__ps_x)))(", fn, ", ", array, ")"]);
      psTsPrinted2 emit arguments
  | .arrayFoldl =>
      let emit : String -> String -> String -> String -> String -> Except PsTsEmitError String :=
        fun (fn : String) (init : String) (array : String) (start : String) (stop : String) =>
          Except.ok
            (psTsJoin "" ["(<A, B>(__ps_f: (__ps_b: B, __ps_x: A) => B, __ps_init: B, ", "__ps_a: A[], __ps_start: bigint, __ps_stop: bigint): B => {", " const __ps_size = BigInt(__ps_a.length); ", "const __ps_end = __ps_stop <= __ps_size ? __ps_stop : __ps_size; ", "let __ps_acc = __ps_init; ", "for (let __ps_i = __ps_start; __ps_i < __ps_end; __ps_i += 1n) {", " __ps_acc = __ps_f(__ps_acc, __ps_a[Number(__ps_i)]!); } ", "return __ps_acc; })(", fn, ", ", init, ", ", array, ", ", start, ", ", stop, ")"]);
      psTsPrinted5 emit arguments
def psTsEmitLetStatements
    (emit : PsVerifiedIrExpr -> Except PsTsEmitError String)
    (expr : PsVerifiedIrExpr) : Except PsTsEmitError String :=
  match expr with
  | PsVerifiedIrExpr.letE name type value body =>
      match psTsEmitType type with
      | Except.error error => Except.error error
      | Except.ok printedType =>
          match emit value with
          | Except.error error => Except.error error
          | Except.ok printedValue =>
              match psTsEmitLetStatements emit body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  if psTsExprUsesNameWithFuel 4096 value name then
                    Except.ok
                      (psTsJoin "" ["return yield* (function*(", name, ": ", printedType,
                        ") { ", printedBody, " })(", printedValue, ");"])
                  else
                    Except.ok (psTsJoin "" ["{ const ", name, ": ", printedType, " = ", printedValue, "; ", printedBody, " }"])
  | _ =>
      match emit expr with
      | Except.error error => Except.error error
      | Except.ok printed => Except.ok (psTsJoin "" ["return ", printed, ";"])

def psTsEmitExprWithFuel
    (brands : List (String × String)) (tags : List (String × String)) (fuel : Nat) :
    PsVerifiedIrExpr -> Except PsTsEmitError String :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) => Except.error PsTsEmitError.fuelExhausted
  | Nat.succ remaining =>
    let smaller : PsVerifiedIrExpr -> Except PsTsEmitError String := psTsEmitExprWithFuel brands tags remaining;
    fun (expr : PsVerifiedIrExpr) =>
      match expr with
      | .literal literal =>
          psTsEmitLiteral literal
      | .var name =>
          Except.ok name
      | .intrinsic operation _ arguments =>
          match psListMapExcept smaller arguments with
          | Except.error error => Except.error error
          | Except.ok printed =>
              psTsEmitIntrinsicFromPrinted operation printed
      | .lambda parameters resultType body =>
          let printParameter : PsVerifiedIrParameter -> Except PsTsEmitError String :=
            fun (parameter : PsVerifiedIrParameter) =>
              match psTsEmitType parameter.type with
              | Except.error error => Except.error error
              | Except.ok type =>
                  Except.ok (psTsJoin "" [parameter.name, ": ", type]);
          match psListMapExcept printParameter parameters with
          | Except.error error => Except.error error
          | Except.ok printedParameters =>
              match smaller body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  match psTsEmitType resultType with
                  | Except.error error => Except.error error
                  | Except.ok printedResult =>
                      Except.ok
                        (psTsJoin "" ["__ps$wrap(function*(", psTsJoin ", " printedParameters, "): __ps$Computation<", printedResult, "> { return ", printedBody, "; })"])
      | .call fn typeArguments arguments =>
          match smaller fn with
          | Except.error error => Except.error error
          | Except.ok printedFn =>
              let callable : String :=
                match fn with
                | PsVerifiedIrExpr.lambda _ _ _ => psTsJoin "" ["(", printedFn, ")"]
                | _ => printedFn;
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  match psListMapExcept smaller arguments with
                  | Except.error error => Except.error error
                  | Except.ok printedArguments =>
                      let suffix :=
                        if psListIsEmpty printedArguments then ""
                        else psTsJoin "" [", ", psTsJoin ", " printedArguments];
                      Except.ok
                        (psTsJoin "" ["(yield* __ps$invoke(", callable, generic, suffix, "))"])
      | .letE _ _ _ _ =>
          match psTsEmitLetStatements smaller expr with
          | Except.error error => Except.error error
          | Except.ok statements =>
              Except.ok (psTsJoin "" ["(yield* (function*() { ", statements, " })())"])
      | .ifE condition thenBranch elseBranch =>
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
                        (psTsJoin "" ["(", printedCondition, " ? ", printedThen, " : ", printedElse, ")"])
      | .record structureName _ fields =>
          match psTsLookup brands structureName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownStructure structureName)
          | Option.some brand =>
              let printField : (String × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                fun (field : String × PsVerifiedIrExpr) =>
                  match field with
                  | Prod.mk fieldName fieldValue =>
                      match
                          smaller
                            fieldValue with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          Except.ok (psTsJoin "" [fieldName, ": ", value]);
              match psListMapExcept printField fields with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let suffix :=
                    if psListIsEmpty printedFields then
                      ""
                    else
                      psTsJoin "" [", ", psTsJoin ", " printedFields];
                  Except.ok
                    (psTsJoin "" ["({ [", brand, "]: true as const", suffix, " })"])
      | .projection _ _ target field =>
          match smaller target with
          | Except.error error => Except.error error
          | Except.ok printedTarget =>
              Except.ok (psTsJoin "" [printedTarget, ".", field])
      | .constructor inductiveName constructorName typeArguments fields =>
          match psTsLookup tags inductiveName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | Option.some _ =>
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  let access :=
                    psTsJoin "" [inductiveName, "[", psJsonQuote constructorName, "]"];
                  let printField : (String × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                    fun (field : String × PsVerifiedIrExpr) =>
                      match field with
                      | Prod.mk fieldName fieldValue =>
                          smaller
                            fieldValue;
                  match psListMapExcept printField fields with
                  | Except.error error => Except.error error
                  | Except.ok printedFields =>
                      if if psListIsEmpty typeArguments then psListIsEmpty fields else false then
                        Except.ok access
                      else
                        Except.ok
                          (psTsJoin "" [access, generic, "(", psTsJoin ", " printedFields, ")"])
      | .matchE inductiveName _ scrutinee alternatives =>
          match psTsLookup tags inductiveName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | Option.some tag =>
              let temp := psTsFreshMatchTemp expr;
              let printAlternative : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
                  match alternative with
                  | Prod.mk constructorName detail =>
                    match detail with
                    | Prod.mk bindings body =>
                      match
                          smaller
                            body with
                      | Except.error error => Except.error error
                      | Except.ok printedBody =>
                          if psListIsEmpty bindings then
                            Except.ok
                              (psTsJoin "" ["case ", psJsonQuote constructorName, ": return ", printedBody, ";"])
                          else
                            let printBinding : PsVerifiedIrMatchBinding -> Except PsTsEmitError String :=
                              fun (binding : PsVerifiedIrMatchBinding) =>
                                match psTsEmitType binding.type with
                                | Except.error error => Except.error error
                                | Except.ok type =>
                                    Except.ok
                                      (psTsJoin "" ["const ", binding.name, ": ", type, " = ", temp, ".", binding.field, ";"]);
                            match psListMapExcept printBinding bindings with
                            | Except.error error => Except.error error
                            | Except.ok printedBindings =>
                                Except.ok
                                  (psTsJoin "" ["case ", psJsonQuote constructorName, ": { ", psTsJoin " " printedBindings, " return ", printedBody, "; }"]);
              match psListMapExcept printAlternative alternatives with
              | Except.error error => Except.error error
              | Except.ok cases =>
                  match
                      smaller
                        scrutinee with
                  | Except.error error => Except.error error
                  | Except.ok printedScrutinee =>
                      Except.ok
                        (psTsJoin "" ["(yield* (function*() { const ", temp, " = ", printedScrutinee, "; switch (", temp, "[", tag, "]) { ", psTsJoin " " cases, " } throw new Error(", psJsonQuote
                            "invalid ProofScript constructor tag", "); })())"])


def psTsEmitExpr
    (brands : List (String × String))
    (tags : List (String × String))
    (expr : PsVerifiedIrExpr) :
    Except PsTsEmitError String :=
  psTsEmitExprWithFuel brands tags 4096 expr
