/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/BEq.lean at eb6cafb.
Copyright (c) 2020 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: checked Core induction for complete uniform nonindexed groups,
including selected nested containers. No partial fallback or assumed self
dictionary. Independent runtime fields retain the shared admissibility boundary.
-/
import Ps.Elab.DerivingContext

-- Distinguish erased proof fields, independent dictionaries and actual child
-- induction evidence. A missing dictionary can never masquerade as recursion.
inductive PsElabDeriveBEqField where
  | erased
  | independent (compare : PsExpr)
  | recursive

structure PsElabDeriveBEqConstructor where
  fields : PsElabDeriveFields
  comparisons : List PsElabDeriveBEqField

def psElabDeriveBEqPlanConstructor (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveBEqConstructor := do
  let fields ← psElabDeriveFieldsWithRecursion plan name true
  let comparisons ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof then return PsElabDeriveBEqField.erased
    if fields.constructor.recursiveFields.contains index then
      return PsElabDeriveBEqField.recursive
    let target ← psElabDeriveClassType plan.context (psRootName "BEq") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return PsElabDeriveBEqField.independent
      (psExprApplyMany (.constE (psNameAppendStr (psRootName "BEq") "beq") levels)
        [field.type, dictionary])
  return { fields, comparisons }

def psElabDeriveBEqCompare (comparisons : List PsElabDeriveBEqField)
    (left right : List PsExpr) (hypotheses : List (Nat × PsExpr) := []) :
    Except PsElabError PsExpr := do
  if comparisons.length != left.length || comparisons.length != right.length then
    throw (.data "BEq deriving field alignment mismatch")
  let values ← ((comparisons.zip left).zip right).mapM fun ((compare, lhs), rhs) => do
    match compare with
    | .erased => return none
    | .independent compare => return some (psExprApplyMany compare [lhs, rhs])
    | .recursive =>
      let .fvar id := lhs | throw (.data "BEq deriving recursive field is not a local")
      let some (_, compare) := hypotheses.find? (fun entry => entry.fst == id)
        | throw (.data "BEq deriving recursive field has no checked induction hypothesis")
      -- The shared eliminator checked this hypothesis at its child family -> Bool.
      -- It already fixes the left child; only the matching right child remains.
      return some (PsExpr.app compare rhs)
  let bool := PsExpr.constE psBoolName []
  let motive := PsExpr.lam .anonymous bool bool .explicit
  return values.foldl (fun previous current =>
    match current with
    | none => previous
    | some current => psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
        [motive, .constE psBoolFalseName [], current, previous]) (.constE psBoolTrueName [])

-- Structures retain direct projections and the independently planned fields.
def psElabDeriveBEqStructure (plan : PsElabDeriveContext)
    (constructor : PsElabDeriveBEqConstructor) : Except PsElabError PsExpr := do
  let left := psLocalPushBinding plan.context.localContext (psRootName "left") plan.family .explicit
  let right := psLocalPushBinding left.context (psRootName "right") plan.family .explicit
  let fields := List.range constructor.fields.constructor.numFields
  let body ← psElabDeriveBEqCompare constructor.comparisons
    (fields.map fun i => .proj plan.info.name i (.fvar left.id))
    (fields.map fun i => .proj plan.info.name i (.fvar right.id))
  return psLogicLam left.id "left" plan.family (psLogicLam right.id "right" plan.family body)

structure PsElabDeriveBEqSlotConstructor where
  slotIndex : Nat
  fields : PsElabDeriveFields
  comparisons : List PsElabDeriveBEqField

def psElabDeriveBEqIsListSlot (slot : PsInductiveEliminationSlot) : Bool :=
  !slot.publicMember && psNameEq slot.family.name psListName

def psElabDeriveBEqSlotResult (slot : PsInductiveEliminationSlot) (family : PsExpr) : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  let result := PsExpr.forallE (psRootName "right") family bool .explicit
  if psElabDeriveBEqIsListSlot slot then
    .forallE (psRootName "reverse") bool (psExprLiftBVars 1 0 result) .explicit
  else result

def psElabDeriveBEqPlanSlot (plan : PsElabDeriveContext) (slotIndex : Nat)
    (slot : PsInductiveEliminationSlot) (constructor : PsInductiveEliminationConstructor) :
    Except PsElabError PsElabDeriveBEqSlotConstructor := do
  let fields ← psElabDeriveSlotFields plan slot constructor
  let comparisons ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof then return PsElabDeriveBEqField.erased
    if constructor.recursiveFields.any (fun edge => edge.1 == index) then
      return PsElabDeriveBEqField.recursive
    let target ← psElabDeriveClassType plan.context (psRootName "BEq") field.type
    let dictionary ← psElabDeriveInstance plan.context target
    let .app (.constE _ levels) _ := target | throw .typeMismatch
    return PsElabDeriveBEqField.independent
      (psExprApplyMany (.constE (psNameAppendStr (psRootName "BEq") "beq") levels)
        [field.type, dictionary])
  return { slotIndex, fields, comparisons }

def psElabDeriveBEqAnd (left right : PsExpr) : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [.lam .anonymous bool bool .explicit, .constE psBoolFalseName [], right, left]

-- A List slot also supplies the reverse traversal needed by Array.isEqv.
-- An element which itself is a List always uses its ordinary forward BEq;
-- only the tail of the selected List inherits the traversal direction.
def psElabDeriveBEqSlotHypotheses (plan : PsElabDeriveContext)
    (hypotheses : List PsElabDeriveHypothesis) : Except PsElabError (List (Nat × PsExpr)) :=
  hypotheses.mapM fun hypothesis => do
    let some target := plan.elimination.slots[hypothesis.target]?
      | throw (.data "BEq deriving hypothesis target slot is absent")
    let value := if psElabDeriveBEqIsListSlot target then
        PsExpr.app hypothesis.value (.constE psBoolFalseName [])
      else hypothesis.value
    return (hypothesis.fieldId, value)

def psElabDeriveBEqListLength (context : PsElabContext) (field : PsElabTypedBinder) :
    Except PsElabError PsExpr := do
  let view := psExprAppView
    (psWhnf context.environment context.metaContext context.localContext field.type)
  let .constE name levels := view.head | throw (.data "BEq Array field is not its actual List")
  if !psNameEq name psListName || view.args.length != 1 || levels.length != 1 then
    throw (.data "BEq Array field is not its actual List")
  return psExprApplyMany (.constE (psNameAppendStr psListName "length") levels)
    (view.args ++ [.fvar field.id])

def psElabDeriveBEqMatchingSlots (plan : PsElabDeriveContext) (context : PsElabContext)
    (slotIndex : Nat) (slot : PsInductiveEliminationSlot)
    (entry : PsElabDeriveBEqSlotConstructor) (left right : List PsElabTypedBinder)
    (hypotheses : List PsElabDeriveHypothesis) (reverse : PsExpr) : Except PsElabError PsExpr := do
  let ordinary ← psElabDeriveBEqSlotHypotheses plan hypotheses
  let values := fun (fields : List PsElabTypedBinder) => fields.map (fun field => PsExpr.fvar field.id)
  if psElabDeriveBEqIsListSlot slot then
    match left, right with
    | [], [] => return .constE psBoolTrueName []
    | [leftHead, leftTail], [rightHead, rightTail] =>
      let some tail := hypotheses.find? (fun hypothesis => hypothesis.fieldId == leftTail.id)
        | throw (.data "BEq List tail has no checked induction hypothesis")
      if tail.target != slotIndex then throw (.data "BEq List tail targets another specialization")
      let head ← psElabDeriveBEqCompare (entry.comparisons.take 1)
        [.fvar leftHead.id] [.fvar rightHead.id] ordinary
      let tail := psExprApplyMany tail.value [reverse, .fvar rightTail.id]
      let bool := PsExpr.constE psBoolName []
      return psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
        [.lam .anonymous bool bool .explicit,
         psElabDeriveBEqAnd head tail, psElabDeriveBEqAnd tail head, reverse]
    | _, _ => throw (.data "BEq List constructor telescope mismatch")
  else if !slot.publicMember && psNameEq slot.family.name psArrayName then
    let [leftField] := left | throw (.data "BEq Array constructor telescope mismatch")
    let [rightField] := right | throw (.data "BEq Array constructor telescope mismatch")
    let some child := hypotheses.find? (fun hypothesis => hypothesis.fieldId == leftField.id)
      | throw (.data "BEq Array field has no checked List hypothesis")
    let some target := plan.elimination.slots[child.target]?
      | throw (.data "BEq Array field target slot is absent")
    if !psElabDeriveBEqIsListSlot target then
      throw (.data "BEq Array field does not target its List specialization")
    let leftLength ← psElabDeriveBEqListLength context leftField
    let rightLength ← psElabDeriveBEqListLength context rightField
    let sameLength := psExprApplyMany (.constE (psNameAppendStr psNatName "beq") [])
      [leftLength, rightLength]
    let compared := psExprApplyMany child.value [.constE psBoolTrueName [], .fvar rightField.id]
    return psElabDeriveBEqAnd sameLength compared
  else
    psElabDeriveBEqCompare entry.comparisons (values left) (values right) ordinary

-- Induct on the left; inspect only the right constructor of the actual slot.
-- Every right minor retains its raw field/IH prefix but ignores those IHs.
-- Only checked left-child evidence enters comparisons, so case inspection
-- does not generate another traversal or a companion worker group.
def psElabDeriveBEqRightCases (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveBEqSlotConstructor) (context : PsElabContext)
    (slotIndex : Nat) (slot : PsInductiveEliminationSlot)
    (constructor : PsInductiveEliminationConstructor) (left : List PsElabTypedBinder)
    (hypotheses : List PsElabDeriveHypothesis) (value reverse : PsExpr) : Except PsElabError PsExpr := do
  let family ← (psInferType context.environment context.metaContext context.localContext value).mapError
    PsElabError.infer
  let bool := PsExpr.constE psBoolName []
  psElabDeriveEliminateSlotAt plan context slotIndex family true (fun _ _ _ _ => bool)
    (fun rightContext rightIndex _ rightConstructor right _ _ => do
      if rightIndex != slotIndex || !psNameEq constructor.info.name rightConstructor.info.name then
        return .constE psBoolFalseName []
      let some entry := constructors.find? (fun candidate => candidate.slotIndex == slotIndex &&
          psNameEq candidate.fields.constructor.name constructor.info.name)
        | throw (.data "BEq deriving constructor plan missing")
      psElabDeriveBEqMatchingSlots plan rightContext slotIndex slot entry left right hypotheses reverse)

def psElabDeriveBEqInductive (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveBEqSlotConstructor) : Except PsElabError PsExpr :=
  psElabDeriveEliminateSlots plan plan.context true
    (fun _ slot family _ => psElabDeriveBEqSlotResult slot family)
    (fun context slotIndex slot constructor fields hypotheses value => do
      if psElabDeriveBEqIsListSlot slot then
        let bool := PsExpr.constE psBoolName []
        let pushed := psLocalPushBinding context.localContext (psRootName "reverse") bool .explicit
        let inner := psElabContextWithLocal context pushed.context
        let body ← psElabDeriveBEqRightCases plan constructors inner slotIndex slot constructor
          fields hypotheses value (.fvar pushed.id)
        return psLogicLam pushed.id "reverse" bool body
      else
        psElabDeriveBEqRightCases plan constructors context slotIndex slot constructor
          fields hypotheses value (.constE psBoolFalseName []))

def psElabDeriveBEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin { groups := true, nested := true }
  let className := psRootName "BEq"
  let plan := psElabDeriveRequirements plan className
  let type ← psElabDeriveClassType plan.context className plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let method ← if plan.info.isStructure then do
      let constructors ← (psElabDeriveConstructorNames plan).mapM (psElabDeriveBEqPlanConstructor plan)
      match constructors with
      | [constructor] => psElabDeriveBEqStructure plan constructor
      | _ => throw (.data "BEq deriving structure must have one constructor")
    else do
      let constructors ← plan.elimination.slots.zipIdx.mapM fun (slot, index) =>
        slot.constructors.mapM (psElabDeriveBEqPlanSlot plan index slot)
      psElabDeriveBEqInductive plan constructors.flatten
  let value := psExprApplyMany (.constE (psNameAppendStr className "mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instBEq" type value

