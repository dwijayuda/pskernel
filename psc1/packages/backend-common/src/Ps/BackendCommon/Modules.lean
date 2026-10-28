import Ps.CompilerIr.Specialize
import Ps.CompilerIr.Provenance
import Ps.CompilerIr.Validate
import Ps.Foundation.List
import Ps.Foundation.Name
import Ps.Foundation.Text

/-! Opt-in bounded module planning. Ownership is supplied by captured elaboration;
no caller-supplied validation token or external import authorizes emission. The
portable helpers below preserve the native pilot's left-to-right error order. -/

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

def filter {A : Type} (predicate : A -> Bool) (values : List A) : List A :=
  match values with
  | List.nil => List.nil
  | List.cons value rest =>
      if predicate value then List.cons value (filter predicate rest)
      else filter predicate rest

def filterMap {A B : Type} (convert : A -> Option B) (values : List A) : List B :=
  match values with
  | List.nil => List.nil
  | List.cons value rest =>
      match convert value with
      | Option.none => filterMap convert rest
      | Option.some result => List.cons result (filterMap convert rest)

def flatten {A : Type} (values : List (List A)) : List A :=
  match values with
  | List.nil => List.nil
  | List.cons value rest => psListAppend value (flatten rest)

def mapError {A E F : Type} (convert : E -> F) (value : Except E A) : Except F A :=
  match value with
  | Except.error error => Except.error (convert error)
  | Except.ok result => Except.ok result

def forEach {A E : Type} (check : A -> Except E Unit) (values : List A) : Except E Unit :=
  match values with
  | List.nil => Except.ok ()
  | List.cons value rest =>
      match check value with
      | Except.error error => Except.error error
      | Except.ok _ => forEach check rest

def filterExcept {A E : Type} (predicate : A -> Except E Bool) (values : List A) : Except E (List A) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons value rest =>
      match predicate value with
      | Except.error error => Except.error error
      | Except.ok keep =>
          match filterExcept predicate rest with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (if keep then List.cons value tail else tail)

def all {A : Type} (predicate : A -> Bool) (values : List A) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest => if predicate value then all predicate rest else false

def foldl {A B : Type} (combine : B -> A -> B) (initial : B) (values : List A) : B :=
  match values with
  | List.nil => initial
  | List.cons value rest => foldl combine (combine initial value) rest

def tail {A : Type} (values : List A) : List A :=
  match values with
  | List.nil => List.nil
  | List.cons _ rest => rest

def atD {A : Type} (values : List A) (index : Nat) (fallback : A) : A :=
  match values with
  | List.nil => fallback
  | List.cons value rest =>
      match index with
      | Nat.zero => value
      | Nat.succ previous => atD rest previous fallback

def rangeFrom (count start : Nat) : List Nat :=
  match count with
  | Nat.zero => List.nil
  | Nat.succ remaining => List.cons start (rangeFrom remaining (Nat.succ start))

def startsWithAt (fuel : Nat) (value prefix : String) (valuePos prefixPos : Nat) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
      if String.Internal.atEnd prefix (String.Pos.Raw.mk prefixPos) then true
      else if String.Internal.atEnd value (String.Pos.Raw.mk valuePos) then false
      else
        let left : Char := String.Internal.get value (String.Pos.Raw.mk valuePos);
        let right : Char := String.Internal.get prefix (String.Pos.Raw.mk prefixPos);
        if Nat.beq (Char.toNat left) (Char.toNat right) then
          startsWithAt remaining value prefix
            (String.Pos.Raw.byteIdx (String.Internal.next value (String.Pos.Raw.mk valuePos)))
            (String.Pos.Raw.byteIdx (String.Internal.next prefix (String.Pos.Raw.mk prefixPos)))
        else false

def startsWith (value prefix : String) : Bool :=
  startsWithAt (Nat.succ (String.utf8ByteSize prefix)) value prefix 0 0

def seen (name : String) (names : List String) : Bool :=
  psListAny (fun (item : String) => psStringEq item name) names

def safeName (name : String) : Except String Unit :=
  if startsWith name "__ps$" || seen name ["eval", "Function", "require", "process", "globalThis", "then"] then
    Except.error "PSC1_MODULE_RESERVED_NAME"
  else Except.ok ()

def owner (owners : List PsModuleOwner) (name : String) : Except String PsModuleOwner :=
  match filter (fun (item : PsModuleOwner) => psStringEq item.name name) owners with
  | List.nil => Except.error (String.Internal.append "PSC1_MODULE_OWNER_COVERAGE:" name)
  | List.cons value rest =>
      if psListIsEmpty rest then Except.ok value
      else Except.error (String.Internal.append "PSC1_MODULE_OWNER_COVERAGE:" name)

def references (fuel : Nat) (locals : List String) : PsVerifiedIrExpr -> Except String (List String) :=
  match fuel with
  | Nat.zero => fun (_expression : PsVerifiedIrExpr) => Except.error "PSC1_MODULE_REFERENCE_FUEL"
  | Nat.succ remaining => fun (expression : PsVerifiedIrExpr) =>
      let visit : PsVerifiedIrExpr -> Except String (List String) := references remaining locals;
      match expression with
      | PsVerifiedIrExpr.literal _ => Except.ok List.nil
      | PsVerifiedIrExpr.var name =>
          match safeName name with
          | Except.error error => Except.error error
          | Except.ok _ => Except.ok (if seen name locals then List.nil else [name])
      | PsVerifiedIrExpr.intrinsic _ _ values =>
          match psListMapExcept visit values with
          | Except.error error => Except.error error
          | Except.ok names => Except.ok (flatten names)
      | PsVerifiedIrExpr.lambda parameters _ body =>
          match forEach (fun (parameter : PsVerifiedIrParameter) => safeName parameter.name) parameters with
          | Except.error error => Except.error error
          | Except.ok _ => references remaining
              (psListAppend (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) parameters) locals) body
      | PsVerifiedIrExpr.call fn _ values =>
          match visit fn with
          | Except.error error => Except.error error
          | Except.ok first =>
              match psListMapExcept visit values with
              | Except.error error => Except.error error
              | Except.ok names => Except.ok (psListAppend first (flatten names))
      | PsVerifiedIrExpr.letE name _ value body =>
          match safeName name with
          | Except.error error => Except.error error
          | Except.ok _ =>
              match visit value with
              | Except.error error => Except.error error
              | Except.ok first =>
                  match references remaining (List.cons name locals) body with
                  | Except.error error => Except.error error
                  | Except.ok second => Except.ok (psListAppend first second)
      | PsVerifiedIrExpr.ifE condition left right =>
          match psListMapExcept visit [condition, left, right] with
          | Except.error error => Except.error error
          | Except.ok names => Except.ok (flatten names)
      | PsVerifiedIrExpr.record _ _ fields =>
          match psListMapExcept (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields with
          | Except.error error => Except.error error
          | Except.ok names => Except.ok (flatten names)
      | PsVerifiedIrExpr.projection _ _ value _ => visit value
      | PsVerifiedIrExpr.constructor _ _ _ fields =>
          match psListMapExcept (fun (field : Prod String PsVerifiedIrExpr) => visit field.snd) fields with
          | Except.error error => Except.error error
          | Except.ok names => Except.ok (flatten names)
      | PsVerifiedIrExpr.matchE _ _ value alternatives =>
          -- The former do block traversed branches before the scrutinee.
          let branch := fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
            match forEach (fun (binding : PsVerifiedIrMatchBinding) => safeName binding.name) alternative.snd.fst with
            | Except.error error => Except.error error
            | Except.ok _ => references remaining
                (psListAppend (psListMap (fun (binding : PsVerifiedIrMatchBinding) => binding.name) alternative.snd.fst) locals)
                alternative.snd.snd;
          match psListMapExcept branch alternatives with
          | Except.error error => Except.error error
          | Except.ok branches =>
              match visit value with
              | Except.error error => Except.error error
              | Except.ok first => Except.ok (psListAppend first (flatten branches))

def staticInitializer (fuel : Nat) : PsVerifiedIrExpr -> Bool :=
  match fuel with
  | Nat.zero => fun (_expression : PsVerifiedIrExpr) => false
  | Nat.succ remaining => fun (expression : PsVerifiedIrExpr) =>
      match expression with
      | PsVerifiedIrExpr.literal _ => true
      | PsVerifiedIrExpr.lambda _ _ _ => true
      | PsVerifiedIrExpr.constructor _ _ _ fields =>
          all (fun (field : Prod String PsVerifiedIrExpr) => staticInitializer remaining field.snd) fields
      | PsVerifiedIrExpr.record _ _ fields =>
          all (fun (field : Prod String PsVerifiedIrExpr) => staticInitializer remaining field.snd) fields
      | _ => false

def distinctImports (values : List PsModuleOwner) : List PsModuleOwner :=
  foldl (fun (acc : List PsModuleOwner) (item : PsModuleOwner) =>
    if psListAny (fun (previous : PsModuleOwner) => psStringEq previous.name item.name) acc then acc
    else psListAppend acc [item]) List.nil values

def unit (raw : PsVerifiedIrModule) (owners : List PsModuleOwner) (index : Nat) : Except String PsModuleUnit :=
  let assigned := fun (declaration : PsVerifiedIrDeclaration) =>
    match owner owners declaration.name with
    | Except.error error => Except.error error
    | Except.ok value => Except.ok (Nat.beq value.unit index);
  match filterExcept assigned raw.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations =>
      let referenced := fun (declaration : PsVerifiedIrDeclaration) =>
        match references 4096 (psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.name) declaration.parameters) declaration.body with
        | Except.error error => Except.error error
        | Except.ok names => psListMapExcept (owner owners) names;
      match psListMapExcept referenced declarations with
      | Except.error error => Except.error error
      | Except.ok references =>
          let imports := filter (fun (imported : PsModuleOwner) => !Nat.beq imported.unit index) (distinctImports (flatten references));
          if psListAny (fun (imported : PsModuleOwner) => Nat.ble index imported.unit) imports then
            Except.error "PSC1_MODULE_CYCLE_OR_ORDER"
          else Except.ok (PsModuleUnit.mk index declarations imports)

end Ps.Internal.ModuleGraph

-- Package identifiers are ASCII by contract, so the accepted slug's UTF-8 byte
-- length equals the native implementation's scalar length. Other input refuses.
def psModuleSlugCharacters (fuel : Nat) (name : String) (position : Nat) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
      if String.Internal.atEnd name (String.Pos.Raw.mk position) then true
      else
        let code := Char.toNat (String.Internal.get name (String.Pos.Raw.mk position));
        let allowed := (Nat.ble 97 code && Nat.ble code 122) ||
          (Nat.ble 48 code && Nat.ble code 57) || Nat.beq code 45;
        if allowed then psModuleSlugCharacters remaining name
          (String.Pos.Raw.byteIdx (String.Internal.next name (String.Pos.Raw.mk position)))
        else false

def psModulePackageSafe (name : String) : Bool :=
  Ps.Internal.ModuleGraph.startsWith name "@proofscript/modular-pilot-" &&
    Nat.ble (String.utf8ByteSize name) 141 &&
    psModuleSlugCharacters (Nat.succ (String.utf8ByteSize name)) name 13

namespace Ps.Internal.ModuleGraph

def checkPackage (packages : List String) (package : String) : Except String Unit :=
  if !psModulePackageSafe package ||
      !Nat.beq (psListLength (filter (fun (value : String) => psStringEq value package) packages)) 1 then
    Except.error "PSC1_MODULE_PACKAGE_IDENTITY"
  else Except.ok ()

def checkOwner (raw : PsVerifiedIrModule) (packageCount : Nat) (item : PsModuleOwner) : Except String Unit :=
  if Nat.ble packageCount item.unit ||
      !psListAny (fun (declaration : PsVerifiedIrDeclaration) => psStringEq declaration.name item.name) raw.declarations then
    Except.error "PSC1_MODULE_OWNER_COVERAGE"
  else Except.ok ()

def checkDeclaration (owners : List PsModuleOwner) (declaration : PsVerifiedIrDeclaration) : Except String Unit :=
  match safeName declaration.name with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match owner owners declaration.name with
      | Except.error error => Except.error error
      | Except.ok _ =>
          if !psListIsEmpty declaration.typeParameters then
            Except.error "PSC1_MODULE_GENERIC_VALUE_UNQUALIFIED"
          else
            match forEach (fun (parameter : PsVerifiedIrParameter) => safeName parameter.name) declaration.parameters with
            | Except.error error => Except.error error
            | Except.ok _ =>
                if psListIsEmpty declaration.parameters && !staticInitializer 4096 declaration.body then
                  Except.error (String.Internal.append "PSC1_MODULE_EAGER_INITIALIZER:" declaration.name)
                else Except.ok ()

def finishPlan (raw : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (packages : List String) (protocol : String) : Except String PsModulePlan :=
  if !psListIsEmpty raw.imports then Except.error "PSC1_MODULE_EXTERNAL_IMPORT"
  else if Nat.blt 256 (psListLength raw.declarations) ||
      Nat.blt 64 (Nat.add (psListLength raw.structures) (psListLength raw.inductives)) then
    Except.error "PSC1_MODULE_PILOT_BOUND"
  else if !Nat.beq (psListLength owners) (psListLength raw.declarations) then
    Except.error "PSC1_MODULE_OWNER_COVERAGE"
  else
    match forEach (checkOwner raw (psListLength packages)) owners with
    | Except.error error => Except.error error
    | Except.ok _ =>
        match forEach (checkDeclaration owners) raw.declarations with
        | Except.error error => Except.error error
        | Except.ok _ =>
            match psListMapExcept (unit raw owners) (rangeFrom (psListLength packages) 0) with
            | Except.error error => Except.error error
            | Except.ok units =>
                match forEach (fun (value : PsModuleUnit) =>
                  if psListIsEmpty value.declarations then Except.error "PSC1_MODULE_EMPTY_SOURCE_OWNER"
                  else Except.ok ()) (tail units) with
                | Except.error error => Except.error error
                | Except.ok _ => Except.ok (PsModulePlan.mk raw owners units packages protocol)

end Ps.Internal.ModuleGraph

def psPlanModulesWithPackages (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (packages : List String) (protocol : String) : Except String PsModulePlan :=
  let legacy := psStringEq protocol "psc1-modular-pilot/1";
  if !legacy && !psStringEq protocol "psc1-modular-pilot/2" then Except.error "PSC1_MODULE_PROFILE"
  else if Nat.blt (psListLength packages) 3 ||
      Nat.blt (if legacy then 3 else 9) (psListLength packages) then
    Except.error "PSC1_MODULE_UNIT_BOUND"
  else
    let runtime := match packages with
      | List.nil => false
      | List.cons value _ => psStringEq value "@proofscript/modular-pilot-runtime";
    if !runtime then Except.error "PSC1_MODULE_PACKAGE_RUNTIME"
    else
      match Ps.Internal.ModuleGraph.forEach (Ps.Internal.ModuleGraph.checkPackage packages) packages with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match psStrictValidateModule input with
          | Except.error _ => Except.error "PSC1_MODULE_STRICT_IR"
          | Except.ok validated => Ps.Internal.ModuleGraph.finishPlan validated.raw owners packages protocol

def psPlanModules (input : PsVerifiedIrModule) (owners : List PsModuleOwner) : Except String PsModulePlan :=
  psPlanModulesWithPackages input owners [
    "@proofscript/modular-pilot-runtime", "@proofscript/modular-pilot-names",
    "@proofscript/modular-pilot-consumer"] "psc1-modular-pilot/1"

structure PsModuleImport where
  source : String
  names : List String
  typeOnly : Bool

-- Lean record elaboration discovers this ordinary definition by its public name.
-- Keeping it explicit preserves omitted typeOnly fields in native callers.
def PsModuleImport.typeOnly._default : Bool := false

structure PsModuleArtifact where
  unit : Nat
  source : String
  declarations : String
  imports : List PsModuleImport
  exports : List String

def psModulePackage (index : Nat) : String :=
  if Nat.beq index 0 then "@proofscript/modular-pilot-runtime"
  else if Nat.beq index 1 then "@proofscript/modular-pilot-names"
  else "@proofscript/modular-pilot-consumer"

def psModuleSpecifier (index : Nat) (typed : Bool) : String :=
  String.Internal.append (psModulePackage index) (if typed then "/ts" else "")

def psModuleTypeNames (raw : PsVerifiedIrModule) : List String :=
  psListAppend (psListMap (fun (value : PsVerifiedIrStructure) => value.name) raw.structures)
    (psListMap (fun (value : PsVerifiedIrInductive) => value.name) raw.inductives)

def psModuleCohort (sourceDigest : String) (typed : Bool) : String :=
  String.Internal.append "psc1-modular-pilot/1:"
    (String.Internal.append (if typed then "ts:" else "js:") sourceDigest)

/-! Value ownership is carried only through complete producer-generated provenance.
Both raw modules are rechecked; metadata cannot authorize IR or prove a transform. -/

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

def psModuleEntityArity (raw : PsVerifiedIrModule) (kind : PsIrOriginKind) (name : String) : Except String Nat :=
  let entries := match kind with
    | PsIrOriginKind.structure => Ps.Internal.ModuleGraph.filterMap (fun (item : PsVerifiedIrStructure) =>
        if psStringEq item.name name then Option.some (psListLength item.typeParameters) else Option.none) raw.structures
    | PsIrOriginKind.inductive => Ps.Internal.ModuleGraph.filterMap (fun (item : PsVerifiedIrInductive) =>
        if psStringEq item.name name then Option.some (psListLength item.typeParameters) else Option.none) raw.inductives
    | PsIrOriginKind.declaration => Ps.Internal.ModuleGraph.filterMap (fun (item : PsVerifiedIrDeclaration) =>
        if psStringEq item.name name then Option.some (psListLength item.typeParameters) else Option.none) raw.declarations;
  match entries with
  | List.nil => Except.error (String.Internal.append "PSC1_MODULE_ORIGIN_ENTITY:" name)
  | List.cons arity rest =>
      if psListIsEmpty rest then Except.ok arity
      else Except.error (String.Internal.append "PSC1_MODULE_ORIGIN_ENTITY:" name)

def psModuleOriginFor (rows : List PsIrTransformOrigin) (kind : PsIrOriginKind) (name : String) : Except String PsIrTransformOrigin :=
  match Ps.Internal.ModuleGraph.filter (fun (row : PsIrTransformOrigin) =>
      psModuleOriginKindEqual row.kind kind && psStringEq row.outputName name) rows with
  | List.nil => Except.error (String.Internal.append "PSC1_MODULE_ORIGIN_COVERAGE:" name)
  | List.cons row rest =>
      if psListIsEmpty rest then Except.ok row
      else Except.error (String.Internal.append "PSC1_MODULE_ORIGIN_COVERAGE:" name)

namespace Ps.Internal.ModuleGraph

def checkInputOwner (owners : List PsModuleOwner) (declaration : PsVerifiedIrDeclaration) : Except String Unit :=
  match owner owners declaration.name with
  | Except.error error => Except.error error
  | Except.ok _ => Except.ok ()

def checkOrigin (input output : PsVerifiedIrModule) (row : PsIrTransformOrigin) : Except String Unit :=
  match psModuleEntityArity output row.kind row.outputName with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psModuleEntityArity input row.kind row.inputName with
      | Except.error error => Except.error error
      | Except.ok arity =>
          match row.rule with
          | PsIrOriginRule.retained =>
              if !psStringEq row.outputName row.inputName || !psListIsEmpty row.arguments then
                Except.error "PSC1_MODULE_ORIGIN_RETAINED"
              else Except.ok ()
          | PsIrOriginRule.specialization =>
              if !Nat.beq arity (psListLength row.arguments) || !psIrSpecializeAllGround row.arguments then
                Except.error "PSC1_MODULE_ORIGIN_ARGUMENTS"
              else
                match psIrSpecializedName row.inputName row.arguments with
                | Option.none => Except.error "PSC1_MODULE_ORIGIN_SPECIALIZATION"
                | Option.some name =>
                    if psStringEq name row.outputName then Except.ok ()
                    else Except.error "PSC1_MODULE_ORIGIN_SPECIALIZATION"
          | PsIrOriginRule.worker =>
              if !psModuleOriginKindEqual row.kind PsIrOriginKind.declaration || !psListIsEmpty row.arguments ||
                  psStringEq row.outputName row.inputName ||
                  psListAny (fun (declaration : PsVerifiedIrDeclaration) => psStringEq declaration.name row.outputName) input.declarations then
                Except.error "PSC1_MODULE_ORIGIN_WORKER"
              else Except.ok ()

def checkCoverage (rows : List PsIrTransformOrigin) (kind : PsIrOriginKind) (name : String) : Except String Unit :=
  match psModuleOriginFor rows kind name with
  | Except.error error => Except.error error
  | Except.ok _ => Except.ok ()

def carryOutputOwner (owners : List PsModuleOwner) (rows : List PsIrTransformOrigin)
    (declaration : PsVerifiedIrDeclaration) : Except String PsModuleOwner :=
  match psModuleOriginFor rows PsIrOriginKind.declaration declaration.name with
  | Except.error error => Except.error error
  | Except.ok row =>
      match owner owners row.inputName with
      | Except.error error => Except.error error
      | Except.ok previous => Except.ok (PsModuleOwner.mk declaration.name previous.unit)

def carryCheckedOwners (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (output : PsIrTracedModule) : Except String (List PsModuleOwner) :=
  if !Nat.beq (psListLength owners) (psListLength input.declarations) then
    Except.error "PSC1_MODULE_ORIGIN_INPUT_OWNERS"
  else
    match forEach (checkInputOwner owners) input.declarations with
    | Except.error error => Except.error error
    | Except.ok _ =>
        let count := Nat.add (Nat.add (psListLength output.raw.structures) (psListLength output.raw.inductives))
          (psListLength output.raw.declarations);
        if !Nat.beq (psListLength output.origins) count then Except.error "PSC1_MODULE_ORIGIN_COVERAGE"
        else
          match forEach (checkOrigin input output.raw) output.origins with
          | Except.error error => Except.error error
          | Except.ok _ =>
              match forEach (fun (item : PsVerifiedIrStructure) =>
                checkCoverage output.origins PsIrOriginKind.structure item.name) output.raw.structures with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  match forEach (fun (item : PsVerifiedIrInductive) =>
                    checkCoverage output.origins PsIrOriginKind.inductive item.name) output.raw.inductives with
                  | Except.error error => Except.error error
                  | Except.ok _ => psListMapExcept (carryOutputOwner owners output.origins) output.raw.declarations

end Ps.Internal.ModuleGraph

def psModuleCarryOwners (input : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (output : PsIrTracedModule) : Except String (List PsModuleOwner) :=
  match psStrictValidateModule input with
  | Except.error _ => Except.error "PSC1_MODULE_ORIGIN_INPUT_IR"
  | Except.ok _ =>
      match psStrictValidateModule output.raw with
      | Except.error _ => Except.error "PSC1_MODULE_ORIGIN_OUTPUT_IR"
      | Except.ok _ => Ps.Internal.ModuleGraph.carryCheckedOwners input owners output

def psModuleSpecifierFor (plan : PsModulePlan) (index : Nat) (typed : Bool) : String :=
  String.Internal.append (Ps.Internal.ModuleGraph.atD plan.packages index "invalid-module-index")
    (if typed then "/ts" else "")

def psModuleSourceIndices (plan : PsModulePlan) : List Nat :=
  Ps.Internal.ModuleGraph.tail (Ps.Internal.ModuleGraph.rangeFrom (psListLength plan.packages) 0)

def psModuleCohortFor (plan : PsModulePlan) (sourceDigest : String) (typed : Bool) : String :=
  String.Internal.append plan.protocol
    (String.Internal.append ":" (String.Internal.append (if typed then "ts:" else "js:") sourceDigest))
