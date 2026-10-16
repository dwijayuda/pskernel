/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/DecEq.lean at eb6cafb.
Copyright (c) 2020 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Adaptation: checked induction over complete direct nonindexed groups, ordinary
equality transport and constructor discrimination. Nested deriving retains the
pinned handler's refusal. No assumed recursive instance or BEq axiom.
-/
import Ps.Elab.DerivingContext
import Ps.Elab.Equality
import Ps.Environment.Decision

inductive PsElabDeriveDecEqDecision where
  | erased
  | independent (method : PsExpr)
  | recursive

structure PsElabDeriveDecEqConstructor where
  fields : PsElabDeriveFields
  decisions : List PsElabDeriveDecEqDecision

def psElabDeriveDecEqPlan (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveDecEqConstructor := do
  let fields ← psElabDeriveFieldsWithRecursion plan name true
  let decisions ← (fields.fields.zip fields.proofs).zipIdx.mapM fun ((field, proof), index) => do
    if proof then return PsElabDeriveDecEqDecision.erased
    if fields.constructor.recursiveFields.contains index then
      return PsElabDeriveDecEqDecision.recursive
    let target ← psElabDeriveClassType plan.context (psRootName "DecidableEq") field.type
    return PsElabDeriveDecEqDecision.independent (← psElabDeriveInstance plan.context target)
  return { fields, decisions }

structure PsElabDeriveDecEqField where
  level : PsLevel
  type : PsExpr
  left : PsExpr
  right : PsExpr
  decision : PsExpr
  projection : PsExpr

def psElabDeriveDecEqProposition (field : PsElabDeriveDecEqField) : PsExpr :=
  psLogicEq field.level field.type field.left field.right

-- The runtime decision and the equality proof are deliberately separate.
-- Once all field equalities are available, the existing substitution engine
-- reverts dependent proof fields, transports them, and closes by reflexivity.
-- There is no BEq-to-equality axiom, proof hole or trusted noConfusion shortcut.
-- Proof fields may depend on earlier data fields; inductive formation still
-- owns positivity and nested-parameter validity, before deriving is attempted.
def psElabDeriveDecEqProof (context : PsElabContext)
    (fields : List PsElabDeriveDecEqField) (right : List PsElabTypedBinder)
    (target : PsExpr) : Except PsElabError PsExpr := do
  let offset := context.localContext.nextId
  let telescope := fields.zipIdx.foldr (fun (field, index) body =>
    psLogicPi (offset + index) "_fieldEq" (psElabDeriveDecEqProposition field) body) target
  let finish := fun (context : PsElabContext) (target : PsExpr) => do
    let equation ← psElabEquationView context target (.constE psBoolTrueName [])
    let checked := psUnify context.environment context.localContext context.metaContext
      equation.left equation.right
    if !checked.success then
      throw (.data "derived equality did not close after field transport")
    pure ({
      context := psElabContextWithMeta context checked.context
      type := target
      term := psLogicRefl equation.level equation.type equation.left } : PsElabTermResult)
  let proof ← psElabSolveIndexConstraints 4096 fields.length
    (right.map (·.id)) [] finish context telescope
  return proof.term

-- Decisions are nested in declaration order, with the remainder inside the
-- positive branch. Failed comparisons do not evaluate later field decisions.
def psElabDeriveDecEqChoose (context : PsElabContext) (familyLevel : PsLevel)
    (family left right target proof : PsExpr) (evidenceRev : List PsExpr) :
    List PsElabDeriveDecEqField → Except PsElabError PsExpr
  | [] => pure (psExprApplyMany (.constE (psDecisionName "Decidable.isTrue") [])
      [target, psExprApplyMany proof evidenceRev.reverse])
  | field :: rest => do
    let proposition := psElabDeriveDecEqProposition field
    let positive := psLocalPushBinding context.localContext (psRootName "equal") proposition .explicit
    let positiveContext := psElabContextWithLocal context positive.context
    let onTrue ← psElabDeriveDecEqChoose positiveContext familyLevel family left right
      target proof (.fvar positive.id :: evidenceRev) rest
    let negative := psLocalPushBinding context.localContext (psRootName "different")
      (psDecisionNot proposition) .explicit
    let whole := psLocalPushBinding negative.context (psRootName "whole") target .explicit
    let negativeContext := psElabContextWithLocal context whole.context
    let equality : PsElabEquation := {
      level := familyLevel, type := family, left, right, proof := .fvar whole.id }
    let projected ← psElabEquationCongr negativeContext equality field.projection field.type
    let refutation := psLogicLam whole.id "whole" target
      (.app (.fvar negative.id) projected.proof)
    let onFalse := psExprApplyMany (.constE (psDecisionName "Decidable.isFalse") [])
      [target, refutation]
    return psExprApplyMany (.constE (psRootName "dite") [.succ .zero])
      [psDecisionType target, proposition, field.decision,
       psLogicLam positive.id "equal" proposition onTrue,
       psLogicLam negative.id "different" (psDecisionNot proposition) onFalse]

def psElabDeriveDecEqSame (plan : PsElabDeriveContext)
    (entry : PsElabDeriveDecEqConstructor) (context : PsElabContext)
    (leftFields rightFields : List PsElabTypedBinder)
    (hypotheses : List (Nat × PsExpr)) (left right : PsExpr) :
    Except PsElabError PsExpr := do
  if leftFields.length != entry.decisions.length || rightFields.length != entry.decisions.length then
    throw (.data "DecidableEq deriving field alignment mismatch")
  let familyLevel ← psElabExpressionSort context plan.family
  let target := psLogicEq familyLevel plan.family left right
  let fields ← ((entry.decisions.zip leftFields).zip rightFields).zipIdx.filterMapM
    fun (((method, lhs), rhs), index) => do
      let leftValue := PsExpr.fvar lhs.id
      let rightValue := PsExpr.fvar rhs.id
      let decision ← match method with
        | .erased => pure none
        | .independent method => pure (some (psExprApplyMany method [leftValue, rightValue]))
        | .recursive => do
          let some (_, method) := hypotheses.find? (fun entry => entry.fst == lhs.id)
            | throw (.data "DecidableEq deriving recursive field has no checked induction hypothesis")
          -- The shared minor checker establishes forall right, Decidable (lhs = right).
          -- This is actual recursor evidence, not a self-instance assumption.
          pure (some (PsExpr.app method rightValue))
      let some decision := decision | return none
      let level ← psElabExpressionSort context lhs.type
      let projection ← if plan.info.isStructure then do
          let major := context.localContext.nextId
          pure (psLogicLam major "value" plan.family (.proj plan.info.name index (.fvar major)))
        else
          psElabIndexFunction context left entry.fields.constructor.name (some index)
            lhs.type leftValue leftValue
      return some ({
        level, type := lhs.type, left := leftValue, right := rightValue,
        decision, projection } : PsElabDeriveDecEqField)
  let proof ← (psElabDeriveDecEqProof context fields rightFields target).mapError
    (.atDeclaration (psNameAppendStr entry.fields.constructor.name "fieldEquality"))
  psElabDeriveDecEqChoose context familyLevel plan.family left right target proof [] fields

def psElabDeriveDecEqDifferent (plan : PsElabDeriveContext)
    (context : PsElabContext) (leftCtor : PsConstructorInfo) (left right : PsExpr) :
    Except PsElabError PsExpr := do
  let level ← psElabExpressionSort context plan.family
  let target := psLogicEq level plan.family left right
  let assumption := psLocalPushBinding context.localContext (psRootName "impossible") target .explicit
  let inner := psElabContextWithLocal context assumption.context
  let predicate ← psElabIndexFunction inner left leftCtor.name none (.sortE .zero)
    (.constE (psRootName "False") []) (.constE (psRootName "True") [])
  let equation : PsElabEquation := {
    level, type := plan.family, left, right, proof := .fvar assumption.id }
  let contradiction ← psElabEquationRec inner equation (fun value => .app predicate value)
    (.constE (psDecisionName "True.intro") [])
  return psExprApplyMany (.constE (psDecisionName "Decidable.isFalse") [])
    [target, psLogicLam assumption.id "impossible" target contradiction]

-- Inspect only the right constructor belonging to this left family. Other
-- group members use the ordinary inhabited type Decidable True, so their
-- motives never pretend that values from different families can be equal.
-- All right-side IHs remain bound and unused; only the real left-child
-- hypotheses provide recursive decisions.
def psElabDeriveDecEqRightCases (plan : PsElabDeriveContext)
    (constructors : List PsElabDeriveDecEqConstructor) (context : PsElabContext)
    (slotIndex : Nat) (slot : PsInductiveEliminationSlot)
    (constructor : PsInductiveEliminationConstructor) (leftFields : List PsElabTypedBinder)
    (hypotheses : List PsElabDeriveHypothesis) (left : PsExpr) : Except PsElabError PsExpr := do
  let member ← psElabDeriveAtMember plan slot.family
  let level ← psElabExpressionSort context member.family
  let target := fun right => psDecisionType (psLogicEq level member.family left right)
  let truth := PsExpr.constE (psRootName "True") []
  let trivial := psExprApplyMany (.constE (psDecisionName "Decidable.isTrue") [])
    [truth, .constE (psDecisionName "True.intro") []]
  psElabDeriveEliminateSlotAt plan context slotIndex member.family true
    (fun rightIndex _ _ right =>
      if rightIndex == slotIndex then target right else psDecisionType truth)
    (fun rightContext rightIndex _ rightConstructor rightFields _ right => do
      if rightIndex != slotIndex then return trivial
      if !psNameEq constructor.info.name rightConstructor.info.name then
        return ← psElabDeriveDecEqDifferent member rightContext constructor.info left right
      let some entry := constructors.find? (fun candidate =>
          psNameEq candidate.fields.constructor.name constructor.info.name)
        | throw (.data "DecidableEq deriving constructor plan missing")
      psElabDeriveDecEqSame member entry rightContext leftFields rightFields
        (hypotheses.map (fun hypothesis => (hypothesis.fieldId, hypothesis.value))) left right)

def psElabDeriveDecEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let initial ← psElabDerivePrepare environment origin { groups := true }
  let plan := psElabDeriveRequirements initial (psRootName "DecidableEq")
  let type ← psElabDeriveClassType plan.context (psRootName "DecidableEq") plan.family
  let constructors ← (psElabDeriveConstructorNames plan).mapM (psElabDeriveDecEqPlan plan)
  let level ← psElabExpressionSort plan.context plan.family
  -- The kernel requires a common result universe for direct mutual families.
  -- Recheck it before the pure motive callback reuses that inferred level.
  for info in plan.group.members do
    let member ← psElabDeriveAtMember plan info
    let memberLevel ← psElabExpressionSort plan.context member.family
    if !psLevelEquivalent level memberLevel then
      throw (.data "DecidableEq deriving group result universes differ")
  let method ← psElabDeriveEliminateSlots plan plan.context true
    -- Each motive is opened in a fresh scope. Bind right directly so a later
    -- member's actual left major cannot collide with a captured local ID.
    (fun _ _ family left => .forallE (psRootName "right") family
      (psDecisionType (psLogicEq level (psExprLiftBVars 1 0 family)
        (psExprLiftBVars 1 0 left) (.bvar 0))) .explicit)
    (fun context slotIndex slot constructor fields hypotheses left =>
      psElabDeriveDecEqRightCases plan constructors context slotIndex slot constructor
        fields hypotheses left)
  psElabDeriveFinish plan "instDecidableEq" type method

