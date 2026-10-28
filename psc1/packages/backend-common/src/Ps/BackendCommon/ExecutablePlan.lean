import Ps.BackendCommon.ModuleModel
import Ps.Foundation.StringMap

/-! Portable production ESM planning. The native reference remains an oracle.
All producer ownership, original/transformed IR, transitive initializer checks
and the existing finite bounds remain. Container operations are explicit. -/
namespace Ps.Internal.ExecutablePlan

def ensure (condition : Bool) (code : String) : Except String Unit :=
  if condition then Except.ok () else Except.error code

def early (declaration : PsVerifiedIrDeclaration) : Bool :=
  !psListIsEmpty declaration.parameters ||
    Ps.Internal.ModuleGraph.staticInitializer 4096 declaration.body

def getDefault {alpha : Type} (index : PsStringMap alpha) (key : String)
    (fallback : alpha) : alpha :=
  match psStringMapGet index key with
  | Option.some value => value
  | Option.none => fallback

def visitDependencies (fuel : Nat) (references : PsStringMap (List String))
    (late : PsStringSet) (pending : List String) (visited : PsStringSet)
    (result : List String) : Except String (List String) :=
  match fuel with
  | Nat.zero =>
    if psListIsEmpty pending then Except.ok result
    else Except.error "PSC1_EXECUTABLE_INITIALIZER_EDGE_BOUND"
  | Nat.succ remaining =>
    match pending with
    | [] => Except.ok result
    | name :: rest =>
      if psStringSetContains visited name then
        visitDependencies remaining references late rest visited result
      else
        let next := psStringSetInsert visited name;
        if psStringSetContains late name then
          visitDependencies remaining references late rest next (List.cons name result)
        else match psStringMapGet references name with
          | Option.none => Except.error (String.Internal.append "PSC1_EXECUTABLE_UNKNOWN_REFERENCE:" name)
          | Option.some refs =>
            visitDependencies remaining references late (psListAppend refs rest) next result

def dependencies (start : String) (references : PsStringMap (List String))
    (late : PsStringSet) : Except String (List String) :=
  visitDependencies 131072 references late (getDefault references start []) PsStringSet.empty []

def installInitializers (fuel : Nat) (pending : List PsVerifiedIrDeclaration)
    (requirements : PsStringMap (List String)) (installed : PsStringSet)
    (ordered : List PsVerifiedIrDeclaration) : Except String (List PsVerifiedIrDeclaration) :=
  match fuel with
  | Nat.zero =>
    if psListIsEmpty pending then Except.ok (psListReverse ordered)
    else Except.error "PSC1_EXECUTABLE_INITIALIZER_ORDER_BOUND"
  | Nat.succ remaining =>
    if psListIsEmpty pending then Except.ok (psListReverse ordered)
    else do
      let found := psListFind (fun (item : PsVerifiedIrDeclaration) =>
        psListAll (psStringSetContains installed) (getDefault requirements item.name [])) pending
      match found with
      | Option.none => throw (String.Internal.append "PSC1_EXECUTABLE_INITIALIZER_CYCLE:"
          (psTextJoin "," (psListMap (fun (d : PsVerifiedIrDeclaration) => d.name) (psListTake 8 pending))))
      | Option.some item =>
        installInitializers remaining
          (psListFilter (fun (other : PsVerifiedIrDeclaration) => !psStringEq other.name item.name) pending)
          requirements (psStringSetInsert installed item.name) (List.cons item ordered)

def orderInitializers (declarations : List PsVerifiedIrDeclaration)
    (references : PsStringMap (List String)) :
    Except String (List PsVerifiedIrDeclaration) := do
  let ready := psListFilter early declarations
  let pending := psListFilter (fun (item : PsVerifiedIrDeclaration) => !early item) declarations
  let late := psStringSetFromList (psListMap (fun (item : PsVerifiedIrDeclaration) => item.name) pending)
  let mut requirements : PsStringMap (List String) := PsStringMap.empty
  for item in pending do
    let required ← dependencies item.name references late
    requirements := psStringMapPut requirements item.name required
  let installed ← installInitializers (psListLength pending) pending requirements PsStringSet.empty []
  return psListAppend ready installed

def asciiAlphaNumeric (c : Char) : Bool :=
  let n := Char.toNat c;
  (Nat.ble 97 n && Nat.ble n 122) || (Nat.ble 65 n && Nat.ble n 90) ||
    (Nat.ble 48 n && Nat.ble n 57)

def slashParts (fuel : Nat) (text : String) (position start : Nat)
    (parts : List String) : List String :=
  match fuel with
  | Nat.zero => []
  | Nat.succ remaining =>
    let current := String.Pos.Raw.mk position;
    if String.Internal.atEnd text current then
      psListReverse (List.cons
        (String.Internal.extract text (String.Pos.Raw.mk start) current) parts)
    else
      let next := String.Pos.Raw.byteIdx (String.Internal.next text current);
      if Nat.beq (Char.toNat (String.Internal.get text current)) 47 then
        slashParts remaining text next next (List.cons
          (String.Internal.extract text (String.Pos.Raw.mk start) current) parts)
      else slashParts remaining text next start parts

def validCharacters (fuel : Nat) (text : String) (position : Nat) (package : Bool) : Bool :=
  match fuel with
  | Nat.zero => false
  | Nat.succ remaining =>
    let current := String.Pos.Raw.mk position;
    if String.Internal.atEnd text current then true
    else
      let c := String.Internal.get text current;
      let n := Char.toNat c;
      let accepted := if package then
          (Nat.ble 97 n && Nat.ble n 122) || (Nat.ble 48 n && Nat.ble n 57) || Nat.beq n 45
        else asciiAlphaNumeric c || Nat.beq n 46 || Nat.beq n 95 || Nat.beq n 45;
      if accepted then validCharacters remaining text
        (String.Pos.Raw.byteIdx (String.Internal.next text current)) package else false

def specifierSafe (specifier : String) : Bool :=
  match slashParts (Nat.succ (String.utf8ByteSize specifier)) specifier 0 0 [] with
  | [scope, package, folder, name] =>
    psStringEq scope "@proofscript" && psStringEq folder "generated" &&
      !(Nat.beq (String.utf8ByteSize package) 0) && !(Nat.beq (String.utf8ByteSize name) 0) &&
      !(Nat.beq (Char.toNat (String.Internal.get name (String.Pos.Raw.mk 0))) 46) &&
      validCharacters (Nat.succ (String.utf8ByteSize package)) package 0 true &&
      validCharacters (Nat.succ (String.utf8ByteSize name)) name 0 false
  | _ => false

def rangeWorker (fuel index : Nat) : List Nat :=
  match fuel with
  | Nat.zero => []
  | Nat.succ remaining => List.cons index (rangeWorker remaining (Nat.succ index))

def range (count : Nat) : List Nat := rangeWorker count 0

def mappedUnit (mapping : List (Prod Nat Nat)) (source : Nat) : Except String Nat :=
  match mapping with
  | [] => Except.error "PSC1_EXECUTABLE_OWNER_MISSING"
  | row :: rest => if Nat.beq row.fst source then Except.ok row.snd else mappedUnit rest source

def natSeen (value : Nat) (values : List Nat) : Bool :=
  psListAny (fun (item : Nat) => Nat.beq item value) values

def orderUnits (fuel : Nat) (pending ordered : List Nat)
    (references : PsStringMap (List PsModuleOwner))
    (mapping : List (Prod Nat Nat)) : Except String (Prod (List Nat) (List (Prod Nat Nat))) :=
  match fuel with
  | Nat.zero =>
    if psListIsEmpty pending then Except.ok (Prod.mk ordered mapping)
    else Except.error "PSC1_EXECUTABLE_ORDER_BOUND"
  | Nat.succ remaining =>
    if psListIsEmpty pending then Except.ok (Prod.mk ordered mapping)
    else do
      let found := psListFind (fun (source : Nat) =>
        psListAll (fun (dependency : PsModuleOwner) => natSeen dependency.unit ordered)
          (getDefault references (psNatToString source) [])) pending
      match found with
      | Option.none => throw "PSC1_EXECUTABLE_CROSS_SOURCE_CYCLE"
      | Option.some source =>
        orderUnits remaining (psListFilter (fun (item : Nat) => !(Nat.beq item source)) pending)
          (psListAppend ordered [source]) references
          (List.cons (Prod.mk source (psListLength ordered)) mapping)

def buildUnits (ordered : List Nat) (unit : Nat)
    (references : PsStringMap (List PsModuleOwner))
    (buckets : PsStringMap (List PsVerifiedIrDeclaration))
    (byName : PsStringMap (List String)) (mapping : List (Prod Nat Nat)) :
    Except String (List PsModuleUnit) := do
  match ordered with
  | [] => return []
  | source :: rest =>
    let mut seen : PsStringSet := PsStringSet.empty
    let mut imports : List PsModuleOwner := []
    for ref in psListReverse (getDefault references (psNatToString source) []) do
      let assigned ← mappedUnit mapping ref.unit
      ensure (Nat.blt assigned unit) "PSC1_EXECUTABLE_CYCLE_OR_ORDER"
      if !psStringSetContains seen ref.name then
        seen := psStringSetInsert seen ref.name
        imports := List.cons (PsModuleOwner.mk ref.name assigned) imports
    let declarations ← orderInitializers
      (psListReverse (getDefault buckets (psNatToString source) [])) byName
    let next ← buildUnits rest (Nat.succ unit) references buckets byName mapping
    return List.cons (PsModuleUnit.mk unit declarations (psListReverse imports)) next

def plan (raw : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (specifiers : List String) : Except String (PsModulePlan × List Nat) := do
  let _ ← psExceptMapError (fun _ => "PSC1_EXECUTABLE_STRICT_IR") (psStrictValidateModule raw)
  ensure (psListIsEmpty raw.imports && Nat.ble (psListLength raw.declarations) 8192 &&
    Nat.ble (psListLength raw.structures + psListLength raw.inductives) 2048) "PSC1_EXECUTABLE_IR_BOUND"
  ensure (Nat.ble 2 (psListLength specifiers) && Nat.ble (psListLength specifiers) 257)
    "PSC1_EXECUTABLE_SOURCE_BOUND"
  let runtimeCorrect := match psListHeadOption specifiers with
    | Option.some value => psStringEq value "@proofscript/foundation/generated/runtime"
    | Option.none => false
  ensure runtimeCorrect "PSC1_EXECUTABLE_RUNTIME_OWNER"
  let mut used : PsStringSet := PsStringSet.empty
  for specifier in specifiers do
    ensure (specifierSafe specifier) "PSC1_EXECUTABLE_SPECIFIER"
    ensure (!psStringSetContains used specifier) "PSC1_EXECUTABLE_SPECIFIER_UNIQUE"
    used := psStringSetInsert used specifier
  ensure (Nat.beq (psListLength owners) (psListLength raw.declarations)) "PSC1_EXECUTABLE_OWNER_COVERAGE"
  let mut index : PsStringMap Nat := PsStringMap.empty
  for owner in owners do
    ensure (Nat.blt owner.unit (psListLength specifiers) && !psStringMapContains index owner.name)
      "PSC1_EXECUTABLE_OWNER_UNIQUE"
    index := psStringMapPut index owner.name owner.unit
  let mut buckets : PsStringMap (List PsVerifiedIrDeclaration) := PsStringMap.empty
  let mut references : PsStringMap (List PsModuleOwner) := PsStringMap.empty
  let mut byName : PsStringMap (List String) := PsStringMap.empty
  for declaration in raw.declarations do
    Ps.Internal.ModuleGraph.safeName declaration.name
    let unit ← match psStringMapGet index declaration.name with
      | Option.some value => Except.ok value
      | Option.none => Except.error "PSC1_EXECUTABLE_OWNER_MISSING"
    ensure (psListIsEmpty declaration.typeParameters) "PSC1_EXECUTABLE_OPEN_VALUE"
    for parameter in declaration.parameters do Ps.Internal.ModuleGraph.safeName parameter.name
    let key := psNatToString unit
    buckets := psStringMapPut buckets key (List.cons declaration (getDefault buckets key []))
    let refs ← Ps.Internal.ModuleGraph.references 4096
      (psListMap (fun (p : PsVerifiedIrParameter) => p.name) declaration.parameters) declaration.body
    byName := psStringMapPut byName declaration.name refs
    for name in refs do
      let assigned ← match psStringMapGet index name with
        | Option.some value => Except.ok value
        | Option.none => Except.error (String.Internal.append "PSC1_EXECUTABLE_UNKNOWN_REFERENCE:" name)
      if !(Nat.beq assigned unit) then
        references := psStringMapPut references key
          (List.cons (PsModuleOwner.mk name assigned) (getDefault references key []))
  ensure (psListIsEmpty (getDefault references "0" [])) "PSC1_EXECUTABLE_RUNTIME_DEPENDENCY"
  let ordering ← orderUnits (psListLength specifiers) (psListTail (range (psListLength specifiers)))
    [0] references [Prod.mk 0 0]
  let ordered := ordering.fst
  let mapping := ordering.snd
  let remapped ← psListMapExcept (fun (owner : PsModuleOwner) => do
    let assigned ← mappedUnit mapping owner.unit
    return PsModuleOwner.mk owner.name assigned) owners
  let units ← buildUnits ordered 0 references buckets byName mapping
  let packages ← psListMapExcept (fun (source : Nat) =>
    match psListGetOption specifiers source with
    | Option.some value => Except.ok value
    | Option.none => Except.error "PSC1_EXECUTABLE_SOURCE_BOUND") ordered
  let sourceToUnit ← psListMapExcept (mappedUnit mapping) (range (psListLength specifiers))
  return Prod.mk (PsModulePlan.mk raw remapped units packages "psc1-executable-compiler/1") sourceToUnit

end Ps.Internal.ExecutablePlan

