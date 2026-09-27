import Ps.KernelCore
import PSC1Kernel.TypeChecker

def psKcQuotReduceApplyArgs
    (fn : PsKernelCoreExpr) : List PsKernelCoreExpr -> PsKernelCoreExpr
  | [] => fn
  | arg :: rest =>
      psKcQuotReduceApplyArgs (PsKernelCoreExpr.app fn arg) rest

def psRefQuotReduceApplyArgs
    (fn : PSC1Kernel.Expr) : List PSC1Kernel.Expr -> PSC1Kernel.Expr
  | [] => fn
  | arg :: rest =>
      psRefQuotReduceApplyArgs (PSC1Kernel.Expr.app fn arg) rest

def psKcQuotReduceSort0 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psRefQuotReduceSort0 : PSC1Kernel.Expr :=
  PSC1Kernel.Expr.sort PSC1Kernel.Level.zero

def psKcQuotReduceLit (value : Nat) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat value)

def psRefQuotReduceLit (value : Nat) : PSC1Kernel.Expr :=
  PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat value)

def psKcQuotReduceIdentity : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam
    PsKernelCoreName.anonymous
    psKcQuotReduceSort0
    (PsKernelCoreExpr.bvar 0)
    PsKernelCoreBinderInfo.default

def psRefQuotReduceIdentity : PSC1Kernel.Expr :=
  PSC1Kernel.Expr.lam
    PSC1Kernel.Name.anonymous
    psRefQuotReduceSort0
    (PSC1Kernel.Expr.bvar 0)
    PSC1Kernel.BinderInfo.default

def psKcQuotReduceConst (name : PsKernelCoreName) : PsKernelCoreExpr :=
  PsKernelCoreExpr.const name PsKernelCoreList.nil

def psRefQuotReduceConst (name : PSC1Kernel.Name) : PSC1Kernel.Expr :=
  PSC1Kernel.Expr.const name []

def psKcQuotReduceMk (representative : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcQuotReduceApplyArgs
    (psKcQuotReduceConst psKernelCoreQuotMkName)
    [psKcQuotReduceSort0, psKcQuotReduceSort0, representative]

def psRefQuotReduceMk (representative : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  psRefQuotReduceApplyArgs
    (psRefQuotReduceConst PSC1Kernel.kernelQuotMkName)
    [psRefQuotReduceSort0, psRefQuotReduceSort0, representative]

def psKcQuotReduceLiftWith
    (f : PsKernelCoreExpr)
    (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcQuotReduceApplyArgs
    (psKcQuotReduceConst psKernelCoreQuotLiftName)
    [ psKcQuotReduceSort0,
      psKcQuotReduceSort0,
      psKcQuotReduceSort0,
      f,
      psKcQuotReduceSort0,
      major ]

def psRefQuotReduceLiftWith
    (f : PSC1Kernel.Expr)
    (major : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  psRefQuotReduceApplyArgs
    (psRefQuotReduceConst PSC1Kernel.kernelQuotLiftName)
    [ psRefQuotReduceSort0,
      psRefQuotReduceSort0,
      psRefQuotReduceSort0,
      f,
      psRefQuotReduceSort0,
      major ]

def psKcQuotReduceIndWith
    (proof : PsKernelCoreExpr)
    (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psKcQuotReduceApplyArgs
    (psKcQuotReduceConst psKernelCoreQuotIndName)
    [ psKcQuotReduceSort0,
      psKcQuotReduceSort0,
      psKcQuotReduceSort0,
      proof,
      major ]

def psRefQuotReduceIndWith
    (proof : PSC1Kernel.Expr)
    (major : PSC1Kernel.Expr) : PSC1Kernel.Expr :=
  psRefQuotReduceApplyArgs
    (psRefQuotReduceConst PSC1Kernel.kernelQuotIndName)
    [ psRefQuotReduceSort0,
      psRefQuotReduceSort0,
      psRefQuotReduceSort0,
      proof,
      major ]

def psKcQuotReduceEnv : PsKernelCoreEnvironment :=
  psKernelCoreEnvironmentMarkQuotInitialized psKernelCoreEnvironmentEmpty

def psRefQuotReduceEnv : PSC1Kernel.Environment :=
  PSC1Kernel.Environment.empty.markQuotInitialized

def psKcQuotReduceWhnf (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String PsKernelCoreExpr :=
  psKernelCoreWhnf 64 psKcQuotReduceEnv psKernelCoreLocalContextEmpty expr

def psRefQuotReduceWhnf (expr : PSC1Kernel.Expr) : Except String PSC1Kernel.Expr :=
  PSC1Kernel.whnf
    (PSC1Kernel.CheckerContext.empty psRefQuotReduceEnv)
    expr

def psKcQuotReduceResultEq
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : PsKernelCoreExpr) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok value => psKernelCoreExprEq value expected

def psRefQuotReduceResultEq
    (result : Except String PSC1Kernel.Expr)
    (expected : PSC1Kernel.Expr) : Bool :=
  match result with
  | Except.error _ => false
  | Except.ok value => PSC1Kernel.Expr.eq value expected

def psRefQuotReductionOracle : Bool :=
  let lift :=
    psRefQuotReduceLiftWith
      psRefQuotReduceIdentity
      (psRefQuotReduceMk (psRefQuotReduceLit 7))
  let ind :=
    psRefQuotReduceIndWith
      psRefQuotReduceIdentity
      (psRefQuotReduceMk (psRefQuotReduceLit 8))
  let majorWhnf :=
    psRefQuotReduceLiftWith
      psRefQuotReduceIdentity
      (PSC1Kernel.Expr.mdata 9 (psRefQuotReduceMk (psRefQuotReduceLit 11)))
  let underapplied :=
    psRefQuotReduceApplyArgs
      (psRefQuotReduceConst PSC1Kernel.kernelQuotLiftName)
      [ psRefQuotReduceSort0,
        psRefQuotReduceSort0,
        psRefQuotReduceSort0,
        psRefQuotReduceIdentity,
        psRefQuotReduceSort0 ]
  let wrongMajor :=
    psRefQuotReduceLiftWith psRefQuotReduceIdentity (psRefQuotReduceLit 12)
  let uninitialized :=
    psRefQuotReduceLiftWith
      psRefQuotReduceIdentity
      (psRefQuotReduceMk (psRefQuotReduceLit 13))
  let trailingF :=
    PSC1Kernel.Expr.lam PSC1Kernel.Name.anonymous psRefQuotReduceSort0
      (PSC1Kernel.Expr.lam PSC1Kernel.Name.anonymous psRefQuotReduceSort0
        (PSC1Kernel.Expr.bvar 1)
        PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.default
  let trailingBase :=
    psRefQuotReduceLiftWith trailingF
      (psRefQuotReduceMk (psRefQuotReduceLit 14))
  let trailing := PSC1Kernel.Expr.app trailingBase (psRefQuotReduceLit 15)
  psRefQuotReduceResultEq (psRefQuotReduceWhnf lift) (psRefQuotReduceLit 7) &&
  psRefQuotReduceResultEq (psRefQuotReduceWhnf ind) (psRefQuotReduceLit 8) &&
  psRefQuotReduceResultEq (psRefQuotReduceWhnf majorWhnf) (psRefQuotReduceLit 11) &&
  psRefQuotReduceResultEq (psRefQuotReduceWhnf underapplied) underapplied &&
  psRefQuotReduceResultEq (psRefQuotReduceWhnf wrongMajor) wrongMajor &&
  psRefQuotReduceResultEq
    (PSC1Kernel.whnf (PSC1Kernel.CheckerContext.empty PSC1Kernel.Environment.empty) uninitialized)
    uninitialized &&
  psRefQuotReduceResultEq (psRefQuotReduceWhnf trailing) (psRefQuotReduceLit 14)

def psKernelCoreQuotReductionCandidate : Bool :=
  let lift :=
    psKcQuotReduceLiftWith
      psKcQuotReduceIdentity
      (psKcQuotReduceMk (psKcQuotReduceLit 7))
  let ind :=
    psKcQuotReduceIndWith
      psKcQuotReduceIdentity
      (psKcQuotReduceMk (psKcQuotReduceLit 8))
  let majorWhnf :=
    psKcQuotReduceLiftWith
      psKcQuotReduceIdentity
      (PsKernelCoreExpr.mdata 9 (psKcQuotReduceMk (psKcQuotReduceLit 11)))
  let underapplied :=
    psKcQuotReduceApplyArgs
      (psKcQuotReduceConst psKernelCoreQuotLiftName)
      [ psKcQuotReduceSort0,
        psKcQuotReduceSort0,
        psKcQuotReduceSort0,
        psKcQuotReduceIdentity,
        psKcQuotReduceSort0 ]
  let wrongMajor :=
    psKcQuotReduceLiftWith psKcQuotReduceIdentity (psKcQuotReduceLit 12)
  let uninitialized :=
    psKcQuotReduceLiftWith
      psKcQuotReduceIdentity
      (psKcQuotReduceMk (psKcQuotReduceLit 13))
  let trailingF :=
    PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcQuotReduceSort0
      (PsKernelCoreExpr.lam PsKernelCoreName.anonymous psKcQuotReduceSort0
        (PsKernelCoreExpr.bvar 1)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
  let trailingBase :=
    psKcQuotReduceLiftWith trailingF
      (psKcQuotReduceMk (psKcQuotReduceLit 14))
  let trailing := PsKernelCoreExpr.app trailingBase (psKcQuotReduceLit 15)
  let tinyBudgetFails :=
    match psKernelCoreWhnfWithResources
        1 psKernelCoreResourceConfigDefault
        psKcQuotReduceEnv psKernelCoreLocalContextEmpty lift with
    | PsKernelCoreResult.error message => message == "reduction budget exhausted"
    | PsKernelCoreResult.ok _ => false
  psKcQuotReduceResultEq (psKcQuotReduceWhnf lift) (psKcQuotReduceLit 7) &&
  psKcQuotReduceResultEq (psKcQuotReduceWhnf ind) (psKcQuotReduceLit 8) &&
  psKcQuotReduceResultEq (psKcQuotReduceWhnf majorWhnf) (psKcQuotReduceLit 11) &&
  psKcQuotReduceResultEq (psKcQuotReduceWhnf underapplied) underapplied &&
  psKcQuotReduceResultEq (psKcQuotReduceWhnf wrongMajor) wrongMajor &&
  psKcQuotReduceResultEq
    (psKernelCoreWhnf 64 psKernelCoreEnvironmentEmpty psKernelCoreLocalContextEmpty uninitialized)
    uninitialized &&
  psKcQuotReduceResultEq (psKcQuotReduceWhnf trailing) (psKcQuotReduceLit 14) &&
  tinyBudgetFails

def main : IO Unit := do
  if !psRefQuotReductionOracle then
    throw (IO.userError "PSC2_KERNEL_CORE_QUOT_REDUCTION: ORACLE FIXTURE FAIL")
  if !psKernelCoreQuotReductionCandidate then
    throw (IO.userError "PSC2_KERNEL_CORE_QUOT_REDUCTION: RED")
  IO.println "PSC2_KERNEL_CORE_QUOT_REDUCTION: PASS"
