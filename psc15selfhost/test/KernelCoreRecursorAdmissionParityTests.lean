import Ps.KernelCore
import PSC1Kernel.Inductive

def psKcRecAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcRecTagged : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "Phase10Tagged"

def psKcRecBase : PsKernelCoreName := PsKernelCoreName.str psKcRecTagged "base"

def psKcRecExtra : PsKernelCoreName := PsKernelCoreName.str psKcRecTagged "extra"

def psKcRecName : PsKernelCoreName := PsKernelCoreName.str psKcRecTagged "rec"

def psKcRecUnrelated : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "phase10Unrelated"

def psKcRecAlphaI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10Alpha"

def psKcRecIndexI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10Index"

def psKcRecFieldI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10Field"

def psKcRecMotiveI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10Motive"

def psKcRecMinorBaseI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10MinorBase"

def psKcRecMinorExtraI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10MinorExtra"

def psKcRecMajorI : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "_phase10Major"

def psKcRecSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcRecAlpha : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecAlphaI

def psKcRecIndex : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecIndexI

def psKcRecField : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecFieldI

def psKcRecMotive : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecMotiveI

def psKcRecMinorBase : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecMinorBaseI

def psKcRecMinorExtra : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecMinorExtraI

def psKcRecMajor : PsKernelCoreExpr := PsKernelCoreExpr.fvar psKcRecMajorI

def psKcRecApp2
    (fn : PsKernelCoreExpr)
    (a : PsKernelCoreExpr)
    (b : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app (PsKernelCoreExpr.app fn a) b

def psKcRecApp3
    (fn : PsKernelCoreExpr)
    (a : PsKernelCoreExpr)
    (b : PsKernelCoreExpr)
    (c : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.app (psKcRecApp2 fn a b) c

def psKcRecCloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRecAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psKcRecCloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psKcRecAnon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psKcRecTaggedOpen : PsKernelCoreExpr :=
  psKcRecApp2
    (PsKernelCoreExpr.const psKcRecTagged PsKernelCoreList.nil)
    psKcRecAlpha psKcRecIndex

def psKcRecBaseOpen : PsKernelCoreExpr :=
  psKcRecApp2
    (PsKernelCoreExpr.const psKcRecBase PsKernelCoreList.nil)
    psKcRecAlpha psKcRecIndex

def psKcRecExtraOpen : PsKernelCoreExpr :=
  psKcRecApp3
    (PsKernelCoreExpr.const psKcRecExtra PsKernelCoreList.nil)
    psKcRecAlpha psKcRecIndex psKcRecField

def psKcRecTaggedType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecAlphaI psKcRecSort1
    (psKcRecCloseForall psKcRecIndexI psKcRecAlpha psKcRecSort1)

def psKcRecBaseType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecAlphaI psKcRecSort1
    (psKcRecCloseForall psKcRecIndexI psKcRecAlpha psKcRecTaggedOpen)

def psKcRecExtraType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecAlphaI psKcRecSort1
    (psKcRecCloseForall psKcRecIndexI psKcRecAlpha
      (psKcRecCloseForall psKcRecFieldI psKcRecAlpha psKcRecTaggedOpen))

def psKcRecFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcRecTagged
    levelParams := PsKernelCoreList.nil
    type := psKcRecTaggedType
  }
  numParams := 1
  numIndices := 1
  all := PsKernelCoreList.cons psKcRecTagged PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcRecBase
    (PsKernelCoreList.cons psKcRecExtra PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcRecBaseCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psKcRecBase
    levelParams := PsKernelCoreList.nil
    type := psKcRecBaseType
  }
  induct := psKcRecTagged
  cidx := 0
  numParams := 1
  numFields := 1
  isUnsafe := false
}

def psKcRecExtraCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psKcRecExtra
    levelParams := PsKernelCoreList.nil
    type := psKcRecExtraType
  }
  induct := psKcRecTagged
  cidx := 1
  numParams := 1
  numFields := 2
  isUnsafe := false
}

def psKcRecCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psKcRecBaseCtor
    (PsKernelCoreList.cons psKcRecExtraCtor PsKernelCoreList.nil)

def psKcRecMotiveType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecIndexI psKcRecAlpha
    (psKcRecCloseForall psKcRecMajorI psKcRecTaggedOpen psKcRecSort1)

def psKcRecMinorBaseType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecIndexI psKcRecAlpha
    (psKcRecApp2 psKcRecMotive psKcRecIndex psKcRecBaseOpen)

def psKcRecMinorExtraType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecIndexI psKcRecAlpha
    (psKcRecCloseForall psKcRecFieldI psKcRecAlpha
      (psKcRecApp2 psKcRecMotive psKcRecIndex psKcRecExtraOpen))

def psKcRecType : PsKernelCoreExpr :=
  psKcRecCloseForall psKcRecAlphaI psKcRecSort1
    (psKcRecCloseForall psKcRecMotiveI psKcRecMotiveType
      (psKcRecCloseForall psKcRecMinorBaseI psKcRecMinorBaseType
        (psKcRecCloseForall psKcRecMinorExtraI psKcRecMinorExtraType
          (psKcRecCloseForall psKcRecIndexI psKcRecAlpha
            (psKcRecCloseForall psKcRecMajorI psKcRecTaggedOpen
              (psKcRecApp2 psKcRecMotive psKcRecIndex psKcRecMajor))))))

def psKcRecBaseRuleRhs : PsKernelCoreExpr :=
  psKcRecCloseLam psKcRecAlphaI psKcRecSort1
    (psKcRecCloseLam psKcRecMotiveI psKcRecMotiveType
      (psKcRecCloseLam psKcRecMinorBaseI psKcRecMinorBaseType
        (psKcRecCloseLam psKcRecMinorExtraI psKcRecMinorExtraType
          (psKcRecCloseLam psKcRecIndexI psKcRecAlpha
            (PsKernelCoreExpr.app psKcRecMinorBase psKcRecIndex)))))

def psKcRecExtraRuleRhs : PsKernelCoreExpr :=
  psKcRecCloseLam psKcRecAlphaI psKcRecSort1
    (psKcRecCloseLam psKcRecMotiveI psKcRecMotiveType
      (psKcRecCloseLam psKcRecMinorBaseI psKcRecMinorBaseType
        (psKcRecCloseLam psKcRecMinorExtraI psKcRecMinorExtraType
          (psKcRecCloseLam psKcRecIndexI psKcRecAlpha
            (psKcRecCloseLam psKcRecFieldI psKcRecAlpha
              (psKcRecApp2 psKcRecMinorExtra psKcRecIndex psKcRecField))))))

def psKcRecursorInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcRecName
    levelParams := PsKernelCoreList.nil
    type := psKcRecType
  }
  all := PsKernelCoreList.cons psKcRecTagged PsKernelCoreList.nil
  numParams := 1
  numIndices := 1
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons
    { ctor := psKcRecBase, nFields := 1, rhs := psKcRecBaseRuleRhs }
    (PsKernelCoreList.cons
      { ctor := psKcRecExtra, nFields := 2, rhs := psKcRecExtraRuleRhs }
      PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psKcRecRuleShapeOk
    (rules : PsKernelCoreList PsKernelCoreRecursorRule) : Bool :=
  match rules with
  | PsKernelCoreList.cons first rest =>
      match rest with
      | PsKernelCoreList.cons second tail =>
          match tail with
          | PsKernelCoreList.nil =>
              psKernelCoreNameEq first.ctor psKcRecBase &&
              (first.nFields == 1) &&
              psKernelCoreNameEq second.ctor psKcRecExtra &&
              (second.nFields == 2)
          | PsKernelCoreList.cons _ _ => false
      | PsKernelCoreList.nil => false
  | PsKernelCoreList.nil => false

def psKcRecursorAdmissionPositive : Bool :=
  let unrelated : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.axiomInfo {
      base := {
        name := psKcRecUnrelated
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      isUnsafe := false
    }
  let initial := psKernelCoreEnvironmentMarkQuotInitialized
    (psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty unrelated)
  match psKernelCoreAddNonRecursiveInductive 256 initial psKcRecFamilyInfo psKcRecCtors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor 256 familyEnv psKcRecursorInfo with
      | PsKernelCoreResult.error _ => false
      | PsKernelCoreResult.ok env =>
          env.quotInitialized &&
          (psKernelCoreEnvironmentSize env == 5) &&
          (psKernelCoreRecursorMajorIndex psKcRecursorInfo == 5) &&
          match psKernelCoreEnvironmentFind? env psKcRecUnrelated with
          | PsKernelCoreOption.none => false
          | PsKernelCoreOption.some _ =>
              match psKernelCoreEnvironmentFind? env psKcRecName with
              | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo recInfo) =>
                  (recInfo.numParams == 1) &&
                  (recInfo.numIndices == 1) &&
                  (recInfo.numMotives == 1) &&
                  (recInfo.numMinors == 2) &&
                  (!recInfo.k) && (!recInfo.isUnsafe) &&
                  psKcRecRuleShapeOk recInfo.rules
              | _ => false

def psKcEmpty : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "Phase10Empty"

def psKcEmptyRec : PsKernelCoreName := PsKernelCoreName.str psKcEmpty "rec"

def psKcEmptyExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcEmpty PsKernelCoreList.nil

def psKcEmptyInfo : PsKernelCoreInductiveInfo := {
  base := { name := psKcEmpty, levelParams := PsKernelCoreList.nil, type := psKcRecSort1 }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcEmpty PsKernelCoreList.nil
  ctors := PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcEmptyMotiveType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRecAnon psKcEmptyExpr psKcRecSort1
    PsKernelCoreBinderInfo.default

def psKcEmptyRecType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRecAnon psKcEmptyMotiveType
    (PsKernelCoreExpr.forallE psKcRecAnon psKcEmptyExpr
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) (PsKernelCoreExpr.bvar 0))
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcEmptyRecInfo : PsKernelCoreRecursorInfo := {
  base := { name := psKcEmptyRec, levelParams := PsKernelCoreList.nil, type := psKcEmptyRecType }
  all := PsKernelCoreList.cons psKcEmpty PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 0
  rules := PsKernelCoreList.nil
  k := false
  isUnsafe := false
}

def psKcZeroConstructorRecursor : Bool :=
  match psKernelCoreAddNonRecursiveInductive
      128 psKernelCoreEnvironmentEmpty psKcEmptyInfo PsKernelCoreList.nil with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor 128 familyEnv psKcEmptyRecInfo with
      | PsKernelCoreResult.error _ => false
      | PsKernelCoreResult.ok env =>
          match psKernelCoreEnvironmentFind? env psKcEmptyRec with
          | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo info) =>
              info.numMinors == 0 &&
              match info.rules with
              | PsKernelCoreList.nil => true
              | PsKernelCoreList.cons _ _ => false
          | _ => false

def psRefRecursorAdmissionPositive : Bool :=
  let family : PSC1Kernel.Name := .str .anonymous "Phase10Tagged"
  let base : PSC1Kernel.Name := .str family "base"
  let extra : PSC1Kernel.Name := .str family "extra"
  let recName : PSC1Kernel.Name := .str family "rec"
  let sort1 : PSC1Kernel.Expr := .sort (.succ .zero)
  let familyType : PSC1Kernel.Expr :=
    .forallE .anonymous sort1
      (.forallE .anonymous (.bvar 0) sort1 .default)
      .default
  let baseType : PSC1Kernel.Expr :=
    .forallE .anonymous sort1
      (.forallE .anonymous (.bvar 0)
        (.app (.app (.const family []) (.bvar 1)) (.bvar 0))
        .default)
      .default
  let extraType : PSC1Kernel.Expr :=
    .forallE .anonymous sort1
      (.forallE .anonymous (.bvar 0)
        (.forallE .anonymous (.bvar 1)
          (.app (.app (.const family []) (.bvar 2)) (.bvar 1))
          .default)
        .default)
      .default
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := familyType
    ctors := [
      { name := base, type := baseType },
      { name := extra, type := extraType }
    ]
    isUnsafe := false
    numParams := 1
  }
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env =>
      match env.find? recName with
      | some (.recInfo info) =>
          info.numParams == 1 && info.numIndices == 1 &&
          info.numMotives == 1 && info.numMinors == 2 &&
          (!info.k) && (!info.isUnsafe) &&
          match info.rules with
          | first :: second :: [] =>
              PSC1Kernel.Name.eq first.ctor base && first.nFields == 1 &&
              PSC1Kernel.Name.eq second.ctor extra && second.nFields == 2
          | _ => false
      | _ => false

def main : IO Unit := do
  if psKcRecursorAdmissionPositive &&
      psKcZeroConstructorRecursor &&
      psRefRecursorAdmissionPositive then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_ADMISSION_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_ADMISSION_PARITY: FAIL")
