import Ps.KernelCore.LocalContext
import PSC1Kernel.LocalContext

def psKernelCoreLocalBinderTag (value : PsKernelCoreBinderInfo) : Nat :=
  match value with
  | PsKernelCoreBinderInfo.default => 0
  | PsKernelCoreBinderInfo.implicit => 1
  | PsKernelCoreBinderInfo.strictImplicit => 2
  | PsKernelCoreBinderInfo.instImplicit => 3

def psReferenceLocalBinderTag (value : PSC1Kernel.BinderInfo) : Nat :=
  match value with
  | PSC1Kernel.BinderInfo.default => 0
  | PSC1Kernel.BinderInfo.implicit => 1
  | PSC1Kernel.BinderInfo.strictImplicit => 2
  | PSC1Kernel.BinderInfo.instImplicit => 3

def psKernelCoreLocalDeclIndex (decl : PsKernelCoreLocalDecl) : Nat :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl index _ _ _ _ => index
  | PsKernelCoreLocalDecl.letDecl index _ _ _ _ => index

def psReferenceLocalDeclIndex (decl : PSC1Kernel.LocalDecl) : Nat :=
  match decl with
  | PSC1Kernel.LocalDecl.localDecl index _ _ _ _ => index
  | PSC1Kernel.LocalDecl.letDecl index _ _ _ _ => index

def psKernelCoreLocalDeclKind (decl : PsKernelCoreLocalDecl) : Nat :=
  match decl with
  | PsKernelCoreLocalDecl.localDecl _ _ _ _ _ => 0
  | PsKernelCoreLocalDecl.letDecl _ _ _ _ _ => 1

def psReferenceLocalDeclKind (decl : PSC1Kernel.LocalDecl) : Nat :=
  match decl with
  | PSC1Kernel.LocalDecl.localDecl _ _ _ _ _ => 0
  | PSC1Kernel.LocalDecl.letDecl _ _ _ _ _ => 1

def psKernelCoreLocalOptionKind
    (value : PsKernelCoreOption PsKernelCoreLocalDecl) : Nat :=
  match value with
  | PsKernelCoreOption.none => 0
  | PsKernelCoreOption.some decl => Nat.succ (psKernelCoreLocalDeclKind decl)

def psReferenceLocalOptionKind
    (value : Option PSC1Kernel.LocalDecl) : Nat :=
  match value with
  | none => 0
  | some decl => Nat.succ (psReferenceLocalDeclKind decl)

def psKernelCoreLocalExprOptionTag
    (value : PsKernelCoreOption PsKernelCoreExpr) : Nat :=
  match value with
  | PsKernelCoreOption.none => 0
  | PsKernelCoreOption.some _ => 1

def psReferenceLocalExprOptionTag
    (value : Option PSC1Kernel.Expr) : Nat :=
  match value with
  | none => 0
  | some _ => 1

def psKernelCoreLocalFoundIndex
    (value : PsKernelCoreOption PsKernelCoreLocalDecl) : Nat :=
  match value with
  | PsKernelCoreOption.none => 99
  | PsKernelCoreOption.some decl => psKernelCoreLocalDeclIndex decl

def psReferenceLocalFoundIndex
    (value : Option PSC1Kernel.LocalDecl) : Nat :=
  match value with
  | none => 99
  | some decl => psReferenceLocalDeclIndex decl

def psKernelCoreLocalContextParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcName := PsKernelCoreName.str kcAnon "x"
  let kcUser := PsKernelCoreName.str kcAnon "userX"
  let kcOther := PsKernelCoreName.str kcAnon "y"
  let kcType := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let kcValue := PsKernelCoreExpr.bvar 0
  let kcEmpty := psKernelCoreLocalContextEmpty
  let kcOne :=
    psKernelCoreLocalContextAddLocal
      kcEmpty kcName kcUser kcType PsKernelCoreBinderInfo.implicit
  let kcTwo :=
    psKernelCoreLocalContextAddLet kcOne kcOther kcOther kcType kcValue
  let kcShadow :=
    psKernelCoreLocalContextAddLet kcTwo kcName kcName kcType kcValue

  let refAnon := PSC1Kernel.Name.anonymous
  let refName := PSC1Kernel.Name.str refAnon "x"
  let refUser := PSC1Kernel.Name.str refAnon "userX"
  let refOther := PSC1Kernel.Name.str refAnon "y"
  let refType := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
  let refValue := PSC1Kernel.Expr.bvar 0
  let refEmpty := PSC1Kernel.LocalContext.empty
  let refOne :=
    PSC1Kernel.LocalContext.addLocal
      refEmpty refName refUser refType PSC1Kernel.BinderInfo.implicit
  let refTwo :=
    PSC1Kernel.LocalContext.addLet refOne refOther refOther refType refValue
  let refShadow :=
    PSC1Kernel.LocalContext.addLet refTwo refName refName refType refValue

  let kcFoundLocal := psKernelCoreLocalContextFind? kcOne kcName
  let kcFoundLet := psKernelCoreLocalContextFind? kcTwo kcOther
  let kcFoundShadow := psKernelCoreLocalContextFind? kcShadow kcName
  let refFoundLocal := PSC1Kernel.LocalContext.find? refOne refName
  let refFoundLet := PSC1Kernel.LocalContext.find? refTwo refOther
  let refFoundShadow := PSC1Kernel.LocalContext.find? refShadow refName

  (kcEmpty.nextIndex == refEmpty.nextIndex) &&
  (kcOne.nextIndex == refOne.nextIndex) &&
  (kcTwo.nextIndex == refTwo.nextIndex) &&
  (kcShadow.nextIndex == refShadow.nextIndex) &&
  (psKernelCoreLocalOptionKind
      (psKernelCoreLocalContextFind? kcEmpty kcName) ==
    psReferenceLocalOptionKind
      (PSC1Kernel.LocalContext.find? refEmpty refName)) &&
  (psKernelCoreLocalOptionKind kcFoundLocal ==
    psReferenceLocalOptionKind refFoundLocal) &&
  (psKernelCoreLocalOptionKind kcFoundLet ==
    psReferenceLocalOptionKind refFoundLet) &&
  (psKernelCoreLocalOptionKind kcFoundShadow ==
    psReferenceLocalOptionKind refFoundShadow) &&
  (psKernelCoreLocalFoundIndex kcFoundLocal ==
    psReferenceLocalFoundIndex refFoundLocal) &&
  (psKernelCoreLocalFoundIndex kcFoundLet ==
    psReferenceLocalFoundIndex refFoundLet) &&
  (psKernelCoreLocalFoundIndex kcFoundShadow ==
    psReferenceLocalFoundIndex refFoundShadow) &&
  (psKernelCoreLocalFoundIndex kcFoundShadow == 2) &&
  match kcFoundLocal with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some kcDecl =>
      match refFoundLocal with
      | none => false
      | some refDecl =>
          psKernelCoreNameEq
              (psKernelCoreLocalDeclName kcDecl)
              kcName &&
          PSC1Kernel.Name.eq
              (PSC1Kernel.LocalDecl.name refDecl)
              refName &&
          psKernelCoreNameEq
              (psKernelCoreLocalDeclUserName kcDecl)
              kcUser &&
          PSC1Kernel.Name.eq
              (PSC1Kernel.LocalDecl.userName refDecl)
              refUser &&
          (psKernelCoreLocalBinderTag
              (psKernelCoreLocalDeclBinderInfo kcDecl) ==
            psReferenceLocalBinderTag
              (PSC1Kernel.LocalDecl.binderInfo refDecl)) &&
          (psKernelCoreLocalExprOptionTag
              (psKernelCoreLocalDeclValue? kcDecl) ==
            psReferenceLocalExprOptionTag
              (PSC1Kernel.LocalDecl.value? refDecl)) &&
          match kcFoundLet with
          | PsKernelCoreOption.none => false
          | PsKernelCoreOption.some kcLetDecl =>
              match refFoundLet with
              | none => false
              | some refLetDecl =>
                  (psKernelCoreLocalBinderTag
                      (psKernelCoreLocalDeclBinderInfo kcLetDecl) ==
                    psReferenceLocalBinderTag
                      (PSC1Kernel.LocalDecl.binderInfo refLetDecl)) &&
                  (psKernelCoreLocalExprOptionTag
                      (psKernelCoreLocalDeclValue? kcLetDecl) ==
                    psReferenceLocalExprOptionTag
                      (PSC1Kernel.LocalDecl.value? refLetDecl))

def main : IO Unit := do
  if psKernelCoreLocalContextParity then
    IO.println "PSC2_KERNEL_CORE_LOCAL_CONTEXT_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_LOCAL_CONTEXT_PARITY: FAIL")
