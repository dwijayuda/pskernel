import Ps.KernelCore.Admission.Inductive.Ordinary.Recursor

theorem psKernelOpenBinderListLength_eq_length
    (values : List PsKernelOpenBinder) :
    psKernelOpenBinderListLength values = List.length values := by
  induction values with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelOpenBinderListLength, ih]

theorem psKernelMakeSimpleRecursiveCallsWorker_nil
    (recName : PsKernelName)
    (recLevels : List PsKernelLevel)
    (fixed : List PsKernelExpr) :
    psKernelMakeSimpleRecursiveCallsWorker
        List.nil recName recLevels fixed =
      List.nil := by
  rfl

theorem psKernelMakeSimpleRecursorRulesWorker_nil
    (recName : PsKernelName)
    (recLevels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (allMinors ruleBinders minors : List PsKernelOpenBinder) :
    psKernelMakeSimpleRecursorRulesWorker
        List.nil recName recLevels params motive
        allMinors ruleBinders minors =
      List.nil := by
  rfl
