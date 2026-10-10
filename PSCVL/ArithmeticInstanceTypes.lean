import PSCVL.Policy

/-!
P1-K: actual imported Lean constant type/module observation for ALL distinct
selected terms in the source-derived P1-J 84-query batch. The input name
list comes from the protected diagnostic producer, not npm plugins.
This is NOT a frozen PSCV Standard, proof/certificate, or runtime mapping.
-/

open Lean
namespace PSCVL

private def parseName (s : String) : Name :=
  (s.splitOn ".").foldl (fun n chunk => Name.str n chunk) Name.anonymous

private def moduleOf (env : Environment) (n : Name) : Json :=
  match env.getModuleIdxFor? n with
  | some idx =>
    match env.header.moduleNames[idx]? with
    | some mod => Json.str mod.toString
    | none => Json.null
  | none => Json.null

private def observe (env : Environment) (raw : String) : Json :=
  let n := parseName raw
  match env.find? n with
  | none =>
    Json.mkObj [
      ("name", toJson raw),("present",toJson false),
      ("importedModule",Json.null),("typeExprRepr",Json.null)
    ]
  | some info =>
    Json.mkObj [
      ("name", toJson raw),("present",toJson true),
      ("importedModule",moduleOf env n),
      ("typeExprRepr",toJson (reprStr info.type))
    ]

def runBatch (args : List String) : IO UInt32 := do
  let [inputFile, outputFile] := args | do
    IO.eprintln "usage: lake env lean --run ArithmeticInstanceTypes.lean names.json output.json"
    return 2
  let source ← IO.FS.readFile inputFile
  let json ← match Json.parse source with
    | .ok j => pure j
    | .error msg => throw <| IO.userError s!"invalid names JSON: {msg}"
  let names : Array String ← match fromJson? json with
    | .ok a => pure a
    | .error msg => throw <| IO.userError s!"invalid selected names: {msg}"
  if names.size < 3 || names.size > 90 then
    throw <| IO.userError "unexpected selected constant count"
  initSearchPath (← findSysroot)
  unsafe enableInitializersExecution
  let env ← importModules #[{module := `PSCVL.Policy}] {} (trustLevel := 0) (loadExts := true)
  let data := Json.mkObj [
    ("protocol",toJson ("psc-arithmetic-constant-types/0" : String)),
    ("leanVersion",toJson ("4.35.0-rc3" : String)),
    ("declarations",toJson (names.map (observe env))),
    ("closedStandardQualified",toJson false),
    ("sourceLineProvenanceQualified",toJson false),
    ("verifiedExecutableAuthorized",toJson false)
  ]
  IO.FS.writeFile outputFile (data.compress ++ "\n")
  IO.println "PSC_P1K_SELECTED_DECL_TYPES: actual imported Lean only, NOT approved Standard"
  return 0

end PSCVL

def main (args : List String) : IO UInt32 :=
  PSCVL.runBatch args
