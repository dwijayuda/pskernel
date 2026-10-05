import Ps.KernelCore.Checker.DefEq.FinalRules

theorem psKernelDefEqEtaStructFieldsWithFuel_zero
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (induct : PsKernelName)
    (term : PsKernelExpr)
    (args : List PsKernelExpr)
    (numParams index : Nat) :
    psKernelDefEqEtaStructFieldsWithFuel
        0 defeq context state induct term args numParams index =
      Except.error "kernel structure eta budget exhausted" := by
  rfl
