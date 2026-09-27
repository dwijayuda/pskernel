import Ps.KernelCore

def psKcRejectAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcRejectName : PsKernelCoreName := PsKernelCoreName.str psKcRejectAnon "Choice"

def psKcRejectCtorName : PsKernelCoreName := PsKernelCoreName.str psKcRejectName "only"

def psKcRejectOther : PsKernelCoreName := PsKernelCoreName.str psKcRejectAnon "Other"

def psKcRejectType : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcRejectResult : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcRejectName PsKernelCoreList.nil

def psKcRejectInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psKcRejectName
    levelParams := PsKernelCoreList.nil
    type := psKcRejectType
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcRejectName PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcRejectCtorName PsKernelCoreList.nil
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcRejectCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psKcRejectCtorName
    levelParams := PsKernelCoreList.nil
    type := psKcRejectResult
  }
  induct := psKcRejectName
  cidx := 0
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psKcRejectOne
    (budget : Nat)
    (info : PsKernelCoreInductiveInfo)
    (ctor : PsKernelCoreConstructorInfo) : Bool :=
  let initial := psKernelCoreEnvironmentMarkQuotInitialized psKernelCoreEnvironmentEmpty
  let ctors := PsKernelCoreList.cons ctor PsKernelCoreList.nil
  match psKernelCoreAddNonRecursiveInductive budget initial info ctors with
  | PsKernelCoreResult.error _ =>
      (psKernelCoreEnvironmentSize initial == 0) && initial.quotInitialized
  | PsKernelCoreResult.ok _ => false

def psKcRejectMetadataCases : Bool :=
  let badAll : PsKernelCoreInductiveInfo := {
    psKcRejectInfo with all := PsKernelCoreList.nil
  }
  let badNested : PsKernelCoreInductiveInfo := {
    psKcRejectInfo with numNested := 1
  }
  let badRec : PsKernelCoreInductiveInfo := {
    psKcRejectInfo with isRec := true
  }
  let badReflexive : PsKernelCoreInductiveInfo := {
    psKcRejectInfo with isReflexive := true
  }
  let badCtorList : PsKernelCoreInductiveInfo := {
    psKcRejectInfo with ctors := PsKernelCoreList.nil
  }
  let badHeader : PsKernelCoreInductiveInfo := {
    psKcRejectInfo with numIndices := 1
  }
  psKcRejectOne 64 badAll psKcRejectCtor &&
  psKcRejectOne 64 badNested psKcRejectCtor &&
  psKcRejectOne 64 badRec psKcRejectCtor &&
  psKcRejectOne 64 badReflexive psKcRejectCtor &&
  psKcRejectOne 64 badCtorList psKcRejectCtor &&
  psKcRejectOne 64 badHeader psKcRejectCtor

def psKcRejectConstructorCases : Bool :=
  let badOwner : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with induct := psKcRejectOther
  }
  let badIndex : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with cidx := 1
  }
  let badParams : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with numParams := 1
  }
  let badFields : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with numFields := 1
  }
  let badSafety : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with isUnsafe := true
  }
  let badResult : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with
      base := {
        psKcRejectCtor.base with
        type := PsKernelCoreExpr.const psKcRejectOther PsKernelCoreList.nil
      }
  }
  let recursiveType :=
    PsKernelCoreExpr.forallE psKcRejectAnon psKcRejectResult psKcRejectResult
      PsKernelCoreBinderInfo.default
  let badRecursive : PsKernelCoreConstructorInfo := {
    psKcRejectCtor with
      base := { psKcRejectCtor.base with type := recursiveType }
      numFields := 1
  }
  psKcRejectOne 64 psKcRejectInfo badOwner &&
  psKcRejectOne 64 psKcRejectInfo badIndex &&
  psKcRejectOne 64 psKcRejectInfo badParams &&
  psKcRejectOne 64 psKcRejectInfo badFields &&
  psKcRejectOne 64 psKcRejectInfo badSafety &&
  psKcRejectOne 64 psKcRejectInfo badResult &&
  psKcRejectOne 64 psKcRejectInfo badRecursive

def psKcRejectBudget : Bool :=
  psKcRejectOne 0 psKcRejectInfo psKcRejectCtor

def main : IO Unit := do
  if psKcRejectMetadataCases && psKcRejectConstructorCases && psKcRejectBudget then
    IO.println "PSC2_KERNEL_CORE_INDUCTIVE_REJECTIONS: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_INDUCTIVE_REJECTIONS: FAIL")
