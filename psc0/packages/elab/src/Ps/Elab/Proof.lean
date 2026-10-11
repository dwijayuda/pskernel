import Ps.Elab.Elimination
import Ps.Elab.Application
import Ps.Elab.Equality

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
      { tag := psNameLastComponent pi.name }
    let context := psElabContextWithMeta current.context fresh.context
    psProofApplyTerm fuel {
      context, term := .app current.term fresh.expr
      type := psExprInstantiate1 pi.body fresh.expr } target

def psProofApplied (state : PsProofState) (goal : PsProofGoal) (before : Nat)
    (value : PsElabTermResult) : Except PsElabError PsProofState := do
  let pending := value.context.metaContext.declarations.filterMap fun entry =>
    match entry.kind with
    | .synthetic => if entry.id >= before then some entry.id else none
    | _ => none
  let value ← psElabSolvePendingInstances value pending
  let goals := (psProofFreshGoals before value.context).map fun child =>
    { child with tag := psProofTag goal.tag child.tag }
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
  let value ← match source with
    | .reference name => psElabReference context name none
    | _ => elaborate context source none
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

def psProofLocalValue (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (nameSyntax : PsSyntaxName) (annotation : Option PsSyntaxTerm)
    (source : PsSyntaxTerm) (reducible : Bool) : Except PsElabError PsProofState := do
  let (_, context, _) ← psProofMain state
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let annotation ← annotation.mapM (psProofSource scope context)
  let source ← psProofSource scope context source
  let value ← psElabLocalValue elaborate context annotation source
  psProofLocal state name value reducible

def psProofChange (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  let (goal, context, target) ← psProofMain state
  let source ← psProofSource scope context source
  let annotation ← psElabType elaborate context source
  let unified := psUnify annotation.context.environment annotation.context.localContext
    annotation.context.metaContext target annotation.type
  if !unified.success then throw (.proof "change requires a definitionally equal target")
  let context := psElabContextWithMeta annotation.context unified.context
  let fresh := psMetaFresh context.metaContext context.localContext
    (psMetaInstantiate context.metaContext annotation.type) .syntheticOpaque
  let .mvar child := fresh.expr | throw (.proof "invalid fresh goal")
  let state := psProofUpdate state (psElabContextWithMeta context fresh.context)
  let state ← psProofAssign state goal.id fresh.expr
  psProofNormalize { state with goals := { id := child, tag := goal.tag } :: state.goals.drop 1 }

-- Each candidate owns its source resolution and unification snapshot. A failed
-- show attempt cannot constrain a later goal. The selected goal moves first.
def psProofShow (elaborate : PsElaborator) (scope : PsSyntaxProofScope)
    (state : PsProofState) (source : PsSyntaxTerm) : Except PsElabError PsProofState := do
  for goal in state.goals do
    let selected := { state with goals := goal :: state.goals.filter (fun other => other.id != goal.id) }
    match psProofChange elaborate scope selected source with
    | .ok next => return next
    | .error _ => pure ()
  throw (.proof "show did not match any goal")

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
        | .localE name type source reducible _ =>
          psProofLocalValue elaborate scope state name type source reducible
        | .change source select _ =>
          if select then psProofShow elaborate scope state source
          else psProofChange elaborate scope state source
        | .eliminate source induction _ => psProofEliminate elaborate scope state source induction
        | .caseE tag names body _ => do
          let (selected, saved) ← psProofSelectCase state tag names
          let finished ← psProofRun elaborate scope fuel selected body
          if !finished.goals.isEmpty then throw (.proof "case left unsolved goals")
          pure { finished with goals := saved }
        | .intro names _ =>
          if names.isEmpty then psProofIntro state none
          else names.foldlM (fun current name => psProofIntro current (some name)) state
        | .assumption _ => psProofAssumption state
        | .reflexivity _ => psProofReflexivity state
        | .constructor _ => psProofConstructor state
        | .each body any _ => do
          let mut current := state
          let mut goals := []
          let mut succeeded := false
          for goal in state.goals do
            if (psMetaFindAssignment current.context.metaContext goal.id).isSome then continue
            match psProofRun elaborate scope fuel { current with goals := [goal] } body with
            | .ok next =>
              current := next
              goals := goals ++ next.goals
              succeeded := true
            | .error error =>
              if !any then throw error
              goals := goals ++ [goal]
          if any && !succeeded then throw (.proof "tactic failed on all goals")
          pure { current with goals }
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
  if !state.goals.isEmpty then throw (.proof "unsolved goals")
  let value := psMetaInstantiate state.context.metaContext fresh.expr
  if psExprHasTermMeta value then throw (.proof "unresolved proof")
  psElabResolvedTerm (psElabLeaveScope context state.context) value expected
