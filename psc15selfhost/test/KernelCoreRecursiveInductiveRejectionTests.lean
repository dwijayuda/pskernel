import Ps.KernelCore.RecursiveInductive
import PSC1Kernel.Inductive

def psP11RejAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP11RejSort0 : PsKernelCoreExpr := PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP11RejSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP11RejName (base : String) : PsKernelCoreName :=
  PsKernelCoreName.str psP11RejAnon base

def psP11RejCtorName (family : PsKernelCoreName) : PsKernelCoreName :=
  PsKernelCoreName.str family "mk"

def psP11RejBase
    (name : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreConstantBase := {
  name := name
  levelParams := levels
  type := type
}

def psP11RejInfo
    (family : PsKernelCoreName)
    (ctor : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (numParams : Nat)
    (numIndices : Nat)
    (type : PsKernelCoreExpr) : PsKernelCoreInductiveInfo := {
  base := psP11RejBase family levelParams type
  numParams := numParams
  numIndices := numIndices
  all := PsKernelCoreList.cons family PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons ctor PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP11RejCtor
    (family : PsKernelCoreName)
    (ctor : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (numParams : Nat)
    (numFields : Nat)
    (type : PsKernelCoreExpr) : PsKernelCoreConstructorInfo := {
  base := psP11RejBase ctor levelParams type
  induct := family
  cidx := 0
  numParams := numParams
  numFields := numFields
  isUnsafe := false
}

def psP11RejSingle
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreInductiveInfo)
    (ctor : PsKernelCoreConstructorInfo) : PsKernelCoreResult String PsKernelCoreEnvironment :=
  psKernelCoreAddRecursiveInductive 384 env info
    (PsKernelCoreList.cons ctor PsKernelCoreList.nil)

def psP11RejErrorIs
    (expected : String)
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error message => psKernelCoreStringEq message expected
  | PsKernelCoreResult.ok _ => false

def psP11Negative : Bool :=
  let family := psP11RejName "P11Negative";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let negativeField :=
    PsKernelCoreExpr.forallE psP11RejAnon target target PsKernelCoreBinderInfo.default;
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon negativeField target
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 0 psP11RejSort1;
  let ctor :=
    psP11RejCtor family ctorName PsKernelCoreList.nil 0 1 ctorType;
  psP11RejErrorIs "negative recursive occurrence"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11Nested : Bool :=
  let family := psP11RejName "P11Nested";
  let ctorName := psP11RejCtorName family;
  let box := psP11RejName "Box";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let nested :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.const box PsKernelCoreList.nil) target;
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon nested target
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 0 psP11RejSort1;
  let ctor :=
    psP11RejCtor family ctorName PsKernelCoreList.nil 0 1 ctorType;
  psP11RejErrorIs "nested recursive occurrence is not supported"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11RecursiveIndex : Bool :=
  let family := psP11RejName "P11RecursiveIndex";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let familyType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0 psP11RejSort1
      PsKernelCoreBinderInfo.default;
  let nestedIndex := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 0);
  let badRecursive := PsKernelCoreExpr.app target nestedIndex;
  let finalResult := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 1);
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0
      (PsKernelCoreExpr.forallE psP11RejAnon badRecursive finalResult
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 1 familyType;
  let ctor :=
    psP11RejCtor family ctorName PsKernelCoreList.nil 0 2 ctorType;
  psP11RejErrorIs "invalid recursive result"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11ParamHeader : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0 psP11RejSort1
    PsKernelCoreBinderInfo.default

def psP11NonUniformParam : Bool :=
  let family := psP11RejName "P11NonUniform";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let wrongRecursive := PsKernelCoreExpr.app target psP11RejSort0;
  let finalResult := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 1);
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0
      (PsKernelCoreExpr.forallE psP11RejAnon wrongRecursive finalResult
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 1 0 psP11ParamHeader;
  let ctor :=
    psP11RejCtor family ctorName PsKernelCoreList.nil 1 1 ctorType;
  psP11RejErrorIs "invalid recursive result"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11WrongParamCount : Bool :=
  let family := psP11RejName "P11WrongParamCount";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let finalResult := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 1);
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0
      (PsKernelCoreExpr.forallE psP11RejAnon target finalResult
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 1 0 psP11ParamHeader;
  let ctor :=
    psP11RejCtor family ctorName PsKernelCoreList.nil 1 1 ctorType;
  psP11RejErrorIs "invalid recursive result"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11WrongIndexArity : Bool :=
  let family := psP11RejName "P11WrongIndexArity";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let familyType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0 psP11RejSort1
      PsKernelCoreBinderInfo.default;
  let finalResult := PsKernelCoreExpr.app target (PsKernelCoreExpr.bvar 1);
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0
      (PsKernelCoreExpr.forallE psP11RejAnon target finalResult
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 1 familyType;
  let ctor :=
    psP11RejCtor family ctorName PsKernelCoreList.nil 0 2 ctorType;
  psP11RejErrorIs "invalid recursive result"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11WrongUniverse : Bool :=
  let family := psP11RejName "P11WrongUniverse";
  let ctorName := psP11RejCtorName family;
  let u := psP11RejName "u";
  let levelNames := PsKernelCoreList.cons u PsKernelCoreList.nil;
  let expectedLevels :=
    PsKernelCoreList.cons (PsKernelCoreLevel.param u) PsKernelCoreList.nil;
  let wrongLevels :=
    PsKernelCoreList.cons PsKernelCoreLevel.zero PsKernelCoreList.nil;
  let targetGood := PsKernelCoreExpr.const family expectedLevels;
  let targetBad := PsKernelCoreExpr.const family wrongLevels;
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon targetBad targetGood
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName levelNames 0 0
      (PsKernelCoreExpr.sort (PsKernelCoreLevel.param u));
  let ctor := psP11RejCtor family ctorName levelNames 0 1 ctorType;
  psP11RejErrorIs "invalid recursive result"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11MalformedFunctional : Bool :=
  let family := psP11RejName "P11MalformedFunctional";
  let ctorName := psP11RejCtorName family;
  let box := psP11RejName "Box2";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let nestedResult :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.const box PsKernelCoreList.nil) target;
  let fieldType :=
    PsKernelCoreExpr.forallE psP11RejAnon psP11RejSort0 nestedResult
      PsKernelCoreBinderInfo.default;
  let ctorType :=
    PsKernelCoreExpr.forallE psP11RejAnon fieldType target
      PsKernelCoreBinderInfo.default;
  let info :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 0 psP11RejSort1;
  let ctor := psP11RejCtor family ctorName PsKernelCoreList.nil 0 1 ctorType;
  psP11RejErrorIs "nested recursive occurrence is not supported"
    (psP11RejSingle psKernelCoreEnvironmentEmpty info ctor)

def psP11ForgedRec : Bool :=
  let family := psP11RejName "P11ForgedRec";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let baseInfo :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 0 psP11RejSort1;
  let forged : PsKernelCoreInductiveInfo := {
    base := baseInfo.base
    numParams := baseInfo.numParams
    numIndices := baseInfo.numIndices
    all := baseInfo.all
    ctors := baseInfo.ctors
    numNested := baseInfo.numNested
    isRec := true
    isReflexive := false
    isUnsafe := baseInfo.isUnsafe
  };
  let ctor := psP11RejCtor family ctorName PsKernelCoreList.nil 0 0 target;
  psP11RejErrorIs "unsupported inductive metadata"
    (psP11RejSingle psKernelCoreEnvironmentEmpty forged ctor)

def psP11ForgedReflexive : Bool :=
  let family := psP11RejName "P11ForgedReflexive";
  let ctorName := psP11RejCtorName family;
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let baseInfo :=
    psP11RejInfo family ctorName PsKernelCoreList.nil 0 0 psP11RejSort1;
  let forged : PsKernelCoreInductiveInfo := {
    base := baseInfo.base
    numParams := baseInfo.numParams
    numIndices := baseInfo.numIndices
    all := baseInfo.all
    ctors := baseInfo.ctors
    numNested := baseInfo.numNested
    isRec := false
    isReflexive := true
    isUnsafe := baseInfo.isUnsafe
  };
  let ctor := psP11RejCtor family ctorName PsKernelCoreList.nil 0 0 target;
  psP11RejErrorIs "unsupported inductive metadata"
    (psP11RejSingle psKernelCoreEnvironmentEmpty forged ctor)

def psP11Transactional : Bool :=
  let family := psP11RejName "P11Transactional";
  let goodName := PsKernelCoreName.str family "good";
  let badName := PsKernelCoreName.str family "bad";
  let target := PsKernelCoreExpr.const family PsKernelCoreList.nil;
  let negativeField :=
    PsKernelCoreExpr.forallE psP11RejAnon target target PsKernelCoreBinderInfo.default;
  let badType :=
    PsKernelCoreExpr.forallE psP11RejAnon negativeField target
      PsKernelCoreBinderInfo.default;
  let info : PsKernelCoreInductiveInfo := {
    base := psP11RejBase family PsKernelCoreList.nil psP11RejSort1
    numParams := 0
    numIndices := 0
    all := PsKernelCoreList.cons family PsKernelCoreList.nil
    ctors :=
      PsKernelCoreList.cons goodName
        (PsKernelCoreList.cons badName PsKernelCoreList.nil)
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  };
  let goodCtor := psP11RejCtor family goodName PsKernelCoreList.nil 0 0 target;
  let badCtor := psP11RejCtor family badName PsKernelCoreList.nil 0 1 badType;
  let ctors :=
    PsKernelCoreList.cons goodCtor
      (PsKernelCoreList.cons badCtor PsKernelCoreList.nil);
  let seedName := psP11RejName "Seed";
  let seed : PsKernelCoreAxiomInfo := {
    base := psP11RejBase seedName PsKernelCoreList.nil psP11RejSort1
    isUnsafe := false
  };
  let initial :=
    psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.axiomInfo seed);
  let beforeSize := psKernelCoreEnvironmentSize initial;
  match psKernelCoreAddRecursiveInductive 384 initial info ctors with
  | PsKernelCoreResult.ok _ => false
  | PsKernelCoreResult.error _ =>
      if Nat.beq (psKernelCoreEnvironmentSize initial) beforeSize then
        if psKernelCoreEnvironmentContains initial seedName then
          if psKernelCoreEnvironmentContains initial family then false
          else if psKernelCoreEnvironmentContains initial goodName then false
          else true
        else
          false
      else
        false

def psP11RefNegativeRejected : Bool :=
  let family : PSC1Kernel.Name := .str .anonymous "P11RefNegative";
  let ctor : PSC1Kernel.Name := .str family "mk";
  let target : PSC1Kernel.Expr := .const family [];
  let negative : PSC1Kernel.Expr := .forallE .anonymous target target .default;
  let ctorType : PSC1Kernel.Expr := .forallE .anonymous negative target .default;
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [{ name := ctor, type := ctorType }]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => true
  | .ok _ => false

def psP11RefNestedRejected : Bool :=
  let family : PSC1Kernel.Name := .str .anonymous "P11RefNested";
  let ctor : PSC1Kernel.Name := .str family "mk";
  let box : PSC1Kernel.Name := .str .anonymous "Box";
  let target : PSC1Kernel.Expr := .const family [];
  let nested : PSC1Kernel.Expr := .app (.const box []) target;
  let ctorType : PSC1Kernel.Expr := .forallE .anonymous nested target .default;
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [{ name := ctor, type := ctorType }]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => true
  | .ok _ => false

def psP11RejectionAll : Bool :=
  psP11Negative &&
  psP11Nested &&
  psP11RecursiveIndex &&
  psP11NonUniformParam &&
  psP11WrongParamCount &&
  psP11WrongIndexArity &&
  psP11WrongUniverse &&
  psP11MalformedFunctional &&
  psP11ForgedRec &&
  psP11ForgedReflexive &&
  psP11Transactional &&
  psP11RefNegativeRejected &&
  psP11RefNestedRejected

def main : IO Unit := do
  if psP11RejectionAll then
    IO.println "PSC2_KERNEL_CORE_PHASE11_RECURSIVE_REJECTION: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_PHASE11_RECURSIVE_REJECTION: FAIL")
