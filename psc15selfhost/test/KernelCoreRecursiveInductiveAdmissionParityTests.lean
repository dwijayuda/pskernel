import Ps.KernelCore.RecursiveInductive
import PSC1Kernel.Inductive

def psP11AdmAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP11AdmSort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP11AdmSmallSort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP11KcName (base : String) : PsKernelCoreName :=
  PsKernelCoreName.str psP11AdmAnon base

def psP11KcCtorName (family : PsKernelCoreName) (base : String) : PsKernelCoreName :=
  PsKernelCoreName.str family base

def psP11KcBase
    (name : PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreConstantBase := {
  name := name
  levelParams := PsKernelCoreList.nil
  type := type
}

def psP11KcCtor
    (family : PsKernelCoreName)
    (name : PsKernelCoreName)
    (index : Nat)
    (fields : Nat)
    (type : PsKernelCoreExpr) : PsKernelCoreConstructorInfo := {
  base := psP11KcBase name type
  induct := family
  cidx := index
  numParams := 0
  numFields := fields
  isUnsafe := false
}

def psP11KcInfo
    (family : PsKernelCoreName)
    (ctors : PsKernelCoreList PsKernelCoreName)
    (numIndices : Nat)
    (type : PsKernelCoreExpr) : PsKernelCoreInductiveInfo := {
  base := psP11KcBase family type
  numParams := 0
  numIndices := numIndices
  all := PsKernelCoreList.cons family PsKernelCoreList.nil
  ctors := ctors
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP11KcFamilyFlags
    (env : PsKernelCoreEnvironment)
    (family : PsKernelCoreName)
    (expectRec : Bool)
    (expectReflexive : Bool) : Bool :=
  match psKernelCoreEnvironmentFind? env family with
  | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo info) =>
      psKernelCoreBoolEq info.isRec expectRec &&
      psKernelCoreBoolEq info.isReflexive expectReflexive
  | _ => false

def psP11DirectKc : Bool :=
  let family := psP11KcName "P11Direct";
  let leaf := psP11KcCtorName family "leaf";
  let node := psP11KcCtorName family "node";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let nodeType :=
    PsKernelCoreExpr.forallE psP11AdmAnon target target PsKernelCoreBinderInfo.default;
  let info :=
    psP11KcInfo family
      (PsKernelCoreList.cons leaf
        (PsKernelCoreList.cons node PsKernelCoreList.nil))
      0 psP11AdmSort;
  let ctors :=
    PsKernelCoreList.cons (psP11KcCtor family leaf 0 0 target)
      (PsKernelCoreList.cons (psP11KcCtor family node 1 1 nodeType)
        PsKernelCoreList.nil);
  match psKernelCoreAddRecursiveInductive 256 psKernelCoreEnvironmentEmpty info ctors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      psP11KcFamilyFlags env family true false &&
      psKernelCoreEnvironmentContains env leaf &&
      psKernelCoreEnvironmentContains env node

def psP11TwoFieldKc : Bool :=
  let family := psP11KcName "P11PairTree";
  let node := psP11KcCtorName family "node";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let ctorType :=
    PsKernelCoreExpr.forallE psP11AdmAnon target
      (PsKernelCoreExpr.forallE psP11AdmAnon target target
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11KcInfo family (PsKernelCoreList.cons node PsKernelCoreList.nil)
      0 psP11AdmSort;
  let ctors :=
    PsKernelCoreList.cons (psP11KcCtor family node 0 2 ctorType)
      PsKernelCoreList.nil;
  match psKernelCoreAddRecursiveInductive 256 psKernelCoreEnvironmentEmpty info ctors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env => psP11KcFamilyFlags env family true false

def psP11FunctionalKc : Bool :=
  let family := psP11KcName "P11Functional";
  let node := psP11KcCtorName family "node";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let recursiveField :=
    PsKernelCoreExpr.forallE psP11AdmAnon psP11AdmSmallSort target
      PsKernelCoreBinderInfo.default;
  let ctorType :=
    PsKernelCoreExpr.forallE psP11AdmAnon recursiveField target
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11KcInfo family (PsKernelCoreList.cons node PsKernelCoreList.nil)
      0 psP11AdmSort;
  let ctors :=
    PsKernelCoreList.cons (psP11KcCtor family node 0 1 ctorType)
      PsKernelCoreList.nil;
  match psKernelCoreAddRecursiveInductive 256 psKernelCoreEnvironmentEmpty info ctors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env => psP11KcFamilyFlags env family true true

def psP11IndexedKc : Bool :=
  let family := psP11KcName "P11Indexed";
  let node := psP11KcCtorName family "node";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let familyType :=
    PsKernelCoreExpr.forallE psP11AdmAnon psP11AdmSmallSort psP11AdmSort
      PsKernelCoreBinderInfo.default;
  let targetAt0 := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 0);
  let targetAt1 := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 1);
  let ctorType :=
    PsKernelCoreExpr.forallE psP11AdmAnon psP11AdmSmallSort
      (PsKernelCoreExpr.forallE psP11AdmAnon targetAt0 targetAt1
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11KcInfo family (PsKernelCoreList.cons node PsKernelCoreList.nil)
      1 familyType;
  let ctors :=
    PsKernelCoreList.cons (psP11KcCtor family node 0 2 ctorType)
      PsKernelCoreList.nil;
  match psKernelCoreAddRecursiveInductive 384 psKernelCoreEnvironmentEmpty info ctors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env => psP11KcFamilyFlags env family true false

def psP11RefName (base : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous base

def psP11RefFamilyFlags
    (env : PSC1Kernel.Environment)
    (family : PSC1Kernel.Name)
    (expectRec : Bool)
    (expectReflexive : Bool) : Bool :=
  match env.find? family with
  | some (.inductInfo info) =>
      (info.isRec == expectRec) && (info.isReflexive == expectReflexive)
  | _ => false

def psP11DirectRef : Bool :=
  let family := psP11RefName "P11Direct";
  let leaf := PSC1Kernel.Name.str family "leaf";
  let node := PSC1Kernel.Name.str family "node";
  let target : PSC1Kernel.Expr := .const family [];
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [
      { name := leaf, type := target },
      { name := node, type := .forallE .anonymous target target .default }
    ]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env => psP11RefFamilyFlags env family true false

def psP11TwoFieldRef : Bool :=
  let family := psP11RefName "P11PairTree";
  let node := PSC1Kernel.Name.str family "node";
  let target : PSC1Kernel.Expr := .const family [];
  let ctorType : PSC1Kernel.Expr :=
    .forallE .anonymous target
      (.forallE .anonymous target target .default) .default;
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [{ name := node, type := ctorType }]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env => psP11RefFamilyFlags env family true false

def psP11FunctionalRef : Bool :=
  let family := psP11RefName "P11Functional";
  let node := PSC1Kernel.Name.str family "node";
  let target : PSC1Kernel.Expr := .const family [];
  let recursiveField : PSC1Kernel.Expr :=
    .forallE .anonymous (.sort .zero) target .default;
  let ctorType : PSC1Kernel.Expr :=
    .forallE .anonymous recursiveField target .default;
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [{ name := node, type := ctorType }]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env => psP11RefFamilyFlags env family true true

def psP11IndexedRef : Bool :=
  let family := psP11RefName "P11Indexed";
  let node := PSC1Kernel.Name.str family "node";
  let target : PSC1Kernel.Expr := .const family [];
  let familyType : PSC1Kernel.Expr :=
    .forallE .anonymous (.sort .zero) (.sort (.succ .zero)) .default;
  let targetAt0 : PSC1Kernel.Expr := .app target (.bvar 0);
  let targetAt1 : PSC1Kernel.Expr := .app target (.bvar 1);
  let ctorType : PSC1Kernel.Expr :=
    .forallE .anonymous (.sort .zero)
      (.forallE .anonymous targetAt0 targetAt1 .default) .default;
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := familyType
    ctors := [{ name := node, type := ctorType }]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env => psP11RefFamilyFlags env family true false

def psP11AdmissionParity : Bool :=
  psP11DirectKc && psP11DirectRef &&
  psP11TwoFieldKc && psP11TwoFieldRef &&
  psP11FunctionalKc && psP11FunctionalRef &&
  psP11IndexedKc && psP11IndexedRef

def main : IO Unit := do
  if psP11AdmissionParity then
    IO.println "PSC2_KERNEL_CORE_PHASE11_RECURSIVE_ADMISSION: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_PHASE11_RECURSIVE_ADMISSION: FAIL")
