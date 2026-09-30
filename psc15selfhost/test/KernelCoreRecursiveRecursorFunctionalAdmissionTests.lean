import Ps.KernelCore

def psP12FuncAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12FuncFamily : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "Phase12Functional"

def psP12FuncNode : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncFamily "node"

def psP12FuncRec : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncFamily "rec"

def psP12FuncMotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "_p12FuncMotive"

def psP12FuncMinorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "_p12FuncMinor"

def psP12FuncFieldI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "_p12FuncField"

def psP12FuncIhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "_p12FuncIh"

def psP12FuncArgI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "_p12FuncArg"

def psP12FuncMajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12FuncAnon "_p12FuncMajor"

def psP12FuncSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12FuncSmallSort : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort PsKernelCoreLevel.zero

def psP12FuncLevels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12FuncTarget : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12FuncFamily psP12FuncLevels

def psP12FuncMotive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncMotiveI

def psP12FuncMinor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncMinorI

def psP12FuncField : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncFieldI

def psP12FuncArg : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncArgI

def psP12FuncMajor : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12FuncMajorI

def psP12FuncCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12FuncAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12FuncCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12FuncAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12FuncFieldType : PsKernelCoreExpr :=
  psP12FuncCloseForall psP12FuncArgI psP12FuncSmallSort psP12FuncTarget

def psP12FuncNodeOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12FuncNode psP12FuncLevels)
    psP12FuncField

def psP12FuncFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12FuncFamily
    levelParams := PsKernelCoreList.nil
    type := psP12FuncSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12FuncFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psP12FuncNode PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12FuncCtorType : PsKernelCoreExpr :=
  psP12FuncCloseForall psP12FuncFieldI psP12FuncFieldType psP12FuncTarget

def psP12FuncCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12FuncNode
    levelParams := PsKernelCoreList.nil
    type := psP12FuncCtorType
  }
  induct := psP12FuncFamily
  cidx := 0
  numParams := 0
  numFields := 1
  isUnsafe := false
}

def psP12FuncConstructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12FuncCtor PsKernelCoreList.nil

def psP12FuncMotiveType : PsKernelCoreExpr :=
  psP12FuncCloseForall psP12FuncMajorI psP12FuncTarget psP12FuncSort1

def psP12FuncFieldApp : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12FuncField psP12FuncArg

def psP12FuncIhType : PsKernelCoreExpr :=
  psP12FuncCloseForall psP12FuncArgI psP12FuncSmallSort
    (PsKernelCoreExpr.app psP12FuncMotive psP12FuncFieldApp)

def psP12FuncMinorType : PsKernelCoreExpr :=
  psP12FuncCloseForall psP12FuncFieldI psP12FuncFieldType
    (psP12FuncCloseForall psP12FuncIhI psP12FuncIhType
      (PsKernelCoreExpr.app psP12FuncMotive psP12FuncNodeOpen))

def psP12FuncRecType : PsKernelCoreExpr :=
  psP12FuncCloseForall psP12FuncMotiveI psP12FuncMotiveType
    (psP12FuncCloseForall psP12FuncMinorI psP12FuncMinorType
      (psP12FuncCloseForall psP12FuncMajorI psP12FuncTarget
        (PsKernelCoreExpr.app psP12FuncMotive psP12FuncMajor)))

def psP12FuncRecPrefix : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.const psP12FuncRec psP12FuncLevels)
      psP12FuncMotive)
    psP12FuncMinor

def psP12FuncRecursiveCallBody : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12FuncRecPrefix psP12FuncFieldApp

def psP12FuncRecursiveCall : PsKernelCoreExpr :=
  psP12FuncCloseLam psP12FuncArgI psP12FuncSmallSort
    psP12FuncRecursiveCallBody

def psP12FuncRuleBody : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12FuncMinor psP12FuncField)
    psP12FuncRecursiveCall

def psP12FuncRuleRhs : PsKernelCoreExpr :=
  psP12FuncCloseLam psP12FuncMotiveI psP12FuncMotiveType
    (psP12FuncCloseLam psP12FuncMinorI psP12FuncMinorType
      (psP12FuncCloseLam psP12FuncFieldI psP12FuncFieldType
        psP12FuncRuleBody))

def psP12FuncRecInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12FuncRec
    levelParams := PsKernelCoreList.nil
    type := psP12FuncRecType
  }
  all := PsKernelCoreList.cons psP12FuncFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 1
  rules :=
    PsKernelCoreList.cons
      { ctor := psP12FuncNode, nFields := 1, rhs := psP12FuncRuleRhs }
      PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psP12FunctionalAdmission : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      384 psKernelCoreEnvironmentEmpty psP12FuncFamilyInfo psP12FuncConstructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("functional family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreEnvironmentFind? familyEnv psP12FuncFamily with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo storedFamily) =>
          if storedFamily.isRec then
            if storedFamily.isReflexive then
              match psKernelCoreAddRecursor 768 familyEnv psP12FuncRecInfo with
              | PsKernelCoreResult.error message => PsKernelCoreResult.error message
              | PsKernelCoreResult.ok env =>
                  match psKernelCoreEnvironmentFind? env psP12FuncRec with
                  | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo info) =>
                      if psKernelCoreNameEq info.base.name psP12FuncRec then
                        PsKernelCoreResult.ok Unit.unit
                      else
                        PsKernelCoreResult.error "stored functional recursor name mismatch"
                  | _ => PsKernelCoreResult.error "functional recursor was not stored"
            else
              PsKernelCoreResult.error "functional family was not classified reflexive"
          else
            PsKernelCoreResult.error "functional family was not classified recursive"
      | _ => PsKernelCoreResult.error "functional family metadata missing"

def main : IO Unit := do
  match psP12FunctionalAdmission with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_ADMISSION: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_FUNCTIONAL_RECURSOR_ADMISSION: FAIL: " ++ message))
