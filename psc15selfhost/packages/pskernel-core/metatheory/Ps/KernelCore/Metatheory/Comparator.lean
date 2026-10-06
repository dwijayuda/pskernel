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
      cases right with
      | mdata rightMetadata rightBody =>
          change
            (if Nat.beq leftMetadata rightMetadata = true then
              psKernelExprEq leftBody rightBody
            else false) =
            (if Nat.beq rightMetadata leftMetadata = true then
              psKernelExprEq rightBody leftBody
            else false)
          rw [
            psKernelNatBeq_symm_core leftMetadata rightMetadata,
            ihBody rightBody
          ]
      | _ => rfl
  | proj leftName leftIndex leftBody ihBody =>
      cases right with
      | proj rightName rightIndex rightBody =>
          change
            (if psKernelNameEq leftName rightName = true then
              if Nat.beq leftIndex rightIndex = true then
                psKernelExprEq leftBody rightBody
              else false
            else false) =
            (if psKernelNameEq rightName leftName = true then
              if Nat.beq rightIndex leftIndex = true then
                psKernelExprEq rightBody leftBody
              else false
            else false)
          rw [
            psKernelNameEq_symm_core leftName rightName,
            psKernelNatBeq_symm_core leftIndex rightIndex,
            ihBody rightBody
          ]
      | _ => rfl


theorem psKernelNatBeq_trans_core
    (left middle right : Nat)
    (hLeft :
      Nat.beq left middle = true)
    (hRight :
      Nat.beq middle right = true) :
    Nat.beq left right = true := by
  have hLM : left = middle := by
    simpa using hLeft
  have hMR : middle = right := by
    simpa using hRight
  subst middle
  subst right
  simp

theorem psKernelStringEqFromWithFuel_trans_core
    (fuel : Nat)
    (left middle right : String)
    (leftPos middlePos rightPos : Nat)
    (hLeft :
      psKernelStringEqFromWithFuel
          fuel
          left
          middle
          leftPos
          middlePos =
        true)
    (hRight :
      psKernelStringEqFromWithFuel
          fuel
          middle
          right
          middlePos
          rightPos =
        true) :
    psKernelStringEqFromWithFuel
        fuel
        left
        right
        leftPos
        rightPos =
      true := by
  induction fuel generalizing
      leftPos middlePos rightPos with
  | zero =>
      simp [psKernelStringEqFromWithFuel] at hLeft
  | succ remaining ih =>
      dsimp only [psKernelStringEqFromWithFuel] at hLeft hRight ⊢
      cases hLeftEnd :
          String.Internal.atEnd
            left
            (String.Pos.Raw.mk leftPos) with
      | true =>
          cases hMiddleEnd :
              String.Internal.atEnd
                middle
                (String.Pos.Raw.mk middlePos) with
          | false =>
              simp [hLeftEnd, hMiddleEnd] at hLeft
          | true =>
              cases hRightEnd :
                  String.Internal.atEnd
                    right
                    (String.Pos.Raw.mk rightPos) with
              | false =>
                  simp [hMiddleEnd, hRightEnd] at hRight
              | true =>
                  simp [
                    hLeftEnd,
                    hMiddleEnd,
                    hRightEnd
                  ]
      | false =>
          cases hMiddleEnd :
              String.Internal.atEnd
                middle
                (String.Pos.Raw.mk middlePos) with
          | true =>
              simp [hLeftEnd, hMiddleEnd] at hLeft
          | false =>
              cases hRightEnd :
                  String.Internal.atEnd
                    right
                    (String.Pos.Raw.mk rightPos) with
              | true =>
                  simp [hMiddleEnd, hRightEnd] at hRight
              | false =>
                  let leftChar :=
                    Char.toNat
                      (String.Internal.get
                        left
                        (String.Pos.Raw.mk leftPos))
                  let middleChar :=
                    Char.toNat
                      (String.Internal.get
                        middle
                        (String.Pos.Raw.mk middlePos))
                  let rightChar :=
                    Char.toNat
                      (String.Internal.get
                        right
                        (String.Pos.Raw.mk rightPos))
                  cases hLM :
                      Nat.beq leftChar middleChar with
                  | false =>
                      simp [
                        hLeftEnd,
                        hMiddleEnd,
                        leftChar,
                        middleChar,
                        hLM
                      ] at hLeft
                  | true =>
                      cases hMR :
                          Nat.beq middleChar rightChar with
                      | false =>
                          simp [
                            hMiddleEnd,
                            hRightEnd,
                            middleChar,
                            rightChar,
                            hMR
                          ] at hRight
                      | true =>
                          have hLR :
                              Nat.beq leftChar rightChar = true :=
                            psKernelNatBeq_trans_core
                              leftChar
                              middleChar
                              rightChar
                              hLM
                              hMR
                          have hLeftRest :
                              psKernelStringEqFromWithFuel
                                  remaining
                                  left
                                  middle
                                  (String.Pos.Raw.byteIdx
                                    (String.Internal.next
                                      left
                                      (String.Pos.Raw.mk leftPos)))
                                  (String.Pos.Raw.byteIdx
                                    (String.Internal.next
                                      middle
                                      (String.Pos.Raw.mk middlePos))) =
                                true := by
                            simpa [
                              hLeftEnd,
                              hMiddleEnd,
                              leftChar,
                              middleChar,
                              hLM
                            ] using hLeft
                          have hRightRest :
                              psKernelStringEqFromWithFuel
                                  remaining
                                  middle
                                  right
                                  (String.Pos.Raw.byteIdx
                                    (String.Internal.next
                                      middle
                                      (String.Pos.Raw.mk middlePos)))
                                  (String.Pos.Raw.byteIdx
                                    (String.Internal.next
                                      right
                                      (String.Pos.Raw.mk rightPos))) =
                                true := by
                            simpa [
                              hMiddleEnd,
                              hRightEnd,
                              middleChar,
                              rightChar,
                              hMR
                            ] using hRight
                          have hRest :=
                            ih
                              (String.Pos.Raw.byteIdx
                                (String.Internal.next
                                  left
                                  (String.Pos.Raw.mk leftPos)))
                              (String.Pos.Raw.byteIdx
                                (String.Internal.next
                                  middle
                                  (String.Pos.Raw.mk middlePos)))
                              (String.Pos.Raw.byteIdx
                                (String.Internal.next
                                  right
                                  (String.Pos.Raw.mk rightPos)))
                              hLeftRest
                              hRightRest
                          simpa [
                            hLeftEnd,
                            hRightEnd,
                            leftChar,
                            rightChar,
                            hLR
                          ] using hRest

theorem psKernelStringEq_trans_core
    (left middle right : String)
    (hLeft :
      psKernelStringEq left middle = true)
    (hRight :
      psKernelStringEq middle right = true) :
    psKernelStringEq left right = true := by
  unfold psKernelStringEq at hLeft hRight ⊢
  cases hLMSize :
      Nat.beq
        (String.utf8ByteSize left)
        (String.utf8ByteSize middle) with
  | false =>
      simp [hLMSize] at hLeft
  | true =>
      cases hMRSize :
          Nat.beq
            (String.utf8ByteSize middle)
            (String.utf8ByteSize right) with
      | false =>
          simp [hMRSize] at hRight
      | true =>
          have hLMSizeEq :
              String.utf8ByteSize left =
                String.utf8ByteSize middle := by
            simpa using hLMSize
          have hMRSizeEq :
              String.utf8ByteSize middle =
                String.utf8ByteSize right := by
            simpa using hMRSize
          have hLRSizeEq :
              String.utf8ByteSize left =
                String.utf8ByteSize right :=
            Eq.trans hLMSizeEq hMRSizeEq
          have hLRSize :
              Nat.beq
                  (String.utf8ByteSize left)
                  (String.utf8ByteSize right) =
                true := by
            simpa [hLRSizeEq]
          have hLeftWorker :
              psKernelStringEqFromWithFuel
                  (Nat.succ
                    (String.utf8ByteSize left))
                  left
                  middle
                  0
                  0 =
                true := by
            simpa [hLMSize] using hLeft
          have hRightWorker :
              psKernelStringEqFromWithFuel
                  (Nat.succ
                    (String.utf8ByteSize left))
                  middle
                  right
                  0
                  0 =
                true := by
            simpa [hMRSize, hLMSizeEq] using hRight
          simp [hLRSize]
          exact
            psKernelStringEqFromWithFuel_trans_core
              (Nat.succ
                (String.utf8ByteSize left))
              left
              middle
              right
              0
              0
              0
              hLeftWorker
              hRightWorker

theorem psKernelNameEq_trans_core
    (left middle right : PsKernelName)
    (hLeft :
      psKernelNameEq left middle = true)
    (hRight :
      psKernelNameEq middle right = true) :
    psKernelNameEq left right = true := by
  induction left generalizing middle right with
  | anonymous =>
      cases middle with
      | anonymous =>
          cases right with
          | anonymous =>
              rfl
          | str parent value =>
              simp [psKernelNameEq] at hRight
          | num parent value =>
              simp [psKernelNameEq] at hRight
      | str parent value =>
          simp [psKernelNameEq] at hLeft
      | num parent value =>
          simp [psKernelNameEq] at hLeft
  | str leftParent leftValue ih =>
      cases middle with
      | anonymous =>
          simp [psKernelNameEq] at hLeft
      | num middleParent middleValue =>
          simp [psKernelNameEq] at hLeft
      | str middleParent middleValue =>
          cases right with
          | anonymous =>
              simp [psKernelNameEq] at hRight
          | num rightParent rightValue =>
              simp [psKernelNameEq] at hRight
          | str rightParent rightValue =>
              cases hLMString :
                  psKernelStringEq
                    leftValue
                    middleValue with
              | false =>
                  simp [
                    psKernelNameEq,
                    hLMString
                  ] at hLeft
              | true =>
                  have hLMParent :
                      psKernelNameEq
                          leftParent
                          middleParent =
                        true := by
                    simpa [
                      psKernelNameEq,
                      hLMString
                    ] using hLeft
                  cases hMRString :
                      psKernelStringEq
                        middleValue
                        rightValue with
                  | false =>
                      simp [
                        psKernelNameEq,
                        hMRString
                      ] at hRight
                  | true =>
                      have hMRParent :
                          psKernelNameEq
                              middleParent
                              rightParent =
                            true := by
                        simpa [
                          psKernelNameEq,
                          hMRString
                        ] using hRight
                      have hLRString :=
                        psKernelStringEq_trans_core
                          leftValue
                          middleValue
                          rightValue
                          hLMString
                          hMRString
                      have hLRParent :=
                        ih
                          middleParent
                          rightParent
                          hLMParent
                          hMRParent
                      simp [
                        psKernelNameEq,
                        hLRString,
                        hLRParent
                      ]
  | num leftParent leftValue ih =>
      cases middle with
      | anonymous =>
          simp [psKernelNameEq] at hLeft
      | str middleParent middleValue =>
          simp [psKernelNameEq] at hLeft
      | num middleParent middleValue =>
          cases right with
          | anonymous =>
              simp [psKernelNameEq] at hRight
          | str rightParent rightValue =>
              simp [psKernelNameEq] at hRight
          | num rightParent rightValue =>
              cases hLMNat :
                  Nat.beq leftValue middleValue with
              | false =>
                  simp [
                    psKernelNameEq,
                    hLMNat
                  ] at hLeft
              | true =>
                  have hLMParent :
                      psKernelNameEq
                          leftParent
                          middleParent =
                        true := by
                    simpa [
                      psKernelNameEq,
                      hLMNat
                    ] using hLeft
                  cases hMRNat :
                      Nat.beq middleValue rightValue with
                  | false =>
                      simp [
                        psKernelNameEq,
                        hMRNat
                      ] at hRight
                  | true =>
                      have hMRParent :
                          psKernelNameEq
                              middleParent
                              rightParent =
                            true := by
                        simpa [
                          psKernelNameEq,
                          hMRNat
                        ] using hRight
                      have hLRNat :=
                        psKernelNatBeq_trans_core
                          leftValue
                          middleValue
                          rightValue
                          hLMNat
                          hMRNat
                      have hLRParent :=
                        ih
                          middleParent
                          rightParent
                          hLMParent
                          hMRParent
                      simp [
                        psKernelNameEq,
                        hLRNat,
                        hLRParent
                      ]
