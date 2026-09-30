import Ps.KernelCore

def psP12MultiAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12MultiFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "Phase12Binary"

def psP12MultiNode : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiFamily "node"

def psP12MultiRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiFamily "rec"

def psP12MultiMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiMotive"

def psP12MultiMinorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiMinor"

def psP12MultiLeftI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiLeft"

def psP12MultiRightI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiRight"

def psP12MultiLeftIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiLeftIh"

def psP12MultiRightIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiRightIh"

def psP12MultiMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MultiAnon "_p12MultiMajor"

def psP12MultiLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12MultiSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12MultiTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12MultiFamily psP12MultiLevels

def psP12MultiMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiMotiveI

def psP12MultiMinor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiMinorI

def psP12MultiLeft : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiLeftI

def psP12MultiRight : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiRightI

def psP12MultiLeftIh : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiLeftIhI

def psP12MultiRightIh : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiRightIhI

def psP12MultiMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MultiMajorI

def psP12MultiCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12MultiAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12MultiCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12MultiAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12MultiNodeOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12MultiNode psP12MultiLevels)
      psP12MultiLeft)
    psP12MultiRight

def psP12MultiFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12MultiFamily
    levelParams := PsKernelCoreList.nil
    type := psP12MultiSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12MultiFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12MultiNode PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12MultiNodeType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12MultiAnon psP12MultiTarget
    (PsKernelCoreExpr.forallE psP12MultiAnon psP12MultiTarget psP12MultiTarget
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psP12MultiNodeCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12MultiNode
    levelParams := PsKernelCoreList.nil
    type := psP12MultiNodeType
  }
  induct := psP12MultiFamily
  cidx := 0
  numParams := 0
  numFields := 2
  isUnsafe := false
}

def psP12MultiConstructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12MultiNodeCtor PsKernelCoreList.nil

def psP12MultiMotiveType : PsKernelCoreExpr :=
  psP12MultiCloseForall psP12MultiMajorI psP12MultiTarget psP12MultiSort1

def psP12MultiValidMinorType : PsKernelCoreExpr :=
  psP12MultiCloseForall psP12MultiLeftI psP12MultiTarget
    (psP12MultiCloseForall psP12MultiRightI psP12MultiTarget
      (psP12MultiCloseForall psP12MultiLeftIhI
        (PsKernelCoreExpr.app psP12MultiMotive psP12MultiLeft)
        (psP12MultiCloseForall psP12MultiRightIhI
          (PsKernelCoreExpr.app psP12MultiMotive psP12MultiRight)
          (PsKernelCoreExpr.app psP12MultiMotive psP12MultiNodeOpen))))

def psP12MultiSwappedMinorType : PsKernelCoreExpr :=
  psP12MultiCloseForall psP12MultiLeftI psP12MultiTarget
    (psP12MultiCloseForall psP12MultiRightI psP12MultiTarget
      (psP12MultiCloseForall psP12MultiRightIhI
        (PsKernelCoreExpr.app psP12MultiMotive psP12MultiRight)
        (psP12MultiCloseForall psP12MultiLeftIhI
          (PsKernelCoreExpr.app psP12MultiMotive psP12MultiLeft)
          (PsKernelCoreExpr.app psP12MultiMotive psP12MultiNodeOpen))))

def psP12MultiMissingMinorType : PsKernelCoreExpr :=
  psP12MultiCloseForall psP12MultiLeftI psP12MultiTarget
    (psP12MultiCloseForall psP12MultiRightI psP12MultiTarget
      (psP12MultiCloseForall psP12MultiLeftIhI
        (PsKernelCoreExpr.app psP12MultiMotive psP12MultiLeft)
        (PsKernelCoreExpr.app psP12MultiMotive psP12MultiNodeOpen)))

def psP12MultiRecType
    (minorType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12MultiCloseForall psP12MultiMotiveI psP12MultiMotiveType
    (psP12MultiCloseForall psP12MultiMinorI minorType
      (psP12MultiCloseForall psP12MultiMajorI psP12MultiTarget
        (PsKernelCoreExpr.app psP12MultiMotive psP12MultiMajor)))

def psP12MultiRecPrefix : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12MultiRec psP12MultiLevels)
      psP12MultiMotive)
    psP12MultiMinor

def psP12MultiRuleBody : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.app psP12MultiMinor psP12MultiLeft)
        psP12MultiRight)
      (PsKernelCoreExpr.app psP12MultiRecPrefix psP12MultiLeft))
    (PsKernelCoreExpr.app psP12MultiRecPrefix psP12MultiRight)

def psP12MultiRuleRhs : PsKernelCoreExpr :=
  psP12MultiCloseLam psP12MultiMotiveI psP12MultiMotiveType
    (psP12MultiCloseLam psP12MultiMinorI psP12MultiValidMinorType
      (psP12MultiCloseLam psP12MultiLeftI psP12MultiTarget
        (psP12MultiCloseLam psP12MultiRightI psP12MultiTarget psP12MultiRuleBody)))

def psP12MultiRecInfo
    (minorType : PsKernelCoreExpr) : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12MultiRec
    levelParams := PsKernelCoreList.nil
    type := psP12MultiRecType minorType
  }
  all := PsKernelCoreList.cons psP12MultiFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 1
  rules := PsKernelCoreList.cons
    { ctor := psP12MultiNode, nFields := 2, rhs := psP12MultiRuleRhs }
    PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psP12MultiRejected
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psP12MultiChecks : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty psP12MultiFamilyInfo psP12MultiConstructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("multi-field family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor
          768 familyEnv (psP12MultiRecInfo psP12MultiValidMinorType) with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error ("valid multi-field recursor rejected: " ++ message)
      | PsKernelCoreResult.ok _ =>
          let swapped :=
            psKernelCoreAddRecursor
              768 familyEnv (psP12MultiRecInfo psP12MultiSwappedMinorType);
          let missing :=
            psKernelCoreAddRecursor
              768 familyEnv (psP12MultiRecInfo psP12MultiMissingMinorType);
          if psP12MultiRejected swapped then
            if psP12MultiRejected missing then
              PsKernelCoreResult.ok Unit.unit
            else
              PsKernelCoreResult.error "missing second IH was accepted"
          else
            PsKernelCoreResult.error "swapped IH order was accepted"

def main : IO Unit := do
  match psP12MultiChecks with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_MULTI_RECURSIVE_FIELDS: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_MULTI_RECURSIVE_FIELDS: FAIL: " ++ message))
