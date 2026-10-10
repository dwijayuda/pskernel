import Ps.KernelCore.Runtime.Capability.Lean434NativeReduction
import Ps.KernelCore.Metatheory.Judgments

/-
Historical Assurance Plane model of the Lean 4.34 native-reduction boundary.
The 4.35 production checker does not invoke this capability.

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


/-
The native evaluator is intentionally outside the portable logical kernel.
This law is the bridge consumed by WHNF soundness: whenever the
installed runtime capability publishes a native reduction, that answer must be
a valid reduction in the current semantic environment/local context.

For 4.35 the law is discharged below because psKernelReduceNative always
returns no reduction. The legacy evaluator itself is not claimed verified.
-/
def PsKernelNativeReductionSoundLaw : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (expr result : PsKernelExpr),
    psKernelReduceNative context expr =
      Except.ok (Option.some result) ->
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result

/-- The 4.35 kernel never invokes a native evaluator, so this obligation is discharged. -/
theorem psKernelNativeReductionSound_lean435 : PsKernelNativeReductionSoundLaw := by
  intro context expr result h
  simp [psKernelReduceNative] at h
