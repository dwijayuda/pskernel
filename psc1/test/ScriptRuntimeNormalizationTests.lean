import ScriptRuntimeReference

def selections : List String -> List (List String)
  | [] => [[]]
  | name :: rest =>
      let tail := selections rest
      tail ++ tail.map (name :: ·)

def main : IO Unit := do
  let pythonNames := ["builtins","calls","int-repr","char-of-nat","string-get","string-next","string-extract","array-get","array-get-d","array-set","array-set-if","array-map","array-foldl"]
  let phpNames := ["gmp","calls","utf8Valid","unicodeChars","charOfNat","charToNat","stringGet","stringNext","stringExtract"]
  for name in pythonNames ++ ["unknown", "", "λ🙂"] do
    unless psPythonRuntimeBody name == PsScriptRuntimeReference.Python.psPythonRuntimeBody name do
      throw (IO.userError ("Python runtime bytes: " ++ name))
    unless psPythonRuntimeDependencies name == PsScriptRuntimeReference.Python.psPythonRuntimeDependencies name do
      throw (IO.userError ("Python runtime dependencies: " ++ name))
  for name in phpNames ++ ["unknown", "", "λ🙂"] do
    unless psPhpRuntimePart name == PsScriptRuntimeReference.Php.psPhpRuntimePart name do
      throw (IO.userError ("PHP runtime bytes: " ++ name))
  let mut cases := 0
  for selected in selections pythonNames do
    for requested in [selected, selected.reverse, selected ++ selected, "unknown" :: selected] do
      unless psPythonRuntimeClosure requested == PsScriptRuntimeReference.Python.psPythonRuntimeClosure requested do
        throw (IO.userError "Python runtime selection order")
      unless psPythonRuntimeSource requested == PsScriptRuntimeReference.Python.psPythonRuntimeSource requested do
        throw (IO.userError "Python runtime concatenation bytes")
      cases := cases + 1
  for selected in selections phpNames do
    for requested in [selected, selected.reverse, selected ++ selected, "unknown" :: selected] do
      unless psPhpRuntimeClosure requested == PsScriptRuntimeReference.Php.psPhpRuntimeClosure requested do
        throw (IO.userError "PHP runtime selection order")
      unless psPhpRuntimeVariables requested == PsScriptRuntimeReference.Php.psPhpRuntimeVariables requested do
        throw (IO.userError "PHP runtime variables")
      unless psPhpSelectedRuntimeSource requested == PsScriptRuntimeReference.Php.psPhpSelectedRuntimeSource requested do
        throw (IO.userError "PHP runtime concatenation bytes")
      cases := cases + 1
  IO.println s!"PSC1_SCRIPT_RUNTIME_NORMALIZATION: {cases} catalog subset/order/duplicate/unknown selections and exact retained runtime byte comparisons passed"
