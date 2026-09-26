import Ps.PSCKernel.Core.DefEq

def psCKernelStructEtaFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelStructEtaFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelStructEtaFixtureName text) []

def psCKernelStructEtaFixtureAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelStructEtaFixtureName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelStructEtaFixtureInductive
    (name : String)
    (declType : PsCKernelExpr)
    (numParams : Nat)
    (numIndices : Nat)
    (ctors : List PsCKernelName)
    (isRec : Bool) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := {
      name := psCKernelStructEtaFixtureName name
      levelParams := []
      declType := declType
    }
    numParams := numParams
    numIndices := numIndices
    all := psCKernelStructEtaFixtureName name :: ctors
    ctors := ctors
    numNested := 0
    isRec := isRec
    isUnsafe := false
    isReflexive := false
  }

def psCKernelStructEtaFixtureConstructor
    (name : String)
    (declType : PsCKernelExpr)
    (induct : PsCKernelName)
    (numParams : Nat)
    (numFields : Nat) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.ctorInfo {
    base := {
      name := psCKernelStructEtaFixtureName name
      levelParams := []
      declType := declType
    }
    induct := induct
    cidx := 0
    numParams := numParams
    numFields := numFields
    isUnsafe := false
  }

def psCKernelStructEtaFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelStructEtaFixtureEnv : PsCKernelEnvironment :=
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let aType := psCKernelStructEtaFixtureConst "A"
  let sName := psCKernelStructEtaFixtureName "S"
  let sCtorName := psCKernelStructEtaFixtureName "S.mk"
  let sCtorType :=
    PsCKernelExpr.forallE
      (psCKernelStructEtaFixtureName "fst") aType
      (PsCKernelExpr.forallE
        (psCKernelStructEtaFixtureName "snd") aType
        (PsCKernelExpr.constE sName []) PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let boxName := psCKernelStructEtaFixtureName "Box"
  let boxCtorName := psCKernelStructEtaFixtureName "Box.mk"
  let boxType :=
    PsCKernelExpr.forallE
      (psCKernelStructEtaFixtureName "A") sort1 sort1 PsCKernelBinderInfo.default
  let boxCtorType :=
    PsCKernelExpr.forallE
      (psCKernelStructEtaFixtureName "A") sort1
      (PsCKernelExpr.forallE
        (psCKernelStructEtaFixtureName "value") (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let rName := psCKernelStructEtaFixtureName "R"
  let rCtorName := psCKernelStructEtaFixtureName "R.mk"
  let rCtorType :=
    PsCKernelExpr.forallE
      (psCKernelStructEtaFixtureName "field") aType
      (PsCKernelExpr.constE rName []) PsCKernelBinderInfo.default
  let mName := psCKernelStructEtaFixtureName "M"
  let mCtor1Name := psCKernelStructEtaFixtureName "M.one"
  let mCtor2Name := psCKernelStructEtaFixtureName "M.two"
  let mCtorType :=
    PsCKernelExpr.forallE
      (psCKernelStructEtaFixtureName "field") aType
      (PsCKernelExpr.constE mName []) PsCKernelBinderInfo.default
  let env0 := psCKernelStructEtaFixtureAdd psCKernelEnvironmentEmpty
    (psCKernelStructEtaFixtureAxiom "A" sort1)
  let env1 := psCKernelStructEtaFixtureAdd env0
    (psCKernelStructEtaFixtureAxiom "a" aType)
  let env2 := psCKernelStructEtaFixtureAdd env1
    (psCKernelStructEtaFixtureAxiom "b" aType)
  let env3 := psCKernelStructEtaFixtureAdd env2
    (psCKernelStructEtaFixtureInductive "S" sort1 0 0 [sCtorName] false)
  let env4 := psCKernelStructEtaFixtureAdd env3
    (psCKernelStructEtaFixtureConstructor "S.mk" sCtorType sName 0 2)
  let env5 := psCKernelStructEtaFixtureAdd env4
    (psCKernelStructEtaFixtureAxiom "s" (PsCKernelExpr.constE sName []))
  let env6 := psCKernelStructEtaFixtureAdd env5
    (psCKernelStructEtaFixtureInductive "Box" boxType 1 0 [boxCtorName] false)
  let env7 := psCKernelStructEtaFixtureAdd env6
    (psCKernelStructEtaFixtureConstructor "Box.mk" boxCtorType boxName 1 1)
  let env8 := psCKernelStructEtaFixtureAdd env7
    (psCKernelStructEtaFixtureAxiom "boxa"
      (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) aType))
  let env9 := psCKernelStructEtaFixtureAdd env8
    (psCKernelStructEtaFixtureInductive "R" sort1 0 0 [rCtorName] true)
  let env10 := psCKernelStructEtaFixtureAdd env9
    (psCKernelStructEtaFixtureConstructor "R.mk" rCtorType rName 0 1)
  let env11 := psCKernelStructEtaFixtureAdd env10
    (psCKernelStructEtaFixtureAxiom "r" (PsCKernelExpr.constE rName []))
  let env12 := psCKernelStructEtaFixtureAdd env11
    (psCKernelStructEtaFixtureInductive "M" sort1 0 0 [mCtor1Name, mCtor2Name] false)
  let env13 := psCKernelStructEtaFixtureAdd env12
    (psCKernelStructEtaFixtureConstructor "M.one" mCtorType mName 0 1)
  let env14 := psCKernelStructEtaFixtureAdd env13
    (psCKernelStructEtaFixtureConstructor "M.two" mCtorType mName 0 1)
  psCKernelStructEtaFixtureAdd env14
    (psCKernelStructEtaFixtureAxiom "m" (PsCKernelExpr.constE mName []))

def psCKernelStructEtaFixtureSExpansion : PsCKernelExpr :=
  let s := psCKernelStructEtaFixtureConst "s"
  psCKernelExprMkAppN
    (psCKernelStructEtaFixtureConst "S.mk")
    [
      PsCKernelExpr.proj (psCKernelStructEtaFixtureName "S") 0 s,
      PsCKernelExpr.proj (psCKernelStructEtaFixtureName "S") 1 s
    ]

def psCKernelStructEtaFixtureBoxExpansion : PsCKernelExpr :=
  let boxa := psCKernelStructEtaFixtureConst "boxa"
  psCKernelExprMkAppN
    (psCKernelStructEtaFixtureConst "Box.mk")
    [
      psCKernelStructEtaFixtureConst "A",
      PsCKernelExpr.proj (psCKernelStructEtaFixtureName "Box") 0 boxa
    ]

def psCKernelStructEtaFixtureEmit
    (key : String)
    (value : Bool) : IO Unit :=
  IO.println (key ++ "\t" ++ (if value then "1" else "0"))

def main : IO Unit := do
  let env := psCKernelStructEtaFixtureEnv
  let ctx := psCKernelLocalContextEmpty
  let s := psCKernelStructEtaFixtureConst "s"
  let r := psCKernelStructEtaFixtureConst "r"
  let m := psCKernelStructEtaFixtureConst "m"
  psCKernelStructEtaFixtureEmit "forward"
    (psCKernelIsDefEq env ctx s psCKernelStructEtaFixtureSExpansion)
  psCKernelStructEtaFixtureEmit "symmetric"
    (psCKernelIsDefEq env ctx psCKernelStructEtaFixtureSExpansion s)
  psCKernelStructEtaFixtureEmit "parameterized"
    (psCKernelIsDefEq env ctx
      (psCKernelStructEtaFixtureConst "boxa") psCKernelStructEtaFixtureBoxExpansion)
  psCKernelStructEtaFixtureEmit "wrong-field"
    (psCKernelIsDefEq env ctx s
      (psCKernelExprMkAppN
        (psCKernelStructEtaFixtureConst "S.mk")
        [PsCKernelExpr.proj (psCKernelStructEtaFixtureName "S") 0 s,
         psCKernelStructEtaFixtureConst "a"]))
  psCKernelStructEtaFixtureEmit "incomplete"
    (psCKernelIsDefEq env ctx s
      (PsCKernelExpr.app
        (psCKernelStructEtaFixtureConst "S.mk")
        (PsCKernelExpr.proj (psCKernelStructEtaFixtureName "S") 0 s)))
  psCKernelStructEtaFixtureEmit "recursive"
    (psCKernelIsDefEq env ctx r
      (PsCKernelExpr.app
        (psCKernelStructEtaFixtureConst "R.mk")
        (PsCKernelExpr.proj (psCKernelStructEtaFixtureName "R") 0 r)))
  psCKernelStructEtaFixtureEmit "multi-ctor"
    (psCKernelIsDefEq env ctx m
      (PsCKernelExpr.app
        (psCKernelStructEtaFixtureConst "M.one")
        (PsCKernelExpr.proj (psCKernelStructEtaFixtureName "M") 0 m)))
  psCKernelStructEtaFixtureEmit "ordinary-unequal"
    (psCKernelIsDefEq env ctx
      (psCKernelStructEtaFixtureConst "a")
      (psCKernelStructEtaFixtureConst "b"))
