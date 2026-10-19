/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/Hashable.lean.
Copyright (c) 2021 Microsoft Corporation. Author: Dany Fabian.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: ordinary Core recursors for complete visible and selected nested
slots. Recursive hashes come from actual checked induction hypotheses. Native
container policies come from Init/Data/Hashable.lean at the same pinned commit.
-/
import Ps.Elab.DerivingContext

def psElabDeriveHashUInt64 : PsExpr := .constE (psRootName "UInt64") []

def psElabDeriveHashNumber (value : Nat) : PsExpr :=
  .app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") []) (.lit (.natural value))

def psElabDeriveHashMix (left right : PsExpr) : PsExpr :=
  psExprApplyMany (.constE (psRootName "mixHash") []) [left, right]

def psElabDeriveHashListSlot (slot : PsInductiveEliminationSlot) : Bool :=
  !slot.publicMember && psNameEq slot.family.name psListName

def psElabDeriveHashResult (slot : PsInductiveEliminationSlot) : PsExpr :=
  if psElabDeriveHashListSlot slot then
    .forallE (psRootName "_hashAcc") psElabDeriveHashUInt64 psElabDeriveHashUInt64 .explicit
  else psElabDeriveHashUInt64

def psElabDeriveHashField (plan : PsElabDeriveContext) (context : PsElabContext)
    (hypotheses : List PsElabDeriveHypothesis) (field : PsElabTypedBinder) :
    Except PsElabError PsExpr := do
  if let some hypothesis := hypotheses.find? (fun hypothesis => hypothesis.fieldId == field.id) then
    let some target := plan.elimination.slots[hypothesis.target]?
      | throw (.data "Hashable field target slot is absent")
    return if psElabDeriveHashListSlot target then
      .app hypothesis.value (psElabDeriveHashNumber 7) else hypothesis.value
  let className := psRootName "Hashable"
  let target ← psElabDeriveClassType context className field.type
  let dictionary ← psElabDeriveInstance context target
  let .app (.constE _ levels) _ := target | throw .typeMismatch
  return psExprApplyMany (.constE (psNameAppendStr className "hash") levels)
    [field.type, dictionary, .fvar field.id]

def psElabDeriveHashBranch (plan : PsElabDeriveContext) (context : PsElabContext)
    (slotIndex : Nat) (slot : PsInductiveEliminationSlot)
    (constructor : PsInductiveEliminationConstructor) (fields : List PsElabTypedBinder)
    (hypotheses : List PsElabDeriveHypothesis) : Except PsElabError PsExpr := do
  let hash := psElabDeriveHashField plan context hypotheses
  if slot.publicMember then
    fields.foldlM (fun acc field => do pure (psElabDeriveHashMix acc (← hash field)))
      (psElabDeriveHashNumber constructor.info.constructorIndex)
  else if psNameEq slot.family.name psListName then
    if psNameEq constructor.info.name (psNameAppendStr psListName "nil") then
      if !fields.isEmpty || !hypotheses.isEmpty then throw .structuralRecursionInternal
      else pure (.lam (psRootName "_hashAcc") psElabDeriveHashUInt64 (.bvar 0) .explicit)
    else if psNameEq constructor.info.name (psNameAppendStr psListName "cons") then
      let [head, tail] := fields | throw .structuralRecursionInternal
      let some tailIH := hypotheses.find? (fun hypothesis => hypothesis.fieldId == tail.id)
        | throw (.data "Hashable List tail hypothesis is absent")
      if tailIH.target != slotIndex then throw (.data "Hashable List tail specialization mismatch")
      let hashed ← hash head
      let acc := psLocalPushBinding context.localContext (psRootName "_hashAcc")
        psElabDeriveHashUInt64 .explicit
      pure (psLogicLam acc.id "_hashAcc" psElabDeriveHashUInt64
        (.app tailIH.value (psElabDeriveHashMix (.fvar acc.id) hashed)))
    else throw (.data "Hashable List constructor mismatch")
  else if psNameEq slot.family.name psOptionName then
    if psNameEq constructor.info.name (psNameAppendStr psOptionName "none") then
      if !fields.isEmpty then throw .structuralRecursionInternal else pure (psElabDeriveHashNumber 11)
    else if psNameEq constructor.info.name (psNameAppendStr psOptionName "some") then
      let [field] := fields | throw .structuralRecursionInternal
      pure (psElabDeriveHashMix (← hash field) (psElabDeriveHashNumber 13))
    else throw (.data "Hashable Option constructor mismatch")
  else if psNameEq slot.family.name psArrayName then
    if !psNameEq constructor.info.name (psNameAppendStr psArrayName "mk") then
      throw (.data "Hashable Array constructor mismatch")
    let [field] := fields | throw .structuralRecursionInternal
    hash field
  else if psNameEq slot.family.name psProdName then
    if !psNameEq constructor.info.name (psNameAppendStr psProdName "mk") then
      throw (.data "Hashable Prod constructor mismatch")
    let [left, right] := fields | throw .structuralRecursionInternal
    pure (psElabDeriveHashMix (← hash left) (← hash right))
  else throw (.data "Hashable nested container is outside the selected plan")

def psElabDeriveHashable (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let plan ← psElabDerivePrepare environment origin { groups := true, indices := true, nested := true }
  let className := psRootName "Hashable"
  let plan ← psElabDeriveRequirements plan className
  -- Validate the complete family before generating any branch.
  for slot in plan.elimination.slots do
    for constructor in slot.constructors do
      let _ ← psElabDeriveSlotFields plan slot constructor true
      pure ()
  let type ← psElabDeriveClassType plan.context className plan.family
  let .app (.constE _ levels) _ := type | throw .typeMismatch
  let method ← psElabDeriveEliminateSlots plan plan.context true
    (fun _ slot _ _ => psElabDeriveHashResult slot)
    (fun context index slot constructor fields hypotheses _ =>
      psElabDeriveHashBranch plan context index slot constructor fields hypotheses)
  let value := psExprApplyMany (.constE (psNameAppendStr className "mk") levels) [plan.family, method]
  psElabDeriveFinish plan "instHashable" type value

