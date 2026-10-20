import Lean

/-- Executed under the same pinned Lean runtime as source admission. The JSON
uses decimal strings so a JavaScript test harness cannot round large integers. -/
def main : IO Unit := do
  let huge : Nat := 900719925474099312345678901234567890
  let text := "A😀é"
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
    ("charLarge", toJson (toString (Char.ofNat 4294967361).toNat))]
  IO.println (Lean.Json.mkObj values).compress
