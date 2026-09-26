import Ps.PSCKernel.Core.QuotientAdmission

structure PsCKernelQuotientAdmissionNamedTest where
  name : String
  passed : Bool

def psCKernelQuotAdmissionTestName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelQuotAdmissionArrow
    (domain codomain : PsCKernelExpr) : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionTestName "_") domain codomain PsCKernelBinderInfo.default

def psCKernelQuotAdmissionEqType (uName : PsCKernelName) : PsCKernelExpr :=
  let u := PsCKernelLevel.param uName
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionTestName "α")
    (PsCKernelExpr.sortE u)
    (psCKernelQuotAdmissionArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotAdmissionArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero)))
    PsCKernelBinderInfo.implicit

def psCKernelQuotAdmissionEqReflType (uName : PsCKernelName) : PsCKernelExpr :=
  let u := PsCKernelLevel.param uName
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionTestName "α")
    (PsCKernelExpr.sortE u)
    (PsCKernelExpr.forallE
      (psCKernelQuotAdmissionTestName "a")
      (PsCKernelExpr.bvar 0)
      (psCKernelExprMkAppN
        (PsCKernelExpr.constE (psCKernelQuotAdmissionTestName "Eq") [u])
        [PsCKernelExpr.bvar 1, PsCKernelExpr.bvar 0, PsCKernelExpr.bvar 0])
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.implicit

def psCKernelQuotAdmissionBase
    (name : PsCKernelName)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantVal := {
  name := name
  levelParams := levelParams
  declType := declType
}

def psCKernelQuotAdmissionAddRaw
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | some next => next
  | none => env

def psCKernelQuotAdmissionSeedEq
    (eqTypeOverride : Option PsCKernelExpr := none)
    (reflTypeOverride : Option PsCKernelExpr := none)
    (extraCtor : Bool := false)
    (eqAsAxiom : Bool := false)
    (uParams : List PsCKernelName := [psCKernelQuotAdmissionTestName "u"]) : PsCKernelEnvironment :=
  let uName :=
    match uParams with
    | head :: _ => head
    | [] => psCKernelQuotAdmissionTestName "u"
  let eqName := psCKernelQuotAdmissionTestName "Eq"
  let reflName := psCKernelQuotAdmissionTestName "Eq.refl"
  let extraName := psCKernelQuotAdmissionTestName "Eq.extra"
  let eqType :=
    match eqTypeOverride with
    | some type => type
    | none => psCKernelQuotAdmissionEqType uName
  let reflType :=
    match reflTypeOverride with
    | some type => type
    | none => psCKernelQuotAdmissionEqReflType uName
  let env0 := psCKernelEnvironmentEmpty
  let eqInfo :=
    if eqAsAxiom then
      PsCKernelConstantInfo.axiomInfo {
        base := psCKernelQuotAdmissionBase eqName uParams eqType
        isUnsafe := false
      }
    else
      PsCKernelConstantInfo.inductInfo {
        base := psCKernelQuotAdmissionBase eqName uParams eqType
        numParams := 2
        numIndices := 1
        all := [eqName]
        ctors := if extraCtor then [reflName, extraName] else [reflName]
        numNested := 0
        isRec := false
        isUnsafe := false
        isReflexive := false
      }
  let env1 := psCKernelQuotAdmissionAddRaw env0 eqInfo
  let reflInfo := PsCKernelConstantInfo.ctorInfo {
    base := psCKernelQuotAdmissionBase reflName [uName] reflType
    induct := eqName
    cidx := 0
    numParams := 2
    numFields := 0
    isUnsafe := false
  }
  let env2 := psCKernelQuotAdmissionAddRaw env1 reflInfo
  if extraCtor then
    psCKernelQuotAdmissionAddRaw env2 (PsCKernelConstantInfo.ctorInfo {
      base := psCKernelQuotAdmissionBase extraName [uName] reflType
      induct := eqName
      cidx := 1
      numParams := 2
      numFields := 0
      isUnsafe := false
    })
  else
    env2

def psCKernelQuotAdmissionContainsAll (env : PsCKernelEnvironment) : Bool :=
  psCKernelEnvironmentContains env (psCKernelQuotAdmissionTestName "Quot") &&
  psCKernelEnvironmentContains env (psCKernelQuotAdmissionTestName "Quot.mk") &&
  psCKernelEnvironmentContains env (psCKernelQuotAdmissionTestName "Quot.lift") &&
  psCKernelEnvironmentContains env (psCKernelQuotAdmissionTestName "Quot.ind")

def psCKernelQuotAdmissionTestValid : Bool :=
  match psCKernelAddQuot? psCKernelQuotAdmissionSeedEq with
  | some env =>
      env.quotInitialized &&
      psCKernelQuotAdmissionContainsAll env &&
      Nat.beq (psCKernelEnvironmentSize env) 6
  | none => false

def psCKernelQuotAdmissionTestKinds : Bool :=
  match psCKernelAddQuot? psCKernelQuotAdmissionSeedEq with
  | none => false
  | some env =>
      match
        psCKernelEnvironmentFind? env (psCKernelQuotAdmissionTestName "Quot"),
        psCKernelEnvironmentFind? env (psCKernelQuotAdmissionTestName "Quot.mk"),
        psCKernelEnvironmentFind? env (psCKernelQuotAdmissionTestName "Quot.lift"),
        psCKernelEnvironmentFind? env (psCKernelQuotAdmissionTestName "Quot.ind") with
      | some (PsCKernelConstantInfo.quotInfo q),
        some (PsCKernelConstantInfo.quotInfo mk),
        some (PsCKernelConstantInfo.quotInfo lift),
        some (PsCKernelConstantInfo.quotInfo ind) =>
          match q.kind, mk.kind, lift.kind, ind.kind with
          | PsCKernelQuotKind.type,
            PsCKernelQuotKind.ctor,
            PsCKernelQuotKind.lift,
            PsCKernelQuotKind.ind => true
          | _, _, _, _ => false
      | _, _, _, _ => false

def psCKernelQuotAdmissionTestIdempotent : Bool :=
  match psCKernelAddQuot? psCKernelQuotAdmissionSeedEq with
  | none => false
  | some once =>
      match psCKernelAddQuot? once with
      | none => false
      | some twice =>
          Nat.beq (psCKernelEnvironmentSize once) (psCKernelEnvironmentSize twice) &&
          twice.quotInitialized

def psCKernelQuotAdmissionTestMissingEq : Bool :=
  match psCKernelAddQuot? psCKernelEnvironmentEmpty with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionTestEqWrongKind : Bool :=
  match psCKernelAddQuot? (psCKernelQuotAdmissionSeedEq (eqAsAxiom := true)) with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionTestEqWrongUniverseArity : Bool :=
  let u := psCKernelQuotAdmissionTestName "u"
  let v := psCKernelQuotAdmissionTestName "v"
  match psCKernelAddQuot? (psCKernelQuotAdmissionSeedEq (uParams := [u, v])) with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionTestEqWrongCtorCount : Bool :=
  match psCKernelAddQuot? (psCKernelQuotAdmissionSeedEq (extraCtor := true)) with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionTestEqWrongType : Bool :=
  let bad := PsCKernelExpr.sortE psCKernelLevelZero
  match psCKernelAddQuot? (psCKernelQuotAdmissionSeedEq (eqTypeOverride := some bad)) with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionTestReflWrongType : Bool :=
  let bad := PsCKernelExpr.sortE psCKernelLevelZero
  match psCKernelAddQuot? (psCKernelQuotAdmissionSeedEq (reflTypeOverride := some bad)) with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionConflict (name : String) : Bool :=
  let env0 := psCKernelQuotAdmissionSeedEq
  let conflict := PsCKernelConstantInfo.axiomInfo {
    base := psCKernelQuotAdmissionBase
      (psCKernelQuotAdmissionTestName name)
      []
      (PsCKernelExpr.sortE psCKernelLevelZero)
    isUnsafe := false
  }
  let env := psCKernelQuotAdmissionAddRaw env0 conflict
  match psCKernelAddQuot? env with
  | none => true
  | some _ => false

def psCKernelQuotAdmissionTestFailurePersistent : Bool :=
  let env := psCKernelQuotAdmissionSeedEq (eqTypeOverride := some (PsCKernelExpr.sortE psCKernelLevelZero))
  let before := psCKernelEnvironmentSize env
  let _ := psCKernelAddQuot? env
  Nat.beq before (psCKernelEnvironmentSize env) && !env.quotInitialized

def psCKernelQuotientAdmissionTests : List PsCKernelQuotientAdmissionNamedTest := [
  { name := "valid Eq environment initializes quotient primitives", passed := psCKernelQuotAdmissionTestValid },
  { name := "installed quotient metadata has all four Lean kinds", passed := psCKernelQuotAdmissionTestKinds },
  { name := "quotient initialization is idempotent", passed := psCKernelQuotAdmissionTestIdempotent },
  { name := "missing Eq rejects quotient initialization", passed := psCKernelQuotAdmissionTestMissingEq },
  { name := "Eq must be an inductive declaration", passed := psCKernelQuotAdmissionTestEqWrongKind },
  { name := "Eq must have exactly one universe parameter", passed := psCKernelQuotAdmissionTestEqWrongUniverseArity },
  { name := "Eq must have exactly one constructor", passed := psCKernelQuotAdmissionTestEqWrongCtorCount },
  { name := "Eq type shape is checked exactly", passed := psCKernelQuotAdmissionTestEqWrongType },
  { name := "Eq.refl type shape is checked exactly", passed := psCKernelQuotAdmissionTestReflWrongType },
  { name := "existing Quot name rejects initialization", passed := psCKernelQuotAdmissionConflict "Quot" },
  { name := "existing Quot.mk name rejects initialization", passed := psCKernelQuotAdmissionConflict "Quot.mk" },
  { name := "existing Quot.lift name rejects initialization", passed := psCKernelQuotAdmissionConflict "Quot.lift" },
  { name := "existing Quot.ind name rejects initialization", passed := psCKernelQuotAdmissionConflict "Quot.ind" },
  { name := "failed quotient initialization preserves original environment", passed := psCKernelQuotAdmissionTestFailurePersistent }
]

def psCKernelRunQuotientAdmissionTests
    (tests : List PsCKernelQuotientAdmissionNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_QUOTIENT_ADMISSION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_QUOTIENT_ADMISSION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunQuotientAdmissionTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunQuotientAdmissionTests psCKernelQuotientAdmissionTests
  if passed then
    IO.println "PSCKERNEL_QUOTIENT_ADMISSION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_QUOTIENT_ADMISSION_TESTS: FAIL")
