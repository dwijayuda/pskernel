/-
Reference: Lean 4.35.0 Lean/Elab/Deriving/{BEq,DecEq}.lean at eb6cafb.
Indexed comparison uses the actual checked recursor and ordered equality
transport. Constructor indices authorize omission only after actual alignment.
-/
import Ps.Elab.DerivingContext
import Ps.Elab.Match
import Ps.Environment.Decision

-- The pinned handlers beta-reduce constructor result types before testing
-- occursOrInType. Do not unfold arbitrary definitions for this syntactic test.
def psElabDeriveIndexedBeta (fuel : Nat) (expression : PsExpr) :
    Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match expression with
    | .app fn arg =>
      let fn ← psElabDeriveIndexedBeta fuel fn
      match fn with
      | .lam _ _ body _ =>
        psElabDeriveIndexedBeta fuel (psExprInstantiate1 body arg)
      | _ => return .app fn (← psElabDeriveIndexedBeta fuel arg)
    | .lam name domain body binder =>
      return .lam name (← psElabDeriveIndexedBeta fuel domain)
        (← psElabDeriveIndexedBeta fuel body) binder
    | .forallE name domain body binder =>
      return .forallE name (← psElabDeriveIndexedBeta fuel domain)
        (← psElabDeriveIndexedBeta fuel body) binder
    | .letE name type value body =>
      return .letE name (← psElabDeriveIndexedBeta fuel type)
        (← psElabDeriveIndexedBeta fuel value) (← psElabDeriveIndexedBeta fuel body)
    | .proj name index value =>
      return .proj name index (← psElabDeriveIndexedBeta fuel value)
    | _ => return expression

def psElabDeriveIndexedDetermined (context : PsElabContext) (type : PsExpr) :
    Except PsElabError (List Nat) := do
  let type ← psElabDeriveIndexedBeta 4096 (psMetaInstantiate context.metaContext type)
  context.localContext.declarations.foldlM (fun ids declaration => do
    if !ids.contains (psLocalDeclId declaration) then return ids
    let domain ← psElabDeriveIndexedBeta 4096
      (psMetaInstantiate context.metaContext (psLocalDeclType declaration))
    return (ids ++ psExprFVarIds domain).eraseDups) (psExprFVarIds type)

structure PsElabDeriveIndexedField where
  index : Nat
  type : PsExpr
  value : PsExpr
  determined : Bool
  proof : Bool
  dependent : Bool
  hypothesis? : Option PsElabDeriveHypothesis

structure PsElabDeriveIndexedPair where
  index : Nat
  leftType : PsExpr
  rightType : PsExpr
  left : PsExpr
  right : PsExpr
  determined : Bool
  proof : Bool
  dependent : Bool
  hypothesis? : Option PsElabDeriveHypothesis

def psElabDeriveIndexedReplace (context : PsElabContext)
    (refinements : PsElabRefinements) (value : PsExpr) : PsExpr :=
  psMetaInstantiate context.metaContext (psElabSubstituteLocals refinements
    (psMetaInstantiate context.metaContext value))

def psElabDeriveIndexedPairRefine (context : PsElabContext)
    (refinements : PsElabRefinements) (field : PsElabDeriveIndexedPair) :
    PsElabDeriveIndexedPair :=
  let replace := psElabDeriveIndexedReplace context refinements
  { field with
    leftType := replace field.leftType, rightType := replace field.rightType
    left := replace field.left, right := replace field.right
    hypothesis? := field.hypothesis?.map fun hypothesis =>
      { hypothesis with value := replace hypothesis.value } }

def psElabDeriveIndexedFields (context : PsElabContext)
    (fields : List PsElabTypedBinder) (hypotheses : List PsElabDeriveHypothesis)
    (value : PsExpr) : Except PsElabError (List PsElabDeriveIndexedField) := do
  let type ← (psInferType context.environment context.metaContext
    context.localContext value).mapError PsElabError.infer
  let determined ← psElabDeriveIndexedDetermined context type
  fields.zipIdx.mapM fun (field, index) => do
    let level ← psElabExpressionSort context field.type
    let dependent := (fields.drop (index + 1)).any fun later =>
      psElabExprContainsLocal field.id (psMetaInstantiate context.metaContext later.type)
    return {
      index, type := field.type, value := .fvar field.id
      determined := determined.contains field.id
      proof := psLevelEquivalent level .zero
      dependent, hypothesis? := hypotheses.find? (fun hypothesis => hypothesis.fieldId == field.id) }

def psElabDeriveIndexedAlign (context : PsElabContext) (field : PsElabDeriveIndexedPair) :
    Except PsElabError Unit := do
  if !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
      field.leftType field.rightType then
    throw (.data "indexed deriving field types did not align")
  if field.determined && !psDefEqReadOnlyWithEnv context.environment context.metaContext
      context.localContext field.left field.right then
    throw (.data "indexed deriving inaccessible field was not determined by its indices")

-- Both constructor values and every retained field/IH consume exactly the
-- substitutions performed by the common typed matching owner.
def psElabDeriveIndexedRight (plan : PsElabDeriveContext) (context : PsElabContext)
    (slot : PsInductiveEliminationSlot) (constructor : PsInductiveEliminationConstructor)
    (fields : List PsElabTypedBinder) (hypotheses : List PsElabDeriveHypothesis)
    (left : PsExpr) (target : PsExpr → PsExpr)
    (same : PsElabContext → List PsElabDeriveIndexedPair → PsExpr → PsExpr → PsExpr →
      Except PsElabError PsElabTermResult)
    (different : PsElabContext → PsExpr → PsExpr → PsExpr →
      Except PsElabError PsElabTermResult) : Except PsElabError PsExpr := do
  let family ← (psInferType context.environment context.metaContext
    context.localContext left).mapError PsElabError.infer
  let entries ← psElabDeriveIndexedFields context fields hypotheses left
  let right := psLocalPushBinding context.localContext (psRootName "right") family .explicit
  let inner := psElabContextWithLocal context right.context
  let resultType := target (.fvar right.id)
  let span := PsSourceSpan.mk (.mk 0 1 1) (.mk 0 1 1)
  let required := (fields.map (·.id) ++
    hypotheses.flatMap (fun hypothesis => psExprFVarIds hypothesis.value)).eraseDups
  let checked ← psElabMatchTypedWith (fun current info => do
      if !psNameEq info.name slot.family.name then
        throw (.data "indexed deriving right family changed")
      info.constructors.mapM fun name => do
        let some rightCtor := psEnvironmentFindConstructor current.environment name
          | throw (.data "indexed deriving right constructor missing")
        return {
          constructorName := name
          fieldNames := List.replicate rightCtor.numFields (PsSyntaxName.mk ["_"] span)
          elaborate := fun child => do
            let hidden := child.hypotheses.map (·.id)
            let localContext := {
              child.context.localContext with
              declarations := child.context.localContext.declarations.filter
                (fun declaration => !hidden.contains (psLocalDeclId declaration)) }
            let current := psElabContextWithLocal child.context localContext
            let replace := psElabDeriveIndexedReplace current child.refinements
            let left := replace left
            let rightValue := replace (.fvar right.id)
            if !psNameEq constructor.info.name name then
              return ← different current left rightValue child.target
            if entries.length != child.fields.length then
              throw (.data "indexed deriving field alignment mismatch")
            let pairs := (entries.zip child.fields).map fun (lhs, rhs) =>
              psElabDeriveIndexedPairRefine current child.refinements {
                index := lhs.index, leftType := lhs.type, rightType := rhs.type
                left := lhs.value, right := .fvar rhs.id
                determined := lhs.determined, proof := lhs.proof, dependent := lhs.dependent
                hypothesis? := lhs.hypothesis? }
            same current pairs left rightValue child.target
          span })
    { context := inner, term := .fvar right.id, type := family }
    (some resultType) none none (some []) required
  let type := psLogicPi right.id "right" family resultType
  let closed ← psElabAbstract context checked.context
    [.lambdaE right.id (psRootName "right") family .explicit] checked.term type
  let term := psMetaInstantiate closed.context.metaContext closed.term
  if psExprHasUnresolvedMeta term then throw .unresolvedMetavariable
  return term

-- Indexed injectivity is a Prop-valued HEq predicate over the real family.
-- It does not assume a homogeneous projection from every constructor index.
def psElabDeriveIndexedPredicate (plan : PsElabDeriveContext) (context : PsElabContext)
    (slotIndex : Nat) (family : PsExpr) (constructor : PsName)
    (field? : Option (Nat × PsExpr × PsExpr)) : Except PsElabError PsExpr :=
  psElabDeriveEliminateSlotAt plan context slotIndex family true
    (fun _ _ _ _ => .sortE .zero)
    (fun current _ _ candidate fields _ _ => do
      if !psNameEq constructor candidate.info.name then
        return .constE (psRootName (if field?.isSome then "True" else "False")) []
      match field? with
      | none => return .constE (psRootName "True") []
      | some (index, leftType, left) =>
        let some field := fields[index]?
          | throw (.data "indexed deriving injection field is absent")
        let leftLevel ← psElabExpressionSort current leftType
        let rightLevel ← psElabExpressionSort current field.type
        if !psLevelEquivalent leftLevel rightLevel then
          throw (.data "indexed deriving injection field universes differ")
        return psExprApplyMany (.constE (psRootName "HEq") [leftLevel])
          [leftType, left, field.type, .fvar field.id])

def psElabDeriveIndexedFieldEquality (plan : PsElabDeriveContext) (context : PsElabContext)
    (slotIndex : Nat) (constructor : PsName) (whole : PsElabEquation)
    (field : PsElabDeriveIndexedPair) : Except PsElabError PsElabEquation := do
  let predicate ← psElabDeriveIndexedPredicate plan context slotIndex whole.type constructor
    (some (field.index, field.leftType, field.left))
  let level ← psElabExpressionSort context field.leftType
  let base := psExprApplyMany (.constE (psNameAppendStr (psRootName "HEq") "refl") [level])
    [field.leftType, field.left]
  let proof ← psElabEquationRec context whole (fun value => .app predicate value) base
  let type := psExprApplyMany (.constE (psRootName "HEq") [level])
    [field.leftType, field.left, field.rightType, field.right]
  let checked ← psElabResolvedTerm context proof none
  let checked ← psElabUnifyExpected checked (some type)
  psElabEquationView checked.context type checked.term

def psElabDeriveIndexedIsListSlot (slot : PsInductiveEliminationSlot) : Bool :=
  !slot.publicMember && psNameEq slot.family.name psListName

def psElabDeriveIndexedBEqResult (slot : PsInductiveEliminationSlot)
    (family : PsExpr) : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  let result := PsExpr.forallE (psRootName "right") family bool .explicit
  if psElabDeriveIndexedIsListSlot slot then
    .forallE (psRootName "reverse") bool (psExprLiftBVars 1 0 result) .explicit
  else result

def psElabDeriveIndexedAnd (left right : PsExpr) : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [.lam .anonymous bool bool .explicit, .constE psBoolFalseName [], right, left]

def psElabDeriveIndexedBEqTest (plan : PsElabDeriveContext) (context : PsElabContext)
    (field : PsElabDeriveIndexedPair) (reverse : PsExpr) :
    Except PsElabError (PsElabTermResult × Option PsExpr) := do
  let (term, dictionary?) ← match field.hypothesis? with
    | some hypothesis => do
      let some slot := plan.elimination.slots[hypothesis.target]?
        | throw (.data "indexed BEq hypothesis target is absent")
      let method := if psElabDeriveIndexedIsListSlot slot then
          PsExpr.app hypothesis.value reverse else hypothesis.value
      pure (PsExpr.app method field.right, (none : Option PsExpr))
    | none => do
      let target ← psElabDeriveClassType context (psRootName "BEq") field.leftType
      let dictionary ← psElabDeriveInstance context target
      let .app (.constE _ levels) _ := target | throw .typeMismatch
      pure (psExprApplyMany (.constE (psNameAppendStr (psRootName "BEq") "beq") levels)
        [field.leftType, dictionary, field.left, field.right], some dictionary)
  let checked ← psElabResolvedTerm context term none
  let checked ← psElabUnifyExpected checked (some (.constE psBoolName []))
  return (checked, dictionary?)

-- Dependent payload comparison uses the selected ordinary LawfulBEq evidence.
-- A BEq dictionary alone never authorizes equality transport.
def psElabDeriveIndexedBEqEquality (context : PsElabContext)
    (field : PsElabDeriveIndexedPair) (dictionary proof : PsExpr) :
    Except PsElabError PsElabEquation := do
  let (context, lawfulHead) ← psElabResolvedReference context (.global (psRootName "LawfulBEq"))
  let lawfulType ← psElabApplyCore context lawfulHead [field.leftType, dictionary]
  let lawful ← psElabDeriveInstance lawfulType.context lawfulType.term
  let (context, head) ← psElabResolvedReference lawfulType.context (.global (psNameAppendStr (psRootName "LawfulBEq") "eq_of_beq"))
  let checked ← psElabApplyCore context head
    [field.leftType, dictionary, lawful, field.left, field.right, proof]
  let level ← psElabExpressionSort checked.context field.leftType
  let expected := psLogicEq level field.leftType field.left field.right
  let checked ← psElabUnifyExpected checked (some expected)
  return {
    level := level
    type := field.leftType
    left := field.left
    right := field.right
    proof := psMetaInstantiate checked.context.metaContext checked.term }

def psElabDeriveIndexedBEqFields (fuel : Nat) (plan : PsElabDeriveContext)
    (context : PsElabContext) (fields : List PsElabDeriveIndexedPair) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match fields with
    | [] => psElabResolvedTerm context (.constE psBoolTrueName []) (some (.constE psBoolName []))
    | field :: rest =>
      psElabDeriveIndexedAlign context field
      if field.determined || field.proof then
        return ← psElabDeriveIndexedBEqFields fuel plan context rest
      let (tested, dictionary?) ← psElabDeriveIndexedBEqTest plan context field
        (.constE psBoolFalseName [])
      let context := tested.context
      if field.dependent && dictionary?.isSome then
        let some dictionary := dictionary? | throw .typeMismatch
        let bool := PsExpr.constE psBoolName []
        let proposition := psLogicEq (.succ .zero) bool tested.term (.constE psBoolTrueName [])
        let decisionType := psDecisionType proposition
        let decision ← psElabDeriveInstance context decisionType
        let positive := psLocalPushBinding context.localContext (psRootName "equal") proposition .explicit
        let inner := psElabContextWithLocal context positive.context
        let equation ← psElabDeriveIndexedBEqEquality inner field dictionary (.fvar positive.id)
        let flexible := match field.right with | .fvar id => [id] | _ => []
        let accepted ← psElabSolveIndexEquationWithRefinements 4096 flexible [positive.id]
          (fun refinements current target => do
            let rest := rest.map (psElabDeriveIndexedPairRefine current refinements)
            let result ← psElabDeriveIndexedBEqFields fuel plan current rest
            psElabUnifyExpected result (some target))
          [] inner bool equation
        let onTrue ← psElabAbstract context accepted.context
          [.lambdaE positive.id (psRootName "equal") proposition .explicit] accepted.term
          (psLogicPi positive.id "equal" proposition bool)
        let negative := psLocalPushBinding onTrue.context.localContext (psRootName "different")
          (psDecisionNot proposition) .explicit
        let onFalse := psLogicLam negative.id "different" (psDecisionNot proposition)
          (.constE psBoolFalseName [])
        let term := psExprApplyMany (.constE (psRootName "dite") [.succ .zero])
          [bool, proposition, decision, onTrue.term, onFalse]
        return ← psElabResolvedTerm onTrue.context term (some bool)
      let remainder ← psElabDeriveIndexedBEqFields fuel plan context rest
      psElabResolvedTerm remainder.context (psElabDeriveIndexedAnd tested.term remainder.term)
        (some (.constE psBoolName []))

def psElabDeriveIndexedListLength (context : PsElabContext) (type value : PsExpr) :
    Except PsElabError PsExpr := do
  let view := psExprAppView (psWhnf context.environment context.metaContext context.localContext type)
  let .constE name levels := view.head | throw (.data "indexed BEq Array field is not its actual List")
  if !psNameEq name psListName || view.args.length != 1 || levels.length != 1 then
    throw (.data "indexed BEq Array field is not its actual List")
  return psExprApplyMany (.constE (psNameAppendStr psListName "length") levels)
    (view.args ++ [value])

def psElabDeriveIndexedBEqSame (plan : PsElabDeriveContext)
    (slotIndex : Nat) (slot : PsInductiveEliminationSlot) (reverse : PsExpr)
    (context : PsElabContext) (fields : List PsElabDeriveIndexedPair) (_left _right target : PsExpr) :
    Except PsElabError PsElabTermResult := do
  if psElabDeriveIndexedIsListSlot slot then
    for field in fields do psElabDeriveIndexedAlign context field
    match fields with
    | [] => psElabResolvedTerm context (.constE psBoolTrueName []) (some target)
    | [head, tail] =>
      let some hypothesis := tail.hypothesis?
        | throw (.data "indexed BEq List tail lacks its induction hypothesis")
      if hypothesis.target != slotIndex then
        throw (.data "indexed BEq List tail targets another slot")
      let comparedHead ← psElabDeriveIndexedBEqFields 4096 plan context [head]
      let (comparedTail, _) ← psElabDeriveIndexedBEqTest plan comparedHead.context tail reverse
      let bool := PsExpr.constE psBoolName []
      let term := psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
        [.lam .anonymous bool bool .explicit,
         psElabDeriveIndexedAnd comparedHead.term comparedTail.term,
         psElabDeriveIndexedAnd comparedTail.term comparedHead.term, reverse]
      psElabResolvedTerm comparedTail.context term (some target)
    | _ => throw (.data "indexed BEq List field telescope mismatch")
  else if !slot.publicMember && psNameEq slot.family.name psArrayName then
    let [field] := fields | throw (.data "indexed BEq Array field telescope mismatch")
    psElabDeriveIndexedAlign context field
    let some hypothesis := field.hypothesis?
      | throw (.data "indexed BEq Array field lacks its List induction hypothesis")
    let some child := plan.elimination.slots[hypothesis.target]?
      | throw (.data "indexed BEq Array field target is absent")
    if !psElabDeriveIndexedIsListSlot child then
      throw (.data "indexed BEq Array field does not target its List specialization")
    let leftLength ← psElabDeriveIndexedListLength context field.leftType field.left
    let rightLength ← psElabDeriveIndexedListLength context field.rightType field.right
    let sameLength := psExprApplyMany (.constE (psNameAppendStr psNatName "beq") [])
      [leftLength, rightLength]
    let (compared, _) ← psElabDeriveIndexedBEqTest plan context field (.constE psBoolTrueName [])
    psElabResolvedTerm compared.context (psElabDeriveIndexedAnd sameLength compared.term) (some target)
  else
    let result ← psElabDeriveIndexedBEqFields 4096 plan context fields
    psElabUnifyExpected result (some target)

def psElabDeriveIndexedBEqMethod (plan : PsElabDeriveContext) : Except PsElabError PsExpr :=
  psElabDeriveEliminateSlots plan plan.context true
    (fun _ slot family _ => psElabDeriveIndexedBEqResult slot family)
    (fun context slotIndex slot constructor fields hypotheses left => do
      let bool := PsExpr.constE psBoolName []
      let rightCases := fun current reverse =>
        psElabDeriveIndexedRight plan current slot constructor fields hypotheses left
          (fun _ => bool) (psElabDeriveIndexedBEqSame plan slotIndex slot reverse)
          (fun current _ _ target =>
            psElabResolvedTerm current (.constE psBoolFalseName []) (some target))
      if psElabDeriveIndexedIsListSlot slot then
        let pushed := psLocalPushBinding context.localContext (psRootName "reverse") bool .explicit
        let term ← rightCases (psElabContextWithLocal context pushed.context) (.fvar pushed.id)
        return psLogicLam pushed.id "reverse" bool term
      rightCases context (.constE psBoolFalseName []))

def psElabDeriveIndexedEquality (context : PsElabContext) (left right : PsExpr) :
    Except PsElabError (PsLevel × PsExpr × PsExpr) := do
  let family ← (psInferType context.environment context.metaContext
    context.localContext left).mapError PsElabError.infer
  let rightFamily ← (psInferType context.environment context.metaContext
    context.localContext right).mapError PsElabError.infer
  if !psDefEqReadOnlyWithEnv context.environment context.metaContext context.localContext
      family rightFamily then
    throw (.data "indexed deriving compared values from different actual indices")
  let level ← psElabExpressionSort context family
  return (level, family, psLogicEq level family left right)

def psElabDeriveIndexedDecEqTest (context : PsElabContext) (field : PsElabDeriveIndexedPair) :
    Except PsElabError PsElabTermResult := do
  let method ← match field.hypothesis? with
    | some hypothesis => pure hypothesis.value
    | none => do
      let target ← psElabDeriveClassType context (psRootName "DecidableEq") field.leftType
      let method ← psElabDeriveInstance context target
      pure (PsExpr.app method field.left)
  let level ← psElabExpressionSort context field.leftType
  let target := psDecisionType (psLogicEq level field.leftType field.left field.right)
  let checked ← psElabResolvedTerm context (.app method field.right) none
  psElabUnifyExpected checked (some target)

def psElabDeriveIndexedDecEqDifferent (plan : PsElabDeriveContext)
    (slotIndex : Nat) (constructor : PsName) (context : PsElabContext)
    (left right target : PsExpr) : Except PsElabError PsElabTermResult := do
  let (level, family, proposition) ← psElabDeriveIndexedEquality context left right
  let assumed := psLocalPushBinding context.localContext (psRootName "impossible")
    proposition .explicit
  let inner := psElabContextWithLocal context assumed.context
  let predicate ← psElabDeriveIndexedPredicate plan inner slotIndex family constructor none
  let equation : PsElabEquation := {
    level, type := family, left, right, proof := .fvar assumed.id }
  let contradiction ← psElabEquationRec inner equation (fun value => .app predicate value)
    (.constE (psDecisionName "True.intro") [])
  let checked ← psElabResolvedTerm inner contradiction none
  let checked ← psElabUnifyExpected checked (some (.constE (psRootName "False") []))
  let refutation ← psElabAbstract context checked.context
    [.lambdaE assumed.id (psRootName "impossible") proposition .explicit] checked.term
    (psDecisionNot proposition)
  psElabResolvedTerm refutation.context
    (psExprApplyMany (.constE (psDecisionName "Decidable.isFalse") [])
      [proposition, refutation.term]) (some target)

def psElabDeriveIndexedDecEqFields (fuel : Nat) (plan : PsElabDeriveContext)
    (slotIndex : Nat) (constructor : PsName) (context : PsElabContext)
    (fields : List PsElabDeriveIndexedPair) (left right target : PsExpr) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let (familyLevel, family, proposition) ← psElabDeriveIndexedEquality context left right
    match fields with
    | [] =>
      let proof ← psElabResolvedTerm context (psLogicRefl familyLevel family left) none
      let proof ← psElabUnifyExpected proof (some proposition)
      psElabResolvedTerm proof.context
        (psExprApplyMany (.constE (psDecisionName "Decidable.isTrue") [])
          [proposition, proof.term]) (some target)
    | field :: rest =>
      psElabDeriveIndexedAlign context field
      if field.determined || field.proof then
        return ← psElabDeriveIndexedDecEqFields fuel plan slotIndex constructor
          context rest left right target
      let tested ← psElabDeriveIndexedDecEqTest context field
      let context := tested.context
      let level ← psElabExpressionSort context field.leftType
      let fieldProposition := psLogicEq level field.leftType field.left field.right
      let positive := psLocalPushBinding context.localContext (psRootName "equal")
        fieldProposition .explicit
      let inner := psElabContextWithLocal context positive.context
      let equation : PsElabEquation := {
        level, type := field.leftType, left := field.left, right := field.right
        proof := .fvar positive.id }
      let flexible := match field.right with | .fvar id => [id] | _ => []
      let accepted ← psElabSolveIndexEquationWithRefinements 4096 flexible [positive.id]
        (fun refinements current target =>
          psElabDeriveIndexedDecEqFields fuel plan slotIndex constructor current
            (rest.map (psElabDeriveIndexedPairRefine current refinements))
            (psElabDeriveIndexedReplace current refinements left)
            (psElabDeriveIndexedReplace current refinements right) target)
        [] inner target equation
      let onTrue ← psElabAbstract context accepted.context
        [.lambdaE positive.id (psRootName "equal") fieldProposition .explicit] accepted.term
        (psLogicPi positive.id "equal" fieldProposition target)
      let negative := psLocalPushBinding onTrue.context.localContext (psRootName "different")
        (psDecisionNot fieldProposition) .explicit
      let negativeContext := psElabContextWithLocal onTrue.context negative.context
      let whole := psLocalPushBinding negativeContext.localContext (psRootName "whole")
        proposition .explicit
      let inner := psElabContextWithLocal negativeContext whole.context
      let equation : PsElabEquation := {
        level := familyLevel, type := family, left, right, proof := .fvar whole.id }
      let projected ← psElabDeriveIndexedFieldEquality plan inner slotIndex constructor equation field
      let contradiction ← psElabResolvedTerm inner (.app (.fvar negative.id) projected.proof) none
      let contradiction ← psElabUnifyExpected contradiction (some (.constE (psRootName "False") []))
      let refutation ← psElabAbstract negativeContext contradiction.context
        [.lambdaE whole.id (psRootName "whole") proposition .explicit] contradiction.term
        (psDecisionNot proposition)
      let rejected ← psElabResolvedTerm refutation.context
        (psExprApplyMany (.constE (psDecisionName "Decidable.isFalse") [])
          [proposition, refutation.term]) (some target)
      let onFalse ← psElabAbstract onTrue.context rejected.context
        [.lambdaE negative.id (psRootName "different") (psDecisionNot fieldProposition) .explicit]
        rejected.term (psLogicPi negative.id "different" (psDecisionNot fieldProposition) target)
      psElabResolvedTerm onFalse.context
        (psExprApplyMany (.constE (psRootName "dite") [.succ .zero])
          [target, fieldProposition, tested.term, onTrue.term, onFalse.term]) (some target)

def psElabDeriveIndexedDecEqMethod (plan : PsElabDeriveContext) : Except PsElabError PsExpr := do
  let level ← psElabExpressionSort plan.context plan.family
  let parameters := psElabBinderArguments plan.parametersRev
  let levels := plan.info.levelParams.map PsLevel.param
  for info in plan.group.members do
    let type := psExprInstantiateLevelParams info.levelParams levels info.type
    let cursor ← psElabMatchApplyParameters plan.context parameters type
    let indices ← psElabOpenCoreTelescope 4096 plan.context cursor (some info.numIndices)
    let family := psExprApplyMany (.constE info.name levels)
      (parameters ++ psElabBinderArguments indices.bindersRev)
    let memberLevel ← psElabExpressionSort indices.context family
    if !psLevelEquivalent level memberLevel then
      throw (.data "indexed DecidableEq group result universes differ")
  psElabDeriveEliminateSlots plan plan.context true
    (fun _ _ family left => .forallE (psRootName "right") family
      (psDecisionType (psLogicEq level (psExprLiftBVars 1 0 family)
        (psExprLiftBVars 1 0 left) (.bvar 0))) .explicit)
    (fun context slotIndex slot constructor fields hypotheses left => do
      let family ← (psInferType context.environment context.metaContext
        context.localContext left).mapError PsElabError.infer
      psElabDeriveIndexedRight plan context slot constructor fields hypotheses left
        (fun right => psDecisionType (psLogicEq level family left right))
        (psElabDeriveIndexedDecEqFields 4096 plan slotIndex constructor.info.name)
        (psElabDeriveIndexedDecEqDifferent plan slotIndex constructor.info.name))
