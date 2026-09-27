import Ps.KernelCore
import PSC1Kernel.Inductive

def psKcIndAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcIndName : PsKernelCoreName := PsKernelCoreName.str psKcIndAnon "Flag"

def psKcIndCtorA : PsKernelCoreName := PsKernelCoreName.str psKcIndName "off"

def psKcIndCtorB : PsKernelCoreName := PsKernelCoreName.str psKcIndName "on"

def psKcIndEmptyNames : PsKernelCoreList PsKernelCoreName := PsKernelCoreList.nil

def psKcIndType : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcIndResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcIndName PsKernelCoreList.nil

def psKcIndInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcIndName
    levelParams := psKcIndEmptyNames
    type := psKcIndType
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcIndName PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcIndCtorA
    (PsKernelCoreList.cons psKcIndCtorB PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcIndCtorInfo
    (name : PsKernelCoreName)
    (index : Nat)
    (type : PsKernelCoreExpr) : PsKernelCoreConstructorInfo := {
  base := {
    name := name
    levelParams := psKcIndEmptyNames
    type := type
  }
  induct := psKcIndName
  cidx := index
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psKcIndCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons
    (psKcIndCtorInfo psKcIndCtorA 0 psKcIndResult)
    (PsKernelCoreList.cons
      (psKcIndCtorInfo psKcIndCtorB 1 psKcIndResult)
      PsKernelCoreList.nil)

def psKcIndRecursiveCtorType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcIndAnon psKcIndResult psKcIndResult
    PsKernelCoreBinderInfo.default

def psKcIndPositive : Bool :=
  let initial := psKernelCoreEnvironmentMarkQuotInitialized psKernelCoreEnvironmentEmpty
  match psKernelCoreAddNonRecursiveInductive 64 initial psKcIndInfo psKcIndCtors with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      (psKernelCoreEnvironmentSize env == 3) && env.quotInitialized &&
      match psKernelCoreEnvironmentFind? env psKcIndName with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo info) =>
          info.numParams == 0 && info.numIndices == 0 &&
          (!info.isRec) && (!info.isReflexive) && (!info.isUnsafe)
      | _ => false

def psRefIndPositive : Bool :=
  let Enum : PSC1Kernel.Name := .str .anonymous "Flag"
  let Off : PSC1Kernel.Name := .str Enum "off"
  let On : PSC1Kernel.Name := .str Enum "on"
  let enumExpr : PSC1Kernel.Expr := .const Enum []
  let decl : PSC1Kernel.Kernel.SimpleInductiveDecl := {
    levelParams := []
    name := Enum
    type := .sort (.succ .zero)
    ctors := [
      { name := Off, type := enumExpr },
      { name := On, type := enumExpr }
    ]
    isUnsafe := false
    numParams := 0
  }
  match PSC1Kernel.Kernel.addSimpleInductive PSC1Kernel.Environment.empty decl with
  | .error _ => false
  | .ok env =>
      match env.find? Enum with
      | some (.inductInfo info) =>
          if info.numParams == 0 && info.numIndices == 0 &&
              info.numNested == 0 && (!info.isRec) &&
              (!info.isReflexive) && (!info.isUnsafe) then
            match env.find? Off with
            | some (.ctorInfo offInfo) =>
                if PSC1Kernel.Name.eq offInfo.induct Enum &&
                    offInfo.cidx == 0 && offInfo.numParams == 0 &&
                    offInfo.numFields == 0 && (!offInfo.isUnsafe) then
                  match env.find? On with
                  | some (.ctorInfo onInfo) =>
                      PSC1Kernel.Name.eq onInfo.induct Enum &&
                      onInfo.cidx == 1 && onInfo.numParams == 0 &&
                      onInfo.numFields == 0 && (!onInfo.isUnsafe)
                  | _ => false
                else
                  false
            | _ => false
          else
            false
      | _ => false

def psKcIndRejectRecursive : Bool :=
  let badInfo : PsKernelCoreInductiveInfo := {
    psKcIndInfo with
    ctors := PsKernelCoreList.cons psKcIndCtorA PsKernelCoreList.nil
  }
  let badCtor : PsKernelCoreConstructorInfo := {
    (psKcIndCtorInfo psKcIndCtorA 0 psKcIndRecursiveCtorType) with
    numFields := 1
  }
  let badCtors := PsKernelCoreList.cons badCtor PsKernelCoreList.nil
  let initial := psKernelCoreEnvironmentEmpty
  match psKernelCoreAddNonRecursiveInductive 64 initial badInfo badCtors with
  | PsKernelCoreResult.error _ => psKernelCoreEnvironmentSize initial == 0
  | PsKernelCoreResult.ok _ => false

def main : IO Unit := do
  if psKcIndPositive && psRefIndPositive && psKcIndRejectRecursive then
    IO.println "PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_INDUCTIVE_ADMISSION_PARITY: FAIL")
