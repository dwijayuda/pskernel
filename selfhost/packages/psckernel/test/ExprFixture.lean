import Ps.PSCKernel.Core.Expr

def psCKernelExprFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelExprFixtureEmit (key : String) (value : Bool) : IO Unit :=
  IO.println (key ++ "\t" ++ psCKernelExprFixtureBoolText value)

def main : IO Unit := do
  let nameA : PsCKernelName := psCKernelNameFromDotted "A"
  let nameF : PsCKernelName := psCKernelNameFromDotted "f"
  let nameX : PsCKernelName := psCKernelNameFromDotted "x"
  let nameY : PsCKernelName := psCKernelNameFromDotted "y"
  let typeA : PsCKernelExpr := PsCKernelExpr.constE nameA []
  let fn : PsCKernelExpr := PsCKernelExpr.constE nameF []
  let arg1 : PsCKernelExpr := PsCKernelExpr.bvar 0
  let arg2 : PsCKernelExpr := PsCKernelExpr.bvar 1
  let application : PsCKernelExpr := psCKernelExprMkAppN fn [arg1, arg2]
  let lambdaLeft : PsCKernelExpr :=
    PsCKernelExpr.lam nameX typeA (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.default
  let lambdaRight : PsCKernelExpr :=
    PsCKernelExpr.lam nameY typeA (PsCKernelExpr.bvar 0) PsCKernelBinderInfo.implicit
  let letLeft : PsCKernelExpr :=
    PsCKernelExpr.letE nameX typeA arg1 (PsCKernelExpr.bvar 0) true
  let letRight : PsCKernelExpr :=
    PsCKernelExpr.letE nameY typeA arg1 (PsCKernelExpr.bvar 0) false
  let projectionLeft : PsCKernelExpr := PsCKernelExpr.proj nameA 0 arg1
  let projectionRight : PsCKernelExpr := PsCKernelExpr.proj nameA 1 arg1
  let fvarExpr : PsCKernelExpr := PsCKernelExpr.fvar { name := nameX }
  let exprMVar : PsCKernelExpr := PsCKernelExpr.mvar { name := nameY }
  let levelMVarExpr : PsCKernelExpr :=
    PsCKernelExpr.sortE (psCKernelLevelMVar nameX)

  psCKernelExprFixtureEmit
    "literal.same"
    (psCKernelLiteralEq (PsCKernelLiteral.natVal 7) (PsCKernelLiteral.natVal 7))
  psCKernelExprFixtureEmit
    "literal.kindDifferent"
    (psCKernelLiteralEq (PsCKernelLiteral.natVal 7) (PsCKernelLiteral.strVal "7"))
  psCKernelExprFixtureEmit
    "eqv.binderPresentation"
    (psCKernelExprEqv lambdaLeft lambdaRight)
  psCKernelExprFixtureEmit
    "eqv.letNondep"
    (psCKernelExprEqv letLeft letRight)
  psCKernelExprFixtureEmit
    "eqv.projectionIndex"
    (psCKernelExprEqv projectionLeft projectionRight)
  psCKernelExprFixtureEmit
    "app.fn"
    (psCKernelExprEqStructural (psCKernelExprGetAppFn application) fn)
  psCKernelExprFixtureEmit
    "app.args"
    (psCKernelExprListEqStructural (psCKernelExprGetAppArgs application) [arg1, arg2])
  psCKernelExprFixtureEmit
    "flags.fvar"
    (psCKernelExprHasFVar (PsCKernelExpr.app fn fvarExpr))
  psCKernelExprFixtureEmit
    "flags.exprMVar"
    (psCKernelExprHasMVar (PsCKernelExpr.app fn exprMVar))
  psCKernelExprFixtureEmit
    "flags.levelMVar"
    (psCKernelExprHasMVar levelMVarExpr)
