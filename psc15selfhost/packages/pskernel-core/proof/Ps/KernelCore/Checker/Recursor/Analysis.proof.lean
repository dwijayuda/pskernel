import Ps.KernelCore.Checker.Recursor.Analysis

theorem psKernelFindRecursorRule_nil
    (ctorName : PsKernelName) :
    psKernelFindRecursorRule ctorName List.nil = Option.none := by
  rfl

theorem psKernelRecursorMajorInductWithFuel_zero
    (expr : PsKernelExpr)
    (index : Nat) :
    psKernelRecursorMajorInductWithFuel 0 expr index = Option.none := by
  rfl

theorem psKernelExprListAnyMVar_nil :
    psKernelExprListAnyMVar List.nil = false := by
  rfl

theorem psKernelRecursorExprListAppend_eq_append
    (left right : List PsKernelExpr) :
    psKernelExprListAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelExprListAppend, ih]

theorem psKernelStructureFieldsWithFuel_zero
    (inductName : PsKernelName)
    (major : PsKernelExpr)
    (fieldCount index : Nat) :
    psKernelStructureFieldsWithFuel
        0 inductName major fieldCount index =
      List.nil := by
  rfl
