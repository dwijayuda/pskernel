import Ps.KernelCore.Core.Name

theorem psKernelNameComponentAppend_eq_append
    (left right : List PsKernelNameComponent) :
    psKernelNameComponentAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelNameComponentAppend, ih]

theorem psKernelNameAppend_right_anonymous
    (base : PsKernelName) :
    psKernelNameAppend base PsKernelName.anonymous = base := by
  rfl

theorem psKernelNameAppend_left_anonymous
    (suffix : PsKernelName) :
    psKernelNameAppend PsKernelName.anonymous suffix = suffix := by
  induction suffix with
  | anonymous =>
      rfl
  | str parent value ih =>
      simp [psKernelNameAppend, ih]
  | num parent value ih =>
      simp [psKernelNameAppend, ih]

theorem psKernelNameAppend_assoc
    (a b c : PsKernelName) :
    psKernelNameAppend (psKernelNameAppend a b) c =
      psKernelNameAppend a (psKernelNameAppend b c) := by
  induction c with
  | anonymous =>
      rfl
  | str parent value ih =>
      simp [psKernelNameAppend, ih]
  | num parent value ih =>
      simp [psKernelNameAppend, ih]

theorem psKernelNameComponents_anonymous :
    psKernelNameComponents PsKernelName.anonymous = List.nil := by
  rfl

theorem psKernelNameListLength_eq_length
    (values : List PsKernelName) :
    psKernelNameListLength values = List.length values := by
  induction values with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelNameListLength, ih]


theorem psKernelStringEqFromWithFuel_symm
    (fuel : Nat)
    (left right : String)
    (leftPos rightPos : Nat) :
    psKernelStringEqFromWithFuel
        fuel left right leftPos rightPos =
      psKernelStringEqFromWithFuel
        fuel right left rightPos leftPos := by
  induction fuel generalizing leftPos rightPos with
  | zero =>
      rfl
  | succ remaining ih =>
      cases hLeft :
          String.Internal.atEnd
            left
            (String.Pos.Raw.mk leftPos) <;>
        cases hRight :
          String.Internal.atEnd
            right
            (String.Pos.Raw.mk rightPos) <;>
        simp [
          psKernelStringEqFromWithFuel,
          hLeft,
          hRight,
          ih,
          Nat.beq_comm
        ]

theorem psKernelStringEq_symm
    (left right : String) :
    psKernelStringEq left right =
      psKernelStringEq right left := by
  unfold psKernelStringEq
  rw [Nat.beq_comm (String.utf8ByteSize left)]
  cases hSize :
      Nat.beq
        (String.utf8ByteSize right)
        (String.utf8ByteSize left) with
  | false =>
      simp [hSize]
  | true =>
      simp [hSize]
      exact
        psKernelStringEqFromWithFuel_symm
          (Nat.succ (String.utf8ByteSize left))
          left
          right
          0
          0

theorem psKernelNameEq_symm
    (left right : PsKernelName) :
    psKernelNameEq left right =
      psKernelNameEq right left := by
  induction left generalizing right with
  | anonymous =>
      cases right <;> rfl
  | str leftParent leftValue ih =>
      cases right with
      | anonymous =>
          rfl
      | str rightParent rightValue =>
          rw [psKernelNameEq]
          rw [psKernelNameEq]
          rw [psKernelStringEq_symm leftValue rightValue]
          cases hString :
              psKernelStringEq rightValue leftValue with
          | false =>
              simp [hString]
          | true =>
              simp [hString]
              exact ih rightParent
      | num rightParent rightValue =>
          rfl
  | num leftParent leftValue ih =>
      cases right with
      | anonymous =>
          rfl
      | str rightParent rightValue =>
          rfl
      | num rightParent rightValue =>
          rw [psKernelNameEq]
          rw [psKernelNameEq]
          rw [Nat.beq_comm leftValue rightValue]
          cases hNat : Nat.beq rightValue leftValue with
          | false =>
              simp [hNat]
          | true =>
              simp [hNat]
              exact ih rightParent
