import Ps.KernelCore

def psP12IdxAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12IdxFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "Phase12Indexed"

def psP12IdxNode : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxFamily "node"

def psP12IdxRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxFamily "rec"

def psP12IdxMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "_p12IdxMotive"

def psP12IdxMinorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "_p12IdxMinor"

def psP12IdxIndexI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "_p12IdxIndex"

def psP12IdxChildI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "_p12IdxChild"

def psP12IdxIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "_p12IdxIh"

def psP12IdxMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxAnon "_p12IdxMajor"

def psP12IdxSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12IdxSmallSort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP12IdxLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12IdxTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12IdxFamily psP12IdxLevels

def psP12IdxMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxMotiveI

def psP12IdxMinor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxMinorI

def psP12IdxIndex : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxIndexI

def psP12IdxChild : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxChildI

def psP12IdxMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxMajorI

def psP12IdxCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12IdxAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12IdxCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12IdxAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12IdxTargetAt (index : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12IdxTarget index

def psP12IdxMotiveAt
    (index : PsKernelCoreExpr)
    (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12IdxMotive index)
    major

def psP12IdxNodeOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12IdxNode psP12IdxLevels)
      psP12IdxIndex)
    psP12IdxChild

def psP12IdxFamilyType : PsKernelCoreExpr :=
  psP12IdxCloseForall psP12IdxIndexI psP12IdxSmallSort psP12IdxSort1

def psP12IdxFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12IdxFamily
    levelParams := PsKernelCoreList.nil
    type := psP12IdxFamilyType
  }
  numParams := 0
  numIndices := 1
  all := PsKernelCoreList.cons psP12IdxFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12IdxNode PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12IdxCtorType : PsKernelCoreExpr :=
  psP12IdxCloseForall psP12IdxIndexI psP12IdxSmallSort
    (psP12IdxCloseForall psP12IdxChildI (psP12IdxTargetAt psP12IdxIndex)
      (psP12IdxTargetAt psP12IdxIndex))

def psP12IdxCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12IdxNode
    levelParams := PsKernelCoreList.nil
    type := psP12IdxCtorType
  }
  induct := psP12IdxFamily
  cidx := 0
  numParams := 0
  numFields := 2
  isUnsafe := false
}

def psP12IdxConstructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12IdxCtor PsKernelCoreList.nil

def psP12IdxMotiveType : PsKernelCoreExpr :=
  psP12IdxCloseForall psP12IdxIndexI psP12IdxSmallSort
    (psP12IdxCloseForall psP12IdxMajorI (psP12IdxTargetAt psP12IdxIndex)
      psP12IdxSort1)

def psP12IdxIhType : PsKernelCoreExpr :=
  psP12IdxMotiveAt psP12IdxIndex psP12IdxChild

def psP12IdxMinorType : PsKernelCoreExpr :=
  psP12IdxCloseForall psP12IdxIndexI psP12IdxSmallSort
    (psP12IdxCloseForall psP12IdxChildI (psP12IdxTargetAt psP12IdxIndex)
      (psP12IdxCloseForall psP12IdxIhI psP12IdxIhType
        (psP12IdxMotiveAt psP12IdxIndex psP12IdxNodeOpen)))

def psP12IdxRecType : PsKernelCoreExpr :=
  psP12IdxCloseForall psP12IdxMotiveI psP12IdxMotiveType
    (psP12IdxCloseForall psP12IdxMinorI psP12IdxMinorType
      (psP12IdxCloseForall psP12IdxIndexI psP12IdxSmallSort
        (psP12IdxCloseForall psP12IdxMajorI (psP12IdxTargetAt psP12IdxIndex)
          (psP12IdxMotiveAt psP12IdxIndex psP12IdxMajor))))

def psP12IdxRecPrefix : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12IdxRec psP12IdxLevels)
      psP12IdxMotive)
    psP12IdxMinor

def psP12IdxRecursiveCall : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12IdxRecPrefix psP12IdxIndex)
    psP12IdxChild

def psP12IdxRuleBody : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app psP12IdxMinor psP12IdxIndex)
      psP12IdxChild)
    psP12IdxRecursiveCall

def psP12IdxRuleRhs : PsKernelCoreExpr :=
  psP12IdxCloseLam psP12IdxMotiveI psP12IdxMotiveType
    (psP12IdxCloseLam psP12IdxMinorI psP12IdxMinorType
      (psP12IdxCloseLam psP12IdxIndexI psP12IdxSmallSort
        (psP12IdxCloseLam psP12IdxChildI (psP12IdxTargetAt psP12IdxIndex)
          psP12IdxRuleBody)))

def psP12IdxRecInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12IdxRec
    levelParams := PsKernelCoreList.nil
    type := psP12IdxRecType
  }
  all := PsKernelCoreList.cons psP12IdxFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 1
  numMotives := 1
  numMinors := 1
  rules :=
    PsKernelCoreList.cons
      { ctor := psP12IdxNode, nFields := 2, rhs := psP12IdxRuleRhs }
      PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psP12IndexedAdmission : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      512 psKernelCoreEnvironmentEmpty psP12IdxFamilyInfo psP12IdxConstructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("indexed family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreEnvironmentFind? familyEnv psP12IdxFamily with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo storedFamily) =>
          if storedFamily.isRec then
            if storedFamily.isReflexive then
              PsKernelCoreResult.error "indexed family was incorrectly classified reflexive"
            else
              match psKernelCoreAddRecursor 1024 familyEnv psP12IdxRecInfo with
              | PsKernelCoreResult.error message => PsKernelCoreResult.error message
              | PsKernelCoreResult.ok env =>
                  match psKernelCoreEnvironmentFind? env psP12IdxRec with
                  | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo info) =>
                      if psKernelCoreNameEq info.base.name psP12IdxRec then
                        PsKernelCoreResult.ok Unit.unit
                      else
                        PsKernelCoreResult.error "stored indexed recursor name mismatch"
                  | _ => PsKernelCoreResult.error "indexed recursor was not stored"
          else
            PsKernelCoreResult.error "indexed family was not classified recursive"
      | _ => PsKernelCoreResult.error "indexed family metadata missing"

def main : IO Unit := do
  match psP12IndexedAdmission with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_ADMISSION: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_ADMISSION: FAIL: " ++ message))
