import Ps.PSCKernel.Core.ReductionBasic

def psCKernelReductionBasicFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelReductionBasicFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelReductionBasicFixtureName text) []

def psCKernelReductionBasicFixtureDefinition
    (name : String)
    (levelParams : List PsCKernelName)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelReductionBasicFixtureName name
      levelParams := levelParams
      declType := psCKernelReductionBasicFixtureConst "Type"
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 1
    safety := PsCKernelDefinitionSafety.safe
    all := [psCKernelReductionBasicFixtureName name]
  }

def psCKernelReductionBasicFixtureTheorem
    (name : String)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := {
      name := psCKernelReductionBasicFixtureName name
      levelParams := []
      declType := psCKernelReductionBasicFixtureConst "Prop"
    }
    value := value
    all := [psCKernelReductionBasicFixtureName name]
  }

def psCKernelReductionBasicFixtureEnvWith
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd psCKernelEnvironmentEmpty info with
  | none => psCKernelEnvironmentEmpty
  | some env => env

def psCKernelReductionBasicFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ =>
          psCKernelLevelToString level ++ "," ++
            psCKernelReductionBasicFixtureLevelListKey rest

def psCKernelReductionBasicFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameToString name ++ "}[" ++
        psCKernelReductionBasicFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelReductionBasicFixtureExprKey fn ++ "," ++
        psCKernelReductionBasicFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body _ =>
      "L{" ++ psCKernelNameToString name ++ "}(" ++
        psCKernelReductionBasicFixtureExprKey type ++ "," ++
        psCKernelReductionBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body _ =>
      "P{" ++ psCKernelNameToString name ++ "}(" ++
        psCKernelReductionBasicFixtureExprKey type ++ "," ++
        psCKernelReductionBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameToString name ++ "," ++
        (if nondep then "1" else "0") ++ "}(" ++
        psCKernelReductionBasicFixtureExprKey type ++ "," ++
        psCKernelReductionBasicFixtureExprKey value ++ "," ++
        psCKernelReductionBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameToString typeName ++ "," ++ toString index ++ "}(" ++
        psCKernelReductionBasicFixtureExprKey value ++ ")"

def psCKernelReductionBasicFixtureEmit
    (key : String)
    (expr : PsCKernelExpr) : IO Unit :=
  IO.println (key ++ "\t" ++ psCKernelReductionBasicFixtureExprKey expr)

def main : IO Unit := do
  let emptyEnv := psCKernelEnvironmentEmpty
  let emptyCtx := psCKernelLocalContextEmpty
  let valueA := psCKernelReductionBasicFixtureConst "A"
  let valueB := psCKernelReductionBasicFixtureConst "B"
  let typeT := psCKernelReductionBasicFixtureConst "T"

  psCKernelReductionBasicFixtureEmit
    "easy-const"
    (psCKernelExprWhnfBasic emptyEnv emptyCtx valueA)

  psCKernelReductionBasicFixtureEmit
    "let-zeta"
    (psCKernelExprWhnfBasic
      emptyEnv
      emptyCtx
      (PsCKernelExpr.letE
        (psCKernelReductionBasicFixtureName "x")
        typeT
        valueA
        (PsCKernelExpr.bvar 0)
        false))

  let identity := PsCKernelExpr.lam
    (psCKernelReductionBasicFixtureName "x")
    typeT
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  psCKernelReductionBasicFixtureEmit
    "beta"
    (psCKernelExprWhnfBasic emptyEnv emptyCtx (PsCKernelExpr.app identity valueA))

  let chooseFirst := PsCKernelExpr.lam
    (psCKernelReductionBasicFixtureName "x")
    typeT
    (PsCKernelExpr.lam
      (psCKernelReductionBasicFixtureName "y")
      typeT
      (PsCKernelExpr.bvar 1)
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default
  psCKernelReductionBasicFixtureEmit
    "nested-beta"
    (psCKernelExprWhnfBasic
      emptyEnv
      emptyCtx
      (PsCKernelExpr.app (PsCKernelExpr.app chooseFirst valueA) valueB))

  let fvarId : PsCKernelFVarId := { name := psCKernelReductionBasicFixtureName "xId" }
  let letCtx := psCKernelLocalContextMkLetDecl
    emptyCtx
    fvarId
    (psCKernelReductionBasicFixtureName "x")
    typeT
    valueA
    false
    PsCKernelLocalDeclKind.default
  psCKernelReductionBasicFixtureEmit
    "local-let"
    (psCKernelExprWhnfBasic emptyEnv letCtx (PsCKernelExpr.fvar fvarId))

  let deltaEnv := psCKernelReductionBasicFixtureEnvWith
    (psCKernelReductionBasicFixtureDefinition "d" [] valueA)
  psCKernelReductionBasicFixtureEmit
    "delta"
    (psCKernelExprWhnfBasic deltaEnv emptyCtx (psCKernelReductionBasicFixtureConst "d"))

  let identityEnv := psCKernelReductionBasicFixtureEnvWith
    (psCKernelReductionBasicFixtureDefinition "id" [] identity)
  psCKernelReductionBasicFixtureEmit
    "delta-beta"
    (psCKernelExprWhnfBasic
      identityEnv
      emptyCtx
      (PsCKernelExpr.app (psCKernelReductionBasicFixtureConst "id") valueA))

  let theoremEnv := psCKernelReductionBasicFixtureEnvWith
    (psCKernelReductionBasicFixtureTheorem
      "thm"
      (psCKernelReductionBasicFixtureConst "proof"))
  psCKernelReductionBasicFixtureEmit
    "theorem-stuck"
    (psCKernelExprWhnfBasic
      theoremEnv
      emptyCtx
      (psCKernelReductionBasicFixtureConst "thm"))

  let u := psCKernelReductionBasicFixtureName "u"
  let polyEnv := psCKernelReductionBasicFixtureEnvWith
    (psCKernelReductionBasicFixtureDefinition
      "poly"
      [u]
      (PsCKernelExpr.sortE (psCKernelLevelParam u)))
  psCKernelReductionBasicFixtureEmit
    "universe-delta"
    (psCKernelExprWhnfBasic
      polyEnv
      emptyCtx
      (PsCKernelExpr.constE
        (psCKernelReductionBasicFixtureName "poly")
        [psCKernelLevelZero]))

  psCKernelReductionBasicFixtureEmit
    "bad-universe-arity"
    (psCKernelExprWhnfBasic
      polyEnv
      emptyCtx
      (psCKernelReductionBasicFixtureConst "poly"))

  let reducibleHead := PsCKernelExpr.letE
    (psCKernelReductionBasicFixtureName "f")
    (psCKernelReductionBasicFixtureConst "Fn")
    identity
    (PsCKernelExpr.bvar 0)
    false
  psCKernelReductionBasicFixtureEmit
    "let-head-beta"
    (psCKernelExprWhnfBasic
      emptyEnv
      emptyCtx
      (PsCKernelExpr.app reducibleHead valueA))
