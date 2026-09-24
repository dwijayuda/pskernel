import Lean.Compiler.ExternAttr
import Lean.Compiler.ImplementedByAttr
import Lean.Compiler.InitAttr
import Lean.Compiler.Old
import Lean.Environment

open Lean

def externEntryJson : ExternEntry → Json
  | .adhoc backend =>
    Json.mkObj [
      ("kind", "adhoc"),
      ("backend", backend.toString)
    ]
  | .inline backend pattern =>
    Json.mkObj [
      ("kind", "inline"),
      ("backend", backend.toString),
      ("pattern", pattern)
    ]
  | .standard backend fn =>
    Json.mkObj [
      ("kind", "standard"),
      ("backend", backend.toString),
      ("symbol", fn)
    ]
  | .opaque =>
    Json.mkObj [
      ("kind", "opaque")
    ]

def externDataJson (data : ExternAttrData) : Json :=
  Json.arr <| data.entries.toArray.map externEntryJson

def optNameJson : Option Name → Json
  | none => Json.null
  | some name => name.toString

def moduleNameForIdx (env : Environment) (idx : Nat) : String :=
  match env.header.moduleNames[idx]? with
  | some name => name.toString
  | none => ""

def dumpDeclarationRuntimeMetadata
    (env : Environment) : IO (Array Json × Array Json × Array Json) := do
  let mut externs := #[]
  let mut implementedBy := #[]
  let mut runtimeTargets := #[]
  for (name, _) in env.constants.map₁.toList do
    if let some data := getExternAttrData? env name then
      let moduleIdx? := env.getModuleIdxFor? name
      externs := externs.push <| Json.mkObj [
        ("declaration", name.toString),
        ("module", moduleIdx?.map (moduleNameForIdx env) |>.getD ""),
        ("moduleIndex", moduleIdx?.map (fun idx => toJson idx.toNat) |>.getD Json.null),
        ("entries", externDataJson data)
      ]
    let moduleIdx? := env.getModuleIdxFor? name
    if let some impl := Compiler.getImplementedBy? env name then
      implementedBy := implementedBy.push <| Json.mkObj [
        ("declaration", name.toString),
        ("module", moduleIdx?.map (moduleNameForIdx env) |>.getD ""),
        ("moduleIndex", moduleIdx?.map (fun idx => toJson idx.toNat) |>.getD Json.null),
        ("implementation", impl.toString)
      ]
      runtimeTargets := runtimeTargets.push <| Json.mkObj [
        ("declaration", name.toString),
        ("module", moduleIdx?.map (moduleNameForIdx env) |>.getD ""),
        ("moduleIndex", moduleIdx?.map (fun idx => toJson idx.toNat) |>.getD Json.null),
        ("kind", "implemented_by"),
        ("implementation", impl.toString)
      ]
    else
      let unsafeRec := Compiler.mkUnsafeRecName name
      if env.find? unsafeRec |>.isSome then
        runtimeTargets := runtimeTargets.push <| Json.mkObj [
          ("declaration", name.toString),
          ("module", moduleIdx?.map (moduleNameForIdx env) |>.getD ""),
          ("moduleIndex", moduleIdx?.map (fun idx => toJson idx.toNat) |>.getD Json.null),
          ("kind", "unsafe_rec"),
          ("implementation", unsafeRec.toString)
        ]
  return (externs, implementedBy, runtimeTargets)

def appendInitEntries
    (env : Environment)
    (moduleIdx : Nat)
    (kind source : String)
    (entries : Array (Name × Name))
    (out : Array Json) : Array Json :=
  entries.foldl (init := out) fun out (decl, initFn) =>
    out.push <| Json.mkObj [
      ("module", moduleNameForIdx env moduleIdx),
      ("moduleIndex", moduleIdx),
      ("kind", kind),
      ("source", source),
      ("declaration", decl.toString),
      ("initFunction", if initFn.isAnonymous then Json.null else initFn.toString),
      ("ioUnit", initFn.isAnonymous)
    ]

def dumpInitializerMetadata (env : Environment) : IO (Array Json) := do
  let mut initializers := #[]
  for moduleIdx in [0:env.header.moduleNames.size] do
    let builtinEntries := builtinInitAttr.ext.getModuleEntries env moduleIdx
    initializers :=
      appendInitEntries env moduleIdx "builtin" "olean" builtinEntries initializers
    let regularEntries := regularInitAttr.ext.getModuleEntries env moduleIdx
    initializers :=
      appendInitEntries env moduleIdx "regular" "olean" regularEntries initializers
    let regularIREntries := regularInitAttr.ext.getModuleIREntries env moduleIdx
    initializers :=
      appendInitEntries env moduleIdx "regular" "ir" regularIREntries initializers
  return initializers

unsafe def main (args : List String) : IO Unit := do
  initSearchPath (← findSysroot)
  if args.isEmpty then
    throw <| IO.userError "usage: RuntimeMetadataExport <module>"
  let moduleName := args.head!.toName
  withImportModules #[{module := moduleName}] {} fun env => do
    let (externs, implementedBy, runtimeTargets) ←
      dumpDeclarationRuntimeMetadata env
    let initializers ← dumpInitializerMetadata env
    let result := Json.mkObj [
      ("format", "proofscript-lean434-runtime-metadata"),
      ("formatVersion", 1),
      ("lean", Json.mkObj [
        ("version", versionString),
        ("githash", githash)
      ]),
      ("module", moduleName.toString),
      ("externs", Json.arr externs),
      ("implementedBy", Json.arr implementedBy),
      ("runtimeTargets", Json.arr runtimeTargets),
      ("initializers", Json.arr initializers)
    ]
    IO.println result.compress
