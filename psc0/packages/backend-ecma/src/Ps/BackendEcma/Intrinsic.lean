import Ps.BackendEcma.Syntax

namespace PsEcma

def compareOp : PsVerifiedIrIntegerCompareOp → String
  | .eq => "===" | .ne => "!==" | .lt => "<" | .le => "<=" | .gt => ">" | .ge => ">="
def floatCompareOp : PsVerifiedIrFloatCompareOp → String
  | .eq => "===" | .ne => "!==" | .lt => "<" | .le => "<=" | .gt => ">" | .ge => ">="
def machineNormalize (type : PsVerifiedIrMachineIntegerType) (value : Expr) : Except String Expr :=
  match type with
  | .uint8 => pure (bin "&" value (num 255))
  | .uint16 => pure (bin "&" value (num 65535))
  | .uint32 => pure (bin ">>>" value (num 0))
  | .int8 => pure (bin ">>" (bin "<<" value (num 24)) (num 24))
  | .int16 => pure (bin ">>" (bin "<<" value (num 16)) (num 16))
  | .int32 => pure (bin "|" value (num 0))
  | .uint64 => pure (call "BigInt.asUintN" [num 64, value])
  | .int64 => pure (call "BigInt.asIntN" [num 64, value])
  | .usize | .isize => .error "PSCV0-ECMA: target word size required"
def machineBinary (type : PsVerifiedIrMachineIntegerType) (op : PsVerifiedIrIntegerBinaryOp)
    (a b : Expr) : Except String Expr := do
  let some width := psIrMachineIntegerFixedWidth type
    | throw "PSCV0-ECMA: target word size required"
  let wide := width == 64
  let scalar := if wide then "bigint" else "number"
  let zero := if wide then id "0n" else num 0
  let shiftMask := if wide then id "63n" else num (width - 1)
  let raw ← match op with
    | .add => pure (bin "+" a b) | .sub => pure (bin "-" a b)
    | .bitAnd => pure (bin "&" a b) | .bitOr => pure (bin "|" a b)
    | .bitXor => pure (bin "^" a b)
    | .mul => pure (if wide then bin "*" a b else call "Math.imul" [a, b])
    | .shiftLeft => pure (bin "<<" a (bin "&" b shiftMask))
    | .shiftRight => pure (bin
        (if wide || psIrMachineIntegerIsSigned type then ">>" else ">>>")
        a (bin "&" b shiftMask))
    | .div | .mod =>
      let remainder := match op with | .mod => true | _ => false
      let lhs := id "__ps_a"
      let rhs := id "__ps_b"
      let arithmetic := bin (if remainder then "%" else "/") lhs rhs
      let arithmetic := if wide || remainder then arithmetic else call "Math.trunc" [arithmetic]
      pure (invoke [{ name := "__ps_a", type := scalar }, { name := "__ps_b", type := scalar }]
        scalar [ret (.conditional (bin "===" rhs zero)
          (if remainder then lhs else zero) arithmetic)] [a, b])
  machineNormalize type raw

def bigPair (a b : Expr) (body : Expr) : Expr :=
  invoke [{ name := "__ps_a", type := "bigint" }, { name := "__ps_b", type := "bigint" }]
    "bigint" [ret body] [a, b]
def equal (type op : String) (a b : Expr) : Expr := bin op (.cast a type) (.cast b type)
def arrayBounds : Expr :=
  bin "||" (bin "<" (id "__ps_index") (id "0n"))
    (bin ">=" (id "__ps_index") (call "BigInt" [field (id "__ps_array") "length"]))
def arrayParams : List Parameter :=
  [{ name := "__ps_array", type := "T[]" }, { name := "__ps_index", type := "bigint" }]
def arrayAt : Expr := .nonnull (.index (id "__ps_array") (call "Number" [id "__ps_index"]))

def intrinsic (op : PsVerifiedIrIntrinsic) (types : List PsVerifiedIrType) (args : List Expr) :
    Except String Expr := do
  match op, args with
  | .hashMix, [a,b] => pure (call "__ps$hashMix" [a,b])
  | .stringHash, [a] => pure (call "__ps$stringHash" [a])
  | .unsignedOfNat type, [value] => do
    let width ← match type with
      | .uint8 => pure 8 | .uint16 => pure 16 | .uint32 => pure 32 | .uint64 => pure 64
      | _ => throw "PSCV0-ECMA: unsupported unsigned width"
    let wrapped := call "BigInt.asUintN" [num width, value]
    pure (match type with | .uint64 => wrapped | _ => call "Number" [wrapped])
  | .signedToUnsigned type, [value] => do
    let some width := psIrMachineIntegerFixedWidth type
      | throw "PSCV0-ECMA: signed carrier requires fixed width"
    unless psIrMachineIntegerIsSigned type do
      throw "PSCV0-ECMA: signed carrier requires signed input"
    let bits := call "BigInt.asUintN" [num width, call "BigInt" [value]]
    pure (if width == 64 then bits else call "Number" [bits])
  | .signedOfNat type, [value] => do
    let some width := psIrMachineIntegerFixedWidth type
      | throw "PSCV0-ECMA: signed platform width is not qualified"
    unless psIrMachineIntegerIsSigned type do
      throw "PSCV0-ECMA: signedOfNat requires a signed width"
    let wrapped := call "BigInt.asIntN" [num width, value]
    pure (if width == 64 then wrapped else call "Number" [wrapped])
  | .unsignedToNat _, [value] => pure (call "BigInt" [value])
  | .machineIntBinary type op, [a,b] => machineBinary type op a b
  | .machineIntCompare _ op, [a,b] => pure (bin (compareOp op) a b)
  | .floatOfBits type, [value] => pure (call
      (match type with | .float => "__ps$float64OfBits" | .float32 => "__ps$float32OfBits") [value])
  | .floatToBits type, [value] => pure (call
      (match type with | .float => "__ps$float64ToBits" | .float32 => "__ps$float32ToBits") [value])
  | .floatUnary _ op, [value] =>
    pure (match op with | .neg => unary "-" value | .abs => call "Math.abs" [value])
  | .floatTest _ op, [value] =>
    pure (match op with
      | .isNaN => call "Number.isNaN" [value]
      | .isFinite => call "Number.isFinite" [value]
      | .isInf => bin "===" (call "Math.abs" [value]) (id "Infinity"))
  | .floatBinary type op, [a,b] =>
    let value := bin (match op with | .add => "+" | .sub => "-" | .mul => "*" | .div => "/") a b
    pure (match type with | .float => value | .float32 => call "Math.fround" [value])
  | .floatCompare _ op, [a,b] => pure (bin (floatCompareOp op) a b)
  | .natAdd, [a,b] | .intAdd, [a,b] | .stringPush, [a,b] | .stringAppend, [a,b] => pure (bin "+" a b)
  | .natPow, [a,b] => pure (bin "**" a b)
  | .natMul, [a,b] | .intMul, [a,b] => pure (bin "*" a b)
  | .intSub, [a,b] => pure (bin "-" a b)
  | .natSub, [a,b] => pure (bigPair a b (.conditional
      (bin ">=" (id "__ps_a") (id "__ps_b")) (bin "-" (id "__ps_a") (id "__ps_b")) (id "0n")))
  | .natDiv, [a,b] => pure (bigPair a b (.conditional
      (bin "===" (id "__ps_b") (id "0n")) (id "0n") (bin "/" (id "__ps_a") (id "__ps_b"))))
  | .natMod, [a,b] => pure (bigPair a b (.conditional
      (bin "===" (id "__ps_b") (id "0n")) (id "__ps_a") (bin "%" (id "__ps_a") (id "__ps_b"))))
  | .natEq, [a,b] | .intEq, [a,b] => pure (equal "bigint" "===" a b)
  | .natNe, [a,b] => pure (equal "bigint" "!==" a b)
  | .natLe, [a,b] | .intLe, [a,b] => pure (bin "<=" a b)
  | .natLt, [a,b] | .intLt, [a,b] => pure (bin "<" a b)
  | .intOfNat, [a] | .stringSingleton, [a] => pure a
  | .intToNat, [a] => pure (invoke [{ name := "__ps_value", type := "bigint" }] "bigint"
      [ret (.conditional (bin "<" (id "__ps_value") (id "0n")) (id "0n") (id "__ps_value"))] [a])
  | .intRepr, [a] => pure (method a "toString" [])
  | .intNeg, [a] => pure (unary "-" a)
  | .intNegSucc, [a] => pure (unary "-" (bin "+" a (id "1n")))
  | .boolNot, [a] => pure (unary "!" a)
  | .boolAnd, [a,b] => pure (bin "&&" a b)
  | .boolOr, [a,b] => pure (bin "||" a b)
  | .boolEq, [a,b] => pure (equal "boolean" "===" a b)
  | .boolNe, [a,b] => pure (equal "boolean" "!==" a b)
  | .charOfNat, [a] => pure (invoke [{ name := "__ps_code", type := "bigint" }] "string" [
      ret (.conditional
        (bin "||" (bin "<" (id "__ps_code") (id "0xd800n"))
          (bin "&&" (bin ">" (id "__ps_code") (id "0xdfffn")) (bin "<" (id "__ps_code") (id "0x110000n"))))
        (call "String.fromCodePoint" [call "Number" [id "__ps_code"]]) (str (String.singleton (Char.ofNat 0))))] [a])
  | .charToNat, [a] => pure (call "BigInt" [bin "??" (method a "codePointAt" [num 0]) (num 0)])
  | .stringLength, [a] => pure (call "BigInt" [field (call "Array.from" [a]) "length"])
  | .stringUtf8ByteSize, [a] => pure (field (call "__ps$utf8" [a]) "size")
  | .stringNext, [a,b] => pure (call "__ps$stringNext" [a,b])
  | .stringGet, [a,b] => pure (call "__ps$stringGet" [a,b])
  | .stringAtEnd, [a,b] => pure (invoke
      [{ name := "__ps_text", type := "string" }, { name := "__ps_position", type := "bigint" }]
      "boolean" [ret (bin ">=" (id "__ps_position") (field (call "__ps$utf8" [id "__ps_text"]) "size"))] [a,b])
  | .stringExtract, [a,b,c] => pure (call "__ps$stringExtract" [a,b,c])
  | .stringEq, [a,b] => pure (equal "string" "===" a b)
  | .arrayBuild, [count,seed,head,tail] =>
      let [a,s] ← types.mapM irType | throw "PSCV0-ECMA: arrayBuild type arguments"
      pure (delegate [
        .binding false "__ps_result" (a ++ "[]") (some (.array [])),
        letE "__ps_cursor" (id "__ps_seed"), letE "__ps_index" (id "0n"),
        .whileE (bin "<" (id "__ps_index") (id "__ps_count")) [
          .expression (method (id "__ps_result") "push" [
            unary "yield* " (call "__ps$invoke" [id "__ps_head", id "__ps_cursor"])]),
          set (id "__ps_cursor") (unary "yield* " (call "__ps$invoke" [id "__ps_tail", id "__ps_cursor"])),
          inc "__ps_index" (id "1n")],
        ret (id "__ps_result")]
        [{ name := "__ps_count", type := "bigint" }, { name := "__ps_seed", type := s },
         { name := "__ps_head", type := "(state: " ++ s ++ ") => " ++ a },
         { name := "__ps_tail", type := "(state: " ++ s ++ ") => " ++ s }]
        [count,seed,head,tail] ("__ps$Computation<" ++ a ++ "[]>"))
  | .arrayEmptyWithCapacity, [capacity] =>
      pure (invoke [{ name := "__ps_capacity", type := "bigint" }] ""
        [.expression (unary "void " (id "__ps_capacity")), ret (.array [])] [capacity])
  | .arraySize, [a] => pure (call "BigInt" [field a "length"])
  | .arrayPush, [a,b] => pure (.array [unary "..." a,b])
  | .arrayGet, [a,b] =>
      pure (invoke arrayParams "T" [
        .ifE arrayBounds [.throwE (.object [("code", str "PSC0_ARRAY_GET_BOUNDS")])] [],
        ret arrayAt] [a,b] "<T>")
  | .arrayGetD, [a,b,c] =>
      pure (invoke (arrayParams ++ [{ name := "__ps_fallback", type := "T" }]) "T" [
        ret (.conditional (bin "<" (id "__ps_index") (call "BigInt" [field (id "__ps_array") "length"]))
          arrayAt (id "__ps_fallback"))] [a,b,c] "<T>")
  | .arraySet, [a,b,c] | .arraySetIfInBounds, [a,b,c] =>
      let guard := match op with
        | .arraySet => Stmt.ifE arrayBounds [.throwE (.object [("code", str "PSC0_ARRAY_SET_BOUNDS")])] []
        | _ => Stmt.ifE (bin ">=" (id "__ps_index") (call "BigInt" [field (id "__ps_array") "length"]))
            [ret (id "__ps_array")] []
      pure (invoke (arrayParams ++ [{ name := "__ps_value", type := "T" }]) "T[]" [
        guard, const "__ps_result" (.array [unary "..." (id "__ps_array")]),
        set (.index (id "__ps_result") (call "Number" [id "__ps_index"])) (id "__ps_value"),
        ret (id "__ps_result")] [a,b,c] "<T>")
  | .arrayMap, [fn,array] =>
      let [a,b] ← types.mapM irType | throw "PSCV0-ECMA: arrayMap type arguments"
      pure (delegate [
        .binding false "__ps_result" (b ++ "[]") (some (.array [])),
        .forOf "__ps_element" (id "__ps_array") [
          .expression (method (id "__ps_result") "push" [
            unary "yield* " (call "__ps$invoke" [id "__ps_fn", id "__ps_element"])])],
        ret (id "__ps_result")]
        [{ name := "__ps_fn", type := "(value: " ++ a ++ ") => " ++ b },
          { name := "__ps_array", type := a ++ "[]" }] [fn,array] ("__ps$Computation<" ++ b ++ "[]>"))
  | .arrayFoldl, [fn,initial,array,start,stop] =>
      let [a,b] ← types.mapM irType | throw "PSCV0-ECMA: arrayFoldl type arguments"
      pure (delegate [
        const "__ps_size" (call "BigInt" [field (id "__ps_array") "length"]),
        const "__ps_end" (.conditional (bin "<=" (id "__ps_stop") (id "__ps_size")) (id "__ps_stop") (id "__ps_size")),
        letE "__ps_acc" (id "__ps_initial"), letE "__ps_index" (id "__ps_start"),
        .whileE (bin "<" (id "__ps_index") (id "__ps_end")) [
          set (id "__ps_acc") (unary "yield* " (call "__ps$invoke" [id "__ps_fn", id "__ps_acc", arrayAt])),
          inc "__ps_index" (id "1n")],
        ret (id "__ps_acc")]
        [{ name := "__ps_fn", type := "(acc: " ++ b ++ ", value: " ++ a ++ ") => " ++ b },
          { name := "__ps_initial", type := b }, { name := "__ps_array", type := a ++ "[]" },
          { name := "__ps_start", type := "bigint" }, { name := "__ps_stop", type := "bigint" }]
        [fn,initial,array,start,stop] ("__ps$Computation<" ++ b ++ ">"))
  | _, _ => throw "PSCV0-ECMA: intrinsic arity"

end PsEcma
