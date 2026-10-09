import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Runtime.Acceleration.Cache

/-
Hash compatibility for semantic cache keys.

The indexed cache may only use hashes as an acceleration layer if every pair
accepted by the semantic key comparator is routed to the same hash bucket.
These theorems establish that requirement from the bottom up.
-/

theorem psKernelCacheStringHashWorker_of_stringEqFrom_true
    (fuel : Nat)
    (left right : String)
    (leftPos rightPos hash : Nat)
    (hEq :
      psKernelStringEqFromWithFuel
          fuel left right leftPos rightPos = true) :
    psKernelCacheStringHashWorker
        fuel left leftPos hash =
      psKernelCacheStringHashWorker
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
                psKernelCacheStringHashWorker,
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
                    (psKernelCacheMix
                      hash
                      (Char.toNat leftChar))
                    hRest
                simpa [
                  psKernelCacheStringHashWorker,
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

theorem psKernelCacheStringHash_of_stringEq_true
    (left right : String)
    (hEq : psKernelStringEq left right = true) :
    psKernelCacheStringHash left =
      psKernelCacheStringHash right := by
  unfold psKernelStringEq at hEq
  cases hSize :
      Nat.beq
        (String.utf8ByteSize left)
        (String.utf8ByteSize right) with
  | false =>
      simp [hSize] at hEq
  | true =>
      have hSizeEq :
          String.utf8ByteSize left =
            String.utf8ByteSize right := by
        simpa using hSize
      have hWorker :
          psKernelStringEqFromWithFuel
              (Nat.succ (String.utf8ByteSize left))
              left right 0 0 =
            true := by
        simpa [hSize] using hEq
      unfold psKernelCacheStringHash
      rw [← hSizeEq]
      exact
        psKernelCacheStringHashWorker_of_stringEqFrom_true
          (Nat.succ (String.utf8ByteSize left))
          left right 0 0 0 hWorker

theorem psKernelCacheNameHash_of_nameEq_true
    (left right : PsKernelName)
    (hEq : psKernelNameEq left right = true) :
    psKernelCacheNameHash left =
      psKernelCacheNameHash right := by
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
              simp [
                psKernelCacheNameHash,
                ih rightParent hParent,
                psKernelCacheStringHash_of_stringEq_true
                  leftValue rightValue hString
              ]
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
          have hValue := hPair.1
          have hParent := hPair.2
          subst rightValue
          simp [
            psKernelCacheNameHash,
            ih rightParent hParent
          ]

theorem psKernelCacheLevelHash_of_levelEq_true
    (left right : PsKernelLevel)
    (hEq : psKernelLevelEq left right = true) :
    psKernelCacheLevelHash left =
      psKernelCacheLevelHash right := by
  induction left generalizing right with
  | zero =>
      cases right <;>
        simp [psKernelLevelEq] at hEq ⊢
  | succ left ih =>
      cases right with
      | succ right =>
          have hInner :
              psKernelLevelEq left right = true := by
            simpa [psKernelLevelEq] using hEq
          simp [
            psKernelCacheLevelHash,
            ih right hInner
          ]
      | zero | max _ _ | imax _ _ | param _ | mvar _ =>
          simp [psKernelLevelEq] at hEq
  | max leftA leftB ihA ihB =>
      cases right with
      | max rightA rightB =>
          cases hA : psKernelLevelEq leftA rightA with
          | false =>
              simp [psKernelLevelEq, hA] at hEq
          | true =>
              have hB : psKernelLevelEq leftB rightB = true := by
                simpa [psKernelLevelEq, hA] using hEq
              simp [
                psKernelCacheLevelHash,
                ihA rightA hA,
                ihB rightB hB
              ]
      | zero | succ _ | imax _ _ | param _ | mvar _ =>
          simp [psKernelLevelEq] at hEq
  | imax leftA leftB ihA ihB =>
      cases right with
      | imax rightA rightB =>
          cases hA : psKernelLevelEq leftA rightA with
          | false =>
              simp [psKernelLevelEq, hA] at hEq
          | true =>
              have hB : psKernelLevelEq leftB rightB = true := by
                simpa [psKernelLevelEq, hA] using hEq
              simp [
                psKernelCacheLevelHash,
                ihA rightA hA,
                ihB rightB hB
              ]
      | zero | succ _ | max _ _ | param _ | mvar _ =>
          simp [psKernelLevelEq] at hEq
  | param leftName =>
      cases right with
      | param rightName =>
          exact
            congrArg
              (fun value =>
                psKernelCacheMix 15 value)
              (psKernelCacheNameHash_of_nameEq_true
                leftName rightName hEq)
      | zero | succ _ | max _ _ | imax _ _ | mvar _ =>
          simp [psKernelLevelEq] at hEq
  | mvar leftName =>
      cases right with
      | mvar rightName =>
          exact
            congrArg
              (fun value =>
                psKernelCacheMix 16 value)
              (psKernelCacheNameHash_of_nameEq_true
                leftName rightName hEq)
      | zero | succ _ | max _ _ | imax _ _ | param _ =>
          simp [psKernelLevelEq] at hEq

theorem psKernelCacheLevelListHashWorker_of_levelListEq_true
    (left right : List PsKernelLevel)
    (hash : Nat)
    (hEq : psKernelLevelListEq left right = true) :
    psKernelCacheLevelListHashWorker left hash =
      psKernelCacheLevelListHashWorker right hash := by
  induction left generalizing right hash with
  | nil =>
      cases right with
      | nil =>
          rfl
      | cons head tail =>
          simp [psKernelLevelListEq] at hEq
  | cons leftHead leftTail ih =>
      cases right with
      | nil =>
          simp [psKernelLevelListEq] at hEq
      | cons rightHead rightTail =>
          cases hHead :
              psKernelLevelEq leftHead rightHead with
          | false =>
              simp [psKernelLevelListEq, hHead] at hEq
          | true =>
              have hTail :
                  psKernelLevelListEq leftTail rightTail = true := by
                simpa [psKernelLevelListEq, hHead] using hEq
              have hHash :
                  psKernelCacheLevelHash leftHead =
                    psKernelCacheLevelHash rightHead :=
                psKernelCacheLevelHash_of_levelEq_true
                  leftHead rightHead hHead
              simpa [
                psKernelCacheLevelListHashWorker,
                hHash
              ] using
                ih
                  rightTail
                  (psKernelCacheMix
                    hash
                    (psKernelCacheLevelHash leftHead))
                  hTail

theorem psKernelCacheLevelListHash_of_levelListEq_true
    (left right : List PsKernelLevel)
    (hEq : psKernelLevelListEq left right = true) :
    psKernelCacheLevelListHash left =
      psKernelCacheLevelListHash right := by
  unfold psKernelCacheLevelListHash
  exact
    psKernelCacheLevelListHashWorker_of_levelListEq_true
      left right 18 hEq

theorem psKernelCacheLiteralHash_of_literalEq_true
    (left right : PsKernelLiteral)
    (hEq : psKernelLiteralEq left right = true) :
    psKernelCacheLiteralHash left =
      psKernelCacheLiteralHash right := by
  cases left with
  | nat leftValue =>
      cases right with
      | nat rightValue =>
          have hValue : leftValue = rightValue := by
            simpa [psKernelLiteralEq] using hEq
          subst rightValue
          rfl
      | str rightValue =>
          simp [psKernelLiteralEq] at hEq
  | str leftValue =>
      cases right with
      | nat rightValue =>
          simp [psKernelLiteralEq] at hEq
      | str rightValue =>
          exact
            congrArg
              (fun value =>
                psKernelCacheMix 20 value)
              (psKernelCacheStringHash_of_stringEq_true
                leftValue rightValue hEq)

theorem psKernelExprHash_of_structuralEq
    (left right : PsKernelExpr)
    (hEq : PsKernelStructuralExprEq left right) :
    psKernelExprHash left =
      psKernelExprHash right := by
  induction hEq with
  | bvar left right h =>
      have hValue : left = right := by
        simpa using h
      subst right
      rfl
  | fvar left right h =>
      simp [
        psKernelExprHash,
        psKernelCacheNameHash_of_nameEq_true left right h
      ]
  | mvar left right h =>
      simp [
        psKernelExprHash,
        psKernelCacheNameHash_of_nameEq_true left right h
      ]
  | sort left right h =>
      simp [
        psKernelExprHash,
        psKernelCacheLevelHash_of_levelEq_true left right h
      ]
  | const leftName rightName leftLevels rightLevels hName hLevels =>
      simp [
        psKernelExprHash,
        psKernelCacheNameHash_of_nameEq_true
          leftName rightName hName,
        psKernelCacheLevelListHash_of_levelListEq_true
          leftLevels rightLevels hLevels
      ]
  | app leftFn leftArg rightFn rightArg hFn hArg ihFn ihArg =>
      simp [psKernelExprHash, ihFn, ihArg]
  | lam leftName rightName leftType leftBody rightType rightBody leftInfo rightInfo hType hBody ihType ihBody =>
      simp [psKernelExprHash, ihType, ihBody]
  | forallE leftName rightName leftType leftBody rightType rightBody leftInfo rightInfo hType hBody ihType ihBody =>
      simp [psKernelExprHash, ihType, ihBody]
  | letE leftName rightName leftType leftValue leftBody rightType rightValue rightBody leftNondep rightNondep hType hValue hBody hNondep ihType ihValue ihBody =>
      have hFlag : leftNondep = rightNondep := by
        cases leftNondep <;>
          cases rightNondep <;>
          simp [psKernelBoolEq] at hNondep ⊢
      subst rightNondep
      simp [psKernelExprHash, ihType, ihValue, ihBody]
  | lit left right h =>
      simp [
        psKernelExprHash,
        psKernelCacheLiteralHash_of_literalEq_true
          left right h
      ]
  | mdata leftMetadata rightMetadata left right hMetadata hBody ihBody =>
      have hMeta : leftMetadata = rightMetadata := by
        simpa using hMetadata
      subst rightMetadata
      simp [psKernelExprHash, ihBody]
  | proj leftName rightName leftIndex rightIndex left right hName hIndex hBody ihBody =>
      have hIdx : leftIndex = rightIndex := by
        simpa using hIndex
      subst rightIndex
      simp [
        psKernelExprHash,
        psKernelCacheNameHash_of_nameEq_true
          leftName rightName hName,
        ihBody
      ]

theorem psKernelExprHash_of_exprEq_true
    (left right : PsKernelExpr)
    (hEq : psKernelExprEq left right = true) :
    psKernelExprHash left =
      psKernelExprHash right := by
  exact
    psKernelExprHash_of_structuralEq
      left
      right
      (psKernelExprEq_true_refines_structural
        left right hEq)
