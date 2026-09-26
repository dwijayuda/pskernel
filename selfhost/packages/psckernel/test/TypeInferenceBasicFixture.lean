import Ps.PSCKernel.Core.TypeInferenceBasic

def psCKernelTypeInferenceBasicFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelTypeInferenceBasicFixtureConst (text : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelTypeInferenceBasicFixtureName text) []

def psCKernelTypeInferenceBasicFixtureAxiom
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := {
      name := psCKernelTypeInferenceBasicFixtureName name
      levelParams := levelParams
      declType := declType
    }
    isUnsafe := false
  }

def psCKernelTypeInferenceBasicFixtureAdd
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | none => env
  | some next => next

def psCKernelTypeInferenceBasicFixtureBaseEnv : PsCKernelEnvironment :=
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let aType := psCKernelTypeInferenceBasicFixtureConst "A"
  let env0 := psCKernelTypeInferenceBasicFixtureAdd
    psCKernelEnvironmentEmpty
    (psCKernelTypeInferenceBasicFixtureAxiom "A" [] sort0)
  let env1 := psCKernelTypeInferenceBasicFixtureAdd
    env0
    (psCKernelTypeInferenceBasicFixtureAxiom "a" [] aType)
  let env2 := psCKernelTypeInferenceBasicFixtureAdd
    env1
    (psCKernelTypeInferenceBasicFixtureAxiom "B" [] sort0)
  psCKernelTypeInferenceBasicFixtureAdd
    env2
    (psCKernelTypeInferenceBasicFixtureAxiom
      "b" [] (psCKernelTypeInferenceBasicFixtureConst "B"))

def psCKernelTypeInferenceBasicFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ => psCKernelLevelToString level ++ "," ++ psCKernelTypeInferenceBasicFixtureLevelListKey rest

def psCKernelTypeInferenceBasicFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameToString name ++ "}[" ++
        psCKernelTypeInferenceBasicFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelTypeInferenceBasicFixtureExprKey fn ++ "," ++
        psCKernelTypeInferenceBasicFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body _ =>
      "L{" ++ psCKernelNameToString name ++ "}(" ++
        psCKernelTypeInferenceBasicFixtureExprKey type ++ "," ++
        psCKernelTypeInferenceBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body _ =>
      "P{" ++ psCKernelNameToString name ++ "}(" ++
        psCKernelTypeInferenceBasicFixtureExprKey type ++ "," ++
        psCKernelTypeInferenceBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameToString name ++ "," ++
        (if nondep then "1" else "0") ++ "}(" ++
        psCKernelTypeInferenceBasicFixtureExprKey type ++ "," ++
        psCKernelTypeInferenceBasicFixtureExprKey value ++ "," ++
        psCKernelTypeInferenceBasicFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameToString typeName ++ "," ++ toString index ++ "}(" ++
        psCKernelTypeInferenceBasicFixtureExprKey value ++ ")"

def psCKernelTypeInferenceBasicFixtureEmit
    (key : String)
    (value : Option PsCKernelExpr) : IO Unit :=
  match value with
  | none => IO.println (key ++ "\tnone")
  | some expr =>
      IO.println (key ++ "\t" ++ psCKernelTypeInferenceBasicFixtureExprKey expr)

def main : IO Unit := do
  let env := psCKernelTypeInferenceBasicFixtureBaseEnv
  let emptyCtx := psCKernelLocalContextEmpty
  let aType := psCKernelTypeInferenceBasicFixtureConst "A"
  let bType := psCKernelTypeInferenceBasicFixtureConst "B"

  psCKernelTypeInferenceBasicFixtureEmit
    "sort"
    (psCKernelInferBasic? env emptyCtx (PsCKernelExpr.sortE psCKernelLevelZero))

  let xId : PsCKernelFVarId := { name := psCKernelTypeInferenceBasicFixtureName "xId" }
  let xCtx := psCKernelLocalContextMkLocalDecl
    emptyCtx xId (psCKernelTypeInferenceBasicFixtureName "x") aType
    PsCKernelBinderInfo.default PsCKernelLocalDeclKind.default
  psCKernelTypeInferenceBasicFixtureEmit
    "known-fvar"
    (psCKernelInferBasic? env xCtx (PsCKernelExpr.fvar xId))

  let missingId : PsCKernelFVarId := { name := psCKernelTypeInferenceBasicFixtureName "missing" }
  psCKernelTypeInferenceBasicFixtureEmit
    "unknown-fvar"
    (psCKernelInferBasic? env emptyCtx (PsCKernelExpr.fvar missingId))

  psCKernelTypeInferenceBasicFixtureEmit
    "known-const"
    (psCKernelInferBasic? env emptyCtx (psCKernelTypeInferenceBasicFixtureConst "a"))

  let u := psCKernelTypeInferenceBasicFixtureName "u"
  let polyEnv := psCKernelTypeInferenceBasicFixtureAdd
    env
    (psCKernelTypeInferenceBasicFixtureAxiom
      "Poly" [u] (PsCKernelExpr.sortE (psCKernelLevelParam u)))
  psCKernelTypeInferenceBasicFixtureEmit
    "universe-const"
    (psCKernelInferBasic?
      polyEnv emptyCtx
      (PsCKernelExpr.constE
        (psCKernelTypeInferenceBasicFixtureName "Poly") [psCKernelLevelZero]))
  psCKernelTypeInferenceBasicFixtureEmit
    "bad-universe-arity"
    (psCKernelInferBasic? polyEnv emptyCtx (psCKernelTypeInferenceBasicFixtureConst "Poly"))

  let dependentFType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceBasicFixtureName "x") aType (PsCKernelExpr.bvar 0)
    PsCKernelBinderInfo.default
  let dependentEnv := psCKernelTypeInferenceBasicFixtureAdd
    env
    (psCKernelTypeInferenceBasicFixtureAxiom "f" [] dependentFType)
  psCKernelTypeInferenceBasicFixtureEmit
    "app"
    (psCKernelInferBasic?
      dependentEnv emptyCtx
      (PsCKernelExpr.app
        (psCKernelTypeInferenceBasicFixtureConst "f")
        (psCKernelTypeInferenceBasicFixtureConst "a")))

  let constantFType := PsCKernelExpr.forallE
    (psCKernelTypeInferenceBasicFixtureName "x") aType bType PsCKernelBinderInfo.default
  let constantEnv := psCKernelTypeInferenceBasicFixtureAdd
    env
    (psCKernelTypeInferenceBasicFixtureAxiom "f" [] constantFType)
  psCKernelTypeInferenceBasicFixtureEmit
    "unchecked-arg"
    (psCKernelInferBasic?
      constantEnv emptyCtx
      (PsCKernelExpr.app
        (psCKernelTypeInferenceBasicFixtureConst "f")
        (psCKernelTypeInferenceBasicFixtureConst "missingArgument")))

  let wrappedType := PsCKernelExpr.letE
    (psCKernelTypeInferenceBasicFixtureName "T")
    (PsCKernelExpr.sortE psCKernelLevelZero)
    constantFType
    (PsCKernelExpr.bvar 0)
    false
  let wrappedEnv := psCKernelTypeInferenceBasicFixtureAdd
    env
    (psCKernelTypeInferenceBasicFixtureAxiom "wrapped" [] wrappedType)
  psCKernelTypeInferenceBasicFixtureEmit
    "app-whnf-type"
    (psCKernelInferBasic?
      wrappedEnv emptyCtx
      (PsCKernelExpr.app
        (psCKernelTypeInferenceBasicFixtureConst "wrapped")
        (psCKernelTypeInferenceBasicFixtureConst "a")))

  psCKernelTypeInferenceBasicFixtureEmit
    "let"
    (psCKernelInferBasic?
      env emptyCtx
      (PsCKernelExpr.letE
        (psCKernelTypeInferenceBasicFixtureName "x") aType
        (psCKernelTypeInferenceBasicFixtureConst "a")
        (PsCKernelExpr.bvar 0)
        false))

  let innerLet := PsCKernelExpr.letE
    (psCKernelTypeInferenceBasicFixtureName "y") aType
    (PsCKernelExpr.bvar 0)
    (PsCKernelExpr.bvar 0)
    false
  psCKernelTypeInferenceBasicFixtureEmit
    "nested-let"
    (psCKernelInferBasic?
      env emptyCtx
      (PsCKernelExpr.letE
        (psCKernelTypeInferenceBasicFixtureName "x") aType
        (psCKernelTypeInferenceBasicFixtureConst "a") innerLet false))

  psCKernelTypeInferenceBasicFixtureEmit
    "nat-lit"
    (psCKernelInferBasic? env emptyCtx (PsCKernelExpr.lit (PsCKernelLiteral.natVal 7)))
  psCKernelTypeInferenceBasicFixtureEmit
    "string-lit"
    (psCKernelInferBasic? env emptyCtx (PsCKernelExpr.lit (PsCKernelLiteral.strVal "psc1")))
  psCKernelTypeInferenceBasicFixtureEmit
    "loose-bvar"
    (psCKernelInferBasic? env emptyCtx (PsCKernelExpr.bvar 0))
  let mId : PsCKernelMVarId := { name := psCKernelTypeInferenceBasicFixtureName "m" }
  psCKernelTypeInferenceBasicFixtureEmit
    "mvar"
    (psCKernelInferBasic? env emptyCtx (PsCKernelExpr.mvar mId))
  psCKernelTypeInferenceBasicFixtureEmit
    "non-function-app"
    (psCKernelInferBasic?
      env emptyCtx
      (PsCKernelExpr.app
        (psCKernelTypeInferenceBasicFixtureConst "a")
        (psCKernelTypeInferenceBasicFixtureConst "a")))
