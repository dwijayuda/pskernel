import Lean
open Lean

private def controlMutationReference (flag : Bool) : Nat := Id.run do
  let mut value : Nat := 3
  if flag then
    value := value + 4
  else
    value := value + 8
  value := value * 2
  return value

private def controlCaptureReference (flag : Bool) : Nat := Id.run do
  let mut value : Nat := if flag then 3 else 5
  let captured : Nat → Nat := fun n => value + n
  value := 100
  return captured value

private def controlEarlyReference (flag : Bool) : Nat := Id.run do
  let mut value : Nat := 3
  if flag then
    value := 7
    if Nat.beq value 7 then
      return value
    value := 50
  else
    value := 11
  value := value + 1
  return value

private def controlShadowReference (flag : Bool) : Nat := Id.run do
  let value : Bool := false
  let mut value : Nat := if flag then 3 else 5
  value := value + 1
  return value

private def controlDanglingReference (flag : Bool) : Nat := Id.run do
  let mut value : Nat := 3
  if flag then
    if false then
      value := 99
  else
    value := 50
  return value

private def dataLiteralReference (flag : Bool) : Int × Nat × Nat × Bool := Id.run do
  let pair : Int × (Bool × Int) := (-7, (flag, 13))
  let values : Array Int := #[pair.fst, pair.snd.snd, 29]
  let empty : Array Int := #[]
  return ((values[0]?).getD 0 + (values[1]?).getD 0, values.size, empty.size, pair.snd.fst)

private def controlErrorReference (flag : Bool) : Except Nat Nat := do
  let mut value : Nat := 3
  value := value + 4
  if flag then
    let _ignored : Unit ← Except.error value
    return 999
  return value

private def controlErrorValue (result : Except Nat Nat) : Nat :=
  match result with
  | .error value => value
  | .ok value => value

private def controlIsError (result : Except Nat Nat) : Bool :=
  match result with
  | .error _ => true
  | .ok _ => false

private def forListReference (flag : Bool) : Nat := Id.run do
  let mut total : Nat := 0
  for value in [1, 2, 3] do
    if flag && Nat.beq value 2 then
      return total
    total := total * 10 + value
  return total

private def forArrayReference (flag : Bool) : Nat := Id.run do
  let mut values : Array Nat := if flag then #[1, 2, 3] else #[]
  let mut total : Nat := 0
  for value in values do
    values := #[99]
    total := total + value
  return total * 10 + values.size

private def forRangeReference (flag : Bool) : Nat := Id.run do
  let mut lower : Nat := if flag then 2 else 5
  let mut upper : Nat := if flag then 5 else 2
  let mut total : Nat := 0
  for value in [lower:upper] do
    lower := 100
    upper := 0
    total := total * 10 + value
  return total

private def forRangeEmptyReference : Nat := Id.run do
  let mut total : Nat := 0
  for _value in [3:3] do
    total := total + 1
  return total

private def forRangeZeroReference : Nat := Id.run do
  let mut total : Nat := 0
  for value in [:3] do
    total := total * 10 + value
  return total

private def optionalArrayReference (flag : Bool) : Option Int :=
  let values : Array Int := #[-7, 13]
  let index : Nat := if flag then 1 else 2
  values[index]?

private def optionalArrayIsSome (result : Option Int) : Bool :=
  match result with
  | .none => false
  | .some _ => true

private def optionalArrayValue (result : Option Int) : Int :=
  match result with
  | .none => 0
  | .some value => value

/-- Executed under the same pinned Lean runtime as source admission. The JSON
uses decimal strings so a JavaScript test harness cannot round large integers. -/
def main : IO Unit := do
  let huge : Nat := 900719925474099312345678901234567890
  let text := "A😀é"
  let optionalValues : Array Int := #[-7, 13]
  let optionalEmpty : Array Int := #[]
  let values : List (String × Lean.Json) := [
    ("leanVersion", toJson Lean.versionString),
    ("leanCommit", toJson Lean.githash),
    ("huge", toJson (toString huge)),
    ("largeAdd", toJson (toString (huge + huge))),
    ("largeMul", toJson (toString (huge * 18446744073709551617))),
    ("natSub", toJson (toString ((3 : Nat) - 5))),
    ("natDivZero", toJson (toString (huge / 0))),
    ("natModZero", toJson (toString (huge % 0))),
    ("natDiv", toJson (toString ((17 : Nat) / 5))),
    ("natMod", toJson (toString ((17 : Nat) % 5))),
    ("intAdd", toJson (Int.repr ((-7 : Int) + (-13)))),
    ("intMul", toJson (Int.repr ((-7 : Int) * 3))),
    ("stringLength", toJson (toString text.length)),
    ("utf8Bytes", toJson (toString text.utf8ByteSize)),
    ("getValid", toJson (toString (String.Pos.Raw.get text ⟨1⟩).toNat)),
    ("getMiddle", toJson (toString (String.Pos.Raw.get text ⟨2⟩).toNat)),
    ("getEnd", toJson (toString (String.Pos.Raw.get text ⟨7⟩).toNat)),
    ("nextValid", toJson (toString (String.Pos.Raw.next text ⟨1⟩).byteIdx)),
    ("nextMiddle", toJson (toString (String.Pos.Raw.next text ⟨2⟩).byteIdx)),
    ("nextEnd", toJson (toString (String.Pos.Raw.next text ⟨7⟩).byteIdx)),
    ("extractValid", toJson (String.Pos.Raw.extract text ⟨1⟩ ⟨5⟩)),
    ("extractMiddle", toJson (String.Pos.Raw.extract text ⟨1⟩ ⟨3⟩)),
    ("charSurrogate", toJson (toString (Char.ofNat 55296).toNat)),
    ("charOutOfRange", toJson (toString (Char.ofNat 1114112).toNat)),
    ("charLarge", toJson (toString (Char.ofNat 4294967361).toNat)),
    ("controlMutationFalse", toJson (toString (controlMutationReference false))),
    ("controlMutationTrue", toJson (toString (controlMutationReference true))),
    ("controlCaptureFalse", toJson (toString (controlCaptureReference false))),
    ("controlCaptureTrue", toJson (toString (controlCaptureReference true))),
    ("controlEarlyFalse", toJson (toString (controlEarlyReference false))),
    ("controlEarlyTrue", toJson (toString (controlEarlyReference true))),
    ("controlShadowFalse", toJson (toString (controlShadowReference false))),
    ("controlShadowTrue", toJson (toString (controlShadowReference true))),
    ("controlErrorFalseValue", toJson (toString (controlErrorValue (controlErrorReference false)))),
    ("controlErrorTrueValue", toJson (toString (controlErrorValue (controlErrorReference true)))),
    ("controlErrorFalseTag", toJson (controlIsError (controlErrorReference false))),
    ("controlErrorTrueTag", toJson (controlIsError (controlErrorReference true))),
    ("controlDanglingFalse", toJson (toString (controlDanglingReference false))),
    ("controlDanglingTrue", toJson (toString (controlDanglingReference true))),
    ("literalTotal", toJson (Int.repr (dataLiteralReference true).1)),
    ("literalArraySize", toJson (toString (dataLiteralReference true).2.1)),
    ("literalEmptySize", toJson (toString (dataLiteralReference true).2.2.1)),
    ("literalFalseFlag", toJson (dataLiteralReference false).2.2.2),
    ("literalTrueFlag", toJson (dataLiteralReference true).2.2.2),
    ("forListFalse", toJson (toString (forListReference false))),
    ("forListTrue", toJson (toString (forListReference true))),
    ("forArrayFalse", toJson (toString (forArrayReference false))),
    ("forArrayTrue", toJson (toString (forArrayReference true))),
    ("forRangeFalse", toJson (toString (forRangeReference false))),
    ("forRangeTrue", toJson (toString (forRangeReference true))),
    ("forRangeEmpty", toJson (toString forRangeEmptyReference)),
    ("forRangeZero", toJson (toString forRangeZeroReference)),
    ("optionalIndexFalseTag", toJson (optionalArrayIsSome (optionalArrayReference false))),
    ("optionalIndexTrueTag", toJson (optionalArrayIsSome (optionalArrayReference true))),
    ("optionalIndexFalseValue", toJson (Int.repr (optionalArrayValue (optionalArrayReference false)))),
    ("optionalIndexTrueValue", toJson (Int.repr (optionalArrayValue (optionalArrayReference true)))),
    ("optionalHugeAbsent", toJson (!(optionalArrayIsSome (optionalValues[huge]?)))),
    ("optionalEmptyAbsent", toJson (!(optionalArrayIsSome (optionalEmpty[0]?))))]
  IO.println (Lean.Json.mkObj values).compress
