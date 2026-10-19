import Ps.Host.StandardClosure

def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError "usage: pscv0_core_native_closure OUTPUT.json")
  let measured ← PsV7Native.collectCoreNativeClosure
  IO.FS.writeFile (System.FilePath.mk output)
    (measured.report.compress ++ "\n")
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-core-native-closure-summary/1" : String)),
    ("sourceModules", Lean.toJson measured.sourceModules.size),
    ("sourceDeclarations", Lean.toJson measured.sourceDeclarations),
    ("externalRoots", Lean.toJson measured.roots.length),
    ("closureDeclarations", Lean.toJson measured.entries.size),
    ("axioms", Lean.toJson ((measured.entries.filter Lean.ConstantInfo.isAxiom).map
      (fun info => toString info.name))),
    ("unsafe", Lean.toJson ((measured.entries.filter Lean.ConstantInfo.isUnsafe).map
      (fun info => toString info.name))),
    ("partial", Lean.toJson ((measured.entries.filter Lean.ConstantInfo.isPartial).map
      (fun info => toString info.name)))]).compress
