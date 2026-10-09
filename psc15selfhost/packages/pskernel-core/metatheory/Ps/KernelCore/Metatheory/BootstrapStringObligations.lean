import Ps.KernelCore.Metatheory.AdmissionEliminationNameConfiguration
import Init.Data.Nat.ToString

/--
Reflexivity depends only on termination of the synchronized cursor traversal.
The character read needs no equality specification when comparing a string
with itself. These cursor hypotheses are explicit obligations on the actual
opaque bootstrap operations; no global primitive law is postulated.
-/
theorem psKernelStringEqFromWithFuel_self_of_cursor_progress
    (value : String)
    (hEnd : ∀ pos : Nat, value.utf8ByteSize ≤ pos ->
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ pos : Nat,
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Internal.next value (String.Pos.Raw.mk pos)).byteIdx)
    (fuel : Nat) :
    ∀ pos : Nat, 0 < fuel -> value.utf8ByteSize < pos + fuel ->
      psKernelStringEqFromWithFuel fuel value value pos pos = true := by
  induction fuel with
  | zero => intro pos hFuel hBound; omega
  | succ remaining ih =>
      intro pos hFuel hBound
      cases hAtEnd : String.Internal.atEnd value (String.Pos.Raw.mk pos) with
      | true => simp [psKernelStringEqFromWithFuel, hAtEnd]
      | false =>
          have hBefore : pos < value.utf8ByteSize := by
            by_cases hBefore : pos < value.utf8ByteSize
            · exact hBefore
            · have hPast := hEnd pos (by omega)
              simp [hPast] at hAtEnd
          have hProgress := hStep pos hAtEnd
          have hTail := ih (String.Internal.next value (String.Pos.Raw.mk pos)).byteIdx
            (by omega) (by omega)
          simpa [psKernelStringEqFromWithFuel, hAtEnd] using hTail

theorem psKernelStringEq_self_of_cursor_progress
    (value : String)
    (hEnd : ∀ pos : Nat, value.utf8ByteSize ≤ pos ->
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ pos : Nat,
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Internal.next value (String.Pos.Raw.mk pos)).byteIdx) :
    psKernelStringEq value value = true := by
  have h := psKernelStringEqFromWithFuel_self_of_cursor_progress value hEnd hStep
    (Nat.succ value.utf8ByteSize) 0 (by omega) (by omega)
  simpa [psKernelStringEq] using h

/-- Explicit conditional reduction of comparator reflexivity to two cursor properties. -/
theorem psKernelStringEqReflexiveLaw_of_cursor_progress
    (hEnd : ∀ (value : String) (pos : Nat), value.utf8ByteSize ≤ pos ->
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ (value : String) (pos : Nat),
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Internal.next value (String.Pos.Raw.mk pos)).byteIdx) :
    PsKernelStringEqReflexiveLaw :=
  fun value => psKernelStringEq_self_of_cursor_progress value (hEnd value) (hStep value)

/-- Decimal representation is injective by the pinned checked digit round trip. -/
theorem psKernelNatToString_injective (left right : Nat)
    (hEqual : psKernelNatToString left = psKernelNatToString right) :
    left = right := by
  have hDecoded := congrArg (fun text : String => Nat.ofDigitChars 10 text.toList 0) hEqual
  simpa [psKernelNatToString, Int.repr] using hDecoded

/--
Candidate distinctness reduces to a bridge for just the actual prefixed decimal
strings. Decimal injectivity is proved above; the append bridge remains an
explicit unresolved hypothesis, not a new trusted axiom.
-/
theorem psKernelSimpleElimNameCandidate_injective_of_append_bridge
    (hAppend : ∀ value : Nat, 0 < value ->
      String.Internal.append "u_" (psKernelNatToString value) =
        "u_" ++ psKernelNatToString value)
    (left right : Nat)
    (hEqual : psKernelSimpleElimNameCandidate left = psKernelSimpleElimNameCandidate right) :
    left = right := by
  have hU : String.length "u" = 1 := by decide
  have hPrefix : String.length "u_" = 2 := by decide
  cases left with
  | zero =>
      cases right with
      | zero => rfl
      | succ right =>
          have hString : "u" = String.Internal.append "u_" (psKernelNatToString (Nat.succ right)) := by
            simpa [psKernelSimpleElimNameCandidate] using hEqual
          rw [hAppend (Nat.succ right) (by omega)] at hString
          have hLength := congrArg String.length hString
          simp only [String.length_append, hU, hPrefix] at hLength
          omega
  | succ left =>
      cases right with
      | zero =>
          have hString : String.Internal.append "u_" (psKernelNatToString (Nat.succ left)) = "u" := by
            simpa [psKernelSimpleElimNameCandidate] using hEqual
          rw [hAppend (Nat.succ left) (by omega)] at hString
          have hLength := congrArg String.length hString
          simp only [String.length_append, hU, hPrefix] at hLength
          omega
      | succ right =>
          have hString : String.Internal.append "u_" (psKernelNatToString (Nat.succ left)) =
              String.Internal.append "u_" (psKernelNatToString (Nat.succ right)) := by
            simpa [psKernelSimpleElimNameCandidate] using hEqual
          rw [hAppend (Nat.succ left) (by omega), hAppend (Nat.succ right) (by omega)] at hString
          exact psKernelNatToString_injective _ _ ((String.append_right_inj "u_").mp hString)

/--
All remaining primitive obligations are visible here. This is a conditional
composition theorem, not an unconditional freshness certificate.
-/
theorem psKernelSimpleFreshElimName_fresh_of_primitive_obligations
    (hString : PsKernelStringEqSoundLaw)
    (hAppend : ∀ value : Nat, 0 < value ->
      String.Internal.append "u_" (psKernelNatToString value) =
        "u_" ++ psKernelNatToString value)
    (hEnd : ∀ (value : String) (pos : Nat), value.utf8ByteSize ≤ pos ->
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = true)
    (hStep : ∀ (value : String) (pos : Nat),
      String.Internal.atEnd value (String.Pos.Raw.mk pos) = false ->
        pos < (String.Internal.next value (String.Pos.Raw.mk pos)).byteIdx)
    (params : List PsKernelName) :
    psKernelSimpleFreshElimName params ∉ params := by
  apply psKernelSimpleFreshElimName_fresh_of_distinct_candidates hString
    (psKernelStringEqReflexiveLaw_of_cursor_progress hEnd hStep) params
  intro i hi j hj hEqual
  exact psKernelSimpleElimNameCandidate_injective_of_append_bridge hAppend i j hEqual

/--
Checked reference operations already satisfy the cursor obligations. These are
facts about the specified standard operations, not bridges to Internal.*.
-/
theorem psKernelSpecifiedString_atEnd_of_bound (value : String) (pos : Nat)
    (hBound : value.utf8ByteSize ≤ pos) :
    String.Pos.Raw.atEnd value (String.Pos.Raw.mk pos) = true := by
  simp [String.Pos.Raw.atEnd, hBound]

theorem psKernelSpecifiedString_next_progress (value : String) (pos : Nat) :
    pos < (String.Pos.Raw.next value (String.Pos.Raw.mk pos)).byteIdx :=
  String.Pos.Raw.byteIdx_lt_byteIdx_next value (String.Pos.Raw.mk pos)
