import Ps.KernelCore.Environment
import PSC1Kernel.Environment

def psKernelCoreEnvTestName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceEnvTestName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

def psKernelCoreEnvTestAxiom
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (isUnsafe : Bool) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := {
      name := name
      levelParams := levelParams
      type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
    }
    isUnsafe := isUnsafe
  }

def psReferenceEnvTestAxiom
    (name : PSC1Kernel.Name)
    (levelParams : List PSC1Kernel.Name)
    (isUnsafe : Bool) : PSC1Kernel.ConstantInfo :=
  PSC1Kernel.ConstantInfo.axiomInfo {
    base := {
      name := name
      levelParams := levelParams
      type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
    }
    isUnsafe := isUnsafe
  }

def psKernelCoreEnvFoundUnsafe
    (value : PsKernelCoreOption PsKernelCoreConstantInfo) : PsKernelCoreOption Bool :=
  match value with
  | PsKernelCoreOption.none => PsKernelCoreOption.none
  | PsKernelCoreOption.some info =>
      PsKernelCoreOption.some (psKernelCoreConstantInfoIsUnsafe info)

def psReferenceEnvFoundUnsafe
    (value : Option PSC1Kernel.ConstantInfo) : Option Bool :=
  match value with
  | none => none
  | some info => some (PSC1Kernel.ConstantInfo.isUnsafe info)

def psKernelCoreBoolOptionTag
    (value : PsKernelCoreOption Bool) : Nat :=
  match value with
  | PsKernelCoreOption.none => 0
  | PsKernelCoreOption.some false => 1
  | PsKernelCoreOption.some true => 2

def psReferenceBoolOptionTag (value : Option Bool) : Nat :=
  match value with
  | none => 0
  | some false => 1
  | some true => 2

def psKernelCoreAddErrorTag
    (value : PsKernelCoreResult String PsKernelCoreEnvironment) : String :=
  match value with
  | PsKernelCoreResult.error message => message
  | PsKernelCoreResult.ok _ => "ok"

def psReferenceAddErrorTag
    (value : Except String PSC1Kernel.Environment) : String :=
  match value with
  | Except.error message => message
  | Except.ok _ => "ok"

def psKernelCoreEnvironmentParity : Bool :=
  let kcNameA := psKernelCoreEnvTestName "A"
  let kcNameB := psKernelCoreEnvTestName "B"
  let kcU := psKernelCoreEnvTestName "u"
  let kcV := psKernelCoreEnvTestName "v"
  let kcNoParams := PsKernelCoreList.nil
  let kcDupParams :=
    PsKernelCoreList.cons kcU
      (PsKernelCoreList.cons kcV
        (PsKernelCoreList.cons kcU PsKernelCoreList.nil))
  let kcA0 := psKernelCoreEnvTestAxiom kcNameA kcNoParams false
  let kcA1 := psKernelCoreEnvTestAxiom kcNameA kcNoParams true
  let kcB := psKernelCoreEnvTestAxiom kcNameB kcNoParams false
  let kcDupLevels := psKernelCoreEnvTestAxiom kcNameB kcDupParams false
  let kcEmpty := psKernelCoreEnvironmentEmpty
  let kcOne := psKernelCoreEnvironmentAddUnchecked kcEmpty kcA0
  let kcShadow := psKernelCoreEnvironmentAddUnchecked kcOne kcA1
  let kcThree :=
    psKernelCoreEnvironmentAddUnchecked
      (psKernelCoreEnvironmentAddUnchecked kcShadow kcB)
      kcA0
  let kcReplaced := psKernelCoreEnvironmentReplaceUnchecked kcThree kcA1
  let kcMarked := psKernelCoreEnvironmentMarkQuotInitialized kcEmpty
  let kcMarkedTwice := psKernelCoreEnvironmentMarkQuotInitialized kcMarked

  let refNameA := psReferenceEnvTestName "A"
  let refNameB := psReferenceEnvTestName "B"
  let refU := psReferenceEnvTestName "u"
  let refV := psReferenceEnvTestName "v"
  let refA0 := psReferenceEnvTestAxiom refNameA [] false
  let refA1 := psReferenceEnvTestAxiom refNameA [] true
  let refB := psReferenceEnvTestAxiom refNameB [] false
  let refDupLevels := psReferenceEnvTestAxiom refNameB [refU, refV, refU] false
  let refEmpty := PSC1Kernel.Environment.empty
  let refOne := PSC1Kernel.Environment.addUnchecked refEmpty refA0
  let refShadow := PSC1Kernel.Environment.addUnchecked refOne refA1
  let refThree :=
    PSC1Kernel.Environment.addUnchecked
      (PSC1Kernel.Environment.addUnchecked refShadow refB)
      refA0
  let refReplaced := PSC1Kernel.Environment.replaceUnchecked refThree refA1
  let refMarked := PSC1Kernel.Environment.markQuotInitialized refEmpty
  let refMarkedTwice := PSC1Kernel.Environment.markQuotInitialized refMarked

  (psKernelCoreBoolOptionTag
      (psKernelCoreEnvFoundUnsafe
        (psKernelCoreEnvironmentFind? kcEmpty kcNameA)) ==
    psReferenceBoolOptionTag
      (psReferenceEnvFoundUnsafe
        (PSC1Kernel.Environment.find? refEmpty refNameA))) &&
  (psKernelCoreBoolOptionTag
      (psKernelCoreEnvFoundUnsafe
        (psKernelCoreEnvironmentFind? kcOne kcNameA)) ==
    psReferenceBoolOptionTag
      (psReferenceEnvFoundUnsafe
        (PSC1Kernel.Environment.find? refOne refNameA))) &&
  (psKernelCoreBoolOptionTag
      (psKernelCoreEnvFoundUnsafe
        (psKernelCoreEnvironmentFind? kcShadow kcNameA)) ==
    psReferenceBoolOptionTag
      (psReferenceEnvFoundUnsafe
        (PSC1Kernel.Environment.find? refShadow refNameA))) &&
  (psKernelCoreEnvironmentContains kcOne kcNameA ==
    PSC1Kernel.Environment.contains refOne refNameA) &&
  (psKernelCoreEnvironmentContains kcOne kcNameB ==
    PSC1Kernel.Environment.contains refOne refNameB) &&
  (psKernelCoreEnvironmentSize kcThree == PSC1Kernel.Environment.size refThree) &&
  (psKernelCoreBoolOptionTag
      (psKernelCoreEnvFoundUnsafe
        (psKernelCoreEnvironmentFind? kcReplaced kcNameA)) ==
    psReferenceBoolOptionTag
      (psReferenceEnvFoundUnsafe
        (PSC1Kernel.Environment.find? refReplaced refNameA))) &&
  (psKernelCoreEnvironmentContains kcReplaced kcNameB ==
    PSC1Kernel.Environment.contains refReplaced refNameB) &&
  (psKernelCoreAddErrorTag (psKernelCoreEnvironmentAdd kcOne kcA1) ==
    psReferenceAddErrorTag (PSC1Kernel.Environment.add refOne refA1)) &&
  (psKernelCoreAddErrorTag (psKernelCoreEnvironmentAdd kcEmpty kcDupLevels) ==
    psReferenceAddErrorTag (PSC1Kernel.Environment.add refEmpty refDupLevels)) &&
  (kcMarked.quotInitialized == refMarked.quotInitialized) &&
  (kcMarkedTwice.quotInitialized == refMarkedTwice.quotInitialized)

def main : IO Unit := do
  if psKernelCoreEnvironmentParity then
    IO.println "PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: FAIL")
