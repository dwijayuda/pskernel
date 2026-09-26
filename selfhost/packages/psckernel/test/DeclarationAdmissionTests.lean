import Ps.PSCKernel.Core.DeclarationAdmission

structure PsCKernelDeclarationAdmissionNamedTest where
  name : String
  passed : Bool

def psCKernelAdmissionName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelAdmissionBase
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantVal := {
  name := psCKernelAdmissionName name
  levelParams := levelParams
  declType := declType
}

def psCKernelAdmissionAxiom
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := psCKernelAdmissionBase name levelParams declType
    isUnsafe := false
  }

def psCKernelAdmissionDef
    (name : String)
    (levelParams : List PsCKernelName)
    (declType value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := psCKernelAdmissionBase name levelParams declType
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := [psCKernelAdmissionName name]
  }

def psCKernelAdmissionThm
    (name : String)
    (declType value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := psCKernelAdmissionBase name [] declType
    value := value
    all := [psCKernelAdmissionName name]
  }

def psCKernelAdmissionOpaque
    (name : String)
    (declType value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.opaqueInfo {
    base := psCKernelAdmissionBase name [] declType
    value := value
    isUnsafe := false
    all := [psCKernelAdmissionName name]
  }

def psCKernelAdmissionPropName : PsCKernelName :=
  psCKernelAdmissionName "P"

def psCKernelAdmissionProofName : PsCKernelName :=
  psCKernelAdmissionName "p"

def psCKernelAdmissionSeedEnv : PsCKernelEnvironment :=
  let env0 := psCKernelEnvironmentEmpty
  let pInfo := psCKernelAdmissionAxiom
    "P" [] (PsCKernelExpr.sortE psCKernelLevelZero)
  let env1 :=
    match psCKernelEnvironmentAdd? env0 pInfo with
    | some env => env
    | none => env0
  let proofInfo := psCKernelAdmissionAxiom
    "p" [] (PsCKernelExpr.constE psCKernelAdmissionPropName [])
  match psCKernelEnvironmentAdd? env1 proofInfo with
  | some env => env
  | none => env1

def psCKernelAdmissionTestValidAxiom : Bool :=
  let info := psCKernelAdmissionAxiom
    "A" [] (PsCKernelExpr.sortE psCKernelLevelZero)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => false
  | some env => psCKernelEnvironmentContains env (psCKernelAdmissionName "A")

def psCKernelAdmissionTestDuplicateName : Bool :=
  let info := psCKernelAdmissionAxiom
    "P" [] (PsCKernelExpr.sortE psCKernelLevelZero)
  match psCKernelAdmitConstant? psCKernelAdmissionSeedEnv info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestDuplicateLevelParams : Bool :=
  let u := psCKernelAdmissionName "u"
  let info := psCKernelAdmissionAxiom
    "A" [u, u] (PsCKernelExpr.sortE (PsCKernelLevel.param u))
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestDeclaredLevelParam : Bool :=
  let u := psCKernelAdmissionName "u"
  let info := psCKernelAdmissionAxiom
    "Poly" [u] (PsCKernelExpr.sortE (PsCKernelLevel.param u))
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | some _ => true
  | none => false

def psCKernelAdmissionTestUndefinedLevelParam : Bool :=
  let u := psCKernelAdmissionName "u"
  let info := psCKernelAdmissionAxiom
    "BadPoly" [] (PsCKernelExpr.sortE (PsCKernelLevel.param u))
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestTypeMustBeType : Bool :=
  let info := psCKernelAdmissionAxiom
    "badType" [] (PsCKernelExpr.constE psCKernelAdmissionProofName [])
  match psCKernelAdmitConstant? psCKernelAdmissionSeedEnv info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestFreeVarClosed : Bool :=
  let fvarId : PsCKernelFVarId := { name := psCKernelAdmissionName "free" }
  let info := psCKernelAdmissionAxiom "freeType" [] (PsCKernelExpr.fvar fvarId)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestLooseBVarClosed : Bool :=
  let info := psCKernelAdmissionAxiom "loose" [] (PsCKernelExpr.bvar 0)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestMVarClosed : Bool :=
  let mvarId : PsCKernelMVarId := { name := psCKernelAdmissionName "m" }
  let info := psCKernelAdmissionAxiom "meta" [] (PsCKernelExpr.mvar mvarId)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestValidDefinition : Bool :=
  let info := psCKernelAdmissionDef
    "U"
    []
    (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero))
    (PsCKernelExpr.sortE psCKernelLevelZero)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | some env => psCKernelEnvironmentContains env (psCKernelAdmissionName "U")
  | none => false

def psCKernelAdmissionTestDefinitionMismatch : Bool :=
  let info := psCKernelAdmissionDef
    "badDef"
    []
    (PsCKernelExpr.sortE psCKernelLevelZero)
    (PsCKernelExpr.sortE psCKernelLevelZero)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestDefinitionValueClosed : Bool :=
  let fvarId : PsCKernelFVarId := { name := psCKernelAdmissionName "free" }
  let info := psCKernelAdmissionDef
    "badValue"
    []
    (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero))
    (PsCKernelExpr.fvar fvarId)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestValidTheorem : Bool :=
  let info := psCKernelAdmissionThm
    "T"
    (PsCKernelExpr.constE psCKernelAdmissionPropName [])
    (PsCKernelExpr.constE psCKernelAdmissionProofName [])
  match psCKernelAdmitConstant? psCKernelAdmissionSeedEnv info with
  | some env => psCKernelEnvironmentContains env (psCKernelAdmissionName "T")
  | none => false

def psCKernelAdmissionTestTheoremRequiresProp : Bool :=
  let info := psCKernelAdmissionThm
    "notTheorem"
    (PsCKernelExpr.sortE psCKernelLevelZero)
    (PsCKernelExpr.constE psCKernelAdmissionProofName [])
  match psCKernelAdmitConstant? psCKernelAdmissionSeedEnv info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestValidOpaque : Bool :=
  let info := psCKernelAdmissionOpaque
    "O"
    (PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero))
    (PsCKernelExpr.sortE psCKernelLevelZero)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | some env => psCKernelEnvironmentContains env (psCKernelAdmissionName "O")
  | none => false

def psCKernelAdmissionTestOpaqueMismatch : Bool :=
  let info := psCKernelAdmissionOpaque
    "badOpaque"
    (PsCKernelExpr.sortE psCKernelLevelZero)
    (PsCKernelExpr.sortE psCKernelLevelZero)
  match psCKernelAdmitConstant? psCKernelEnvironmentEmpty info with
  | none => true
  | some _ => false

def psCKernelAdmissionTestFailurePersistent : Bool :=
  let before := psCKernelEnvironmentNumConstants psCKernelAdmissionSeedEnv
  let info := psCKernelAdmissionDef
    "badTxn"
    []
    (PsCKernelExpr.sortE psCKernelLevelZero)
    (PsCKernelExpr.sortE psCKernelLevelZero)
  let _ := psCKernelAdmitConstant? psCKernelAdmissionSeedEnv info
  Nat.beq before (psCKernelEnvironmentNumConstants psCKernelAdmissionSeedEnv)

def psCKernelDeclarationAdmissionTests : List PsCKernelDeclarationAdmissionNamedTest := [
  { name := "valid axiom is admitted", passed := psCKernelAdmissionTestValidAxiom },
  { name := "duplicate declaration name is rejected", passed := psCKernelAdmissionTestDuplicateName },
  { name := "duplicate universe parameter is rejected", passed := psCKernelAdmissionTestDuplicateLevelParams },
  { name := "declared universe parameter is accepted", passed := psCKernelAdmissionTestDeclaredLevelParam },
  { name := "undefined universe parameter is rejected", passed := psCKernelAdmissionTestUndefinedLevelParam },
  { name := "declaration type must itself be a type", passed := psCKernelAdmissionTestTypeMustBeType },
  { name := "free variable in declaration type is rejected", passed := psCKernelAdmissionTestFreeVarClosed },
  { name := "loose bound variable in declaration type is rejected", passed := psCKernelAdmissionTestLooseBVarClosed },
  { name := "metavariable in declaration type is rejected", passed := psCKernelAdmissionTestMVarClosed },
  { name := "valid definition is admitted", passed := psCKernelAdmissionTestValidDefinition },
  { name := "definition value type mismatch is rejected", passed := psCKernelAdmissionTestDefinitionMismatch },
  { name := "free variable in definition value is rejected", passed := psCKernelAdmissionTestDefinitionValueClosed },
  { name := "valid theorem proof is admitted", passed := psCKernelAdmissionTestValidTheorem },
  { name := "theorem declaration must be a proposition", passed := psCKernelAdmissionTestTheoremRequiresProp },
  { name := "valid opaque declaration is admitted", passed := psCKernelAdmissionTestValidOpaque },
  { name := "opaque value type mismatch is rejected", passed := psCKernelAdmissionTestOpaqueMismatch },
  { name := "failed admission preserves original persistent environment", passed := psCKernelAdmissionTestFailurePersistent }
]

def psCKernelRunDeclarationAdmissionTests
    (tests : List PsCKernelDeclarationAdmissionNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_DECLARATION_ADMISSION_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_DECLARATION_ADMISSION_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunDeclarationAdmissionTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunDeclarationAdmissionTests psCKernelDeclarationAdmissionTests
  if passed then
    IO.println "PSCKERNEL_DECLARATION_ADMISSION_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_DECLARATION_ADMISSION_TESTS: FAIL")
