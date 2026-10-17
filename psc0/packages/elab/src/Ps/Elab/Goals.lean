import Ps.Elab.Binders

-- Goals refer to the same typed metavariables used by term elaboration.
-- Local IDs are allocated globally within a proof, even across sibling goals.
structure PsProofGoal where
  id : Nat
  tag : String := ""

structure PsProofState where
  context : PsElabContext
  goals : List PsProofGoal

def psProofContext (state : PsProofState) (id : Nat) : Except PsElabError PsElabContext := do
  let some goal := psMetaFindDecl state.context.metaContext id
    | throw (.proof "unknown goal")
  return { state.context with localContext := {
    goal.localContext with nextId := max goal.localContext.nextId state.context.localContext.nextId } }

def psProofUpdate (state : PsProofState) (context : PsElabContext) : PsProofState :=
  { state with context := psElabLeaveScope state.context context }

def psProofAssign (state : PsProofState) (id : Nat) (value : PsExpr) :
    Except PsElabError PsProofState := do
  let context ← psProofContext state id
  let some goal := psMetaFindDecl context.metaContext id | throw (.proof "unknown goal")
  let checked ← psElabResolvedTerm context value (some goal.type)
  let some constraints := psMetaAssign checked.context.metaContext id checked.term
    | throw (.proof "invalid goal assignment")
  return psProofUpdate state (psElabContextWithMeta checked.context constraints)

-- Shared metavariable assignment settles term and tactic scope closures.
def psProofNormalize (state : PsProofState) : Except PsElabError PsProofState := do
  let some constraints := psMetaNormalizeDelayed
      state.context.metaContext.delayed.length state.context.metaContext
    | throw (.proof "invalid scope closure")
  return { state with
    context := psElabContextWithMeta state.context constraints
    goals := state.goals.filter fun goal =>
      (psMetaFindAssignment constraints goal.id).isNone &&
      (psMetaFindDelayed constraints goal.id).isNone }

def psProofFreshGoals (before : Nat) (context : PsElabContext) : List PsProofGoal :=
  context.metaContext.declarations.reverse.filterMap fun entry =>
    if entry.id >= before && (psMetaFindAssignment context.metaContext entry.id).isNone &&
        (psMetaFindDelayed context.metaContext entry.id).isNone then
      some { id := entry.id, tag := entry.origin.tag }
    else none

def psProofIntro (state : PsProofState) (source : Option PsSyntaxName) :
    Except PsElabError PsProofState := do
  let state ← psProofNormalize state
  let goal :: rest := state.goals | throw (.proof "no goals to introduce")
  let context ← psProofContext state goal.id
  let some declaration := psMetaFindDecl context.metaContext goal.id
    | throw (.proof "unknown goal")
  let pi ← (psInferEnsureForall context.environment context.metaContext
    context.localContext declaration.type).mapError PsElabError.infer
  let name ← match source with
    | none => pure pi.name
    | some source => match psSyntaxNameToName source with
      | none => throw .emptyName
      | some name => pure name
  let pushed := psLocalPushBinding context.localContext name pi.domain pi.binder
  let context := psElabContextWithLocal context pushed.context
  let fresh := psMetaFresh context.metaContext context.localContext
    (psExprInstantiate1 pi.body (.fvar pushed.id)) .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid fresh goal")
  let some constraints := psMetaAssignDelayed fresh.context goal.id
      [.lambdaE pushed.id name pi.domain pi.binder] fresh.expr
    | throw (.proof "invalid intro scope")
  let context := psElabContextWithMeta context constraints
  return { (psProofUpdate state context) with
    goals := { id := child, tag := goal.tag } :: rest }

-- A completed local fact enters only this goal's context. Closing its scope
-- uses the same deferred abstraction as intro, including nested proof goals.
def psProofLocal (state : PsProofState) (name : PsName) (value : PsElabTermResult)
    (reducible : Bool) : Except PsElabError PsProofState := do
  let goal :: rest := state.goals | throw (.proof "no goal for local declaration")
  let some declaration := psMetaFindDecl value.context.metaContext goal.id
    | throw (.proof "unknown goal")
  let type := psMetaInstantiate value.context.metaContext value.type
  let term := psMetaInstantiate value.context.metaContext value.term
  if psExprHasTermMeta type || psExprHasTermMeta term then
    throw (.proof "local declaration has unresolved holes")
  let pushed := if reducible then
      psLocalPushLet value.context.localContext name type term
    else psLocalPushBinding value.context.localContext name type .explicit
  let context := psElabContextWithLocal value.context pushed.context
  let fresh := psMetaFresh context.metaContext context.localContext declaration.type .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid fresh goal")
  let some constraints := psMetaAssignDelayed fresh.context goal.id
      [.letE pushed.id name type term] fresh.expr
    | throw (.proof "invalid local declaration scope")
  let context := psElabContextWithMeta context constraints
  return { (psProofUpdate state context) with
    goals := { id := child, tag := goal.tag } :: rest }
