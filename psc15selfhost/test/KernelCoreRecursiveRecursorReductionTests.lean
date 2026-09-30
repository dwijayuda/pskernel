import Ps.KernelCore

def psP12RedAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12RedFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "Phase12ReduceList"

def psP12RedNil : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedFamily "nil"

def psP12RedCons : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedFamily "cons"

def psP12RedRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedFamily "rec"

def psP12RedMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "_p12RedMotive"

def psP12RedMinorNilI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "_p12RedMinorNil"

def psP12RedMinorConsI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "_p12RedMinorCons"

def psP12RedTailI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "_p12RedTail"

def psP12RedIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "_p12RedIh"

def psP12RedMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12RedAnon "_p12RedMajor"

def psP12RedSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12RedLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12RedTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12RedFamily psP12RedLevels

def psP12RedNilExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12RedNil psP12RedLevels

def psP12RedMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12RedMotiveI

def psP12RedMinorNil : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12RedMinorNilI

def psP12RedMinorCons : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12RedMinorConsI

def psP12RedTail : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12RedTailI

def psP12RedIh : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12RedIhI

def psP12RedMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12RedMajorI

def psP12RedCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12RedAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12RedCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12RedAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12RedConsOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12RedCons psP12RedLevels)
    psP12RedTail

def psP12RedFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12RedFamily
    levelParams := PsKernelCoreList.nil
    type := psP12RedSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12RedFamily PsKernelCoreList.nil
  ctors :=
    PsKernelCoreList.cons psP12RedNil
      (PsKernelCoreList.cons psP12RedCons PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12RedNilCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12RedNil
    levelParams := PsKernelCoreList.nil
    type := psP12RedTarget
  }
  induct := psP12RedFamily
  cidx := 0
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psP12RedConsCtorType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    psP12RedAnon psP12RedTarget psP12RedTarget PsKernelCoreBinderInfo.default

def psP12RedConsCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12RedCons
    levelParams := PsKernelCoreList.nil
    type := psP12RedConsCtorType
  }
  induct := psP12RedFamily
  cidx := 1
  numParams := 0
  numFields := 1
  isUnsafe := false
}

def psP12RedConstructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12RedNilCtor
    (PsKernelCoreList.cons psP12RedConsCtor PsKernelCoreList.nil)

def psP12RedMotiveType : PsKernelCoreExpr :=
  psP12RedCloseForall psP12RedMajorI psP12RedTarget psP12RedSort1

def psP12RedMinorNilType : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12RedMotive psP12RedNilExpr

def psP12RedMinorConsType : PsKernelCoreExpr :=
  psP12RedCloseForall psP12RedTailI psP12RedTarget
    (psP12RedCloseForall psP12RedIhI
      (PsKernelCoreExpr.app psP12RedMotive psP12RedTail)
      (PsKernelCoreExpr.app psP12RedMotive psP12RedConsOpen))

def psP12RedRecType : PsKernelCoreExpr :=
  psP12RedCloseForall psP12RedMotiveI psP12RedMotiveType
    (psP12RedCloseForall psP12RedMinorNilI psP12RedMinorNilType
      (psP12RedCloseForall psP12RedMinorConsI psP12RedMinorConsType
        (psP12RedCloseForall psP12RedMajorI psP12RedTarget
          (PsKernelCoreExpr.app psP12RedMotive psP12RedMajor))))

def psP12RedNilRuleRhs : PsKernelCoreExpr :=
  psP12RedCloseLam psP12RedMotiveI psP12RedMotiveType
    (psP12RedCloseLam psP12RedMinorNilI psP12RedMinorNilType
      (psP12RedCloseLam psP12RedMinorConsI psP12RedMinorConsType
        psP12RedMinorNil))

def psP12RedRecursiveCall : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psP12RedRec psP12RedLevels)
        psP12RedMotive)
      psP12RedMinorNil)
    psP12RedMinorCons

def psP12RedConsRuleBody : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12RedMinorCons psP12RedTail)
    (PsKernelCoreExpr.app psP12RedRecursiveCall psP12RedTail)

def psP12RedConsRuleRhs : PsKernelCoreExpr :=
  psP12RedCloseLam psP12RedMotiveI psP12RedMotiveType
    (psP12RedCloseLam psP12RedMinorNilI psP12RedMinorNilType
      (psP12RedCloseLam psP12RedMinorConsI psP12RedMinorConsType
        (psP12RedCloseLam psP12RedTailI psP12RedTarget psP12RedConsRuleBody)))

def psP12RedRecInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12RedRec
    levelParams := PsKernelCoreList.nil
    type := psP12RedRecType
  }
  all := PsKernelCoreList.cons psP12RedFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules :=
    PsKernelCoreList.cons
      { ctor := psP12RedNil, nFields := 0, rhs := psP12RedNilRuleRhs }
      (PsKernelCoreList.cons
        { ctor := psP12RedCons, nFields := 1, rhs := psP12RedConsRuleRhs }
        PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psP12RedConsExpr (tail : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12RedCons psP12RedLevels)
    tail

def psP12RedMotiveValue : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12RedAnon psP12RedTarget
    psP12RedTarget PsKernelCoreBinderInfo.default

def psP12RedMinorConsValue : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12RedAnon psP12RedTarget
    (PsKernelCoreExpr.lam psP12RedAnon psP12RedTarget
      (PsKernelCoreExpr.bvar 0) PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psP12RedNestedMajor : PsKernelCoreExpr :=
  psP12RedConsExpr (psP12RedConsExpr psP12RedNilExpr)

def psP12RedRecCall : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.app
          (PsKernelCoreExpr.const psP12RedRec psP12RedLevels)
          psP12RedMotiveValue)
        psP12RedNilExpr)
      psP12RedMinorConsValue)
    psP12RedNestedMajor

def psP12RedIsNil
    (result : PsKernelCoreResult String PsKernelCoreExpr) : Bool :=
  match result with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok value =>
      match value with
      | PsKernelCoreExpr.const name levels =>
          psKernelCoreNameEq name psP12RedNil &&
          match levels with
          | PsKernelCoreList.nil => true
          | PsKernelCoreList.cons _ _ => false
      | _ => false

def psP12RecursiveIota : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty psP12RedFamilyInfo psP12RedConstructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("recursive family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor 768 familyEnv psP12RedRecInfo with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error ("recursive recursor admission failed: " ++ message)
      | PsKernelCoreResult.ok recEnv =>
          let reduced :=
            psKernelCoreWhnf 1024 recEnv psKernelCoreLocalContextEmpty psP12RedRecCall;
          if psP12RedIsNil reduced then
            PsKernelCoreResult.ok Unit.unit
          else
            PsKernelCoreResult.error
              "nested recursive iota did not evaluate embedded self-calls to nil"

def main : IO Unit := do
  match psP12RecursiveIota with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_RECURSIVE_IOTA: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_RECURSIVE_IOTA: FAIL: " ++ message))
