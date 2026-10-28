import Ps.BackendCommon.ModuleModel
import Ps.Foundation.StringMap

/-! Portable production ESM planning over strictly checked IR. This preserves the
native reference planner's ordering and conservative transitive initializer
analysis. The 131072-edge, 4096-reference-depth, 8192-value and 257-unit policies
remain. Lookup tries use exact keys; no host container or unchecked IR is used. -/

namespace Ps.Internal.ExecutablePlan

def ensure (condition : Bool) (code : String) : Except String Unit :=
  if condition then .ok () else .error code

def early (declaration : PsVerifiedIrDeclaration) : Bool :=
  !declaration.parameters.isEmpty ||
    Ps.Internal.ModuleGraph.staticInitializer 4096 declaration.body

def getDefault {alpha : Type} (index : PsStringMap alpha) (key : String)
    (fallback : alpha) : alpha :=
  match psStringMapGet index key with
  | .some value => value
  | .none => fallback

def visitDependencies (fuel : Nat) (references : PsStringMap (List String))
    (late : PsStringSet) (pending : List String) (visited : PsStringSet)
    (result : List String) : Except String (List String) :=
  if pending.isEmpty then .ok result
  else match fuel with
  | 0 => .error "PSC1_EXECUTABLE_INITIALIZER_EDGE_BOUND"
  | remaining + 1 =>
    let name := pending.head!
    let rest := pending.tail
    if psStringSetContains visited name then
      visitDependencies remaining references late rest visited result
    else
      let next := psStringSetInsert visited name
      if psStringSetContains late name then
        visitDependencies remaining references late rest next (name :: result)
      else match psStringMapGet references name with
        | .none => .error ("PSC1_EXECUTABLE_UNKNOWN_REFERENCE:" ++ name)
        | .some refs => visitDependencies remaining references late (refs ++ rest) next result

def dependencies (start : String) (references : PsStringMap (List String))
    (late : PsStringSet) : Except String (List String) :=
  visitDependencies 131072 references late (getDefault references start []) .empty []

def installInitializers (fuel : Nat) (pending : List PsVerifiedIrDeclaration)
    (requirements : PsStringMap (List String)) (installed : PsStringSet)
    (ordered : List PsVerifiedIrDeclaration) : Except String (List PsVerifiedIrDeclaration) :=
  if pending.isEmpty then .ok ordered.reverse
  else match fuel with
  | 0 => .error "PSC1_EXECUTABLE_INITIALIZER_ORDER_BOUND"
  | remaining + 1 => do
    let some item := pending.find? (fun item =>
      (getDefault requirements item.name []).all (psStringSetContains installed))
      | throw ("PSC1_EXECUTABLE_INITIALIZER_CYCLE:" ++
          String.intercalate "," ((pending.take 8).map (fun d => d.name)))
    installInitializers remaining (pending.filter (fun other => other.name != item.name))
      requirements (psStringSetInsert installed item.name) (item :: ordered)

def orderInitializers (declarations : List PsVerifiedIrDeclaration)
    (references : PsStringMap (List String)) :
    Except String (List PsVerifiedIrDeclaration) := do
  let ready := declarations.filter early
  let pending := declarations.filter (fun item => !early item)
  let late := psStringSetFromList (pending.map (fun item => item.name))
  let mut requirements : PsStringMap (List String) := .empty
  for item in pending do
    requirements := psStringMapPut requirements item.name (← dependencies item.name references late)
  return ready ++ (← installInitializers pending.length pending requirements .empty [])

def asciiAlphaNumeric (c : Char) : Bool :=
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')

def specifierSafe (specifier : String) : Bool :=
  match specifier.splitOn "/" with
  | ["@proofscript", package, "generated", name] =>
    !package.isEmpty && !name.isEmpty && !name.startsWith "." &&
      package.toList.all (fun c =>
        (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-') &&
      name.toList.all (fun c => asciiAlphaNumeric c || c == '.' || c == '_' || c == '-')
  | _ => false

def rangeWorker (fuel : Nat) (index : Nat) : List Nat :=
  match fuel with
  | 0 => []
  | remaining + 1 => index :: rangeWorker remaining (index + 1)

def range (count : Nat) : List Nat := rangeWorker count 0

def mappedUnit (mapping : List (Prod Nat Nat)) (source : Nat) : Except String Nat :=
  match mapping with
  | [] => .error "PSC1_EXECUTABLE_OWNER_MISSING"
  | row :: rest => if row.fst == source then .ok row.snd else mappedUnit rest source

def orderUnits (fuel : Nat) (pending ordered : List Nat)
    (references : PsStringMap (List PsModuleOwner))
    (mapping : List (Prod Nat Nat)) : Except String (Prod (List Nat) (List (Prod Nat Nat))) :=
  if pending.isEmpty then .ok (ordered, mapping)
  else match fuel with
  | 0 => .error "PSC1_EXECUTABLE_ORDER_BOUND"
  | remaining + 1 => do
    let some source := pending.find? (fun source =>
      (getDefault references (psNatToString source) []).all
        (fun dependency => ordered.contains dependency.unit))
      | throw "PSC1_EXECUTABLE_CROSS_SOURCE_CYCLE"
    orderUnits remaining (pending.filter (fun item => item != source)) (ordered ++ [source])
      references ((source, ordered.length) :: mapping)

def buildUnits (ordered : List Nat) (unit : Nat)
    (references : PsStringMap (List PsModuleOwner))
    (buckets : PsStringMap (List PsVerifiedIrDeclaration))
    (byName : PsStringMap (List String)) (mapping : List (Prod Nat Nat)) :
    Except String (List PsModuleUnit) := do
  match ordered with
  | [] => return []
  | source :: rest =>
    let mut seen : PsStringSet := .empty
    let mut imports : List PsModuleOwner := []
    for ref in (getDefault references (psNatToString source) []).reverse do
      let assigned ← mappedUnit mapping ref.unit
      ensure (assigned < unit) "PSC1_EXECUTABLE_CYCLE_OR_ORDER"
      if !psStringSetContains seen ref.name then
        seen := psStringSetInsert seen ref.name
        imports := { ref with unit := assigned } :: imports
    let declarations ← orderInitializers
      (getDefault buckets (psNatToString source) []).reverse byName
    let next ← buildUnits rest (unit + 1) references buckets byName mapping
    return PsModuleUnit.mk unit declarations imports.reverse :: next

def plan (raw : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (specifiers : List String) : Except String (PsModulePlan × List Nat) := do
  let _ ← (psStrictValidateModule raw).mapError (fun _ => "PSC1_EXECUTABLE_STRICT_IR")
  ensure (raw.imports.isEmpty && raw.declarations.length <= 8192 &&
    raw.structures.length + raw.inductives.length <= 2048) "PSC1_EXECUTABLE_IR_BOUND"
  ensure (specifiers.length >= 2 && specifiers.length <= 257) "PSC1_EXECUTABLE_SOURCE_BOUND"
  ensure (specifiers.head? == some "@proofscript/foundation/generated/runtime")
    "PSC1_EXECUTABLE_RUNTIME_OWNER"
  let mut used : PsStringSet := .empty
  for specifier in specifiers do
    ensure (specifierSafe specifier) "PSC1_EXECUTABLE_SPECIFIER"
    ensure (!psStringSetContains used specifier) "PSC1_EXECUTABLE_SPECIFIER_UNIQUE"
    used := psStringSetInsert used specifier
  ensure (owners.length == raw.declarations.length) "PSC1_EXECUTABLE_OWNER_COVERAGE"
  let mut index : PsStringMap Nat := .empty
  for owner in owners do
    ensure (owner.unit < specifiers.length && !psStringMapContains index owner.name)
      "PSC1_EXECUTABLE_OWNER_UNIQUE"
    index := psStringMapPut index owner.name owner.unit
  let mut buckets : PsStringMap (List PsVerifiedIrDeclaration) := .empty
  let mut references : PsStringMap (List PsModuleOwner) := .empty
  let mut byName : PsStringMap (List String) := .empty
  for declaration in raw.declarations do
    Ps.Internal.ModuleGraph.safeName declaration.name
    let some unit := psStringMapGet index declaration.name | throw "PSC1_EXECUTABLE_OWNER_MISSING"
    ensure declaration.typeParameters.isEmpty "PSC1_EXECUTABLE_OPEN_VALUE"
    for parameter in declaration.parameters do Ps.Internal.ModuleGraph.safeName parameter.name
    let key := psNatToString unit
    buckets := psStringMapPut buckets key (declaration :: getDefault buckets key [])
    let refs ← Ps.Internal.ModuleGraph.references 4096
      (declaration.parameters.map (fun p => p.name)) declaration.body
    byName := psStringMapPut byName declaration.name refs
    for name in refs do
      let some assigned := psStringMapGet index name
        | throw ("PSC1_EXECUTABLE_UNKNOWN_REFERENCE:" ++ name)
      if assigned != unit then
        references := psStringMapPut references key
          ({ name, unit := assigned } :: getDefault references key [])
  ensure ((getDefault references "0" []).isEmpty) "PSC1_EXECUTABLE_RUNTIME_DEPENDENCY"
  let (ordered, mapping) ← orderUnits specifiers.length (range specifiers.length).tail
    [0] references [(0, 0)]
  let remapped ← owners.mapM fun owner => do
    return { owner with unit := (← mappedUnit mapping owner.unit) }
  let units ← buildUnits ordered 0 references buckets byName mapping
  let packages ← ordered.mapM fun source =>
    match specifiers[source]? with
    | .some value => .ok value
    | .none => .error "PSC1_EXECUTABLE_SOURCE_BOUND"
  let sourceToUnit ← (range specifiers.length).mapM (mappedUnit mapping)
  return (PsModulePlan.mk raw remapped units packages "psc1-executable-compiler/1", sourceToUnit)

end Ps.Internal.ExecutablePlan

