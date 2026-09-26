import Ps.PSCKernel.Core.DefEqBasic

structure PsCKernelDefEqBasicNamedTest where
  name : String
  passed : Bool

def psCKernelDefEqBasicName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDefEqBasicConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDefEqBasicName text) []

def psCKernelDefEqBasicAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqBasicName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelDefEqBasicDefinition
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelDefEqBasicName name
      levelParams := levelParams
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelDefEqBasicTheorem
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := {
      name := psCKernelDefEqBasicName name
      levelParams := []
      declType := declType
    }
    value := value
    all := []
  }

def psCKernelDefEqBasicAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelDefEqBasicEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelDefEqBasicConst "A"
  let env0 := psCKernelDefEqBasicAdd
    psCKernelEnvironmentEmpty (psCKernelDefEqBasicAxiom "A" sort0)
  let env1 := psCKernelDefEqBasicAdd
    env0 (psCKernelDefEqBasicAxiom "a" aType)
  let env2 := psCKernelDefEqBasicAdd
    env1
    (psCKernelDefEqBasicDefinition
      "alias" [] aType (psCKernelDefEqBasicConst "a"))
  let idType := PsCKernelExpr.forallE
    (psCKernelDefEqBasicName "x") aType aType PsCKernelBinderInfo.default
  let idValue := PsCKernelExpr.lam
    (psCKernelDefEqBasicName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let env3 := psCKernelDefEqBasicAdd
    env2 (psCKernelDefEqBasicDefinition "id" [] idType idValue)
  psCKernelDefEqBasicAdd
    env3
    (psCKernelDefEqBasicTheorem
      "hidden" aType (psCKernelDefEqBasicConst "a"))

def psCKernelDefEqBasicTestStructural : Bool :=
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (psCKernelDefEqBasicConst "a") (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestBinderPresentation : Bool :=
  let aType := psCKernelDefEqBasicConst "A"
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (PsCKernelExpr.lam
      (psCKernelDefEqBasicName "x") aType (PsCKernelExpr.bvar 0)
      PsCKernelBinderInfo.default)
    (PsCKernelExpr.lam
      (psCKernelDefEqBasicName "renamed") aType (PsCKernelExpr.bvar 0)
      PsCKernelBinderInfo.implicit)

def psCKernelDefEqBasicTestSortLevelEquivalence : Bool :=
  let u := psCKernelLevelParam (psCKernelDefEqBasicName "u")
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (PsCKernelExpr.sortE (psCKernelLevelMkMax u u))
    (PsCKernelExpr.sortE u)

def psCKernelDefEqBasicTestConstLevelEquivalence : Bool :=
  let uName := psCKernelDefEqBasicName "u"
  let u := psCKernelLevelParam uName
  let polyInfo := psCKernelDefEqBasicAxiom "Poly" (PsCKernelExpr.sortE u)
  let polyInfo :=
    match polyInfo with
    | PsCKernelConstantInfo.axiomInfo value =>
        PsCKernelConstantInfo.axiomInfo {
          value with base := { value.base with levelParams := [uName] }
        }
    | other => other
  let env := psCKernelDefEqBasicAdd psCKernelDefEqBasicEnv polyInfo
  psCKernelIsDefEqBasic
    env psCKernelLocalContextEmpty
    (PsCKernelExpr.constE
      (psCKernelDefEqBasicName "Poly") [psCKernelLevelMkMax u u])
    (PsCKernelExpr.constE (psCKernelDefEqBasicName "Poly") [u])

def psCKernelDefEqBasicTestBeta : Bool :=
  let aType := psCKernelDefEqBasicConst "A"
  let beta := PsCKernelExpr.app
    (PsCKernelExpr.lam
      (psCKernelDefEqBasicName "x") aType (PsCKernelExpr.bvar 0)
      PsCKernelBinderInfo.default)
    (psCKernelDefEqBasicConst "a")
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    beta (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestZeta : Bool :=
  let aType := psCKernelDefEqBasicConst "A"
  let zeta := PsCKernelExpr.letE
    (psCKernelDefEqBasicName "x") aType
    (psCKernelDefEqBasicConst "a")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    zeta (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestDelta : Bool :=
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (psCKernelDefEqBasicConst "alias")
    (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestDeltaBeta : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelDefEqBasicConst "id") (psCKernelDefEqBasicConst "a")
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    expr (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestLocalLet : Bool :=
  let id : PsCKernelFVarId := { name := psCKernelDefEqBasicName "xId" }
  let ctx := psCKernelLocalContextMkLetDecl
    psCKernelLocalContextEmpty id (psCKernelDefEqBasicName "x")
    (psCKernelDefEqBasicConst "A") (psCKernelDefEqBasicConst "a")
    false PsCKernelLocalDeclKind.default
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv ctx
    (PsCKernelExpr.fvar id) (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestDifferentConstants : Bool :=
  !psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (psCKernelDefEqBasicConst "A") (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTestDifferentAppArgs : Bool :=
  let fn := psCKernelDefEqBasicConst "f"
  !psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (PsCKernelExpr.app fn (psCKernelDefEqBasicConst "A"))
    (PsCKernelExpr.app fn (psCKernelDefEqBasicConst "a"))

def psCKernelDefEqBasicTestPiRecursive : Bool :=
  let u := psCKernelLevelParam (psCKernelDefEqBasicName "u")
  let left := PsCKernelExpr.forallE
    (psCKernelDefEqBasicName "x")
    (PsCKernelExpr.sortE (psCKernelLevelMkMax u u))
    (PsCKernelExpr.sortE u)
    PsCKernelBinderInfo.default
  let right := PsCKernelExpr.forallE
    (psCKernelDefEqBasicName "y")
    (PsCKernelExpr.sortE u)
    (PsCKernelExpr.sortE (psCKernelLevelMkMax u u))
    PsCKernelBinderInfo.implicit
  psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty left right

def psCKernelDefEqBasicTestTheoremOpaque : Bool :=
  !psCKernelIsDefEqBasic
    psCKernelDefEqBasicEnv psCKernelLocalContextEmpty
    (psCKernelDefEqBasicConst "hidden") (psCKernelDefEqBasicConst "a")

def psCKernelDefEqBasicTests : List PsCKernelDefEqBasicNamedTest := [
  { name := "structural equality succeeds", passed := psCKernelDefEqBasicTestStructural },
  { name := "binder presentation is ignored", passed := psCKernelDefEqBasicTestBinderPresentation },
  { name := "sort levels compare modulo normalization", passed := psCKernelDefEqBasicTestSortLevelEquivalence },
  { name := "constant levels compare modulo normalization", passed := psCKernelDefEqBasicTestConstLevelEquivalence },
  { name := "beta conversion is definitional equality", passed := psCKernelDefEqBasicTestBeta },
  { name := "zeta conversion is definitional equality", passed := psCKernelDefEqBasicTestZeta },
  { name := "definition delta conversion is equality", passed := psCKernelDefEqBasicTestDelta },
  { name := "delta can expose beta conversion", passed := psCKernelDefEqBasicTestDeltaBeta },
  { name := "dependent local let unfolds", passed := psCKernelDefEqBasicTestLocalLet },
  { name := "different constants remain unequal", passed := psCKernelDefEqBasicTestDifferentConstants },
  { name := "different application arguments remain unequal", passed := psCKernelDefEqBasicTestDifferentAppArgs },
  { name := "Pi comparison recurses through level-equivalent fields", passed := psCKernelDefEqBasicTestPiRecursive },
  { name := "theorem values remain opaque in basic defeq", passed := psCKernelDefEqBasicTestTheoremOpaque }
]

def psCKernelRunDefEqBasicTests
    (tests : List PsCKernelDefEqBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_DEFEQ_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_DEFEQ_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunDefEqBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunDefEqBasicTests psCKernelDefEqBasicTests
  if passed then
    IO.println "PSCKERNEL_DEFEQ_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_DEFEQ_BASIC_TESTS: FAIL")
