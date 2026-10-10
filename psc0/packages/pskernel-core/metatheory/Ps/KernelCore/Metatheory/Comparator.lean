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
          String.Pos.Raw.atEnd
            left
            (String.Pos.Raw.mk leftPos) with
      | true =>
          cases hRight :
              String.Pos.Raw.atEnd
                right
                (String.Pos.Raw.mk rightPos) <;>
            simp [hLeft, hRight]
      | false =>
          cases hRight :
              String.Pos.Raw.atEnd
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
                        (String.Pos.Raw.next
                          left
                          (String.Pos.Raw.mk leftPos)))
                      (String.Pos.Raw.byteIdx
                        (String.Pos.Raw.next
                          right
                          (String.Pos.Raw.mk rightPos)))

theorem psKernelStringEq_symm_core
    (left right : String) :
    psKernelStringEq left right = psKernelStringEq right left := by
  simp only [psKernelStringEq, eq_comm]

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
          String.Pos.Raw.atEnd
            left
            (String.Pos.Raw.mk leftPos) with
      | true =>
          cases hMiddleEnd :
              String.Pos.Raw.atEnd
                middle
                (String.Pos.Raw.mk middlePos) with
          | false =>
              simp [hLeftEnd, hMiddleEnd] at hLeft
          | true =>
              cases hRightEnd :
                  String.Pos.Raw.atEnd
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
              String.Pos.Raw.atEnd
                middle
                (String.Pos.Raw.mk middlePos) with
          | true =>
              simp [hLeftEnd, hMiddleEnd] at hLeft
          | false =>
              cases hRightEnd :
                  String.Pos.Raw.atEnd
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
                                    (String.Pos.Raw.next
                                      left
                                      (String.Pos.Raw.mk leftPos)))
                                  (String.Pos.Raw.byteIdx
                                    (String.Pos.Raw.next
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
                                    (String.Pos.Raw.next
                                      middle
                                      (String.Pos.Raw.mk middlePos)))
                                  (String.Pos.Raw.byteIdx
                                    (String.Pos.Raw.next
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
                                (String.Pos.Raw.next
                                  left
                                  (String.Pos.Raw.mk leftPos)))
                              (String.Pos.Raw.byteIdx
                                (String.Pos.Raw.next
                                  middle
                                  (String.Pos.Raw.mk middlePos)))
                              (String.Pos.Raw.byteIdx
                                (String.Pos.Raw.next
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
    (hLeft : psKernelStringEq left middle = true)
    (hRight : psKernelStringEq middle right = true) :
    psKernelStringEq left right = true := by
  have hLM : left = middle := of_decide_eq_true hLeft
  have hMR : middle = right := of_decide_eq_true hRight
  subst middle
  subst right
  simp [psKernelStringEq]

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
              have hLM :
                  leftValue = middleValue ∧
                  psKernelNameEq
                      leftParent
                      middleParent =
                    true := by
                simpa [psKernelNameEq] using hLeft
              have hMR :
                  middleValue = rightValue ∧
                  psKernelNameEq
                      middleParent
                      rightParent =
                    true := by
                simpa [psKernelNameEq] using hRight
              have hParent :
                  psKernelNameEq
                      leftParent
                      rightParent =
                    true :=
                ih
                  middleParent
                  rightParent
                  hLM.2
                  hMR.2
              have hValue :
                  leftValue = rightValue :=
                Eq.trans hLM.1 hMR.1
              have hValueBeq :
                  Nat.beq leftValue rightValue = true := by
                simpa [hValue]
              change
                (if Nat.beq leftValue rightValue = true then
                  psKernelNameEq leftParent rightParent
                else false) =
                  true
              simp [hValueBeq, hParent]


/-
The named reflexivity interface is retained for reusable comparator lemmas.
The equality traversal uses specified String.Pos.Raw cursor operations;
BootstrapStringObligations proves this law without a new trusted premise.
Positive equality soundness remains a separately named trusted boundary.
-/

def PsKernelStringEqReflexiveLaw : Prop :=
  ∀ value : String,
    psKernelStringEq value value = true

theorem psKernelNameEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (name : PsKernelName) :
    psKernelNameEq name name = true := by
  induction name with
  | anonymous =>
      rfl
  | str parent value ih =>
      simp [
        psKernelNameEq,
        hString value,
        ih
      ]
  | num parent value ih =>
      simp [psKernelNameEq, ih]

theorem psKernelLevelEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (level : PsKernelLevel) :
    psKernelLevelEq level level = true := by
  induction level with
  | zero =>
      rfl
  | succ inner ih =>
      exact ih
  | max left right ihLeft ihRight =>
      simp [psKernelLevelEq, ihLeft, ihRight]
  | imax left right ihLeft ihRight =>
      simp [psKernelLevelEq, ihLeft, ihRight]
  | param name =>
      exact psKernelNameEq_refl_of_string_law hString name
  | mvar name =>
      exact psKernelNameEq_refl_of_string_law hString name

theorem psKernelLevelListEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (levels : List PsKernelLevel) :
    psKernelLevelListEq levels levels = true := by
  induction levels with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [
        psKernelLevelListEq,
        psKernelLevelEq_refl_of_string_law hString,
        ih
      ]

theorem psKernelLiteralEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (literal : PsKernelLiteral) :
    psKernelLiteralEq literal literal = true := by
  cases literal with
  | nat value =>
      simp [psKernelLiteralEq]
  | str value =>
      exact hString value

theorem psKernelExprEq_refl_of_string_law
    (hString : PsKernelStringEqReflexiveLaw)
    (expr : PsKernelExpr) :
    psKernelExprEq expr expr = true := by
  induction expr with
  | bvar index =>
      simp [psKernelExprEq]
  | fvar name =>
      exact psKernelNameEq_refl_of_string_law hString name
  | mvar name =>
      exact psKernelNameEq_refl_of_string_law hString name
  | sort level =>
      exact psKernelLevelEq_refl_of_string_law hString level
  | const name levels =>
      simp [
        psKernelExprEq,
        psKernelNameEq_refl_of_string_law hString,
        psKernelLevelListEq_refl_of_string_law hString
      ]
  | app fn arg ihFn ihArg =>
      simp [psKernelExprEq, ihFn, ihArg]
  | lam name type body binderInfo ihType ihBody =>
      simp [psKernelExprEq, ihType, ihBody]
  | forallE name type body binderInfo ihType ihBody =>
      simp [psKernelExprEq, ihType, ihBody]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases nondep <;>
        simp [
          psKernelExprEq,
          ihType,
          ihValue,
          ihBody,
          psKernelBoolEq
        ]
  | lit literal =>
      exact psKernelLiteralEq_refl_of_string_law hString literal
  | mdata metadata body ihBody =>
      simp [psKernelExprEq, ihBody]
  | proj typeName index body ihBody =>
      simp [
        psKernelExprEq,
        psKernelNameEq_refl_of_string_law hString,
        ihBody
      ]


/-
The existing refinements accept a modular String equality law. The current
Lean 4.35 native comparator discharges this interface below from its checked
DecidableEq definition. The runtime/compiler correspondence remains a separate
TCB boundary, as with the other native primitive operations.
-/

def PsKernelStringEqSoundLaw : Prop :=
  ∀ (left right : String),
    psKernelStringEq left right = true ->
      left = right

/-- The actual 4.35 comparator decides string equality without a soundness premise. -/
theorem psKernelStringEq_true_iff (left right : String) :
    psKernelStringEq left right = true ↔ left = right := by
  simp [psKernelStringEq]

/-- Discharges the compatibility interface consumed by the existing refinements. -/
theorem psKernelStringEq_sound_lean435 : PsKernelStringEqSoundLaw := by
  intro left right h
  exact of_decide_eq_true h

theorem psKernelNameEq_sound_of_string_law
    (hString : PsKernelStringEqSoundLaw)
    (left right : PsKernelName)
    (hEq : psKernelNameEq left right = true) :
    left = right := by
  induction left generalizing right with
  | anonymous =>
      cases right with
      | anonymous =>
          rfl
      | str parent value =>
          simp [psKernelNameEq] at hEq
      | num parent value =>
          simp [psKernelNameEq] at hEq
  | str leftParent leftValue ih =>
      cases right with
      | anonymous =>
          simp [psKernelNameEq] at hEq
      | num rightParent rightValue =>
          simp [psKernelNameEq] at hEq
      | str rightParent rightValue =>
          cases hStringEq :
              psKernelStringEq leftValue rightValue with
          | false =>
              simp [psKernelNameEq, hStringEq] at hEq
          | true =>
              have hParent :
                  psKernelNameEq leftParent rightParent = true := by
                simpa [psKernelNameEq, hStringEq] using hEq
              have hValue :
                  leftValue = rightValue :=
                hString leftValue rightValue hStringEq
              have hParentEq :
                  leftParent = rightParent :=
                ih rightParent hParent
              subst rightValue
              subst rightParent
              rfl
  | num leftParent leftValue ih =>
      cases right with
      | anonymous =>
          simp [psKernelNameEq] at hEq
      | str rightParent rightValue =>
          simp [psKernelNameEq] at hEq
      | num rightParent rightValue =>
          have hParts :
              leftValue = rightValue ∧
              psKernelNameEq leftParent rightParent = true := by
            simpa [psKernelNameEq] using hEq
          have hValue :
              leftValue = rightValue :=
            hParts.1
          have hParentEq :
              leftParent = rightParent :=
            ih rightParent hParts.2
          rw [← hValue, ← hParentEq]



theorem psKernelLevelEq_sound_of_string_law
    (hString : PsKernelStringEqSoundLaw)
    (left right : PsKernelLevel)
    (hEq : psKernelLevelEq left right = true) :
    left = right := by
  induction left generalizing right with
  | zero =>
      cases right with
      | zero => rfl
      | succ value => simp [psKernelLevelEq] at hEq
      | max a b => simp [psKernelLevelEq] at hEq
      | imax a b => simp [psKernelLevelEq] at hEq
      | param name => simp [psKernelLevelEq] at hEq
      | mvar name => simp [psKernelLevelEq] at hEq
  | succ leftValue ih =>
      cases right with
      | succ rightValue =>
          have hInner :
              leftValue = rightValue :=
            ih rightValue hEq
          rw [hInner]
      | _ =>
          simp [psKernelLevelEq] at hEq
  | max leftA leftB ihA ihB =>
      cases right with
      | max rightA rightB =>
          cases hA : psKernelLevelEq leftA rightA with
          | false =>
              simp [psKernelLevelEq, hA] at hEq
          | true =>
              have hB :
                  psKernelLevelEq leftB rightB = true := by
                simpa [psKernelLevelEq, hA] using hEq
              have hAEq : leftA = rightA :=
                ihA rightA hA
              have hBEq : leftB = rightB :=
                ihB rightB hB
              rw [hAEq, hBEq]
      | _ =>
          simp [psKernelLevelEq] at hEq
  | imax leftA leftB ihA ihB =>
      cases right with
      | imax rightA rightB =>
          cases hA : psKernelLevelEq leftA rightA with
          | false =>
              simp [psKernelLevelEq, hA] at hEq
          | true =>
              have hB :
                  psKernelLevelEq leftB rightB = true := by
                simpa [psKernelLevelEq, hA] using hEq
              have hAEq : leftA = rightA :=
                ihA rightA hA
              have hBEq : leftB = rightB :=
                ihB rightB hB
              rw [hAEq, hBEq]
      | _ =>
          simp [psKernelLevelEq] at hEq
  | param leftName =>
      cases right with
      | param rightName =>
          have hName :
              leftName = rightName :=
            psKernelNameEq_sound_of_string_law
              hString
              leftName
              rightName
              hEq
          rw [hName]
      | _ =>
          simp [psKernelLevelEq] at hEq
  | mvar leftName =>
      cases right with
      | mvar rightName =>
          have hName :
              leftName = rightName :=
            psKernelNameEq_sound_of_string_law
              hString
              leftName
              rightName
              hEq
          rw [hName]
      | _ =>
          simp [psKernelLevelEq] at hEq

theorem psKernelLevelListEq_sound_of_string_law
    (hString : PsKernelStringEqSoundLaw)
    (left right : List PsKernelLevel)
    (hEq : psKernelLevelListEq left right = true) :
    left = right := by
  induction left generalizing right with
  | nil =>
      cases right with
      | nil => rfl
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
              have hHeadEq :
                  leftHead = rightHead :=
                psKernelLevelEq_sound_of_string_law
                  hString
                  leftHead
                  rightHead
                  hHead
              have hTailEq :
                  leftTail = rightTail :=
                ih rightTail hTail
              rw [hHeadEq, hTailEq]


theorem psKernelLevelEq_trans_core
    (left middle right : PsKernelLevel)
    (hLeft : psKernelLevelEq left middle = true)
    (hRight : psKernelLevelEq middle right = true) :
    psKernelLevelEq left right = true := by
  induction left generalizing middle right with
  | zero =>
      cases middle with
      | zero =>
          cases right <;>
            simp [psKernelLevelEq] at hRight ⊢
      | _ =>
          simp [psKernelLevelEq] at hLeft
  | succ leftValue ih =>
      cases middle with
      | succ middleValue =>
          cases right with
          | succ rightValue =>
              exact
                ih middleValue rightValue hLeft hRight
          | _ =>
              simp [psKernelLevelEq] at hRight
      | _ =>
          simp [psKernelLevelEq] at hLeft
  | max leftA leftB ihA ihB =>
      cases middle with
      | max middleA middleB =>
          cases right with
          | max rightA rightB =>
              cases hLA :
                  psKernelLevelEq leftA middleA with
              | false =>
                  simp [psKernelLevelEq, hLA] at hLeft
              | true =>
                  have hLB :
                      psKernelLevelEq leftB middleB = true := by
                    simpa [psKernelLevelEq, hLA] using hLeft
                  cases hRA :
                      psKernelLevelEq middleA rightA with
                  | false =>
                      simp [psKernelLevelEq, hRA] at hRight
                  | true =>
                      have hRB :
                          psKernelLevelEq middleB rightB = true := by
                        simpa [psKernelLevelEq, hRA] using hRight
                      have hA :=
                        ihA middleA rightA hLA hRA
                      have hB :=
                        ihB middleB rightB hLB hRB
                      simp [psKernelLevelEq, hA, hB]
          | _ =>
              simp [psKernelLevelEq] at hRight
      | _ =>
          simp [psKernelLevelEq] at hLeft
  | imax leftA leftB ihA ihB =>
      cases middle with
      | imax middleA middleB =>
          cases right with
          | imax rightA rightB =>
              cases hLA :
                  psKernelLevelEq leftA middleA with
              | false =>
                  simp [psKernelLevelEq, hLA] at hLeft
              | true =>
                  have hLB :
                      psKernelLevelEq leftB middleB = true := by
                    simpa [psKernelLevelEq, hLA] using hLeft
                  cases hRA :
                      psKernelLevelEq middleA rightA with
                  | false =>
                      simp [psKernelLevelEq, hRA] at hRight
                  | true =>
                      have hRB :
                          psKernelLevelEq middleB rightB = true := by
                        simpa [psKernelLevelEq, hRA] using hRight
                      have hA :=
                        ihA middleA rightA hLA hRA
                      have hB :=
                        ihB middleB rightB hLB hRB
                      simp [psKernelLevelEq, hA, hB]
          | _ =>
              simp [psKernelLevelEq] at hRight
      | _ =>
          simp [psKernelLevelEq] at hLeft
  | param leftName =>
      cases middle with
      | param middleName =>
          cases right with
          | param rightName =>
              exact
                psKernelNameEq_trans_core
                  leftName
                  middleName
                  rightName
                  hLeft
                  hRight
          | _ =>
              simp [psKernelLevelEq] at hRight
      | _ =>
          simp [psKernelLevelEq] at hLeft
  | mvar leftName =>
      cases middle with
      | mvar middleName =>
          cases right with
          | mvar rightName =>
              exact
                psKernelNameEq_trans_core
                  leftName
                  middleName
                  rightName
                  hLeft
                  hRight
          | _ =>
              simp [psKernelLevelEq] at hRight
      | _ =>
          simp [psKernelLevelEq] at hLeft

theorem psKernelLevelListEq_trans_core
    (left middle right : List PsKernelLevel)
    (hLeft : psKernelLevelListEq left middle = true)
    (hRight : psKernelLevelListEq middle right = true) :
    psKernelLevelListEq left right = true := by
  induction left generalizing middle right with
  | nil =>
      cases middle with
      | nil =>
          cases right <;>
            simp [psKernelLevelListEq] at hRight ⊢
      | cons head tail =>
          simp [psKernelLevelListEq] at hLeft
  | cons leftHead leftTail ih =>
      cases middle with
      | nil =>
          simp [psKernelLevelListEq] at hLeft
      | cons middleHead middleTail =>
          cases right with
          | nil =>
              simp [psKernelLevelListEq] at hRight
          | cons rightHead rightTail =>
              cases hLH :
                  psKernelLevelEq leftHead middleHead with
              | false =>
                  simp [
                    psKernelLevelListEq,
                    hLH
                  ] at hLeft
              | true =>
                  have hLT :
                      psKernelLevelListEq
                          leftTail
                          middleTail =
                        true := by
                    simpa [
                      psKernelLevelListEq,
                      hLH
                    ] using hLeft
                  cases hRH :
                      psKernelLevelEq middleHead rightHead with
                  | false =>
                      simp [
                        psKernelLevelListEq,
                        hRH
                      ] at hRight
                  | true =>
                      have hRT :
                          psKernelLevelListEq
                              middleTail
                              rightTail =
                            true := by
                        simpa [
                          psKernelLevelListEq,
                          hRH
                        ] using hRight
                      have hHead :=
                        psKernelLevelEq_trans_core
                          leftHead
                          middleHead
                          rightHead
                          hLH
                          hRH
                      have hTail :=
                        ih middleTail rightTail hLT hRT
                      simp [
                        psKernelLevelListEq,
                        hHead,
                        hTail
                      ]

theorem psKernelBoolEq_trans_core
    (left middle right : Bool)
    (hLeft : psKernelBoolEq left middle = true)
    (hRight : psKernelBoolEq middle right = true) :
    psKernelBoolEq left right = true := by
  cases left <;>
    cases middle <;>
    cases right <;>
    simp [psKernelBoolEq] at hLeft hRight ⊢

theorem psKernelLiteralEq_trans_core
    (left middle right : PsKernelLiteral)
    (hLeft : psKernelLiteralEq left middle = true)
    (hRight : psKernelLiteralEq middle right = true) :
    psKernelLiteralEq left right = true := by
  cases left with
  | nat leftValue =>
      cases middle with
      | nat middleValue =>
          cases right with
          | nat rightValue =>
              exact
                psKernelNatBeq_trans_core
                  leftValue
                  middleValue
                  rightValue
                  hLeft
                  hRight
          | str rightValue =>
              simp [psKernelLiteralEq] at hRight
      | str middleValue =>
          simp [psKernelLiteralEq] at hLeft
  | str leftValue =>
      cases middle with
      | nat middleValue =>
          simp [psKernelLiteralEq] at hLeft
      | str middleValue =>
          cases right with
          | nat rightValue =>
              simp [psKernelLiteralEq] at hRight
          | str rightValue =>
              exact
                psKernelStringEq_trans_core
                  leftValue
                  middleValue
                  rightValue
                  hLeft
                  hRight

theorem psKernelExprEq_trans_core
    (left middle right : PsKernelExpr)
    (hLeft : psKernelExprEq left middle = true)
    (hRight : psKernelExprEq middle right = true) :
    psKernelExprEq left right = true := by
  induction left generalizing middle right with
  | bvar leftIndex =>
      cases middle with
      | bvar middleIndex =>
          cases right with
          | bvar rightIndex =>
              exact
                psKernelNatBeq_trans_core
                  leftIndex
                  middleIndex
                  rightIndex
                  hLeft
                  hRight
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


theorem psKernelLevelEquivalent_sound_of_string_law
    (hString : PsKernelStringEqSoundLaw)
    (left right : PsKernelLevel)
    (hEq : psKernelLevelEquivalent left right = true) :
    psKernelLevelNormalize left =
      psKernelLevelNormalize right := by
  unfold psKernelLevelEquivalent at hEq
  cases hRaw : psKernelLevelEq left right with
  | true =>
      have hSame :
          left = right :=
        psKernelLevelEq_sound_of_string_law
          hString
          left
          right
          hRaw
      rw [hSame]
  | false =>
      have hNormalized :
          psKernelLevelEq
              (psKernelLevelNormalize left)
              (psKernelLevelNormalize right) =
            true := by
        simpa [hRaw] using hEq
      exact
        psKernelLevelEq_sound_of_string_law
          hString
          (psKernelLevelNormalize left)
          (psKernelLevelNormalize right)
          hNormalized
