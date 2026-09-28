import Ps.KernelCore

def psKcForgeAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcForgeFamily : PsKernelCoreName :=
  PsKernelCoreName.str psKcForgeAnon "Phase10ForgedMinorFlag"

def psKcForgeOff : PsKernelCoreName :=
  PsKernelCoreName.str psKcForgeFamily "off"

def psKcForgeOn : PsKernelCoreName :=
  PsKernelCoreName.str psKcForgeFamily "on"

def psKcForgeRec : PsKernelCoreName :=
  PsKernelCoreName.str psKcForgeFamily "rec"

def psKcForgeSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcForgeFamilyExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcForgeFamily PsKernelCoreList.nil

def psKcForgeOffExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcForgeOff PsKernelCoreList.nil

def psKcForgeOnExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcForgeOn PsKernelCoreList.nil

def psKcForgeMotiveType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcForgeAnon psKcForgeFamilyExpr psKcForgeSort1
    PsKernelCoreBinderInfo.default

def psKcForgeFamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcForgeFamily
    levelParams := PsKernelCoreList.nil
    type := psKcForgeSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcForgeFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcForgeOff
    (PsKernelCoreList.cons psKcForgeOn PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcForgeCtor
    (name : PsKernelCoreName)
    (index : Nat) : PsKernelCoreConstructorInfo := {
  base := {
    name := name
    levelParams := PsKernelCoreList.nil
    type := psKcForgeFamilyExpr
  }
  induct := psKcForgeFamily
  cidx := index
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psKcForgeCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons (psKcForgeCtor psKcForgeOff 0)
    (PsKernelCoreList.cons (psKcForgeCtor psKcForgeOn 1) PsKernelCoreList.nil)

-- Deliberately forged: the first minor is typed as motive on instead of motive off.
-- The final result shape remains canonical, so a validator that derives the
-- expected rule type from this supplied minor binder can be fooled.
def psKcForgeRecType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcForgeAnon psKcForgeMotiveType
    (PsKernelCoreExpr.forallE psKcForgeAnon
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcForgeOnExpr)
      (PsKernelCoreExpr.forallE psKcForgeAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcForgeOnExpr)
        (PsKernelCoreExpr.forallE psKcForgeAnon psKcForgeFamilyExpr
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 3) (PsKernelCoreExpr.bvar 0))
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcForgeOffRule : PsKernelCoreRecursorRule := {
  ctor := psKcForgeOff
  nFields := 0
  rhs :=
    PsKernelCoreExpr.lam psKcForgeAnon psKcForgeMotiveType
      (PsKernelCoreExpr.lam psKcForgeAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcForgeOnExpr)
        (PsKernelCoreExpr.lam psKcForgeAnon
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcForgeOnExpr)
          (PsKernelCoreExpr.bvar 1)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
}

def psKcForgeOnRule : PsKernelCoreRecursorRule := {
  ctor := psKcForgeOn
  nFields := 0
  rhs :=
    PsKernelCoreExpr.lam psKcForgeAnon psKcForgeMotiveType
      (PsKernelCoreExpr.lam psKcForgeAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcForgeOnExpr)
        (PsKernelCoreExpr.lam psKcForgeAnon
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcForgeOnExpr)
          (PsKernelCoreExpr.bvar 0)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
}

def psKcForgeInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcForgeRec
    levelParams := PsKernelCoreList.nil
    type := psKcForgeRecType
  }
  all := PsKernelCoreList.cons psKcForgeFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons psKcForgeOffRule
    (PsKernelCoreList.cons psKcForgeOnRule PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psKernelCoreRejectsForgedMinorBranch : Bool :=
  match psKernelCoreAddNonRecursiveInductive
      128 psKernelCoreEnvironmentEmpty psKcForgeFamilyInfo psKcForgeCtors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      match psKernelCoreAddRecursor 128 env psKcForgeInfo with
      | PsKernelCoreResult.error _ => true
      | PsKernelCoreResult.ok _ => false

def main : IO Unit := do
  if psKernelCoreRejectsForgedMinorBranch then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_FORGED_MINOR_REJECTION: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_FORGED_MINOR_REJECTION: FAIL")
