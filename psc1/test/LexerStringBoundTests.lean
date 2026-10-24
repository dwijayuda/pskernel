import Ps.Syntax.Lexer
import Lean

namespace LexerStringBoundTests

theorem length_acc {α : Type} (xs : List α) (acc : Nat) :
    psLexListLengthAcc xs acc = xs.length + acc := by
  induction xs generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      simp only [psLexListLengthAcc, List.length_cons]
      rw [ih]
      omega

theorem length_eq {α : Type} (xs : List α) :
    psLexListLength xs = xs.length := by
  unfold psLexListLength
  rw [length_acc]
  omega

theorem sufficient_fuel (fuel : Nat) (remaining : List Char)
    (position start : PsSourcePos) (charsRev : List Char)
    (enough : remaining.length < fuel) :
    psLexReadStringBodyWithFuel fuel remaining position start charsRev =
      psLexReadStringBodyStructural remaining position start charsRev := by
  induction fuel generalizing remaining position charsRev with
  | zero => omega
  | succ fuel ih =>
      cases remaining with
      | nil => rfl
      | cons char rest =>
          simp only [psLexReadStringBodyWithFuel, psLexReadStringBodyStructural]
          split
          · rfl
          · split
            · rfl
            · split
              · cases rest with
                | nil => rfl
                | cons escaped tail =>
                    simp only
                    apply ih
                    simp only [List.length_cons] at enough
                    omega
              · apply ih
                simp only [List.length_cons] at enough
                omega

theorem exact_original (remaining : List Char) (position start : PsSourcePos)
    (charsRev : List Char) :
    psLexReadStringBody remaining position start charsRev =
      psLexReadStringBodyWithFuel
        (Nat.add (psLexListLength remaining) 1) remaining position start charsRev := by
  unfold psLexReadStringBody
  symm
  apply sufficient_fuel
  rw [length_eq]
  omega

end LexerStringBoundTests

#print axioms LexerStringBoundTests.sufficient_fuel
#print axioms LexerStringBoundTests.exact_original

def main : IO Unit :=
  IO.println "PSC1_LEXER_STRING_BOUND: all character lists, source positions, accumulators, outcomes and original fuel-bound API proved equal"
