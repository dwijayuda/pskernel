import Ps.PSCKernel.Core.CheckedInferenceBasic

def psCKernelCheckedInferenceBasicFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelCheckedInferenceBasicFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelCheckedInferenceBasicFixtureName text) []

def psCKernelCheckedInferenceBasicFixtureAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelCheckedInferenceBasicFixtureName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelCheckedInferenceBasicFixtureDefinition
    (name : String)
    (declType : PsCKernelExpr)
    (value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := {
      name := psCKernelCheckedInferenceBasicFixtureName name
      levelParams := []
      declType := declType
    }
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := []
  }

def psCKernelCheckedInferenceBasicFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelCheckedInferenceBasicFixtureEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelCheckedInferenceBasicFixtureConst "A"
  let bType := psCKernelCheckedInferenceBasicFixtureConst "B"
  let aliasType := psCKernelCheckedInferenceBasicFixtureConst "AliasType"
  let fType := PsCKernelExpr.forallE
    (psCKernelCheckedInferenceBasicFixtureName "x") aType aType PsCKernelBinderInfo.default
  let env0 := psCKernelCheckedInferenceBasicFixtureAdd
    psCKernelEnvironmentEmpty
    (psCKernelCheckedInferenceBasicFixtureAxiom "A" sort0)
  let env1 := psCKernelCheckedInferenceBasicFixtureAdd
    env0 (psCKernelCheckedInferenceBasicFixtureAxiom "a" aType)
  let env2 := psCKernelCheckedInferenceBasicFixtureAdd
    env1 (psCKernelCheckedInferenceBasicFixtureAxiom "B" sort0)
  let env3 := psCKernelCheckedInferenceBasicFixtureAdd
    env2 (psCKernelCheckedInferenceBasicFixtureAxiom "b" bType)
  let env4 := psCKernelCheckedInferenceBasicFixtureAdd
    env3 (psCKernelCheckedInferenceBasicFixtureDefinition "AliasType" sort0 aType)
  let env5 := psCKernelCheckedInferenceBasicFixtureAdd
    env4 (psCKernelCheckedInferenceBasicFixtureAxiom "aa" aliasType)
  psCKernelCheckedInferenceBasicFixtureAdd
    env5 (psCKernelCheckedInferenceBasicFixtureAxiom "f" fType)

def psCKernelCheckedInferenceBasicFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ => psCKernelLevelToString level ++ "," ++ psCKernelCheckedInferenceBasicFixtureLevelListKey rest

def psCKernelCheckedInferenceBasicFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameToString name ++ "}[" ++ psCKernelCheckedInferenceBasicFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelCheckedInferenceBasicFixtureExprKey fn ++ "," ++ psCKernelCheckedInferenceBasicFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body _ =>
      "L{" ++ psCKernelNameToString name ++ "}(" ++ psCKernelCheckedInferenceBasicFixtureExprKey type ++ "," ++ psCKernelCheckedInferenceBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body _ =>
      "P{" ++ psCKernelNameToString name ++ "}(" ++ psCKernelCheckedInferenceBasicFixtureExprKey type ++ "," ++ psCKernelCheckedInferenceBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameToString name ++ "," ++ (if nondep then "1" else "0") ++ "}(" ++
        psCKernelCheckedInferenceBasicFixtureExprKey type ++ "," ++
        psCKernelCheckedInferenceBasicFixtureExprKey value ++ "," ++
        psCKernelCheckedInferenceBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameToString typeName ++ "," ++ toString index ++ "}(" ++ psCKernelCheckedInferenceBasicFixtureExprKey value ++ ")"

def psCKernelCheckedInferenceBasicFixtureEmit
    (key : String)
    (value : Option PsCKernelExpr) : IO Unit :=
  match value with
  | none => IO.println (key ++ "\tnone")
  | some expr => IO.println (key ++ "\t" ++ psCKernelCheckedInferenceBasicFixtureExprKey expr)

def main : IO Unit := do
  let env := psCKernelCheckedInferenceBasicFixtureEnv
  let ctx := psCKernelLocalContextEmpty
  let aType := psCKernelCheckedInferenceBasicFixtureConst "A"
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero

  psCKernelCheckedInferenceBasicFixtureEmit "sort"
    (psCKernelCheckBasic? env ctx sort0)
  psCKernelCheckedInferenceBasicFixtureEmit "const"
    (psCKernelCheckBasic? env ctx (psCKernelCheckedInferenceBasicFixtureConst "a"))
  psCKernelCheckedInferenceBasicFixtureEmit "valid-app"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.app
        (psCKernelCheckedInferenceBasicFixtureConst "f")
        (psCKernelCheckedInferenceBasicFixtureConst "a")))
  psCKernelCheckedInferenceBasicFixtureEmit "defeq-app"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.app
        (psCKernelCheckedInferenceBasicFixtureConst "f")
        (psCKernelCheckedInferenceBasicFixtureConst "aa")))
  psCKernelCheckedInferenceBasicFixtureEmit "bad-app"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.app
        (psCKernelCheckedInferenceBasicFixtureConst "f")
        (psCKernelCheckedInferenceBasicFixtureConst "b")))
  psCKernelCheckedInferenceBasicFixtureEmit "valid-lambda"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.lam
        (psCKernelCheckedInferenceBasicFixtureName "x") aType
        (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default))
  psCKernelCheckedInferenceBasicFixtureEmit "bad-lambda-domain"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.lam
        (psCKernelCheckedInferenceBasicFixtureName "x")
        (psCKernelCheckedInferenceBasicFixtureConst "a")
        (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default))
  psCKernelCheckedInferenceBasicFixtureEmit "valid-pi"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.forallE
        (psCKernelCheckedInferenceBasicFixtureName "p") sort0 sort0 PsCKernelBinderInfo.default))
  psCKernelCheckedInferenceBasicFixtureEmit "bad-pi-domain"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.forallE
        (psCKernelCheckedInferenceBasicFixtureName "x")
        (psCKernelCheckedInferenceBasicFixtureConst "a") aType PsCKernelBinderInfo.default))
  psCKernelCheckedInferenceBasicFixtureEmit "valid-let"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.letE
        (psCKernelCheckedInferenceBasicFixtureName "x") aType
        (psCKernelCheckedInferenceBasicFixtureConst "a")
        (PsCKernelExpr.bvar 0) false))
  psCKernelCheckedInferenceBasicFixtureEmit "bad-let-type"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.letE
        (psCKernelCheckedInferenceBasicFixtureName "x")
        (psCKernelCheckedInferenceBasicFixtureConst "a")
        (psCKernelCheckedInferenceBasicFixtureConst "a")
        (PsCKernelExpr.bvar 0) false))
  psCKernelCheckedInferenceBasicFixtureEmit "bad-let-value"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.letE
        (psCKernelCheckedInferenceBasicFixtureName "x") aType
        (psCKernelCheckedInferenceBasicFixtureConst "b")
        (PsCKernelExpr.bvar 0) false))
  psCKernelCheckedInferenceBasicFixtureEmit "defeq-let-value"
    (psCKernelCheckBasic? env ctx
      (PsCKernelExpr.letE
        (psCKernelCheckedInferenceBasicFixtureName "x") aType
        (psCKernelCheckedInferenceBasicFixtureConst "aa")
        (PsCKernelExpr.bvar 0) false))
  psCKernelCheckedInferenceBasicFixtureEmit "unknown-const"
    (psCKernelCheckBasic? env ctx (psCKernelCheckedInferenceBasicFixtureConst "missing"))
