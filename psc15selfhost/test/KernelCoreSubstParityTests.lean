import Ps.KernelCore.Subst
import PSC1Kernel.Instantiate

def psKernelCoreObservedBVar (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.bvar index => index
  | _ => 9999

def psReferenceObservedBVar (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.bvar index => index
  | _ => 9999

def psKernelCoreObservedLamForall (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.lam _ type body _ =>
      match body with
      | PsKernelCoreExpr.forallE _ domain range _ =>
          Nat.add
            (Nat.mul 100 (psKernelCoreObservedBVar type))
            (Nat.add
              (Nat.mul 10 (psKernelCoreObservedBVar domain))
              (psKernelCoreObservedBVar range))
      | _ => 9999
  | _ => 9999

def psReferenceObservedLamForall (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.lam _ type body _ =>
      match body with
      | PSC1Kernel.Expr.forallE _ domain range _ =>
          Nat.add
            (Nat.mul 100 (psReferenceObservedBVar type))
            (Nat.add
              (Nat.mul 10 (psReferenceObservedBVar domain))
              (psReferenceObservedBVar range))
      | _ => 9999
  | _ => 9999

def psKernelCoreObservedLet (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.letE _ type value body _ =>
      Nat.add
        (Nat.mul 100 (psKernelCoreObservedBVar type))
        (Nat.add
          (Nat.mul 10 (psKernelCoreObservedBVar value))
          (psKernelCoreObservedBVar body))
  | _ => 9999

def psReferenceObservedLet (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.letE _ type value body _ =>
      Nat.add
        (Nat.mul 100 (psReferenceObservedBVar type))
        (Nat.add
          (Nat.mul 10 (psReferenceObservedBVar value))
          (psReferenceObservedBVar body))
  | _ => 9999

def psKernelCoreObservedWrapped (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.mdata _ child =>
      match child with
      | PsKernelCoreExpr.proj _ _ value => psKernelCoreObservedBVar value
      | _ => 9999
  | _ => 9999

def psReferenceObservedWrapped (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.mdata _ child =>
      match child with
      | PSC1Kernel.Expr.proj _ _ value => psReferenceObservedBVar value
      | _ => 9999
  | _ => 9999

def psKernelCoreObservedLamBody (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.lam _ _ body _ => psKernelCoreObservedBVar body
  | _ => 9999

def psReferenceObservedLamBody (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.lam _ _ body _ => psReferenceObservedBVar body
  | _ => 9999

def psKernelCoreObservedNatLiteral (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.lit literal =>
      match literal with
      | PsKernelCoreLiteral.nat value => value
      | _ => 9999
  | _ => 9999

def psReferenceObservedNatLiteral (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.lit literal =>
      match literal with
      | PSC1Kernel.Literal.nat value => value
      | _ => 9999
  | _ => 9999

def psKernelCoreObservedNatApp (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.app fn arg =>
      Nat.add
        (Nat.mul 100 (psKernelCoreObservedNatLiteral fn))
        (psKernelCoreObservedNatLiteral arg)
  | _ => 9999

def psReferenceObservedNatApp (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.app fn arg =>
      Nat.add
        (Nat.mul 100 (psReferenceObservedNatLiteral fn))
        (psReferenceObservedNatLiteral arg)
  | _ => 9999

def psKernelCoreExprKind (expr : PsKernelCoreExpr) : Nat :=
  match expr with
  | PsKernelCoreExpr.fvar _ => 1
  | _ => 0

def psReferenceExprKind (expr : PSC1Kernel.Expr) : Nat :=
  match expr with
  | PSC1Kernel.Expr.fvar _ => 1
  | _ => 0

def psKernelCoreSubstParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcX := PsKernelCoreName.str kcAnon "x"
  let kcZero := PsKernelCoreLevel.zero
  let refAnon := PSC1Kernel.Name.anonymous
  let refX := PSC1Kernel.Name.str refAnon "x"
  let refZero := PSC1Kernel.Level.zero

  let kcLiftBelow :=
    psKernelCoreExprLiftBVars (PsKernelCoreExpr.bvar 0) 1 2
  let refLiftBelow :=
    PSC1Kernel.Expr.liftLooseBVars (PSC1Kernel.Expr.bvar 0) 1 2

  let kcLiftAt :=
    psKernelCoreExprLiftBVars (PsKernelCoreExpr.bvar 1) 1 2
  let refLiftAt :=
    PSC1Kernel.Expr.liftLooseBVars (PSC1Kernel.Expr.bvar 1) 1 2

  let kcNested :=
    PsKernelCoreExpr.lam
      kcX
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE
        kcX
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.bvar 2)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
  let refNested :=
    PSC1Kernel.Expr.lam
      refX
      (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.forallE
        refX
        (PSC1Kernel.Expr.bvar 1)
        (PSC1Kernel.Expr.bvar 2)
        PSC1Kernel.BinderInfo.default)
      PSC1Kernel.BinderInfo.default

  let kcLet :=
    PsKernelCoreExpr.letE
      kcX
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.bvar 1)
      (PsKernelCoreExpr.bvar 1)
      true
  let refLet :=
    PSC1Kernel.Expr.letE
      refX
      (PSC1Kernel.Expr.bvar 0)
      (PSC1Kernel.Expr.bvar 1)
      (PSC1Kernel.Expr.bvar 1)
      true

  let kcWrapped :=
    PsKernelCoreExpr.mdata
      5
      (PsKernelCoreExpr.proj kcX 0 (PsKernelCoreExpr.bvar 1))
  let refWrapped :=
    PSC1Kernel.Expr.mdata
      5
      (PSC1Kernel.Expr.proj refX 0 (PSC1Kernel.Expr.bvar 1))

  let kcReplacement := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 42)
  let refReplacement := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 42)

  let kcUnderBinder :=
    PsKernelCoreExpr.lam
      kcX
      (PsKernelCoreExpr.sort kcZero)
      (PsKernelCoreExpr.bvar 1)
      PsKernelCoreBinderInfo.default
  let refUnderBinder :=
    PSC1Kernel.Expr.lam
      refX
      (PSC1Kernel.Expr.sort refZero)
      (PSC1Kernel.Expr.bvar 1)
      PSC1Kernel.BinderInfo.default

  let kcArgA := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 7)
  let kcArgB := PsKernelCoreExpr.lit (PsKernelCoreLiteral.nat 9)
  let kcRevSubst :=
    PsKernelCoreList.cons kcArgA
      (PsKernelCoreList.cons kcArgB PsKernelCoreList.nil)
  let refArgA := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 7)
  let refArgB := PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 9)
  let kcMultiBody :=
    PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) (PsKernelCoreExpr.bvar 0)
  let refMultiBody :=
    PSC1Kernel.Expr.app (PSC1Kernel.Expr.bvar 1) (PSC1Kernel.Expr.bvar 0)

  let kcUnaffected := PsKernelCoreExpr.fvar kcX
  let refUnaffected := PSC1Kernel.Expr.fvar refX

  (psKernelCoreObservedBVar kcLiftBelow == psReferenceObservedBVar refLiftBelow) &&
  (psKernelCoreObservedBVar kcLiftAt == psReferenceObservedBVar refLiftAt) &&
  (psKernelCoreObservedLamForall
      (psKernelCoreExprLiftBVars kcNested 0 1) ==
    psReferenceObservedLamForall
      (PSC1Kernel.Expr.liftLooseBVars refNested 0 1)) &&
  (psKernelCoreObservedLet
      (psKernelCoreExprLiftBVars kcLet 0 1) ==
    psReferenceObservedLet
      (PSC1Kernel.Expr.liftLooseBVars refLet 0 1)) &&
  (psKernelCoreObservedWrapped
      (psKernelCoreExprLiftBVars kcWrapped 0 2) ==
    psReferenceObservedWrapped
      (PSC1Kernel.Expr.liftLooseBVars refWrapped 0 2)) &&
  (psKernelCoreObservedNatLiteral
      (psKernelCoreExprInstantiate1 (PsKernelCoreExpr.bvar 0) kcReplacement) ==
    psReferenceObservedNatLiteral
      (PSC1Kernel.Expr.instantiate1 (PSC1Kernel.Expr.bvar 0) refReplacement)) &&
  (psKernelCoreObservedLamBody
      (psKernelCoreExprInstantiate1 kcUnderBinder (PsKernelCoreExpr.bvar 0)) ==
    psReferenceObservedLamBody
      (PSC1Kernel.Expr.instantiate1 refUnderBinder (PSC1Kernel.Expr.bvar 0))) &&
  (psKernelCoreObservedNatApp
      (psKernelCoreExprInstantiateRev kcMultiBody kcRevSubst) ==
    psReferenceObservedNatApp
      (PSC1Kernel.Expr.instantiateRev refMultiBody [refArgA, refArgB])) &&
  (psKernelCoreExprKind
      (psKernelCoreExprInstantiate1 kcUnaffected kcReplacement) ==
    psReferenceExprKind
      (PSC1Kernel.Expr.instantiate1 refUnaffected refReplacement))

def main : IO Unit := do
  if psKernelCoreSubstParity then
    IO.println "PSC2_KERNEL_CORE_SUBST_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_SUBST_PARITY: FAIL")
