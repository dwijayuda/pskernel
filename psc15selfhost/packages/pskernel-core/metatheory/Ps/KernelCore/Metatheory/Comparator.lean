import Ps.KernelCore.Core.Expr

/- Reusable symmetry algebra for the portable kernel comparators. -/

theorem psKernelNatBeq_symm_core
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

theorem psKernelStringEqFromWithFuel_symm_core
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
                    rw [← psKernelNatBeq_symm_core leftChar rightChar]
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
                    rw [← psKernelNatBeq_symm_core leftChar rightChar]
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

theorem psKernelStringEq_symm_core
    (left right : String) :
    psKernelStringEq left right =
      psKernelStringEq right left := by
  unfold psKernelStringEq
  rw [
    psKernelNatBeq_symm_core
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
        psKernelStringEqFromWithFuel_symm_core
          (Nat.succ (String.utf8ByteSize left))
          left
          right
          0
          0

theorem psKernelNameEq_symm_core
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
          rw [psKernelStringEq_symm_core leftValue rightValue]
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
          rw [psKernelNatBeq_symm_core leftValue rightValue]
          rw [ih rightParent]



theorem psKernelLevelEq_symm_core
    (left right : PsKernelLevel) :
    psKernelLevelEq left right =
      psKernelLevelEq right left := by
  induction left generalizing right with
  | zero =>
      cases right <;> rfl
  | succ left ih =>
      cases right with
      | succ right =>
          exact ih right
      | _ =>
          rfl
  | max leftA leftB ihA ihB =>
      cases right with
      | max rightA rightB =>
          change
            (if psKernelLevelEq leftA rightA = true then
              psKernelLevelEq leftB rightB
            else false) =
            (if psKernelLevelEq rightA leftA = true then
              psKernelLevelEq rightB leftB
            else false)
          rw [ihA rightA, ihB rightB]
      | _ =>
          rfl
  | imax leftA leftB ihA ihB =>
      cases right with
      | imax rightA rightB =>
          change
            (if psKernelLevelEq leftA rightA = true then
              psKernelLevelEq leftB rightB
            else false) =
            (if psKernelLevelEq rightA leftA = true then
              psKernelLevelEq rightB leftB
            else false)
          rw [ihA rightA, ihB rightB]
      | _ =>
          rfl
  | param leftName =>
      cases right with
      | param rightName =>
          exact psKernelNameEq_symm_core leftName rightName
      | _ =>
          rfl
  | mvar leftName =>
      cases right with
      | mvar rightName =>
          exact psKernelNameEq_symm_core leftName rightName
      | _ =>
          rfl

theorem psKernelLevelListEq_symm_core
    (left right : List PsKernelLevel) :
    psKernelLevelListEq left right =
      psKernelLevelListEq right left := by
  induction left generalizing right with
  | nil =>
      cases right <;> rfl
  | cons leftHead leftTail ih =>
      cases right with
      | nil =>
          rfl
      | cons rightHead rightTail =>
          change
            (if psKernelLevelEq leftHead rightHead = true then
              psKernelLevelListEq leftTail rightTail
            else false) =
            (if psKernelLevelEq rightHead leftHead = true then
              psKernelLevelListEq rightTail leftTail
            else false)
          rw [psKernelLevelEq_symm_core leftHead rightHead]
          rw [ih rightTail]

theorem psKernelBoolEq_symm_core
    (left right : Bool) :
    psKernelBoolEq left right =
      psKernelBoolEq right left := by
  cases left <;> cases right <;> rfl

theorem psKernelLiteralEq_symm_core
    (left right : PsKernelLiteral) :
    psKernelLiteralEq left right =
      psKernelLiteralEq right left := by
  cases left with
  | nat leftValue =>
      cases right with
      | nat rightValue =>
          exact psKernelNatBeq_symm_core leftValue rightValue
      | str rightValue =>
          rfl
  | str leftValue =>
      cases right with
      | nat rightValue =>
          rfl
      | str rightValue =>
          exact psKernelStringEq_symm_core leftValue rightValue

theorem psKernelExprEq_symm_core
    (left right : PsKernelExpr) :
    psKernelExprEq left right =
      psKernelExprEq right left := by
  induction left generalizing right with
  | bvar leftIndex =>
      cases right with
      | bvar rightIndex =>
          exact psKernelNatBeq_symm_core leftIndex rightIndex
      | _ => rfl
  | fvar leftName =>
      cases right with
      | fvar rightName =>
          exact psKernelNameEq_symm_core leftName rightName
      | _ => rfl
  | mvar leftName =>
      cases right with
      | mvar rightName =>
          exact psKernelNameEq_symm_core leftName rightName
      | _ => rfl
  | sort leftLevel =>
      cases right with
      | sort rightLevel =>
          exact psKernelLevelEq_symm_core leftLevel rightLevel
      | _ => rfl
  | const leftName leftLevels =>
      cases right with
      | const rightName rightLevels =>
          change
            (if psKernelNameEq leftName rightName = true then
              psKernelLevelListEq leftLevels rightLevels
            else false) =
            (if psKernelNameEq rightName leftName = true then
              psKernelLevelListEq rightLevels leftLevels
            else false)
          rw [psKernelNameEq_symm_core leftName rightName]
          rw [psKernelLevelListEq_symm_core leftLevels rightLevels]
      | _ => rfl
  | app leftFn leftArg ihFn ihArg =>
      cases right with
      | app rightFn rightArg =>
          change
            (if psKernelExprEq leftFn rightFn = true then
              psKernelExprEq leftArg rightArg
            else false) =
            (if psKernelExprEq rightFn leftFn = true then
              psKernelExprEq rightArg leftArg
            else false)
          rw [ihFn rightFn, ihArg rightArg]
      | _ => rfl
  | lam leftName leftType leftBody leftInfo ihType ihBody =>
      cases right with
      | lam rightName rightType rightBody rightInfo =>
          change
            (if psKernelExprEq leftType rightType = true then
              psKernelExprEq leftBody rightBody
            else false) =
            (if psKernelExprEq rightType leftType = true then
              psKernelExprEq rightBody leftBody
            else false)
          rw [ihType rightType, ihBody rightBody]
      | _ => rfl
  | forallE leftName leftType leftBody leftInfo ihType ihBody =>
      cases right with
      | forallE rightName rightType rightBody rightInfo =>
          change
            (if psKernelExprEq leftType rightType = true then
              psKernelExprEq leftBody rightBody
            else false) =
            (if psKernelExprEq rightType leftType = true then
              psKernelExprEq rightBody leftBody
            else false)
          rw [ihType rightType, ihBody rightBody]
      | _ => rfl
  | letE leftName leftType leftValue leftBody leftNondep ihType ihValue ihBody =>
      cases right with
      | letE rightName rightType rightValue rightBody rightNondep =>
          change
            (if psKernelExprEq leftType rightType = true then
              if psKernelExprEq leftValue rightValue = true then
                if psKernelExprEq leftBody rightBody = true then
                  psKernelBoolEq leftNondep rightNondep
                else false
              else false
            else false) =
            (if psKernelExprEq rightType leftType = true then
              if psKernelExprEq rightValue leftValue = true then
                if psKernelExprEq rightBody leftBody = true then
                  psKernelBoolEq rightNondep leftNondep
                else false
              else false
            else false)
          rw [
            ihType rightType,
            ihValue rightValue,
            ihBody rightBody,
            psKernelBoolEq_symm_core leftNondep rightNondep
          ]
      | _ => rfl
  | lit leftLiteral =>
      cases right with
      | lit rightLiteral =>
          exact psKernelLiteralEq_symm_core leftLiteral rightLiteral
      | _ => rfl
  | mdata leftMetadata leftBody ihBody =>
      cases middle with
      | mdata middleMetadata middleBody =>
          cases right with
          | mdata rightMetadata rightBody =>
              have hLM :
                  leftMetadata = middleMetadata ∧
                  psKernelExprEq leftBody middleBody = true := by
                simpa [psKernelExprEq] using hLeft
              have hMR :
                  middleMetadata = rightMetadata ∧
                  psKernelExprEq middleBody rightBody = true := by
                simpa [psKernelExprEq] using hRight
              have hMeta :
                  leftMetadata = rightMetadata :=
                Eq.trans hLM.1 hMR.1
              have hBody :
                  psKernelExprEq leftBody rightBody = true :=
                ihBody
                  middleBody
                  rightBody
                  hLM.2
                  hMR.2
              simp [psKernelExprEq, hMeta, hBody]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | proj leftName leftIndex leftBody ihBody =>
      cases middle with
      | proj middleName middleIndex middleBody =>
          cases right with
          | proj rightName rightIndex rightBody =>
              cases hLN :
                  psKernelNameEq leftName middleName with
              | false =>
                  simp [psKernelExprEq, hLN] at hLeft
              | true =>
                  have hLRest :
                      leftIndex = middleIndex ∧
                      psKernelExprEq leftBody middleBody = true := by
                    simpa [psKernelExprEq, hLN] using hLeft
                  cases hRN :
                      psKernelNameEq middleName rightName with
                  | false =>
                      simp [psKernelExprEq, hRN] at hRight
                  | true =>
                      have hRRest :
                          middleIndex = rightIndex ∧
                          psKernelExprEq middleBody rightBody = true := by
                        simpa [psKernelExprEq, hRN] using hRight
                      have hName :
                          psKernelNameEq leftName rightName = true :=
                        psKernelNameEq_trans_core
                          leftName
                          middleName
                          rightName
                          hLN
                          hRN
                      have hIndex :
                          leftIndex = rightIndex :=
                        Eq.trans hLRest.1 hRRest.1
                      have hBody :
                          psKernelExprEq leftBody rightBody = true :=
                        ihBody
                          middleBody
                          rightBody
                          hLRest.2
                          hRRest.2
                      simp [
                        psKernelExprEq,
                        hName,
                        hIndex,
                        hBody
                      ]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | fvar leftName =>
      cases middle with
      | fvar middleName =>
          cases right with
          | fvar rightName =>
              exact
                psKernelNameEq_trans_core
                  leftName middleName rightName
                  hLeft hRight
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | mvar leftName =>
      cases middle with
      | mvar middleName =>
          cases right with
          | mvar rightName =>
              exact
                psKernelNameEq_trans_core
                  leftName middleName rightName
                  hLeft hRight
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | sort leftLevel =>
      cases middle with
      | sort middleLevel =>
          cases right with
          | sort rightLevel =>
              exact
                psKernelLevelEq_trans_core
                  leftLevel middleLevel rightLevel
                  hLeft hRight
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | const leftName leftLevels =>
      cases middle with
      | const middleName middleLevels =>
          cases right with
          | const rightName rightLevels =>
              cases hLN :
                  psKernelNameEq leftName middleName with
              | false =>
                  simp [psKernelExprEq, hLN] at hLeft
              | true =>
                  have hLL :
                      psKernelLevelListEq
                          leftLevels
                          middleLevels =
                        true := by
                    simpa [psKernelExprEq, hLN] using hLeft
                  cases hRN :
                      psKernelNameEq middleName rightName with
                  | false =>
                      simp [psKernelExprEq, hRN] at hRight
                  | true =>
                      have hRL :
                          psKernelLevelListEq
                              middleLevels
                              rightLevels =
                            true := by
                        simpa [psKernelExprEq, hRN] using hRight
                      have hName :=
                        psKernelNameEq_trans_core
                          leftName middleName rightName
                          hLN hRN
                      have hLevels :=
                        psKernelLevelListEq_trans_core
                          leftLevels middleLevels rightLevels
                          hLL hRL
                      simp [psKernelExprEq, hName, hLevels]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | app leftFn leftArg ihFn ihArg =>
      cases middle with
      | app middleFn middleArg =>
          cases right with
          | app rightFn rightArg =>
              cases hLF :
                  psKernelExprEq leftFn middleFn with
              | false =>
                  simp [psKernelExprEq, hLF] at hLeft
              | true =>
                  have hLA :
                      psKernelExprEq leftArg middleArg = true := by
                    simpa [psKernelExprEq, hLF] using hLeft
                  cases hRF :
                      psKernelExprEq middleFn rightFn with
                  | false =>
                      simp [psKernelExprEq, hRF] at hRight
                  | true =>
                      have hRA :
                          psKernelExprEq middleArg rightArg = true := by
                        simpa [psKernelExprEq, hRF] using hRight
                      have hFn :=
                        ihFn middleFn rightFn hLF hRF
                      have hArg :=
                        ihArg middleArg rightArg hLA hRA
                      simp [psKernelExprEq, hFn, hArg]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | lam leftName leftType leftBody leftInfo ihType ihBody =>
      cases middle with
      | lam middleName middleType middleBody middleInfo =>
          cases right with
          | lam rightName rightType rightBody rightInfo =>
              cases hLT :
                  psKernelExprEq leftType middleType with
              | false =>
                  simp [psKernelExprEq, hLT] at hLeft
              | true =>
                  have hLB :
                      psKernelExprEq leftBody middleBody = true := by
                    simpa [psKernelExprEq, hLT] using hLeft
                  cases hRT :
                      psKernelExprEq middleType rightType with
                  | false =>
                      simp [psKernelExprEq, hRT] at hRight
                  | true =>
                      have hRB :
                          psKernelExprEq middleBody rightBody = true := by
                        simpa [psKernelExprEq, hRT] using hRight
                      have hType :=
                        ihType middleType rightType hLT hRT
                      have hBody :=
                        ihBody middleBody rightBody hLB hRB
                      simp [psKernelExprEq, hType, hBody]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | forallE leftName leftType leftBody leftInfo ihType ihBody =>
      cases middle with
      | forallE middleName middleType middleBody middleInfo =>
          cases right with
          | forallE rightName rightType rightBody rightInfo =>
              cases hLT :
                  psKernelExprEq leftType middleType with
              | false =>
                  simp [psKernelExprEq, hLT] at hLeft
              | true =>
                  have hLB :
                      psKernelExprEq leftBody middleBody = true := by
                    simpa [psKernelExprEq, hLT] using hLeft
                  cases hRT :
                      psKernelExprEq middleType rightType with
                  | false =>
                      simp [psKernelExprEq, hRT] at hRight
                  | true =>
                      have hRB :
                          psKernelExprEq middleBody rightBody = true := by
                        simpa [psKernelExprEq, hRT] using hRight
                      have hType :=
                        ihType middleType rightType hLT hRT
                      have hBody :=
                        ihBody middleBody rightBody hLB hRB
                      simp [psKernelExprEq, hType, hBody]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | letE leftName leftType leftValue leftBody leftNondep ihType ihValue ihBody =>
      cases middle with
      | letE middleName middleType middleValue middleBody middleNondep =>
          cases right with
          | letE rightName rightType rightValue rightBody rightNondep =>
              cases hLT :
                  psKernelExprEq leftType middleType with
              | false =>
                  simp [psKernelExprEq, hLT] at hLeft
              | true =>
                  cases hLV :
                      psKernelExprEq leftValue middleValue with
                  | false =>
                      simp [psKernelExprEq, hLT, hLV] at hLeft
                  | true =>
                      cases hLB :
                          psKernelExprEq leftBody middleBody with
                      | false =>
                          simp [
                            psKernelExprEq,
                            hLT,
                            hLV,
                            hLB
                          ] at hLeft
                      | true =>
                          have hLN :
                              psKernelBoolEq
                                  leftNondep
                                  middleNondep =
                                true := by
                            simpa [
                              psKernelExprEq,
                              hLT,
                              hLV,
                              hLB
                            ] using hLeft
                          cases hRT :
                              psKernelExprEq middleType rightType with
                          | false =>
                              simp [psKernelExprEq, hRT] at hRight
                          | true =>
                              cases hRV :
                                  psKernelExprEq middleValue rightValue with
                              | false =>
                                  simp [
                                    psKernelExprEq,
                                    hRT,
                                    hRV
                                  ] at hRight
                              | true =>
                                  cases hRB :
                                      psKernelExprEq middleBody rightBody with
                                  | false =>
                                      simp [
                                        psKernelExprEq,
                                        hRT,
                                        hRV,
                                        hRB
                                      ] at hRight
                                  | true =>
                                      have hRN :
                                          psKernelBoolEq
                                              middleNondep
                                              rightNondep =
                                            true := by
                                        simpa [
                                          psKernelExprEq,
                                          hRT,
                                          hRV,
                                          hRB
                                        ] using hRight
                                      have hType :=
                                        ihType
                                          middleType
                                          rightType
                                          hLT
                                          hRT
                                      have hValue :=
                                        ihValue
                                          middleValue
                                          rightValue
                                          hLV
                                          hRV
                                      have hBody :=
                                        ihBody
                                          middleBody
                                          rightBody
                                          hLB
                                          hRB
                                      have hNondep :=
                                        psKernelBoolEq_trans_core
                                          leftNondep
                                          middleNondep
                                          rightNondep
                                          hLN
                                          hRN
                                      simp [
                                        psKernelExprEq,
                                        hType,
                                        hValue,
                                        hBody,
                                        hNondep
                                      ]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | lit leftLiteral =>
      cases middle with
      | lit middleLiteral =>
          cases right with
          | lit rightLiteral =>
              exact
                psKernelLiteralEq_trans_core
                  leftLiteral
                  middleLiteral
                  rightLiteral
                  hLeft
                  hRight
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | mdata leftMetadata leftBody ihBody =>
      cases middle with
      | mdata middleMetadata middleBody =>
          cases right with
          | mdata rightMetadata rightBody =>
              cases hLM :
                  Nat.beq leftMetadata middleMetadata with
              | false =>
                  simp [psKernelExprEq, hLM] at hLeft
              | true =>
                  have hLB :
                      psKernelExprEq leftBody middleBody = true := by
                    simpa [psKernelExprEq, hLM] using hLeft
                  cases hRM :
                      Nat.beq middleMetadata rightMetadata with
                  | false =>
                      simp [psKernelExprEq, hRM] at hRight
                  | true =>
                      have hRB :
                          psKernelExprEq middleBody rightBody = true := by
                        simpa [psKernelExprEq, hRM] using hRight
                      have hMeta :=
                        psKernelNatBeq_trans_core
                          leftMetadata
                          middleMetadata
                          rightMetadata
                          hLM
                          hRM
                      have hBody :=
                        ihBody middleBody rightBody hLB hRB
                      simp [psKernelExprEq, hMeta, hBody]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
  | proj leftName leftIndex leftBody ihBody =>
      cases middle with
      | proj middleName middleIndex middleBody =>
          cases right with
          | proj rightName rightIndex rightBody =>
              cases hLN :
                  psKernelNameEq leftName middleName with
              | false =>
                  simp [psKernelExprEq, hLN] at hLeft
              | true =>
                  cases hLI :
                      Nat.beq leftIndex middleIndex with
                  | false =>
                      simp [
                        psKernelExprEq,
                        hLN,
                        hLI
                      ] at hLeft
                  | true =>
                      have hLB :
                          psKernelExprEq leftBody middleBody = true := by
                        simpa [
                          psKernelExprEq,
                          hLN,
                          hLI
                        ] using hLeft
                      cases hRN :
                          psKernelNameEq middleName rightName with
                      | false =>
                          simp [psKernelExprEq, hRN] at hRight
                      | true =>
                          cases hRI :
                              Nat.beq middleIndex rightIndex with
                          | false =>
                              simp [
                                psKernelExprEq,
                                hRN,
                                hRI
                              ] at hRight
                          | true =>
                              have hRB :
                                  psKernelExprEq middleBody rightBody = true := by
                                simpa [
                                  psKernelExprEq,
                                  hRN,
                                  hRI
                                ] using hRight
                              have hName :=
                                psKernelNameEq_trans_core
                                  leftName
                                  middleName
                                  rightName
                                  hLN
                                  hRN
                              have hIndex :=
                                psKernelNatBeq_trans_core
                                  leftIndex
                                  middleIndex
                                  rightIndex
                                  hLI
                                  hRI
                              have hBody :=
                                ihBody
                                  middleBody
                                  rightBody
                                  hLB
                                  hRB
                              simp [
                                psKernelExprEq,
                                hName,
                                hIndex,
                                hBody
                              ]
          | _ =>
              simp [psKernelExprEq] at hRight
      | _ =>
          simp [psKernelExprEq] at hLeft
