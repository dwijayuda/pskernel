import Ps.KernelCore.Declaration
import PSC1Kernel.Declaration

def psKernelCoreInductiveMetadataParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcName := PsKernelCoreName.str kcAnon "Eq"
  let kcCtorName := PsKernelCoreName.str kcName "refl"
  let kcU := PsKernelCoreName.str kcAnon "u"
  let kcParams := PsKernelCoreList.cons kcU PsKernelCoreList.nil
  let kcType := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let kcBase : PsKernelCoreConstantBase := {
    name := kcName
    levelParams := kcParams
    type := kcType
  }
  let kcCtorBase : PsKernelCoreConstantBase := {
    name := kcCtorName
    levelParams := kcParams
    type := kcType
  }
  let kcIndInfo : PsKernelCoreInductiveInfo := {
    base := kcBase
    numParams := 1
    numIndices := 2
    all := PsKernelCoreList.cons kcName PsKernelCoreList.nil
    ctors := PsKernelCoreList.cons kcCtorName PsKernelCoreList.nil
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  }
  let kcCtorInfo : PsKernelCoreConstructorInfo := {
    base := kcCtorBase
    induct := kcName
    cidx := 0
    numParams := 1
    numFields := 0
    isUnsafe := false
  }
  let kcInd : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.inductInfo kcIndInfo
  let kcCtor : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.ctorInfo kcCtorInfo

  let refAnon := PSC1Kernel.Name.anonymous
  let refName := PSC1Kernel.Name.str refAnon "Eq"
  let refCtorName := PSC1Kernel.Name.str refName "refl"
  let refU := PSC1Kernel.Name.str refAnon "u"
  let refType := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
  let refBase : PSC1Kernel.ConstantBase := {
    name := refName
    levelParams := [refU]
    type := refType
  }
  let refCtorBase : PSC1Kernel.ConstantBase := {
    name := refCtorName
    levelParams := [refU]
    type := refType
  }
  let refInd : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.inductInfo {
      base := refBase
      numParams := 1
      numIndices := 2
      all := [refName]
      ctors := [refCtorName]
      numNested := 0
      isRec := false
      isReflexive := false
      isUnsafe := false
    }
  let refCtor : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.ctorInfo {
      base := refCtorBase
      induct := refName
      cidx := 0
      numParams := 1
      numFields := 0
      isUnsafe := false
    }

  psKernelCoreNameEq (psKernelCoreConstantInfoName kcInd) kcName &&
  psKernelCoreNameEq (psKernelCoreConstantInfoName kcCtor) kcCtorName &&
  (psKernelCoreConstantInfoIsUnsafe kcInd == PSC1Kernel.ConstantInfo.isUnsafe refInd) &&
  (psKernelCoreConstantInfoIsUnsafe kcCtor == PSC1Kernel.ConstantInfo.isUnsafe refCtor) &&
  (!psKernelCoreConstantInfoIsPartial kcInd) &&
  (!psKernelCoreConstantInfoIsPartial kcCtor) &&
  (!psKernelCoreConstantInfoIsDefinition kcInd) &&
  (!psKernelCoreConstantInfoIsDefinition kcCtor)

def main : IO Unit := do
  if psKernelCoreInductiveMetadataParity then
    IO.println "PSC2_KERNEL_CORE_INDUCTIVE_METADATA: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_INDUCTIVE_METADATA: FAIL")
