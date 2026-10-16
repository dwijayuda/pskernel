import Ps.Environment.StandardArray

/-!
Lean 4.35.0, Init/Data/Array/Basic.lean: Array.filter is a bounded left
fold into an initially empty persistent array. This checked model preserves
the native telescope (including dependent defaults) and element universe.
Runtime lowering uses one typed intrinsic, avoiding repeated persistent push.
Algorithm reference: Lean project, Apache-2.0; independently authored Core builder.
-/
def psStandardArrayFilterDeclaration : PsDeclaration :=
  let u := PsLevel.param (psRootName "u")
  let alpha := PsExpr.fvar 0
  let predicate := PsExpr.fvar 1
  let xs := PsExpr.fvar 2
  let start := PsExpr.fvar 3
  let stop := PsExpr.fvar 4
  let acc := PsExpr.fvar 5
  let value := PsExpr.fvar 6
  let bool := PsExpr.constE psBoolName []
  let array := psPreludeArrayOf alpha u
  let predicateType := psLogicPi 6 "value" alpha bool
  let zero := psLogicApply (.constE (psDecisionName "OfNat.ofNat") [.zero])
    [psOrderNat, .lit (.natural 0), .app (.constE (psDecisionName "instOfNatNat") []) (.lit (.natural 0))]
  let optional := fun defaultValue =>
    psLogicApply (.constE psOptParamName [.succ .zero]) [psOrderNat, defaultValue]
  let startType := optional zero
  let stopType := optional (psStandardArraySize alpha xs u)
  let type := psLogicPi 0 "α" (.sortE (.succ u))
    (psLogicPi 1 "p" predicateType (psLogicPi 2 "as" array
      (psLogicPi 3 "start" startType (psLogicPi 4 "stop" stopType array)))) .implicit
  let step := psLogicLam 5 "acc" array (psLogicLam 6 "a" alpha
    (psLogicApply (.constE (psNameAppendStr psBoolName "rec") [.succ u])
      [psLogicLam 7 "_" bool array, acc,
       psStandardArrayCall "push" [alpha, acc, value] [u], .app predicate value]))
  let body := psStandardArrayCall "foldl"
    [alpha, array, step, psStandardArrayCall "emptyWithCapacity" [alpha, .lit (.natural 0)] [u],
     xs, start, stop] [u, u]
  let value := psLogicLam 0 "α" (.sortE (.succ u))
    (psLogicLam 1 "p" predicateType (psLogicLam 2 "as" array
      (psLogicLam 3 "start" startType (psLogicLam 4 "stop" stopType body)))) .implicit
  .definitionDecl (psDecisionName "Array.filter") [psRootName "u"] type value

def psStandardArrayFilterExtend (environment : PsEnvironment) : PsEnvironment :=
  psPreludeAdd environment psStandardArrayFilterDeclaration
