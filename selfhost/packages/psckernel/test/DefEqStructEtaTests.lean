import Ps.PSCKernel.Core.DefEq

structure PsCKernelDefEqStructEtaNamedTest where
  name : String
  passed : Bool

def psCKernelDefEqStructEtaName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDefEqStructEtaConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDefEqStructEtaName text) []

def psCKernelDefEqStructEtaAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqStructEtaName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelDefEqStructEtaInductive
    (name : String)
    (declType : PsCKernelExpr)
    (numParams : Nat)
    (numIndices : Nat)
    (ctors : List PsCKernelName)
    (isRec : Bool) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := {
      name := psCKernelDefEqStructEtaName name
      levelParams := []
      declType := declType
    }
    numParams := numParams
    numIndices := numIndices
    all := psCKernelDefEqStructEtaName name :: ctors
    ctors := ctors
    numNested := 0
    isRec := isRec
    isUnsafe := false
    isReflexive := false
  }

def psCKernelDefEqStructEtaConstructor
    (name : String)
    (declType : PsCKernelExpr)
    (induct : PsCKernelName)
    (numParams : Nat)
    (numFields : Nat) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.ctorInfo {
    base := {
      name := psCKernelDefEqStructEtaName name
      levelParams := []
      declType := declType
    }
    induct := induct
    cidx := 0
    numParams := numParams
    numFields := numFields
    isUnsafe := false
  }

def psCKernelDefEqStructEtaAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelDefEqStructEtaEnv : PsCKernelEnvironment :=
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let aType := psCKernelDefEqStructEtaConst "A"
  let sName := psCKernelDefEqStructEtaName "S"
  let sType := psCKernelDefEqStructEtaConst "S"
  let sCtorName := psCKernelDefEqStructEtaName "S.mk"
  let sCtorType :=
    PsCKernelExpr.forallE
      (psCKernelDefEqStructEtaName "fst") aType
      (PsCKernelExpr.forallE
        (psCKernelDefEqStructEtaName "snd") aType sType PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let boxName := psCKernelDefEqStructEtaName "Box"
  let boxCtorName := psCKernelDefEqStructEtaName "Box.mk"
  let boxType :=
    PsCKernelExpr.forallE
      (psCKernelDefEqStructEtaName "A") sort1 sort1 PsCKernelBinderInfo.default
  let boxCtorType :=
    PsCKernelExpr.forallE
      (psCKernelDefEqStructEtaName "A") sort1
      (PsCKernelExpr.forallE
        (psCKernelDefEqStructEtaName "value") (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let rName := psCKernelDefEqStructEtaName "R"
  let rCtorName := psCKernelDefEqStructEtaName "R.mk"
  let rCtorType :=
    PsCKernelExpr.forallE
      (psCKernelDefEqStructEtaName "field") aType
      (PsCKernelExpr.constE rName [])
      PsCKernelBinderInfo.default
  let mName := psCKernelDefEqStructEtaName "M"
  let mCtor1Name := psCKernelDefEqStructEtaName "M.one"
  let mCtor2Name := psCKernelDefEqStructEtaName "M.two"
  let mCtorType :=
    PsCKernelExpr.forallE
      (psCKernelDefEqStructEtaName "field") aType
      (PsCKernelExpr.constE mName [])
      PsCKernelBinderInfo.default
  let env0 := psCKernelDefEqStructEtaAdd psCKernelEnvironmentEmpty
    (psCKernelDefEqStructEtaAxiom "A" sort1)
  let env1 := psCKernelDefEqStructEtaAdd env0
    (psCKernelDefEqStructEtaAxiom "a" aType)
  let env2 := psCKernelDefEqStructEtaAdd env1
    (psCKernelDefEqStructEtaAxiom "b" aType)
  let env3 := psCKernelDefEqStructEtaAdd env2
    (psCKernelDefEqStructEtaInductive "S" sort1 0 0 [sCtorName] false)
  let env4 := psCKernelDefEqStructEtaAdd env3
    (psCKernelDefEqStructEtaConstructor "S.mk" sCtorType sName 0 2)
  let env5 := psCKernelDefEqStructEtaAdd env4
    (psCKernelDefEqStructEtaAxiom "s" sType)
  let env6 := psCKernelDefEqStructEtaAdd env5
    (psCKernelDefEqStructEtaInductive "Box" boxType 1 0 [boxCtorName] false)
  let env7 := psCKernelDefEqStructEtaAdd env6
    (psCKernelDefEqStructEtaConstructor "Box.mk" boxCtorType boxName 1 1)
  let env8 := psCKernelDefEqStructEtaAdd env7
    (psCKernelDefEqStructEtaAxiom "boxa"
      (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) aType))
  let env9 := psCKernelDefEqStructEtaAdd env8
    (psCKernelDefEqStructEtaInductive "R" sort1 0 0 [rCtorName] true)
  let env10 := psCKernelDefEqStructEtaAdd env9
    (psCKernelDefEqStructEtaConstructor "R.mk" rCtorType rName 0 1)
  let env11 := psCKernelDefEqStructEtaAdd env10
    (psCKernelDefEqStructEtaAxiom "r" (PsCKernelExpr.constE rName []))
  let env12 := psCKernelDefEqStructEtaAdd env11
    (psCKernelDefEqStructEtaInductive "M" sort1 0 0 [mCtor1Name, mCtor2Name] false)
  let env13 := psCKernelDefEqStructEtaAdd env12
    (psCKernelDefEqStructEtaConstructor "M.one" mCtorType mName 0 1)
  let env14 := psCKernelDefEqStructEtaAdd env13
    (psCKernelDefEqStructEtaConstructor "M.two" mCtorType mName 0 1)
  psCKernelDefEqStructEtaAdd env14
    (psCKernelDefEqStructEtaAxiom "m" (PsCKernelExpr.constE mName []))

def psCKernelDefEqStructEtaSExpansion : PsCKernelExpr :=
  let s := psCKernelDefEqStructEtaConst "s"
  psCKernelExprMkAppN
    (psCKernelDefEqStructEtaConst "S.mk")
    [
      PsCKernelExpr.proj (psCKernelDefEqStructEtaName "S") 0 s,
      PsCKernelExpr.proj (psCKernelDefEqStructEtaName "S") 1 s
    ]

def psCKernelDefEqStructEtaBoxExpansion : PsCKernelExpr :=
  let boxa := psCKernelDefEqStructEtaConst "boxa"
  psCKernelExprMkAppN
    (psCKernelDefEqStructEtaConst "Box.mk")
    [
      psCKernelDefEqStructEtaConst "A",
      PsCKernelExpr.proj (psCKernelDefEqStructEtaName "Box") 0 boxa
    ]

def psCKernelDefEqStructEtaTestForward : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqStructEtaConst "s")
    psCKernelDefEqStructEtaSExpansion

def psCKernelDefEqStructEtaTestSymmetric : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty
    psCKernelDefEqStructEtaSExpansion
    (psCKernelDefEqStructEtaConst "s")

def psCKernelDefEqStructEtaTestParameterized : Bool :=
  psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqStructEtaConst "boxa")
    psCKernelDefEqStructEtaBoxExpansion

def psCKernelDefEqStructEtaTestWrongField : Bool :=
  let s := psCKernelDefEqStructEtaConst "s"
  let wrong :=
    psCKernelExprMkAppN
      (psCKernelDefEqStructEtaConst "S.mk")
      [
        PsCKernelExpr.proj (psCKernelDefEqStructEtaName "S") 0 s,
        psCKernelDefEqStructEtaConst "a"
      ]
  !psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty s wrong

def psCKernelDefEqStructEtaTestIncompleteCtor : Bool :=
  let s := psCKernelDefEqStructEtaConst "s"
  let incomplete :=
    PsCKernelExpr.app
      (psCKernelDefEqStructEtaConst "S.mk")
      (PsCKernelExpr.proj (psCKernelDefEqStructEtaName "S") 0 s)
  !psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty s incomplete

def psCKernelDefEqStructEtaTestRecursiveBlocked : Bool :=
  let r := psCKernelDefEqStructEtaConst "r"
  let expanded :=
    PsCKernelExpr.app
      (psCKernelDefEqStructEtaConst "R.mk")
      (PsCKernelExpr.proj (psCKernelDefEqStructEtaName "R") 0 r)
  !psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty r expanded

def psCKernelDefEqStructEtaTestMultipleCtorBlocked : Bool :=
  let m := psCKernelDefEqStructEtaConst "m"
  let expanded :=
    PsCKernelExpr.app
      (psCKernelDefEqStructEtaConst "M.one")
      (PsCKernelExpr.proj (psCKernelDefEqStructEtaName "M") 0 m)
  !psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty m expanded

def psCKernelDefEqStructEtaTestOrdinaryUnequal : Bool :=
  !psCKernelIsDefEq
    psCKernelDefEqStructEtaEnv psCKernelLocalContextEmpty
    (psCKernelDefEqStructEtaConst "a")
    (psCKernelDefEqStructEtaConst "b")

def psCKernelDefEqStructEtaTests : List PsCKernelDefEqStructEtaNamedTest := [
  { name := "structure eta equates term with constructor of projections", passed := psCKernelDefEqStructEtaTestForward },
  { name := "structure eta is symmetric", passed := psCKernelDefEqStructEtaTestSymmetric },
  { name := "structure eta preserves parameters", passed := psCKernelDefEqStructEtaTestParameterized },
  { name := "structure eta rejects mismatched field", passed := psCKernelDefEqStructEtaTestWrongField },
  { name := "structure eta requires fully applied constructor", passed := psCKernelDefEqStructEtaTestIncompleteCtor },
  { name := "structure eta rejects recursive inductive", passed := psCKernelDefEqStructEtaTestRecursiveBlocked },
  { name := "structure eta rejects multiple constructors", passed := psCKernelDefEqStructEtaTestMultipleCtorBlocked },
  { name := "ordinary unequal terms remain unequal", passed := psCKernelDefEqStructEtaTestOrdinaryUnequal }
]

def psCKernelRunDefEqStructEtaTests
    (tests : List PsCKernelDefEqStructEtaNamedTest) : IO Bool :=
  match tests with
  | [] => pure true
  | test :: rest => do
      if test.passed then
        IO.println ("PSCKERNEL_DEFEQ_STRUCT_ETA_PASS: " ++ test.name)
      else
        IO.println ("PSCKERNEL_DEFEQ_STRUCT_ETA_FAIL: " ++ test.name)
      let restPassed ← psCKernelRunDefEqStructEtaTests rest
      pure (test.passed && restPassed)

def main : IO Unit := do
  let passed ← psCKernelRunDefEqStructEtaTests psCKernelDefEqStructEtaTests
  if passed then
    IO.println "PSCKERNEL_DEFEQ_STRUCT_ETA_TESTS: PASS"
  else
    throw (IO.userError "PSCKERNEL_DEFEQ_STRUCT_ETA_TESTS: FAIL")
