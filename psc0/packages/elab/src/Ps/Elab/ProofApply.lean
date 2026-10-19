import Ps.Elab.ProofTerm
import Ps.Elab.Application

-- Application creates typed goals over the current telescope. Failed target
-- unification is discarded before opening the next binder.
def psProofApplyTerm (fuel : Nat) (current : PsElabTermResult) (target : PsExpr) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let unified := psUnify current.context.environment current.context.localContext
      current.context.metaContext current.type target
    if unified.resourceExceeded then throw .fuelExhausted
    if unified.success then
      return { current with context := psElabContextWithMeta current.context unified.context }
    let pi ← (psInferEnsureForall current.context.environment current.context.metaContext
      current.context.localContext current.type).mapError PsElabError.infer
    let fresh := psMetaFresh current.context.metaContext current.context.localContext pi.domain
      (if psBinderIsInstanceImplicit pi.binder then .synthetic else .natural)
      { tag := psNameLastComponent pi.name }
    let context := psElabContextWithMeta current.context fresh.context
    psProofApplyTerm fuel {
      context, term := .app current.term fresh.expr
      type := psExprInstantiate1 pi.body fresh.expr } target

def psProofApplied (state : PsProofState) (goal : PsProofGoal) (before : Nat)
    (value : PsElabTermResult) (allGoals : Bool := false) : Except PsElabError PsProofState := do
  let pending := value.context.metaContext.declarations.filterMap fun entry =>
    match entry.kind with
    | .synthetic => if entry.id >= before then some entry.id else none
    | _ => none
  let value ← psElabSolveSynthetic value (pending.map PsSyntheticConstraint.instanceGoal)
  let goals := (psProofFreshGoals before value.context).map fun child =>
    { child with tag := psProofTag goal.tag child.tag }
  let dependent := fun goal => goals.any fun other =>
    match psMetaFindDecl value.context.metaContext other.id with
    | none => false
    | some other => psExprContainsMVar goal.id (psMetaInstantiate value.context.metaContext other.type)
  let ordered := if allGoals then goals else
    goals.filter (fun goal => !dependent goal) ++ goals.filter dependent
  let state ← psProofAssign (psProofUpdate state value.context) goal.id value.term
  psProofNormalize { state with goals := ordered ++ state.goals.drop 1 }

def psProofApply (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← match source with
    | .reference name => psElabReference context name none
    | _ => elaborate context source none
  let value ← psProofApplyTerm 4096 value target
  psProofApplied state goal context.metaContext.nextId value

