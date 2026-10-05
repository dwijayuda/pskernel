import Ps.KernelCore.Metatheory.Judgments

theorem psKernelExprEq_true_refines_structural
    (left right : PsKernelExpr)
    (h : psKernelExprEq left right = true) :
    PsKernelStructuralExprEq left right := by
  induction left generalizing right with
  | bvar leftIndex =>
      cases right <;> simp [psKernelExprEq] at h
      subst_vars
      exact PsKernelStructuralExprEq.bvar leftIndex leftIndex (by simp)
  | fvar leftName =>
      cases right <;> simp [psKernelExprEq] at h
      exact PsKernelStructuralExprEq.fvar _ _ h
  | mvar leftName =>
      cases right <;> simp [psKernelExprEq] at h
      exact PsKernelStructuralExprEq.mvar _ _ h
  | sort leftLevel =>
      cases right <;> simp [psKernelExprEq] at h
      exact PsKernelStructuralExprEq.sort _ _ h
  | const leftName leftLevels =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightName rightLevels
      cases hName : psKernelNameEq leftName rightName with
      | false =>
          simp [psKernelExprEq, hName] at h
      | true =>
          have hLevels :
              psKernelLevelListEq leftLevels rightLevels = true := by
            simpa [psKernelExprEq, hName] using h
          exact
            PsKernelStructuralExprEq.const
              leftName rightName
              leftLevels rightLevels
              hName hLevels
  | app leftFn leftArg ihFn ihArg =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightFn rightArg
      cases hFn : psKernelExprEq leftFn rightFn with
      | false =>
          simp [psKernelExprEq, hFn] at h
      | true =>
          have hArg : psKernelExprEq leftArg rightArg = true := by
            simpa [psKernelExprEq, hFn] using h
          exact
            PsKernelStructuralExprEq.app
              leftFn leftArg rightFn rightArg
              (ihFn rightFn hFn)
              (ihArg rightArg hArg)
  | lam leftName leftType leftBody leftInfo ihType ihBody =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightName rightType rightBody rightInfo
      cases hType : psKernelExprEq leftType rightType with
      | false =>
          simp [psKernelExprEq, hType] at h
      | true =>
          have hBody : psKernelExprEq leftBody rightBody = true := by
            simpa [psKernelExprEq, hType] using h
          exact
            PsKernelStructuralExprEq.lam
              leftName rightName
              leftType leftBody rightType rightBody
              leftInfo rightInfo
              (ihType rightType hType)
              (ihBody rightBody hBody)
  | forallE leftName leftType leftBody leftInfo ihType ihBody =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightName rightType rightBody rightInfo
      cases hType : psKernelExprEq leftType rightType with
      | false =>
          simp [psKernelExprEq, hType] at h
      | true =>
          have hBody : psKernelExprEq leftBody rightBody = true := by
            simpa [psKernelExprEq, hType] using h
          exact
            PsKernelStructuralExprEq.forallE
              leftName rightName
              leftType leftBody rightType rightBody
              leftInfo rightInfo
              (ihType rightType hType)
              (ihBody rightBody hBody)
  | letE leftName leftType leftValue leftBody leftNondep ihType ihValue ihBody =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightName rightType rightValue rightBody rightNondep
      cases hType : psKernelExprEq leftType rightType with
      | false =>
          simp [psKernelExprEq, hType] at h
      | true =>
          cases hValue : psKernelExprEq leftValue rightValue with
          | false =>
              simp [psKernelExprEq, hType, hValue] at h
          | true =>
              cases hBody : psKernelExprEq leftBody rightBody with
              | false =>
                  simp [psKernelExprEq, hType, hValue, hBody] at h
              | true =>
                  have hNondep :
                      psKernelBoolEq leftNondep rightNondep = true := by
                    simpa [
                      psKernelExprEq,
                      hType,
                      hValue,
                      hBody
                    ] using h
                  exact
                    PsKernelStructuralExprEq.letE
                      leftName rightName
                      leftType leftValue leftBody
                      rightType rightValue rightBody
                      leftNondep rightNondep
                      (ihType rightType hType)
                      (ihValue rightValue hValue)
                      (ihBody rightBody hBody)
                      hNondep
  | lit leftLiteral =>
      cases right <;> simp [psKernelExprEq] at h
      exact PsKernelStructuralExprEq.lit _ _ h
  | mdata leftMetadata leftBody ihBody =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightMetadata rightBody
      cases hMetadata : Nat.beq leftMetadata rightMetadata with
      | false =>
          simp [psKernelExprEq, hMetadata] at h
      | true =>
          have hBody : psKernelExprEq leftBody rightBody = true := by
            simpa [psKernelExprEq, hMetadata] using h
          exact
            PsKernelStructuralExprEq.mdata
              leftMetadata rightMetadata
              leftBody rightBody
              hMetadata
              (ihBody rightBody hBody)
  | proj leftName leftIndex leftBody ihBody =>
      cases right <;> simp [psKernelExprEq] at h
      rename_i rightName rightIndex rightBody
      cases hName : psKernelNameEq leftName rightName with
      | false =>
          simp [psKernelExprEq, hName] at h
      | true =>
          cases hIndex : Nat.beq leftIndex rightIndex with
          | false =>
              simp [psKernelExprEq, hName, hIndex] at h
          | true =>
              have hBody : psKernelExprEq leftBody rightBody = true := by
                simpa [
                  psKernelExprEq,
                  hName,
                  hIndex
                ] using h
              exact
                PsKernelStructuralExprEq.proj
                  leftName rightName
                  leftIndex rightIndex
                  leftBody rightBody
                  hName hIndex
                  (ihBody rightBody hBody)

theorem psKernelExprEq_true_implies_defeq
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left right : PsKernelExpr)
    (h : psKernelExprEq left right = true) :
    PsKernelDefEqJudgment
      environment
      localContext
      left
      right := by
  exact
    PsKernelDefEqJudgment.structural
      left
      right
      (psKernelExprEq_true_refines_structural
        left
        right
        h)

theorem psKernelExprEqSound_all
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExprEqSound
      environment
      localContext := by
  intro left right h
  exact
    psKernelExprEq_true_implies_defeq
      environment
      localContext
      left
      right
      h
