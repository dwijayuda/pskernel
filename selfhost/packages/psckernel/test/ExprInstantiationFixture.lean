import Ps.PSCKernel.Core.ExprInstantiation

def psCKernelExprInstantiationFixtureBinderInfoKey
    (info : PsCKernelBinderInfo) : String :=
  match info with
  | PsCKernelBinderInfo.default => "d"
  | PsCKernelBinderInfo.implicit => "i"
  | PsCKernelBinderInfo.strictImplicit => "s"
  | PsCKernelBinderInfo.instImplicit => "c"

def psCKernelExprInstantiationFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelLevelToString level
      | _ =>
          psCKernelLevelToString level ++ "," ++
            psCKernelExprInstantiationFixtureLevelListKey rest

def psCKernelExprInstantiationFixtureExprKey (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id => "f{" ++ psCKernelNameKey id.name ++ "}"
  | PsCKernelExpr.mvar id => "v{" ++ psCKernelNameKey id.name ++ "}"
  | PsCKernelExpr.sortE level => "S{" ++ psCKernelLevelToString level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameKey name ++ "}[" ++
        psCKernelExprInstantiationFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelExprInstantiationFixtureExprKey fn ++ "," ++
        psCKernelExprInstantiationFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name domain body binderInfo =>
      "L{" ++ psCKernelNameKey name ++ "," ++
        psCKernelExprInstantiationFixtureBinderInfoKey binderInfo ++ "}(" ++
        psCKernelExprInstantiationFixtureExprKey domain ++ "," ++
        psCKernelExprInstantiationFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name domain body binderInfo =>
      "P{" ++ psCKernelNameKey name ++ "," ++
        psCKernelExprInstantiationFixtureBinderInfoKey binderInfo ++ "}(" ++
        psCKernelExprInstantiationFixtureExprKey domain ++ "," ++
        psCKernelExprInstantiationFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name domain value body nondep =>
      "T{" ++ psCKernelNameKey name ++ "," ++
        (if nondep then "1" else "0") ++ "}(" ++
        psCKernelExprInstantiationFixtureExprKey domain ++ "," ++
        psCKernelExprInstantiationFixtureExprKey value ++ "," ++
        psCKernelExprInstantiationFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameKey typeName ++ "," ++ toString index ++ "}(" ++
        psCKernelExprInstantiationFixtureExprKey value ++ ")"

def psCKernelExprInstantiationFixtureEmit
    (key : String)
    (expr : PsCKernelExpr) : IO Unit :=
  IO.println (key ++ "\t" ++ psCKernelExprInstantiationFixtureExprKey expr)

def psCKernelExprInstantiationFixtureConst (name : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNameFromDotted name) []

def main : IO Unit := do
  let nameX : PsCKernelName := psCKernelNameFromDotted "x"
  let nameP : PsCKernelName := psCKernelNameFromDotted "P"
  let constA : PsCKernelExpr := psCKernelExprInstantiationFixtureConst "A"
  let constB : PsCKernelExpr := psCKernelExprInstantiationFixtureConst "B"
  let constT : PsCKernelExpr := psCKernelExprInstantiationFixtureConst "T"

  psCKernelExprInstantiationFixtureEmit
    "lift-zero"
    (psCKernelExprLiftLooseBVars (PsCKernelExpr.bvar 2) 0 0)

  psCKernelExprInstantiationFixtureEmit
    "lift-cutoff"
    (psCKernelExprLiftLooseBVars
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      1
      2)

  psCKernelExprInstantiationFixtureEmit
    "lift-binder"
    (psCKernelExprLiftLooseBVars
      (PsCKernelExpr.lam
        nameX
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      0
      1)

  psCKernelExprInstantiationFixtureEmit
    "empty"
    (psCKernelExprInstantiate
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 2))
      [])

  psCKernelExprInstantiationFixtureEmit
    "single"
    (psCKernelExprInstantiate1
      (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
      constA)

  psCKernelExprInstantiationFixtureEmit
    "multi"
    (psCKernelExprInstantiate
      (PsCKernelExpr.app
        (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
        (PsCKernelExpr.bvar 2))
      [constA, constB])

  psCKernelExprInstantiationFixtureEmit
    "subst-lift"
    (psCKernelExprInstantiate
      (PsCKernelExpr.lam
        nameX
        constT
        (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.default)
      [PsCKernelExpr.bvar 0])

  psCKernelExprInstantiationFixtureEmit
    "forall-depth"
    (psCKernelExprInstantiate
      (PsCKernelExpr.forallE
        nameX
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
        PsCKernelBinderInfo.implicit)
      [constA])

  psCKernelExprInstantiationFixtureEmit
    "let-depth"
    (psCKernelExprInstantiate
      (PsCKernelExpr.letE
        nameX
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.bvar 0)
        (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1))
        true)
      [constA])

  psCKernelExprInstantiationFixtureEmit
    "projection"
    (psCKernelExprInstantiate1
      (PsCKernelExpr.proj
        nameP
        2
        (PsCKernelExpr.app (PsCKernelExpr.bvar 0) (PsCKernelExpr.bvar 1)))
      constA)
