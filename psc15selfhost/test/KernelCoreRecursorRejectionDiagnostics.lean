import Ps.KernelCore

def psKcDiagAnon : PsKernelCoreName := PsKernelCoreName.anonymous

def psKcDiagFamily : PsKernelCoreName := PsKernelCoreName.str psKcDiagAnon "Phase10DiagFlag"

def psKcDiagOff : PsKernelCoreName := PsKernelCoreName.str psKcDiagFamily "off"

def psKcDiagOn : PsKernelCoreName := PsKernelCoreName.str psKcDiagFamily "on"

def psKcDiagRec : PsKernelCoreName := PsKernelCoreName.str psKcDiagFamily "rec"

def psKcDiagSort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psKcDiagFamilyExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcDiagFamily PsKernelCoreList.nil

def psKcDiagOffExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcDiagOff PsKernelCoreList.nil

def psKcDiagOnExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psKcDiagOn PsKernelCoreList.nil

def psKcDiagMotiveType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcDiagAnon psKcDiagFamilyExpr psKcDiagSort1
    PsKernelCoreBinderInfo.default

def psKcDiagFamilyInfo : PsKernelCoreInductiveInfo := {
  base := { name := psKcDiagFamily, levelParams := PsKernelCoreList.nil, type := psKcDiagSort1 }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psKcDiagFamily PsKernelCoreList.nil
  ctors := PsKernelCoreList.cons psKcDiagOff
    (PsKernelCoreList.cons psKcDiagOn PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psKcDiagCtor
    (name : PsKernelCoreName)
    (index : Nat) : PsKernelCoreConstructorInfo := {
  base := { name := name, levelParams := PsKernelCoreList.nil, type := psKcDiagFamilyExpr }
  induct := psKcDiagFamily
  cidx := index
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psKcDiagCtors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons (psKcDiagCtor psKcDiagOff 0)
    (PsKernelCoreList.cons (psKcDiagCtor psKcDiagOn 1) PsKernelCoreList.nil)

def psKcDiagRecType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psKcDiagAnon psKcDiagMotiveType
    (PsKernelCoreExpr.forallE psKcDiagAnon
      (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcDiagOffExpr)
      (PsKernelCoreExpr.forallE psKcDiagAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcDiagOnExpr)
        (PsKernelCoreExpr.forallE psKcDiagAnon psKcDiagFamilyExpr
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 3) (PsKernelCoreExpr.bvar 0))
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default)
    PsKernelCoreBinderInfo.default

def psKcDiagOffRule : PsKernelCoreRecursorRule := {
  ctor := psKcDiagOff
  nFields := 0
  rhs :=
    PsKernelCoreExpr.lam psKcDiagAnon psKcDiagMotiveType
      (PsKernelCoreExpr.lam psKcDiagAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcDiagOffExpr)
        (PsKernelCoreExpr.lam psKcDiagAnon
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcDiagOnExpr)
          (PsKernelCoreExpr.bvar 1)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
}

def psKcDiagOnRule : PsKernelCoreRecursorRule := {
  ctor := psKcDiagOn
  nFields := 0
  rhs :=
    PsKernelCoreExpr.lam psKcDiagAnon psKcDiagMotiveType
      (PsKernelCoreExpr.lam psKcDiagAnon
        (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 0) psKcDiagOffExpr)
        (PsKernelCoreExpr.lam psKcDiagAnon
          (PsKernelCoreExpr.app (PsKernelCoreExpr.bvar 1) psKcDiagOnExpr)
          (PsKernelCoreExpr.bvar 0)
          PsKernelCoreBinderInfo.default)
        PsKernelCoreBinderInfo.default)
      PsKernelCoreBinderInfo.default
}

def psKcDiagGoodInfo : PsKernelCoreRecursorInfo := {
  base := { name := psKcDiagRec, levelParams := PsKernelCoreList.nil, type := psKcDiagRecType }
  all := PsKernelCoreList.cons psKcDiagFamily PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules := PsKernelCoreList.cons psKcDiagOffRule
    (PsKernelCoreList.cons psKcDiagOnRule PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psKcDiagStatus
    (result : PsKernelCoreResult String PsKernelCoreEnvironment) : String :=
  match result with
  | PsKernelCoreResult.ok _ => "ACCEPTED"
  | PsKernelCoreResult.error message => String.Internal.append "REJECTED: " message

def main : IO Unit := do
  match psKernelCoreAddNonRecursiveInductive
      128 psKernelCoreEnvironmentEmpty psKcDiagFamilyInfo psKcDiagCtors with
  | PsKernelCoreResult.error message =>
      throw (IO.userError (String.Internal.append "diagnostic family failed: " message))
  | PsKernelCoreResult.ok env =>
      let malformedType : PsKernelCoreRecursorInfo := {
        psKcDiagGoodInfo with
        base := { psKcDiagGoodInfo.base with type := psKcDiagFamilyExpr }
      }
      let wrongBranchRule : PsKernelCoreRecursorRule := {
        psKcDiagOffRule with rhs := psKcDiagOnRule.rhs
      }
      let wrongBranch : PsKernelCoreRecursorInfo := {
        psKcDiagGoodInfo with
        rules := PsKernelCoreList.cons wrongBranchRule
          (PsKernelCoreList.cons psKcDiagOnRule PsKernelCoreList.nil)
      }
      IO.println (String.Internal.append "MALFORMED_TYPE="
        (psKcDiagStatus (psKernelCoreAddRecursor 128 env malformedType)))
      IO.println (String.Internal.append "WRONG_BRANCH="
        (psKcDiagStatus (psKernelCoreAddRecursor 128 env wrongBranch)))
