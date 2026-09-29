import Ps.KernelCore.RecursiveInductive

def psP11Anon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP11Target : PsKernelCoreName :=
  PsKernelCoreName.str psP11Anon "Tree"

def psP11Ctor : PsKernelCoreName :=
  PsKernelCoreName.str psP11Target "node"

def psP11Alias : PsKernelCoreName :=
  PsKernelCoreName.str psP11Anon "TreeAlias"

def psP11Levels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP11TargetExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP11Target psP11Levels

def psP11Sort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP11DirectShape : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11Target psP11Levels 0 0 0 psP11TargetExpr with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some shape =>
          if Nat.beq shape.argCount 0 then
            Nat.beq (psKernelCoreInductiveExprListLength shape.indices) 0
          else
            false

def psP11FunctionalExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    psP11Anon psP11Sort psP11TargetExpr PsKernelCoreBinderInfo.default

def psP11FunctionalShape : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11Target psP11Levels 0 0 0 psP11FunctionalExpr with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some shape => Nat.beq shape.argCount 1

def psP11DoubleFunctionalExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    psP11Anon psP11Sort
    (PsKernelCoreExpr.forallE
      psP11Anon psP11Sort psP11TargetExpr PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psP11DoubleFunctionalShape : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11Target psP11Levels 0 0 0 psP11DoubleFunctionalExpr with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some shape => Nat.beq shape.argCount 2

def psP11NonRecursiveShape : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11Target psP11Levels 0 0 0 psP11Sort with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => true
      | PsKernelCoreOption.some _ => false

def psP11IndexedExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP11TargetExpr (PsKernelCoreExpr.bvar 0)

def psP11IndexedShape : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11Target psP11Levels 0 1 1 psP11IndexedExpr with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some shape =>
          match shape.indices with
          | PsKernelCoreList.nil => false
          | PsKernelCoreList.cons head tail =>
              if psKernelCoreExprEq head (PsKernelCoreExpr.bvar 0) then
                match tail with
                | PsKernelCoreList.nil => true
                | PsKernelCoreList.cons _ _ => false
              else
                false

def psP11UniformFunctionalExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    psP11Anon psP11Sort
    (PsKernelCoreExpr.app psP11TargetExpr (PsKernelCoreExpr.bvar 1))
    PsKernelCoreBinderInfo.default

def psP11UniformBinderDepth : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11Target psP11Levels 1 0 1 psP11UniformFunctionalExpr with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some shape => Nat.beq shape.argCount 1

def psP11AliasBase : PsKernelCoreConstantBase := {
  name := psP11Alias
  levelParams := PsKernelCoreList.nil
  type := psP11Sort
}

def psP11AliasInfo : PsKernelCoreDefinitionInfo := {
  base := psP11AliasBase
  value := psP11TargetExpr
  hints := PsKernelCoreReducibilityHints.regular 0
  safety := PsKernelCoreDefinitionSafety.safe
}

def psP11AliasEnv : PsKernelCoreEnvironment :=
  psKernelCoreEnvironmentAddUnchecked
    psKernelCoreEnvironmentEmpty
    (PsKernelCoreConstantInfo.defnInfo psP11AliasInfo)

def psP11ReducedShape : Bool :=
  match psKernelCoreRecursiveFieldShapeWithResources
      32 psKernelCoreResourceConfigDefault
      psP11AliasEnv
      psP11Target psP11Levels 0 0 0
      (PsKernelCoreExpr.const psP11Alias PsKernelCoreList.nil) with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok result =>
      match result with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some shape => Nat.beq shape.argCount 0

def psP11TwoFieldCtorType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    psP11Anon psP11TargetExpr
    (PsKernelCoreExpr.forallE
      psP11Anon psP11TargetExpr psP11TargetExpr PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psP11InductiveInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP11Target
    levelParams := PsKernelCoreList.nil
    type := psP11Sort
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP11Target PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP11Ctor PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP11CtorInfo : PsKernelCoreConstructorInfo := {
  base := {
    name := psP11Ctor
    levelParams := PsKernelCoreList.nil
    type := psP11TwoFieldCtorType
  }
  induct := psP11Target
  cidx := 0
  numParams := 0
  numFields := 2
  isUnsafe := false
}

def psP11MultipleFieldSummary : Bool :=
  match psKernelCoreAnalyzeRecursiveConstructorWithResources
      64 psKernelCoreResourceConfigDefault
      psKernelCoreEnvironmentEmpty
      psP11InductiveInfo psP11Levels psP11CtorInfo with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok summary =>
      if summary.isRec then
        if summary.isReflexive then false else true
      else
        false

def psP11ShapeAll : Bool :=
  psP11DirectShape &&
  psP11FunctionalShape &&
  psP11DoubleFunctionalShape &&
  psP11NonRecursiveShape &&
  psP11IndexedShape &&
  psP11UniformBinderDepth &&
  psP11ReducedShape &&
  psP11MultipleFieldSummary

def main : IO Unit := do
  if psP11ShapeAll then
    IO.println "PSC2_KERNEL_CORE_PHASE11_RECURSIVE_SHAPE: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_PHASE11_RECURSIVE_SHAPE: FAIL")
