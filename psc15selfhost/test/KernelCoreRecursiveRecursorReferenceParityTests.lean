import Ps.KernelCore
import PSC1Kernel.Inductive
import PSC1Kernel.TypeChecker

def psP12KernelName (base : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous base

def psP12KernelDirect : Bool :=
  let family := psP12KernelName "Phase12RefDirect";
  let nilName := PsKernelCoreName.str family "nil";
  let consName := PsKernelCoreName.str family "cons";
  let target : PsKernelCoreExpr := .const family PsKernelCoreList.nil;
  let info : PsKernelCoreInductiveInfo := {
    base := {
      name := family
      levelParams := PsKernelCoreList.nil
      type := .sort (.succ .zero)
    }
    numParams := 0
    numIndices := 0
    all := PsKernelCoreList.cons family PsKernelCoreList.nil
    ctors :=
      PsKernelCoreList.cons nilName
        (PsKernelCoreList.cons consName PsKernelCoreList.nil)
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  };
  let nilCtor : PsKernelCoreConstructorInfo := {
    base := {
      name := nilName
      levelParams := PsKernelCoreList.nil
      type := target
    }
    induct := family
    cidx := 0
    numParams := 0
    numFields := 0
    isUnsafe := false
  };
  let consType : PsKernelCoreExpr :=
    .forallE .anonymous target target .default;
  let consCtor : PsKernelCoreConstructorInfo := {
    base := {
      name := consName
      levelParams := PsKernelCoreList.nil
      type := consType
    }
    induct := family
    cidx := 1
    numParams := 0
    numFields := 1
    isUnsafe := false
  };
  let ctors :=
    PsKernelCoreList.cons nilCtor
      (PsKernelCoreList.cons consCtor PsKernelCoreList.nil);
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty info ctors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      match psKernelCoreEnvironmentFind? env family,
          psKernelCoreEnvironmentFind? env nilName,
          psKernelCoreEnvironmentFind? env consName with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo induct),
          PsKernelCoreOption.some (PsKernelCoreConstantInfo.ctorInfo nilInfo),
          PsKernelCoreOption.some (PsKernelCoreConstantInfo.ctorInfo consInfo) =>
          induct.isRec && (!induct.isReflexive) &&
          induct.numIndices == 0 &&
          nilInfo.numFields == 0 && consInfo.numFields == 1
      | _, _, _ => false

def psP12KernelMulti : Bool :=
  let family := psP12KernelName "Phase12RefMulti";
  let node := PsKernelCoreName.str family "node";
  let target : PsKernelCoreExpr := .const family PsKernelCoreList.nil;
  let ctorType : PsKernelCoreExpr :=
    .forallE .anonymous target
      (.forallE .anonymous target target .default) .default;
  let info : PsKernelCoreInductiveInfo := {
    base := {
      name := family
      levelParams := PsKernelCoreList.nil
      type := .sort (.succ .zero)
    }
    numParams := 0
    numIndices := 0
    all := PsKernelCoreList.cons family PsKernelCoreList.nil
    ctors := PsKernelCoreList.cons node PsKernelCoreList.nil
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  };
  let ctor : PsKernelCoreConstructorInfo := {
    base := {
      name := node
      levelParams := PsKernelCoreList.nil
      type := ctorType
    }
    induct := family
    cidx := 0
    numParams := 0
    numFields := 2
    isUnsafe := false
  };
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty info
      (PsKernelCoreList.cons ctor PsKernelCoreList.nil) with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      match psKernelCoreEnvironmentFind? env family,
          psKernelCoreEnvironmentFind? env node with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo induct),
          PsKernelCoreOption.some (PsKernelCoreConstantInfo.ctorInfo ctorInfo) =>
          induct.isRec && (!induct.isReflexive) &&
          induct.numIndices == 0 && ctorInfo.numFields == 2
      | _, _ => false

def psP12KernelFunctional : Bool :=
  let family := psP12KernelName "Phase12RefFunctional";
  let node := PsKernelCoreName.str family "node";
  let target : PsKernelCoreExpr := .const family PsKernelCoreList.nil;
  let recursiveField : PsKernelCoreExpr :=
    .forallE .anonymous (.sort .zero) target .default;
  let ctorType : PsKernelCoreExpr :=
    .forallE .anonymous recursiveField target .default;
  let info : PsKernelCoreInductiveInfo := {
    base := {
      name := family
      levelParams := PsKernelCoreList.nil
      type := .sort (.succ .zero)
    }
    numParams := 0
    numIndices := 0
    all := PsKernelCoreList.cons family PsKernelCoreList.nil
    ctors := PsKernelCoreList.cons node PsKernelCoreList.nil
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  };
  let ctor : PsKernelCoreConstructorInfo := {
    base := {
      name := node
      levelParams := PsKernelCoreList.nil
      type := ctorType
    }
    induct := family
    cidx := 0
    numParams := 0
    numFields := 1
    isUnsafe := false
  };
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty info
      (PsKernelCoreList.cons ctor PsKernelCoreList.nil) with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      match psKernelCoreEnvironmentFind? env family,
          psKernelCoreEnvironmentFind? env node with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo induct),
          PsKernelCoreOption.some (PsKernelCoreConstantInfo.ctorInfo ctorInfo) =>
          induct.isRec && induct.isReflexive &&
          induct.numIndices == 0 && ctorInfo.numFields == 1
      | _, _ => false

def psP12KernelIndexed : Bool :=
  let family := psP12KernelName "Phase12RefIndexed";
  let node := PsKernelCoreName.str family "node";
  let target : PsKernelCoreExpr := .const family PsKernelCoreList.nil;
  let familyType : PsKernelCoreExpr :=
    .forallE .anonymous (.sort .zero) (.sort (.succ .zero)) .default;
  let targetAt0 : PsKernelCoreExpr := .app target (.bvar 0);
  let targetAt1 : PsKernelCoreExpr := .app target (.bvar 1);
  let ctorType : PsKernelCoreExpr :=
    .forallE .anonymous (.sort .zero)
      (.forallE .anonymous targetAt0 targetAt1 .default) .default;
  let info : PsKernelCoreInductiveInfo := {
    base := {
      name := family
      levelParams := PsKernelCoreList.nil
      type := familyType
    }
    numParams := 0
    numIndices := 1
    all := PsKernelCoreList.cons family PsKernelCoreList.nil
    ctors := PsKernelCoreList.cons node PsKernelCoreList.nil
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  };
  let ctor : PsKernelCoreConstructorInfo := {
    base := {
      name := node
      levelParams := PsKernelCoreList.nil
      type := ctorType
    }
    induct := family
    cidx := 0
    numParams := 0
    numFields := 2
    isUnsafe := false
  };
  match psKernelCoreAddRecursiveInductive
      512 psKernelCoreEnvironmentEmpty info
      (PsKernelCoreList.cons ctor PsKernelCoreList.nil) with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      match psKernelCoreEnvironmentFind? env family,
          psKernelCoreEnvironmentFind? env node with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo induct),
          PsKernelCoreOption.some (PsKernelCoreConstantInfo.ctorInfo ctorInfo) =>
          induct.isRec && (!induct.isReflexive) &&
          induct.numIndices == 1 && ctorInfo.numFields == 2
      | _, _ => false

def psP12RefName (base : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous base

def psP12RefRuleFieldsEq
    (rules : List PSC1Kernel.RecursorRule)
    (expected : List Nat) : Bool :=
  match rules, expected with
  | [], [] => true
  | rule :: ruleRest, fieldCount :: fieldRest =>
      rule.nFields == fieldCount && psP12RefRuleFieldsEq ruleRest fieldRest
  | _, _ => false

def psP12RefContract
    (env : PSC1Kernel.Environment)
    (family : PSC1Kernel.Name)
    (recName : PSC1Kernel.Name)
    (numIndices : Nat)
    (numMinors : Nat)
    (ruleFields : List Nat)
    (expectReflexive : Bool) : Bool :=
  match env.find? family, env.find? recName with
  | some (.inductInfo induct), some (.recInfo recInfo) =>
      induct.isRec &&
      induct.isReflexive == expectReflexive &&
      recInfo.numParams == 0 &&
      recInfo.numIndices == numIndices &&
      recInfo.numMotives == 1 &&
      recInfo.numMinors == numMinors &&
      psP12RefRuleFieldsEq recInfo.rules ruleFields
  | _, _ => false

def psP12RefDirect : Bool :=
  let family := psP12RefName "Phase12RefDirect";
  let nilName := PSC1Kernel.Name.str family "nil";
  let consName := PSC1Kernel.Name.str family "cons";
  let recName := PSC1Kernel.Name.str family "rec";
  let target : PSC1Kernel.Expr := .const family [];
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [
      { name := nilName, type := target },
      { name := consName, type := .forallE .anonymous target target .default }
    ]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env => psP12RefContract env family recName 0 2 [0, 1] false

def psP12RefMulti : Bool :=
  let family := psP12RefName "Phase12RefMulti";
  let node := PSC1Kernel.Name.str family "node";
  let recName := PSC1Kernel.Name.str family "rec";
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
  | .ok env => psP12RefContract env family recName 0 1 [2] false

def psP12RefFunctional : Bool :=
  let family := psP12RefName "Phase12RefFunctional";
  let node := PSC1Kernel.Name.str family "node";
  let recName := PSC1Kernel.Name.str family "rec";
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
  | .ok env => psP12RefContract env family recName 0 1 [1] true

def psP12RefIndexed : Bool :=
  let family := psP12RefName "Phase12RefIndexed";
  let node := PSC1Kernel.Name.str family "node";
  let recName := PSC1Kernel.Name.str family "rec";
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
  | .ok env => psP12RefContract env family recName 1 1 [2] false

def psP12RefDirectReduction : Bool :=
  let family := psP12RefName "Phase12RefReduce";
  let nilName := PSC1Kernel.Name.str family "nil";
  let consName := PSC1Kernel.Name.str family "cons";
  let recName := PSC1Kernel.Name.str family "rec";
  let target : PSC1Kernel.Expr := .const family [];
  let nilExpr : PSC1Kernel.Expr := .const nilName [];
  let consHead : PSC1Kernel.Expr := .const consName [];
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [
      { name := nilName, type := target },
      { name := consName, type := .forallE .anonymous target target .default }
    ]
    isUnsafe := false
    numParams := 0
  };
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env =>
      let motive : PSC1Kernel.Expr :=
        .lam .anonymous target target .default;
      let consMinor : PSC1Kernel.Expr :=
        .lam .anonymous target
          (.lam .anonymous target (.bvar 0) .default) .default;
      let nestedMajor : PSC1Kernel.Expr :=
        .app consHead (.app consHead nilExpr);
      let recCall :=
        PSC1Kernel.applyArgs
          (.const recName [(.succ .zero)])
          [motive, nilExpr, consMinor, nestedMajor];
      match PSC1Kernel.whnf (PSC1Kernel.CheckerContext.empty env) recCall with
      | .error _ => false
      | .ok (.const result []) => PSC1Kernel.Name.eq result nilName
      | .ok _ => false

def psP12ReferenceParity : Bool :=
  (psP12KernelDirect == psP12RefDirect) && psP12KernelDirect &&
  (psP12KernelMulti == psP12RefMulti) && psP12KernelMulti &&
  (psP12KernelFunctional == psP12RefFunctional) && psP12KernelFunctional &&
  (psP12KernelIndexed == psP12RefIndexed) && psP12KernelIndexed &&
  psP12RefDirectReduction

def main : IO Unit := do
  if psP12ReferenceParity then
    IO.println "PSC2_KERNEL_CORE_PHASE12_REFERENCE_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_PHASE12_REFERENCE_PARITY: FAIL")
