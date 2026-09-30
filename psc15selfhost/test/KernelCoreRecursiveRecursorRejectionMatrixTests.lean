import Ps.KernelCore

def psP12MatAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12MatFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "Phase12MatrixList"

def psP12MatNil : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatFamily "nil"

def psP12MatCons : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatFamily "cons"

def psP12MatRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatFamily "rec"

def psP12MatMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatMotive"

def psP12MatMinorNilI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatMinorNil"

def psP12MatMinorConsI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatMinorCons"

def psP12MatTailI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatTail"

def psP12MatIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatIh"

def psP12MatIh2I : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatIh2"

def psP12MatMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatMajor"

def psP12MatExtraI : PsKernelCoreName :=
  PsKernelCoreName.str psP12MatAnon "_p12MatExtra"

def psP12MatLevels : PsKernelCoreList PsKernelCoreLevel := PsKernelCoreList.nil

def psP12MatSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12MatTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12MatFamily psP12MatLevels

def psP12MatNilExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12MatNil psP12MatLevels

def psP12MatMotive : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12MatMotiveI

def psP12MatMinorNil : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12MatMinorNilI

def psP12MatMinorCons : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12MatMinorConsI

def psP12MatTail : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12MatTailI

def psP12MatMajor : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12MatMajorI

def psP12MatCloseForall
    (internalName : PsKernelCoreName)
    (type body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12MatAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12MatCloseLam
    (internalName : PsKernelCoreName)
    (type body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12MatAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12MatConsOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12MatCons psP12MatLevels)
    psP12MatTail

def psP12MatFamilyInfo : PsKernelCoreInductiveInfo := {
  base := { name := psP12MatFamily, levelParams := PsKernelCoreList.nil, type := psP12MatSort1 }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12MatFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12MatNil
    (PsKernelCoreList.cons psP12MatCons PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12MatNilCtor : PsKernelCoreConstructorInfo := {
  base := { name := psP12MatNil, levelParams := PsKernelCoreList.nil, type := psP12MatTarget }
  induct := psP12MatFamily
  cidx := 0
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psP12MatConsCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12MatCons
    levelParams := PsKernelCoreList.nil
    type := PsKernelCoreExpr.forallE psP12MatAnon psP12MatTarget psP12MatTarget
      PsKernelCoreBinderInfo.default
  }
  induct := psP12MatFamily
  cidx := 1
  numParams := 0
  numFields := 1
  isUnsafe := false
}

def psP12MatCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12MatNilCtor
    (PsKernelCoreList.cons psP12MatConsCtor PsKernelCoreList.nil)

def psP12MatMotiveType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatMajorI psP12MatTarget psP12MatSort1

def psP12MatCanonicalNilType : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12MatMotive psP12MatNilExpr

def psP12MatExtraNilType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatExtraI psP12MatCanonicalNilType psP12MatCanonicalNilType

def psP12MatCanonicalConsType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatTailI psP12MatTarget
    (psP12MatCloseForall psP12MatIhI
      (PsKernelCoreExpr.app psP12MatMotive psP12MatTail)
      (PsKernelCoreExpr.app psP12MatMotive psP12MatConsOpen))

def psP12MatMissingIhConsType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatTailI psP12MatTarget
    (PsKernelCoreExpr.app psP12MatMotive psP12MatConsOpen)

def psP12MatExtraIhConsType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatTailI psP12MatTarget
    (psP12MatCloseForall psP12MatIhI
      (PsKernelCoreExpr.app psP12MatMotive psP12MatTail)
      (psP12MatCloseForall psP12MatIh2I
        (PsKernelCoreExpr.app psP12MatMotive psP12MatTail)
        (PsKernelCoreExpr.app psP12MatMotive psP12MatConsOpen)))

def psP12MatWrongMotiveConsType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatTailI psP12MatTarget
    (psP12MatCloseForall psP12MatIhI
      (PsKernelCoreExpr.app psP12MatMotive psP12MatConsOpen)
      (PsKernelCoreExpr.app psP12MatMotive psP12MatConsOpen))

def psP12MatForgedResultConsType : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatTailI psP12MatTarget
    (psP12MatCloseForall psP12MatIhI
      (PsKernelCoreExpr.app psP12MatMotive psP12MatTail)
      (PsKernelCoreExpr.app psP12MatMotive psP12MatTail))

def psP12MatRecType
    (nilType consType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12MatCloseForall psP12MatMotiveI psP12MatMotiveType
    (psP12MatCloseForall psP12MatMinorNilI nilType
      (psP12MatCloseForall psP12MatMinorConsI consType
        (psP12MatCloseForall psP12MatMajorI psP12MatTarget
          (PsKernelCoreExpr.app psP12MatMotive psP12MatMajor))))

def psP12MatRecPrefix : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psP12MatRec psP12MatLevels)
        psP12MatMotive)
      psP12MatMinorNil)
    psP12MatMinorCons

def psP12MatNilRuleRhs
    (nilType consType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  psP12MatCloseLam psP12MatMotiveI psP12MatMotiveType
    (psP12MatCloseLam psP12MatMinorNilI nilType
      (psP12MatCloseLam psP12MatMinorConsI consType psP12MatMinorNil))

def psP12MatConsRuleRhs
    (nilType consType : PsKernelCoreExpr) : PsKernelCoreExpr :=
  let recursiveCall := PsKernelCoreExpr.app psP12MatRecPrefix psP12MatTail;
  let body :=
    PsKernelCoreExpr.app
      (PsKernelCoreExpr.app psP12MatMinorCons psP12MatTail)
      recursiveCall;
  psP12MatCloseLam psP12MatMotiveI psP12MatMotiveType
    (psP12MatCloseLam psP12MatMinorNilI nilType
      (psP12MatCloseLam psP12MatMinorConsI consType
        (psP12MatCloseLam psP12MatTailI psP12MatTarget body)))

def psP12MatRecInfo
    (nilType consType : PsKernelCoreExpr) : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12MatRec
    levelParams := PsKernelCoreList.nil
    type := psP12MatRecType nilType consType
  }
  all := PsKernelCoreList.cons psP12MatFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons
    { ctor := psP12MatNil, nFields := 0, rhs := psP12MatNilRuleRhs nilType consType }
    (PsKernelCoreList.cons
      { ctor := psP12MatCons, nFields := 1, rhs := psP12MatConsRuleRhs nilType consType }
      PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psP12MatRejected
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psP12MatForgedFamilyEnv
    (familyEnv : PsKernelCoreEnvironment) : PsKernelCoreEnvironment :=
  match psKernelCoreEnvironmentFind? familyEnv psP12MatFamily with
  | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo stored) =>
      let forged : PsKernelCoreInductiveInfo := {
        base := stored.base
        numParams := stored.numParams
        numIndices := stored.numIndices
        all := stored.all
        ctors := stored.ctors
        numNested := stored.numNested
        isRec := stored.isRec
        isReflexive := true
        isUnsafe := stored.isUnsafe
      };
      psKernelCoreEnvironmentReplaceUnchecked familyEnv
        (PsKernelCoreConstantInfo.inductInfo forged)
  | _ => familyEnv

def psP12MatChecks : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty psP12MatFamilyInfo psP12MatCtors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("rejection-matrix family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      let canonical := psP12MatRecInfo psP12MatCanonicalNilType psP12MatCanonicalConsType;
      match psKernelCoreAddRecursor 768 familyEnv canonical with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error ("canonical recursor rejected: " ++ message)
      | PsKernelCoreResult.ok _ =>
          let extraNil :=
            psKernelCoreAddRecursor 768 familyEnv
              (psP12MatRecInfo psP12MatExtraNilType psP12MatCanonicalConsType);
          let missingIh :=
            psKernelCoreAddRecursor 768 familyEnv
              (psP12MatRecInfo psP12MatCanonicalNilType psP12MatMissingIhConsType);
          let extraIh :=
            psKernelCoreAddRecursor 768 familyEnv
              (psP12MatRecInfo psP12MatCanonicalNilType psP12MatExtraIhConsType);
          let wrongMotive :=
            psKernelCoreAddRecursor 768 familyEnv
              (psP12MatRecInfo psP12MatCanonicalNilType psP12MatWrongMotiveConsType);
          let forgedResult :=
            psKernelCoreAddRecursor 768 familyEnv
              (psP12MatRecInfo psP12MatCanonicalNilType psP12MatForgedResultConsType);
          let forgedFlags :=
            psKernelCoreAddRecursor 768 (psP12MatForgedFamilyEnv familyEnv) canonical;
          if psP12MatRejected extraNil && psP12MatRejected missingIh &&
              psP12MatRejected extraIh && psP12MatRejected wrongMotive &&
              psP12MatRejected forgedResult && psP12MatRejected forgedFlags then
            if psKernelCoreEnvironmentContains familyEnv psP12MatRec then
              PsKernelCoreResult.error "failed admission mutated the caller environment"
            else
              PsKernelCoreResult.ok Unit.unit
          else
            PsKernelCoreResult.error "one or more recursive rejection-matrix cases were accepted"

def main : IO Unit := do
  match psP12MatChecks with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_REJECTION_MATRIX: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError ("PSC2_KERNEL_CORE_PHASE12_REJECTION_MATRIX: FAIL: " ++ message))
