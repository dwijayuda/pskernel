import Ps.KernelCore.SelfHost
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

private def requireKernel
    (caseName : String)
    (condition : Bool) : IO Unit := do
  if condition then
    IO.println s!"PSC1_KERNEL_REGRESSION PASS: {caseName}"
  else
    throw (IO.userError s!"PSC1_KERNEL_REGRESSION FAIL: {caseName}")


-- Exact reference behavior, retained only in tests to compare C0's source
-- rewrite with the previously accepted beta-spine algorithm.
private def betaReferencePlan (fn : PsKernelExpr) (args : List PsKernelExpr) :
    PsKernelExpr :=
  let result := psKernelWhnfCountLambdas fn args.length
  match Prod.fst result with
  | PsKernelExpr.lam _ _ body _ =>
      psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev body (args.take (Prod.snd result)))
        (args.drop (Prod.snd result))
  | _ => psKernelExprApplyArgsCheap fn args

private def betaOptimizedPlan (fn : PsKernelExpr) (args : List PsKernelExpr) :
    PsKernelExpr :=
  match psKernelC0BetaSpinePlan fn args with
  | Option.none => psKernelExprApplyArgsCheap fn args
  | Option.some plan => psKernelC0BetaSpineApply plan

private def checkBetaPort (caseName : String) (fn : PsKernelExpr)
    (args : List PsKernelExpr) : IO Unit := do
  requireKernel caseName
    (psKernelExprEq (betaReferencePlan fn args) (betaOptimizedPlan fn args))

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

  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let betaName := PsKernelName.str PsKernelName.anonymous "beta"
  let idLam := PsKernelExpr.lam betaName sort0
      (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let constantLam := PsKernelExpr.lam betaName sort0 sort0
      PsKernelBinderInfo.default
  let twoLams := PsKernelExpr.lam betaName sort0
      (PsKernelExpr.lam betaName sort0 (PsKernelExpr.bvar 1)
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  let oneArg := [sort0]
  let twoArgs := [sort0, PsKernelExpr.bvar 0]
  let threeArgs := [sort0, PsKernelExpr.bvar 0, sort0]
  checkBetaPort "C0 beta identity" idLam oneArg
  checkBetaPort "C0 beta nondependent body" constantLam oneArg
  checkBetaPort "C0 beta two binders" twoLams twoArgs
  checkBetaPort "C0 beta argument excess" twoLams threeArgs
  checkBetaPort "C0 beta argument shortfall" twoLams oneArg
  checkBetaPort "C0 beta unchanged nonlambda" sort0 oneArg
  requireKernel "C0 linear consumed lambda spine matches old fuel walker"
    (let old := psKernelExprConsumeLambdaSpineWithFuel
        (Nat.succ (psKernelExprNodeCount twoLams)) twoLams twoArgs 0
     let newer := psKernelExprConsumeLambdaSpine twoLams twoArgs 0
     Prod.snd old == Prod.snd newer &&
       psKernelExprEq (Prod.fst old) (Prod.fst newer))
  let sample := "héllo"
  let p := String.Pos.Raw.mk 0
  requireKernel "Lean 4.34 string atEnd alias parity"
    (String.Pos.Raw.atEnd sample p == String.Internal.atEnd sample p)
  requireKernel "Lean 4.34 UTF-8 next alias parity"
    (String.Pos.Raw.byteIdx (String.Pos.Raw.next sample p) ==
      String.Pos.Raw.byteIdx (String.Internal.next sample p))
  requireKernel "Nat maximum shim matches pinned Lean"
    (psKernelStateNatMax 19 7 == Nat.max 19 7 &&
      psKernelStateNatMax 3 12 == Nat.max 3 12)
  requireKernel "String append alias parity"
    (String.append "é" "x" == String.Internal.append "é" "x")
  let u := PsKernelLevel.param (PsKernelName.str PsKernelName.anonymous "u")
  let v := PsKernelLevel.param (PsKernelName.str PsKernelName.anonymous "v")
  let shiftedMax := PsKernelLevel.succ (PsKernelLevel.max u v)
  let maxOfShifted := PsKernelLevel.max (PsKernelLevel.succ u) (PsKernelLevel.succ v)
  requireKernel "max universe successor distributes to both arms"
    (psKernelLevelEquivalent shiftedMax maxOfShifted)
