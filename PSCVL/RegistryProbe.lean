import PSCVL.Policy

/-!
Reads the *observed* pinned Lean 4.35.0-rc3 environment, NOT the closed
ProofScript Standard environment. `PSCVL.Policy` imports Lean + Std.WP plus
development-only attributes. Source/frozen registry rules from the PSCV
normative reference still apply separately and are NOT implemented here.

Do not promote this output into STD-ENV-PSCV-V1-L435RC3-RC1.json,
a language feature manifest, or a trusted PSCV certificate.
-/

open Lean

namespace PSCVL

private def recordName (name : Name) : Json :=
  Json.str name.toString

private def recordInstance (p : Name × Meta.InstanceEntry) : Json :=
  Json.mkObj [
    ("name", recordName p.1),
    ("priority", toJson p.2.priority)
  ]

private def recordDefault (p : Name × List (Name × Nat)) : Json :=
  Json.mkObj [
    ("class", recordName p.1),
    ("instances", toJson (p.2.map fun (name, prio) =>
      Json.mkObj [("name", recordName name), ("priority", toJson prio)]))
  ]

private def recordSimpOrigin (p : Meta.Origin × Unit) : Json :=
  Json.mkObj [
    ("name", recordName p.1.key)
  ]

private def recordSimproc (p : Name × Array Meta.SimpTheoremKey) : Json :=
  Json.mkObj [
    ("name", recordName p.1),
    ("patternCount", toJson p.2.size)
  ]

/--
The only direct overloaded-surface IDs identified by the normative source
are Bool.not, Bool.and and Bool.or. This probe observes their *actual Lean
declaration identities*, separately records their executable Bool.Internal
counterparts and csimp equality theorems, and never authorizes source lowering
or backend publication on that basis.
-/
private def observeDirectBool (env : Environment)
    (id : String) (logical implementation witness : Name) : Json :=
  let present (n : Name) := (env.find? n).isSome
  let theoremPresent := match env.find? witness with
    | some (.thmInfo _) => true
    | _ => false
  Json.mkObj [
    ("snapshotId", toJson id),
    ("logicalDeclaration", recordName logical),
    ("internalDeclaration", recordName implementation),
    ("equalityTheorem", recordName witness),
    ("logicalPresent", toJson (present logical)),
    ("internalPresent", toJson (present implementation)),
    ("equalityTheoremPresent", toJson theoremPresent),
    ("logicalNoncomputable", toJson (Lean.isNoncomputable env logical)),
    ("internalNoncomputable", toJson (Lean.isNoncomputable env implementation)),
    ("sourceLineProvenanceChecked", toJson false),
    ("runtimeEquivalenceQualified", toJson false),
    ("pscvVerified", toJson false)
  ]

/--
Capture directly observed extension membership from the actual imported
Lean environment, retaining explicitly false conformance/authority flags.
Priority/order and source-line provenance must be independently audited.
-/
def observedRegistryData (env : Environment) : Json := Id.run do
  let instances := (Meta.instanceExtension.getState env).instanceNames.toList
  let defaultClasses := (Meta.defaultInstanceExtension.getState env).defaultInstances.toList
  let simp := Meta.simpExtension.getState env
  let simprocs := Meta.Simp.simprocDeclExt.getState env
  let grind := Meta.Grind.grindExt.getState env
  let body := Json.mkObj [
    ("schemaVersion", toJson (0 : Nat)),
    ("kind", toJson ("psc-lean-ambient-registrations/0" : String)),
    ("environment", toJson ("PSCVL.Policy imported into Lean 4.35.0-rc3" : String)),
    ("selectedLeanVersion", toJson ("4.35.0-rc3" : String)),
    ("instances", toJson (instances.map recordInstance)),
    ("defaultInstances", toJson (defaultClasses.map recordDefault)),
    ("simpOrigins", toJson (simp.lemmaNames.set.toList.map recordSimpOrigin)),
    ("simpToUnfold", toJson (simp.toUnfold.set.toList.map fun (name, _) => recordName name)),
    ("simprocBuiltins", toJson (simprocs.builtin.toList.map recordSimproc)),
    ("simprocLocal", toJson (simprocs.newEntries.toList.map recordSimproc)),
    ("grindExtNames", toJson (grind.extThms.set.toList.map fun (name, _) => recordName name)),
    ("grindCases", toJson (grind.casesTypes.casesMap.toList.map fun (name, eager) =>
      Json.mkObj [("name", recordName name), ("eager", toJson eager)])),
    ("directBool", toJson (#[
      observeDirectBool env "Bool.not" ``Bool.not ``Bool.Internal.not ``Bool.not_eq_internalNot,
      observeDirectBool env "Bool.and" ``Bool.and ``Bool.Internal.and ``Bool.and_eq_internalAnd,
      observeDirectBool env "Bool.or" ``Bool.or ``Bool.Internal.or ``Bool.or_eq_internalOr
    ])),
    ("rawStateOrderPreserved", toJson false),
    ("sourceLineProvenanceResolved", toJson false),
    ("standardRegistryComplete", toJson false),
    ("coercionsEnumerated", toJson false),
    ("extTheoremsEnumerated", toJson false),
    ("grindEmatchComplete", toJson false),
    ("verificationEffectRegistryComplete", toJson false),
    ("pscvVerified", toJson false),
    ("verifiedExecutableAuthorized", toJson false)
  ]
  return body

def runProbe (args : List String) : IO UInt32 := do
  let [out] := args | do
    IO.eprintln "usage: lake env lean --run RegistryProbe.lean <output.json>"
    return 2
  initSearchPath (← findSysroot)
  unsafe enableInitializersExecution
  let env ← importModules #[{module := `PSCVL.Policy}] {} (trustLevel := 0) (loadExts := true)
  let json := observedRegistryData env
  IO.FS.writeFile out (json.compress ++ "\n")
  IO.println "PSC_PSCV_OBSERVED_LEAN_REGISTRIES: captured ambient state, NOT Standard profile"
  return 0

end PSCVL

def main (args : List String) : IO UInt32 := PSCVL.runProbe args
