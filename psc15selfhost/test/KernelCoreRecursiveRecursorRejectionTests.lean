import Ps.KernelCore

def psP12RAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12RFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "Phase12RejectList"

def psP12RNil : PsKernelCoreName :=
  PsKernelCoreName.str psP12RFamily "nil"

def psP12RCons : PsKernelCoreName :=
  PsKernelCoreName.str psP12RFamily "cons"

def psP12RRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12RFamily "rec"

def psP12RFakeRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "Phase12FakeRec"

def psP12RMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "_p12RejectMotive"

def psP12RMinorNilI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "_p12RejectMinorNil"

def psP12RMinorConsI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "_p12RejectMinorCons"

def psP12RTailI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "_p12RejectTail"

def psP12RIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "_p12RejectIh"

def psP12RMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RAnon "_p12RejectMajor"

def psP12RSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12RTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12RFamily PsKernelCoreList.nil

def psP12RNilExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12RNil PsKernelCoreList.nil

def psP12RMotive : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12RMotiveI

def psP12RMinorNil : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12RMinorNilI

def psP12RMinorCons : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12RMinorConsI

def psP12RTail : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12RTailI

def psP12RMajor : PsKernelCoreExpr := PsKernelCoreExpr.fvar psP12RMajorI

def psP12RCloseForall
    (internalName : PsKernelCoreName)
    (type body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12RAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12RCloseLam
    (internalName : PsKernelCoreName)
    (type body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12RAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12RConsOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12RCons PsKernelCoreList.nil)
    psP12RTail

def psP12RFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12RFamily
    levelParams := PsKernelCoreList.nil
    type := psP12RSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12RFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12RNil
    (PsKernelCoreList.cons psP12RCons PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12RNilCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12RNil
    levelParams := PsKernelCoreList.nil
    type := psP12RTarget
  }
  induct := psP12RFamily
  cidx := 0
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psP12RConsCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12RCons
    levelParams := PsKernelCoreList.nil
    type := PsKernelCoreExpr.forallE
      psP12RAnon psP12RTarget psP12RTarget PsKernelCoreBinderInfo.default
  }
  induct := psP12RFamily
  cidx := 1
  numParams := 0
  numFields := 1
  isUnsafe := false
}

def psP12RCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12RNilCtor
    (PsKernelCoreList.cons psP12RConsCtor PsKernelCoreList.nil)

def psP12RMotiveType : PsKernelCoreExpr :=
  psP12RCloseForall psP12RMajorI psP12RTarget psP12RSort1

def psP12RMinorNilType : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12RMotive psP12RNilExpr

def psP12RMinorConsType : PsKernelCoreExpr :=
  psP12RCloseForall psP12RTailI psP12RTarget
    (psP12RCloseForall psP12RIhI
      (PsKernelCoreExpr.app psP12RMotive psP12RTail)
      (PsKernelCoreExpr.app psP12RMotive psP12RConsOpen))

def psP12RRecType : PsKernelCoreExpr :=
  psP12RCloseForall psP12RMotiveI psP12RMotiveType
    (psP12RCloseForall psP12RMinorNilI psP12RMinorNilType
      (psP12RCloseForall psP12RMinorConsI psP12RMinorConsType
        (psP12RCloseForall psP12RMajorI psP12RTarget
          (PsKernelCoreExpr.app psP12RMotive psP12RMajor))))

def psP12RNilRule : PsKernelCoreRecursorRule := {
  ctor := psP12RNil
  nFields := 0
  rhs := psP12RCloseLam psP12RMotiveI psP12RMotiveType
    (psP12RCloseLam psP12RMinorNilI psP12RMinorNilType
      (psP12RCloseLam psP12RMinorConsI psP12RMinorConsType psP12RMinorNil))
}

def psP12RForgedRecursiveCall : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psP12RFakeRec PsKernelCoreList.nil)
        psP12RMotive)
      psP12RMinorNil)
    psP12RMinorCons

def psP12RCanonicalRecursiveCall : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psP12RRec PsKernelCoreList.nil)
        psP12RMotive)
      psP12RMinorNil)
    psP12RMinorCons

def psP12RConsRule : PsKernelCoreRecursorRule := {
  ctor := psP12RCons
  nFields := 1
  rhs := psP12RCloseLam psP12RMotiveI psP12RMotiveType
    (psP12RCloseLam psP12RMinorNilI psP12RMinorNilType
      (psP12RCloseLam psP12RMinorConsI psP12RMinorConsType
        (psP12RCloseLam psP12RTailI psP12RTarget
          (PsKernelCoreExpr.app
            (PsKernelCoreExpr.app psP12RMinorCons psP12RTail)
            (PsKernelCoreExpr.app psP12RForgedRecursiveCall psP12RTail)))))
}

def psP12RMissingRecursiveCallRule : PsKernelCoreRecursorRule := {
  ctor := psP12RCons
  nFields := 1
  rhs := psP12RCloseLam psP12RMotiveI psP12RMotiveType
    (psP12RCloseLam psP12RMinorNilI psP12RMinorNilType
      (psP12RCloseLam psP12RMinorConsI psP12RMinorConsType
        (psP12RCloseLam psP12RTailI psP12RTarget
          (PsKernelCoreExpr.app psP12RMinorCons psP12RTail))))
}

def psP12RExtraRecursiveCallRule : PsKernelCoreRecursorRule := {
  ctor := psP12RCons
  nFields := 1
  rhs := psP12RCloseLam psP12RMotiveI psP12RMotiveType
    (psP12RCloseLam psP12RMinorNilI psP12RMinorNilType
      (psP12RCloseLam psP12RMinorConsI psP12RMinorConsType
        (psP12RCloseLam psP12RTailI psP12RTarget
          (PsKernelCoreExpr.app
            (PsKernelCoreExpr.app
              (PsKernelCoreExpr.app psP12RMinorCons psP12RTail)
              (PsKernelCoreExpr.app psP12RCanonicalRecursiveCall psP12RTail))
            (PsKernelCoreExpr.app psP12RCanonicalRecursiveCall psP12RTail)))))
}

def psP12RRecInfoWithConsRule
    (consRule : PsKernelCoreRecursorRule) : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12RRec
    levelParams := PsKernelCoreList.nil
    type := psP12RRecType
  }
  all := PsKernelCoreList.cons psP12RFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons psP12RNilRule
    (PsKernelCoreList.cons consRule PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psP12RRecInfo : PsKernelCoreRecursorInfo :=
  psP12RRecInfoWithConsRule psP12RConsRule

def psP12RFakeRecInfo : PsKernelCoreAxiomInfo := {
  base := {
    name := psP12RFakeRec
    levelParams := PsKernelCoreList.nil
    type := psP12RRecType
  }
  isUnsafe := false
}

def psP12RRejected
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psP12RRejectionChecks : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      256 psKernelCoreEnvironmentEmpty psP12RFamilyInfo psP12RCtors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("rejection family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      let forgedEnv :=
        psKernelCoreEnvironmentAddUnchecked familyEnv
          (PsKernelCoreConstantInfo.axiomInfo psP12RFakeRecInfo);
      let wrongTarget := psKernelCoreAddRecursor 512 forgedEnv psP12RRecInfo;
      let missingCall :=
        psKernelCoreAddRecursor 512 familyEnv
          (psP12RRecInfoWithConsRule psP12RMissingRecursiveCallRule);
      let extraCall :=
        psKernelCoreAddRecursor 512 familyEnv
          (psP12RRecInfoWithConsRule psP12RExtraRecursiveCallRule);
      if psP12RRejected wrongTarget then
        if psP12RRejected missingCall then
          if psP12RRejected extraCall then
            PsKernelCoreResult.ok Unit.unit
          else
            PsKernelCoreResult.error "extra recursive call was accepted"
        else
          PsKernelCoreResult.error "missing recursive call was accepted"
      else
        PsKernelCoreResult.error "forged recursive-call target was accepted"

def main : IO Unit := do
  match psP12RRejectionChecks with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_REJECTION: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_REJECTION: FAIL: " ++ message))
