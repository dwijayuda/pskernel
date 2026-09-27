import Ps.KernelCore

def psKcRejectAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcRejectFamily : PsKernelCoreName := PsKernelCoreName.str psKcRejectAnon "Phase10RejectFlag"

def psKcRejectOff : PsKernelCoreName := PsKernelCoreName.str psKcRejectFamily "off"

def psKcRejectOn : PsKernelCoreName := PsKernelCoreName.str psKcRejectFamily "on"

def psKcRejectRec : PsKernelCoreName := PsKernelCoreName.str psKcRejectFamily "rec"

def psKcRejectOther : PsKernelCoreName := PsKernelCoreName.str psKcRejectAnon "phase10RejectOther"

def psKcRejectMissing : PsKernelCoreName := PsKernelCoreName.str psKcRejectAnon "phase10Missing"

def psKcRejectU : PsKernelCoreName := PsKernelCoreName.str psKcRejectAnon "u"

def psKcRejectSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcRejectFamilyExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRejectFamily PsKernelCoreList.nil

def psKcRejectOffExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRejectOff PsKernelCoreList.nil

def psKcRejectOnExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRejectOn PsKernelCoreList.nil

def psKcRejectMotiveType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRejectAnon psKcRejectFamilyExpr psKcRejectSort1
    PsKernelCoreBinderInfo.default

def psKcRejectFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcRejectFamily
    levelParams := PsKernelCoreList.nil
    type := psKcRejectSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcRejectFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcRejectOff
    (PsKernelCoreList.cons psKcRejectOn PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcRejectCtor
    (name : PsKernelCoreName)
    (index : Nat) : PsKernelCoreConstructorInfo := {
  base := {
    name := name
    levelParams := PsKernelCoreList.nil
    type := psKcRejectFamilyExpr
  }
  induct := psKcRejectFamily
  cidx := index
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psKcRejectCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons (psKcRejectCtor psKcRejectOff 0)
    (PsKernelCoreList.cons (psKcRejectCtor psKcRejectOn 1) PsKernelCoreList.nil)

def psKcRejectRecType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRejectAnon psKcRejectMotiveType
    (PsKernelCoreExpr.forallE psKcRejectAnon
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcRejectOffExpr)
      (PsKernelCoreExpr.forallE psKcRejectAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcRejectOnExpr)
        (PsKernelCoreExpr.forallE psKcRejectAnon psKcRejectFamilyExpr
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 3) (PsKernelCoreExpr.bvar 0))
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcRejectOffRule : PsKernelCoreRecursorRule := {
  ctor := psKcRejectOff
  nFields := 0
  rhs :=
    PsKernelCoreExpr.lam psKcRejectAnon psKcRejectMotiveType
      (PsKernelCoreExpr.lam psKcRejectAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcRejectOffExpr)
        (PsKernelCoreExpr.lam psKcRejectAnon
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcRejectOnExpr)
          (PsKernelCoreExpr.bvar 1)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
}

def psKcRejectOnRule : PsKernelCoreRecursorRule := {
  ctor := psKcRejectOn
  nFields := 0
  rhs :=
    PsKernelCoreExpr.lam psKcRejectAnon psKcRejectMotiveType
      (PsKernelCoreExpr.lam psKcRejectAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcRejectOffExpr)
        (PsKernelCoreExpr.lam psKcRejectAnon
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcRejectOnExpr)
          (PsKernelCoreExpr.bvar 0)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
}

def psKcRejectBadOffRule : PsKernelCoreRecursorRule := {
  ctor := psKcRejectOff
  nFields := 0
  rhs := psKcRejectOnRule.rhs
}

def psKcRejectRules : PsKernelCoreList PsKernelCoreRecursorRule :=
  PsKernelCoreList.cons psKcRejectOffRule
    (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)

def psKcRejectInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcRejectRec
    levelParams := PsKernelCoreList.nil
    type := psKcRejectRecType
  }
  all := PsKernelCoreList.cons psKcRejectFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := psKcRejectRules
  k := false
  isUnsafe := false
}

def psKcRejectInitial : PsKernelCoreEnvironment :=
  let unrelated : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.axiomInfo {
      base := {
        name := psKcRejectOther
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      isUnsafe := false
    }
  psKernelCoreEnvironmentMarkQuotInitialized
    (psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty unrelated)

def psKcRejectFamilyEnv? : PsKernelCoreOption PsKernelCoreEnvironment :=
  match psKernelCoreAddNonRecursiveInductive
      128 psKcRejectInitial psKcRejectFamilyInfo psKcRejectCtors with
  | PsKernelCoreResult.error _ => PsKernelCoreOption.none
  | PsKernelCoreResult.ok env => PsKernelCoreOption.some env

def psKcRejectEnvironmentUnchanged
    (before : PsKernelCoreEnvironment)
    (afterAttempt : PsKernelCoreResult String PsKernelCoreEnvironment) : Bool :=
  match afterAttempt with
  | PsKernelCoreResult.ok _ => false
  | PsKernelCoreResult.error _ =>
      (psKernelCoreEnvironmentSize before == 4) && before.quotInitialized &&
      match psKernelCoreEnvironmentFind? before psKcRejectOther with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some _ =>
          match psKernelCoreEnvironmentFind? before psKcRejectRec with
          | PsKernelCoreOption.none => true
          | PsKernelCoreOption.some _ => false

def psKcRejects
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) : Bool :=
  psKcRejectEnvironmentUnchanged env (psKernelCoreAddRecursor 128 env info)

def psKcRejectsAnyEnv
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreRecursorInfo) : Bool :=
  match psKernelCoreAddRecursor 128 env info with
  | PsKernelCoreResult.error _ => true
  | PsKernelCoreResult.ok _ => false

def psKcRejectRecursorCollision
    (env : PsKernelCoreEnvironment) : Bool :=
  let occupied : PsKernelCoreConstantInfo :=
    PsKernelCoreConstantInfo.axiomInfo {
      base := {
        name := psKcRejectRec
        levelParams := PsKernelCoreList.nil
        type := PsKernelCoreExpr.sort PsKernelCoreLevel.zero
      }
      isUnsafe := false
    }
  let collisionEnv := psKernelCoreEnvironmentAddUnchecked env occupied;
  psKcRejectsAnyEnv collisionEnv psKcRejectInfo &&
  (psKernelCoreEnvironmentSize collisionEnv == 5) &&
  collisionEnv.quotInitialized

def psKcRecursorRejectionMatrix : Bool :=
  match psKcRejectFamilyEnv? with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some env =>
      let emptyTargets : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with all := PsKernelCoreList.nil
      }
      let missingTarget : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        all := PsKernelCoreList.cons psKcRejectMissing PsKernelCoreList.nil
      }
      let nonInductiveTarget : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        all := PsKernelCoreList.cons psKcRejectOther PsKernelCoreList.nil
      }
      let multipleTargets : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        all := PsKernelCoreList.cons psKcRejectFamily
          (PsKernelCoreList.cons psKcRejectMissing PsKernelCoreList.nil)
      }
      let wrongParams : PsKernelCoreRecursorInfo := { psKcRejectInfo with numParams := 1 }
      let wrongIndices : PsKernelCoreRecursorInfo := { psKcRejectInfo with numIndices := 1 }
      let zeroMotives : PsKernelCoreRecursorInfo := { psKcRejectInfo with numMotives := 0 }
      let twoMotives : PsKernelCoreRecursorInfo := { psKcRejectInfo with numMotives := 2 }
      let wrongMinors : PsKernelCoreRecursorInfo := { psKcRejectInfo with numMinors := 1 }
      let oneRule : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons psKcRejectOffRule PsKernelCoreList.nil
      }
      let duplicateRules : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons psKcRejectOffRule
          (PsKernelCoreList.cons psKcRejectOffRule PsKernelCoreList.nil)
      }
      let kRecursor : PsKernelCoreRecursorInfo := { psKcRejectInfo with k := true }
      let unsafeRecursor : PsKernelCoreRecursorInfo := { psKcRejectInfo with isUnsafe := true }
      let wrongRuleOrder : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons psKcRejectOnRule
          (PsKernelCoreList.cons psKcRejectOffRule PsKernelCoreList.nil)
      }
      let wrongFieldRule : PsKernelCoreRecursorRule := { psKcRejectOffRule with nFields := 1 }
      let wrongFields : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons wrongFieldRule
          (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)
      }
      let duplicateUBase : PsKernelCoreConstantBase := {
        psKcRejectInfo.base with
        levelParams := PsKernelCoreList.cons psKcRejectU
          (PsKernelCoreList.cons psKcRejectU PsKernelCoreList.nil)
      }
      let duplicateUniverse : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with base := duplicateUBase
      }
      let uncoveredBase : PsKernelCoreConstantBase := {
        psKcRejectInfo.base with
        type := PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcRejectU)
      }
      let uncoveredUniverse : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with base := uncoveredBase
      }
      let mvarBase : PsKernelCoreConstantBase := {
        psKcRejectInfo.base with type := PsKernelCoreExpr.mvar psKcRejectMissing
      }
      let mvarInfo : PsKernelCoreRecursorInfo := { psKcRejectInfo with base := mvarBase }
      let fvarBase : PsKernelCoreConstantBase := {
        psKcRejectInfo.base with type := PsKernelCoreExpr.fvar psKcRejectMissing
      }
      let fvarInfo : PsKernelCoreRecursorInfo := { psKcRejectInfo with base := fvarBase }
      let malformedBase : PsKernelCoreConstantBase := {
        psKcRejectInfo.base with type := psKcRejectFamilyExpr
      }
      let malformedType : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with base := malformedBase
      }
      let branchMismatch : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons psKcRejectBadOffRule
          (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)
      }
      let uncoveredRule : PsKernelCoreRecursorRule := {
        psKcRejectOffRule with
        rhs := PsKernelCoreExpr.sort (PsKernelCoreLevel.param psKcRejectU)
      }
      let uncoveredRuleInfo : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons uncoveredRule
          (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)
      }
      let mvarRule : PsKernelCoreRecursorRule := {
        psKcRejectOffRule with rhs := PsKernelCoreExpr.mvar psKcRejectMissing
      }
      let mvarRuleInfo : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons mvarRule
          (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)
      }
      let fvarRule : PsKernelCoreRecursorRule := {
        psKcRejectOffRule with rhs := PsKernelCoreExpr.fvar psKcRejectMissing
      }
      let fvarRuleInfo : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons fvarRule
          (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)
      }
      let recursiveFamily : PsKernelCoreInductiveInfo := {
        psKcRejectFamilyInfo with isRec := true
      }
      let recursiveEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.inductInfo recursiveFamily)
      let nestedFamily : PsKernelCoreInductiveInfo := {
        psKcRejectFamilyInfo with numNested := 1
      }
      let nestedEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.inductInfo nestedFamily)
      let reflexiveFamily : PsKernelCoreInductiveInfo := {
        psKcRejectFamilyInfo with isReflexive := true
      }
      let reflexiveEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.inductInfo reflexiveFamily)
      let badCtor : PsKernelCoreConstructorInfo := {
        psKcRejectCtor psKcRejectOff 7 with numFields := 0
      }
      let badCtorEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.ctorInfo badCtor)
      let offAsAxiom : PsKernelCoreConstantInfo :=
        PsKernelCoreConstantInfo.axiomInfo {
          base := {
            name := psKcRejectOff
            levelParams := PsKernelCoreList.nil
            type := psKcRejectFamilyExpr
          }
          isUnsafe := false
        }
      let nonCtorEnv := psKernelCoreEnvironmentReplaceUnchecked env offAsAxiom;
      let foreignCtor : PsKernelCoreConstructorInfo := {
        psKcRejectCtor psKcRejectOff 0 with induct := psKcRejectMissing
      }
      let foreignCtorEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.ctorInfo foreignCtor)
      let unsafeCtor : PsKernelCoreConstructorInfo := {
        psKcRejectCtor psKcRejectOff 0 with isUnsafe := true
      }
      let unsafeCtorEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.ctorInfo unsafeCtor)
      let missingFamily : PsKernelCoreInductiveInfo := {
        psKcRejectFamilyInfo with
        ctors := PsKernelCoreList.cons psKcRejectMissing
          (PsKernelCoreList.cons psKcRejectOn PsKernelCoreList.nil)
      }
      let missingCtorEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.inductInfo missingFamily)
      let missingRule : PsKernelCoreRecursorRule := {
        psKcRejectOffRule with ctor := psKcRejectMissing
      }
      let missingCtorInfo : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        rules := PsKernelCoreList.cons missingRule
          (PsKernelCoreList.cons psKcRejectOnRule PsKernelCoreList.nil)
      }
      psKcRejectRecursorCollision env &&
      psKcRejects env emptyTargets &&
      psKcRejects env missingTarget &&
      psKcRejects env nonInductiveTarget &&
      psKcRejects env multipleTargets &&
      psKcRejects env wrongParams &&
      psKcRejects env wrongIndices &&
      psKcRejects env zeroMotives &&
      psKcRejects env twoMotives &&
      psKcRejects env wrongMinors &&
      psKcRejects env oneRule &&
      psKcRejects env duplicateRules &&
      psKcRejects env kRecursor &&
      psKcRejects env unsafeRecursor &&
      psKcRejects env wrongRuleOrder &&
      psKcRejects env wrongFields &&
      psKcRejects env duplicateUniverse &&
      psKcRejects env uncoveredUniverse &&
      psKcRejects env mvarInfo &&
      psKcRejects env fvarInfo &&
      psKcRejects env malformedType &&
      psKcRejects env branchMismatch &&
      psKcRejects env uncoveredRuleInfo &&
      psKcRejects env mvarRuleInfo &&
      psKcRejects env fvarRuleInfo &&
      psKcRejects recursiveEnv psKcRejectInfo &&
      psKcRejects nestedEnv psKcRejectInfo &&
      psKcRejects reflexiveEnv psKcRejectInfo &&
      psKcRejects badCtorEnv psKcRejectInfo &&
      psKcRejects nonCtorEnv psKcRejectInfo &&
      psKcRejects foreignCtorEnv psKcRejectInfo &&
      psKcRejects unsafeCtorEnv psKcRejectInfo &&
      psKcRejectsAnyEnv missingCtorEnv missingCtorInfo

def main : IO Unit := do
  if psKcRecursorRejectionMatrix then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_REJECTION: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_REJECTION: FAIL")
