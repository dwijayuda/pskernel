import Ps.Syntax.ParserState

theorem psListLengthAccCorrect {alpha : Type} (values : List alpha) (count : Nat) :
    psListLengthAcc values count = count + values.length := by
  induction values generalizing count with
  | nil => rfl
  | cons value rest ih =>
      simp [psListLengthAcc, ih, Nat.add_comm, Nat.add_left_comm]

theorem psListLengthCorrect {alpha : Type} (values : List alpha) :
    psListLength values = values.length := by
  simp [psListLength, psListLengthAccCorrect]

def PsTokenCursorWellFormed (cursor : PsTokenCursor) : Prop :=
  cursor.remainingCount = cursor.remaining.length

theorem psTokenCursorFromTokensWellFormed (tokens : List PsToken) :
    PsTokenCursorWellFormed (psTokenCursorFromTokens tokens) := by
  simp [PsTokenCursorWellFormed, psTokenCursorFromTokens, psListLengthCorrect]

theorem psTokenCursorAdvanceWellFormed (cursor : PsTokenCursor) (read : PsTokenRead)
    (wellFormed : PsTokenCursorWellFormed cursor)
    (advanced : psTokenCursorAdvance cursor = Option.some read) :
    PsTokenCursorWellFormed read.cursor := by
  rcases cursor with ⟨tokens, count⟩
  cases tokens with
  | nil => simp [psTokenCursorAdvance] at advanced
  | cons token rest =>
      simp [psTokenCursorAdvance] at advanced
      cases advanced
      simp [PsTokenCursorWellFormed] at wellFormed ⊢
      omega

theorem psTokenCursorDropPrefixWellFormed
    (cursor : PsTokenCursor) (consumed rest : List PsToken)
    (wellFormed : PsTokenCursorWellFormed cursor)
    (decomposition : cursor.remaining = consumed ++ rest) :
    PsTokenCursorWellFormed
      (PsTokenCursor.mk rest (cursor.remainingCount - consumed.length)) := by
  simp [PsTokenCursorWellFormed] at wellFormed ⊢
  rw [decomposition, List.length_append] at wellFormed
  omega
