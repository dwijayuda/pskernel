import Ps.PSCKernel.Core.ExprAbstraction

def psCKernelExprAbstractionFixtureBinderInfoKey
    (info : PsCKernelBinderInfo) : String :=
  match info with
  | PsCKernelBinderInfo.default => "d"
  | PsCKernelBinderInfo.implicit => "i"
  | PsCKernelBinderInfo.strictImplicit => "s"
  | PsCKernelBinderInfo.instImplicit => "c"

def psCKernelExprAbstractionFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ =>
          psCKernelLevelToString level ++ "," ++
            psCKernelExprAbstractionFixtureLevelListKey rest

def psCKernelExprAbstractionFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameKey name ++ "}[" ++
        psCKernelExprAbstractionFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelExprAbstractionFixtureExprKey fn ++ "," ++
        psCKernelExprAbstractionFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name domain body binderInfo =>
      "L{" ++ psCKernelNameKey name ++ "," ++
        psCKernelExprAbstractionFixtureBinderInfoKey binderInfo ++ "}(" ++
        psCKernelExprAbstractionFixtureExprKey domain ++ "," ++
        psCKernelExprAbstractionFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name domain body binderInfo =>
      "P{" ++ psCKernelNameKey name ++ "," ++
        psCKernelExprAbstractionFixtureBinderInfoKey binderInfo ++ "}(" ++
        psCKernelExprAbstractionFixtureExprKey domain ++ "," ++
        psCKernelExprAbstractionFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name domain value body nondep =>
      "T{" ++ psCKernelNameKey name ++ "," ++
        (if nondep then "1" else "0") ++ "}(" ++
        psCKernelExprAbstractionFixtureExprKey domain ++ "," ++
        psCKernelExprAbstractionFixtureExprKey value ++ "," ++
        psCKernelExprAbstractionFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameKey typeName ++ "," ++ toString index ++ "}(" ++
        psCKernelExprAbstractionFixtureExprKey value ++ ")"

def psCKernelExprAbstractionFixtureEmit
    (key : String)
    (expr : PsCKernelExpr) : IO Unit :=
  IO.println (key ++ "\t" ++ psCKernelExprAbstractionFixtureExprKey expr)

def psCKernelExprAbstractionFixtureConst (name : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNameFromDotted name) []

def main : IO Unit := do
  let nameX : PsCKernelName := psCKernelNameFromDotted "x"
  let nameY : PsCKernelName := psCKernelNameFromDotted "y"
  let nameP : PsCKernelName := psCKernelNameFromDotted "P"
  let target : PsCKernelFVarId := { name := nameX }
  let other : PsCKernelFVarId := { name := nameY }
  let targetExpr : PsCKernelExpr := PsCKernelExpr.fvar target
  let otherExpr : PsCKernelExpr := PsCKernelExpr.fvar other
  let constT : PsCKernelExpr := psCKernelExprAbstractionFixtureConst "T"

  psCKernelExprAbstractionFixtureEmit
    "non-target"
    (psCKernelExprAbstractFVar otherExpr target)

  psCKernelExprAbstractionFixtureEmit
    "target-root"
    (psCKernelExprAbstractFVar targetExpr target)

  psCKernelExprAbstractionFixtureEmit
    "loose-shift"
    (psCKernelExprAbstractFVar (PsCKernelExpr.bvar 0) target)

  psCKernelExprAbstractionFixtureEmit
    "application"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.app targetExpr (PsCKernelExpr.bvar 0))
      target)

  psCKernelExprAbstractionFixtureEmit
    "lambda-depth"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.lam
        nameY
        constT
        (PsCKernelExpr.app targetExpr (PsCKernelExpr.bvar 0))
        PsCKernelBinderInfo.default)
      target)

  psCKernelExprAbstractionFixtureEmit
    "forall-depth"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.forallE
        nameY
        targetExpr
        targetExpr
        PsCKernelBinderInfo.implicit)
      target)

  psCKernelExprAbstractionFixtureEmit
    "loose-under-binder"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.lam
        nameY
        constT
        (PsCKernelExpr.bvar 1)
        PsCKernelBinderInfo.default)
      target)

  psCKernelExprAbstractionFixtureEmit
    "let-depth"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.letE
        nameY
        targetExpr
        targetExpr
        (PsCKernelExpr.app targetExpr (PsCKernelExpr.bvar 0))
        true)
      target)

  psCKernelExprAbstractionFixtureEmit
    "projection"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.proj nameP 3 targetExpr)
      target)

  psCKernelExprAbstractionFixtureEmit
    "nested-non-target"
    (psCKernelExprAbstractFVar
      (PsCKernelExpr.app otherExpr targetExpr)
      target)
