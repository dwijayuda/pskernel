import Ps.PSCKernel.Core.DefEq

def psCKernelDefEqProofFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDefEqProofFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDefEqProofFixtureName text) []

def psCKernelDefEqProofFixtureAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqProofFixtureName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelDefEqProofFixtureDefinition
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelDefEqProofFixtureName name
      levelParams := []
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelDefEqProofFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelDefEqProofFixtureEnv : PsCKernelEnvironment :=
  let propSort := PsCKernelExpr.sortE psCKernelLevelZero
  let typeSort := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let pType := psCKernelDefEqProofFixtureConst "P"
  let qType := psCKernelDefEqProofFixtureConst "Q"
  let aType := psCKernelDefEqProofFixtureConst "A"
  let aliasP := psCKernelDefEqProofFixtureConst "AliasP"
  let env0 := psCKernelDefEqProofFixtureAdd psCKernelEnvironmentEmpty
    (psCKernelDefEqProofFixtureAxiom "P" propSort)
  let env1 := psCKernelDefEqProofFixtureAdd env0
    (psCKernelDefEqProofFixtureAxiom "p" pType)
  let env2 := psCKernelDefEqProofFixtureAdd env1
    (psCKernelDefEqProofFixtureAxiom "q" pType)
  let env3 := psCKernelDefEqProofFixtureAdd env2
    (psCKernelDefEqProofFixtureAxiom "Q" propSort)
  let env4 := psCKernelDefEqProofFixtureAdd env3
    (psCKernelDefEqProofFixtureAxiom "r" qType)
  let env5 := psCKernelDefEqProofFixtureAdd env4
    (psCKernelDefEqProofFixtureDefinition "AliasP" propSort pType)
  let env6 := psCKernelDefEqProofFixtureAdd env5
    (psCKernelDefEqProofFixtureAxiom "aliasProof" aliasP)
  let env7 := psCKernelDefEqProofFixtureAdd env6
    (psCKernelDefEqProofFixtureAxiom "A" typeSort)
  let env8 := psCKernelDefEqProofFixtureAdd env7
    (psCKernelDefEqProofFixtureAxiom "a" aType)
  psCKernelDefEqProofFixtureAdd env8
    (psCKernelDefEqProofFixtureAxiom "b" aType)

def psCKernelDefEqProofFixtureEmit
    (key : String)
    (value : Bool) : IO Unit :=
  IO.println (key ++ "\t" ++ (if value then "1" else "0"))

def main : IO Unit := do
  let env := psCKernelDefEqProofFixtureEnv
  let ctx := psCKernelLocalContextEmpty
  psCKernelDefEqProofFixtureEmit "same-prop"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "p")
      (psCKernelDefEqProofFixtureConst "q"))
  psCKernelDefEqProofFixtureEmit "same-prop-symmetric"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "q")
      (psCKernelDefEqProofFixtureConst "p"))
  psCKernelDefEqProofFixtureEmit "defeq-prop-types"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "p")
      (psCKernelDefEqProofFixtureConst "aliasProof"))
  psCKernelDefEqProofFixtureEmit "different-props"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "p")
      (psCKernelDefEqProofFixtureConst "r"))
  psCKernelDefEqProofFixtureEmit "data"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "a")
      (psCKernelDefEqProofFixtureConst "b"))
  psCKernelDefEqProofFixtureEmit "prop-expressions"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "P")
      (psCKernelDefEqProofFixtureConst "Q"))
  psCKernelDefEqProofFixtureEmit "reflexive-data"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "a")
      (psCKernelDefEqProofFixtureConst "a"))
  psCKernelDefEqProofFixtureEmit "delta"
    (psCKernelIsDefEq env ctx
      (psCKernelDefEqProofFixtureConst "AliasP")
      (psCKernelDefEqProofFixtureConst "P"))
