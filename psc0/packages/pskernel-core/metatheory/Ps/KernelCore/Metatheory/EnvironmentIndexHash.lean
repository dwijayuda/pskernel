import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex

/-
Hash compatibility for the environment acceleration index.

The semantic name comparator is the authority for declaration identity.  These
theorems show that comparator-equal names necessarily take the same hash route,
which is required before the trie index can be proved refinement-only.
-/

theorem psKernelEnvironmentHashStringWorker_of_stringEqFrom_true
    (fuel : Nat)
    (left right : String)
    (leftPos rightPos hash : Nat)
    (hEq :
      psKernelStringEqFromWithFuel
          fuel left right leftPos rightPos = true) :
    psKernelEnvironmentHashStringWorker
        fuel left leftPos hash =
      psKernelEnvironmentHashStringWorker
        fuel right rightPos hash := by
  induction fuel generalizing leftPos rightPos hash with
  | zero =>
      simp [psKernelStringEqFromWithFuel] at hEq
  | succ remaining ih =>
      cases hLeft :
          String.Pos.Raw.atEnd
            left
            (String.Pos.Raw.mk leftPos) with
      | true =>
          cases hRight :
              String.Pos.Raw.atEnd
                right
                (String.Pos.Raw.mk rightPos) with
          | false =>
              simp [
                psKernelStringEqFromWithFuel,
                hLeft,
                hRight
              ] at hEq
          | true =>
              simp [
                psKernelEnvironmentHashStringWorker,
                hLeft,
                hRight
              ]
      | false =>
          cases hRight :
              String.Pos.Raw.atEnd
                right
                (String.Pos.Raw.mk rightPos) with
          | true =>
              simp [
                psKernelStringEqFromWithFuel,
                hLeft,
                hRight
              ] at hEq
          | false =>
              let leftChar :=
                String.Internal.get
                  left
                  (String.Pos.Raw.mk leftPos)
              let rightChar :=
                String.Internal.get
                  right
                  (String.Pos.Raw.mk rightPos)
              by_cases hChar :
                  Char.toNat leftChar =
                    Char.toNat rightChar
              · have hRest :
                    psKernelStringEqFromWithFuel
                        remaining
                        left
                        right
                        (String.Pos.Raw.byteIdx
                          (String.Pos.Raw.next
                            left
                            (String.Pos.Raw.mk leftPos)))
                        (String.Pos.Raw.byteIdx
                          (String.Pos.Raw.next
                            right
                            (String.Pos.Raw.mk rightPos))) =
                      true := by
                  simpa [
                    psKernelStringEqFromWithFuel,
                    hLeft,
                    hRight,
                    leftChar,
                    rightChar,
                    hChar
                  ] using hEq
                have hIH :=
                  ih
                    (String.Pos.Raw.byteIdx
                      (String.Pos.Raw.next
                        left
                        (String.Pos.Raw.mk leftPos)))
                    (String.Pos.Raw.byteIdx
                      (String.Pos.Raw.next
                        right
                        (String.Pos.Raw.mk rightPos)))
                    (Nat.mod
                      (Nat.add
                        (Nat.mul hash 31)
                        (Char.toNat leftChar))
                      65521)
                    hRest
                simpa [
                  psKernelEnvironmentHashStringWorker,
                  hLeft,
                  hRight,
                  leftChar,
                  rightChar,
                  hChar
                ] using hIH
              · simp [
                  psKernelStringEqFromWithFuel,
                  hLeft,
                  hRight,
                  leftChar,
                  rightChar,
                  hChar
                ] at hEq

theorem psKernelEnvironmentStringHash_of_stringEq_true
    (left right : String)
    (seed : Nat)
    (hEq : psKernelStringEq left right = true) :
    psKernelEnvironmentHashStringWorker
        (Nat.succ (String.utf8ByteSize left))
        left
        0
        seed =
      psKernelEnvironmentHashStringWorker
        (Nat.succ (String.utf8ByteSize right))
        right
        0
        seed := by
  have hSame : left = right := psKernelStringEq_sound_lean435 left right hEq
  subst right
  rfl

theorem psKernelEnvironmentNameHash_of_nameEq_true
    (left right : PsKernelName)
    (hEq : psKernelNameEq left right = true) :
    psKernelEnvironmentNameHash left =
      psKernelEnvironmentNameHash right := by
  induction left generalizing right with
  | anonymous =>
      cases right <;>
        simp [psKernelNameEq] at hEq ⊢
  | str leftParent leftValue ih =>
      cases right with
      | anonymous =>
          simp [psKernelNameEq] at hEq
      | str rightParent rightValue =>
          cases hString :
              psKernelStringEq leftValue rightValue with
          | false =>
              simp [psKernelNameEq, hString] at hEq
          | true =>
              have hParent :
                  psKernelNameEq leftParent rightParent = true := by
                simpa [psKernelNameEq, hString] using hEq
              have hParentHash :=
                ih rightParent hParent
              unfold psKernelEnvironmentNameHash
              rw [hParentHash]
              exact
                psKernelEnvironmentStringHash_of_stringEq_true
                  leftValue
                  rightValue
                  (Nat.mod
                    (Nat.add
                      (Nat.mul
                        (psKernelEnvironmentNameHash rightParent)
                        31)
                      1)
                    65521)
                  hString
      | num rightParent rightValue =>
          simp [psKernelNameEq] at hEq
  | num leftParent leftValue ih =>
      cases right with
      | anonymous =>
          simp [psKernelNameEq] at hEq
      | str rightParent rightValue =>
          simp [psKernelNameEq] at hEq
      | num rightParent rightValue =>
          have hPair :
              leftValue = rightValue ∧
              psKernelNameEq leftParent rightParent = true := by
            simpa [psKernelNameEq] using hEq
          have hParentHash :=
            ih rightParent hPair.2
          have hValue :
              leftValue = rightValue :=
            hPair.1
          subst rightValue
          simp [
            psKernelEnvironmentNameHash,
            hParentHash
          ]


theorem psKernelEnvironmentHashStringWorker_lt_modulus
    (fuel : Nat)
    (value : String)
    (position hash : Nat)
    (hHash : hash < 65521) :
    psKernelEnvironmentHashStringWorker
        fuel value position hash <
      65521 := by
  induction fuel generalizing position hash with
  | zero =>
      exact hHash
  | succ remaining ih =>
      cases hEnd :
          String.Pos.Raw.atEnd
            value
            (String.Pos.Raw.mk position) with
      | true =>
          simpa [
            psKernelEnvironmentHashStringWorker,
            hEnd
          ] using hHash
      | false =>
          simp only [
            psKernelEnvironmentHashStringWorker,
            hEnd
          ]
          apply ih
          exact
            Nat.mod_lt
              _
              (by decide)

theorem psKernelEnvironmentNameHash_lt_modulus
    (name : PsKernelName) :
    psKernelEnvironmentNameHash name < 65521 := by
  induction name with
  | anonymous =>
      decide
  | str parent value ih =>
      unfold psKernelEnvironmentNameHash
      apply
        psKernelEnvironmentHashStringWorker_lt_modulus
      exact
        Nat.mod_lt
          _
          (by decide)
  | num parent value ih =>
      unfold psKernelEnvironmentNameHash
      exact
        Nat.mod_lt
          _
          (by decide)

theorem psKernelEnvironmentNameHash_lt_two_pow_16
    (name : PsKernelName) :
    psKernelEnvironmentNameHash name <
      Nat.pow 2 16 := by
  exact
    Nat.lt_trans
      (psKernelEnvironmentNameHash_lt_modulus name)
      (by decide)
