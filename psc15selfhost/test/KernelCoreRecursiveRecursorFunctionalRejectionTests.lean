import Ps.KernelCore

def psP12FuncRejAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12FuncRejFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "Phase12FunctionalReject"

def psP12FuncRejNode : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejFamily "node"

def psP12FuncRejRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejFamily "rec"

def psP12FuncRejP : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "Phase12FunctionalRejectP"

def psP12FuncRejMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejMotive"

def psP12FuncRejMinorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejMinor"

def psP12FuncRejFieldI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejField"

def psP12FuncRejIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejIh"

def psP12FuncRejArgI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejArg"

def psP12FuncRejExtraI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejExtra"

def psP12FuncRejMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncRejAnon "_p12FuncRejMajor"

def psP12FuncRejSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12FuncRejSmallSort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP12FuncRejLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12FuncRejTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12FuncRejFamily psP12FuncRejLevels

def psP12FuncRejPExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12FuncRejP psP12FuncRejLevels

def psP12FuncRejMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncRejMotiveI

def psP12FuncRejMinor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncRejMinorI

def psP12FuncRejField : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncRejFieldI

def psP12FuncRejArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncRejArgI

def psP12FuncRejMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncRejMajorI

def psP12FuncRejCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12FuncRejAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12FuncRejCloseForallImplicit
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12FuncRejAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.implicit

def psP12FuncRejCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12FuncRejAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12FuncRejFieldType : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejArgI psP12FuncRejSmallSort psP12FuncRejTarget

def psP12FuncRejNodeOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12FuncRejNode psP12FuncRejLevels)
    psP12FuncRejField

def psP12FuncRejFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12FuncRejFamily
    levelParams := PsKernelCoreList.nil
    type := psP12FuncRejSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12FuncRejFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12FuncRejNode PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12FuncRejCtorType : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejFieldI psP12FuncRejFieldType psP12FuncRejTarget

def psP12FuncRejCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12FuncRejNode
    levelParams := PsKernelCoreList.nil
    type := psP12FuncRejCtorType
  }
  induct := psP12FuncRejFamily
  cidx := 0
  numParams := 0
  numFields := 1
  isUnsafe := false
}

def psP12FuncRejConstructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12FuncRejCtor PsKernelCoreList.nil

def psP12FuncRejMotiveType : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejMajorI psP12FuncRejTarget psP12FuncRejSort1

def psP12FuncRejFieldApp : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12FuncRejField psP12FuncRejArg

def psP12FuncRejCanonicalIhType : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejArgI psP12FuncRejSmallSort
    (PsKernelCoreExpr.app psP12FuncRejMotive psP12FuncRejFieldApp)

def psP12FuncRejMissingIhArgType : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12FuncRejMotive
    (PsKernelCoreExpr.app psP12FuncRejField psP12FuncRejPExpr)

def psP12FuncRejExtraIhArgType : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejArgI psP12FuncRejSmallSort
    (psP12FuncRejCloseForall psP12FuncRejExtraI psP12FuncRejSmallSort
      (PsKernelCoreExpr.app psP12FuncRejMotive psP12FuncRejFieldApp))

def psP12FuncRejWrongBinderIhType : PsKernelCoreExpr :=
  psP12FuncRejCloseForallImplicit psP12FuncRejArgI psP12FuncRejSmallSort
    (PsKernelCoreExpr.app psP12FuncRejMotive psP12FuncRejFieldApp)

def psP12FuncRejMinorType
    (ihType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejFieldI psP12FuncRejFieldType
    (psP12FuncRejCloseForall psP12FuncRejIhI ihType
      (PsKernelCoreExpr.app psP12FuncRejMotive psP12FuncRejNodeOpen))

def psP12FuncRejRecType
    (minorType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12FuncRejCloseForall psP12FuncRejMotiveI psP12FuncRejMotiveType
    (psP12FuncRejCloseForall psP12FuncRejMinorI minorType
      (psP12FuncRejCloseForall psP12FuncRejMajorI psP12FuncRejTarget
        (PsKernelCoreExpr.app psP12FuncRejMotive psP12FuncRejMajor)))

def psP12FuncRejRecPrefix : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12FuncRejRec psP12FuncRejLevels)
      psP12FuncRejMotive)
    psP12FuncRejMinor

def psP12FuncRejRecursiveCall : PsKernelCoreExpr :=
  psP12FuncRejCloseLam psP12FuncRejArgI psP12FuncRejSmallSort
    (PsKernelCoreExpr.app psP12FuncRejRecPrefix psP12FuncRejFieldApp)

def psP12FuncRejRuleRhs
    (minorType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  let body :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app psP12FuncRejMinor psP12FuncRejField)
      psP12FuncRejRecursiveCall;
  psP12FuncRejCloseLam psP12FuncRejMotiveI psP12FuncRejMotiveType
    (psP12FuncRejCloseLam psP12FuncRejMinorI minorType
      (psP12FuncRejCloseLam psP12FuncRejFieldI psP12FuncRejFieldType body))

def psP12FuncRejRecInfo
    (minorType : PsKernelCoreExpr) : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12FuncRejRec
    levelParams := PsKernelCoreList.nil
    type := psP12FuncRejRecType minorType
  }
  all := PsKernelCoreList.cons psP12FuncRejFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 1
  rules := PsKernelCoreList.cons
    {
      ctor := psP12FuncRejNode
      nFields := 1
      rhs := psP12FuncRejRuleRhs minorType
    }
    PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psP12FuncRejPInfo : PsKernelCoreAxiomInfo := {
  base := {
    name := psP12FuncRejP
    levelParams := PsKernelCoreList.nil
    type := psP12FuncRejSmallSort
  }
  isUnsafe := false
}

def psP12FuncRejRejected
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psP12FuncRejChecks : PsKernelCoreResult String Unit :=
  let startEnv :=
    psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.axiomInfo psP12FuncRejPInfo);
  let canonicalMinor := psP12FuncRejMinorType psP12FuncRejCanonicalIhType;
  let missingMinor := psP12FuncRejMinorType psP12FuncRejMissingIhArgType;
  let extraMinor := psP12FuncRejMinorType psP12FuncRejExtraIhArgType;
  let wrongBinderMinor := psP12FuncRejMinorType psP12FuncRejWrongBinderIhType;
  match psKernelCoreAddRecursiveInductive
      512 startEnv psP12FuncRejFamilyInfo psP12FuncRejConstructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("functional rejection family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor
          1024 familyEnv (psP12FuncRejRecInfo canonicalMinor) with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error ("canonical functional recursor rejected: " ++ message)
      | PsKernelCoreResult.ok _ =>
          let missing :=
            psKernelCoreAddRecursor 1024 familyEnv
              (psP12FuncRejRecInfo missingMinor);
          let extra :=
            psKernelCoreAddRecursor 1024 familyEnv
              (psP12FuncRejRecInfo extraMinor);
          let wrongBinder :=
            psKernelCoreAddRecursor 1024 familyEnv
              (psP12FuncRejRecInfo wrongBinderMinor);
          if psP12FuncRejRejected missing then
            if psP12FuncRejRejected extra then
              if psP12FuncRejRejected wrongBinder then
                PsKernelCoreResult.ok Unit.unit
              else
                PsKernelCoreResult.error "wrong functional IH binder mode was accepted"
            else
              PsKernelCoreResult.error "extra functional IH argument was accepted"
          else
            PsKernelCoreResult.error "missing functional IH argument was accepted"

def main : IO Unit := do
  match psP12FuncRejChecks with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_REJECTION: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_REJECTION: FAIL: " ++ message))
