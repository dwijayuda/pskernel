import Ps.Elab.Goals
import Ps.Elab.Application
import Ps.Elab.Equality
import Ps.Elab.Scope

def psProofSource (scope : PsSyntaxProofScope) (context : PsElabContext)
    (source : PsSyntaxTerm) : Except PsElabError PsSyntaxTerm := do
  let bound := context.localContext.declarations.map fun entry =>
    psNameLastComponent (psLocalDeclUserName entry)
  let resolved ← psScopeTerm 4096 {
    environment := context.environment
    scope := { namePrefix := scope.namePrefix, opened := scope.opened } } bound source
  return resolved.term

def psProofMain (state : PsProofState) :
    Except PsElabError (PsProofGoal × PsElabContext × PsExpr) := do
  let some goal := state.goals.head? | throw (.proof "no goals")
  let context ← psProofContext state goal.id
  let some declaration := psMetaFindDecl context.metaContext goal.id
    | throw (.proof "unknown goal")
  return (goal, context, psMetaInstantiate context.metaContext declaration.type)

def psProofExact (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) (refine : Bool) :
    Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← elaborate context source (some target)
  if !refine && psExprHasTermMeta (psMetaInstantiate value.context.metaContext value.term) then
    throw (.proof "exact left unresolved holes")
  let pending := psProofFreshGoals context.metaContext.nextId value.context
  let state ← psProofAssign (psProofUpdate state value.context) goal.id value.term
  psProofNormalize { state with goals := pending ++ state.goals.drop 1 }

-- Application creates typed goals over the current telescope. Failed target
-- unification is discarded before opening the next binder.
def psProofApplyTerm (fuel : Nat) (current : PsElabTermResult) (target : PsExpr) :
    Except PsElabError PsElabTermResult := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let unified := psUnify current.context.environment current.context.localContext
      current.context.metaContext current.type target
    if unified.success then
      return { current with context := psElabContextWithMeta current.context unified.context }
    let pi ← (psInferEnsureForall current.context.environment current.context.metaContext
      current.context.localContext current.type).mapError PsElabError.infer
    let fresh := psMetaFresh current.context.metaContext current.context.localContext pi.domain
      (if psBinderIsInstanceImplicit pi.binder then .synthetic else .natural)
    let context := psElabContextWithMeta current.context fresh.context
    psProofApplyTerm fuel {
      context, term := .app current.term fresh.expr
      type := psExprInstantiate1 pi.body fresh.expr } target

def psProofApplied (state : PsProofState) (goal : PsProofGoal) (before : Nat)
    (value : PsElabTermResult) : Except PsElabError PsProofState := do
  let goals := psProofFreshGoals before value.context
  let dependent := fun goal => goals.any fun other =>
    match psMetaFindDecl value.context.metaContext other.id with
    | none => false
    | some other => psExprContainsMVar goal.id (psMetaInstantiate value.context.metaContext other.type)
  let ordered := goals.filter (fun goal => !dependent goal) ++ goals.filter dependent
  let state ← psProofAssign (psProofUpdate state value.context) goal.id value.term
  psProofNormalize { state with goals := ordered ++ state.goals.drop 1 }

def psProofApply (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let value ← elaborate context source none
  let value ← psProofApplyTerm 4096 value target
  psProofApplied state goal context.metaContext.nextId value

def psProofAssumption (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, _) ← psProofMain state
  for declaration in context.localContext.declarations do
    match psProofAssign state goal.id (.fvar (psLocalDeclId declaration)) with
    | .ok next => return ← psProofNormalize next
    | .error _ => pure ()
  throw (.proof "assumption did not match a local declaration")

def psProofReflexivity (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let equation ← psElabEquationView context target (.mvar goal.id)
  let unified := psUnify context.environment context.localContext context.metaContext
    equation.left equation.right
  if !unified.success then throw (.proof "rfl requires definitionally equal sides")
  let context := psElabContextWithMeta context unified.context
  let value := psLogicRefl equation.level equation.type equation.left
  let next ← psProofAssign (psProofUpdate state context) goal.id value
  psProofNormalize next

def psProofConstructor (state : PsProofState) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let head := (psExprAppView (psWhnf context.environment context.metaContext context.localContext target)).head
  let .constE name _ := head | throw (.proof "constructor requires an inductive target")
  let some info := psEnvironmentFindInductive context.environment name
    | throw (.proof "constructor requires an inductive target")
  for constructor in info.constructors do
    let attempt := do
      let (context, term) ← psElabResolvedReference context (.global constructor)
      let value ← psElabResolvedTerm context term none
      let value ← psProofApplyTerm 4096 value target
      psProofApplied state goal state.context.metaContext.nextId value
    match attempt with
    | .ok next => return next
    | .error _ => pure ()
  throw (.proof "no constructor applies to the target")

def psProofRun (elaborate : PsElaborator) (scope : PsSyntaxProofScope) (fuel : Nat)
    (state : PsProofState) (tactics : List PsSyntaxTactic) : Except PsElabError PsProofState := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match tactics with
    | [] => psProofNormalize state
    | tactic :: rest =>
      let state ← psProofNormalize state
      let next ← match tactic with
        | .exactE source refine _ => psProofExact elaborate scope state source refine
        | .applyE source _ => psProofApply elaborate scope state source
        | .intro names _ =>
          if names.isEmpty then psProofIntro state none
          else names.foldlM (fun current name => psProofIntro current (some name)) state
        | .assumption _ => psProofAssumption state
        | .reflexivity _ => psProofReflexivity state
        | .constructor _ => psProofConstructor state
        | .focus body mustClose _ => do
          let goal :: saved := state.goals | throw (.proof "no goal to focus")
          let focused ← psProofRun elaborate scope fuel { state with goals := [goal] } body
          if mustClose && !focused.goals.isEmpty then throw (.proof "focused branch left unsolved goals")
          pure { focused with goals := focused.goals ++ saved }
      psProofRun elaborate scope fuel next rest

def psElabProof (elaborate : PsElaborator) (context : PsElabContext)
    (tactics : List PsSyntaxTactic) (scope : PsSyntaxProofScope) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let some target := expected | throw (.proof "by requires an expected type")
  let fresh := psMetaFresh context.metaContext context.localContext target .syntheticOpaque
  let .mvar root := fresh.expr | throw (.proof "invalid fresh goal")
  let state ← psProofRun elaborate scope 4096 {
    context := psElabContextWithMeta context fresh.context, goals := [{ id := root }] } tactics
  if !state.goals.isEmpty || !state.closures.isEmpty then throw (.proof "unsolved goals")
  let value := psMetaInstantiate state.context.metaContext fresh.expr
  if psExprHasTermMeta value then throw (.proof "unresolved proof")
  psElabResolvedTerm (psElabLeaveScope context state.context) value expected
