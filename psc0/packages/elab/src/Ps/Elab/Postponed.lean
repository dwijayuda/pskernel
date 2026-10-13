import Ps.Elab.Basic

-- Only failures that can change after inference are resumable. Name/grammar,
-- resource and structural-recursion refusals remain immediate diagnostics.
def psElabErrorMayPostpone : PsElabError → Bool
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
    (expected : Option PsExpr) (defaulting : Bool := false) : PsElabTermResult :=
  let target := match expected with
    | some type => PsElabTypeResult.mk context type
    | none => psElabFreshType context
  let fresh := psMetaFresh target.context.metaContext target.context.localContext
    target.type .syntheticOpaque
  let context := psElabContextWithMeta target.context fresh.context
  let pending := match fresh.expr with
    | .mvar id => PsElabPendingWork.sourceTerm (psElabSaveScope context)
        id source defaulting :: context.pending
    | _ => context.pending
  { context := { context with pending }, term := fresh.expr, type := target.type }

-- A numeral can use later type information before the pinned Nat fallback.
-- Tactics must not turn an unresolved expected proposition into a guessed one.
def psElabDelayBefore (context : PsElabContext) (source : PsSyntaxTerm)
    (expected : Option PsExpr) : Option Bool := do
  if !context.postponing then none else
  let type ← expected
  let type := psWhnf context.environment context.metaContext context.localContext type
  match source with
  | .natural _ _ => match type with | .mvar _ => some true | _ => none
  | .record _ _ => match type with | .mvar _ => some false | _ => none
  | .byE _ _ _ => if psExprHasTermMeta type then some false else none
  | _ => none

def psElabWithPostponement (attempt : Unit → Except PsElabError PsElabTermResult)
    (context : PsElabContext) (source : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabDelayBefore context source expected with
  | some defaulting => .ok (psElabSuspend context source expected defaulting)
  | none => match attempt () with
    | .ok result => .ok result
    | .error error =>
      if context.postponing && psElabErrorMayPostpone error &&
          psElabHasPendingInput context expected then
        .ok (psElabSuspend context source expected)
      else .error error

def psElabPendingIsDefault : PsElabPendingWork → Bool
  | .core _ constraint => psSyntheticIsDefault constraint
  | .sourceTerm _ _ _ defaulting => defaulting

def psElabResumeWork (elaborate : PsElaborator) (context : PsElabContext)
    (work : PsElabPendingWork) : Except PsElabError PsElabContext := do
  match work with
  | .core scope constraint =>
    let some metaContext := psSyntheticAttempt scope.environment scope.instances
        context.metaContext constraint |
      match constraint with
      | .instanceGoal _ => throw .implicitApplicationUnsupported
      | _ => throw .typeMismatch
    return psElabContextWithMeta context metaContext
  | .sourceTerm scope id source _ =>
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
    let some metaContext := psSyntheticAssign saved.environment result.context.metaContext
        id result.term | throw .typeMismatch
    return psElabLeaveScope context (psElabContextWithMeta result.context metaContext)

def psElabDrainPending (elaborate : PsElaborator) (result : PsElabTermResult)
    (limit : Nat := 32768) : Except PsElabError PsElabTermResult := do
  let context := { result.context with pending := [], postponing := false }
  let attempt := fun current work =>
    (psElabResumeWork elaborate current work).toOption
  let solved := psSyntheticQueueSolve attempt psElabPendingIsDefault context
    result.context.pending.reverse true limit
  if solved.resourceExceeded then throw .fuelExhausted
  -- Re-run just the first blocked item for its owning diagnostic. The queue
  -- attempt has already rolled back every unsuccessful speculative change.
  if let some work := solved.pending.head? then
    let _ ← psElabResumeWork elaborate solved.context work
    throw .unresolvedMetavariable
  return psElabResultWithMeta { result with context := solved.context }
    solved.context.metaContext result.type
