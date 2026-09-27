import Ps.KernelCore.Inductive

def psKcShapeAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcShapeTarget : PsKernelCoreName :=
  PsKernelCoreName.str psKcShapeAnon "T"

def psKcShapeU : PsKernelCoreName :=
  PsKernelCoreName.str psKcShapeAnon "u"

def psKcShapeLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.cons (PsKernelCoreLevel.param psKcShapeU) PsKernelCoreList.nil

def psKcShapeTargetConst : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcShapeTarget psKcShapeLevels

def psKcShapeCorrectIndexedResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psKcShapeTargetConst (PsKernelCoreExpr.bvar 1))
    (PsKernelCoreExpr.bvar 0)

def psKcShapeWrongPrefixResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psKcShapeTargetConst (PsKernelCoreExpr.bvar 0))
    (PsKernelCoreExpr.bvar 0)

def psKcShapeHiddenRecursiveIndex : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psKcShapeTargetConst (PsKernelCoreExpr.bvar 1))
    psKcShapeTargetConst

def psKcShapeGoodCtor : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcShapeAnon
    (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
    (PsKernelCoreExpr.forallE psKcShapeAnon
      (PsKernelCoreExpr.bvar 0)
      psKcShapeCorrectIndexedResult
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKcShapeRecursiveFieldCtor : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcShapeAnon
    (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
    (PsKernelCoreExpr.forallE psKcShapeAnon
      (PsKernelCoreExpr.app psKcShapeTargetConst (PsKernelCoreExpr.bvar 0))
      psKcShapeCorrectIndexedResult
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.implicit

def psKernelCoreInductiveShapeTests : Bool :=
  let nested :=
    PsKernelCoreExpr.mdata 0
      (PsKernelCoreExpr.proj psKcShapeTarget 0
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcShapeTargetConst))
  (!psKernelCoreExprContainsConstName psKcShapeTarget (PsKernelCoreExpr.bvar 0)) &&
  psKernelCoreExprContainsConstName psKcShapeTarget psKcShapeTargetConst &&
  psKernelCoreExprContainsConstName psKcShapeTarget nested &&
  psKernelCoreInductiveResultMatches
    psKcShapeTarget psKcShapeLevels 1 1 2 psKcShapeCorrectIndexedResult &&
  (!psKernelCoreInductiveResultMatches
    psKcShapeTarget psKcShapeLevels 1 1 2 psKcShapeWrongPrefixResult) &&
  (!psKernelCoreInductiveResultMatches
    psKcShapeTarget psKcShapeLevels 1 1 2 psKcShapeHiddenRecursiveIndex) &&
  (!psKernelCoreInductiveConstructorRecursiveOccurrence
    psKcShapeTarget psKcShapeLevels 1 1 psKcShapeGoodCtor) &&
  psKernelCoreInductiveConstructorRecursiveOccurrence
    psKcShapeTarget psKcShapeLevels 1 1 psKcShapeRecursiveFieldCtor

def main : IO Unit := do
  if psKernelCoreInductiveShapeTests then
    IO.println "PSC2_KERNEL_CORE_INDUCTIVE_SHAPE: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_INDUCTIVE_SHAPE: FAIL")
