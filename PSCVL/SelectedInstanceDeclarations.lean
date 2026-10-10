import PSCVL.Policy

/-!
P1-H imports actual Lean4.35.0-rc3 declarations previously observed by
P1-E and P1-F. This source reports declaration types and originating
imported modules, not PSCV Standard registration/instance ordering,
runtime correspondence, or verified executable authority.
-/

open Lean

namespace PSCVL

private def requested : Array Name := #[
  ``instHAdd, ``instHMul, ``instHSub, ``instAppendString,
  ``instBEqOfDecidableEq, ``instAddNat, ``instMulNat,
  ``instSubNat, ``Int.instAdd,
  ``instDecidableEqNat, ``instDecidableEqBool
]

private def moduleFor (env : Environment) (name : Name) : Json :=
  match env.getModuleIdxFor? name with
  | some i =>
    match env.header.moduleNames[i]? with
    | some m => Json.str m.toString
    | none => Json.null
  | none => Json.null

private def record (env : Environment) (name : Name) : Json :=
  match env.find? name with
  | none => Json.mkObj [
      ("name", Json.str name.toString),
      ("present", toJson false),
      ("importedModule", Json.null),
      ("typeExprRepr", Json.null)
    ]
  | some info =>
    Json.mkObj [
      ("name", Json.str name.toString),
      ("present", toJson true),
      ("importedModule", moduleFor env name),
      ("typeExprRepr", toJson (reprStr info.type))
    ]

def runSelectedDeclProbe (args : List String) : IO UInt32 := do
  let [out] := args | do
    IO.eprintln "usage: lake env lean --run SelectedInstanceDeclarations.lean output.json"
    return 2
  initSearchPath (← findSysroot)
  unsafe enableInitializersExecution
  let env ← importModules #[{module := `PSCVL.Policy}] {} (trustLevel := 0) (loadExts := true)
  let data := Json.mkObj [
    ("kind", toJson ("psc-lean-selected-declaration-types/0" : String)),
    ("leanVersion", toJson ("4.35.0-rc3" : String)),
    ("declarations", toJson (requested.map (record env))),
    ("importedModuleIsSourceLineProof", toJson false),
    ("closedStandardMapped", toJson false),
    ("verifiedExecutableAuthorized", toJson false)
  ]
  IO.FS.writeFile out (data.compress ++ "\n")
  IO.println "PSC_P1H_DECLARATION_TYPES: observed imported Lean, not Standard"
  return 0

end PSCVL

def main (args : List String) : IO UInt32 := PSCVL.runSelectedDeclProbe args
