import Ps.BackendCommon.ModuleModel
import Std.Data.HashMap
import Std.Data.HashSet

/-! Build-time production ESM planning, over the same strictly checked IR.
No names are exempted from initialization checks. Function/static declarations
are installed before computed values. A computed value waits for every same-unit
computed value reachable through referenced function/closure bodies. This is a
conservative dependency analysis, not a termination or transform-preservation
proof. Cross-source cycles fail closed rather than merging source responsibilities.
The portable compiler and the retained pilot planners are unchanged. -/

namespace Ps.Host.ExecutablePlan

def ensure (condition : Bool) (code : String) : Except String Unit :=
  if condition then .ok () else .error code

def early (declaration : PsVerifiedIrDeclaration) : Bool :=
  !declaration.parameters.isEmpty ||
    Ps.Internal.ModuleGraph.staticInitializer 4096 declaration.body

def dependencies (start : String) (references : Std.HashMap String (List String))
    (late : Std.HashSet String) : Except String (List String) := do
  let mut pending := (references.get? start).getD []
  let mut visited : Std.HashSet String := {}
  let mut result : List String := []
  -- This separate build-stage traversal has a finite aggregate edge budget.
  for _ in [:131072] do
    if pending.isEmpty then break
    let name := pending.head!
    pending := pending.tail
    if !visited.contains name then
      visited := visited.insert name
      if late.contains name then result := name :: result
      else
        let some refs := references.get? name
          | throw ("PSC1_EXECUTABLE_UNKNOWN_REFERENCE:" ++ name)
        pending := refs ++ pending
  ensure pending.isEmpty "PSC1_EXECUTABLE_INITIALIZER_EDGE_BOUND"
  return result

def initialize (declarations : List PsVerifiedIrDeclaration)
    (references : Std.HashMap String (List String)) :
    Except String (List PsVerifiedIrDeclaration) := do
  let ready := declarations.filter early
  let mut pending := declarations.filter (fun item => !early item)
  let late := pending.foldl (fun (set : Std.HashSet String) item => set.insert item.name) {}
  let mut requirements : Std.HashMap String (List String) := {}
  for item in pending do
    requirements := requirements.insert item.name (← dependencies item.name references late)
  let mut installed : Std.HashSet String := {}
  let mut ordered : List PsVerifiedIrDeclaration := []
  for _ in [:pending.length] do
    let some item := pending.find? (fun item =>
      ((requirements.get? item.name).getD []).all installed.contains)
      | throw ("PSC1_EXECUTABLE_INITIALIZER_CYCLE:" ++
          String.intercalate "," ((pending.take 8).map (fun d => d.name)))
    installed := installed.insert item.name
    ordered := item :: ordered
    pending := pending.filter (fun other => other.name != item.name)
  ensure pending.isEmpty "PSC1_EXECUTABLE_INITIALIZER_ORDER_BOUND"
  return ready ++ ordered.reverse

def specifierSafe (specifier : String) : Bool :=
  match specifier.splitOn "/" with
  | ["@proofscript", package, "generated", name] =>
    !package.isEmpty && !name.isEmpty && !name.startsWith "." &&
      package.toList.all (fun c =>
        (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-') &&
      name.toList.all (fun c => c.isAlphanum || c == '.' || c == '_' || c == '-')
  | _ => false

def plan (raw : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (specifiers : Array String) : Except String (PsModulePlan × List Nat) := do
  let _ ← (psStrictValidateModule raw).mapError (fun _ => "PSC1_EXECUTABLE_STRICT_IR")
  ensure (raw.imports.isEmpty && raw.declarations.length <= 8192 &&
    raw.structures.length + raw.inductives.length <= 2048) "PSC1_EXECUTABLE_IR_BOUND"
  ensure (specifiers.size >= 2 && specifiers.size <= 257) "PSC1_EXECUTABLE_SOURCE_BOUND"
  ensure (specifiers[0]? == some "@proofscript/foundation/generated/runtime")
    "PSC1_EXECUTABLE_RUNTIME_OWNER"
  for specifier in specifiers do
    ensure (specifierSafe specifier) "PSC1_EXECUTABLE_SPECIFIER"
  ensure (specifiers.toList.eraseDups.length == specifiers.size)
    "PSC1_EXECUTABLE_SPECIFIER_UNIQUE"
  ensure (owners.length == raw.declarations.length) "PSC1_EXECUTABLE_OWNER_COVERAGE"
  let mut index : Std.HashMap String Nat := {}
  for owner in owners do
    ensure (owner.unit < specifiers.size && !index.contains owner.name)
      "PSC1_EXECUTABLE_OWNER_UNIQUE"
    index := index.insert owner.name owner.unit
  let mut buckets : Array (List PsVerifiedIrDeclaration) := Array.replicate specifiers.size []
  let mut references : Array (List PsModuleOwner) := Array.replicate specifiers.size []
  let mut byName : Std.HashMap String (List String) := {}
  for declaration in raw.declarations do
    Ps.Internal.ModuleGraph.safeName declaration.name
    let some unit := index.get? declaration.name | throw "PSC1_EXECUTABLE_OWNER_MISSING"
    ensure declaration.typeParameters.isEmpty "PSC1_EXECUTABLE_OPEN_VALUE"
    for parameter in declaration.parameters do Ps.Internal.ModuleGraph.safeName parameter.name
    buckets := buckets.set! unit (declaration :: buckets[unit]!)
    let refs ← Ps.Internal.ModuleGraph.references 4096
      (declaration.parameters.map (fun p => p.name)) declaration.body
    byName := byName.insert declaration.name refs
    for name in refs do
      let some assigned := index.get? name
        | throw ("PSC1_EXECUTABLE_UNKNOWN_REFERENCE:" ++ name)
      if assigned != unit then
        references := references.set! unit ({ name, unit := assigned } :: references[unit]!)
  ensure (references[0]!.isEmpty) "PSC1_EXECUTABLE_RUNTIME_DEPENDENCY"
  let mut pending := (List.range specifiers.size).tail
  let mut ordered := [0]
  let mut mapped : Array Nat := Array.replicate specifiers.size 0
  for _ in [:specifiers.size] do
    if pending.isEmpty then break
    let some source := pending.find? (fun source =>
      references[source]!.all (fun dependency => ordered.contains dependency.unit))
      | throw "PSC1_EXECUTABLE_CROSS_SOURCE_CYCLE"
    mapped := mapped.set! source ordered.length
    ordered := ordered ++ [source]
    pending := pending.filter (fun item => item != source)
  ensure pending.isEmpty "PSC1_EXECUTABLE_ORDER_BOUND"
  let remapped := owners.map fun owner => { owner with unit := mapped[owner.unit]! }
  let units ← ordered.zipIdx.mapM fun (source, unit) => do
    let mut seen : Std.HashSet String := {}
    let mut imports : List PsModuleOwner := []
    for ref in references[source]!.reverse do
      let assigned := mapped[ref.unit]!
      ensure (assigned < unit) "PSC1_EXECUTABLE_CYCLE_OR_ORDER"
      if !seen.contains ref.name then
        seen := seen.insert ref.name
        imports := { ref with unit := assigned } :: imports
    let declarations ← initialize buckets[source]!.reverse byName
    return PsModuleUnit.mk unit declarations imports.reverse
  return (PsModulePlan.mk raw remapped units
    (ordered.map (fun source => specifiers[source]!)) "psc1-executable-compiler/1", mapped.toList)

end Ps.Host.ExecutablePlan
