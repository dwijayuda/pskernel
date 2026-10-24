import PythonUtf8Reference
import Lean.Data.Json

def selections : List String -> List (List String)
  | [] => [[]]
  | name :: rest =>
      let tail := selections rest
      tail ++ tail.map (name :: ·)

def main (args : List String) : IO Unit := do
  let pythonNames := ["builtins","calls","int-repr","char-of-nat","string-get","string-next","string-extract","array-get","array-get-d","array-set","array-set-if","array-map","array-foldl"]
  let phpNames := ["gmp","calls","utf8Valid","unicodeChars","charOfNat","charToNat","stringGet","stringNext","stringExtract"]
  for name in pythonNames ++ ["unknown", "", "λ🙂"] do
    unless psPythonUtf8ReferenceNeutral (psPythonRuntimeBody name) == PsScriptRuntimeReference.Python.psPythonRuntimeBody name do
      throw (IO.userError ("Python runtime bytes: " ++ name))
    unless psPythonRuntimeDependencies name == PsScriptRuntimeReference.Python.psPythonRuntimeDependencies name do
      throw (IO.userError ("Python runtime dependencies: " ++ name))
  for name in phpNames ++ ["unknown", "", "λ🙂"] do
    unless psPhpRuntimePart name == PsScriptRuntimeReference.Php.psPhpRuntimePart name do
      throw (IO.userError ("PHP runtime bytes: " ++ name))
  unless psPhpRuntimeClosure ["nodes", "nodes", "unknown"] == ["nodes"] &&
      psPhpRuntimeVariables ["nodes"] == ["$__ps_nodes"] do
    throw (IO.userError "PHP node helper closure/inventory")
  let mut cases := 0
  for selected in selections pythonNames do
    for requested in [selected, selected.reverse, selected ++ selected, "unknown" :: selected] do
      unless psPythonRuntimeClosure requested == PsScriptRuntimeReference.Python.psPythonRuntimeClosure requested do
        throw (IO.userError "Python runtime selection order")
      unless psPythonUtf8ReferenceNeutral (psPythonRuntimeSource requested) == PsScriptRuntimeReference.Python.psPythonRuntimeSource requested do
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

  if let some output := args.head? then
    let names := pythonNames ++ phpNames ++ ["nodes", "unknown", "", "λ🙂", "stringGet"]
    let records := names.map fun name =>
      Lean.Json.arr #[
        Lean.toJson name,
        Lean.toJson (psPythonRuntimeBody name),
        Lean.toJson (String.intercalate "|" (PsScriptRuntimeReference.Python.psPythonRuntimeClosure [name, name, "unknown"])),
        Lean.toJson (if name == "nodes" then psPhpRuntimePart name else PsScriptRuntimeReference.Php.psPhpRuntimePart name),
        Lean.toJson (String.intercalate "|" (PsScriptRuntimeReference.Php.psPhpRuntimeClosure [name, name, "unknown"]))]
    IO.FS.writeFile output ((Lean.Json.arr records.toArray).compress ++ "\n")
  IO.println s!"PSC1_SCRIPT_RUNTIME_NORMALIZATION: {cases} catalog subset/order/duplicate/unknown selections and retained runtime bytes outside explicit Python UTF8 cache substitutions passed"
