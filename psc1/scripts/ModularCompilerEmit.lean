import Ps.Host.ModularPilot
import Ps.Host.PortableIr
import Std.Data.HashMap
import Std.Data.HashSet

/-! Full compiler generation is a native build operation, not another frontend.
The exact captured compiler Core is checked independently by the host. This
emitter decodes/rechecks the exact transformed IR, keeps the existing reference
fuel/initializer/refusal rules, and uses the existing JS/TS structured printers.
The smaller v1/v2/v3 pilot profiles and their bounds remain unchanged. -/

namespace Ps.Host.ModularCompiler
open Ps.Host.ModularPilot

def ensure (condition : Bool) (code : String) : Except String Unit :=
  if condition then .ok () else .error code

def plan (raw : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (specifiers : Array String) : Except String (PsModulePlan × List Nat) := do
  let _ ← (psStrictValidateModule raw).mapError (fun _ => "PSC1_FULL_MODULE_STRICT_IR")
  ensure (raw.imports.isEmpty && raw.declarations.length ≤ 8192 &&
    raw.structures.length + raw.inductives.length ≤ 2048) "PSC1_FULL_MODULE_IR_BOUND"
  ensure (specifiers.size ≥ 2 && specifiers.size ≤ 257) "PSC1_FULL_MODULE_SOURCE_BOUND"
  for specifier in specifiers do
    let valid := match specifier.splitOn "/" with
      | ["@proofscript", package, "generated", name] =>
        !package.isEmpty && !name.isEmpty && !name.startsWith "." &&
        package.toList.all (fun c => c.isAlphanum || c == '-') &&
        name.toList.all (fun c => c.isAlphanum || c == '.' || c == '_' || c == '-')
      | _ => false
    ensure valid "PSC1_FULL_MODULE_SPECIFIER"
  ensure (specifiers.toList.eraseDups.length == specifiers.size) "PSC1_FULL_MODULE_SPECIFIER_UNIQUE"
  ensure (owners.length == raw.declarations.length) "PSC1_FULL_MODULE_OWNER_COVERAGE"
  let mut index : Std.HashMap String Nat := {}
  for owner in owners do
    ensure (owner.unit < specifiers.size && !index.contains owner.name) "PSC1_FULL_MODULE_OWNER_UNIQUE"
    index := index.insert owner.name owner.unit
  let mut buckets : Array (List PsVerifiedIrDeclaration) := Array.replicate specifiers.size []
  let mut references : Array (List PsModuleOwner) := Array.replicate specifiers.size []
  for declaration in raw.declarations do
    Ps.Internal.ModuleGraph.safeName declaration.name
    let some unit := index.get? declaration.name | throw "PSC1_FULL_MODULE_OWNER_MISSING"
    ensure declaration.typeParameters.isEmpty "PSC1_MODULE_GENERIC_VALUE_UNQUALIFIED"
    for parameter in declaration.parameters do Ps.Internal.ModuleGraph.safeName parameter.name
    if declaration.parameters.isEmpty &&
        !Ps.Internal.ModuleGraph.staticInitializer 4096 declaration.body then
      throw ("PSC1_MODULE_EAGER_INITIALIZER:" ++ declaration.name)
    buckets := buckets.set! unit (declaration :: buckets[unit]!)
    let refs ← Ps.Internal.ModuleGraph.references 4096
      (declaration.parameters.map (fun p => p.name)) declaration.body
    for name in refs do
      let some assigned := index.get? name | throw ("PSC1_FULL_MODULE_UNKNOWN_REFERENCE:" ++ name)
      if assigned != unit then
        references := references.set! unit ({ name, unit := assigned } :: references[unit]!)
  ensure (references[0]!.isEmpty) "PSC1_PARTITION_RUNTIME_DEPENDENCY"
  let active := (List.range specifiers.size).tail.filter (fun i => !buckets[i]!.isEmpty)
  let mut pending := active
  let mut ordered := [0]
  let mut mapped : Array Nat := Array.replicate specifiers.size 0
  for _ in [:specifiers.size] do
    if !pending.isEmpty then
      let ready := pending.find? fun source =>
        references[source]!.all (fun dependency =>
          dependency.unit == 0 || buckets[dependency.unit]!.isEmpty || ordered.contains dependency.unit)
      let some source := ready | throw "PSC1_FULL_MODULE_CROSS_SOURCE_CYCLE"
      mapped := mapped.set! source ordered.length
      ordered := ordered ++ [source]
      pending := pending.filter (fun item => item != source)
  ensure pending.isEmpty "PSC1_FULL_MODULE_ORDER_BOUND"
  let remapped := owners.map fun owner => { owner with unit := mapped[owner.unit]! }
  let units ← ordered.zipIdx.mapM fun (source, unit) => do
    let mut seen : Std.HashSet String := {}
    let mut imports : List PsModuleOwner := []
    for ref in references[source]!.reverse do
      let assigned := mapped[ref.unit]!
      ensure (assigned < unit) "PSC1_MODULE_CYCLE_OR_ORDER"
      if !seen.contains ref.name then
        seen := seen.insert ref.name
        imports := { ref with unit := assigned } :: imports
    return PsModuleUnit.mk unit buckets[source]!.reverse imports.reverse
  return (PsModulePlan.mk raw remapped units (ordered.map (fun source => specifiers[source]!)) "psc1-modular-compiler/1", mapped.toList)

def boundedRead (file : String) : IO Lean.Json := do
  let text ← IO.FS.readFile file
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_FULL_MODULE_INPUT_BOUND")
  liftResult (Lean.Json.parse text)

def boundedWrite (file text : String) : IO Unit := do
  if text.utf8ByteSize > 33554432 then throw (IO.userError "PSC1_FULL_MODULE_OUTPUT_BOUND")
  IO.FS.writeFile file text

def phase (name : String) : IO Unit := do
  IO.println ("PSC1_FULL_MODULE_PHASE " ++ name ++ " " ++ toString (← IO.monoMsNow))
  (← IO.getStdout).flush

def artifactMetadata (kind : String) (unit : PsModuleUnit) (artifact : PsModuleArtifact) : Lean.Json :=
  .mkObj [("unit", Lean.toJson unit.index),
    ("file", .str (kind ++ "/unit-" ++ toString unit.index ++ (if kind == "js" then ".mjs" else ".mts"))),
    ("imports", Lean.toJson (artifact.imports.map importJson)),
    ("exports", Lean.toJson artifact.exports)]

def main (args : List String) : IO Unit := do
  let [irFile, graphFile, specifiersFile, digest, directory] := args
    | throw (IO.userError "PSC1_FULL_MODULE_ARGUMENTS")
  phase "decode"
  let raw ← liftResult (Ps.Host.PortableIr.decode (← boundedRead irFile))
  let graph ← boundedRead graphFile
  let declarationRows ← liftResult do
    let fused ← graph.getObjVal? "fused"
    jsonRows fused "declarations"
  let owners ← liftResult (declarationRows.mapM fun row => do
    return (PsModuleOwner.mk (← (← row.getObjVal? "name").getStr?)
      (← (← row.getObjVal? "owner").getNat?)))
  let specifierJson ← boundedRead specifiersFile
  let specifiers ← liftResult do
    let rows ← specifierJson.getArr?
    rows.mapM Lean.Json.getStr?
  phase "plan"
  let (selected, sourceToUnit) ← liftResult (plan raw owners specifiers)
  phase "lower"
  let lowered ← liftResult ((psJsLowerSpecializedModule selected.raw).mapError
    (fun _ => "PSC1_FULL_MODULE_JS_LOWER"))
  let _ ← liftResult ((psJsValidateModule lowered).mapError (fun _ => "PSC1_FULL_MODULE_JS_VALIDATE"))
  let brands := psTsBuildBrandMap selected.raw
  let tags := psTsBuildTagMap selected.raw
  IO.FS.createDirAll (directory ++ "/js")
  IO.FS.createDirAll (directory ++ "/ts")
  let mut jsRows := []
  let mut tsRows := []
  phase "print"
  for unit in selected.units do
    let js ← liftResult (Ps.Internal.ModularJs.renderUnit selected lowered digest unit)
    let ts ← liftResult (Ps.Internal.ModularTs.renderUnit selected digest brands tags unit)
    let suffix := "/unit-" ++ toString unit.index
    boundedWrite (directory ++ "/js" ++ suffix ++ ".mjs") js.source
    boundedWrite (directory ++ "/js" ++ suffix ++ ".d.mts") js.declarations
    boundedWrite (directory ++ "/ts" ++ suffix ++ ".mts") ts.source
    jsRows := artifactMetadata "js" unit js :: jsRows
    tsRows := artifactMetadata "ts" unit ts :: tsRows
  phase "reference"
  boundedWrite (directory ++ "/reference.js") (← liftResult
    ((psJsPrintModuleStackSafe lowered).mapError (fun _ => "PSC1_FULL_MODULE_REFERENCE_JS")))
  boundedWrite (directory ++ "/reference.ts") (← liftResult
    ((psTsEmitModule selected.raw).mapError (fun _ => "PSC1_FULL_MODULE_REFERENCE_TS")))
  boundedWrite (directory ++ "/modules.json") (Lean.Json.mkObj [
    ("schema", .str "psc1-modular-compiler-emission/1"),
    ("sourceClosureDigest", .str digest), ("protocol", .str selected.protocol),
    ("packages", Lean.toJson selected.packages),
    ("sourceToUnit", Lean.toJson sourceToUnit),
    ("owners", Lean.toJson (selected.owners.map ownerJson)),
    ("units", Lean.toJson (selected.units.map fun unit => Lean.Json.mkObj [
      ("index", Lean.toJson unit.index), ("names", Lean.toJson (unit.declarations.map (fun d => d.name)))])),
    ("js", Lean.toJson jsRows.reverse), ("ts", Lean.toJson tsRows.reverse),
    ("logicalAdmission", .str "external-host-required"),
    ("strictIR", Lean.toJson true), ("referenceFuel", Lean.toJson (4096 : Nat))
  ]).compress
  phase "complete"

end Ps.Host.ModularCompiler

def main : List String → IO Unit := Ps.Host.ModularCompiler.main
