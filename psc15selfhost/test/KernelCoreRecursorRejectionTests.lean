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

def psKcRecursorRejectionMatrix : Bool :=
  match psKcRejectFamilyEnv? with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some env =>
      let missingTarget : PsKernelCoreRecursorInfo := {
        psKcRejectInfo with
        all := PsKernelCoreList.cons psKcRejectMissing PsKernelCoreList.nil
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
      let recursiveFamily : PsKernelCoreInductiveInfo := {
        psKcRejectFamilyInfo with isRec := true
      }
      let recursiveEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.inductInfo recursiveFamily)
      let badCtor : PsKernelCoreConstructorInfo := {
        psKcRejectCtor psKcRejectOff 7 with numFields := 0
      }
      let badCtorEnv :=
        psKernelCoreEnvironmentReplaceUnchecked env
          (PsKernelCoreConstantInfo.ctorInfo badCtor)
      psKcRejects env missingTarget &&
      psKcRejects env multipleTargets &&
      psKcRejects env wrongParams &&
      psKcRejects env wrongIndices &&
      psKcRejects env zeroMotives &&
      psKcRejects env twoMotives &&
      psKcRejects env wrongMinors &&
      psKcRejects env kRecursor &&
      psKcRejects env unsafeRecursor &&
      psKcRejects env wrongRuleOrder &&
      psKcRejects env wrongFields &&
      psKcRejects env duplicateUniverse &&
      psKcRejects env uncoveredUniverse &&
      psKcRejects env mvarInfo &&
      psKcRejects env malformedType &&
      psKcRejects env branchMismatch &&
      psKcRejects recursiveEnv psKcRejectInfo &&
      psKcRejects badCtorEnv psKcRejectInfo

def main : IO Unit := do
  if psKcRecursorRejectionMatrix then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_REJECTION: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_REJECTION: FAIL")
