import Ps.BackendTs.Type

def psTsLookup :
    List (String × String) -> String -> Option String
  | [], _ => none
  | entry :: rest, name =>
      if entry.1 == name then
        some entry.2
      else
        psTsLookup rest name

def psTsExprUsesNameWithFuel :
    Nat -> PsVerifiedIrExpr -> String -> Bool
  | 0, _, _ => false
  | fuel + 1, expr, name =>
      match expr with
      | .literal _ => false
      | .var value => value == name
      | .intrinsic _ arguments =>
          arguments.any
            (fun argument =>
              psTsExprUsesNameWithFuel fuel argument name)
      | .lambda parameters _ body =>
          parameters.any (fun parameter => parameter.name == name)
            || psTsExprUsesNameWithFuel fuel body name
      | .call fn _ arguments =>
          psTsExprUsesNameWithFuel fuel fn name
            || arguments.any
              (fun argument =>
                psTsExprUsesNameWithFuel fuel argument name)
      | .letE localName _ value body =>
          localName == name
            || psTsExprUsesNameWithFuel fuel value name
            || psTsExprUsesNameWithFuel fuel body name
      | .ifE condition thenBranch elseBranch =>
          psTsExprUsesNameWithFuel fuel condition name
            || psTsExprUsesNameWithFuel fuel thenBranch name
            || psTsExprUsesNameWithFuel fuel elseBranch name
      | .record _ fields =>
          fields.any
            (fun field =>
              psTsExprUsesNameWithFuel fuel field.2 name)
      | .projection _ target _ =>
          psTsExprUsesNameWithFuel fuel target name
      | .constructor _ _ _ fields =>
          fields.any
            (fun field =>
              psTsExprUsesNameWithFuel fuel field.2 name)
      | .matchE _ scrutinee alternatives =>
          psTsExprUsesNameWithFuel fuel scrutinee name
            || alternatives.any
              (fun alternative =>
                alternative.2.1.any
                    (fun binding => binding.name == name)
                  || psTsExprUsesNameWithFuel
                    fuel
                    alternative.2.2
                    name)

def psTsFreshMatchTempLoop
    (expr : PsVerifiedIrExpr) :
    Nat -> Nat -> String
  | _, 0 => "__ps$match$overflow"
  | index, attempts + 1 =>
      let candidate := "__ps$match$" ++ toString index
      if psTsExprUsesNameWithFuel 4096 expr candidate then
        psTsFreshMatchTempLoop expr (index + 1) attempts
      else
        candidate

def psTsFreshMatchTemp (expr : PsVerifiedIrExpr) : String :=
  psTsFreshMatchTempLoop expr 0 4096

def psTsEmitTypeArguments
    (arguments : List PsVerifiedIrType) :
    Except PsTsEmitError String :=
  match arguments.mapM psTsEmitType with
  | Except.error error => Except.error error
  | Except.ok printed =>
      if printed.isEmpty then
        Except.ok ""
      else
        Except.ok ("<" ++ psTsJoin ", " printed ++ ">")

def psTsNormalizeMachineInteger
    (type : PsVerifiedIrMachineIntegerType)
    (value : String) :
    Except PsTsEmitError String :=
  match type with
  | .uint8 =>
      Except.ok ("((" ++ value ++ ") & 255)")
  | .uint16 =>
      Except.ok ("((" ++ value ++ ") & 65535)")
  | .uint32 =>
      Except.ok ("((" ++ value ++ ") >>> 0)")
  | .int8 =>
      Except.ok ("(((" ++ value ++ ") << 24) >> 24)")
  | .int16 =>
      Except.ok ("(((" ++ value ++ ") << 16) >> 16)")
  | .int32 =>
      Except.ok ("((" ++ value ++ ") | 0)")
  | .uint64 =>
      Except.ok ("BigInt.asUintN(64, (" ++ value ++ "))")
  | .int64 =>
      Except.ok ("BigInt.asIntN(64, (" ++ value ++ "))")
  | .usize =>
      Except.error PsTsEmitError.targetWordSizeRequired
  | .isize =>
      Except.error PsTsEmitError.targetWordSizeRequired

def psTsMachineIntegerBinaryRaw
    (type : PsVerifiedIrMachineIntegerType)
    (operation : PsVerifiedIrIntegerBinaryOp)
    (left right : String) : String :=
  match operation with
  | .add => "(" ++ left ++ " + " ++ right ++ ")"
  | .sub => "(" ++ left ++ " - " ++ right ++ ")"
  | .mul =>
      match type with
      | .uint8 => "Math.imul(" ++ left ++ ", " ++ right ++ ")"
      | .uint16 => "Math.imul(" ++ left ++ ", " ++ right ++ ")"
      | .uint32 => "Math.imul(" ++ left ++ ", " ++ right ++ ")"
      | .int8 => "Math.imul(" ++ left ++ ", " ++ right ++ ")"
      | .int16 => "Math.imul(" ++ left ++ ", " ++ right ++ ")"
      | .int32 => "Math.imul(" ++ left ++ ", " ++ right ++ ")"
      | _ => "(" ++ left ++ " * " ++ right ++ ")"
  | .bitAnd => "(" ++ left ++ " & " ++ right ++ ")"
  | .bitOr => "(" ++ left ++ " | " ++ right ++ ")"
  | .bitXor => "(" ++ left ++ " ^ " ++ right ++ ")"

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
  | .eq => "(" ++ left ++ " === " ++ right ++ ")"
  | .ne => "(" ++ left ++ " !== " ++ right ++ ")"
  | .lt => "(" ++ left ++ " < " ++ right ++ ")"
  | .le => "(" ++ left ++ " <= " ++ right ++ ")"
  | .gt => "(" ++ left ++ " > " ++ right ++ ")"
  | .ge => "(" ++ left ++ " >= " ++ right ++ ")"

def psTsEmitFloatBinary
    (type : PsVerifiedIrFloatingType)
    (operation : PsVerifiedIrFloatBinaryOp)
    (left right : String) : String :=
  let raw :=
    match operation with
    | .add => "(" ++ left ++ " + " ++ right ++ ")"
    | .sub => "(" ++ left ++ " - " ++ right ++ ")"
    | .mul => "(" ++ left ++ " * " ++ right ++ ")"
    | .div => "(" ++ left ++ " / " ++ right ++ ")"
  match type with
  | .float => raw
  | .float32 => "Math.fround(" ++ raw ++ ")"

def psTsEmitFloatCompare
    (operation : PsVerifiedIrFloatCompareOp)
    (left right : String) : String :=
  match operation with
  | .eq => "(" ++ left ++ " === " ++ right ++ ")"
  | .ne => "(" ++ left ++ " !== " ++ right ++ ")"
  | .lt => "(" ++ left ++ " < " ++ right ++ ")"
  | .le => "(" ++ left ++ " <= " ++ right ++ ")"
  | .gt => "(" ++ left ++ " > " ++ right ++ ")"
  | .ge => "(" ++ left ++ " >= " ++ right ++ ")"

def psTsEmitIntrinsicFromPrinted
    (operation : PsVerifiedIrIntrinsic)
    (arguments : List String) :
    Except PsTsEmitError String :=
  match operation, arguments with
  | (.machineIntBinary type integerOperation), [left, right] =>
      psTsEmitMachineIntegerBinary type integerOperation left right
  | (.machineIntCompare _ integerOperation), [left, right] =>
      Except.ok
        (psTsEmitMachineIntegerCompare integerOperation left right)
  | (.floatBinary type floatOperation), [left, right] =>
      Except.ok (psTsEmitFloatBinary type floatOperation left right)
  | (.floatCompare _ floatOperation), [left, right] =>
      Except.ok (psTsEmitFloatCompare floatOperation left right)
  | .natAdd, [left, right] =>
      Except.ok ("(" ++ left ++ " + " ++ right ++ ")")
  | .natSub, [left, right] =>
      Except.ok
        ("((__ps_a: bigint, __ps_b: bigint) => " ++
          "(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))(" ++
          left ++ ", " ++ right ++ ")")
  | .natMul, [left, right] =>
      Except.ok ("(" ++ left ++ " * " ++ right ++ ")")
  | .natDiv, [left, right] =>
      Except.ok
        ("((__ps_a: bigint, __ps_b: bigint) => " ++
          "(__ps_b === 0n ? 0n : __ps_a / __ps_b))(" ++
          left ++ ", " ++ right ++ ")")
  | .natMod, [left, right] =>
      Except.ok
        ("((__ps_a: bigint, __ps_b: bigint) => " ++
          "(__ps_b === 0n ? __ps_a : __ps_a % __ps_b))(" ++
          left ++ ", " ++ right ++ ")")
  | .natEq, [left, right] =>
      Except.ok ("(" ++ left ++ " === " ++ right ++ ")")
  | .natNe, [left, right] =>
      Except.ok ("(" ++ left ++ " !== " ++ right ++ ")")
  | .natLe, [left, right] =>
      Except.ok ("(" ++ left ++ " <= " ++ right ++ ")")
  | .natLt, [left, right] =>
      Except.ok ("(" ++ left ++ " < " ++ right ++ ")")
  | .intOfNat, [value] =>
      Except.ok value
  | .intNegSucc, [value] =>
      Except.ok ("(-(" ++ value ++ " + 1n))")
  | .intNeg, [value] =>
      Except.ok ("(-(" ++ value ++ "))")
  | .intAdd, [left, right] =>
      Except.ok ("(" ++ left ++ " + " ++ right ++ ")")
  | .intSub, [left, right] =>
      Except.ok ("(" ++ left ++ " - " ++ right ++ ")")
  | .intMul, [left, right] =>
      Except.ok ("(" ++ left ++ " * " ++ right ++ ")")
  | .intEq, [left, right] =>
      Except.ok ("(" ++ left ++ " === " ++ right ++ ")")
  | .intLe, [left, right] =>
      Except.ok ("(" ++ left ++ " <= " ++ right ++ ")")
  | .intLt, [left, right] =>
      Except.ok ("(" ++ left ++ " < " ++ right ++ ")")
  | .boolNot, [value] =>
      Except.ok ("(!" ++ value ++ ")")
  | .boolAnd, [left, right] =>
      Except.ok ("(" ++ left ++ " && " ++ right ++ ")")
  | .boolOr, [left, right] =>
      Except.ok ("(" ++ left ++ " || " ++ right ++ ")")
  | .boolEq, [left, right] =>
      Except.ok ("(" ++ left ++ " === " ++ right ++ ")")
  | .boolNe, [left, right] =>
      Except.ok ("(" ++ left ++ " !== " ++ right ++ ")")
  | .charOfNat, [value] =>
      Except.ok
        ("((__ps_n: bigint) => " ++
          "((__ps_n < 0xd800n || (__ps_n > 0xdfffn && __ps_n < 0x110000n)) " ++
          "? String.fromCodePoint(Number(__ps_n)) : \"\\0\"))(" ++
          value ++ ")")
  | .charToNat, [value] =>
      Except.ok
        ("((__ps_c: string) => BigInt(__ps_c.codePointAt(0) ?? 0))(" ++
          value ++ ")")
  | .stringPush, [left, right] =>
      Except.ok ("(" ++ left ++ " + " ++ right ++ ")")
  | .stringSingleton, [value] =>
      Except.ok value
  | .stringLength, [value] =>
      Except.ok
        ("((__ps_s: string) => BigInt(Array.from(__ps_s).length))(" ++
          value ++ ")")
  | .stringAppend, [left, right] =>
      Except.ok ("(" ++ left ++ " + " ++ right ++ ")")
  | .stringUtf8ByteSize, [value] =>
      Except.ok
        ("((__ps_s: string) => { let __ps_n = 0n; " ++
          "for (const __ps_c of __ps_s) { " ++
          "const __ps_cp = __ps_c.codePointAt(0) ?? 0; " ++
          "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : " ++
          "__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); " ++
          "__ps_n += __ps_w; } return __ps_n; })(" ++ value ++ ")")
  | .stringNext, [value, position] =>
      Except.ok
        ("((__ps_s: string, __ps_p: bigint) => { let __ps_i = 0n; " ++
          "for (const __ps_c of __ps_s) { " ++
          "const __ps_cp = __ps_c.codePointAt(0) ?? 0; " ++
          "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : " ++
          "__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); " ++
          "if (__ps_i === __ps_p) return __ps_p + __ps_w; " ++
          "if (__ps_i > __ps_p) return __ps_p + 1n; " ++
          "__ps_i += __ps_w; } return __ps_p + 1n; })(" ++
          value ++ ", " ++ position ++ ")")
  | .stringGet, [value, position] =>
      Except.ok
        ("((__ps_s: string, __ps_p: bigint) => { let __ps_i = 0n; " ++
          "for (const __ps_c of __ps_s) { " ++
          "if (__ps_i === __ps_p) return __ps_c; " ++
          "if (__ps_i > __ps_p) return \"A\"; " ++
          "const __ps_cp = __ps_c.codePointAt(0) ?? 0; " ++
          "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : " ++
          "__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); " ++
          "__ps_i += __ps_w; } return \"A\"; })(" ++
          value ++ ", " ++ position ++ ")")
  | .stringAtEnd, [value, position] =>
      let size :=
        "((__ps_s: string) => { let __ps_n = 0n; " ++
          "for (const __ps_c of __ps_s) { " ++
          "const __ps_cp = __ps_c.codePointAt(0) ?? 0; " ++
          "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : " ++
          "__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); " ++
          "__ps_n += __ps_w; } return __ps_n; })(" ++ value ++ ")"
      Except.ok ("(" ++ position ++ " >= " ++ size ++ ")")
  | .stringExtract, [value, start, stop] =>
      Except.ok
        ("((__ps_s: string, __ps_b: bigint, __ps_e: bigint) => { " ++
          "if (__ps_b >= __ps_e) return \"\"; let __ps_i = 0n; " ++
          "let __ps_started = false; let __ps_out = \"\"; " ++
          "for (const __ps_c of __ps_s) { " ++
          "const __ps_cp = __ps_c.codePointAt(0) ?? 0; " ++
          "const __ps_w = BigInt(__ps_cp <= 0x7f ? 1 : " ++
          "__ps_cp <= 0x7ff ? 2 : __ps_cp <= 0xffff ? 3 : 4); " ++
          "if (!__ps_started) { if (__ps_i === __ps_b) __ps_started = true; " ++
          "else { __ps_i += __ps_w; continue; } } " ++
          "if (__ps_i === __ps_e) return __ps_out; " ++
          "__ps_out += __ps_c; __ps_i += __ps_w; } return __ps_out; })(" ++
          value ++ ", " ++ start ++ ", " ++ stop ++ ")")
  | .stringEq, [left, right] =>
      Except.ok ("(" ++ left ++ " === " ++ right ++ ")")
  | .arrayEmptyWithCapacity, [capacity] =>
      Except.ok
        ("(() => { void (" ++ capacity ++ "); return []; })()")
  | .arraySize, [value] =>
      Except.ok ("BigInt((" ++ value ++ ").length)")
  | .arrayPush, [array, value] =>
      Except.ok ("[...(" ++ array ++ "), " ++ value ++ "]")
  | .arrayGet, [array, index] =>
      Except.ok
        ("(<T>(__ps_a: T[], __ps_i: bigint): T => " ++
          "__ps_a[Number(__ps_i)]!)(" ++
          array ++ ", " ++ index ++ ")")
  | .arrayGetD, [array, index, fallback] =>
      Except.ok
        ("(<T>(__ps_a: T[], __ps_i: bigint, __ps_fallback: T): T => " ++
          "(__ps_i < BigInt(__ps_a.length) ? " ++
          "__ps_a[Number(__ps_i)]! : __ps_fallback))(" ++
          array ++ ", " ++ index ++ ", " ++ fallback ++ ")")
  | .arraySet, [array, index, value] =>
      Except.ok
        ("(<T>(__ps_a: T[], __ps_i: bigint, __ps_v: T): T[] => {" ++
          " const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; " ++
          "return __ps_out; })(" ++
          array ++ ", " ++ index ++ ", " ++ value ++ ")")
  | .arraySetIfInBounds, [array, index, value] =>
      Except.ok
        ("(<T>(__ps_a: T[], __ps_i: bigint, __ps_v: T): T[] => { " ++
          "if (__ps_i >= BigInt(__ps_a.length)) return __ps_a; " ++
          "const __ps_out = [...__ps_a]; __ps_out[Number(__ps_i)] = __ps_v; " ++
          "return __ps_out; })(" ++
          array ++ ", " ++ index ++ ", " ++ value ++ ")")
  | .arrayMap, [fn, array] =>
      Except.ok
        ("(<A, B>(__ps_f: (__ps_x: A) => B, __ps_a: A[]): B[] => " ++
          "__ps_a.map((__ps_x) => __ps_f(__ps_x)))(" ++
          fn ++ ", " ++ array ++ ")")
  | .arrayFoldl, [fn, init, array, start, stop] =>
      Except.ok
        ("(<A, B>(__ps_f: (__ps_b: B, __ps_x: A) => B, __ps_init: B, " ++
          "__ps_a: A[], __ps_start: bigint, __ps_stop: bigint): B => {" ++
          " const __ps_size = BigInt(__ps_a.length); " ++
          "const __ps_end = __ps_stop <= __ps_size ? __ps_stop : __ps_size; " ++
          "let __ps_acc = __ps_init; " ++
          "for (let __ps_i = __ps_start; __ps_i < __ps_end; __ps_i += 1n) {" ++
          " __ps_acc = __ps_f(__ps_acc, __ps_a[Number(__ps_i)]!); } " ++
          "return __ps_acc; })(" ++
          fn ++ ", " ++ init ++ ", " ++ array ++ ", " ++
          start ++ ", " ++ stop ++ ")")
  | _, _ => Except.error PsTsEmitError.intrinsicArity

def psTsEmitExprWithFuel
    (brands : List (String × String))
    (tags : List (String × String)) :
    Nat -> PsVerifiedIrExpr -> Except PsTsEmitError String
  | 0, _ => Except.error PsTsEmitError.fuelExhausted
  | fuel + 1, expr =>
      match expr with
      | .literal literal =>
          psTsEmitLiteral literal
      | .var name =>
          Except.ok name
      | .intrinsic operation arguments =>
          match arguments.mapM
              (psTsEmitExprWithFuel brands tags fuel) with
          | Except.error error => Except.error error
          | Except.ok printed =>
              psTsEmitIntrinsicFromPrinted operation printed
      | .lambda parameters _ body =>
          let printParameter :=
            fun parameter =>
              match psTsEmitType parameter.type with
              | Except.error error => Except.error error
              | Except.ok type =>
                  Except.ok (parameter.name ++ ": " ++ type)
          match parameters.mapM printParameter with
          | Except.error error => Except.error error
          | Except.ok printedParameters =>
              match psTsEmitExprWithFuel brands tags fuel body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    ("(" ++ psTsJoin ", " printedParameters ++
                      ") => " ++ printedBody)
      | .call fn typeArguments arguments =>
          match psTsEmitExprWithFuel brands tags fuel fn with
          | Except.error error => Except.error error
          | Except.ok printedFn =>
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  match arguments.mapM
                      (psTsEmitExprWithFuel brands tags fuel) with
                  | Except.error error => Except.error error
                  | Except.ok printedArguments =>
                      Except.ok
                        (printedFn ++ generic ++ "(" ++
                          psTsJoin ", " printedArguments ++ ")")
      | .letE name _ value body =>
          match psTsEmitExprWithFuel brands tags fuel value with
          | Except.error error => Except.error error
          | Except.ok printedValue =>
              match psTsEmitExprWithFuel brands tags fuel body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  Except.ok
                    ("(() => { const " ++ name ++ " = " ++
                      printedValue ++ "; return " ++
                      printedBody ++ "; })()")
      | .ifE condition thenBranch elseBranch =>
          match psTsEmitExprWithFuel brands tags fuel condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match psTsEmitExprWithFuel brands tags fuel thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match psTsEmitExprWithFuel brands tags fuel elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        ("(" ++ printedCondition ++ " ? " ++
                          printedThen ++ " : " ++ printedElse ++ ")")
      | .record structureName fields =>
          match psTsLookup brands structureName with
          | none =>
              Except.error (PsTsEmitError.unknownStructure structureName)
          | some brand =>
              let printField :=
                fun field =>
                  match
                      psTsEmitExprWithFuel
                        brands
                        tags
                        fuel
                        field.2 with
                  | Except.error error => Except.error error
                  | Except.ok value =>
                      Except.ok (field.1 ++ ": " ++ value)
              match fields.mapM printField with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let suffix :=
                    if printedFields.isEmpty then
                      ""
                    else
                      ", " ++ psTsJoin ", " printedFields
                  Except.ok
                    ("{ [" ++ brand ++ "]: true" ++ suffix ++ " }")
      | .projection _ target field =>
          match psTsEmitExprWithFuel brands tags fuel target with
          | Except.error error => Except.error error
          | Except.ok printedTarget =>
              Except.ok (printedTarget ++ "." ++ field)
      | .constructor inductiveName constructorName typeArguments fields =>
          match psTsLookup tags inductiveName with
          | none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | some _ =>
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  let access :=
                    inductiveName ++ "[" ++
                      psJsonQuote constructorName ++ "]"
                  let printField :=
                    fun field =>
                      psTsEmitExprWithFuel
                        brands
                        tags
                        fuel
                        field.2
                  match fields.mapM printField with
                  | Except.error error => Except.error error
                  | Except.ok printedFields =>
                      if typeArguments.isEmpty && fields.isEmpty then
                        Except.ok access
                      else
                        Except.ok
                          (access ++ generic ++ "(" ++
                            psTsJoin ", " printedFields ++ ")")
      | .matchE inductiveName scrutinee alternatives =>
          match psTsLookup tags inductiveName with
          | none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | some tag =>
              let temp := psTsFreshMatchTemp expr
              let printAlternative :=
                fun alternative =>
                  let constructorName := alternative.1
                  let bindings := alternative.2.1
                  let body := alternative.2.2
                  match
                      psTsEmitExprWithFuel
                        brands
                        tags
                        fuel
                        body with
                  | Except.error error => Except.error error
                  | Except.ok printedBody =>
                      if bindings.isEmpty then
                        Except.ok
                          ("case " ++ psJsonQuote constructorName ++
                            ": return " ++ printedBody ++ ";")
                      else
                        let printBinding :=
                          fun binding =>
                            match psTsEmitType binding.type with
                            | Except.error error => Except.error error
                            | Except.ok type =>
                                Except.ok
                                  (binding.name ++ ": " ++ type)
                        match bindings.mapM printBinding with
                        | Except.error error => Except.error error
                        | Except.ok printedBindings =>
                            let arguments :=
                              bindings.map
                                (fun binding =>
                                  temp ++ "." ++ binding.field)
                            Except.ok
                              ("case " ++ psJsonQuote constructorName ++
                                ": return ((" ++
                                psTsJoin ", " printedBindings ++
                                ") => " ++ printedBody ++ ")(" ++
                                psTsJoin ", " arguments ++ ");")
              match alternatives.mapM printAlternative with
              | Except.error error => Except.error error
              | Except.ok cases =>
                  match
                      psTsEmitExprWithFuel
                        brands
                        tags
                        fuel
                        scrutinee with
                  | Except.error error => Except.error error
                  | Except.ok printedScrutinee =>
                      Except.ok
                        ("((" ++ temp ++ ") => { switch (" ++
                          temp ++ "[" ++ tag ++ "]) { " ++
                          psTsJoin " " cases ++
                          " } throw new Error(" ++
                          psJsonQuote
                            "invalid ProofScript constructor tag" ++
                          "); })(" ++ printedScrutinee ++ ")")

def psTsEmitExpr
    (brands : List (String × String))
    (tags : List (String × String))
    (expr : PsVerifiedIrExpr) :
    Except PsTsEmitError String :=
  psTsEmitExprWithFuel brands tags 4096 expr
