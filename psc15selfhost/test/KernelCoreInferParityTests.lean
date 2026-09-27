import Ps.KernelCore.Subst

partial def psKernelCoreInferTestLevelListEq
    (left right : PsKernelCoreList PsKernelCoreLevel) : Bool :=
  match left, right with
  | PsKernelCoreList.nil, PsKernelCoreList.nil => true
  | PsKernelCoreList.cons lh lt, PsKernelCoreList.cons rh rt =>
      psKernelCoreLevelEq lh rh && psKernelCoreInferTestLevelListEq lt rt
  | _, _ => false

def psKernelCoreInferTestBinderEq
    (left right : PsKernelCoreBinderInfo) : Bool :=
  match left, right with
  | PsKernelCoreBinderInfo.default, PsKernelCoreBinderInfo.default => true
  | PsKernelCoreBinderInfo.implicit, PsKernelCoreBinderInfo.implicit => true
  | PsKernelCoreBinderInfo.strictImplicit, PsKernelCoreBinderInfo.strictImplicit => true
  | PsKernelCoreBinderInfo.instImplicit, PsKernelCoreBinderInfo.instImplicit => true
  | _, _ => false

def psKernelCoreInferTestLiteralEq
    (left right : PsKernelCoreLiteral) : Bool :=
  match left, right with
  | PsKernelCoreLiteral.nat l, PsKernelCoreLiteral.nat r => l == r
  | PsKernelCoreLiteral.str l, PsKernelCoreLiteral.str r => l == r
  | _, _ => false

partial def psKernelCoreInferTestExprEq
    (left right : PsKernelCoreExpr) : Bool :=
  match left, right with
  | PsKernelCoreExpr.bvar l, PsKernelCoreExpr.bvar r => l == r
  | PsKernelCoreExpr.fvar l, PsKernelCoreExpr.fvar r => psKernelCoreNameEq l r
  | PsKernelCoreExpr.mvar l, PsKernelCoreExpr.mvar r => psKernelCoreNameEq l r
  | PsKernelCoreExpr.sort l, PsKernelCoreExpr.sort r => psKernelCoreLevelEq l r
  | PsKernelCoreExpr.const ln ll, PsKernelCoreExpr.const rn rl =>
      psKernelCoreNameEq ln rn && psKernelCoreInferTestLevelListEq ll rl
  | PsKernelCoreExpr.app lf la, PsKernelCoreExpr.app rf ra =>
      psKernelCoreInferTestExprEq lf rf && psKernelCoreInferTestExprEq la ra
  | PsKernelCoreExpr.lam ln lt lb li, PsKernelCoreExpr.lam rn rt rb ri =>
      psKernelCoreNameEq ln rn &&
        psKernelCoreInferTestExprEq lt rt &&
        psKernelCoreInferTestExprEq lb rb &&
        psKernelCoreInferTestBinderEq li ri
  | PsKernelCoreExpr.forallE ln lt lb li, PsKernelCoreExpr.forallE rn rt rb ri =>
      psKernelCoreNameEq ln rn &&
        psKernelCoreInferTestExprEq lt rt &&
        psKernelCoreInferTestExprEq lb rb &&
        psKernelCoreInferTestBinderEq li ri
  | PsKernelCoreExpr.letE ln lt lv lb lnd,
      PsKernelCoreExpr.letE rn rt rv rb rnd =>
      psKernelCoreNameEq ln rn &&
        psKernelCoreInferTestExprEq lt rt &&
        psKernelCoreInferTestExprEq lv rv &&
        psKernelCoreInferTestExprEq lb rb &&
        lnd == rnd
  | PsKernelCoreExpr.lit l, PsKernelCoreExpr.lit r =>
      psKernelCoreInferTestLiteralEq l r
  | PsKernelCoreExpr.mdata lm le, PsKernelCoreExpr.mdata rm re =>
      lm == rm && psKernelCoreInferTestExprEq le re
  | PsKernelCoreExpr.proj ln li le, PsKernelCoreExpr.proj rn ri re =>
      psKernelCoreNameEq ln rn && li == ri && psKernelCoreInferTestExprEq le re
  | _, _ => false

def psKernelCoreInferTestName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psKernelCoreInferBinderContracts : Bool :=
  let x := psKernelCoreInferTestName "x"
  let y := psKernelCoreInferTestName "y"
  let t := psKernelCoreInferTestName "T"
  let zero := PsKernelCoreLevel.zero
  let xVar := PsKernelCoreExpr.fvar x
  let yVar := PsKernelCoreExpr.fvar y
  let leaf := PsKernelCoreExpr.sort zero
  let recursiveSurface :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.lam
        y
        (PsKernelCoreExpr.app xVar leaf)
        (PsKernelCoreExpr.forallE
          y
          (PsKernelCoreExpr.mdata 7 xVar)
          (PsKernelCoreExpr.letE
            y
            xVar
            (PsKernelCoreExpr.proj t 2 xVar)
            (PsKernelCoreExpr.app yVar xVar)
            false)
          PsKernelCoreBinderInfo.implicit)
        PsKernelCoreBinderInfo.default)
      (PsKernelCoreExpr.const t PsKernelCoreList.nil)
  let nested :=
    PsKernelCoreExpr.lam
      y
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE
        y
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.letE
          y
          (PsKernelCoreExpr.bvar 0)
          xVar
          (PsKernelCoreExpr.app xVar (PsKernelCoreExpr.bvar 2))
          true)
        PsKernelCoreBinderInfo.strictImplicit)
      PsKernelCoreBinderInfo.instImplicit
  let closedAbsent :=
    PsKernelCoreExpr.mdata 9
      (PsKernelCoreExpr.app yVar (PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 3)))
  let abstractedNested := psKernelCoreExprAbstractFVar nested x
  let roundTrip :=
    psKernelCoreExprInstantiate1 abstractedNested (PsKernelCoreExpr.fvar x)
  let shiftedTop :=
    psKernelCoreExprAbstractFVar (PsKernelCoreExpr.bvar 0) x
  let shiftedUnder :=
    psKernelCoreExprAbstractFVar
      (PsKernelCoreExpr.lam
        y leaf (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
      x
  psKernelCoreExprHasFVarName recursiveSurface x &&
  (!psKernelCoreExprHasFVarName recursiveSurface (psKernelCoreInferTestName "missing")) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.bvar 0) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.sort zero) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.const t PsKernelCoreList.nil) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "s")) x) &&
  (!psKernelCoreExprHasFVarName (PsKernelCoreExpr.mvar y) x) &&
  psKernelCoreInferTestExprEq
    (psKernelCoreExprAbstractFVar xVar x)
    (PsKernelCoreExpr.bvar 0) &&
  psKernelCoreInferTestExprEq
    (psKernelCoreExprAbstractFVar yVar x)
    yVar &&
  psKernelCoreInferTestExprEq roundTrip nested &&
  psKernelCoreInferTestExprEq shiftedTop (PsKernelCoreExpr.bvar 1) &&
  psKernelCoreInferTestExprEq shiftedUnder
    (PsKernelCoreExpr.lam
      y leaf (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default) &&
  psKernelCoreInferTestExprEq
    (psKernelCoreExprAbstractFVar closedAbsent x)
    closedAbsent

def main : IO Unit := do
  if psKernelCoreInferBinderContracts then
    IO.println "PSC2_KERNEL_CORE_INFER_BINDERS: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_INFER_BINDERS: FAIL")
