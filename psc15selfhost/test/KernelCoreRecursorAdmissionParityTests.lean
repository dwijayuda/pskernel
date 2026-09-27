import Ps.KernelCore
import PSC1Kernel.Inductive

def psKcRecAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcRecFamily : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "Phase10Flag"

def psKcRecOff : PsKernelCoreName := PsKernelCoreName.str psKcRecFamily "off"

def psKcRecOn : PsKernelCoreName := PsKernelCoreName.str psKcRecFamily "on"

def psKcRecName : PsKernelCoreName := PsKernelCoreName.str psKcRecFamily "rec"

def psKcRecUnrelated : PsKernelCoreName := PsKernelCoreName.str psKcRecAnon "phase10Unrelated"

def psKcRecSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcRecFamilyExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRecFamily PsKernelCoreList.nil

def psKcRecOffExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRecOff PsKernelCoreList.nil

def psKcRecOnExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRecOn PsKernelCoreList.nil

def psKcRecMotiveType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRecAnon psKcRecFamilyExpr psKcRecSort1
    PsKernelCoreBinderInfo.default

def psKcRecInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcRecFamily
    levelParams := PsKernelCoreList.nil
    type := psKcRecSort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcRecFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcRecOff
    (PsKernelCoreList.cons psKcRecOn PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcRecCtor
    (name : PsKernelCoreName)
    (index : Nat) : PsKernelCoreConstructorInfo := {
  base := {
    name := name
    levelParams := PsKernelCoreList.nil
    type := psKcRecFamilyExpr
  }
  induct := psKcRecFamily
  cidx := index
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psKcRecCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons (psKcRecCtor psKcRecOff 0)
    (PsKernelCoreList.cons (psKcRecCtor psKcRecOn 1) PsKernelCoreList.nil)

def psKcRecType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcRecAnon psKcRecMotiveType
    (PsKernelCoreExpr.forallE psKcRecAnon
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcRecOffExpr)
      (PsKernelCoreExpr.forallE psKcRecAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcRecOnExpr)
        (PsKernelCoreExpr.forallE psKcRecAnon psKcRecFamilyExpr
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 3) (PsKernelCoreExpr.bvar 0))
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcRecOffRuleRhs : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psKcRecAnon psKcRecMotiveType
    (PsKernelCoreExpr.lam psKcRecAnon
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcRecOffExpr)
      (PsKernelCoreExpr.lam psKcRecAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcRecOnExpr)
        (PsKernelCoreExpr.bvar 1)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcRecOnRuleRhs : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psKcRecAnon psKcRecMotiveType
    (PsKernelCoreExpr.lam psKcRecAnon
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcRecOffExpr)
      (PsKernelCoreExpr.lam psKcRecAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcRecOnExpr)
        (PsKernelCoreExpr.bvar 0)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcRecursorInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psKcRecName
    levelParams := PsKernelCoreList.nil
    type := psKcRecType
  }
  all := PsKernelCoreList.cons psKcRecFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons
    { ctor := psKcRecOff, nFields := 0, rhs := psKcRecOffRuleRhs }
    (PsKernelCoreList.cons
      { ctor := psKcRecOn, nFields := 0, rhs := psKcRecOnRuleRhs }
      PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

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
  match psKernelCoreAddNonRecursiveInductive 128 initial psKcRecInfo psKcRecCtors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreAddRecursor 128 familyEnv psKcRecursorInfo with
      | PsKernelCoreResult.error _ => false
      | PsKernelCoreResult.ok env =>
          env.quotInitialized &&
          (psKernelCoreEnvironmentSize env == 5) &&
          match psKernelCoreEnvironmentFind? env psKcRecUnrelated with
          | PsKernelCoreOption.none => false
          | PsKernelCoreOption.some _ =>
              match psKernelCoreEnvironmentFind? env psKcRecName with
              | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo recInfo) =>
                  (recInfo.numParams == 0) &&
                  (recInfo.numIndices == 0) &&
                  (recInfo.numMotives == 1) &&
                  (recInfo.numMinors == 2) &&
                  (!recInfo.k) && (!recInfo.isUnsafe)
              | _ => false

def psRefRecursorAdmissionPositive : Bool :=
  let family : PSC1Kernel.Name := .str .anonymous "Phase10Flag"
  let off : PSC1Kernel.Name := .str family "off"
  let on : PSC1Kernel.Name := .str family "on"
  let recName : PSC1Kernel.Name := .str family "rec"
  let familyExpr : PSC1Kernel.Expr := .const family []
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := family
    type := .sort (.succ .zero)
    ctors := [
      { name := off, type := familyExpr },
      { name := on, type := familyExpr }
    ]
    isUnsafe := false
    numParams := 0
  }
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env =>
      match env.find? recName with
      | some (.recInfo info) =>
          info.numParams == 0 && info.numIndices == 0 &&
          info.numMotives == 1 && info.numMinors == 2 &&
          (!info.k) && (!info.isUnsafe) && info.rules.length == 2
      | _ => false

def main : IO Unit := do
  if psKcRecursorAdmissionPositive && psRefRecursorAdmissionPositive then
    IO.println "PSC2_KERNEL_CORE_RECURSOR_ADMISSION_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_RECURSOR_ADMISSION_PARITY: FAIL")
