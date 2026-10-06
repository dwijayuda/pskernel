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



theorem psKernelNatBeq_symm
    (left right : Nat) :
    Nat.beq left right = Nat.beq right left := by
  induction left generalizing right with
  | zero =>
      cases right <;> rfl
  | succ left ih =>
      cases right with
      | zero =>
          rfl
      | succ right =>
          exact ih right

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
      dsimp only [psKernelStringEqFromWithFuel]
      cases hLeft :
          String.Internal.atEnd
            left
            (String.Pos.Raw.mk leftPos) with
      | true =>
          cases hRight :
              String.Internal.atEnd
                right
                (String.Pos.Raw.mk rightPos) <;>
            simp [hLeft, hRight]
      | false =>
          cases hRight :
              String.Internal.atEnd
                right
                (String.Pos.Raw.mk rightPos) with
          | true =>
              simp [hLeft, hRight]
          | false =>
              let leftChar :=
                Char.toNat
                  (String.Internal.get
                    left
                    (String.Pos.Raw.mk leftPos))
              let rightChar :=
                Char.toNat
                  (String.Internal.get
                    right
                    (String.Pos.Raw.mk rightPos))
              cases hBeq : Nat.beq leftChar rightChar with
              | false =>
                  have hBeqSymm :
                      Nat.beq rightChar leftChar = false := by
                    rw [← psKernelNatBeq_symm leftChar rightChar]
                    exact hBeq
                  simp [
                    hLeft,
                    hRight,
                    leftChar,
                    rightChar,
                    hBeq,
                    hBeqSymm
                  ]
              | true =>
                  have hBeqSymm :
                      Nat.beq rightChar leftChar = true := by
                    rw [← psKernelNatBeq_symm leftChar rightChar]
                    exact hBeq
                  simp [
                    hLeft,
                    hRight,
                    leftChar,
                    rightChar,
                    hBeq,
                    hBeqSymm
                  ]
                  exact
                    ih
                      (String.Pos.Raw.byteIdx
                        (String.Internal.next
                          left
                          (String.Pos.Raw.mk leftPos)))
                      (String.Pos.Raw.byteIdx
                        (String.Internal.next
                          right
                          (String.Pos.Raw.mk rightPos)))

theorem psKernelStringEq_symm
    (left right : String) :
    psKernelStringEq left right =
      psKernelStringEq right left := by
  unfold psKernelStringEq
  rw [
    psKernelNatBeq_symm
      (String.utf8ByteSize left)
      (String.utf8ByteSize right)
  ]
  cases hSize :
      Nat.beq
        (String.utf8ByteSize right)
        (String.utf8ByteSize left) with
  | false =>
      simp [hSize]
  | true =>
      have hSizeEq :
          String.utf8ByteSize right =
            String.utf8ByteSize left := by
        simpa using hSize
      rw [hSizeEq]
      simp
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
          change
            (if psKernelStringEq leftValue rightValue = true then
              psKernelNameEq leftParent rightParent
            else false) =
            (if psKernelStringEq rightValue leftValue = true then
              psKernelNameEq rightParent leftParent
            else false)
          rw [psKernelStringEq_symm leftValue rightValue]
          rw [ih rightParent]
      | num rightParent rightValue =>
          rfl
  | num leftParent leftValue ih =>
      cases right with
      | anonymous =>
          rfl
      | str rightParent rightValue =>
          rfl
      | num rightParent rightValue =>
          change
            (if Nat.beq leftValue rightValue = true then
              psKernelNameEq leftParent rightParent
            else false) =
            (if Nat.beq rightValue leftValue = true then
              psKernelNameEq rightParent leftParent
            else false)
          rw [psKernelNatBeq_symm leftValue rightValue]
          rw [ih rightParent]
