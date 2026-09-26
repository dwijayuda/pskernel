import Ps.PSCKernel.Core.ReductionBasic

structure PsCKernelRecursorBasicNamedTest where
  name : String
  passed : Bool

def psCKernelRecursorBasicName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelRecursorBasicConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelRecursorBasicName text) []

def psCKernelRecursorBasicNat (value : Nat) : PsCKernelExpr :=
  PsCKernelExpr.lit (PsCKernelLiteral.natVal value)

def psCKernelRecursorBasicAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelRecursorBasicName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelRecursorBasicInductive
    (name : String)
    (declType : PsCKernelExpr)
    (numParams : Nat)
    (ctors : List PsCKernelName) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := {
      name := psCKernelRecursorBasicName name
      levelParams := []
      declType := declType
    }
    numParams := numParams
    numIndices := 0
    all := psCKernelRecursorBasicName name :: ctors
    ctors := ctors
    numNested := 0
    isRec := false
    isUnsafe := false
    isReflexive := false
  }

def psCKernelRecursorBasicConstructor
    (name : String)
    (declType : PsCKernelExpr)
    (induct : PsCKernelName)
    (cidx : Nat)
    (numParams : Nat)
    (numFields : Nat) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.ctorInfo {
    base := {
      name := psCKernelRecursorBasicName name
      levelParams := []
      declType := declType
    }
    induct := induct
    cidx := cidx
    numParams := numParams
    numFields := numFields
    isUnsafe := false
  }

def psCKernelRecursorBasicRecursor
    (name : PsCKernelName)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr)
    (numParams : Nat)
    (numMotives : Nat)
    (numMinors : Nat)
    (rules : List PsCKernelRecursorRule) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.recInfo {
    base := {
      name := name
      levelParams := levelParams
      declType := declType
    }
    all := []
    numParams := numParams
    numIndices := 0
    numMotives := numMotives
    numMinors := numMinors
    rules := rules
    k := false
    isUnsafe := false
  }

def psCKernelRecursorBasicAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelRecursorBasicEnv : PsCKernelEnvironment :=
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let aType := psCKernelRecursorBasicConst "A"
  let iName := psCKernelRecursorBasicName "I"
  let c0Name := psCKernelRecursorBasicName "I.c0"
  let c1Name := psCKernelRecursorBasicName "I.c1"
  let iRecName := psCKernelRecursorBasicName "I.rec"
  let jName := psCKernelRecursorBasicName "J"
  let jMkName := psCKernelRecursorBasicName "J.mk"
  let jRecName := psCKernelRecursorBasicName "J.rec"
  let boxName := psCKernelRecursorBasicName "Box"
  let boxMkName := psCKernelRecursorBasicName "Box.mk"
  let boxRecName := psCKernelRecursorBasicName "Box.rec"
  let tailRecName := psCKernelRecursorBasicName "I.tailRec"
  let uName := psCKernelRecursorBasicName "u"
  let uRecName := psCKernelRecursorBasicName "I.uRec"
  let env0 := psCKernelRecursorBasicAdd psCKernelEnvironmentEmpty
    (psCKernelRecursorBasicAxiom "A" sort1)
  let env1 := psCKernelRecursorBasicAdd env0
    (psCKernelRecursorBasicAxiom "a" aType)
  let env2 := psCKernelRecursorBasicAdd env1
    (psCKernelRecursorBasicInductive "I" sort1 0 [c0Name, c1Name])
  let env3 := psCKernelRecursorBasicAdd env2
    (psCKernelRecursorBasicConstructor "I.c0" (PsCKernelExpr.constE iName []) iName 0 0 0)
  let env4 := psCKernelRecursorBasicAdd env3
    (psCKernelRecursorBasicConstructor "I.c1" (PsCKernelExpr.constE iName []) iName 1 0 0)
  let env5 := psCKernelRecursorBasicAdd env4
    (psCKernelRecursorBasicRecursor
      iRecName []
      (PsCKernelExpr.forallE
        (psCKernelRecursorBasicName "major") (PsCKernelExpr.constE iName [])
        (psCKernelRecursorBasicConst "A") PsCKernelBinderInfo.default)
      0 0 0
      [{ ctor := c0Name, nfields := 0, rhs := psCKernelRecursorBasicNat 7 }])
  let env6 := psCKernelRecursorBasicAdd env5
    (psCKernelRecursorBasicInductive "J" sort1 0 [jMkName])
  let env7 := psCKernelRecursorBasicAdd env6
    (psCKernelRecursorBasicConstructor
      "J.mk"
      (PsCKernelExpr.forallE
        (psCKernelRecursorBasicName "value") aType
        (PsCKernelExpr.constE jName []) PsCKernelBinderInfo.default)
      jName 0 0 1)
  let env8 := psCKernelRecursorBasicAdd env7
    (psCKernelRecursorBasicRecursor
      jRecName []
      (PsCKernelExpr.forallE
        (psCKernelRecursorBasicName "major") (PsCKernelExpr.constE jName [])
        aType PsCKernelBinderInfo.default)
      0 0 0
      [{
        ctor := jMkName
        nfields := 1
        rhs := PsCKernelExpr.lam
          (psCKernelRecursorBasicName "field") aType
          (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default
      }])
  let env9 := psCKernelRecursorBasicAdd env8
    (psCKernelRecursorBasicInductive "Box" sort1 1 [boxMkName])
  let env10 := psCKernelRecursorBasicAdd env9
    (psCKernelRecursorBasicConstructor
      "Box.mk"
      (PsCKernelExpr.forallE
        (psCKernelRecursorBasicName "T") sort1
        (PsCKernelExpr.forallE
          (psCKernelRecursorBasicName "value") (PsCKernelExpr.bvar 0)
          (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) (PsCKernelExpr.bvar 1))
          PsCKernelBinderInfo.default)
        PsCKernelBinderInfo.default)
      boxName 0 1 1)
  let env11 := psCKernelRecursorBasicAdd env10
    (psCKernelRecursorBasicRecursor
      boxRecName [] sort1 1 0 0
      [{
        ctor := boxMkName
        nfields := 1
        rhs := PsCKernelExpr.lam
          (psCKernelRecursorBasicName "T") sort1
          (PsCKernelExpr.lam
            (psCKernelRecursorBasicName "value") (PsCKernelExpr.bvar 0)
            (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default)
          PsCKernelBinderInfo.default
      }])
  let env12 := psCKernelRecursorBasicAdd env11
    (psCKernelRecursorBasicRecursor
      tailRecName [] sort1 0 0 0
      [{
        ctor := c0Name
        nfields := 0
        rhs := PsCKernelExpr.lam
          (psCKernelRecursorBasicName "tail") aType
          (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default
      }])
  psCKernelRecursorBasicAdd env12
    (psCKernelRecursorBasicRecursor
      uRecName [uName] sort1 0 0 0
      [{
        ctor := c0Name
        nfields := 0
        rhs := PsCKernelExpr.sortE (PsCKernelLevel.param uName)
      }])

def psCKernelRecursorBasicTestRuleSelection : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelRecursorBasicConst "I.rec")
    (psCKernelRecursorBasicConst "I.c0")
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorBasicNat 7)

def psCKernelRecursorBasicTestFieldForwarding : Bool :=
  let major := PsCKernelExpr.app
    (psCKernelRecursorBasicConst "J.mk")
    (psCKernelRecursorBasicConst "a")
  let expr := PsCKernelExpr.app (psCKernelRecursorBasicConst "J.rec") major
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorBasicConst "a")

def psCKernelRecursorBasicTestParameterDrop : Bool :=
  let major := psCKernelExprMkAppN
    (psCKernelRecursorBasicConst "Box.mk")
    [psCKernelRecursorBasicConst "A", psCKernelRecursorBasicConst "a"]
  let expr := psCKernelExprMkAppN
    (psCKernelRecursorBasicConst "Box.rec")
    [psCKernelRecursorBasicConst "A", major]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorBasicConst "a")

def psCKernelRecursorBasicTestTrailingArgs : Bool :=
  let expr := psCKernelExprMkAppN
    (psCKernelRecursorBasicConst "I.tailRec")
    [psCKernelRecursorBasicConst "I.c0", psCKernelRecursorBasicConst "a"]
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorBasicConst "a")

def psCKernelRecursorBasicTestUniverseInstantiation : Bool :=
  let expr := PsCKernelExpr.app
    (PsCKernelExpr.constE
      (psCKernelRecursorBasicName "I.uRec") [psCKernelLevelZero])
    (psCKernelRecursorBasicConst "I.c0")
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    (PsCKernelExpr.sortE psCKernelLevelZero)

def psCKernelRecursorBasicTestReducibleMajor : Bool :=
  let major := PsCKernelExpr.letE
    (psCKernelRecursorBasicName "x")
    (psCKernelRecursorBasicConst "I")
    (psCKernelRecursorBasicConst "I.c0")
    (PsCKernelExpr.bvar 0)
    false
  let expr := PsCKernelExpr.app (psCKernelRecursorBasicConst "I.rec") major
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    (psCKernelRecursorBasicNat 7)

def psCKernelRecursorBasicTestUnmatchedRule : Bool :=
  let expr := PsCKernelExpr.app
    (psCKernelRecursorBasicConst "I.rec")
    (psCKernelRecursorBasicConst "I.c1")
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    expr

def psCKernelRecursorBasicTestTooFewArgs : Bool :=
  let expr := psCKernelRecursorBasicConst "I.rec"
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    expr

def psCKernelRecursorBasicTestWrongUniverseArity : Bool :=
  let expr := PsCKernelExpr.app
    (PsCKernelExpr.constE
      (psCKernelRecursorBasicName "I.rec") [psCKernelLevelZero])
    (psCKernelRecursorBasicConst "I.c0")
  psCKernelExprEqStructural
    (psCKernelExprWhnfBasic psCKernelRecursorBasicEnv psCKernelLocalContextEmpty expr)
    expr

def psCKernelRecursorBasicTests : List PsCKernelRecursorBasicNamedTest := [
  { name := "matching constructor selects recursor rule", passed := psCKernelRecursorBasicTestRuleSelection },
  { name := "constructor fields are forwarded to rule rhs", passed := psCKernelRecursorBasicTestFieldForwarding },
  { name := "constructor parameter prefix is dropped", passed := psCKernelRecursorBasicTestParameterDrop },
  { name := "arguments after major are preserved", passed := psCKernelRecursorBasicTestTrailingArgs },
  { name := "rule rhs universe parameters instantiate", passed := psCKernelRecursorBasicTestUniverseInstantiation },
  { name := "major expression is weak-head reduced before rule selection", passed := psCKernelRecursorBasicTestReducibleMajor },
  { name := "unmatched constructor rule stays stuck", passed := psCKernelRecursorBasicTestUnmatchedRule },
  { name := "recursor without major argument stays stuck", passed := psCKernelRecursorBasicTestTooFewArgs },
  { name := "wrong recursor universe arity stays stuck", passed := psCKernelRecursorBasicTestWrongUniverseArity }
]

def psCKernelRunRecursorBasicTests
    (tests : List PsCKernelRecursorBasicNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_RECURSOR_BASIC_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_RECURSOR_BASIC_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunRecursorBasicTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunRecursorBasicTests psCKernelRecursorBasicTests
  if passed then
    IO.println "PSCKERNEL_RECURSOR_BASIC_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_RECURSOR_BASIC_TESTS: FAIL")
