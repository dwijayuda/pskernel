import Ps.PSCKernel.Core.ExprLevelInstantiation

def psCKernelExprLevelFixtureBinderInfoKey (info : PsCKernelBinderInfo) : String :=
  match info with
  | PsCKernelBinderInfo.default => "d"
  | PsCKernelBinderInfo.implicit => "i"
  | PsCKernelBinderInfo.strictImplicit => "s"
  | PsCKernelBinderInfo.instImplicit => "c"

def psCKernelExprLevelFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ =>
          psCKernelLevelToString level ++ "," ++
            psCKernelExprLevelFixtureLevelListKey rest

def psCKernelExprLevelFixtureLiteralKey (literal : PsCKernelLiteral) : String :=
  match literal with
  | PsCKernelLiteral.natVal value => "N" ++ toString value
  | PsCKernelLiteral.strVal value => "Q" ++ value

def psCKernelExprLevelFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameKey id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameKey id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameKey name ++ "}[" ++
        psCKernelExprLevelFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelExprLevelFixtureExprKey fn ++ "," ++
        psCKernelExprLevelFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body binderInfo =>
      "L{" ++ psCKernelNameKey name ++ "," ++
        psCKernelExprLevelFixtureBinderInfoKey binderInfo ++ "}(" ++
        psCKernelExprLevelFixtureExprKey type ++ "," ++
        psCKernelExprLevelFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body binderInfo =>
      "P{" ++ psCKernelNameKey name ++ "," ++
        psCKernelExprLevelFixtureBinderInfoKey binderInfo ++ "}(" ++
        psCKernelExprLevelFixtureExprKey type ++ "," ++
        psCKernelExprLevelFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameKey name ++ "," ++
        (if nondep then "1" else "0") ++ "}(" ++
        psCKernelExprLevelFixtureExprKey type ++ "," ++
        psCKernelExprLevelFixtureExprKey value ++ "," ++
        psCKernelExprLevelFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal => psCKernelExprLevelFixtureLiteralKey literal
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameKey typeName ++ "," ++ toString index ++ "}(" ++
        psCKernelExprLevelFixtureExprKey value ++ ")"

def psCKernelExprLevelFixtureEmit
    (key : String)
    (expr : PsCKernelExpr) : IO Unit :=
  IO.println (key ++ "\t" ++ psCKernelExprLevelFixtureExprKey expr)

def main : IO Unit := do
  let nameU : PsCKernelName := psCKernelNameFromDotted "u"
  let nameV : PsCKernelName := psCKernelNameFromDotted "v"
  let nameC : PsCKernelName := psCKernelNameFromDotted "C"
  let nameF : PsCKernelName := psCKernelNameFromDotted "f"
  let nameP : PsCKernelName := psCKernelNameFromDotted "P"
  let nameX : PsCKernelName := psCKernelNameFromDotted "x"
  let u : PsCKernelLevel := psCKernelLevelParam nameU
  let v : PsCKernelLevel := psCKernelLevelParam nameV
  let zeroLevel : PsCKernelLevel := psCKernelLevelZero
  let oneLevel : PsCKernelLevel := psCKernelLevelSucc zeroLevel

  psCKernelExprLevelFixtureEmit
    "empty"
    (psCKernelInstantiateExprLevels (PsCKernelExpr.sortE u) [] [])
  psCKernelExprLevelFixtureEmit
    "sort"
    (psCKernelInstantiateExprLevels
      (PsCKernelExpr.sortE (psCKernelLevelSucc u))
      [nameU]
      [zeroLevel])
  psCKernelExprLevelFixtureEmit
    "const"
    (psCKernelInstantiateExprLevels
      (PsCKernelExpr.constE nameC [u, v])
      [nameU, nameV]
      [zeroLevel, oneLevel])
  psCKernelExprLevelFixtureEmit
    "nested"
    (psCKernelInstantiateExprLevels
      (PsCKernelExpr.letE
        nameX
        (PsCKernelExpr.sortE u)
        (PsCKernelExpr.constE nameC [u])
        (PsCKernelExpr.proj
          nameP
          0
          (PsCKernelExpr.app
            (PsCKernelExpr.constE nameF [u])
            (PsCKernelExpr.sortE v)))
        true)
      [nameU]
      [zeroLevel])
  psCKernelExprLevelFixtureEmit
    "binders"
    (psCKernelInstantiateExprLevels
      (PsCKernelExpr.forallE
        nameX
        (PsCKernelExpr.sortE u)
        (PsCKernelExpr.lam
          nameX
          (PsCKernelExpr.sortE v)
          (PsCKernelExpr.constE nameC [u])
          PsCKernelBinderInfo.implicit)
        PsCKernelBinderInfo.default)
      [nameU]
      [zeroLevel])
  psCKernelExprLevelFixtureEmit
    "missing"
    (psCKernelInstantiateExprLevels
      (PsCKernelExpr.constE nameC [v])
      [nameU]
      [zeroLevel])
  psCKernelExprLevelFixtureEmit
    "duplicate"
    (psCKernelInstantiateExprLevels
      (PsCKernelExpr.sortE u)
      [nameU, nameU]
      [zeroLevel, oneLevel])
