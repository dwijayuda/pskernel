import Ps.KernelCore.SelfHost
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

private def requireKernel
    (caseName : String)
    (condition : Bool) : IO Unit := do
  if condition then
    IO.println s!"PSC1_KERNEL_REGRESSION PASS: {caseName}"
  else
    throw (IO.userError s!"PSC1_KERNEL_REGRESSION FAIL: {caseName}")

def main : IO Unit := do
  let fName := PsKernelName.str PsKernelName.anonymous "bound"
  let localExpr := PsKernelExpr.fvar fName
  let closed := PsKernelExpr.sort PsKernelLevel.zero
  let wrapped := PsKernelExpr.mdata 0 (PsKernelExpr.app closed localExpr)
  requireKernel "closed semantic cache is eligible"
    (psKernelSemanticCacheEligible closed)
  requireKernel "raw localExpr semantic cache is ineligible"
    (!psKernelSemanticCacheEligible localExpr)
  requireKernel "wrapped localExpr semantic cache is ineligible"
    (!psKernelSemanticCacheEligible wrapped)
  requireKernel "localExpr defeq pair semantic cache is ineligible"
    (!psKernelSemanticPairCacheEligible localExpr closed)
  requireKernel "closed defeq pair semantic cache is eligible"
    (psKernelSemanticPairCacheEligible closed closed)

  let parent := psKernelCheckerStateEmpty
  let allocated := psKernelCheckerStateFreshName parent fName
  let childMap := psKernelExprMapInsert psKernelExprMapEmpty localExpr closed
  let childPairs := psKernelExprPairSetInsert psKernelExprPairSetEmpty localExpr closed
  let child := psKernelCheckerStateWithFailure
    (psKernelCheckerStateWithSuccess
      (psKernelCheckerStateWithWhnf
        (psKernelCheckerStateWithCheckedInfer
          (Prod.snd allocated) childMap)
        childMap)
      childPairs)
    childPairs
  let restored := psKernelCheckerStateExitLocalScope parent child
  requireKernel "scope retains monotone fresh identifier"
    (restored.nextFresh == 1)
  requireKernel "scope drops child whnf cache"
    (match psKernelExprMapGet restored.whnf localExpr with
      | Option.none => true
      | Option.some _ => false)
  requireKernel "scope drops child checked-inference cache"
    (match psKernelExprMapGet restored.checkedInfer localExpr with
      | Option.none => true
      | Option.some _ => false)
  requireKernel "scope drops child positive defeq cache"
    (!psKernelExprPairSetContains restored.success localExpr closed)
  requireKernel "scope drops child negative defeq cache"
    (!psKernelExprPairSetContains restored.failure localExpr closed)
  let u := PsKernelLevel.param (PsKernelName.str PsKernelName.anonymous "u")
  let v := PsKernelLevel.param (PsKernelName.str PsKernelName.anonymous "v")
  let shiftedMax := PsKernelLevel.succ (PsKernelLevel.max u v)
  let maxOfShifted := PsKernelLevel.max (PsKernelLevel.succ u) (PsKernelLevel.succ v)
  requireKernel "max universe successor distributes to both arms"
    (psKernelLevelEquivalent shiftedMax maxOfShifted)
