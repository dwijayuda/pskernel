import Ps.Elab.Basic

private def psElabDiagnosticPrefix : String := "PSCV0-ELAB-DIAGNOSTIC: "

-- Only failures that can change after inference are resumable. Name/grammar,
-- resource and structural-recursion refusals remain immediate diagnostics.
def psElabErrorMayPostpone : PsElabError → Bool
  | .typeMismatch | .implicitApplicationUnsupported | .unresolvedMetavariable
  | .unsupportedTerm | .infer _ | .matchExpectedType | .matchScrutineeUnsupported
  | .proof _ => true
  | .atContext label error =>
    label.startsWith psElabDiagnosticPrefix && psElabErrorMayPostpone error
  | _ => false

-- Temporary diagnostics are transparent to retry classification. All other
-- failures retain their original constructors for owner-specific fallbacks.
-- The description is evaluated only for a retryable error, never on success.
def psElabDiagnosticError (describe : Unit → String) (error : PsElabError) : PsElabError :=
  if psElabErrorMayPostpone error then
    .atContext (psElabDiagnosticPrefix ++ describe ()) error
  else error

-- Bounded sketches retain open term/universe identities and mask string data.
def psElabDiagnosticLevelSketch (fuel : Nat) (level : PsLevel) : String :=
  match fuel with
  | 0 => "..."
  | fuel + 1 =>
    match level with
    | .zero => "0"
    | .succ inner => "succ(" ++ psElabDiagnosticLevelSketch fuel inner ++ ")"
    | .max left right =>
      "max(" ++ psElabDiagnosticLevelSketch fuel left ++ "," ++
        psElabDiagnosticLevelSketch fuel right ++ ")"
    | .imax left right =>
      "imax(" ++ psElabDiagnosticLevelSketch fuel left ++ "," ++
        psElabDiagnosticLevelSketch fuel right ++ ")"
    | .param name => psNameToString name
    | .mvar id => "?u" ++ psNatToString id

def psElabDiagnosticBinderSketch : PsBinderInfo → String
  | .explicit => "explicit"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instanceImplicit"

def psElabDiagnosticExprSketch (fuel : Nat) (expression : PsExpr) : String :=
  match fuel with
  | 0 => "..."
  | fuel + 1 =>
    let child := psElabDiagnosticExprSketch fuel
    match expression with
    | .bvar index => "#" ++ psNatToString index
    | .fvar id => "f#" ++ psNatToString id
    | .mvar id => "?m" ++ psNatToString id
    | .sortE level => "Sort(" ++ psElabDiagnosticLevelSketch 4 level ++ ")"
    | .constE name levels =>
      let universes := (levels.take 4).map (psElabDiagnosticLevelSketch 4)
      psNameToString name ++ ".{" ++ String.intercalate "," universes ++
        (if levels.length > 4 then ",..." else "") ++ "}"
    | .app function argument => "(" ++ child function ++ " " ++ child argument ++ ")"
    | .lam name type body binder =>
      "(lam " ++ psElabDiagnosticBinderSketch binder ++ " " ++ psNameToString name ++
        " : " ++ child type ++ " => " ++ child body ++ ")"
    | .forallE name type body binder =>
      "(forall " ++ psElabDiagnosticBinderSketch binder ++ " " ++ psNameToString name ++
        " : " ++ child type ++ ", " ++ child body ++ ")"
    | .letE name type value body =>
      "(let " ++ psNameToString name ++ " : " ++ child type ++ " := " ++
        child value ++ "; " ++ child body ++ ")"
    | .lit (.natural value) => psNatToString value
    | .lit (.string _) => "<string>"
    | .proj name index value =>
      "(proj " ++ psNameToString name ++ "." ++ psNatToString index ++ " " ++ child value ++ ")"

def psElabDiagnosticExpression (context : PsElabContext) (expression : PsExpr) : String :=
  psElabDiagnosticExprSketch 12 (psMetaInstantiate context.metaContext expression)

def psElabDiagnosticExpected (context : PsElabContext) (expected : Option PsExpr) : String :=
  match expected with
  | none => "<none>"
  | some type => psElabDiagnosticExpression context type

def psElabDiagnosticGoalType (context : PsElabContext) (id : Nat) : String :=
  match psMetaFindDecl context.metaContext id with
  | none => "<missing>"
  | some declaration => psElabDiagnosticExpression context declaration.type

def psElabDiagnosticLocals (locals : PsLocalContext) : String :=
  let entries := (locals.declarations.take 24).map fun declaration =>
    psNameToString (psLocalDeclUserName declaration) ++ "@f#" ++
      psNatToString (psLocalDeclId declaration)
  "next=" ++ psNatToString locals.nextId ++ "; newest-first(" ++
    psNatToString locals.declarations.length ++ ")=[" ++ String.intercalate "," entries ++
    (if locals.declarations.length > 24 then ",..." else "") ++ "]"

def psElabDiagnosticConstraint (context : PsElabContext)
    (constraint : PsSyntheticConstraint) : String :=
  match constraint with
  | .instanceGoal id => "instance ?m" ++ psNatToString id ++ " : " ++
      psElabDiagnosticGoalType context id
  | .expectedType locals actual expected =>
      "expectedType " ++ psElabDiagnosticExpression context actual ++ " ~ " ++
        psElabDiagnosticExpression context expected ++ "; locals=[" ++
        psElabDiagnosticLocals locals ++ "]"
  | .defaultValue id value => "default ?m" ++ psNatToString id ++ " := " ++
      psElabDiagnosticExpression context value

def psElabDiagnosticConstraints (context : PsElabContext)
    (constraints : List PsSyntheticConstraint) : String :=
  "[" ++ String.intercalate " | "
    ((constraints.take 12).map (psElabDiagnosticConstraint context)) ++
    (if constraints.length > 12 then " | ..." else "") ++ "]"

def psElabDiagnosticPending (context : PsElabContext) (work : PsElabPendingWork) : String :=
  match work with
  | .core _ constraint => "core " ++ psElabDiagnosticConstraint context constraint
  | .expectedTerm scope id value actual =>
    "expectedTerm ?m" ++ psNatToString id ++ "; term=" ++
      psElabDiagnosticExpression context value ++ "; actual=" ++
      psElabDiagnosticExpression context actual ++ "; target=" ++
      psElabDiagnosticGoalType context id ++ "; saved-locals=[" ++
      psElabDiagnosticLocals scope.localContext ++ "]"
  | .sourceTerm scope id source =>
    let span := psSyntaxTermSpan source
    "sourceTerm ?m" ++ psNatToString id ++ "; source-span=" ++
      psNatToString span.start.byteOffset ++ ".." ++ psNatToString span.stop.byteOffset ++
      "; target=" ++ psElabDiagnosticGoalType context id ++ "; saved-locals=[" ++
      psElabDiagnosticLocals scope.localContext ++ "]"

def psElabDiagnosticPendingList (context : PsElabContext) (pending : List PsElabPendingWork) :
    String :=
  "[" ++ String.intercalate " | " ((pending.take 12).map (psElabDiagnosticPending context)) ++
    (if pending.length > 12 then " | ..." else "") ++ "]"

def psElabDiagnosticContext (context : PsElabContext) : String :=
  let span := match context.sourceSpan with
    | none => "<none>"
    | some span => psNatToString span.start.byteOffset ++ ".." ++
        psNatToString span.stop.byteOffset
  let metas := (context.metaContext.declarations.take 24).map fun declaration =>
    let kind := match declaration.kind with
      | .natural => "natural"
      | .synthetic => "synthetic"
      | .syntheticOpaque => "syntheticOpaque"
    let value := match psMetaFindAssignment context.metaContext declaration.id with
      | none => if (psMetaFindDelayed context.metaContext declaration.id).isSome then
          "<delayed>" else "<unassigned>"
      | some value => psElabDiagnosticExprSketch 8
          (psMetaInstantiate context.metaContext value)
    "?m" ++ psNatToString declaration.id ++ ":" ++ kind ++ " : " ++
      psElabDiagnosticExprSketch 8
        (psMetaInstantiate context.metaContext declaration.type) ++ " := " ++ value
  "span=" ++ span ++ "; postponing=" ++ (if context.postponing then "true" else "false") ++
    "; locals=[" ++ psElabDiagnosticLocals context.localContext ++
    "]; metas-next=" ++ psNatToString context.metaContext.nextId ++ "; metas-newest-first(" ++
    psNatToString context.metaContext.declarations.length ++ ")=[" ++
    String.intercalate " | " metas ++
    (if context.metaContext.declarations.length > 24 then " | ..." else "") ++
    "]; pending-newest-first(" ++ psNatToString context.pending.length ++ ")=" ++
    psElabDiagnosticPendingList context context.pending

def psElabDiagnosticResult (result : PsElabTermResult) : String :=
  "term=" ++ psElabDiagnosticExpression result.context result.term ++
    "; type=" ++ psElabDiagnosticExpression result.context result.type ++
    "; context=[" ++ psElabDiagnosticContext result.context ++ "]"

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
    | .record _ _ => match type with | .mvar _ => true | _ => false
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
    let some metaContext := psSyntheticAttempt scope.environment scope.instances
        context.metaContext constraint |
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
    let some metaContext := psSyntheticAssign saved.environment result.context.metaContext
        id result.term | throw .typeMismatch
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
    let some metaContext := psSyntheticAssign saved.environment result.context.metaContext
        id result.term | throw .typeMismatch
    return psElabLeaveScope context (psElabContextWithMeta result.context metaContext)

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
      (psSyntheticAttempt scope.environment scope.instances current.metaContext
        (.instanceGoal id)).map (psElabContextWithMeta current)
    | _ => none
  let solved := psSyntheticQueueSolve attempt psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    { context with pending := [] } context.pending.reverse false limit
  if solved.resourceExceeded then throw .fuelExhausted
  return { solved.context with
    pending := solved.pending.reverse
    postponing := context.postponing }

def psElabDrainPending (elaborate : PsElaborator) (result : PsElabTermResult)
    (limit : Nat := 32768) : Except PsElabError PsElabTermResult := do
  let context := { result.context with pending := [], postponing := false }
  let attempt := fun current work =>
    (psElabResumeWork elaborate current work).toOption
  let solved := psSyntheticQueueSolve attempt psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    context result.context.pending.reverse true limit
  if solved.resourceExceeded then throw .fuelExhausted
  -- Re-run just the first blocked item for its owning diagnostic. The queue
  -- attempt has already rolled back every unsuccessful speculative change.
  if let some work := solved.pending.head? then
    let _ ← (psElabResumeWork elaborate solved.context work).mapError
      (psElabDiagnosticError (fun _ =>
        let scope := match work with
          | .core scope _ | .expectedTerm scope _ _ _ | .sourceTerm scope _ _ => scope
        let saved := psElabRestoreScope { solved.context with postponing := false } scope
        "drain blocked-work; work=[" ++ psElabDiagnosticPending saved work ++
          "]; retained-context=[" ++ psElabDiagnosticContext saved ++
          "]; remaining-queue(" ++ psNatToString solved.pending.length ++ ")=" ++
          psElabDiagnosticPendingList saved solved.pending))
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
    | .sourceTerm .. => none
    | _ => (psElabResumeWork elaborate current work).toOption
  let solved := psSyntheticQueueSolve attempt psElabPendingIsDefault
    psElabPendingPriorities psElabResumeDefault
    { context with pending := [] } context.pending.reverse false limit
  if solved.resourceExceeded then throw .fuelExhausted
  return { solved.context with
    pending := solved.pending.reverse
    postponing := context.postponing }
