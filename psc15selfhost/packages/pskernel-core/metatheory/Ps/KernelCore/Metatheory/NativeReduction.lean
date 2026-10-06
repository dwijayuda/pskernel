import Ps.KernelCore.Runtime.Capability.Lean434NativeReduction

/-
Explicit Assurance Plane model of the trusted native-reduction boundary.

A native evaluator is an extension of the TCB.  These constructors do not
attempt to prove the evaluator internally; they record exactly which evaluator
answer justifies the native reduction observed by the portable kernel wrapper.
-/

inductive PsKernelTrustedNativeReduction
    (evaluator : PsKernelNativeEvaluator)
    (reduceBoolName reduceNatName : PsKernelName)
    (boolTrueName boolFalseName : PsKernelName) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | bool
      (marker target : PsKernelName)
      (targetLevels : List PsKernelLevel)
      (value : Bool)
      (hMarker :
        psKernelNameEq marker reduceBoolName = true)
      (hEval :
        evaluator.evalBool target =
          Except.ok (Option.some value)) :
      PsKernelTrustedNativeReduction
        evaluator
        reduceBoolName
        reduceNatName
        boolTrueName
        boolFalseName
        (PsKernelExpr.app
          (PsKernelExpr.const marker List.nil)
          (PsKernelExpr.const target targetLevels))
        (psKernelNativeBoolExpr
          boolTrueName
          boolFalseName
          value)
  | nat
      (marker target : PsKernelName)
      (targetLevels : List PsKernelLevel)
      (value : Nat)
      (hNotBool :
        psKernelNameEq marker reduceBoolName = false)
      (hMarker :
        psKernelNameEq marker reduceNatName = true)
      (hEval :
        evaluator.evalNat target =
          Except.ok (Option.some value)) :
      PsKernelTrustedNativeReduction
        evaluator
        reduceBoolName
        reduceNatName
        boolTrueName
        boolFalseName
        (PsKernelExpr.app
          (PsKernelExpr.const marker List.nil)
          (PsKernelExpr.const target targetLevels))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat value))
