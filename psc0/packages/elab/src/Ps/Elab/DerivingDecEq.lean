import Ps.Elab.DerivingContext
import Ps.Elab.Equality

structure PsElabDeriveDecEqConstructor where
  fields : PsElabDeriveFields
  decisions : List (Option PsExpr)

def psElabDeriveDecEqPlan (plan : PsElabDeriveContext) (name : PsName) :
    Except PsElabError PsElabDeriveDecEqConstructor := do
  let fields ← psElabDeriveFields plan name
  let decisions ← (fields.fields.zip fields.proofs).mapM fun (field, proof) => do
    if proof then return none
    let target ← psElabDeriveClassType plan.context (psRootName "DecidableEq") field.type
    return some (← psElabDeriveInstance plan.context target)
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
    pure ({ context := psElabContextWithMeta context checked.context, type := target,
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
    (leftFields rightFields : List PsElabTypedBinder) (left right : PsExpr) :
    Except PsElabError PsExpr := do
  if leftFields.length != entry.decisions.length || rightFields.length != entry.decisions.length then
    throw (.data "DecidableEq deriving field alignment mismatch")
  let familyLevel ← psElabExpressionSort context plan.family
  let target := psLogicEq familyLevel plan.family left right
  let fields ← ((entry.decisions.zip leftFields).zip rightFields).zipIdx.filterMapM
    fun (((method, lhs), rhs), index) => do
      let some method := method | return none
      let level ← psElabExpressionSort context lhs.type
      let leftValue := PsExpr.fvar lhs.id
      let rightValue := PsExpr.fvar rhs.id
      let projection ← if plan.info.isStructure then do
          let major := context.localContext.nextId
          pure (psLogicLam major "value" plan.family (.proj plan.info.name index (.fvar major)))
        else psElabIndexFunction context left entry.fields.constructor.name (some index)
          lhs.type leftValue leftValue
      return some ({
        level, type := lhs.type, left := leftValue, right := rightValue,
        decision := psExprApplyMany method [leftValue, rightValue], projection } : PsElabDeriveDecEqField)
  let proof ← psElabDeriveDecEqProof context fields rightFields target
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

def psElabDeriveDecEq (environment : PsEnvironment)
    (origin : PsElabBatchOrigin) : Except PsElabError PsDeclaration := do
  let initial ← psElabDerivePrepare environment origin
  let plan := psElabDeriveRequirements initial (psRootName "DecidableEq")
  let type ← psElabDeriveClassType plan.context (psRootName "DecidableEq") plan.family
  let constructors ← plan.info.constructors.mapM (psElabDeriveDecEqPlan plan)
  let level ← psElabExpressionSort plan.context plan.family
  let target := fun left right => psDecisionType (psLogicEq level plan.family left right)
  let rightId := plan.context.localContext.nextId + 1
  let method ← psElabDeriveEliminate plan plan.context
    (fun left => psLogicPi rightId "right" plan.family (target left (.fvar rightId)))
    (fun leftContext leftCtor leftFields left =>
      psElabDeriveEliminate plan leftContext (target left)
        (fun context rightCtor rightFields right => do
          if !psNameEq leftCtor.name rightCtor.name then
            return ← psElabDeriveDecEqDifferent plan context leftCtor left right
          let some entry := constructors.find? (fun c => psNameEq c.fields.constructor.name leftCtor.name)
            | throw (.data "DecidableEq deriving constructor plan missing")
          psElabDeriveDecEqSame plan entry context leftFields rightFields left right))
  psElabDeriveFinish plan "instDecidableEq" type method
