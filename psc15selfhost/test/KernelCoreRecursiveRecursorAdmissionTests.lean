import Ps.KernelCore

def psP12Anon : PsKernelCoreName := PsKernelCoreName.anonymous

def psP12Family : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "Phase12List"

def psP12Nil : PsKernelCoreName :=
  PsKernelCoreName.str psP12Family "nil"

def psP12Cons : PsKernelCoreName :=
  PsKernelCoreName.str psP12Family "cons"

def psP12Rec : PsKernelCoreName :=
  PsKernelCoreName.str psP12Family "rec"

def psP12MotiveI : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "_p12Motive"

def psP12MinorNilI : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "_p12MinorNil"

def psP12MinorConsI : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "_p12MinorCons"

def psP12TailI : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "_p12Tail"

def psP12IhI : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "_p12Ih"

def psP12MajorI : PsKernelCoreName :=
  PsKernelCoreName.str psP12Anon "_p12Major"

def psP12Sort1 : PsKernelCoreExpr :=
  PsKernelCoreExpr.sort (PsKernelCoreLevel.succ PsKernelCoreLevel.zero)

def psP12Levels : PsKernelCoreList PsKernelCoreLevel :=
  PsKernelCoreList.nil

def psP12Target : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12Family psP12Levels

def psP12NilExpr : PsKernelCoreExpr :=
  PsKernelCoreExpr.const psP12Nil psP12Levels

def psP12Motive : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MotiveI

def psP12MinorNil : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MinorNilI

def psP12MinorCons : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MinorConsI

def psP12Tail : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12TailI

def psP12Ih : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12IhI

def psP12Major : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar psP12MajorI

def psP12CloseForall
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE psP12Anon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12CloseLam
    (internalName : PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (body : PsKernelCoreExpr) : PsKernelCoreExpr :=
  PsKernelCoreExpr.lam psP12Anon type
    (psKernelCoreExprAbstractFVar body internalName)
    PsKernelCoreBinderInfo.default

def psP12ConsOpen : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.const psP12Cons psP12Levels)
    psP12Tail

def psP12FamilyInfo : PsKernelCoreInductiveInfo := {
  base := {
    name := psP12Family
    levelParams := PsKernelCoreList.nil
    type := psP12Sort1
  }
  numParams := 0
  numIndices := 0
  all := PsKernelCoreList.cons psP12Family PsKernelCoreList.nil
  ctors :=
    PsKernelCoreList.cons psP12Nil
      (PsKernelCoreList.cons psP12Cons PsKernelCoreList.nil)
  numNested := 0
  isRec := false
  isReflexive := false
  isUnsafe := false
}

def psP12NilCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12Nil
    levelParams := PsKernelCoreList.nil
    type := psP12Target
  }
  induct := psP12Family
  cidx := 0
  numParams := 0
  numFields := 0
  isUnsafe := false
}

def psP12ConsCtorType : PsKernelCoreExpr :=
  PsKernelCoreExpr.forallE
    psP12Anon psP12Target psP12Target PsKernelCoreBinderInfo.default

def psP12ConsCtor : PsKernelCoreConstructorInfo := {
  base := {
    name := psP12Cons
    levelParams := PsKernelCoreList.nil
    type := psP12ConsCtorType
  }
  induct := psP12Family
  cidx := 1
  numParams := 0
  numFields := 1
  isUnsafe := false
}

def psP12Constructors : PsKernelCoreList PsKernelCoreConstructorInfo :=
  PsKernelCoreList.cons psP12NilCtor
    (PsKernelCoreList.cons psP12ConsCtor PsKernelCoreList.nil)

def psP12MotiveType : PsKernelCoreExpr :=
  psP12CloseForall psP12MajorI psP12Target psP12Sort1

def psP12MinorNilType : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12Motive psP12NilExpr

def psP12MinorConsType : PsKernelCoreExpr :=
  psP12CloseForall psP12TailI psP12Target
    (psP12CloseForall psP12IhI
      (PsKernelCoreExpr.app psP12Motive psP12Tail)
      (PsKernelCoreExpr.app psP12Motive psP12ConsOpen))

def psP12RecType : PsKernelCoreExpr :=
  psP12CloseForall psP12MotiveI psP12MotiveType
    (psP12CloseForall psP12MinorNilI psP12MinorNilType
      (psP12CloseForall psP12MinorConsI psP12MinorConsType
        (psP12CloseForall psP12MajorI psP12Target
          (PsKernelCoreExpr.app psP12Motive psP12Major))))

def psP12NilRuleRhs : PsKernelCoreExpr :=
  psP12CloseLam psP12MotiveI psP12MotiveType
    (psP12CloseLam psP12MinorNilI psP12MinorNilType
      (psP12CloseLam psP12MinorConsI psP12MinorConsType
        psP12MinorNil))

def psP12RecursiveCall : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app
      (PsKernelCoreExpr.app
        (PsKernelCoreExpr.const psP12Rec psP12Levels)
        psP12Motive)
      psP12MinorNil)
    psP12MinorCons

def psP12RecursiveCallOnTail : PsKernelCoreExpr :=
  PsKernelCoreExpr.app psP12RecursiveCall psP12Tail

def psP12ConsRuleBody : PsKernelCoreExpr :=
  PsKernelCoreExpr.app
    (PsKernelCoreExpr.app psP12MinorCons psP12Tail)
    psP12RecursiveCallOnTail

def psP12ConsRuleRhs : PsKernelCoreExpr :=
  psP12CloseLam psP12MotiveI psP12MotiveType
    (psP12CloseLam psP12MinorNilI psP12MinorNilType
      (psP12CloseLam psP12MinorConsI psP12MinorConsType
        (psP12CloseLam psP12TailI psP12Target psP12ConsRuleBody)))

def psP12RecInfo : PsKernelCoreRecursorInfo := {
  base := {
    name := psP12Rec
    levelParams := PsKernelCoreList.nil
    type := psP12RecType
  }
  all := PsKernelCoreList.cons psP12Family PsKernelCoreList.nil
  numParams := 0
  numIndices := 0
  numMotives := 1
  numMinors := 2
  rules :=
    PsKernelCoreList.cons
      { ctor := psP12Nil, nFields := 0, rhs := psP12NilRuleRhs }
      (PsKernelCoreList.cons
        { ctor := psP12Cons, nFields := 1, rhs := psP12ConsRuleRhs }
        PsKernelCoreList.nil)
  k := false
  isUnsafe := false
}

def psP12DirectAdmission : PsKernelCoreResult String Unit :=
  match psKernelCoreAddRecursiveInductive
      256 psKernelCoreEnvironmentEmpty psP12FamilyInfo psP12Constructors with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error ("recursive family admission failed: " ++ message)
  | PsKernelCoreResult.ok familyEnv =>
      match psKernelCoreEnvironmentFind? familyEnv psP12Family with
      | PsKernelCoreOption.some (PsKernelCoreConstantInfo.inductInfo storedFamily) =>
          if storedFamily.isRec then
            match psKernelCoreAddRecursor 512 familyEnv psP12RecInfo with
            | PsKernelCoreResult.error message => PsKernelCoreResult.error message
            | PsKernelCoreResult.ok env =>
                match psKernelCoreEnvironmentFind? env psP12Rec with
                | PsKernelCoreOption.some (PsKernelCoreConstantInfo.recInfo info) =>
                    if psKernelCoreNameEq info.base.name psP12Rec then
                      PsKernelCoreResult.ok Unit.unit
                    else
                      PsKernelCoreResult.error "stored recursive recursor name mismatch"
                | _ => PsKernelCoreResult.error "recursive recursor was not stored"
          else
            PsKernelCoreResult.error "recursive family was not classified recursive"
      | _ => PsKernelCoreResult.error "recursive family metadata missing"

def main : IO Unit := do
  match psP12DirectAdmission with
  | PsKernelCoreResult.ok _ =>
      IO.println "PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_ADMISSION: PASS"
  | PsKernelCoreResult.error message =>
      throw (IO.userError
        ("PSC2_KERNEL_CORE_PHASE12_RECURSIVE_RECURSOR_ADMISSION: FAIL: " ++ message))
