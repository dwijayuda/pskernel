import Ps.KernelCore

def psKcEqAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcEqName : PsKernelCoreName := PsKernelCoreName.str psKcEqAnon "Eq"

def psKcEqReflName : PsKernelCoreName := PsKernelCoreName.str psKcEqName "refl"

def psKcEqU : PsKernelCoreName := PsKernelCoreName.str psKcEqAnon "u"

def psKcEqLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons (PsKernelCoreLevel.param psKcEqU) PsKernelCoreList.nil

def psKcEqLevelParams : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons psKcEqU PsKernelCoreList.nil

def psKcEqType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcEqAnon
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqU))
    (PsKernelCoreExpr.forallE psKcEqAnon
      (PsKernelCoreExpr.bvar 0)
      (PsKernelCoreExpr.forallE psKcEqAnon
        (PsKernelCoreExpr.bvar 1)
        (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcEqReflResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psKcEqName psKcEqLevels)
        (PsKernelCoreExpr.bvar 1))
      (PsKernelCoreExpr.bvar 0))
    (PsKernelCoreExpr.bvar 0)

def psKcEqReflType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcEqAnon
    (PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcEqU))
    (PsKernelCoreExpr.forallE psKcEqAnon
      (PsKernelCoreExpr.bvar 0)
      psKcEqReflResult
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcEqInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcEqName
    levelParams := psKcEqLevelParams
    type := psKcEqType
  }
  numParams := 1
  numIndices := 2
  all := PsKernelCoreList.cons psKcEqName PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcEqReflName PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcEqReflInfo : PsKernelCoreConstructorInfo := {
  base := {
    name := psKcEqReflName
    levelParams := psKcEqLevelParams
    type := psKcEqReflType
  }
  induct := psKcEqName
  cidx := 0
  numParams := 1
  numFields := 1
  isUnsafe := false
}

def psKernelCoreEqInductiveCompatibility : Bool :=
  let ctors := PsKernelCoreList.cons psKcEqReflInfo PsKernelCoreList.nil
  match psKernelCoreAddNonRecursiveInductive
      128 psKernelCoreEnvironmentEmpty psKcEqInfo ctors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      (psKernelCoreEnvironmentSize env == 2) &&
      match psKernelCoreEnvironmentFind? env psKcEqName with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo eqInfo) =>
          (eqInfo.numParams == 1) && (eqInfo.numIndices == 2) &&
          match psKernelCoreEnvironmentFind? env psKcEqReflName with
          | PsKernelCoreOption.some (PsKernelCoreConstantInfo.ctorInfo reflInfo) =>
              psKernelCoreNameEq reflInfo.induct psKcEqName &&
              (reflInfo.cidx == 0) &&
              (reflInfo.numParams == 1) &&
              (reflInfo.numFields == 1)
          | _ => false
      | _ => false

def main : IO Unit := do
  if psKernelCoreEqInductiveCompatibility then
    IO.println "PSC2_KERNEL_CORE_EQ_INDUCTIVE: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_EQ_INDUCTIVE: FAIL")
