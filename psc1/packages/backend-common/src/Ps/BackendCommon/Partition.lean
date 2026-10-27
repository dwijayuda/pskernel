import Ps.BackendCommon.Modules

/-! Bounded logical-owner partitioning, before the existing strict module planner.
SCCs coalesce latent function references; eager initializer policy is unchanged.
Sources with no surviving values share unit zero, which already owns all types.
No metadata grants validation, checking, or publication authority. -/

structure PsModulePartition where
  plan : PsModulePlan
  sourceToUnit : List Nat
  groups : List (List Nat)

namespace Ps.Internal.ModulePartition

def reach (fuel : Nat) (edges : List (Nat × Nat)) (known : List Nat) : List Nat :=
  match fuel with
  | 0 => known
  | remaining + 1 =>
    let expanded := edges.foldl (fun found edge =>
      if known.contains edge.1 && !found.contains edge.2 then found ++ [edge.2] else found) known
    if expanded.length == known.length then known else reach remaining edges expanded

def components (nodes : List Nat) (edges : List (Nat × Nat)) : List (List Nat) :=
  nodes.foldl (fun groups node =>
    if groups.any (fun group => group.contains node) then groups
    else
      let forward := reach 9 edges [node]
      let group := nodes.filter (fun candidate =>
        forward.contains candidate && (reach 9 edges [candidate]).contains node)
      groups ++ [group]) []

def dependenciesReady (edges : List (Nat × Nat)) (done group : List Nat) : Bool :=
  edges.all (fun edge =>
    !group.contains edge.1 || group.contains edge.2 || done.contains edge.2)

def order (fuel : Nat) (edges : List (Nat × Nat)) (done : List Nat)
    (groups : List (List Nat)) : Except String (List (List Nat)) := do
  match fuel with
  | 0 => if groups.isEmpty then return [] else throw "PSC1_PARTITION_ORDER_FUEL"
  | remaining + 1 =>
    if groups.isEmpty then return []
    match groups.find? (dependenciesReady edges done) with
    | none => throw "PSC1_PARTITION_CONDENSATION"
    | some group =>
      let tail := groups.filter (fun other => other.head? != group.head?)
      return group :: (← order remaining edges (done ++ group) tail)

def target (groups : List (List Nat)) (source : Nat) : Except String Nat := do
  let matches := (List.range groups.length).filter (fun index =>
    (groups[index]?.getD []).contains source)
  match matches with
  | [index] => return index
  | _ => throw "PSC1_PARTITION_SOURCE_COVERAGE"

end Ps.Internal.ModulePartition

def psPartitionModules (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (logicalPackages : List String) : Except String PsModulePartition := do
  let _ ← (psStrictValidateModule input).mapError (fun _ => "PSC1_PARTITION_STRICT_IR")
  if logicalPackages.length < 3 || logicalPackages.length > 9 then
    throw "PSC1_PARTITION_SOURCE_BOUND"
  if logicalPackages.head? != some "@proofscript/modular-pilot-runtime" then
    throw "PSC1_MODULE_PACKAGE_RUNTIME"
  for package in logicalPackages do
    if !psModulePackageSafe package ||
        (logicalPackages.filter (fun item => item == package)).length != 1 then
      throw "PSC1_MODULE_PACKAGE_IDENTITY"
  if input.declarations.length > 256 || input.structures.length + input.inductives.length > 64 then
    throw "PSC1_MODULE_PILOT_BOUND"
  if !input.imports.isEmpty then throw "PSC1_MODULE_EXTERNAL_IMPORT"
  if owners.length != input.declarations.length then throw "PSC1_MODULE_OWNER_COVERAGE"
  for owner in owners do
    if owner.unit >= logicalPackages.length ||
        !input.declarations.any (fun declaration => declaration.name == owner.name) then
      throw "PSC1_MODULE_OWNER_COVERAGE"
  let nodes := List.range logicalPackages.length
  let references ← input.declarations.mapM fun declaration => do
    let assigned ← Ps.Internal.ModuleGraph.owner owners declaration.name
    let references ← Ps.Internal.ModuleGraph.references 4096
      (declaration.parameters.map (fun p => p.name)) declaration.body
    let dependencies ← references.mapM (Ps.Internal.ModuleGraph.owner owners)
    return dependencies.map (fun dependency => (assigned.unit, dependency.unit))
  let edges := references.flatten
  -- Runtime/type initialization must remain dependency-free. Do not absorb a
  -- source into the runtime merely to hide an initialization-order violation.
  if edges.any (fun edge => edge.1 == 0 && edge.2 != 0) then
    throw "PSC1_PARTITION_RUNTIME_DEPENDENCY"
  let empty := nodes.tail.filter (fun node => !owners.any (fun owner => owner.unit == node))
  let active := nodes.tail.filter (fun node => !empty.contains node)
  let components := Ps.Internal.ModulePartition.components active edges
  let ordered ← Ps.Internal.ModulePartition.order 9 edges (0 :: empty) components
  let groups := (0 :: empty) :: ordered
  let sourceToUnit ← nodes.mapM (Ps.Internal.ModulePartition.target groups)
  let packages ← (List.range groups.length).mapM fun index => do
    if index == 0 then return "@proofscript/modular-pilot-runtime"
    let group := groups[index]?.getD []
    match group with
    | [source] =>
      match logicalPackages[source]? with
      | some package => return package
      | none => throw "PSC1_PARTITION_PACKAGE_COVERAGE"
    | _ => return "@proofscript/modular-pilot-group-" ++ String.intercalate "-" (group.map toString)
  let mapped ← owners.mapM fun owner => do
    match sourceToUnit[owner.unit]? with
    | some unit => return (PsModuleOwner.mk owner.name unit)
    | none => throw "PSC1_PARTITION_OWNER_RANGE"
  let plan ← psPlanModulesWithPackages input mapped packages "psc1-modular-pilot/3"
  return { plan, sourceToUnit, groups }
