import Ps.Elab.Basic

-- Only failures that can change after inference are resumable. Name/grammar,
-- resource and structural-recursion refusals remain immediate diagnostics.
def psElabErrorMayPostpone (error : PsElabError) : Bool :=
  if psElabErrorIsResource error then false else
  match error with
  | .typeMismatch | .implicitApplicationUnsupported | .unresolvedMetavariable
  | .unsupportedTerm | .infer _ | .matchExpectedType | .matchScrutineeUnsupported
  | .proof _ => true
  | _ => false

def psElabHasPendingInput (context : PsElabContext) (expected : Option PsExpr) : Bool :=
  let unresolved := fun term =>
    psExprHasTermMeta (psMetaInstantiate context.metaContext term)
  (expected.toList.any unresolved) ||
    context.localContext.declarations.any (fun localDecl =>
      unresolved (psLocalDeclType localDecl))

def psElabSuspend (context : PsElabContext) (source : PsSyntaxTerm)
    (expected : Option PsExpr) : PsElabTermResult :=
  let target := match expected with
    | some type => PsElabTypeResult.mk context type
    | none => psElabFreshType context
  let fresh := psMetaFresh target.context.metaContext target.context.localContext
    target.type .syntheticOpaque
  let context := psElabContextWithMeta target.context fresh.context
  let pending := match fresh.expr with
    | .mvar id => PsElabPendingWork.sourceTerm (psElabSaveScope context)
        id source :: context.pending
    | _ => context.pending
  { context := { context with pending }, term := fresh.expr, type := target.type }

-- Syntax continuations wait for structural information. Numerals now own
-- ordinary OfNat constraints and share the same default-instance scheduling.
def psElabDelayBefore (context : PsElabContext) (source : PsSyntaxTerm)
    (expected : Option PsExpr) : Bool :=
  if !context.postponing then false else
  match expected with
  | none => false
  | some type =>
    let type := psWhnf context.environment context.metaContext context.localContext type
    match source with
    | .record _ _ => psElabExpectedTypeIsUnconstrained context type
    | .byE _ _ _ => psExprHasTermMeta type
    | _ => false

def psElabWithPostponement (attempt : Unit → Except PsElabError PsElabTermResult)
    (context : PsElabContext) (source : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  if psElabDelayBefore context source expected then
    .ok (psElabSuspend context source expected)
  else match attempt () with
    | .ok result => .ok result
    | .error error =>
      if context.postponing && psElabErrorMayPostpone error &&
          psElabHasPendingInput context expected then
        .ok (psElabSuspend context source expected)
      else .error error

def psElabPendingIsDefault : PsElabPendingWork → Bool
  | .core _ constraint => psSyntheticIsDefault constraint
  | .expectedTerm _ _ _ _ => false
  | .sourceTerm _ _ _ => false

def psElabResumeWork (elaborate : PsElaborator) (context : PsElabContext)
    (work : PsElabPendingWork) : Except PsElabError PsElabContext := do
  match work with
  | .core scope constraint =>
    let attempted ← (psSyntheticAttemptChecked scope.environment scope.instances
      context.metaContext constraint).mapError (fun _ => PsElabError.fuelExhausted)
    let some metaContext := attempted |
      match constraint with
      | .instanceGoal _ => throw .implicitApplicationUnsupported
      | _ => throw .typeMismatch
    return psElabContextWithMeta context metaContext
  | .expectedTerm scope id value actual =>
    let saved := psElabRestoreScope { context with postponing := false } scope
    let some declaration := psMetaFindDecl saved.metaContext id | throw .unresolvedMetavariable
    let result ← psElabFinalizeExpected
      { context := saved, term := psMetaInstantiate saved.metaContext value,
        type := psMetaInstantiate saved.metaContext actual }
      (some (psMetaInstantiate saved.metaContext declaration.type))
    let assigned ← (psSyntheticAssignChecked saved.environment result.context.metaContext
      id result.term).mapError (fun _ => PsElabError.fuelExhausted)
    let some metaContext := assigned | throw .typeMismatch
    return psElabLeaveScope context (psElabContextWithMeta result.context metaContext)
  | .sourceTerm scope id source =>
    let saved := psElabRestoreScope { context with postponing := false } scope
    let some declaration := psMetaFindDecl saved.metaContext id
      | throw .unresolvedMetavariable
    let type := psMetaInstantiate saved.metaContext declaration.type
    -- Delay proof scripts until their goal is fixed, including in the final
    -- diagnostic pass. Ordinary term elaboration can still infer a type.
    match source with
    | .byE _ _ _ =>
      if psExprHasTermMeta type then throw (.proof "postponed tactic goal is unresolved")
    | _ => pure ()
    let result ← elaborate saved source (some type)
    let assigned ← (psSyntheticAssignChecked saved.environment result.context.metaContext
      id result.term).mapError (fun _ => PsElabError.fuelExhausted)
    let some metaContext := assigned | throw .typeMismatch
    return psElabLeaveScope context (psElabContextWithMeta result.context metaContext)

-- Ordinary blocked work remains retryable; an actual resource refusal aborts
-- the checked worklist before another item or default can run.
def psElabResumeWorkAttempt (elaborate : PsElaborator) (context : PsElabContext)
    (work : PsElabPendingWork) : Except Unit (Option PsElabContext) :=
  match psElabResumeWork elaborate context work with
  | .ok result => .ok (some result)
  | .error error => if psElabErrorIsResource error then .error () else .ok none

def psElabPendingPriorities : PsElabPendingWork → List Nat
  | .core scope constraint => psSyntheticConstraintPriorities scope.instances constraint
  | _ => []

def psElabResumeDefault (context : PsElabContext)
    (work : PsElabPendingWork) (priority : Nat) : Except Unit (Option PsElabContext) :=
  match work with
  | .core scope constraint =>
    (psSyntheticAttemptDefault scope.environment scope.instances
      context.metaContext constraint priority).map
        (fun result => result.map (psElabContextWithMeta context))
  | _ => .ok none

-- Before propagating an eligible application result, resolve ready instance
-- work from earlier arguments. Keep defaults, expected-term adaptations and
-- source continuations on their existing queues and preserve captured scopes.
def psElabProgressInstancePending (context : PsElabContext)
    (limit : Nat := 32768) : Except PsElabError PsElabContext := do
  let attempt := fun (current : PsElabContext) (work : PsElabPendingWork) =>
    match work with
    | .core scope (.instanceGoal id) =>
      (psSyntheticAttemptChecked scope.environment scope.instances current.metaContext
        (.instanceGoal id)).map (fun result => result.map (psElabContextWithMeta current))
    | _ => .ok none
  let solved := psSyntheticQueueSolveChecked attempt psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    { context with pending := [] } context.pending.reverse false limit
  if solved.resourceExceeded then throw .fuelExhausted
  return { solved.context with
    pending := solved.pending.reverse
    postponing := context.postponing }

-- Expected-result comparison may learn an instance's input type before a
-- class-field reduction blocks. Recover only that blocking queued instance,
-- inside the current equality transaction. This follows pinned Lean 4.35.0
-- Meta/ExprDefEq.unstuckMVar and Meta/SynthInstance.synthPendingImp; no defaults
-- or source/expected-term continuations run here.
private def psElabProjectionMajorMeta (context : PsElabContext)
    (metaContext : PsMetaContext) (fuel : Nat) (expression : PsExpr) : Option Nat :=
  match fuel with
  | 0 => none
  | fuel + 1 =>
    let view := psReduceAppView
      (psWhnf context.environment metaContext context.localContext expression)
    match view.head with
    | .mvar id => some id
    | .proj _ _ major => psElabProjectionMajorMeta context metaContext fuel major
    | _ => none

def psElabRecoverPendingProjection (context : PsElabContext)
    (metaContext : PsMetaContext) (left right : PsExpr) : Option PsUnifyResult := Id.run do
  for expression in [left, right] do
    -- The unifier supplies weak-head operands. Follow a projection's reduction
    -- dependency, never arbitrary argument holes or unrelated pending work.
    let .proj _ _ major := (psReduceAppView expression).head | continue
    let some id := psElabProjectionMajorMeta context metaContext 256 major | continue
    if (psMetaFindAssignment metaContext id).isSome then continue
    let some declaration := psMetaFindDecl metaContext id | continue
    match declaration.kind with
    | .syntheticOpaque => continue
    | _ => pure ()
    let scope? := context.pending.findSome? fun work =>
      match work with
      | .core scope (.instanceGoal goalId) => if goalId == id then some scope else none
      | _ => none
    let some scope := scope? | continue
    -- The queued scope owns the environment/registry; the declaration owns
    -- its creation locals. A later caller instance cannot supply this evidence.
    let attempted := psSyntheticInstanceAttempt scope.environment scope.instances metaContext id
    if attempted.table.resourceExceeded then
      return some { context := metaContext, success := false, resourceExceeded := true }
    if attempted.result.value.isSome &&
        (psMetaFindAssignment attempted.result.context id).isSome then
      return some { context := attempted.result.context, success := true }
  return none

def psElabDrainPending (elaborate : PsElaborator) (result : PsElabTermResult)
    (limit : Nat := 32768) : Except PsElabError PsElabTermResult := do
  let context := { result.context with pending := [], postponing := false }
  let attempt := psElabResumeWorkAttempt elaborate
  let solved := psSyntheticQueueSolveChecked attempt psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    context result.context.pending.reverse true limit
  if solved.resourceExceeded then throw .fuelExhausted
  -- Re-run just the first blocked item for its owning diagnostic. The queue
  -- attempt has already rolled back every unsuccessful speculative change.
  if let some work := solved.pending.head? then
    let _ ← psElabResumeWork elaborate solved.context work
    throw .unresolvedMetavariable
  return psElabResultWithMeta { result with context := solved.context }
    solved.context.metaContext result.type

-- Lean Extra.toTree uses light synthesis before comparing operand types.
-- Source continuations retain their scopes and wait for the ordinary drain:
-- resuming them with postponing=false here could prematurely apply defaults.
def psElabProgressPending (elaborate : PsElaborator) (context : PsElabContext)
    (limit : Nat := 32768) : Except PsElabError PsElabContext := do
  let attempt := fun current work =>
    match work with
    | .sourceTerm .. => .ok none
    | _ => psElabResumeWorkAttempt elaborate current work
  let solved := psSyntheticQueueSolveChecked attempt psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    { context with pending := [] } context.pending.reverse false limit
  if solved.resourceExceeded then throw .fuelExhausted
  return { solved.context with
    pending := solved.pending.reverse
    postponing := context.postponing }
