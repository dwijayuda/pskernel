import Ps.PSCKernel.Core.CheckedInferenceBasic

def psCKernelProjectionFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelProjectionFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelProjectionFixtureName text) []

def psCKernelProjectionFixtureAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelProjectionFixtureName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelProjectionFixtureInductive
    (name : String)
    (declType : PsCKernelExpr)
    (numParams : Nat)
    (ctors : List PsCKernelName) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := {
      name := psCKernelProjectionFixtureName name
      levelParams := []
      declType := declType
    }
    numParams := numParams
    numIndices := 0
    all := psCKernelProjectionFixtureName name :: ctors
    ctors := ctors
    numNested := 0
    isRec := false
    isUnsafe := false
    isReflexive := false
  }

def psCKernelProjectionFixtureConstructor
    (name : String)
    (declType : PsCKernelExpr)
    (induct : PsCKernelName)
    (numParams : Nat)
    (numFields : Nat) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.ctorInfo {
    base := {
      name := psCKernelProjectionFixtureName name
      levelParams := []
      declType := declType
    }
    induct := induct
    cidx := 0
    numParams := numParams
    numFields := numFields
    isUnsafe := false
  }

def psCKernelProjectionFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelProjectionFixtureEnv : PsCKernelEnvironment :=
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let aType := psCKernelProjectionFixtureConst "A"
  let bType := psCKernelProjectionFixtureConst "B"
  let sName := psCKernelProjectionFixtureName "S"
  let sCtorName := psCKernelProjectionFixtureName "S.mk"
  let sType := PsCKernelExpr.constE sName []
  let sCtorType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionFixtureName "fst") aType
      (PsCKernelExpr.forallE
        (psCKernelProjectionFixtureName "snd") bType sType PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let boxName := psCKernelProjectionFixtureName "Box"
  let boxCtorName := psCKernelProjectionFixtureName "Box.mk"
  let boxType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionFixtureName "A") sort1 sort1 PsCKernelBinderInfo.default
  let boxCtorType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionFixtureName "A") sort1
      (PsCKernelExpr.forallE
        (psCKernelProjectionFixtureName "value") (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      PsCKernelBinderInfo.default
  let proofBoxName := psCKernelProjectionFixtureName "ProofBox"
  let proofBoxCtorName := psCKernelProjectionFixtureName "ProofBox.mk"
  let proofBoxType := PsCKernelExpr.sortE psCKernelLevelZero
  let proofBoxCtorType :=
    PsCKernelExpr.forallE
      (psCKernelProjectionFixtureName "data") aType
      (PsCKernelExpr.constE proofBoxName [])
      PsCKernelBinderInfo.default
  let env0 := psCKernelProjectionFixtureAdd psCKernelEnvironmentEmpty
    (psCKernelProjectionFixtureAxiom "A" sort1)
  let env1 := psCKernelProjectionFixtureAdd env0
    (psCKernelProjectionFixtureAxiom "a" aType)
  let env2 := psCKernelProjectionFixtureAdd env1
    (psCKernelProjectionFixtureAxiom "B" sort1)
  let env3 := psCKernelProjectionFixtureAdd env2
    (psCKernelProjectionFixtureAxiom "b" bType)
  let env4 := psCKernelProjectionFixtureAdd env3
    (psCKernelProjectionFixtureInductive "S" sort1 0 [sCtorName])
  let env5 := psCKernelProjectionFixtureAdd env4
    (psCKernelProjectionFixtureConstructor "S.mk" sCtorType sName 0 2)
  let env6 := psCKernelProjectionFixtureAdd env5
    (psCKernelProjectionFixtureAxiom "s" sType)
  let env7 := psCKernelProjectionFixtureAdd env6
    (psCKernelProjectionFixtureInductive "Box" boxType 1 [boxCtorName])
  let env8 := psCKernelProjectionFixtureAdd env7
    (psCKernelProjectionFixtureConstructor "Box.mk" boxCtorType boxName 1 1)
  let env9 := psCKernelProjectionFixtureAdd env8
    (psCKernelProjectionFixtureAxiom "boxa"
      (PsCKernelExpr.app (PsCKernelExpr.constE boxName []) aType))
  let env10 := psCKernelProjectionFixtureAdd env9
    (psCKernelProjectionFixtureInductive "ProofBox" proofBoxType 0 [proofBoxCtorName])
  let env11 := psCKernelProjectionFixtureAdd env10
    (psCKernelProjectionFixtureConstructor "ProofBox.mk" proofBoxCtorType proofBoxName 0 1)
  psCKernelProjectionFixtureAdd env11
    (psCKernelProjectionFixtureAxiom "proofBox" (PsCKernelExpr.constE proofBoxName []))

def psCKernelProjectionFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ => psCKernelLevelToString level ++ "," ++ psCKernelProjectionFixtureLevelListKey rest

def psCKernelProjectionFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameToString name ++ "}[" ++ psCKernelProjectionFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelProjectionFixtureExprKey fn ++ "," ++ psCKernelProjectionFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body _ =>
      "L{" ++ psCKernelNameToString name ++ "}(" ++ psCKernelProjectionFixtureExprKey type ++ "," ++ psCKernelProjectionFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body _ =>
      "P{" ++ psCKernelNameToString name ++ "}(" ++ psCKernelProjectionFixtureExprKey type ++ "," ++ psCKernelProjectionFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameToString name ++ "," ++ (if nondep then "1" else "0") ++ "}(" ++
        psCKernelProjectionFixtureExprKey type ++ "," ++
        psCKernelProjectionFixtureExprKey value ++ "," ++
        psCKernelProjectionFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameToString typeName ++ "," ++ toString index ++ "}(" ++ psCKernelProjectionFixtureExprKey value ++ ")"

def psCKernelProjectionFixtureEmitExpr
    (key : String)
    (value : PsCKernelExpr) : IO Unit :=
  IO.println (key ++ "\t" ++ psCKernelProjectionFixtureExprKey value)

def psCKernelProjectionFixtureEmitOption
    (key : String)
    (value : Option PsCKernelExpr) : IO Unit :=
  match value with
  | none => IO.println (key ++ "\tnone")
  | some expr => psCKernelProjectionFixtureEmitExpr key expr

def main : IO Unit := do
  let env := psCKernelProjectionFixtureEnv
  let ctx := psCKernelLocalContextEmpty
  let sName := psCKernelProjectionFixtureName "S"
  let boxName := psCKernelProjectionFixtureName "Box"
  let proofBoxName := psCKernelProjectionFixtureName "ProofBox"
  let sCtor := psCKernelExprMkAppN
    (psCKernelProjectionFixtureConst "S.mk")
    [psCKernelProjectionFixtureConst "a", psCKernelProjectionFixtureConst "b"]
  let boxCtor := psCKernelExprMkAppN
    (psCKernelProjectionFixtureConst "Box.mk")
    [psCKernelProjectionFixtureConst "A", psCKernelProjectionFixtureConst "a"]

  psCKernelProjectionFixtureEmitExpr "reduce-first"
    (psCKernelExprWhnfBasic env ctx (PsCKernelExpr.proj sName 0 sCtor))
  psCKernelProjectionFixtureEmitExpr "reduce-second"
    (psCKernelExprWhnfBasic env ctx (PsCKernelExpr.proj sName 1 sCtor))
  psCKernelProjectionFixtureEmitOption "infer-first"
    (psCKernelInfer? env ctx (PsCKernelExpr.proj sName 0 (psCKernelProjectionFixtureConst "s")))
  psCKernelProjectionFixtureEmitOption "infer-second"
    (psCKernelInfer? env ctx (PsCKernelExpr.proj sName 1 (psCKernelProjectionFixtureConst "s")))
  psCKernelProjectionFixtureEmitOption "check-first"
    (psCKernelCheckBasic? env ctx (PsCKernelExpr.proj sName 0 (psCKernelProjectionFixtureConst "s")))
  psCKernelProjectionFixtureEmitOption "param-infer"
    (psCKernelInfer? env ctx (PsCKernelExpr.proj boxName 0 (psCKernelProjectionFixtureConst "boxa")))
  psCKernelProjectionFixtureEmitExpr "param-reduce"
    (psCKernelExprWhnfBasic env ctx (PsCKernelExpr.proj boxName 0 boxCtor))
  psCKernelProjectionFixtureEmitOption "bad-index"
    (psCKernelInfer? env ctx (PsCKernelExpr.proj sName 2 (psCKernelProjectionFixtureConst "s")))
  psCKernelProjectionFixtureEmitOption "wrong-name"
    (psCKernelInfer? env ctx (PsCKernelExpr.proj boxName 0 (psCKernelProjectionFixtureConst "s")))
  psCKernelProjectionFixtureEmitOption "proof-to-data"
    (psCKernelInfer? env ctx (PsCKernelExpr.proj proofBoxName 0 (psCKernelProjectionFixtureConst "proofBox")))
