import Ps.CompilerIr.Specialize
import Ps.CompilerIr.Provenance
import Ps.CompilerIr.Validate

/-! Opt-in bounded module planning. Ownership is supplied by the same captured
elaboration; every value is assigned once. No caller-supplied validation token
or external import can authorize emission. The first pilot is an ordered DAG
with shared types/runtime and two monomorphic source owners. -/

structure PsModuleOwner where
  name : String
  unit : Nat

structure PsModuleUnit where
  index : Nat
  declarations : List PsVerifiedIrDeclaration
  imports : List PsModuleOwner

structure PsModulePlan where
  raw : PsVerifiedIrModule
  owners : List PsModuleOwner
  units : List PsModuleUnit

namespace Ps.Internal.ModuleGraph

def seen (name : String) (names : List String) : Bool :=
  names.any (fun item => item == name)

def safeName (name : String) : Except String Unit :=
  if name.startsWith "__ps$" || ["eval", "Function", "require", "process", "globalThis", "then"].contains name then
    .error "PSC1_MODULE_RESERVED_NAME" else .ok ()

def owner (owners : List PsModuleOwner) (name : String) : Except String PsModuleOwner :=
  match owners.filter (fun item => item.name == name) with
  | [value] => .ok value
  | _ => .error ("PSC1_MODULE_OWNER_COVERAGE:" ++ name)

def references (fuel : Nat) (locals : List String) :
    PsVerifiedIrExpr -> Except String (List String) :=
  match fuel with
  | 0 => fun _ => .error "PSC1_MODULE_REFERENCE_FUEL"
  | remaining + 1 => fun expression => do
    let visit := references remaining locals
    match expression with
    | .literal _ => return []
    | .var name =>
      safeName name
      return if seen name locals then [] else [name]
    | .intrinsic _ _ values =>
      return (← values.mapM visit).flatten
    | .lambda parameters _ body =>
      for parameter in parameters do safeName parameter.name
      references remaining (parameters.map (fun p => p.name) ++ locals) body
    | .call fn _ values =>
      return (← visit fn) ++ (← values.mapM visit).flatten
    | .letE name _ value body =>
      safeName name
      return (← visit value) ++ (← references remaining (name :: locals) body)
    | .ifE condition left right =>
      return (← visit condition) ++ (← visit left) ++ (← visit right)
    | .record _ _ fields =>
      return (← fields.mapM (fun field => visit field.2)).flatten
    | .projection _ _ value _ => visit value
    | .constructor _ _ _ fields =>
      return (← fields.mapM (fun field => visit field.2)).flatten
    | .matchE _ _ value alternatives =>
      let branches ← alternatives.mapM fun alternative => do
        for binding in alternative.2.1 do safeName binding.name
        references remaining (alternative.2.1.map (fun b => b.name) ++ locals) alternative.2.2
      return (← visit value) ++ branches.flatten

def staticInitializer (fuel : Nat) : PsVerifiedIrExpr -> Bool :=
  match fuel with
  | 0 => fun _ => false
  | remaining + 1 => fun expression =>
    match expression with
    | .literal _ => true
    | .lambda _ _ _ => true
    | .constructor _ _ _ fields =>
      fields.all (fun field => staticInitializer remaining field.2)
    | .record _ _ fields =>
      fields.all (fun field => staticInitializer remaining field.2)
    | _ => false

def distinctImports (values : List PsModuleOwner) : List PsModuleOwner :=
  values.foldl (fun acc item =>
    if acc.any (fun previous => previous.name == item.name) then acc else acc ++ [item]) []

def unit (raw : PsVerifiedIrModule) (owners : List PsModuleOwner) (index : Nat) :
    Except String PsModuleUnit := do
  let declarations ← raw.declarations.filterM fun declaration => do
    let assigned ← owner owners declaration.name
    return assigned.unit == index
  let references ← declarations.mapM fun declaration => do
    let names ← references 4096 (declaration.parameters.map (fun p => p.name)) declaration.body
    names.mapM (owner owners)
  let imports := (distinctImports references.flatten).filter (fun imported => imported.unit != index)
  -- Cross-owner cycles, including latent function cycles, are unqualified.
  if imports.any (fun imported => imported.unit >= index) then
    throw "PSC1_MODULE_CYCLE_OR_ORDER"
  return { index, declarations, imports }

end Ps.Internal.ModuleGraph

def psPlanModules (input : PsVerifiedIrModule) (owners : List PsModuleOwner) :
    Except String PsModulePlan := do
  let validated ← (psStrictValidateModule input).mapError (fun _ => "PSC1_MODULE_STRICT_IR")
  let raw := validated.raw
  if !raw.imports.isEmpty then throw "PSC1_MODULE_EXTERNAL_IMPORT"
  if raw.declarations.length > 256 || raw.structures.length + raw.inductives.length > 64 then
    throw "PSC1_MODULE_PILOT_BOUND"
  if owners.length != raw.declarations.length then throw "PSC1_MODULE_OWNER_COVERAGE"
  for item in owners do
    if item.unit > 2 || !raw.declarations.any (fun d => d.name == item.name) then
      throw "PSC1_MODULE_OWNER_COVERAGE"
  for declaration in raw.declarations do
    Ps.Internal.ModuleGraph.safeName declaration.name
    let _ ← Ps.Internal.ModuleGraph.owner owners declaration.name
    if !declaration.typeParameters.isEmpty then throw "PSC1_MODULE_GENERIC_VALUE_UNQUALIFIED"
    for parameter in declaration.parameters do Ps.Internal.ModuleGraph.safeName parameter.name
    if declaration.parameters.isEmpty &&
        !Ps.Internal.ModuleGraph.staticInitializer 4096 declaration.body then
      throw ("PSC1_MODULE_EAGER_INITIALIZER:" ++ declaration.name)
  let units ← [0, 1, 2].mapM (Ps.Internal.ModuleGraph.unit raw owners)
  match units with
  | [_, producer, consumer] =>
    if producer.declarations.isEmpty || consumer.declarations.isEmpty then
      throw "PSC1_MODULE_EMPTY_SOURCE_OWNER"
  | _ => throw "PSC1_MODULE_UNIT_COVERAGE"
  return { raw, owners, units }

structure PsModuleImport where
  source : String
  names : List String
  typeOnly : Bool := false

structure PsModuleArtifact where
  unit : Nat
  source : String
  declarations : String
  imports : List PsModuleImport
  exports : List String

def psModulePackage (index : Nat) : String :=
  if index == 0 then "@proofscript/modular-pilot-runtime"
  else if index == 1 then "@proofscript/modular-pilot-names"
  else "@proofscript/modular-pilot-consumer"

def psModuleSpecifier (index : Nat) (typed : Bool) : String :=
  psModulePackage index ++ (if typed then "/ts" else "")

def psModuleTypeNames (raw : PsVerifiedIrModule) : List String :=
  raw.structures.map (fun value => value.name) ++ raw.inductives.map (fun value => value.name)

def psModuleCohort (sourceDigest : String) (typed : Bool) : String :=
  "psc1-modular-pilot/1:" ++ (if typed then "ts:" else "js:") ++ sourceDigest


/-! Carry value ownership only through complete producer-generated provenance.
Nominal types remain owned by the shared runtime unit. This metadata neither
authorizes IR nor proves transform preservation: both raw modules are rechecked. -/

def psModuleOriginKindEqual (left right : PsIrOriginKind) : Bool :=
  match left, right with
  | .structure, .structure => true
  | .inductive, .inductive => true
  | .declaration, .declaration => true
  | _, _ => false

def psModuleEntityArity (raw : PsVerifiedIrModule) (kind : PsIrOriginKind)
    (name : String) : Except String Nat := do
  let entries := match kind with
    | .structure => raw.structures.filterMap (fun item =>
        if item.name == name then some item.typeParameters.length else none)
    | .inductive => raw.inductives.filterMap (fun item =>
        if item.name == name then some item.typeParameters.length else none)
    | .declaration => raw.declarations.filterMap (fun item =>
        if item.name == name then some item.typeParameters.length else none)
  match entries with
  | [arity] => return arity
  | _ => throw ("PSC1_MODULE_ORIGIN_ENTITY:" ++ name)

def psModuleOriginFor (rows : List PsIrTransformOrigin) (kind : PsIrOriginKind)
    (name : String) : Except String PsIrTransformOrigin := do
  match rows.filter (fun row => psModuleOriginKindEqual row.kind kind && row.outputName == name) with
  | [row] => return row
  | _ => throw ("PSC1_MODULE_ORIGIN_COVERAGE:" ++ name)

def psModuleCarryOwners (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (output : PsIrTracedModule) : Except String (List PsModuleOwner) := do
  let _ ← (psStrictValidateModule input).mapError (fun _ => "PSC1_MODULE_ORIGIN_INPUT_IR")
  let _ ← (psStrictValidateModule output.raw).mapError (fun _ => "PSC1_MODULE_ORIGIN_OUTPUT_IR")
  if owners.length != input.declarations.length then throw "PSC1_MODULE_ORIGIN_INPUT_OWNERS"
  for declaration in input.declarations do
    let _ ← Ps.Internal.ModuleGraph.owner owners declaration.name
  let count := output.raw.structures.length + output.raw.inductives.length + output.raw.declarations.length
  if output.origins.length != count then throw "PSC1_MODULE_ORIGIN_COVERAGE"
  for row in output.origins do
    let _ ← psModuleEntityArity output.raw row.kind row.outputName
    let arity ← psModuleEntityArity input row.kind row.inputName
    match row.rule with
    | .retained =>
      if row.outputName != row.inputName || !row.arguments.isEmpty then
        throw "PSC1_MODULE_ORIGIN_RETAINED"
    | .specialization =>
      if arity != row.arguments.length || !psIrSpecializeAllGround row.arguments then
        throw "PSC1_MODULE_ORIGIN_ARGUMENTS"
      if psIrSpecializedName row.inputName row.arguments != some row.outputName then
        throw "PSC1_MODULE_ORIGIN_SPECIALIZATION"
    | .worker =>
      if !psModuleOriginKindEqual row.kind .declaration || !row.arguments.isEmpty ||
          row.outputName == row.inputName || input.declarations.any (fun d => d.name == row.outputName) then
        throw "PSC1_MODULE_ORIGIN_WORKER"
  for item in output.raw.structures do
    let _ ← psModuleOriginFor output.origins .structure item.name
  for item in output.raw.inductives do
    let _ ← psModuleOriginFor output.origins .inductive item.name
  output.raw.declarations.mapM fun declaration => do
    let row ← psModuleOriginFor output.origins .declaration declaration.name
    let previous ← Ps.Internal.ModuleGraph.owner owners row.inputName
    return { name := declaration.name, unit := previous.unit }
