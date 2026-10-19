import Ps.Elab.ProofTerm

-- Lean 4.35.0 Init/Tactics.suffices and refine_lift allocate the antecedent
-- in the original goal scope and place it first. The completed proof may
-- itself leave typed holes under the opaque assumption. Existing delayed
-- abstraction closes those holes without moving the antecedent into that scope.
def psProofSuffices (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (nameSyntax : PsSyntaxName)
    (annotation source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let annotation ← psProofSource scope context annotation
  let (value, antecedent) ← psProofWithTermSynthesisAnd elaborate context fun current => do
    let type ← psElabType elaborate current annotation
    let fresh := psMetaFresh type.context.metaContext type.context.localContext
      type.type .syntheticOpaque { tag := goal.tag }
    let .mvar id := fresh.expr | throw (.proof "invalid suffices antecedent")
    let outer := psElabContextWithMeta type.context fresh.context
    let pushed := psLocalPushBinding outer.localContext name type.type .explicit
    let inner := psElabContextWithLocal outer pushed.context
    let source ← psProofSource scope inner source
    let proof ← elaborate inner source (some target)
    let value ← psElabAbstract outer proof.context
      [.letE pushed.id name type.type fresh.expr] proof.term target
    return (value, PsProofGoal.mk id goal.tag)
  let pending := psProofFreshGoals context.metaContext.nextId value.context
  let state ← psProofAssign (psProofUpdate state value.context) goal.id value.term
  psProofNormalize { state with goals :=
    [antecedent] ++ pending.filter (fun child => child.id != antecedent.id) ++ state.goals.drop 1 }
