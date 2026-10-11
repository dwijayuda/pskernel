import Ps.KernelCore.Checker.Reduction.WhnfCore

def c0LegacyBeta
    (fn : PsKernelExpr)
    (args : List PsKernelExpr) : PsKernelExpr :=
  let counted :=
    psKernelWhnfCountLambdas fn (psKernelExprListLength args)
  let last := Prod.fst counted
  let consumed := Prod.snd counted
  match last with
  | PsKernelExpr.lam _ _ body _ =>
      psKernelExprApplyArgsCheap
        (psKernelExprInstantiateRev
          body
          (psKernelExprListTake consumed args))
        (psKernelExprListDrop consumed args)
  | _ =>
      psKernelExprApplyArgsCheap fn args

def c0FastBeta
    (fn : PsKernelExpr)
    (args : List PsKernelExpr) : PsKernelExpr :=
  match psKernelC0BetaSpinePlan fn args with
  | Option.some plan =>
      psKernelC0BetaSpineApply plan
  | Option.none =>
      psKernelExprApplyArgsCheap fn args

def c0CheckCase
    (label : String)
    (fn : PsKernelExpr)
    (args : List PsKernelExpr) : IO Unit := do
  let oldResult := c0LegacyBeta fn args
  let newResult := c0FastBeta fn args
  if psKernelExprEqual oldResult newResult then
    pure ()
  else
    throw (IO.userError s!"C0 beta mismatch: {label}")

def c0CheckSubstitution
    (label : String)
    (expr : PsKernelExpr)
    (values : List PsKernelExpr)
    (offset : Nat) : IO Unit := do
  let original :=
    psKernelExprInstantiateAtChangedWithFuel
      (Nat.succ (psKernelExprNodeCount expr))
      expr
      0
      values
      offset
  let optimized :=
    psKernelExprInstantiateAtChanged expr 0 values offset
  if psKernelBoolEq (Prod.snd original) (Prod.snd optimized) &&
      psKernelExprEqual (Prod.fst original) (Prod.fst optimized) then
    pure ()
  else
    throw (IO.userError s!"C0 substitution mismatch: {label}")

def main : IO Unit := do
  let n := PsKernelName.anonymous
  let ty := PsKernelExpr.sort PsKernelLevel.zero
  let x := PsKernelExpr.bvar 0
  let y := PsKernelExpr.bvar 1
  let z := PsKernelExpr.bvar 2
  let lam1 := PsKernelExpr.lam n ty x PsKernelBinderInfo.default
  let lam2 := PsKernelExpr.lam n ty
    (PsKernelExpr.lam n ty y PsKernelBinderInfo.implicit)
    PsKernelBinderInfo.default
  let lam3 := PsKernelExpr.lam n ty
    (PsKernelExpr.lam n ty
      (PsKernelExpr.lam n ty z PsKernelBinderInfo.default)
      PsKernelBinderInfo.implicit)
    PsKernelBinderInfo.default
  let blocked := PsKernelExpr.lam n ty
    (PsKernelExpr.app x y) PsKernelBinderInfo.default
  c0CheckCase "one argument" lam1 [z]
  c0CheckCase "two arguments" lam2 [z,y]
  c0CheckCase "three arguments" lam3 [z,y,x]
  c0CheckCase "partial application" lam3 [z]
  c0CheckCase "more arguments" lam1 [z,y,x]
  c0CheckCase "stops on nonlambda body" blocked [y,z]
  c0CheckCase "no beta arguments" lam1 []
  c0CheckCase "stuck function" ty [z,y]
  let nested :=
    PsKernelExpr.lam n ty
      (PsKernelExpr.app y x) PsKernelBinderInfo.default
  let letTerm := PsKernelExpr.letE n ty y nested false
  let projected := PsKernelExpr.proj n 0
    (PsKernelExpr.mdata 7 letTerm)
  c0CheckSubstitution "bound-var" x [z] 0
  c0CheckSubstitution "outer-var" z [y] 0
  c0CheckSubstitution "binder" nested [z,x] 0
  c0CheckSubstitution "let" letTerm [x,y] 0
  c0CheckSubstitution "metadata/projection" projected [y,z] 0
  c0CheckSubstitution "scoped offset" projected [y,z] 2
  c0CheckSubstitution "empty substitutions" projected [] 0
  IO.println "PSKernel-C0 beta and structural substitution differential cases: PASS"
