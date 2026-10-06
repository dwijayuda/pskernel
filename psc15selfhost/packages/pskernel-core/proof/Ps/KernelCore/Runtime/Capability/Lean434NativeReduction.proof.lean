import Ps.KernelCore.Runtime.Capability.Lean434NativeReduction
import Ps.KernelCore.Metatheory.NativeReduction

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


theorem psKernelReduceNativeWith_success_refines_trusted
    (evaluator : PsKernelNativeEvaluator)
    (reduceBoolName reduceNatName boolTrueName boolFalseName : PsKernelName)
    (expr result : PsKernelExpr)
    (hSuccess :
      psKernelReduceNativeWith
          (Option.some evaluator)
          reduceBoolName
          reduceNatName
          boolTrueName
          boolFalseName
          expr =
        Except.ok (Option.some result)) :
    PsKernelTrustedNativeReduction
      evaluator
      reduceBoolName
      reduceNatName
      boolTrueName
      boolFalseName
      expr
      result := by
  cases expr with
  | app fn arg =>
      cases fn with
      | const marker levels =>
          cases levels with
          | nil =>
              cases arg with
              | const target targetLevels =>
                  cases hBool :
                      psKernelNameEq marker reduceBoolName with
                  | true =>
                      cases hEval :
                          evaluator.evalBool target with
                      | error error =>
                          simp [
                            psKernelReduceNativeWith,
                            hBool,
                            hEval
                          ] at hSuccess
                      | ok answer =>
                          cases answer with
                          | none =>
                              simp [
                                psKernelReduceNativeWith,
                                hBool,
                                hEval
                              ] at hSuccess
                          | some value =>
                              simp [
                                psKernelReduceNativeWith,
                                hBool,
                                hEval
                              ] at hSuccess
                              subst result
                              exact
                                PsKernelTrustedNativeReduction.bool
                                  marker
                                  target
                                  targetLevels
                                  value
                                  hBool
                                  hEval
                  | false =>
                      cases hNat :
                          psKernelNameEq marker reduceNatName with
                      | false =>
                          simp [
                            psKernelReduceNativeWith,
                            hBool,
                            hNat
                          ] at hSuccess
                      | true =>
                          cases hEval :
                              evaluator.evalNat target with
                          | error error =>
                              simp [
                                psKernelReduceNativeWith,
                                hBool,
                                hNat,
                                hEval
                              ] at hSuccess
                          | ok answer =>
                              cases answer with
                              | none =>
                                  simp [
                                    psKernelReduceNativeWith,
                                    hBool,
                                    hNat,
                                    hEval
                                  ] at hSuccess
                              | some value =>
                                  simp [
                                    psKernelReduceNativeWith,
                                    hBool,
                                    hNat,
                                    hEval
                                  ] at hSuccess
                                  subst result
                                  exact
                                    PsKernelTrustedNativeReduction.nat
                                      marker
                                      target
                                      targetLevels
                                      value
                                      hBool
                                      hNat
                                      hEval
              | _ =>
                  simp [psKernelReduceNativeWith] at hSuccess
          | cons level rest =>
              simp [psKernelReduceNativeWith] at hSuccess
      | _ =>
          simp [psKernelReduceNativeWith] at hSuccess
  | _ =>
      simp [psKernelReduceNativeWith] at hSuccess
