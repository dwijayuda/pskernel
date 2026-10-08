import Ps.TheoryBridge.Model
import Ps.TheoryBridge.Translate

def psTheoryBridgeIdentityTest : Bool :=
  let bridge := psTheoryBridgeIdentity "psc-declarative-core-seed/1";
  psTheoryBridgeWellFormed bridge

def psTheoryBridgeRejectsEmptySource : Bool :=
  let bridge :=
    psTheoryBridgeV1
      ""
      "destination"
      List.nil
      List.nil
      List.nil
      "claim"
      List.nil;
  if psTheoryBridgeWellFormed bridge then
    false
  else
    true

def bridgeName (value : String) : PsName := PsName.str PsName.anonymous value

def bridgeDeclarations (proposition theoremName : String) : List PsDeclaration :=
  let prop := PsExpr.constE (bridgeName proposition) [];
  let name := bridgeName "proof";
  [PsDeclaration.axiomDecl (bridgeName proposition) [] (PsExpr.sortE PsLevel.zero),
   PsDeclaration.theoremDecl (bridgeName theoremName) []
     (PsExpr.forallE name prop prop PsBinderInfo.explicit)
     (PsExpr.lam name prop (PsExpr.bvar 0) PsBinderInfo.explicit)]

def bridgeSource : PsTheoryCoreView :=
  PsTheoryCoreView.mk "source" "fixture-core/1" (bridgeDeclarations "P" "idP")

def bridgeDestination : PsTheoryCoreView :=
  PsTheoryCoreView.mk "destination" "fixture-core/1" (bridgeDeclarations "Q" "idQ")

def bridgePlan : PsTheoryTranslationPlan :=
  PsTheoryTranslationPlan.mk "psc-core-renaming/1" "source" "destination"
    [PsTheoryCoreSymbolMap.mk (bridgeName "P") (bridgeName "Q"),
     PsTheoryCoreSymbolMap.mk (bridgeName "idP") (bridgeName "idQ")]
    [PsTheoryCoreSymbolMap.mk (bridgeName "P") (bridgeName "Q")]
    [bridgeName "P"] [bridgeName "Q"] []

def bridgeAccepted (plan : PsTheoryTranslationPlan) (source destination : PsTheoryCoreView) : Bool :=
  match psTheoryCheckTranslation plan source destination with
  | Except.error _ => false
  | Except.ok result => psStringEq result.preservation "global-preservation-unproved"

def bridgeExprRejected (expression : PsExpr) : Bool :=
  match psTheoryTranslateExpr expression bridgePlan.symbols [] 0 with
  | Except.error _ => true
  | Except.ok _ => false

def main : IO Unit := do
  let cases : List (String × Bool) := [
    ("legacy identity descriptor", psTheoryBridgeIdentityTest),
    ("legacy empty source", psTheoryBridgeRejectsEmptySource),
    ("actual closed declaration renaming", bridgeAccepted bridgePlan bridgeSource bridgeDestination),
    ("missing symbol mapping", !bridgeAccepted { bridgePlan with symbols := [] } bridgeSource bridgeDestination),
    ("duplicate source mapping", !bridgeAccepted { bridgePlan with symbols := bridgePlan.symbols ++ bridgePlan.symbols } bridgeSource bridgeDestination),
    ("missing axiom map", !bridgeAccepted { bridgePlan with axioms := [] } bridgeSource bridgeDestination),
    ("source assumption denied", !bridgeAccepted { bridgePlan with allowedSourceAxioms := [] } bridgeSource bridgeDestination),
    ("destination assumption denied", !bridgeAccepted { bridgePlan with allowedDestinationAxioms := [] } bridgeSource bridgeDestination),
    ("changed semantic profile", !bridgeAccepted bridgePlan bridgeSource { bridgeDestination with semanticProfile := "another" }),
    ("declared unsupported feature", !bridgeAccepted { bridgePlan with unsupportedFeatures := ["quotient-translation"] } bridgeSource bridgeDestination),
    ("destination theorem drift", !bridgeAccepted bridgePlan bridgeSource { bridgeDestination with declarations := [
      PsDeclaration.axiomDecl (bridgeName "Q") [] (PsExpr.sortE PsLevel.zero),
      PsDeclaration.theoremDecl (bridgeName "idQ") [] (PsExpr.sortE PsLevel.zero) (PsExpr.sortE PsLevel.zero)] }),
    ("extra destination assumption", !bridgeAccepted bridgePlan bridgeSource { bridgeDestination with declarations := bridgeDestination.declarations ++ [PsDeclaration.axiomDecl (bridgeName "extra") [] (PsExpr.sortE PsLevel.zero)] }),
    ("unknown constant", bridgeExprRejected (PsExpr.constE (bridgeName "outside") [])),
    ("free local", bridgeExprRejected (PsExpr.fvar 0)),
    ("metavariable", bridgeExprRejected (PsExpr.mvar 0)),
    ("loose bound variable", bridgeExprRejected (PsExpr.bvar 0)),
    ("unknown universe", bridgeExprRejected (PsExpr.sortE (PsLevel.param (bridgeName "u")))),
    ("universe metavariable", bridgeExprRejected (PsExpr.sortE (PsLevel.mvar 0))),
    ("projection unsupported", bridgeExprRejected (PsExpr.proj (bridgeName "P") 0 (PsExpr.bvar 0)))
  ]
  for entry in cases do
    if !entry.2 then throw (IO.userError ("PSCV_THEORY_BRIDGE_TESTS: FAIL " ++ entry.1))
  IO.println ("PSCV_THEORY_BRIDGE_TESTS: PASS (" ++ toString cases.length ++ " cases)")
