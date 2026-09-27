import Ps.KernelCore.Declaration
import PSC1Kernel.Declaration

def psKernelCoreQuotKindParity
    (kc : PsKernelCoreQuotKind)
    (ref : PSC1Kernel.QuotKind) : Bool :=
  match kc, ref with
  | PsKernelCoreQuotKind.typeQ, PSC1Kernel.QuotKind.typeQ => true
  | PsKernelCoreQuotKind.ctorQ, PSC1Kernel.QuotKind.ctorQ => true
  | PsKernelCoreQuotKind.liftQ, PSC1Kernel.QuotKind.liftQ => true
  | PsKernelCoreQuotKind.indQ, PSC1Kernel.QuotKind.indQ => true
  | _, _ => false

def psKernelCoreQuotMetadataCase
    (kcKind : PsKernelCoreQuotKind)
    (refKind : PSC1Kernel.QuotKind)
    (suffix : String) : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcName := PsKernelCoreName.str kcAnon suffix
  let kcU := PsKernelCoreName.str kcAnon "u"
  let kcType := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
  let kcInfo : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.quotInfo {
      base := {
        name := kcName
        levelParams := PsKernelCoreList.cons kcU PsKernelCoreList.nil
        type := kcType
      }
      kind := kcKind
    }

  let refAnon := PSC1Kernel.Name.anonymous
  let refName := PSC1Kernel.Name.str refAnon suffix
  let refU := PSC1Kernel.Name.str refAnon "u"
  let refType := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
  let refInfo : PSC1Kernel.ConstantInfo :=
    PSC1Kernel.ConstantInfo.quotInfo {
      base := {
        name := refName
        levelParams := [refU]
        type := refType
      }
      kind := refKind
    }

  let kcKindStored :=
    match kcInfo with
    | PsKernelCoreConstantInfo.quotInfo value =>
        psKernelCoreQuotKindParity value.kind refKind
    | _ => false
  let typeStored :=
    match psKernelCoreConstantInfoType kcInfo with
    | PsKernelCoreExpr.sort PsKernelCoreLevel.zero => true
    | _ => false
  let deltaNone :=
    match psKernelCoreConstantInfoDeltaValue? kcInfo with
    | PsKernelCoreOption.none => true
    | PsKernelCoreOption.some _ => false
  let hintsNone :=
    match psKernelCoreConstantInfoHints? kcInfo with
    | PsKernelCoreOption.none => true
    | PsKernelCoreOption.some _ => false
  let definitionNone :=
    match psKernelCoreConstantInfoDefinition? kcInfo with
    | PsKernelCoreOption.none => true
    | PsKernelCoreOption.some _ => false

  psKernelCoreNameEq (psKernelCoreConstantInfoName kcInfo) kcName &&
  psKernelCoreLevelListEq
    (psKernelCoreConstantInfoLevelParams kcInfo)
    (PsKernelCoreList.cons kcU PsKernelCoreList.nil) &&
  typeStored &&
  kcKindStored &&
  (psKernelCoreConstantInfoIsUnsafe kcInfo == PSC1Kernel.ConstantInfo.isUnsafe refInfo) &&
  (psKernelCoreConstantInfoIsPartial kcInfo == PSC1Kernel.ConstantInfo.isPartial refInfo) &&
  (psKernelCoreConstantInfoIsDefinition kcInfo == PSC1Kernel.ConstantInfo.isDefinition refInfo) &&
  deltaNone && hintsNone && definitionNone

def psKernelCoreQuotMetadataParity : Bool :=
  psKernelCoreQuotMetadataCase
      PsKernelCoreQuotKind.typeQ PSC1Kernel.QuotKind.typeQ "Quot" &&
  psKernelCoreQuotMetadataCase
      PsKernelCoreQuotKind.ctorQ PSC1Kernel.QuotKind.ctorQ "Quot.mk" &&
  psKernelCoreQuotMetadataCase
      PsKernelCoreQuotKind.liftQ PSC1Kernel.QuotKind.liftQ "Quot.lift" &&
  psKernelCoreQuotMetadataCase
      PsKernelCoreQuotKind.indQ PSC1Kernel.QuotKind.indQ "Quot.ind"

def main : IO Unit := do
  if psKernelCoreQuotMetadataParity then
    IO.println "PSC2_KERNEL_CORE_QUOT_METADATA: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_QUOT_METADATA: FAIL")
