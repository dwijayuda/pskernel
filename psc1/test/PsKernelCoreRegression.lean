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
  let local := PsKernelExpr.fvar fName
  let closed := PsKernelExpr.sort PsKernelLevel.zero
  let wrapped := PsKernelExpr.mdata 0 (PsKernelExpr.app closed local)
  requireKernel "closed semantic cache is eligible"
    (psKernelSemanticCacheEligible closed)
  requireKernel "raw local semantic cache is ineligible"
    (!psKernelSemanticCacheEligible local)
  requireKernel "wrapped local semantic cache is ineligible"
    (!psKernelSemanticCacheEligible wrapped)
  requireKernel "local defeq pair semantic cache is ineligible"
    (!psKernelSemanticPairCacheEligible local closed)
  requireKernel "closed defeq pair semantic cache is eligible"
    (psKernelSemanticPairCacheEligible closed closed)

  let parent := psKernelCheckerStateEmpty
  let allocated := psKernelCheckerStateFreshName parent fName
  let childMap := psKernelExprMapInsert psKernelExprMapEmpty local closed
  let childPairs := psKernelExprPairSetInsert psKernelExprPairSetEmpty local closed
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
    (match psKernelExprMapGet restored.whnf local with
      | Option.none => true
      | Option.some _ => false)
  requireKernel "scope drops child checked-inference cache"
    (match psKernelExprMapGet restored.checkedInfer local with
      | Option.none => true
      | Option.some _ => false)
  requireKernel "scope drops child positive defeq cache"
    (!psKernelExprPairSetContains restored.success local closed)
  requireKernel "scope drops child negative defeq cache"
    (!psKernelExprPairSetContains restored.failure local closed)
  let u := PsKernelLevel.param (PsKernelName.str PsKernelName.anonymous "u")
  let v := PsKernelLevel.param (PsKernelName.str PsKernelName.anonymous "v")
  let shiftedMax := PsKernelLevel.succ (PsKernelLevel.max u v)
  let maxOfShifted := PsKernelLevel.max (PsKernelLevel.succ u) (PsKernelLevel.succ v)
  requireKernel "max universe successor distributes to both arms"
    (psKernelLevelEquivalent shiftedMax maxOfShifted)
