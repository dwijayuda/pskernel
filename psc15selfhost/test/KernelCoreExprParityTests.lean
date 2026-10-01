import Ps.KernelCore.Expr
import PSC1Kernel.Expr

def psKernelCoreBinderTag (binder : PsKernelCoreBinderInfo) : Nat :=
  match binder with
  | PsKernelCoreBinderInfo.default => 0
  | PsKernelCoreBinderInfo.implicit => 1
  | PsKernelCoreBinderInfo.strictImplicit => 2
  | PsKernelCoreBinderInfo.instImplicit => 3

def psReferenceBinderTag (binder : PSC1Kernel.BinderInfo) : Nat :=
  match binder with
  | PSC1Kernel.BinderInfo.default => 0
  | PSC1Kernel.BinderInfo.implicit => 1
  | PSC1Kernel.BinderInfo.strictImplicit => 2
  | PSC1Kernel.BinderInfo.instImplicit => 3

def psKernelCoreLiteralTag (literal : PsKernelCoreLiteral) : Nat :=
  match literal with
  | PsKernelCoreLiteral.nat value => Nat.add 10 value
  | PsKernelCoreLiteral.str value => Nat.add 20 (String.Internal.length value)

def psReferenceLiteralTag (literal : PSC1Kernel.Literal) : Nat :=
  match literal with
  | PSC1Kernel.Literal.nat value => Nat.add 10 value
  | PSC1Kernel.Literal.str value => Nat.add 20 (String.Internal.length value)

def psKernelCoreExprTag (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.bvar _ => 0
  | PsKernelCoreExpr.fvar _ => 1
  | PsKernelCoreExpr.mvar _ => 2
  | PsKernelCoreExpr.sort _ => 3
  | PsKernelCoreExpr.const _ _ => 4
  | PsKernelCoreExpr.app _ _ => 5
  | PsKernelCoreExpr.lam _ _ _ _ => 6
  | PsKernelCoreExpr.forallE _ _ _ _ => 7
  | PsKernelCoreExpr.letE _ _ _ _ _ => 8
  | PsKernelCoreExpr.lit _ => 9
  | PsKernelCoreExpr.mdata _ _ => 10
  | PsKernelCoreExpr.proj _ _ _ => 11

def psReferenceExprTag (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.bvar _ => 0
  | PSC1Kernel.Expr.fvar _ => 1
  | PSC1Kernel.Expr.mvar _ => 2
  | PSC1Kernel.Expr.sort _ => 3
  | PSC1Kernel.Expr.const _ _ => 4
  | PSC1Kernel.Expr.app _ _ => 5
  | PSC1Kernel.Expr.lam _ _ _ _ => 6
  | PSC1Kernel.Expr.forallE _ _ _ _ => 7
  | PSC1Kernel.Expr.letE _ _ _ _ _ => 8
  | PSC1Kernel.Expr.lit _ => 9
  | PSC1Kernel.Expr.mdata _ _ => 10
  | PSC1Kernel.Expr.proj _ _ _ => 11

def psKernelCoreExprParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcX := PsKernelCoreName.str kcAnon "x"
  let kcU := PsKernelCoreName.str kcAnon "u"
  let kcZero := PsKernelCoreLevel.zero
  let kcUParam := PsKernelCoreLevel.param kcU
  let kcLevels :=
    PsKernelCoreList.cons kcUParam PsKernelCoreList.nil
  let kcBvar := PsKernelCoreExpr.bvar 2
  let kcFvar := PsKernelCoreExpr.fvar kcX
  let kcMvar := PsKernelCoreExpr.mvar kcX
  let kcSort := PsKernelCoreExpr.sort kcUParam
  let kcConst := PsKernelCoreExpr.const kcX kcLevels
  let kcApp := PsKernelCoreExpr.app kcConst kcBvar
  let kcLam :=
    PsKernelCoreExpr.lam kcX kcSort kcBvar PsKernelCoreBinderInfo.default
  let kcForall :=
    PsKernelCoreExpr.forallE kcX kcSort kcBvar PsKernelCoreBinderInfo.implicit
  let kcLet :=
    PsKernelCoreExpr.letE kcX kcSort kcBvar kcBvar true
  let kcNatLit := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7)
  let kcStrLit := PsKernelCoreExpr.lit (PsKernelCoreLiteral.str "ps")
  let kcMData := PsKernelCoreExpr.mdata 9 kcBvar
  let kcProj := PsKernelCoreExpr.proj kcX 1 kcBvar
  let refAnon := PSC1Kernel.Name.anonymous
  let refX := PSC1Kernel.Name.str refAnon "x"
  let refU := PSC1Kernel.Name.str refAnon "u"
  let refUParam := PSC1Kernel.Level.param refU
  let refBvar := PSC1Kernel.Expr.bvar 2
  let refFvar := PSC1Kernel.Expr.fvar refX
  let refMvar := PSC1Kernel.Expr.mvar refX
  let refSort := PSC1Kernel.Expr.sort refUParam
  let refConst := PSC1Kernel.Expr.const refX [refUParam]
  let refApp := PSC1Kernel.Expr.app refConst refBvar
  let refLam :=
    PSC1Kernel.Expr.lam refX refSort refBvar PSC1Kernel.BinderInfo.default
  let refForall :=
    PSC1Kernel.Expr.forallE refX refSort refBvar PSC1Kernel.BinderInfo.implicit
  let refLet :=
    PSC1Kernel.Expr.letE refX refSort refBvar refBvar true
  let refNatLit := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)
  let refStrLit := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.str "ps")
  let refMData := PSC1Kernel.Expr.mdata 9 refBvar
  let refProj := PSC1Kernel.Expr.proj refX 1 refBvar
  (psKernelCoreBinderTag PsKernelCoreBinderInfo.default ==
    psReferenceBinderTag PSC1Kernel.BinderInfo.default) &&
  (psKernelCoreBinderTag PsKernelCoreBinderInfo.implicit ==
    psReferenceBinderTag PSC1Kernel.BinderInfo.implicit) &&
  (psKernelCoreBinderTag PsKernelCoreBinderInfo.strictImplicit ==
    psReferenceBinderTag PSC1Kernel.BinderInfo.strictImplicit) &&
  (psKernelCoreBinderTag PsKernelCoreBinderInfo.instImplicit ==
    psReferenceBinderTag PSC1Kernel.BinderInfo.instImplicit) &&
  (psKernelCoreLiteralTag (PsKernelCoreLiteral.nat 7) ==
    psReferenceLiteralTag (PSC1Kernel.Literal.nat 7)) &&
  (psKernelCoreLiteralTag (PsKernelCoreLiteral.str "ps") ==
    psReferenceLiteralTag (PSC1Kernel.Literal.str "ps")) &&
  (psKernelCoreExprTag kcBvar == psReferenceExprTag refBvar) &&
  (psKernelCoreExprTag kcFvar == psReferenceExprTag refFvar) &&
  (psKernelCoreExprTag kcMvar == psReferenceExprTag refMvar) &&
  (psKernelCoreExprTag kcSort == psReferenceExprTag refSort) &&
  (psKernelCoreExprTag kcConst == psReferenceExprTag refConst) &&
  (psKernelCoreExprTag kcApp == psReferenceExprTag refApp) &&
  (psKernelCoreExprTag kcLam == psReferenceExprTag refLam) &&
  (psKernelCoreExprTag kcForall == psReferenceExprTag refForall) &&
  (psKernelCoreExprTag kcLet == psReferenceExprTag refLet) &&
  (psKernelCoreExprTag kcNatLit == psReferenceExprTag refNatLit) &&
  (psKernelCoreExprTag kcStrLit == psReferenceExprTag refStrLit) &&
  (psKernelCoreExprTag kcMData == psReferenceExprTag refMData) &&
  (psKernelCoreExprTag kcProj == psReferenceExprTag refProj) &&
  (psKernelCoreLevelEq kcZero PsKernelCoreLevel.zero)

def main : IO Unit := do
  if psKernelCoreExprParity then
    IO.println "PSC2_KERNEL_CORE_EXPR_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_EXPR_PARITY: FAIL")
