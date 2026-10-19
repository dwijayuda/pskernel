import Ps.Elab.ProofTerm
import Ps.Elab.ProofReduce

/-!
Adapted from Lean 4.35.0 Lean/Elab/Calc.lean and Lean/Elab/Tactic/Calc.lean
(eb6cafb7290e8bd5f2937522d8d804f58f02bafc), Microsoft Corporation /
Leonardo de Moura, Apache-2.0. Chaining uses the actual checked Trans class
and its ordinary instance index. The expected final endpoints never guide
step elaboration; heterogeneous and Sort-valued relations retain their types.
-/

def psCalcError (message : String) : PsElabError :=
  .data ("PSCV0-CALC: " ++ message)

def psCalcRelation (context : PsElabContext) (type : PsExpr) :
    Option (PsExpr × PsExpr × PsExpr) :=
  match psMetaInstantiate context.metaContext type with
  | .app (.app relation left) right => some (relation, left, right)
  | _ => none

-- Native annotateFirstHoleWithType acts before notation expansion. The raw
-- leading byte and one-byte hole extent distinguish (_) and named applications
-- from a leading _ even though the shared AST has no parenthesis constructor.
def psCalcLeadingHole (fuel : Nat) (start : Nat) (source : PsSyntaxTerm) :
    Except PsElabError (Option PsSourceSpan) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if (psSyntaxTermSpan source).start.byteOffset != start then return none
    match source with
    | .hole span =>
      return if span.stop.byteOffset == span.start.byteOffset + 1 then some span else none
    | _ =>
      let children := match source with
        | .operatorE _ _ _ arguments _ => arguments
        | .app fn arguments _ => fn :: arguments
        | .call fn arguments _ => fn :: arguments.map Prod.snd
        | .ascription value _ _ => [value]
        | _ => []
      for child in children do
        if let some span ← psCalcLeadingHole fuel start child then return some span
      return none

def psCalcRelationSort (fuel : Nat) (context : PsElabContext) (type : PsExpr) :
    Except PsElabError PsLevel := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let type ← psProofWhnfWithFuel 256 context type
    match type with
    | .sortE level => return level
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding context.localContext name domain binder
      psCalcRelationSort fuel (psElabContextWithLocal context pushed.context)
        (psExprInstantiate1 body (.fvar pushed.id))
    | _ => throw (psCalcError "relation type does not end in a sort")

def psCalcRelUniverse (context : PsElabContext) (relation : PsExpr) :
    Except PsElabError PsLevel := do
  let type ← (psInferType context.environment context.metaContext
    context.localContext relation).mapError PsElabError.infer
  psCalcRelationSort 4096 context type

-- Expr.headBeta only reduces the head lambda applications. Delta, local-let
-- and relation normalization would change native relation selection here.
def psCalcHeadBeta (fuel : Nat) (expression : PsExpr) (arguments : List PsExpr) :
    Except PsElabError PsExpr := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match expression with
    | .app fn arg => psCalcHeadBeta fuel fn (arg :: arguments)
    | .lam _ _ body _ =>
      match arguments with
      | [] => return expression
      | argument :: rest => psCalcHeadBeta fuel (psExprInstantiate1 body argument) rest
    | _ => return psExprApplyMany expression arguments

-- The fresh output relation and output universe are solved by ordinary class
-- output-parameter unification. No equality-only fallback or relation whitelist
-- replaces the checked dictionary's actual transitivity function.
def psElabCalcTrans (context : PsElabContext) (value type step stepType : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let some (relation, left, middle) := psCalcRelation context type
    | throw (psCalcError "previous result is not a relation")
  let some (nextRelation, _, right) := psCalcRelation context stepType
    | throw (psCalcError "step result is not a relation")
  let transName := psRootName "Trans"
  if !(context.environment.classes.any (psNameEq transName)) then
    throw (.data "PSCV0-CALC-PROFILE: the checked Trans class is not registered")
  let u ← psCalcRelUniverse context relation
  let v ← psCalcRelUniverse context nextRelation
  let infer := fun term => (psInferType context.environment context.metaContext
    context.localContext term).mapError PsElabError.infer
  let leftType ← infer left
  let middleType ← infer middle
  let rightType ← infer right
  let leftLevel ← psElabExpressionSort context leftType
  let middleLevel ← psElabExpressionSort context middleType
  let rightLevel ← psElabExpressionSort context rightType
  let level := psMetaFreshLevel context.metaContext
  let outputType := PsExpr.forallE (psRootName "a") leftType
    (.forallE (psRootName "c") rightType (.sortE level.level) .explicit) .explicit
  let output := psMetaFresh level.context context.localContext outputType .natural
  let levels := [u, v, level.level, leftLevel, middleLevel, rightLevel]
  let target ← psElabApplyCore (psElabContextWithMeta context output.context)
    (.constE transName levels)
    [leftType, middleType, rightType, relation, nextRelation, output.expr]
  let dictionary ← match psElabSynthesizeInstance
      { target.context with postponing := false } target.term with
    | .ok result => pure result
    | .error error =>
      if psElabErrorIsResource error then throw error
      throw (psCalcError "failed to synthesize the actual Trans instance")
  let result ← psElabApplyCore
    { dictionary.context with postponing := context.postponing }
    (.constE (psNameAppendStr transName "trans") levels)
    [leftType, middleType, rightType, relation, nextRelation, output.expr,
      dictionary.term, left, middle, right, value, step]
  -- Infer/check first, then only head beta-reduce the resulting relation.
  let resultType ← psCalcHeadBeta 4096 (psMetaInstantiate result.context.metaContext result.type) []
  if (psCalcRelation result.context resultType).isNone then
    throw (psCalcError "Trans result is not a relation")
  return { result with type := resultType }

structure PsCalcState where
  context : PsElabContext
  result : Option (PsExpr × PsExpr) := none
  previousRight : Option PsExpr := none

def psElabCalcStep (elaborate : PsElaborator) (state : PsCalcState)
    (source : PsSyntaxTerm × PsSyntaxTerm) : Except PsElabError PsCalcState := do
  let mut context := { state.context with postponing := true }
  let hints := context.termHoleHints
  if let some previous := state.previousRight then
    if let some span ← psCalcLeadingHole 4096 (psSyntaxTermSpan source.1).start.byteOffset source.1 then
      let type ← (psInferType context.environment context.metaContext
        context.localContext previous).mapError PsElabError.infer
      context := { context with termHoleHints := (span, type) :: hints }
  let annotation ← psElabType elaborate context source.1
  context := { annotation.context with termHoleHints := hints }
  let some (_, left, right) := psCalcRelation context annotation.type
    | throw (psCalcError "a step annotation is not a relation")
  if let some previous := state.previousRight then
    let unified := psUnify context.environment context.localContext context.metaContext left previous
    if unified.resourceExceeded then throw .fuelExhausted
    if !unified.success then throw (psCalcError "step left endpoint differs from the previous right endpoint")
    context := psElabContextWithMeta context unified.context
  let proof ← elaborate context source.2 (some annotation.type)
  let result ← match state.result with
    | none => pure proof
    | some (value, type) => do
      -- Native calc drains ordinary/default work only before composition,
      -- after the following annotation and proof have supplied constraints.
      let proof ← psElabDrainPending elaborate proof
      psElabCalcTrans proof.context value type proof.term annotation.type
  return {
    context := result.context
    result := some (result.term, result.type)
    previousRight := some right }

def psElabCalcSteps (elaborate : PsElaborator) (context : PsElabContext)
    (steps : List (PsSyntaxTerm × PsSyntaxTerm)) :
    Except PsElabError PsElabTermResult := do
  let state ← steps.foldlM (psElabCalcStep elaborate) ({ context } : PsCalcState)
  let some (term, type) := state.result | throw (psCalcError "empty calculation")
  psElabDrainPending elaborate { context := state.context, term, type }

def psElabCalc (elaborate : PsElaborator) (context : PsElabContext)
    (steps : List (PsSyntaxTerm × PsSyntaxTerm)) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let value ← psProofWithTermSynthesis elaborate context
    (fun current => psElabCalcSteps elaborate current steps)
  psElabFinalizeExpected value expected

-- A tactic may leave exactly the remaining endpoint relation as a new goal.
-- Every speculative assignment, fresh output relation and failed instance
-- attempt belongs to this immutable branch and is discarded together.
def psProofCalcExtension (value : PsElabTermResult) (target : PsExpr) (tag : String) :
    Except PsElabError PsElabTermResult := do
  let some (_, left, right) := psCalcRelation value.context value.type
    | throw (psCalcError "calculation result is not a relation")
  let some (relation, expectedLeft, expectedRight) := psCalcRelation value.context target
    | throw (psCalcError "target is not a relation")
  let mut context := value.context
  let aligned := psUnify context.environment context.localContext context.metaContext left expectedLeft
  if aligned.resourceExceeded then throw .fuelExhausted
  if !aligned.success then throw (psCalcError "target left endpoint differs")
  context := psElabContextWithMeta context aligned.context
  let actualType ← (psInferType context.environment context.metaContext
    context.localContext right).mapError PsElabError.infer
  let expectedType ← (psInferType context.environment context.metaContext
    context.localContext expectedLeft).mapError PsElabError.infer
  let aligned := psUnify context.environment context.localContext context.metaContext actualType expectedType
  if aligned.resourceExceeded then throw .fuelExhausted
  if !aligned.success then throw (psCalcError "last-step endpoint types differ")
  context := psElabContextWithMeta context aligned.context
  let lastType := PsExpr.app (.app relation right) expectedRight
  let _ ← psElabExpressionSort context lastType
  let fresh := psMetaFresh context.metaContext context.localContext lastType .syntheticOpaque
    { tag := psProofTag tag "calc.step" }
  let result ← psElabCalcTrans (psElabContextWithMeta context fresh.context)
    value.term value.type fresh.expr lastType
  psElabUnifyExpected result (some target)

def psProofCalc (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (steps : List (PsSyntaxTerm × PsSyntaxTerm)) (span : PsSourceSpan) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let .calcE steps _ ← psProofSource scope context (.calcE steps span)
    | throw (psCalcError "source scope changed the calculation form")
  let value ← psProofWithTermSynthesis elaborate context fun current => do
    let value ← psElabCalcSteps elaborate current steps
    match psElabUnifyExpected value (some target) with
    | .ok result => pure result
    | .error error =>
      if psElabErrorIsResource error then throw error
      match psProofCalcExtension value target goal.tag with
      | .ok result => pure result
      | .error extensionError =>
        if psElabErrorIsResource extensionError then throw extensionError
        psElabFinalizeExpected value (some target)
  let pending := (psProofFreshGoals context.metaContext.nextId value.context).map fun child =>
    if child.tag.isEmpty then { child with tag := psProofTag goal.tag "calc" } else child
  let state ← psProofAssign (psProofUpdate state value.context) goal.id value.term
  psProofNormalize { state with goals := pending ++ state.goals.drop 1 }
