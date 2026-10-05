import Ps.KernelCore.Checker.Session

theorem psKernelMkCheckerSession_recDepth_zero
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) :
    (psKernelMkCheckerSession
      environment levelParams safety maxRecDepth maxNatSize).context.recDepth =
      0 := by
  rfl

theorem psKernelMkCheckerSession_state_empty
    (environment : PsKernelEnvironment)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) :
    (psKernelMkCheckerSession
      environment levelParams safety maxRecDepth maxNatSize).state =
      psKernelCheckerStateEmpty := by
  rfl

theorem psKernelSessionWhnf_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (error : String)
    (h :
      psKernelCheckerWhnf
          fuel session.context session.state expr =
        Except.error error) :
    psKernelSessionWhnf fuel session expr =
      Except.error error := by
  simp [psKernelSessionWhnf, h]

theorem psKernelSessionWhnf_success
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (state : PsKernelCheckerState)
    (h :
      psKernelCheckerWhnf
          fuel session.context session.state expr =
        Except.ok (Prod.mk result state)) :
    psKernelSessionWhnf fuel session expr =
      Except.ok
        (Prod.mk
          result
          (PsKernelCheckerSession.mk session.context state)) := by
  simp [psKernelSessionWhnf, h]

theorem psKernelSessionInfer_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (error : String)
    (h :
      psKernelCheckerInfer
          fuel session.context session.state expr =
        Except.error error) :
    psKernelSessionInfer fuel session expr =
      Except.error error := by
  simp [psKernelSessionInfer, h]

theorem psKernelSessionCheck_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (expr : PsKernelExpr)
    (error : String)
    (h :
      psKernelCheckerCheck
          fuel session.context session.state expr =
        Except.error error) :
    psKernelSessionCheck fuel session expr =
      Except.error error := by
  simp [psKernelSessionCheck, h]

theorem psKernelSessionIsDefEq_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (left right : PsKernelExpr)
    (error : String)
    (h :
      psKernelIsDefEq
          fuel session.context session.state left right =
        Except.error error) :
    psKernelSessionIsDefEq fuel session left right =
      Except.error error := by
  simp [psKernelSessionIsDefEq, h]
