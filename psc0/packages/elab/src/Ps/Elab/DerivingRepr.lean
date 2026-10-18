/-
Repr deriving adapted from Lean 4.35.0 Lean/Elab/Deriving/Repr.lean.
Copyright (c) 2020 Microsoft Corporation. All rights reserved.
Author: Leonardo de Moura. Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: checked Core construction for independent fields and complete uniform
visible/nested groups, including each member's own index telescope. Selected
containers preserve native formatting through heterogeneous checked motives.
-/
import Ps.Elab.DerivingContext
import Ps.Environment.StandardRepr

structure PsElabDeriveReprConstructor where
  fields : PsElabDeriveFields
  printers : List (Option PsExpr)

-- Plan independent dictionaries once in the parameter telescope. A direct
-- recursive field obtains its printer from the checked recursor minor, never
-- from an assumed self instance. Types/proofs and hidden inductive fields
-- retain the existing underscore/omission behavior.
def psElabDeriveReprPlan (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveReprConstructor := do
  let fields ← psElabDeriveFieldsWithRecursion plan name (!plan.info.isStructure)
  let printers ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof || (!plan.info.isStructure && !psBinderInfoEq field.binder .explicit) then return none
    if fields.directRecursiveFields.contains index then return none
    match psWhnf plan.context.environment plan.context.metaContext
        plan.context.localContext field.type with
    | .sortE _ => return none
    | _ => pure ()
    let target ← psElabDeriveClassType plan.context (psRootName "Repr") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return some (psExprApplyMany (.constE (psDecisionName "Repr.reprPrec") levels)
      [field.type, dictionary])
  return { fields, printers }

def psElabDeriveReprField (printer : Option PsExpr) (value : PsExpr)
    (precedence : Nat) : PsExpr :=
  match printer with
  | none => psReprText "_"
  | some printer => psExprApplyMany printer [value, psFormatNat precedence]

def psElabDeriveReprStructure (plan : PsElabDeriveContext)
    (constructor : PsElabDeriveReprConstructor) : Except PsElabError PsExpr := do
  let id := plan.context.localContext.nextId
  let append := fun a b => psFormatCall "append" [a, b]
  let fields := (constructor.fields.fields.zip constructor.printers).zipIdx
  let body := fields.foldl (fun acc ((field, printer), index) =>
    let label := psNameLastComponent field.name
    let value := psElabDeriveReprField printer (.proj plan.info.name index (.fvar id)) 0
    let value := match printer with
      | none => value
      | some _ => psFormatCall "group"
          [psFormatCall "nest" [psFormatInt (psFormatNat (label.length + 4)), value],
           psFormatBehavior]
    let acc := if index == 0 then acc else append (append acc (psReprText ",")) (psFormatCall "line")
    append (append (append acc (psReprText label)) (psReprText " := ")) value) (psFormatCall "nil")
  return psLogicLam id "value" plan.family (psLogicLam (id + 1) "prec" psOrderNat
    (psFormatCall "bracket" [.lit (.string "{ "), body, .lit (.string " }")]))

structure PsElabDeriveReprSlotConstructor where
  slotIndex : Nat
  fields : PsElabDeriveFields
  printers : List (Option PsExpr)
  tuples : List (Option PsExpr)

def psElabDeriveReprIsListSlot (slot : PsInductiveEliminationSlot) : Bool :=
  !slot.publicMember && psNameEq slot.family.name psListName

def psElabDeriveReprIsProdSlot (slot : PsInductiveEliminationSlot) : Bool :=
  !slot.publicMember && psNameEq slot.family.name psProdName

def psElabDeriveReprDocuments : PsExpr :=
  psSelfHostListOf psFormatType

def psElabDeriveReprSlotResult (slot : PsInductiveEliminationSlot) : PsExpr :=
  if psElabDeriveReprIsListSlot slot then psElabDeriveReprDocuments
  else if psElabDeriveReprIsProdSlot slot then
    .forallE (psRootName "tail") psElabDeriveReprDocuments psElabDeriveReprDocuments .explicit
  else .forallE (psRootName "prec") psOrderNat psFormatType .explicit

-- Native List chooses bracketFill only when a checked ReprAtom marker is
-- available for its actual element type. Repr requirements do not fabricate
-- such a marker, and no recursive Repr dictionary is needed for this choice.
def psElabDeriveReprAtomicList (plan : PsElabDeriveContext)
    (slot : PsInductiveEliminationSlot) : Except PsElabError Bool := do
  if !psElabDeriveReprIsListSlot slot then return false
  let some specialized := psInductiveEliminationInstantiate plan.elimination
      (plan.info.levelParams.map PsLevel.param) (psElabBinderArguments plan.parametersRev) slot.typeFormer
    | throw (.data "Repr List specialization is absent")
  let view := psExprAppView specialized
  let [element] := view.args | throw (.data "Repr List specialization has the wrong parameters")
  let target ← psElabDeriveClassType plan.context (psRootName "ReprAtom") element
  match psElabDeriveInstance plan.context target with
  | .ok _ => return true
  | .error _ => return false

def psElabDeriveReprPlanSlot (plan : PsElabDeriveContext) (slotIndex : Nat)
    (slot : PsInductiveEliminationSlot) (constructor : PsInductiveEliminationConstructor) :
    Except PsElabError PsElabDeriveReprSlotConstructor := do
  let fields ← psElabDeriveSlotFields plan slot constructor
  let recursive := fun (index : Nat) => fields.directRecursiveFields.contains index
  let tupleField := fun (index : Nat) => psElabDeriveReprIsProdSlot slot && index == 1
  let printers ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof || recursive index || tupleField index ||
        (slot.publicMember && !psBinderInfoEq field.binder .explicit) then return none
    match psWhnf plan.context.environment plan.context.metaContext plan.context.localContext field.type with
    | .sortE _ => return none
    | _ => pure ()
    let target ← psElabDeriveClassType plan.context (psRootName "Repr") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return some (psExprApplyMany (.constE (psDecisionName "Repr.reprPrec") levels)
      [field.type, dictionary])
  let tuples ← fields.fields.zipIdx.mapM fun (field, index) => do
    if recursive index || !tupleField index then return none
    let target ← psElabDeriveClassType plan.context (psRootName "ReprTuple") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return some (psExprApplyMany (.constE (psDecisionName "ReprTuple.reprTuple") levels)
      [field.type, dictionary])
  return { slotIndex, fields, printers, tuples }

def psElabDeriveReprJoin (documents : PsExpr) : PsExpr :=
  let identity := psFormatClassValue "Std.ToFormat" psFormatType
    (.lam .anonymous psFormatType (.bvar 0) .explicit)
  psExprApplyMany (.constE (psDecisionName "Std.Format.joinSep") [.zero])
    [psFormatType, identity, documents,
     psFormatCall "append" [psReprText ",", psFormatCall "line"]]

-- Store already-rendered element documents in the List motive. A case-only
-- List.rec distinguishes the native empty spelling; joinSep keeps its native
-- left-to-right document association and bracket/bracketFill layout policy.
def psElabDeriveReprListDocument (documents : PsExpr) (atomic : Bool)
    (opening : String := "[") : PsExpr :=
  let document := psFormatCall (if atomic then "bracketFill" else "bracket")
    [.lit (.string opening), psElabDeriveReprJoin documents, .lit (.string "]")]
  let step := PsExpr.lam (psRootName "head") psFormatType
    (.lam (psRootName "tail") psElabDeriveReprDocuments
      (.lam (psRootName "unused") psFormatType (psExprLiftBVars 3 0 document) .explicit) .explicit) .explicit
  psExprApplyMany (.constE psSelfHostListRecName [.succ .zero, .zero])
    [psFormatType, .lam .anonymous psElabDeriveReprDocuments psFormatType .explicit,
     psReprText (opening ++ "]"), step, documents]

def psElabDeriveReprTupleDocument (tuple : PsExpr) : PsExpr :=
  let gathered := PsExpr.app tuple (psSelfHostListNilOf psFormatType)
  let documents := psStandardListCall "reverse" [psFormatType, gathered]
  psFormatCall "bracket"
    [.lit (.string "("), psElabDeriveReprJoin documents, .lit (.string ")")]

def psElabDeriveReprHypothesis (plan : PsElabDeriveContext) (atomic : List Bool)
    (hypothesis : PsElabDeriveHypothesis) (precedence : Nat) : Except PsElabError PsExpr := do
  let some target := plan.elimination.slots[hypothesis.target]?
    | throw (.data "Repr deriving hypothesis target slot is absent")
  if psElabDeriveReprIsListSlot target then
    let some marker := atomic[hypothesis.target]?
      | throw (.data "Repr deriving List marker plan is absent")
    return psElabDeriveReprListDocument hypothesis.value marker
  else if psElabDeriveReprIsProdSlot target then
    return psElabDeriveReprTupleDocument hypothesis.value
  else return .app hypothesis.value (psFormatNat precedence)

def psElabDeriveReprSlotField (plan : PsElabDeriveContext) (atomic : List Bool)
    (entry : PsElabDeriveReprSlotConstructor)
    (fields : List PsElabTypedBinder) (hypotheses : List PsElabDeriveHypothesis)
    (index precedence : Nat) : Except PsElabError PsExpr := do
  let some field := fields[index]? | throw (.data "Repr deriving field alignment mismatch")
  if entry.fields.directRecursiveFields.contains index then
    let some hypothesis := hypotheses.find? (fun hypothesis => hypothesis.fieldId == field.id)
      | throw (.data "Repr deriving recursive field has no checked induction printer")
    psElabDeriveReprHypothesis plan atomic hypothesis precedence
  else
    let some printer := entry.printers[index]?
      | throw (.data "Repr deriving field alignment mismatch")
    return psElabDeriveReprField printer (.fvar field.id) precedence

def psElabDeriveReprPublicBranch (plan : PsElabDeriveContext) (atomic : List Bool)
    (context : PsElabContext) (entry : PsElabDeriveReprSlotConstructor)
    (constructor : PsInductiveEliminationConstructor) (fields : List PsElabTypedBinder)
    (hypotheses : List PsElabDeriveHypothesis) : Except PsElabError PsExpr := do
  if entry.printers.length != fields.length then throw (.data "Repr deriving field alignment mismatch")
  let append := fun a b => psFormatCall "append" [a, b]
  let body ← fields.zipIdx.foldlM (fun acc (field, index) => do
    if !psBinderInfoEq field.binder .explicit then return acc
    let rendered ← psElabDeriveReprSlotField plan atomic entry fields hypotheses index 1024
    return append (append acc (psFormatCall "line")) rendered)
    (psReprText (psNameToString constructor.info.name))
  let id := context.localContext.nextId
  let indent := psFormatIf psOrderNat
    (psOrderCall "Nat.ble" [psFormatNat 1024, .fvar id]) (psFormatNat 1) (psFormatNat 2)
  let document := psFormatCall "group"
    [psFormatCall "nest" [psFormatInt indent, body], psFormatBehavior]
  return psLogicLam id "prec" psOrderNat (psReprAddAppParen document (.fvar id))

def psElabDeriveReprContainerBranch (plan : PsElabDeriveContext) (atomic : List Bool)
    (context : PsElabContext) (slotIndex : Nat) (slot : PsInductiveEliminationSlot)
    (entry : PsElabDeriveReprSlotConstructor) (constructor : PsInductiveEliminationConstructor)
    (fields : List PsElabTypedBinder) (hypotheses : List PsElabDeriveHypothesis) :
    Except PsElabError PsExpr := do
  if psElabDeriveReprIsListSlot slot then
    match fields with
    | [] => return psSelfHostListNilOf psFormatType
    | [_, tail] =>
      let head ← psElabDeriveReprSlotField plan atomic entry fields hypotheses 0 0
      let some rest := hypotheses.find? (fun hypothesis => hypothesis.fieldId == tail.id)
        | throw (.data "Repr List tail has no checked document hypothesis")
      if rest.target != slotIndex then throw (.data "Repr List tail targets another specialization")
      return psSelfHostListConsOf psFormatType head rest.value
    | _ => throw (.data "Repr List constructor telescope mismatch")
  else if psElabDeriveReprIsProdSlot slot then
    let [_, right] := fields | throw (.data "Repr Prod constructor telescope mismatch")
    let first ← psElabDeriveReprSlotField plan atomic entry fields hypotheses 0 0
    let id := context.localContext.nextId
    let initial := psSelfHostListConsOf psFormatType first (.fvar id)
    -- This bound do-if shares the enclosing return continuation. Yield its
    -- body with pure so every path reaches the accumulator lambda below.
    let body ←
      if let some child := hypotheses.find? (fun hypothesis => hypothesis.fieldId == right.id) then do
        let some target := plan.elimination.slots[child.target]?
          | throw (.data "Repr Prod right target slot is absent")
        if psElabDeriveReprIsProdSlot target then pure (PsExpr.app child.value initial)
        else
          let rendered ← psElabDeriveReprHypothesis plan atomic child 0
          pure (psSelfHostListConsOf psFormatType rendered initial)
      else do
        let some (some tuple) := entry.tuples[1]?
          | throw (.data "Repr Prod right field has no checked tuple dictionary")
        pure (psExprApplyMany tuple [.fvar right.id, initial])
    return psLogicLam id "tail" psElabDeriveReprDocuments body
  else if psNameEq slot.family.name psArrayName then
    let [field] := fields | throw (.data "Repr Array constructor telescope mismatch")
    let some child := hypotheses.find? (fun hypothesis => hypothesis.fieldId == field.id)
      | throw (.data "Repr Array field has no checked List hypothesis")
    let some target := plan.elimination.slots[child.target]?
      | throw (.data "Repr Array field target slot is absent")
    if !psElabDeriveReprIsListSlot target then
      throw (.data "Repr Array field does not target its List specialization")
    return psLogicLam context.localContext.nextId "prec" psOrderNat
      (psElabDeriveReprListDocument child.value true "#[")
  else if psNameEq slot.family.name psOptionName then
    let id := context.localContext.nextId
    match fields with
    | [] => return psLogicLam id "prec" psOrderNat (psReprText "none")
    | [_] =>
      let rendered ← psElabDeriveReprSlotField plan atomic entry fields hypotheses 0 1024
      let body := psReprAddAppParen
        (psFormatCall "append" [psReprText "some ", rendered]) (.fvar id)
      return psLogicLam id "prec" psOrderNat body
    | _ => throw (.data "Repr Option constructor telescope mismatch")
  else throw (.data "Repr deriving has no selected container policy")

def psElabDeriveReprInductive (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveReprSlotConstructor) (atomic : List Bool)
    (diagnose : PsElabRecursorArgumentDiagnostic := fun _ error => error) :
    Except PsElabError PsExpr :=
  psElabDeriveEliminateSlots plan plan.context true
    (fun _ slot _ _ => psElabDeriveReprSlotResult slot)
    (fun context slotIndex slot constructor fields hypotheses _ => do
      let some entry := constructors.find? (fun candidate => candidate.slotIndex == slotIndex &&
          psNameEq candidate.fields.constructor.name constructor.info.name)
        | throw (.data "Repr deriving constructor plan missing")
      if slot.publicMember then
        psElabDeriveReprPublicBranch plan atomic context entry constructor fields hypotheses
      else
        psElabDeriveReprContainerBranch plan atomic context slotIndex slot entry constructor fields hypotheses)
    diagnose

def psElabDeriveRepr (environment : PsEnvironment)
    (origin : PsElabBatchOrigin)
    (diagnose : PsElabRecursorArgumentDiagnostic := fun _ error => error) :
    Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin { groups := true, indices := true, nested := true }
  let plan := psElabDeriveRequirements plan (psRootName "Repr")
  let type ← psElabDeriveClassType plan.context (psRootName "Repr") plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let method ← if plan.info.isStructure then do
      let constructors ← (psElabDeriveConstructorNames plan).mapM (psElabDeriveReprPlan plan)
      match constructors with
      | [constructor] => psElabDeriveReprStructure plan constructor
      | _ => throw (.data "Repr deriving structure must have one constructor")
    else do
      let constructors ← plan.elimination.slots.zipIdx.mapM fun (slot, index) =>
        slot.constructors.mapM (psElabDeriveReprPlanSlot plan index slot)
      let atomic ← plan.elimination.slots.mapM (psElabDeriveReprAtomicList plan)
      psElabDeriveReprInductive plan constructors.flatten atomic diagnose
  let value := psExprApplyMany (.constE (psDecisionName "Repr.mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instRepr" type value

