import Ps.KernelCore.Checker.DefEq.DeltaStep

theorem psKernelDefEqFinishLazyStep_equal
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h :
      psKernelDefEqQuick
          defeq context state left right =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk PsKernelDeltaStepResult.equal nextState) := by
  simp [psKernelDefEqFinishLazyStep, h]

theorem psKernelDefEqFinishLazyStep_different
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h :
      psKernelDefEqQuick
          defeq context state left right =
        Except.ok
          (Prod.mk (Option.some false) nextState)) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk
          (PsKernelDeltaStepResult.different left right)
          nextState) := by
  simp [psKernelDefEqFinishLazyStep, h]

theorem psKernelDefEqFinishLazyStep_continue
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h :
      psKernelDefEqQuick
          defeq context state left right =
        Except.ok
          (Prod.mk Option.none nextState)) :
    psKernelDefEqFinishLazyStep
        defeq context state left right =
      Except.ok
        (Prod.mk
          (PsKernelDeltaStepResult.continue left right)
          nextState) := by
  simp [psKernelDefEqFinishLazyStep, h]
