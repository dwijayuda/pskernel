import Ps.KernelCore

def psKcQuotRejectAnon : PsKernelCoreName :=
  PsKernelCoreName.anonymous

def psKcQuotRejectOtherName : PsKernelCoreName :=
  PsKernelCoreName.str psKcQuotRejectAnon "Other"

def psKcQuotRejectOneName
    (name : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons name PsKernelCoreList.nil

def psKcQuotRejectTwoNames
    (first : PsKernelCoreName)
    (second : PsKernelCoreName) : PsKernelCoreList PsKernelCoreName :=
  PsKernelCoreList.cons first
    (PsKernelCoreList.cons second PsKernelCoreList.nil)

def psKcQuotRejectBase
    (name : PsKernelCoreName)
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreConstantBase :=
  {
    name := name
    levelParams := levelParams
    type := type
  }

def psKcQuotRejectAxiom
    (name : PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreConstantInfo :=
  PsKernelCoreConstantInfo.axiomInfo {
    base := psKcQuotRejectBase name PsKernelCoreList.nil type
    isUnsafe := false
  }

def psKcQuotRejectEqInfoWith
    (levelParams : PsKernelCoreList PsKernelCoreName)
    (type : PsKernelCoreExpr)
    (ctors : PsKernelCoreList PsKernelCoreName) : PsKernelCoreInductiveInfo :=
  {
    base := psKcQuotRejectBase psKernelCoreQuotEqName levelParams type
    numParams := 1
    numIndices := 2
    all := psKcQuotRejectOneName psKernelCoreQuotEqName
    ctors := ctors
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := false
  }

def psKcQuotRejectValidEqInfo : PsKernelCoreInductiveInfo :=
  psKcQuotRejectEqInfoWith
    (psKcQuotRejectOneName psKernelCoreQuotUName)
    (psKernelCoreQuotExpectedEqType psKernelCoreQuotUName)
    (psKcQuotRejectOneName psKernelCoreQuotEqReflName)

def psKcQuotRejectReflInfoWith
    (induct : PsKernelCoreName)
    (type : PsKernelCoreExpr) : PsKernelCoreConstructorInfo :=
  {
    base := psKcQuotRejectBase
      psKernelCoreQuotEqReflName
      (psKcQuotRejectOneName psKernelCoreQuotUName)
      type
    induct := induct
    cidx := 0
    numParams := 1
    numFields := 1
    isUnsafe := false
  }

def psKcQuotRejectValidReflInfo : PsKernelCoreConstructorInfo :=
  psKcQuotRejectReflInfoWith
    psKernelCoreQuotEqName
    (psKernelCoreQuotExpectedEqReflType psKernelCoreQuotUName)

def psKcQuotRejectAddInfo
    (env : PsKernelCoreEnvironment)
    (info : PsKernelCoreConstantInfo) : PsKernelCoreEnvironment :=
  psKernelCoreEnvironmentAddUnchecked env info

def psKcQuotRejectValidEqEnvironment : PsKernelCoreEnvironment :=
  let withEq :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo psKcQuotRejectValidEqInfo)
  psKcQuotRejectAddInfo
    withEq
    (PsKernelCoreConstantInfo.ctorInfo psKcQuotRejectValidReflInfo)

def psKcQuotRejectsWithoutChangingOriginal
    (env : PsKernelCoreEnvironment) : Bool :=
  let sizeBefore := psKernelCoreEnvironmentSize env
  let flagBefore := env.quotInitialized
  match psKernelCoreAddQuot env with
  | PsKernelCoreResult.error _ =>
      (psKernelCoreEnvironmentSize env == sizeBefore) &&
      (env.quotInitialized == flagBefore)
  | PsKernelCoreResult.ok _ => false

def psKcQuotRejectCollision
    (name : PsKernelCoreName) : Bool :=
  let collision :=
    psKcQuotRejectAxiom name
      (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
  let env :=
    psKcQuotRejectAddInfo psKcQuotRejectValidEqEnvironment collision
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectMissingEq : Bool :=
  psKcQuotRejectsWithoutChangingOriginal psKernelCoreEnvironmentEmpty

def psKcQuotRejectOrdinaryEq : Bool :=
  let env :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (psKcQuotRejectAxiom
        psKernelCoreQuotEqName
        (psKernelCoreQuotExpectedEqType psKernelCoreQuotUName))
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectWrongEqUniverseArity : Bool :=
  let info :=
    psKcQuotRejectEqInfoWith
      (psKcQuotRejectTwoNames psKernelCoreQuotUName psKernelCoreQuotVName)
      (psKernelCoreQuotExpectedEqType psKernelCoreQuotUName)
      (psKcQuotRejectOneName psKernelCoreQuotEqReflName)
  let env :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo info)
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectWrongCtorList : Bool :=
  let info :=
    psKcQuotRejectEqInfoWith
      (psKcQuotRejectOneName psKernelCoreQuotUName)
      (psKernelCoreQuotExpectedEqType psKernelCoreQuotUName)
      PsKernelCoreList.nil
  let env :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo info)
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectMissingCtor : Bool :=
  let env :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo psKcQuotRejectValidEqInfo)
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectCtorWrongKind : Bool :=
  let withEq :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo psKcQuotRejectValidEqInfo)
  let env :=
    psKcQuotRejectAddInfo
      withEq
      (psKcQuotRejectAxiom
        psKernelCoreQuotEqReflName
        (psKernelCoreQuotExpectedEqReflType psKernelCoreQuotUName))
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectCtorWrongParent : Bool :=
  let withEq :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo psKcQuotRejectValidEqInfo)
  let wrongRefl :=
    psKcQuotRejectReflInfoWith
      psKcQuotRejectOtherName
      (psKernelCoreQuotExpectedEqReflType psKernelCoreQuotUName)
  let env :=
    psKcQuotRejectAddInfo
      withEq
      (PsKernelCoreConstantInfo.ctorInfo wrongRefl)
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectMalformedEqType : Bool :=
  let info :=
    psKcQuotRejectEqInfoWith
      (psKcQuotRejectOneName psKernelCoreQuotUName)
      (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
      (psKcQuotRejectOneName psKernelCoreQuotEqReflName)
  let env :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo info)
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotRejectMalformedReflType : Bool :=
  let withEq :=
    psKcQuotRejectAddInfo
      psKernelCoreEnvironmentEmpty
      (PsKernelCoreConstantInfo.inductInfo psKcQuotRejectValidEqInfo)
  let malformed :=
    psKcQuotRejectReflInfoWith
      psKernelCoreQuotEqName
      (PsKernelCoreExpr.sort PsKernelCoreLevel.zero)
  let env :=
    psKcQuotRejectAddInfo
      withEq
      (PsKernelCoreConstantInfo.ctorInfo malformed)
  psKcQuotRejectsWithoutChangingOriginal env

def psKcQuotAlreadyInitializedIsIdempotent : Bool :=
  let initialized :=
    psKernelCoreEnvironmentMarkQuotInitialized psKernelCoreEnvironmentEmpty
  match psKernelCoreAddQuot initialized with
  | PsKernelCoreResult.error _ => false
  | PsKernelCoreResult.ok env =>
      env.quotInitialized &&
      (psKernelCoreEnvironmentSize env == 0) &&
      (!psKernelCoreEnvironmentContains env psKernelCoreQuotName) &&
      (!psKernelCoreEnvironmentContains env psKernelCoreQuotMkName) &&
      (!psKernelCoreEnvironmentContains env psKernelCoreQuotLiftName) &&
      (!psKernelCoreEnvironmentContains env psKernelCoreQuotIndName)

def psKernelCoreQuotRejectionMatrix : Bool :=
  psKcQuotRejectMissingEq &&
  psKcQuotRejectOrdinaryEq &&
  psKcQuotRejectWrongEqUniverseArity &&
  psKcQuotRejectWrongCtorList &&
  psKcQuotRejectMissingCtor &&
  psKcQuotRejectCtorWrongKind &&
  psKcQuotRejectCtorWrongParent &&
  psKcQuotRejectMalformedEqType &&
  psKcQuotRejectMalformedReflType &&
  psKcQuotRejectCollision psKernelCoreQuotName &&
  psKcQuotRejectCollision psKernelCoreQuotMkName &&
  psKcQuotRejectCollision psKernelCoreQuotLiftName &&
  psKcQuotRejectCollision psKernelCoreQuotIndName &&
  psKcQuotAlreadyInitializedIsIdempotent

def main : IO Unit := do
  if psKernelCoreQuotRejectionMatrix then
    IO.println "PSC2_KERNEL_CORE_QUOT_REJECTIONS: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_QUOT_REJECTIONS: FAIL")
