import Ps.BackendCommon.ModuleModel

/-! Retained bounded experimental planner. Its profiles, fixture limits and
static-initializer acceptance are unchanged. Production uses a separate planner. -/

def psModulePackageSafe (name : String) : Bool :=
  match name.splitOn "/" with
  | ["@proofscript", slug] =>
    slug.startsWith "modular-pilot-" && slug.length <= 128 &&
      slug.toList.all (fun char =>
        (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-')
  | _ => false

def psPlanModulesWithPackages (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (packages : List String) (protocol : String) :
    Except String PsModulePlan := do
  let legacy := protocol == "psc1-modular-pilot/1"
  if !legacy && protocol != "psc1-modular-pilot/2" then throw "PSC1_MODULE_PROFILE"
  if packages.length < 3 || packages.length > (if legacy then 3 else 9) then
    throw "PSC1_MODULE_UNIT_BOUND"
  if packages.head? != some "@proofscript/modular-pilot-runtime" then throw "PSC1_MODULE_PACKAGE_RUNTIME"
  for package in packages do
    if !psModulePackageSafe package || (packages.filter (fun value => value == package)).length != 1 then
      throw "PSC1_MODULE_PACKAGE_IDENTITY"
  let validated ← (psStrictValidateModule input).mapError (fun _ => "PSC1_MODULE_STRICT_IR")
  let raw := validated.raw
  if !raw.imports.isEmpty then throw "PSC1_MODULE_EXTERNAL_IMPORT"
  if raw.declarations.length > 256 || raw.structures.length + raw.inductives.length > 64 then
    throw "PSC1_MODULE_PILOT_BOUND"
  if owners.length != raw.declarations.length then throw "PSC1_MODULE_OWNER_COVERAGE"
  for item in owners do
    if item.unit >= packages.length || !raw.declarations.any (fun d => d.name == item.name) then
      throw "PSC1_MODULE_OWNER_COVERAGE"
  for declaration in raw.declarations do
    Ps.Internal.ModuleGraph.safeName declaration.name
    let _ ← Ps.Internal.ModuleGraph.owner owners declaration.name
    if !declaration.typeParameters.isEmpty then throw "PSC1_MODULE_GENERIC_VALUE_UNQUALIFIED"
    for parameter in declaration.parameters do Ps.Internal.ModuleGraph.safeName parameter.name
    if declaration.parameters.isEmpty &&
        !Ps.Internal.ModuleGraph.staticInitializer 4096 declaration.body then
      throw ("PSC1_MODULE_EAGER_INITIALIZER:" ++ declaration.name)
  let units ← (List.range packages.length).mapM (Ps.Internal.ModuleGraph.unit raw owners)
  for unit in units.tail do
    if unit.declarations.isEmpty then throw "PSC1_MODULE_EMPTY_SOURCE_OWNER"
  return { raw, owners, units, packages, protocol }

def psPlanModules (input : PsVerifiedIrModule) (owners : List PsModuleOwner) :
    Except String PsModulePlan :=
  psPlanModulesWithPackages input owners [
    "@proofscript/modular-pilot-runtime", "@proofscript/modular-pilot-names",
    "@proofscript/modular-pilot-consumer"] "psc1-modular-pilot/1"

def psModulePackage (index : Nat) : String :=
  if index == 0 then "@proofscript/modular-pilot-runtime"
  else if index == 1 then "@proofscript/modular-pilot-names"
  else "@proofscript/modular-pilot-consumer"

def psModuleSpecifier (index : Nat) (typed : Bool) : String :=
  psModulePackage index ++ (if typed then "/ts" else "")

def psModuleCohort (sourceDigest : String) (typed : Bool) : String :=
  "psc1-modular-pilot/1:" ++ (if typed then "ts:" else "js:") ++ sourceDigest


