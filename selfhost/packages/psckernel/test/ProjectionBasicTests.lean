import Ps.PSCKernel.Core.CheckedInferenceBasic

structure PsCKernelProjectionBasicNamedTest where
  name : String
  passed : Bool

def psCKernelProjectionBasicName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelProjectionBasicConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelProjectionBasicName text) []

def psCKernelProjectionBasicAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelProjectionBasicName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelProjectionBasicInductive
    (name : String)
    (declType : PsCKernelExpr)
    (numParams : Nat)
    (ctors : List PsCKernelName) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := {
      name := psCKernelProjectionBasicName name
      levelParams := []
      declType := declType
    }
    numParams := numParams
    numIndices := 0
    all := psCKernelProjectionBasicName name :: ctors
    ctors := ctors
    numNested := 0
    isRec := false
    isUnsafe := false
    isReflexive := false
  }

def psCKernelProjectionBasicConstructor
    (name : String)
    (declType : PsCKernelExpr)
    (induct : PsCKernelName)
    (numParams : Nat)
    (numFields : Nat) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.ctorInfo {
    base := {
      name := psCKernelProjectionBasicName name
      levelParams := []
      declType := declType
    }
    induct := induct
    cidx := 0
    numParams := numParams
    numFields := numFields
    isUnsafe := false
  }

def psCKernelProjectionBasicAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelProjectionBasicEnv : PsCKernelEnvironment :=
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let aType := psCKernelProjectionBasicConst "A"
  let bType := psCKernelProjectionBasicConst "B"
  let sType := psCKernelProjectionBasicConst "S"
  let sName := psCKernelProjectionBasicName "S"
  let sCtorName := psCKernelProjectionBasicName "S.mk"
  let sCtorType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionBasicName "fst") aType
      (PsCKernelExpr.forallE
        (psCKernelProjectionBasicName "snd") bType sType PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let boxName := psCKernelProjectionBasicName "Box"
  let boxCtorName := psCKernelProjectionBasicName "Box.mk"
  let boxType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionBasicName "A") sort1 sort1 PsCKernelBinderInfo.default
  let boxCtorType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionBasicName "A") sort1
      (PsCKernelExpr.forallE
        (psCKernelProjectionBasicName "value") (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let proofBoxName := psCKernelProjectionBasicName "ProofBox"
  let proofBoxCtorName := psCKernelProjectionBasicName "ProofBox.mk"
  let proofBoxType := PsCKernelExpr.sortE psCKernelLevelZero
  let proofBoxCtorType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionBasicName "data") aType
      (PsCKernelExpr.constE proofBoxName [])
      PsCKernelBinderInfo.default
  let env0 := psCKernelProjectionBasicAdd psCKernelEnvironmentEmpty
    (psCKernelProjectionBasicAxiom "A" sort1)
  let env1 := psCKernelProjectionBasicAdd env0
    (psCKernelProjectionBasicAxiom "a" aType)
  let env2 := psCKernelProjectionBasicAdd env1
    (psCKernelProjectionBasicAxiom "B" sort1)
  let env3 := psCKernelProjectionBasicAdd env2
    (psCKernelProjectionBasicAxiom "b" bType)
  let env4 := psCKernelProjectionBasicAdd env3
    (psCKernelProjectionBasicInductive "S" sort1 0 [sCtorName])
  let env5 := psCKernelProjectionBasicAdd env4
    (psCKernelProjectionBasicConstructor "S.mk" sCtorType sName 0 2)
  let env6 := psCKernelProjectionBasicAdd env5
    (psCKernelProjectionBasicAxiom "s" sType)
  let env7 := psCKernelProjectionBasicAdd env6
    (psCKernelProjectionBasicInductive "Box" boxType 1 [boxCtorName])
  let env8 := psCKernelProjectionBasicAdd env7
    (psCKernelProjectionBasicConstructor "Box.mk" boxCtorType boxName 1 1)
  let env9 := psCKernelProjectionBasicAdd env8
    (psCKernelProjectionBasicAxiom "boxa"
      (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) aType))
  let env10 := psCKernelProjectionBasicAdd env9
    (psCKernelProjectionBasicInductive "ProofBox" proofBoxType 0 [proofBoxCtorName])
  let env11 := psCKernelProjectionBasicAdd env10
    (psCKernelProjectionBasicConstructor "ProofBox.mk" proofBoxCtorType proofBoxName 0 1)
  psCKernelProjectionBasicAdd env11
    (psCKernelProjectionBasicAxiom "proofBox" (PsCKernelExpr.constE proofBoxName []))

def psCKernelProjectionBasicEqOption
    (actual : Option PsCKernelExpr)
    (expected : Option PsCKernelExpr) : Bool :=
  match actual, expected with
  | none, none => true
  | some left, some right => psCKernelExprEqStructural left right
  | _, _ => false

def psCKernelProjectionBasicCtorValue : PsCKernelExpr :=
  psCKernelExprMkAppN
    (psCKernelProjectionBasicConst "S.mk")
    [psCKernelProjectionBasicConst "a", psCKernelProjectionBasicConst "b"]

def psCKernelProjectionBasicTestReduceFirst : Bool :=
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "S") 0 psCKernelProjectionBasicCtorValue))
    (psCKernelProjectionBasicConst "a")

def psCKernelProjectionBasicTestReduceSecond : Bool :=
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "S") 1 psCKernelProjectionBasicCtorValue))
    (psCKernelProjectionBasicConst "b")

def psCKernelProjectionBasicTestInferFirst : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelInfer?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "S") 0 (psCKernelProjectionBasicConst "s")))
    (some (psCKernelProjectionBasicConst "A"))

def psCKernelProjectionBasicTestInferSecond : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelInfer?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "S") 1 (psCKernelProjectionBasicConst "s")))
    (some (psCKernelProjectionBasicConst "B"))

def psCKernelProjectionBasicTestCheckedFirst : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelCheckBasic?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "S") 0 (psCKernelProjectionBasicConst "s")))
    (some (psCKernelProjectionBasicConst "A"))

def psCKernelProjectionBasicTestParameterizedInfer : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelInfer?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "Box") 0 (psCKernelProjectionBasicConst "boxa")))
    (some (psCKernelProjectionBasicConst "A"))

def psCKernelProjectionBasicTestParameterizedReduce : Bool :=
  let boxCtor := psCKernelExprMkAppN
    (psCKernelProjectionBasicConst "Box.mk")
    [psCKernelProjectionBasicConst "A", psCKernelProjectionBasicConst "a"]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj (psCKernelProjectionBasicName "Box") 0 boxCtor))
    (psCKernelProjectionBasicConst "a")

def psCKernelProjectionBasicTestBadIndex : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelInfer?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "S") 2 (psCKernelProjectionBasicConst "s")))
    none

def psCKernelProjectionBasicTestWrongTypeName : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelInfer?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "Box") 0 (psCKernelProjectionBasicConst "s")))
    none

def psCKernelProjectionBasicTestProofToDataRejected : Bool :=
  psCKernelProjectionBasicEqOption
    (psCKernelInfer?
      psCKernelProjectionBasicEnv psCKernelLocalContextEmpty
      (PsCKernelExpr.proj
        (psCKernelProjectionBasicName "ProofBox") 0
        (psCKernelProjectionBasicConst "proofBox")))
    none

def psCKernelProjectionBasicTests : List PsCKernelProjectionBasicNamedTest := [
  { name := "projection reduces first constructor field", passed := psCKernelProjectionBasicTestReduceFirst },
  { name := "projection reduces second constructor field", passed := psCKernelProjectionBasicTestReduceSecond },
  { name := "projection inference returns first field type", passed := psCKernelProjectionBasicTestInferFirst },
  { name := "projection inference returns second field type", passed := psCKernelProjectionBasicTestInferSecond },
  { name := "checked inference accepts projection", passed := psCKernelProjectionBasicTestCheckedFirst },
  { name := "projection inference skips structure parameters", passed := psCKernelProjectionBasicTestParameterizedInfer },
  { name := "projection reduction skips constructor parameters", passed := psCKernelProjectionBasicTestParameterizedReduce },
  { name := "projection rejects out-of-bounds field", passed := psCKernelProjectionBasicTestBadIndex },
  { name := "projection rejects mismatched structure name", passed := psCKernelProjectionBasicTestWrongTypeName },
  { name := "projection rejects proof elimination into data", passed := psCKernelProjectionBasicTestProofToDataRejected }
]

def psCKernelRunProjectionBasicTests
    (tests : List PsCKernelProjectionBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_PROJECTION_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_PROJECTION_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunProjectionBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunProjectionBasicTests psCKernelProjectionBasicTests
  if passed then
    IO.println "PSCKERNEL_PROJECTION_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_PROJECTION_BASIC_TESTS: FAIL")
