import Ps.KernelCore.Admission.Inductive.Common.RecursorValidation

theorem psKernelValidateSimpleRecursorRulesWorker_empty
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel) :
    psKernelValidateSimpleRecursorRulesWorker
        List.nil fuel session params ruleBinders motive levels List.nil =
      Except.ok Unit.unit := by
  rfl
