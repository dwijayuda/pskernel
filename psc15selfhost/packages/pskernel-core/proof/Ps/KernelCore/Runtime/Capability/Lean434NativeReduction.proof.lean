import Ps.KernelCore.Runtime.Capability.Lean434NativeReduction

theorem psKernelNativeBoolExpr_true
    (trueName falseName : PsKernelName) :
    psKernelNativeBoolExpr trueName falseName true =
      PsKernelExpr.const trueName List.nil := by
  rfl

theorem psKernelNativeBoolExpr_false
    (trueName falseName : PsKernelName) :
    psKernelNativeBoolExpr trueName falseName false =
      PsKernelExpr.const falseName List.nil := by
  rfl

theorem psKernelReduceNativeWith_none
    (reduceBoolName reduceNatName boolTrueName boolFalseName : PsKernelName)
    (expr : PsKernelExpr) :
    psKernelReduceNativeWith
        Option.none
        reduceBoolName
        reduceNatName
        boolTrueName
        boolFalseName
        expr =
      Except.ok Option.none := by
  rfl
