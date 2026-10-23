import Ps.Syntax.Lexer

namespace PsCursorNormalizationReference
def legacyLengthAcc {α : Type} (xs : List α) : Nat -> Nat :=
  match xs with
  | List.nil => fun (acc : Nat) => acc
  | List.cons _ rest =>
      fun (acc : Nat) =>
        let smaller : Nat -> Nat := legacyLengthAcc rest;
        smaller (Nat.succ acc)


def legacy (fuel : Nat) : String -> Nat -> List Char :=
  match fuel with
  | Nat.zero => fun (_source : String) (_position : Nat) => List.nil
  | Nat.succ remaining =>
      fun (source : String) (position : Nat) =>
        let smaller : String -> Nat -> List Char := legacy remaining;
        if
            String.Internal.atEnd
              source
              (String.Pos.Raw.mk position) then
          List.nil
        else
          let char : Char :=
            String.Internal.get
              source
              (String.Pos.Raw.mk position);
          let nextPosition : Nat :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                source
                (String.Pos.Raw.mk position));
          List.cons
            char
            (smaller source nextPosition)


theorem append_nil {alpha : Type} (values : List alpha) :
    psListAppend values [] = values := by
  induction values with
  | nil => rfl
  | cons head tail ih => simp only [psListAppend, ih]

theorem append_assoc {alpha : Type} (left middle right : List alpha) :
    psListAppend (psListAppend left middle) right =
      psListAppend left (psListAppend middle right) := by
  induction left with
  | nil => rfl
  | cons head tail ih => simp only [psListAppend, ih]

theorem reverse_acc_append {alpha : Type} (values acc : List alpha) :
    psListReverseAcc values acc =
      psListAppend (psListReverseAcc values []) acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      change psListReverseAcc tail (head :: acc) =
        psListAppend (psListReverseAcc tail [head]) acc
      rw [ih (head :: acc), ih [head], append_assoc]
      all_goals rfl

theorem reverse_cons {alpha : Type} (head : alpha) (tail : List alpha) :
    psListReverse (head :: tail) = psListAppend (psListReverse tail) [head] := by
  exact reverse_acc_append tail [head]

theorem accumulator_eq (fuel : Nat) (source : String) (position : Nat) (reversed : List Char) :
    psLexStringToListAccWithFuel fuel source position reversed =
      psListAppend (psListReverse reversed) (legacy fuel source position) := by
  induction fuel generalizing source position reversed with
  | zero =>
      exact (append_nil (psListReverse reversed)).symm
  | succ remaining ih =>
      by_cases ended : String.Internal.atEnd source (String.Pos.Raw.mk position) = true
      · simp only [psLexStringToListAccWithFuel, legacy, if_pos ended]
        exact (append_nil (psListReverse reversed)).symm
      · simp only [psLexStringToListAccWithFuel, legacy, if_neg ended]
        rw [ih, reverse_cons, append_assoc]
        all_goals rfl

theorem normalized_eq (fuel : Nat) (source : String) (position : Nat) :
    legacy fuel source position = psLexStringToListFromWithFuel fuel source position := by
  unfold psLexStringToListFromWithFuel
  rw [accumulator_eq]
  all_goals rfl

theorem length_acc_eq {alpha : Type} (values : List alpha) :
    legacyLengthAcc values = psLexListLengthAcc values := by
  induction values with
  | nil => rfl
  | cons head tail ih =>
      funext count
      simp only [legacyLengthAcc, psLexListLengthAcc, ih]
      all_goals rfl
end PsCursorNormalizationReference

def main : IO Unit := do
  let mut count := 0
  for source in ["", "abc", "λ🙂", "a\nλ\r🙂", String.singleton (Char.ofNat 0), "quote\\\"slash\\\\"] do
    for position in List.range (source.utf8ByteSize + 3) do
      for fuel in [0,1,2,3,source.utf8ByteSize,source.utf8ByteSize + 1] do
        if psLexStringToListFromWithFuel fuel source position !=
            PsCursorNormalizationReference.legacy fuel source position then
          throw (IO.userError "PSC1_CURSOR_NORMALIZATION_MISMATCH")
        count := count + 1
  let source := String.intercalate "" (List.replicate 50000 "λ🙂")
  let chars := psLexStringToList source
  if chars.length != 100000 then
    throw (IO.userError "PSC1_CURSOR_NORMALIZATION_LARGE_INPUT")
  if psLexListLengthAcc chars 7 != 100007 then
    throw (IO.userError "PSC1_CURSOR_GENERIC_LENGTH_LARGE_INPUT")
  IO.println ("PSC1_CURSOR_NORMALIZATION: all-input fuel/source/offset equality proved; UTF8 offset/fuel cases=" ++
    toString count ++ "; large input chars=100000; all-input generic length equality and 100007 result passed")
