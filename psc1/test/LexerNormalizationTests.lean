import Ps.Syntax.Lexer

namespace PsLexerNormalizationReference
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


def legacyLean
    (inputBound : Nat)
    (fuel : Nat) :
    PsLexCursor -> Except PsLexError (List PsToken) :=
  match fuel with
  | 0 =>
      fun (cursor : PsLexCursor) =>
        if psLexCursorDone cursor then
          let position := cursor.position;
          let token : PsToken := {
            kind := PsTokenKind.endOfInput
            text := ""
            span := psLexSpan position position
          };
          Except.ok
            (List.cons token List.nil)
        else
          Except.error PsLexError.fuelExhausted
  | remainingFuel + 1 =>
      fun (cursor : PsLexCursor) =>
        let smaller :
            PsLexCursor ->
            Except PsLexError (List PsToken) :=
          legacyLean inputBound remainingFuel;
        match psLexSkipTriviaWithFuel inputBound cursor.remaining cursor.position with
        | Except.error error => Except.error error
        | Except.ok ready =>
            if psLexCursorDone ready then
              let position := ready.position;
              let token : PsToken := {
                kind := PsTokenKind.endOfInput
                text := ""
                span := psLexSpan position position
              };
              Except.ok
                (List.cons token List.nil)
            else
              match psLexReadToken ready with
              | Except.error error => Except.error error
              | Except.ok pair =>
                  let token : PsToken := pair.fst;
                  let next : PsLexCursor := pair.snd;
                  match smaller next with
                  | Except.error error => Except.error error
                  | Except.ok rest =>
                      Except.ok (List.cons token rest)

def legacyProofScript
    (inputBound : Nat)
    (fuel : Nat) :
    PsLexCursor -> Except PsLexError (List PsToken) :=
  match fuel with
  | 0 =>
      fun (cursor : PsLexCursor) =>
        if psLexCursorDone cursor then
          let position := cursor.position;
          let token : PsToken := {
            kind := PsTokenKind.endOfInput
            text := ""
            span := psLexSpan position position
          };
          Except.ok
            (List.cons token List.nil)
        else
          Except.error PsLexError.fuelExhausted
  | remainingFuel + 1 =>
      fun (cursor : PsLexCursor) =>
        let smaller :
            PsLexCursor ->
            Except PsLexError (List PsToken) :=
          legacyProofScript inputBound remainingFuel;
        match psLexSkipProofScriptTriviaWithFuel inputBound cursor.remaining cursor.position with
        | Except.error error => Except.error error
        | Except.ok ready =>
            if psLexCursorDone ready then
              let position := ready.position;
              let token : PsToken := {
                kind := PsTokenKind.endOfInput
                text := ""
                span := psLexSpan position position
              };
              Except.ok
                (List.cons token List.nil)
            else
              match psLexReadToken ready with
              | Except.error error => Except.error error
              | Except.ok pair =>
                  let token : PsToken := pair.fst;
                  let next : PsLexCursor := pair.snd;
                  match smaller next with
                  | Except.error error => Except.error error
                  | Except.ok rest =>
                      Except.ok (List.cons token rest)

def withPrefix (reversed : List PsToken) (result : Except PsLexError (List PsToken)) :
    Except PsLexError (List PsToken) :=
  match result with
  | .error error => .error error
  | .ok tokens => .ok (psListAppend (psListReverse reversed) tokens)

theorem lean_acc_eq (inputBound fuel : Nat) (cursor : PsLexCursor) (reversed : List PsToken) :
    psLexAllAccWorker inputBound fuel cursor reversed = withPrefix reversed (legacyLean inputBound fuel cursor) := by
  induction fuel generalizing cursor reversed with
  | zero =>
      simp only [psLexAllAccWorker, legacyLean]
      split <;> simp only [withPrefix, PsLexerNormalizationReference.reverse_cons]
  | succ remaining ih =>
      simp only [psLexAllAccWorker, legacyLean]
      cases skipped : psLexSkipTriviaWithFuel inputBound cursor.remaining cursor.position with
      | error error => simp only [skipped, withPrefix]
      | ok ready =>
          simp only [skipped]
          split
          · simp only [withPrefix, PsLexerNormalizationReference.reverse_cons]
          · cases read : psLexReadToken ready with
            | error error => simp only [read, withPrefix]
            | ok pair =>
                simp only [read]
                rw [ih]
                cases result : legacyLean inputBound remaining pair.snd with
                | error error => simp only [result, withPrefix]
                | ok rest =>
                    simp only [result, withPrefix, PsLexerNormalizationReference.reverse_cons,
                      PsLexerNormalizationReference.append_assoc, psListAppend]

theorem lean_normalized_eq (inputBound fuel : Nat) (cursor : PsLexCursor) :
    psLexAllWorker inputBound fuel cursor = legacyLean inputBound fuel cursor := by
  unfold psLexAllWorker
  rw [lean_acc_eq]
  cases legacyLean inputBound fuel cursor <;> rfl

theorem proofscript_acc_eq (inputBound fuel : Nat) (cursor : PsLexCursor) (reversed : List PsToken) :
    psLexAllProofScriptAccWorker inputBound fuel cursor reversed = withPrefix reversed (legacyProofScript inputBound fuel cursor) := by
  induction fuel generalizing cursor reversed with
  | zero =>
      simp only [psLexAllProofScriptAccWorker, legacyProofScript]
      split <;> simp only [withPrefix, PsLexerNormalizationReference.reverse_cons]
  | succ remaining ih =>
      simp only [psLexAllProofScriptAccWorker, legacyProofScript]
      cases skipped : psLexSkipProofScriptTriviaWithFuel inputBound cursor.remaining cursor.position with
      | error error => simp only [skipped, withPrefix]
      | ok ready =>
          simp only [skipped]
          split
          · simp only [withPrefix, PsLexerNormalizationReference.reverse_cons]
          · cases read : psLexReadToken ready with
            | error error => simp only [read, withPrefix]
            | ok pair =>
                simp only [read]
                rw [ih]
                cases result : legacyProofScript inputBound remaining pair.snd with
                | error error => simp only [result, withPrefix]
                | ok rest =>
                    simp only [result, withPrefix, PsLexerNormalizationReference.reverse_cons,
                      PsLexerNormalizationReference.append_assoc, psListAppend]

theorem proofscript_normalized_eq (inputBound fuel : Nat) (cursor : PsLexCursor) :
    psLexAllProofScriptWorker inputBound fuel cursor = legacyProofScript inputBound fuel cursor := by
  unfold psLexAllProofScriptWorker
  rw [proofscript_acc_eq]
  cases legacyProofScript inputBound fuel cursor <;> rfl

end PsLexerNormalizationReference

deriving instance BEq for PsSourcePos
deriving instance BEq for PsSourceSpan
deriving instance BEq for PsTokenKind
deriving instance BEq for PsToken
deriving instance BEq for PsLexError

private def sameResult (left right : Except PsLexError (List PsToken)) : Bool :=
  match left, right with
  | .ok a, .ok b => a == b
  | .error a, .error b => a == b
  | _, _ => false

def main : IO Unit := do
  let mut cases := 0
  for source in ["", "a b c", "λ \"🙂\" -- line\n42", "/- nested /- x -/ -/ a", "\"unterminated", "a\tb", "a\rb", "a\r\nb"] do
    let cursor := psLexCursorFromString source
    for bound in [0,1,2,source.utf8ByteSize + 1] do
      for fuel in [0,1,2,4,source.utf8ByteSize + 1] do
        if !sameResult (psLexAllWorker bound fuel cursor) (PsLexerNormalizationReference.legacyLean bound fuel cursor) then
          throw (IO.userError "PSC1_LEXER_LEAN_NORMALIZATION_MISMATCH")
        if !sameResult (psLexAllProofScriptWorker bound fuel cursor) (PsLexerNormalizationReference.legacyProofScript bound fuel cursor) then
          throw (IO.userError "PSC1_LEXER_PS_NORMALIZATION_MISMATCH")
        cases := cases + 2
  let large := String.intercalate "" (List.replicate 100000 "a ")
  for result in [psLex large, psLexProofScript large] do
    match result with
    | .error _ => throw (IO.userError "PSC1_LEXER_LARGE_FAILED")
    | .ok tokens =>
        if tokens.length != 100001 then throw (IO.userError "PSC1_LEXER_LARGE_LENGTH")
  IO.println ("PSC1_LEXER_NORMALIZATION: all input-bound/fuel/cursor/accumulator equalities proved for both grammars; cases=" ++ toString cases ++ "; 100001 tokens per grammar passed")
