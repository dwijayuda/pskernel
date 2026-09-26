import Ps.PSCKernel.Core.DefEq

structure PsCKernelDefEqProofNamedTest where
  name : String
  passed : Bool

def psCKernelDefEqProofName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDefEqProofConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDefEqProofName text) []

def psCKernelDefEqProofAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqProofName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelDefEqProofDefinition
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelDefEqProofName name
      levelParams := []
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelDefEqProofAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelDefEqProofEnv : PsCKernelEnvironment :=
  let propSort := PsCKernelExpr.sortE psCKernelLevelZero
  let typeSort := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let pType := psCKernelDefEqProofConst "P"
  let qType := psCKernelDefEqProofConst "Q"
  let aType := psCKernelDefEqProofConst "A"
  let aliasP := psCKernelDefEqProofConst "AliasP"
  let env0 := psCKernelDefEqProofAdd psCKernelEnvironmentEmpty
    (psCKernelDefEqProofAxiom "P" propSort)
  let env1 := psCKernelDefEqProofAdd env0
    (psCKernelDefEqProofAxiom "p" pType)
  let env2 := psCKernelDefEqProofAdd env1
    (psCKernelDefEqProofAxiom "q" pType)
  let env3 := psCKernelDefEqProofAdd env2
    (psCKernelDefEqProofAxiom "Q" propSort)
  let env4 := psCKernelDefEqProofAdd env3
    (psCKernelDefEqProofAxiom "r" qType)
  let env5 := psCKernelDefEqProofAdd env4
    (psCKernelDefEqProofDefinition "AliasP" propSort pType)
  let env6 := psCKernelDefEqProofAdd env5
    (psCKernelDefEqProofAxiom "aliasProof" aliasP)
  let env7 := psCKernelDefEqProofAdd env6
    (psCKernelDefEqProofAxiom "A" typeSort)
  let env8 := psCKernelDefEqProofAdd env7
    (psCKernelDefEqProofAxiom "a" aType)
  psCKernelDefEqProofAdd env8
    (psCKernelDefEqProofAxiom "b" aType)

def psCKernelDefEqProofTestDistinctProofs : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "p")
    (psCKernelDefEqProofConst "q")

def psCKernelDefEqProofTestSymmetric : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "q")
    (psCKernelDefEqProofConst "p")

def psCKernelDefEqProofTestDefEqPropTypes : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "p")
    (psCKernelDefEqProofConst "aliasProof")

def psCKernelDefEqProofTestDifferentProps : Bool :=
  !(psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "p")
    (psCKernelDefEqProofConst "r"))

def psCKernelDefEqProofTestDataNotIrrelevant : Bool :=
  !(psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "a")
    (psCKernelDefEqProofConst "b"))

def psCKernelDefEqProofTestPropositionsNotCollapsed : Bool :=
  !(psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "P")
    (psCKernelDefEqProofConst "Q"))

def psCKernelDefEqProofTestReflexiveData : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "a")
    (psCKernelDefEqProofConst "a")

def psCKernelDefEqProofTestBasicConversionStillWorks : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqProofEnv psCKernelLocalContextEmpty
    (psCKernelDefEqProofConst "AliasP")
    (psCKernelDefEqProofConst "P")

def psCKernelDefEqProofTests : List PsCKernelDefEqProofNamedTest := [
  { name := "distinct proofs of the same proposition are definitionally equal", passed := psCKernelDefEqProofTestDistinctProofs },
  { name := "proof irrelevance is symmetric", passed := psCKernelDefEqProofTestSymmetric },
  { name := "proof irrelevance accepts definitionally equal proposition types", passed := psCKernelDefEqProofTestDefEqPropTypes },
  { name := "proofs of different propositions remain unequal", passed := psCKernelDefEqProofTestDifferentProps },
  { name := "data inhabitants are not collapsed by proof irrelevance", passed := psCKernelDefEqProofTestDataNotIrrelevant },
  { name := "proposition expressions themselves are not proof-irrelevant", passed := psCKernelDefEqProofTestPropositionsNotCollapsed },
  { name := "full defeq preserves reflexive data equality", passed := psCKernelDefEqProofTestReflexiveData },
  { name := "full defeq preserves basic delta conversion", passed := psCKernelDefEqProofTestBasicConversionStillWorks }
]

def psCKernelRunDefEqProofTests
    (tests : List PsCKernelDefEqProofNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_DEFEQ_PROOF_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_DEFEQ_PROOF_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunDefEqProofTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunDefEqProofTests psCKernelDefEqProofTests
  if passed then
    IO.println "PSCKERNEL_DEFEQ_PROOF_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_DEFEQ_PROOF_TESTS: FAIL")
