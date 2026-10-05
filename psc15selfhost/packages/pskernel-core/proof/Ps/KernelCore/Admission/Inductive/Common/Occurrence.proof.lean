import Ps.KernelCore.Admission.Inductive.Common.Occurrence

theorem psKernelSimpleUniformParamArgsMatchWorker_nil
    (offset index : Nat) :
    psKernelSimpleUniformParamArgsMatchWorker
        List.nil offset index =
      true := by
  rfl

theorem psKernelSimpleCheckUniformOccurrenceWithFuel_zero
    (declaredNames : List PsKernelName)
    (expectedLevels : List PsKernelLevel)
    (numParams : Nat)
    (expr : PsKernelExpr)
    (offset : Nat) :
    psKernelSimpleCheckUniformOccurrenceWithFuel
        0 declaredNames expectedLevels numParams expr offset =
      Except.error
        "simple inductive uniform-occurrence budget exhausted" := by
  rfl

theorem psKernelExprContainsConst_bvar
    (target : PsKernelName)
    (index : Nat) :
    psKernelExprContainsConst
        target
        (PsKernelExpr.bvar index) =
      false := by
  rfl
