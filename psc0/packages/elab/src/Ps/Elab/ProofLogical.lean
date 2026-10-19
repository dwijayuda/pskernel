import Ps.Elab.ProofTerm
import Ps.Elab.ProofReduce
import Ps.Elab.ProofClassical
import Ps.Elab.Conditional

-- Pinned Lean4.35.0 Init/Tactics.exfalso constructs False.elim. The new
-- False goal is an ordinary typed metavariable and remains mandatory.
def psProofExfalso (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let falseType := PsExpr.constE (psRootName "False") []
  let fresh := psMetaFresh context.metaContext context.localContext
    falseType .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid false goal")
  let context := psElabContextWithMeta context fresh.context
  let proof ← psElabFalseElimination context target fresh.expr
  let next ← psProofAssign (psProofUpdate state proof.context) goal.id proof.term
  psProofNormalize { next with
    goals := { id := child, tag := goal.tag } :: state.goals.drop 1 }

-- Pinned Lean/Elab/Tactic/Decide preprocesses only local lets; arbitrary
-- free variables or metavariables in the proposition remain a refusal.
-- A true host Boolean is never proof evidence: the real Decidable dictionary
-- supplies its checked Bool.Reflects field, whose type must reduce to target.
def psProofDecide (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let target := context.localContext.declarations.foldl (fun current declaration =>
    match declaration with
    | .letDecl id _ _ value => psElabSubstituteLocals [(id, value)] current
    | _ => current) target
  let target := psMetaInstantiate context.metaContext target
  if psExprHasTermMeta target then
    throw (.proof "decide requires a proposition without metavariables")
  if !(psExprFVarIds target).isEmpty then
    throw (.proof "decide requires a proposition without free variables")
  let level ← psElabExpressionSort context target
  if !psLevelEquivalent level .zero then
    throw (.proof "decide requires a proposition")
  let decision ← psElabSynthesizeInstance context
    (.app (.constE psDecidableName []) target)
  let boolean := PsExpr.proj psDecidableName 0 decision.term
  let reduced ← psProofWhnfWithFuel 256 decision.context boolean
  if !psExprAlphaEq reduced (.constE psBoolTrueName []) then
    throw (.proof "decide could not reduce its checked decision to true")
  let proof := PsExpr.proj psDecidableName 1 decision.term
  let checked ← psElabResolvedTerm decision.context proof (some target)
  psProofNormalize (← psProofAssign (psProofUpdate state checked.context) goal.id checked.term)

-- Pinned Init/ByCases expands to a named dependent if with positive and
-- negative holes. Only constructing its decision opens Classical; neither
-- branch nor a later tactic inherits that temporary instance registration.
def psProofByCases (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (name : Option PsSyntaxName) (source : PsSyntaxTerm) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let sourceValue ← psProofWithTermSynthesis elaborate context
    (fun current => elaborate current source none)
  let condition ← match psElabCondition
      (fun current _ _ => pure { sourceValue with context := current })
      sourceValue.context source with
    | .ok condition => pure condition
    | .error error => do
      if psElabErrorIsResource error then throw error
      let decisionContext ← psElabClassicalContext sourceValue.context
      psElabCondition (fun current _ _ => pure { sourceValue with context := current })
        decisionContext source
  let context := psElabLeaveScope sourceValue.context condition.context
  let branchName ← match name with
    | none => pure (PsName.num (psRootName "_byCases") context.localContext.nextId)
    | some name => do
      let some name := psSyntaxNameToName name | throw .emptyName
      pure name
  let positiveLocal := psLocalPushBinding context.localContext
    branchName condition.proposition .explicit
  let positiveContext := psElabContextWithLocal context positiveLocal.context
  let positive := psMetaFresh positiveContext.metaContext positiveContext.localContext
    target .syntheticOpaque { tag := psProofTag goal.tag "pos" }
  let .mvar positiveId := positive.expr | throw (.proof "invalid positive branch")
  let positive ← psElabAbstract context
    (psElabContextWithMeta positiveContext positive.context)
    [.lambdaE positiveLocal.id branchName condition.proposition .explicit]
    positive.expr (.forallE branchName condition.proposition target .explicit)
  let context := positive.context
  let negativeType := PsExpr.app (.constE (psRootName "Not") []) condition.proposition
  let negativeLocal := psLocalPushBinding context.localContext branchName negativeType .explicit
  let negativeContext := psElabContextWithLocal context negativeLocal.context
  let negative := psMetaFresh negativeContext.metaContext negativeContext.localContext
    target .syntheticOpaque { tag := psProofTag goal.tag "neg" }
  let .mvar negativeId := negative.expr | throw (.proof "invalid negative branch")
  let negative ← psElabAbstract context
    (psElabContextWithMeta negativeContext negative.context)
    [.lambdaE negativeLocal.id branchName negativeType .explicit]
    negative.expr (.forallE branchName negativeType target .explicit)
  let context := negative.context
  let level ← psElabExpressionSort context target
  let proof := psExprApplyMany (.constE (psRootName "dite") [level])
    [target, condition.proposition, condition.decision, positive.term, negative.term]
  let next ← psProofAssign (psProofUpdate state context) goal.id proof
  psProofNormalize { next with goals := [
    { id := positiveId, tag := psProofTag goal.tag "pos" },
    { id := negativeId, tag := psProofTag goal.tag "neg" }] ++ state.goals.drop 1 }
