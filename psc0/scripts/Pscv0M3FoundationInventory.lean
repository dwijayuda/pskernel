import Ps.Environment.SelfHostProd

def main : IO Unit := do
  let before := psSelfHostProdPreClassicalPreludeEnvironment
  let after := psSelfHostProdPreludeEnvironment
  for declaration in psStandardClassicalExpectedDeclarations do
    let name := psDeclarationName declaration
    IO.println ("PSCV0_M3_FOUNDATION_INVENTORY " ++ psNameToString name ++
      " before=" ++ toString (psEnvironmentFind before name).isSome ++
      " after=" ++ toString (psEnvironmentFind after name).isSome)
  for text in ["PSum", "PSum.inl", "PSum.inr", "PSum.rec", "PSum.casesOn",
      "PSigma", "PSigma.mk", "PSigma.casesOn"] do
    IO.println ("PSCV0_M3_PACKING_INVENTORY " ++ text ++
      " selected=" ++ toString (psEnvironmentFind after (psDecisionName text)).isSome)
  let className := psRootName "Nonempty"
  IO.println ("PSCV0_M3_NONEMPTY_CLASS before=" ++
    toString (before.classes.filter (psNameEq className)).length ++ " after=" ++
    toString (after.classes.filter (psNameEq className)).length)
  match psStandardClassicalAudit after with
  | .ok _ => IO.println "PSCV0_M3_CLASSICAL_ASSET: PASS exact selected declaration audit"
  | .error error => throw (IO.userError error)
