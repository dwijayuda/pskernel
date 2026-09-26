import Ps.PSCKernel.Core.TypeInference

def psCKernelTypeInferenceFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelTypeInferenceFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelTypeInferenceFixtureName text) []

def psCKernelTypeInferenceFixtureAxiom
    (name : String)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelTypeInferenceFixtureName name
      levelParams := []
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelTypeInferenceFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelTypeInferenceFixtureEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelTypeInferenceFixtureConst "A"
  let bType := psCKernelTypeInferenceFixtureConst "B"
  let pType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceFixtureName "x") aType sort0 PsCKernelBinderInfo.default
  let pOfX := PsCKernelExpr.app (psCKernelTypeInferenceFixtureConst "P") (PsCKernelExpr.bvar 0)
  let gType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceFixtureName "x") aType pOfX PsCKernelBinderInfo.default
  let env0 := psCKernelTypeInferenceFixtureAdd
    psCKernelEnvironmentEmpty (psCKernelTypeInferenceFixtureAxiom "A" sort0)
  let env1 := psCKernelTypeInferenceFixtureAdd env0 (psCKernelTypeInferenceFixtureAxiom "a" aType)
  let env2 := psCKernelTypeInferenceFixtureAdd env1 (psCKernelTypeInferenceFixtureAxiom "B" sort0)
  let env3 := psCKernelTypeInferenceFixtureAdd env2 (psCKernelTypeInferenceFixtureAxiom "b" bType)
  let env4 := psCKernelTypeInferenceFixtureAdd env3 (psCKernelTypeInferenceFixtureAxiom "P" pType)
  psCKernelTypeInferenceFixtureAdd env4 (psCKernelTypeInferenceFixtureAxiom "g" gType)

def psCKernelTypeInferenceFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ => psCKernelLevelToString level ++ "," ++ psCKernelTypeInferenceFixtureLevelListKey rest

def psCKernelTypeInferenceFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameToString name ++ "}[" ++ psCKernelTypeInferenceFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelTypeInferenceFixtureExprKey fn ++ "," ++ psCKernelTypeInferenceFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body _ =>
      "L{" ++ psCKernelNameToString name ++ "}(" ++ psCKernelTypeInferenceFixtureExprKey type ++ "," ++ psCKernelTypeInferenceFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body _ =>
      "P{" ++ psCKernelNameToString name ++ "}(" ++ psCKernelTypeInferenceFixtureExprKey type ++ "," ++ psCKernelTypeInferenceFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameToString name ++ "," ++ (if nondep then "1" else "0") ++ "}(" ++
        psCKernelTypeInferenceFixtureExprKey type ++ "," ++
        psCKernelTypeInferenceFixtureExprKey value ++ "," ++
        psCKernelTypeInferenceFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameToString typeName ++ "," ++ toString index ++ "}(" ++ psCKernelTypeInferenceFixtureExprKey value ++ ")"

def psCKernelTypeInferenceFixtureEmit
    (key : String)
    (value : Option PsCKernelExpr) : IO Unit :=
  match value with
  | none => IO.println (key ++ "\tnone")
  | some expr => IO.println (key ++ "\t" ++ psCKernelTypeInferenceFixtureExprKey expr)

def main : IO Unit := do
  let env := psCKernelTypeInferenceFixtureEnv
  let ctx := psCKernelLocalContextEmpty
  let aType := psCKernelTypeInferenceFixtureConst "A"
  let bType := psCKernelTypeInferenceFixtureConst "B"
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero

  let identity := PsCKernelExpr.lam
    (psCKernelTypeInferenceFixtureName "x") aType (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "identity-lambda" (psCKernelInfer? env ctx identity)

  let badDomainLambda := PsCKernelExpr.lam
    (psCKernelTypeInferenceFixtureName "x")
    (psCKernelTypeInferenceFixtureConst "a")
    (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "unchecked-lambda-domain" (psCKernelInfer? env ctx badDomainLambda)

  let nestedLambda := PsCKernelExpr.lam
    (psCKernelTypeInferenceFixtureName "x") aType
    (PsCKernelExpr.lam
      (psCKernelTypeInferenceFixtureName "y") bType (PsCKernelExpr.bvar 1) PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "nested-lambda" (psCKernelInfer? env ctx nestedLambda)

  let dependentLambda := PsCKernelExpr.lam
    (psCKernelTypeInferenceFixtureName "x") aType
    (PsCKernelExpr.app (psCKernelTypeInferenceFixtureConst "g") (PsCKernelExpr.bvar 0))
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "dependent-lambda" (psCKernelInfer? env ctx dependentLambda)

  let propPi := PsCKernelExpr.forallE
    (psCKernelTypeInferenceFixtureName "p") sort0 (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "pi-prop" (psCKernelInfer? env ctx propPi)

  let typePi := PsCKernelExpr.forallE
    (psCKernelTypeInferenceFixtureName "p") sort0 sort0 PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "pi-type" (psCKernelInfer? env ctx typePi)

  let badPi := PsCKernelExpr.forallE
    (psCKernelTypeInferenceFixtureName "x")
    (psCKernelTypeInferenceFixtureConst "a")
    aType
    PsCKernelBinderInfo.default
  psCKernelTypeInferenceFixtureEmit "pi-bad-domain" (psCKernelInfer? env ctx badPi)

  let dependentLet := PsCKernelExpr.letE
    (psCKernelTypeInferenceFixtureName "x") aType
    (psCKernelTypeInferenceFixtureConst "a")
    (PsCKernelExpr.app (psCKernelTypeInferenceFixtureConst "g") (PsCKernelExpr.bvar 0))
    false
  psCKernelTypeInferenceFixtureEmit "dependent-let" (psCKernelInfer? env ctx dependentLet)

  let nondependentLet := PsCKernelExpr.letE
    (psCKernelTypeInferenceFixtureName "x") aType
    (psCKernelTypeInferenceFixtureConst "a")
    (psCKernelTypeInferenceFixtureConst "b")
    false
  psCKernelTypeInferenceFixtureEmit "nondependent-let" (psCKernelInfer? env ctx nondependentLet)

  psCKernelTypeInferenceFixtureEmit
    "lambda-app"
    (psCKernelInfer?
      env ctx (PsCKernelExpr.app identity (psCKernelTypeInferenceFixtureConst "a")))
