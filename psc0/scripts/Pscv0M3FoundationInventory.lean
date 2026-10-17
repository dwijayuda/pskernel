import Ps.Environment.SelfHostProd

def main : IO Unit := do
  let before := psSelfHostProdPreClassicalPreludeEnvironment
  let after := psSelfHostProdPreludeEnvironment
  for declaration in psStandardClassicalDeclarations do
    let name := psDeclarationName declaration
    IO.println ("PSCV0_M3_FOUNDATION_INVENTORY " ++ psNameToString name ++
      " before=" ++ toString (psEnvironmentFind before name).isSome ++
      " after=" ++ toString (psEnvironmentFind after name).isSome)
  let className := psRootName "Nonempty"
  IO.println ("PSCV0_M3_NONEMPTY_CLASS before=" ++
    toString (before.classes.filter (psNameEq className)).length ++ " after=" ++
    toString (after.classes.filter (psNameEq className)).length)
  match psStandardClassicalAudit after with
  | .ok _ => IO.println "PSCV0_M3_CLASSICAL_ASSET: PASS exact selected declaration audit"
  | .error error => throw (IO.userError error)
