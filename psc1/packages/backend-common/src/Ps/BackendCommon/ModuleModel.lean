import Ps.CompilerIr.Specialize
import Ps.CompilerIr.Provenance
import Ps.CompilerIr.Validate
import Ps.Foundation.Collections
import Ps.Foundation.Text

/-! Shared structured records and exact producer provenance. The production
compiler and retained pilot use these same definitions. Portable spelling makes
container operations explicit; no fixture bounds or checking policy changes. -/

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
  packages : List String
  protocol : String

namespace Ps.Internal.ModuleGraph

def seen (name : String) (names : List String) : Bool :=
  psListAny (fun (item : String) => psStringEq item name) names

def safeName (name : String) : Except String Unit :=
  let reserved := seen name ["eval", "Function", "require", "process", "globalThis", "then"];
  let leading := String.Internal.extract name (String.Pos.Raw.mk 0) (String.Pos.Raw.mk 5);
  if psStringEq leading "__ps$" || reserved then Except.error "PSC1_MODULE_RESERVED_NAME"
  else Except.ok ()

def owner (owners : List PsModuleOwner) (name : String) : Except String PsModuleOwner :=
  match psListFilter (fun (item : PsModuleOwner) => psStringEq item.name name) owners with
  | [value] => Except.ok value
  | _ => Except.error (String.Internal.append "PSC1_MODULE_OWNER_COVERAGE:" name)

def references (fuel : Nat) (locals : List String) :
    PsVerifiedIrExpr -> Except String (List String) :=
  match fuel with
  | Nat.zero => fun (_expression : PsVerifiedIrExpr) => Except.error "PSC1_MODULE_REFERENCE_FUEL"
  | Nat.succ remaining => fun (expression : PsVerifiedIrExpr) => do
    let visit := references remaining locals
    match expression with
    | PsVerifiedIrExpr.literal _ => return []
    | PsVerifiedIrExpr.var name =>
      safeName name
      return if seen name locals then [] else [name]
    | PsVerifiedIrExpr.intrinsic _ _ values =>
      let result ← psListMapExcept visit values
      return psListFlatten result
    | PsVerifiedIrExpr.lambda parameters _ body =>
      for parameter in parameters do safeName parameter.name
      references remaining
        (psListAppend (psListMap (fun (p : PsVerifiedIrParameter) => p.name) parameters) locals) body
    | PsVerifiedIrExpr.call fn _ values =>
      let target ← visit fn
      let arguments ← psListMapExcept visit values
      return psListAppend target (psListFlatten arguments)
    | PsVerifiedIrExpr.letE name _ value body =>
      safeName name
      let first ← visit value
      let rest ← references remaining (List.cons name locals) body
      return psListAppend first rest
    | PsVerifiedIrExpr.ifE condition left right =>
      let first ← visit condition
      let yes ← visit left
      let no ← visit right
      return psListAppend first (psListAppend yes no)
    | PsVerifiedIrExpr.record _ _ fields =>
      let result ← psListMapExcept
        (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields
      return psListFlatten result
    | PsVerifiedIrExpr.projection _ _ value _ => visit value
    | PsVerifiedIrExpr.constructor _ _ _ fields =>
      let result ← psListMapExcept
        (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields
      return psListFlatten result
    | PsVerifiedIrExpr.matchE _ _ value alternatives =>
      let branches ← psListMapExcept
        (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) => do
          for binding in alternative.snd.fst do safeName binding.name
          references remaining (psListAppend
            (psListMap (fun (binding : PsVerifiedIrMatchBinding) => binding.name) alternative.snd.fst)
            locals) alternative.snd.snd) alternatives
      let target ← visit value
      return psListAppend target (psListFlatten branches)

def staticInitializer (fuel : Nat) : PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_expression : PsVerifiedIrExpr) => false
  | Nat.succ remaining => fun (expression : PsVerifiedIrExpr) =>
    match expression with
    | PsVerifiedIrExpr.literal _ => true
    | PsVerifiedIrExpr.lambda _ _ _ => true
    | PsVerifiedIrExpr.constructor _ _ _ fields =>
        psListAll (fun (field : Prod String PsVerifiedIrExpr) => staticInitializer remaining field.snd) fields
    | PsVerifiedIrExpr.record _ _ fields =>
        psListAll (fun (field : Prod String PsVerifiedIrExpr) => staticInitializer remaining field.snd) fields
    | _ => false

def distinctImportsWorker (values acc : List PsModuleOwner) : List PsModuleOwner :=
  match values with
  | [] => acc
  | item :: rest =>
    let next := if psListAny
      (fun (previous : PsModuleOwner) => psStringEq previous.name item.name) acc then acc
      else psListAppend acc [item];
    distinctImportsWorker rest next

def distinctImports (values : List PsModuleOwner) : List PsModuleOwner :=
  distinctImportsWorker values []

def unit (raw : PsVerifiedIrModule) (owners : List PsModuleOwner) (index : Nat) :
    Except String PsModuleUnit := do
  let declarations ← psListFilterExcept (fun (declaration : PsVerifiedIrDeclaration) => do
    let assigned ← owner owners declaration.name
    return Nat.beq assigned.unit index) raw.declarations
  let refs ← psListMapExcept (fun (declaration : PsVerifiedIrDeclaration) => do
    let names ← references 4096
      (psListMap (fun (p : PsVerifiedIrParameter) => p.name) declaration.parameters) declaration.body
    psListMapExcept (owner owners) names) declarations
  let imports := psListFilter (fun (imported : PsModuleOwner) => !(Nat.beq imported.unit index))
    (distinctImports (psListFlatten refs))
  if psListAny (fun (imported : PsModuleOwner) => Nat.ble index imported.unit) imports then
    throw "PSC1_MODULE_CYCLE_OR_ORDER"
  return PsModuleUnit.mk index declarations imports

end Ps.Internal.ModuleGraph

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

def psModuleTypeNames (raw : PsVerifiedIrModule) : List String :=
  psListAppend (psListMap (fun (value : PsVerifiedIrStructure) => value.name) raw.structures)
    (psListMap (fun (value : PsVerifiedIrInductive) => value.name) raw.inductives)

def psModuleOriginKindEqual (left right : PsIrOriginKind) : Bool :=
  match left with
  | PsIrOriginKind.structure =>
    match right with
    | PsIrOriginKind.structure => true
    | _ => false
  | PsIrOriginKind.inductive =>
    match right with
    | PsIrOriginKind.inductive => true
    | _ => false
  | PsIrOriginKind.declaration =>
    match right with
    | PsIrOriginKind.declaration => true
    | _ => false

def psModuleEntityArity (raw : PsVerifiedIrModule) (kind : PsIrOriginKind)
    (name : String) : Except String Nat := do
  let entries := match kind with
    | PsIrOriginKind.structure => psListFilterMap (fun (item : PsVerifiedIrStructure) =>
        if psStringEq item.name name then Option.some (psListLength item.typeParameters)
        else Option.none) raw.structures
    | PsIrOriginKind.inductive => psListFilterMap (fun (item : PsVerifiedIrInductive) =>
        if psStringEq item.name name then Option.some (psListLength item.typeParameters)
        else Option.none) raw.inductives
    | PsIrOriginKind.declaration => psListFilterMap (fun (item : PsVerifiedIrDeclaration) =>
        if psStringEq item.name name then Option.some (psListLength item.typeParameters)
        else Option.none) raw.declarations
  match entries with
  | [arity] => return arity
  | _ => throw (String.Internal.append "PSC1_MODULE_ORIGIN_ENTITY:" name)

def psModuleOriginFor (rows : List PsIrTransformOrigin) (kind : PsIrOriginKind)
    (name : String) : Except String PsIrTransformOrigin := do
  match psListFilter (fun (row : PsIrTransformOrigin) =>
      psModuleOriginKindEqual row.kind kind && psStringEq row.outputName name) rows with
  | [row] => return row
  | _ => throw (String.Internal.append "PSC1_MODULE_ORIGIN_COVERAGE:" name)

def psModuleCarryOwners (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (output : PsIrTracedModule) : Except String (List PsModuleOwner) := do
  let _ ← psExceptMapError (fun (_reason : PsVerifiedIrValidationError) => "PSC1_MODULE_ORIGIN_INPUT_IR")
    (psStrictValidateModule input)
  let _ ← psExceptMapError (fun (_reason : PsVerifiedIrValidationError) => "PSC1_MODULE_ORIGIN_OUTPUT_IR")
    (psStrictValidateModule output.raw)
  if !(Nat.beq (psListLength owners) (psListLength input.declarations)) then
    throw "PSC1_MODULE_ORIGIN_INPUT_OWNERS"
  for declaration in input.declarations do
    let _ ← Ps.Internal.ModuleGraph.owner owners declaration.name
  let count := psListLength output.raw.structures + psListLength output.raw.inductives +
    psListLength output.raw.declarations
  if !(Nat.beq (psListLength output.origins) count) then throw "PSC1_MODULE_ORIGIN_COVERAGE"
  for row in output.origins do
    let _ ← psModuleEntityArity output.raw row.kind row.outputName
    let arity ← psModuleEntityArity input row.kind row.inputName
    match row.rule with
    | PsIrOriginRule.retained =>
      if !psStringEq row.outputName row.inputName || !psListIsEmpty row.arguments then
        throw "PSC1_MODULE_ORIGIN_RETAINED"
    | PsIrOriginRule.specialization =>
      if !(Nat.beq arity (psListLength row.arguments)) || !psIrSpecializeAllGround row.arguments then
        throw "PSC1_MODULE_ORIGIN_ARGUMENTS"
      match psIrSpecializedName row.inputName row.arguments with
      | Option.some expected =>
        if !psStringEq expected row.outputName then throw "PSC1_MODULE_ORIGIN_SPECIALIZATION"
      | Option.none => throw "PSC1_MODULE_ORIGIN_SPECIALIZATION"
    | PsIrOriginRule.worker =>
      if !psModuleOriginKindEqual row.kind PsIrOriginKind.declaration ||
          !psListIsEmpty row.arguments || psStringEq row.outputName row.inputName ||
          psListAny (fun (d : PsVerifiedIrDeclaration) => psStringEq d.name row.outputName) input.declarations then
        throw "PSC1_MODULE_ORIGIN_WORKER"
  for item in output.raw.structures do
    let _ ← psModuleOriginFor output.origins PsIrOriginKind.structure item.name
  for item in output.raw.inductives do
    let _ ← psModuleOriginFor output.origins PsIrOriginKind.inductive item.name
  psListMapExcept (fun (declaration : PsVerifiedIrDeclaration) => do
    let row ← psModuleOriginFor output.origins PsIrOriginKind.declaration declaration.name
    let previous ← Ps.Internal.ModuleGraph.owner owners row.inputName
    return PsModuleOwner.mk declaration.name previous.unit) output.raw.declarations

def psModuleSpecifierFor (plan : PsModulePlan) (index : Nat) (typed : Bool) : String :=
  let selected := match psListGetOption plan.packages index with
    | Option.some value => value
    | Option.none => "invalid-module-index";
  String.Internal.append selected (if typed then "/ts" else "")

def psModuleSourceIndicesWorker (fuel : Nat) (index : Nat) : List Nat :=
  match fuel with
  | Nat.zero => []
  | Nat.succ remaining => List.cons index (psModuleSourceIndicesWorker remaining (Nat.succ index))

def psModuleSourceIndices (plan : PsModulePlan) : List Nat :=
  match psListLength plan.packages with
  | Nat.zero => []
  | Nat.succ remaining => psModuleSourceIndicesWorker remaining 1

def psModuleCohortFor (plan : PsModulePlan) (sourceDigest : String) (typed : Bool) : String :=
  psTextJoin "" [plan.protocol, ":", if typed then "ts:" else "js:", sourceDigest]

