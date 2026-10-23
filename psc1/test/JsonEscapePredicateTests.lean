import Ps.Bridge.Json

namespace PsJsonEscapePredicateReference
def needsEscape (char : Char) : Bool :=
  let code : Nat := Char.toNat char
  Nat.blt code 32 || Nat.beq code 34 || Nat.beq code 92
end PsJsonEscapePredicateReference

theorem psJsonEscapePredicate_all_characters (char : Char) :
    psJsonCharNeedsEscape char = PsJsonEscapePredicateReference.needsEscape char := by
  unfold psJsonCharNeedsEscape PsJsonEscapePredicateReference.needsEscape
  dsimp
  cases h0 : Nat.blt (Char.toNat char) 32 <;>
    cases h1 : Nat.beq (Char.toNat char) 34 <;>
    cases h2 : Nat.beq (Char.toNat char) 92 <;>
    simp_all

#print axioms psJsonEscapePredicate_all_characters

def main : IO Unit := do
  for code in [:1114112] do
    let char := Char.ofNat code
    unless psJsonCharNeedsEscape char == PsJsonEscapePredicateReference.needsEscape char do
      throw (IO.userError s!"JSON escape predicate mismatch at {code}")
  IO.println "PSC1_JSON_ESCAPE_PREDICATE: all-Char equality proved; 1114112 native code-point inputs agree"
