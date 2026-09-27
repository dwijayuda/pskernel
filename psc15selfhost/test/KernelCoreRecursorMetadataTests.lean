import Ps.KernelCore.Declaration
import PSC1Kernel.Declaration

def psKernelCoreRecursorMetadataParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcCtor := PsKernelCoreName.str kcAnon "C"
  let kcRec := PsKernelCoreName.str kcAnon "T.rec"
  let kcU := PsKernelCoreName.str kcAnon "u"
  let kcRhs := PsKernelCoreExpr.bvar 0
  let kcRule : PsKernelCoreRecursorRule := {
    ctor := kcCtor
    nFields := 1
    rhs := kcRhs
  }
  let kcInfo : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.recInfo {
      base := {
        name := kcRec
        levelParams := PsKernelCoreList.cons kcU PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      all := PsKernelCoreList.cons (PsKernelCoreName.str kcAnon "T") PsKernelCoreList.nil
      numParams := 1
      numIndices := 0
      numMotives := 1
      numMinors := 1
      rules := PsKernelCoreList.cons kcRule PsKernelCoreList.nil
      k := false
      isUnsafe := true
    }

  let refAnon := PSC1Kernel.Name.anonymous
  let refCtor := PSC1Kernel.Name.str refAnon "C"
  let refRec := PSC1Kernel.Name.str refAnon "T.rec"
  let refU := PSC1Kernel.Name.str refAnon "u"
  let refRhs := PSC1Kernel.Expr.bvar 0
  let refRule : PSC1Kernel.RecursorRule := {
    ctor := refCtor
    nFields := 1
    rhs := refRhs
  }
  let refInfo : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.recInfo {
      base := {
        name := refRec
        levelParams := [refU]
        type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
      }
      all := [PSC1Kernel.Name.str refAnon "T"]
      numParams := 1
      numIndices := 0
      numMotives := 1
      numMinors := 1
      rules := [refRule]
      k := false
      isUnsafe := true
    }

  let ruleStored :=
    match kcInfo with
    | PsKernelCoreConstantInfo.recInfo value =>
        match value.rules with
        | PsKernelCoreList.cons rule PsKernelCoreList.nil =>
            psKernelCoreNameEq rule.ctor kcCtor &&
            rule.nFields == refRule.nFields &&
            match rule.rhs with
            | PsKernelCoreExpr.bvar 0 => true
            | _ => false
        | _ => false
    | _ => false
  let levelsStored :=
    match psKernelCoreConstantInfoLevelParams kcInfo with
    | PsKernelCoreList.cons only PsKernelCoreList.nil => psKernelCoreNameEq only kcU
    | _ => false
  let typeStored :=
    match psKernelCoreConstantInfoType kcInfo with
    | PsKernelCoreExpr.sort PsKernelCoreLevel.zero => true
    | _ => false
  let deltaNone :=
    match psKernelCoreConstantInfoDeltaValue? kcInfo with
    | PsKernelCoreOption.none => true
    | _ => false
  let hintsNone :=
    match psKernelCoreConstantInfoHints? kcInfo with
    | PsKernelCoreOption.none => true
    | _ => false
  let definitionNone :=
    match psKernelCoreConstantInfoDefinition? kcInfo with
    | PsKernelCoreOption.none => true
    | _ => false

  psKernelCoreNameEq (psKernelCoreConstantInfoName kcInfo) kcRec &&
  levelsStored && typeStored && ruleStored &&
  (psKernelCoreConstantInfoIsUnsafe kcInfo == PSC1Kernel.ConstantInfo.isUnsafe refInfo) &&
  (psKernelCoreConstantInfoIsPartial kcInfo == PSC1Kernel.ConstantInfo.isPartial refInfo) &&
  (psKernelCoreConstantInfoIsDefinition kcInfo == PSC1Kernel.ConstantInfo.isDefinition refInfo) &&
  deltaNone && hintsNone && definitionNone

def main : IO Unit := do
  if psKernelCoreRecursorMetadataParity then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_METADATA: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_METADATA: FAIL")
