import Ps.KernelCore.Checker.Projection

theorem psKernelProjectionApplyParamsWithFuel_zero
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index numParams : Nat)
    (current : PsKernelExpr) :
    psKernelProjectionApplyParamsWithFuel
        0 whnf context state args index numParams current =
      Except.error "kernel projection parameter budget exhausted" := by
  rfl

theorem psKernelProjectionSkipFieldsWithFuel_zero
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (inductName : PsKernelName)
    (structValue : PsKernelExpr)
    (propType : Bool)
    (targetIndex index : Nat)
    (current : PsKernelExpr) :
    psKernelProjectionSkipFieldsWithFuel
        0 whnf inferType context state inductName structValue
        propType targetIndex index current =
      Except.error "kernel projection field budget exhausted" := by
  rfl

theorem psKernelProjectionEnsureSortWith_error
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (type : PsKernelExpr)
    (error : String)
    (h : whnf context state type = Except.error error) :
    psKernelProjectionEnsureSortWith whnf context state type =
      Except.error error := by
  simp [psKernelProjectionEnsureSortWith, h]
