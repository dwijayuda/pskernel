import Ps.KernelCore

def psP12IdxRejAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12IdxRejFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "Phase12IndexedReject"

def psP12IdxRejNode : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejFamily "node"

def psP12IdxRejRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejFamily "rec"

def psP12IdxRejMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "_p12IdxRejMotive"

def psP12IdxRejMinorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "_p12IdxRejMinor"

def psP12IdxRejIndexI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "_p12IdxRejIndex"

def psP12IdxRejChildI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "_p12IdxRejChild"

def psP12IdxRejIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "_p12IdxRejIh"

def psP12IdxRejMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12IdxRejAnon "_p12IdxRejMajor"

def psP12IdxRejSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12IdxRejSmallSort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP12IdxRejLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12IdxRejTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12IdxRejFamily psP12IdxRejLevels

def psP12IdxRejMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxRejMotiveI

def psP12IdxRejMinor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxRejMinorI

def psP12IdxRejIndex : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxRejIndexI

def psP12IdxRejChild : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxRejChildI

def psP12IdxRejMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IdxRejMajorI

def psP12IdxRejCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12IdxRejAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12IdxRejCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12IdxRejAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12IdxRejTargetAt (index : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12IdxRejTarget index

def psP12IdxRejMotiveAt
    (index : PsKernelCoreExpr)
    (major : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12IdxRejMotive index)
    major

def psP12IdxRejWrappedIndex : PsKernelCoreExpr :=
  PsKernelCoreExpr.letE psP12IdxRejAnon psP12IdxRejSmallSort
    psP12IdxRejIndex (PsKernelCoreExpr.bvar 0) false

def psP12IdxRejNodeOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12IdxRejNode psP12IdxRejLevels)
      psP12IdxRejIndex)
    psP12IdxRejChild

def psP12IdxRejFamilyType : PsKernelCoreExpr :=
  psP12IdxRejCloseForall psP12IdxRejIndexI psP12IdxRejSmallSort psP12IdxRejSort1

def psP12IdxRejFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12IdxRejFamily
    levelParams := PsKernelCoreList.nil
    type := psP12IdxRejFamilyType
  }
  numParams := 0
  numIndices := 1
  all := PsKernelCoreList.cons psP12IdxRejFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12IdxRejNode PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12IdxRejCtorType : PsKernelCoreExpr :=
  psP12IdxRejCloseForall psP12IdxRejIndexI psP12IdxRejSmallSort
    (psP12IdxRejCloseForall psP12IdxRejChildI
      (psP12IdxRejTargetAt psP12IdxRejIndex)
      (psP12IdxRejTargetAt psP12IdxRejIndex))

def psP12IdxRejCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12IdxRejNode
    levelParams := PsKernelCoreList.nil
    type := psP12IdxRejCtorType
  }
  induct := psP12IdxRejFamily
  cidx := 0
  numParams := 0
  numFields := 2
  isUnsafe := false
}

def psP12IdxRejConstructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12IdxRejCtor PsKernelCoreList.nil

def psP12IdxRejMotiveType : PsKernelCoreExpr :=
  psP12IdxRejCloseForall psP12IdxRejIndexI psP12IdxRejSmallSort
    (psP12IdxRejCloseForall psP12IdxRejMajorI
      (psP12IdxRejTargetAt psP12IdxRejIndex)
      psP12IdxRejSort1)

def psP12IdxRejCanonicalIhType : PsKernelCoreExpr :=
  psP12IdxRejMotiveAt psP12IdxRejIndex psP12IdxRejChild

def psP12IdxRejForgedIhType : PsKernelCoreExpr :=
  psP12IdxRejMotiveAt psP12IdxRejWrappedIndex psP12IdxRejChild

def psP12IdxRejMinorType
    (ihType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12IdxRejCloseForall psP12IdxRejIndexI psP12IdxRejSmallSort
    (psP12IdxRejCloseForall psP12IdxRejChildI
      (psP12IdxRejTargetAt psP12IdxRejIndex)
      (psP12IdxRejCloseForall psP12IdxRejIhI ihType
        (psP12IdxRejMotiveAt psP12IdxRejIndex psP12IdxRejNodeOpen)))

def psP12IdxRejRecType
    (minorType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12IdxRejCloseForall psP12IdxRejMotiveI psP12IdxRejMotiveType
    (psP12IdxRejCloseForall psP12IdxRejMinorI minorType
      (psP12IdxRejCloseForall psP12IdxRejIndexI psP12IdxRejSmallSort
        (psP12IdxRejCloseForall psP12IdxRejMajorI
          (psP12IdxRejTargetAt psP12IdxRejIndex)
          (psP12IdxRejMotiveAt psP12IdxRejIndex psP12IdxRejMajor))))

def psP12IdxRejRecPrefix : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12IdxRejRec psP12IdxRejLevels)
      psP12IdxRejMotive)
    psP12IdxRejMinor

def psP12IdxRejRecursiveCall
    (index : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12IdxRejRecPrefix index)
    psP12IdxRejChild

def psP12IdxRejRuleRhs
    (minorType : PsKernelCoreExpr)
    (callIndex : PsKernelCoreExpr) : PsKernelCoreExpr :=
  let body :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.app psP12IdxRejMinor psP12IdxRejIndex)
        psP12IdxRejChild)
      (psP12IdxRejRecursiveCall callIndex);
  psP12IdxRejCloseLam psP12IdxRejMotiveI psP12IdxRejMotiveType
    (psP12IdxRejCloseLam psP12IdxRejMinorI minorType
      (psP12IdxRejCloseLam psP12IdxRejIndexI psP12IdxRejSmallSort
        (psP12IdxRejCloseLam psP12IdxRejChildI
          (psP12IdxRejTargetAt psP12IdxRejIndex) body)))

def psP12IdxRejRecInfo
    (minorType : PsKernelCoreExpr)
    (callIndex : PsKernelCoreExpr) : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12IdxRejRec
    levelParams := PsKernelCoreList.nil
    type := psP12IdxRejRecType minorType
  }
  all := PsKernelCoreList.cons psP12IdxRejFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 1
  numMotives := 1
  numMinors := 1
  rules := PsKernelCoreList.cons
    {
      ctor := psP12IdxRejNode
      nFields := 2
      rhs := psP12IdxRejRuleRhs minorType callIndex
    }
    PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psP12IdxRejRejected
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psP12IdxRejChecks : PsKernelCoreResult String Unit :=
  let canonicalMinor := psP12IdxRejMinorType psP12IdxRejCanonicalIhType;
  let forgedMinor := psP12IdxRejMinorType psP12IdxRejForgedIhType;
  match psKernelCoreAddRecursiveInductive
      512 psKernelCoreEnvironmentEmpty psP12IdxRejFamilyInfo psP12IdxRejConstructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("indexed rejection family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor
          1024 familyEnv
          (psP12IdxRejRecInfo canonicalMinor psP12IdxRejIndex) with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error ("canonical indexed recursor rejected: " ++ message)
      | PsKernelCoreResult.ok _ =>
          let forgedIh :=
            psKernelCoreAddRecursor
              1024 familyEnv
              (psP12IdxRejRecInfo forgedMinor psP12IdxRejIndex);
          let forgedCall :=
            psKernelCoreAddRecursor
              1024 familyEnv
              (psP12IdxRejRecInfo canonicalMinor psP12IdxRejWrappedIndex);
          if psP12IdxRejRejected forgedIh then
            if psP12IdxRejRejected forgedCall then
              PsKernelCoreResult.ok Unit.unit
            else
              PsKernelCoreResult.error
                "definitionally-equal but noncanonical recursive-call index was accepted"
          else
            PsKernelCoreResult.error
              "definitionally-equal but noncanonical IH index was accepted"

def main : IO Unit := do
  match psP12IdxRejChecks with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_REJECTION: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_INDEXED_RECURSOR_REJECTION: FAIL: " ++ message))
