import Ps.PSCKernel.Core.DefEqBasic

def psCKernelDefEqBasicFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelDefEqBasicFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelDefEqBasicFixtureName text) []

def psCKernelDefEqBasicFixtureAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqBasicFixtureName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelDefEqBasicFixtureDefinition
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelDefEqBasicFixtureName name
      levelParams := []
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelDefEqBasicFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelDefEqBasicFixtureEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelDefEqBasicFixtureConst "A"
  let env0 := psCKernelDefEqBasicFixtureAdd
    psCKernelEnvironmentEmpty
    (psCKernelDefEqBasicFixtureAxiom "A" sort0)
  let env1 := psCKernelDefEqBasicFixtureAdd
    env0
    (psCKernelDefEqBasicFixtureAxiom "a" aType)
  let env2 := psCKernelDefEqBasicFixtureAdd
    env1
    (psCKernelDefEqBasicFixtureDefinition
      "alias" aType (psCKernelDefEqBasicFixtureConst "a"))
  let idType := PsCKernelExpr.forallE
    (psCKernelDefEqBasicFixtureName "x") aType aType PsCKernelBinderInfo.default
  let idValue := PsCKernelExpr.lam
    (psCKernelDefEqBasicFixtureName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  psCKernelDefEqBasicFixtureAdd
    env2
    (psCKernelDefEqBasicFixtureDefinition "id" idType idValue)

def psCKernelDefEqBasicFixtureEmit
    (key : String)
    (value : Bool) : IO Unit :=
  IO.println (key ++ "\t" ++ (if value then "true" else "false"))

def main : IO Unit := do
  let env := psCKernelDefEqBasicFixtureEnv
  let emptyCtx := psCKernelLocalContextEmpty
  let aType := psCKernelDefEqBasicFixtureConst "A"

  psCKernelDefEqBasicFixtureEmit
    "structural"
    (psCKernelIsDefEqBasic env emptyCtx
      (psCKernelDefEqBasicFixtureConst "a")
      (psCKernelDefEqBasicFixtureConst "a"))

  psCKernelDefEqBasicFixtureEmit
    "binder-presentation"
    (psCKernelIsDefEqBasic env emptyCtx
      (PsCKernelExpr.lam
        (psCKernelDefEqBasicFixtureName "x") aType (PsCKernelExpr.bvar 0)
        PsCKernelBinderInfo.default)
      (PsCKernelExpr.lam
        (psCKernelDefEqBasicFixtureName "renamed") aType (PsCKernelExpr.bvar 0)
        PsCKernelBinderInfo.implicit))

  let uName := psCKernelDefEqBasicFixtureName "u"
  let u := psCKernelLevelParam uName
  psCKernelDefEqBasicFixtureEmit
    "sort-level"
    (psCKernelIsDefEqBasic env emptyCtx
      (PsCKernelExpr.sortE (psCKernelLevelMkMax u u))
      (PsCKernelExpr.sortE u))

  let polyInfo := PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelDefEqBasicFixtureName "Poly"
      levelParams := [uName]
      declType := PsCKernelExpr.sortE u
    }
    isUnsafe := false
  }
  let polyEnv := psCKernelDefEqBasicFixtureAdd env polyInfo
  psCKernelDefEqBasicFixtureEmit
    "const-level"
    (psCKernelIsDefEqBasic polyEnv emptyCtx
      (PsCKernelExpr.constE
        (psCKernelDefEqBasicFixtureName "Poly") [psCKernelLevelMkMax u u])
      (PsCKernelExpr.constE (psCKernelDefEqBasicFixtureName "Poly") [u]))

  let beta := PsCKernelExpr.app
    (PsCKernelExpr.lam
      (psCKernelDefEqBasicFixtureName "x") aType (PsCKernelExpr.bvar 0)
      PsCKernelBinderInfo.default)
    (psCKernelDefEqBasicFixtureConst "a")
  psCKernelDefEqBasicFixtureEmit
    "beta"
    (psCKernelIsDefEqBasic env emptyCtx beta (psCKernelDefEqBasicFixtureConst "a"))

  let zeta := PsCKernelExpr.letE
    (psCKernelDefEqBasicFixtureName "x") aType
    (psCKernelDefEqBasicFixtureConst "a")
    (PsCKernelExpr.bvar 0)
    false
  psCKernelDefEqBasicFixtureEmit
    "zeta"
    (psCKernelIsDefEqBasic env emptyCtx zeta (psCKernelDefEqBasicFixtureConst "a"))

  psCKernelDefEqBasicFixtureEmit
    "delta"
    (psCKernelIsDefEqBasic env emptyCtx
      (psCKernelDefEqBasicFixtureConst "alias")
      (psCKernelDefEqBasicFixtureConst "a"))

  psCKernelDefEqBasicFixtureEmit
    "delta-beta"
    (psCKernelIsDefEqBasic env emptyCtx
      (PsCKernelExpr.app
        (psCKernelDefEqBasicFixtureConst "id")
        (psCKernelDefEqBasicFixtureConst "a"))
      (psCKernelDefEqBasicFixtureConst "a"))

  let localId : PsCKernelFVarId := { name := psCKernelDefEqBasicFixtureName "xId" }
  let localCtx := psCKernelLocalContextMkLetDecl
    emptyCtx localId (psCKernelDefEqBasicFixtureName "x")
    aType (psCKernelDefEqBasicFixtureConst "a")
    false PsCKernelLocalDeclKind.default
  psCKernelDefEqBasicFixtureEmit
    "local-let"
    (psCKernelIsDefEqBasic env localCtx
      (PsCKernelExpr.fvar localId)
      (psCKernelDefEqBasicFixtureConst "a"))

  psCKernelDefEqBasicFixtureEmit
    "different-constants"
    (psCKernelIsDefEqBasic env emptyCtx
      (psCKernelDefEqBasicFixtureConst "A")
      (psCKernelDefEqBasicFixtureConst "a"))

  let fn := psCKernelDefEqBasicFixtureConst "f"
  psCKernelDefEqBasicFixtureEmit
    "different-app-args"
    (psCKernelIsDefEqBasic env emptyCtx
      (PsCKernelExpr.app fn (psCKernelDefEqBasicFixtureConst "A"))
      (PsCKernelExpr.app fn (psCKernelDefEqBasicFixtureConst "a")))

  let leftPi := PsCKernelExpr.forallE
    (psCKernelDefEqBasicFixtureName "x")
    (PsCKernelExpr.sortE (psCKernelLevelMkMax u u))
    (PsCKernelExpr.sortE u)
    PsCKernelBinderInfo.default
  let rightPi := PsCKernelExpr.forallE
    (psCKernelDefEqBasicFixtureName "y")
    (PsCKernelExpr.sortE u)
    (PsCKernelExpr.sortE (psCKernelLevelMkMax u u))
    PsCKernelBinderInfo.implicit
  psCKernelDefEqBasicFixtureEmit
    "pi-recursive"
    (psCKernelIsDefEqBasic env emptyCtx leftPi rightPi)
