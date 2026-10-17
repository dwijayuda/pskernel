import Ps.Meta.InstanceSearch

-- Constraints carry their own scope. Only checked, successful attempts commit;
-- a blocked attempt cannot leak speculative assignments into another item.
inductive PsSyntheticConstraint where
  | instanceGoal (id : Nat)
  | expectedType (locals : PsLocalContext) (actual expected : PsExpr)
  | defaultValue (id : Nat) (value : PsExpr)

-- One transactional worklist serves Core constraints and elaborator-owned
-- syntax continuations. Payloads and captured scopes remain with their owner.
structure PsSyntheticQueueResult (σ α : Type) where
  context : σ
  pending : List α
  attempts : Nat := 0
  resourceExceeded : Bool := false

abbrev PsSyntheticResult := PsSyntheticQueueResult PsMetaContext PsSyntheticConstraint

def psSyntheticAssignChecked (environment : PsEnvironment) (context : PsMetaContext)
    (id : Nat) (value : PsExpr) : Except Unit (Option PsMetaContext) := do
  let some declaration := psMetaFindDecl context id | return none
  let checked ← psInstanceCheckChecked environment declaration.localContext context declaration.type value
  let some checked := checked | return none
  let some value := checked.value | return none
  match psMetaFindAssignment checked.context id with
  | none => return psMetaAssign checked.context id value
  | some prior =>
    let unified := psUnify environment declaration.localContext checked.context prior value
    if unified.resourceExceeded then throw ()
    return if unified.success then some unified.context else none

def psSyntheticAssign (environment : PsEnvironment) (context : PsMetaContext)
    (id : Nat) (value : PsExpr) : Option PsMetaContext :=
  match psSyntheticAssignChecked environment context id value with
  | .ok result => result
  | .error () => none

-- Reuse one checked instance-attempt boundary for ordinary and nested-default
-- work. Search counters remain available to the enclosing default budget.
def psSyntheticInstanceAttempt (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (id : Nat) (limits : PsInstanceSearchLimits := {}) :
    PsInstanceTabledResult :=
  match psMetaFindDecl context id with
  | none => { result := psSynthFailure context, table := {} }
  | some declaration =>
    match psMetaFindAssignment context id with
    | some value =>
      match psSyntheticAssignChecked environment context id value with
      | .error () => { result := psSynthFailure context, table := { resourceExceeded := true } }
      | .ok (some checked) => { result := psSynthSuccess checked value, table := {} }
      | .ok none => { result := psSynthFailure context, table := {} }
    | none =>
      let searched := psSynthInstanceWithLimits environment declaration.localContext index
        context 64 limits (psMetaInstantiate context declaration.type)
      match searched.result.value with
      | none => searched
      | some value =>
        match psSyntheticAssignChecked environment searched.result.context id value with
        | .error () => { searched with result := psSynthFailure context,
            table := { searched.table with resourceExceeded := true } }
        | .ok (some checked) => { searched with result := psSynthSuccess checked value }
        | .ok none => { searched with result := psSynthFailure context }

def psSyntheticAttemptChecked (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) : PsSyntheticConstraint → Except Unit (Option PsMetaContext)
  | .expectedType locals actual expected =>
    let unified := psUnify environment locals context actual expected
    if unified.resourceExceeded then .error () else
    .ok (if unified.success then some unified.context else none)
  | .defaultValue id value => psSyntheticAssignChecked environment context id value
  | .instanceGoal id =>
    let checked := psSyntheticInstanceAttempt environment index context id
    if checked.table.resourceExceeded then .error () else
    .ok (checked.result.value.map (fun _ => checked.result.context))

def psSyntheticAttempt (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (constraint : PsSyntheticConstraint) : Option PsMetaContext :=
  match psSyntheticAttemptChecked environment index context constraint with
  | .ok result => result
  | .error () => none


-- Default-instance search follows Lean 4.35.0 Lean/Elab/SyntheticMVars.lean
-- (synthesizeUsingDefaultPrio / synthesizePending), Apache-2.0, Microsoft
-- Corporation, Leonardo de Moura and Sebastian Ullrich. Reuse PSC0's checked
-- telescope preparation and ordinary tabled search. Failed candidates roll
-- back their entire context; consumed search budget is never rolled back.
structure PsDefaultSearchResult where
  context : PsMetaContext
  remaining : Nat
  success : Bool := false
  exhausted : Bool := false

def psSyntheticDefaultPriorities (index : PsInstanceIndex) : List Nat :=
  (index.defaults.map (·.priority)).eraseDups

def psSyntheticInstanceClass (environment : PsEnvironment) (context : PsMetaContext)
    (id : Nat) : Option PsName := do
  let declaration ← psMetaFindDecl context id
  let type := psWhnfWithTransparency .instances environment context
    declaration.localContext (psMetaInstantiate context declaration.type)
  let .constE name _ := (psInferAppView type).head | none
  if environment.classes.any (psNameEq name) then some name else none

mutual
def psSyntheticDefaultSearch (fuel : Nat) (environment : PsEnvironment)
    (index : PsInstanceIndex) (context : PsMetaContext) (id priority remaining : Nat) :
    PsDefaultSearchResult :=
  match fuel with
  | 0 => { context, remaining, exhausted := true }
  | fuel + 1 => Id.run do
    let some declaration := psMetaFindDecl context id | return { context, remaining }
    let some className := psSyntheticInstanceClass environment context id
      | return { context, remaining }
    let mut remaining := remaining
    for entry in index.defaults do
      if entry.priority != priority ||
          !(entry.className.any (psNameEq className)) then continue
      if remaining == 0 then return { context, remaining, exhausted := true }
      remaining := remaining - 1
      let candidate := psPrepareInstance environment declaration.localContext context entry
      if !candidate.success then continue
      let checked := psUnifyWithTransparency .instances environment declaration.localContext
        candidate.context candidate.resultType declaration.type
      if checked.resourceExceeded then return { context, remaining, exhausted := true }
      if !checked.success then continue
      let pending := candidate.arguments.filterMap fun arg =>
        if arg.isInstance then
          match arg.expr with | .mvar id => some id | _ => none
        else none
      let solved := psSyntheticDefaultGoals fuel environment index checked.context pending.reverse remaining
      remaining := solved.remaining
      if solved.exhausted then return { context, remaining, exhausted := true }
      if !solved.success then continue
      match psSyntheticAssignChecked environment solved.context id candidate.value with
      | .error () => return { context, remaining, exhausted := true }
      | .ok (some next) => return { context := next, remaining, success := true }
      | .ok none => pure ()
    return { context, remaining }

def psSyntheticDefaultGoals (fuel : Nat) (environment : PsEnvironment)
    (index : PsInstanceIndex) (context : PsMetaContext) (pending : List Nat)
    (remaining : Nat) : PsDefaultSearchResult :=
  match fuel with
  | 0 => { context, remaining, exhausted := true }
  | fuel + 1 => Id.run do
    let pending := pending.filter fun id => (psMetaFindAssignment context id).isNone
    if pending.isEmpty then return { context, remaining, success := true }
    let mut current := context
    let mut remaining := remaining
    let mut unresolved := []
    for id in pending do
      if remaining == 0 then return { context, remaining, exhausted := true }
      remaining := remaining - 1
      let attempted := psSyntheticInstanceAttempt environment index current id {
        goals := remaining, candidates := remaining, transitions := remaining, answers := remaining }
      remaining := remaining - attempted.table.transitions
      if attempted.table.resourceExceeded then return { context, remaining, exhausted := true }
      if attempted.result.value.isSome then current := attempted.result.context
      else unresolved := id :: unresolved
    unresolved := unresolved.reverse
    if unresolved.length < pending.length then
      return psSyntheticDefaultGoals fuel environment index current unresolved remaining
    -- Nested dependencies follow Lean: reverse telescope order, then each
    -- goal's priorities. Only the outer scheduler orders priorities globally.
    for id in unresolved do
      for priority in psSyntheticDefaultPriorities index do
        let tried := psSyntheticDefaultSearch fuel environment index current id priority remaining
        remaining := tried.remaining
        if tried.exhausted then return { context, remaining, exhausted := true }
        if tried.success then
          return psSyntheticDefaultGoals fuel environment index tried.context unresolved remaining
    return { context, remaining }
end

-- Lean's trySynthInstance distinguishes a stuck input from definite failure:
-- an empty ordinary candidate set never reaches defaulting. Probe candidate
-- result types transactionally, with outputs masked by the shared target
-- preparation. This does not select evidence or assign caller metavariables.
def psSyntheticDefaultEligibility (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (id remaining : Nat) : Except Unit (Bool × Nat) := do
  let some declaration := psMetaFindDecl context id | return (false, remaining)
  if psInstanceGoalReady environment declaration.localContext context declaration.type then
    return (false, remaining)
  let some target := psPrepareInstanceTarget environment declaration.localContext context
      declaration.type false | return (false, remaining)
  let .constE name _ := (psInferAppView target.type).head | return (false, remaining)
  let entries := psLocalInstanceEntries declaration.localContext ++
    psInstanceRegistryEntries (psInstanceRegistry index) name
  let mut remaining := remaining
  for entry in entries do
    if remaining == 0 then throw ()
    remaining := remaining - 1
    let candidate := psPrepareInstance environment declaration.localContext target.context entry
    if !candidate.success then continue
    let checked := psUnifyWithTransparency .instances environment declaration.localContext
      candidate.context candidate.resultType target.type
    if checked.resourceExceeded then throw ()
    if checked.success then return (true, remaining)
  return (false, remaining)

def psSyntheticAttemptDefault (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (constraint : PsSyntheticConstraint) (priority : Nat) :
    Except Unit (Option PsMetaContext) :=
  match constraint with
  | .defaultValue id value =>
    if priority == 0 then psSyntheticAssignChecked environment context id value else .ok none
  | .instanceGoal id =>
    if (psMetaFindAssignment context id).isSome then
      psSyntheticAttemptChecked environment index context constraint
    else do
      let (eligible, remaining) ← psSyntheticDefaultEligibility environment index context id
        psInstanceMaxCandidateChecks
      if !eligible then return none
      let result := psSyntheticDefaultSearch 64 environment index context id priority remaining
      if result.exhausted then .error ()
      else .ok (if result.success then some result.context else none)
  | _ => .ok none

def psSyntheticConstraintPriorities (index : PsInstanceIndex) :
    PsSyntheticConstraint → List Nat
  | .defaultValue _ _ => [0]
  | .instanceGoal _ => psSyntheticDefaultPriorities index
  | _ => []

-- A rigid failure cannot be repaired by running unrelated work. Refuse it at
-- its owning boundary, before an ill-typed intermediate term is constructed.
def psSyntheticMayRetry (context : PsMetaContext) : PsSyntheticConstraint → Bool
  | .expectedType locals actual expected =>
    let unresolved := fun term => psExprHasUnresolvedMeta (psMetaInstantiate context term)
    unresolved actual || unresolved expected ||
      locals.declarations.any (fun localDecl => unresolved (psLocalDeclType localDecl))
  | .defaultValue _ _ => true
  | .instanceGoal id =>
    match psMetaFindDecl context id with
    | none => false
    | some declaration =>
      let unresolved := fun term => psExprHasUnresolvedMeta (psMetaInstantiate context term)
      unresolved declaration.type ||
        declaration.localContext.declarations.any
          (fun localDecl => unresolved (psLocalDeclType localDecl)) ||
        match psMetaFindAssignment context id with
        | some value => unresolved value
        | none => false

def psSyntheticIsDefault : PsSyntheticConstraint → Bool
  | .defaultValue _ _ => true
  | _ => false

def psSyntheticQueuePassChecked {σ α : Type}
    (attempt : σ → α → Except Unit (Option σ)) (isDefault : α → Bool)
    (limit : Nat) (pending : List α)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  match pending with
  | [] => { state with pending := state.pending.reverse }
  | constraint :: rest =>
    if isDefault constraint then
      psSyntheticQueuePassChecked attempt isDefault limit rest
        { state with pending := constraint :: state.pending }
    else if state.attempts >= limit then
      { state with pending := state.pending.reverse ++ pending, resourceExceeded := true }
    else
      match attempt state.context constraint with
      | .error () => { state with pending := state.pending.reverse ++ pending,
          attempts := state.attempts + 1, resourceExceeded := true }
      | .ok solved =>
        psSyntheticQueuePassChecked attempt isDefault limit rest {
          state with context := solved.getD state.context
                     pending := if solved.isSome then state.pending else constraint :: state.pending
                     attempts := state.attempts + 1 }

def psSyntheticQueuePass {σ α : Type}
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (limit : Nat) (pending : List α)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  psSyntheticQueuePassChecked (fun context constraint => .ok (attempt context constraint))
    isDefault limit pending state

-- Apply at most one default, then resume ordinary synthesis. The priority
-- belongs to each captured scope; an unrelated registry cannot supply evidence.
def psSyntheticQueueDefault {σ α : Type}
    (attempt : σ → α → Nat → Except Unit (Option σ)) (priorities : α → List Nat)
    (limit : Nat) (state : PsSyntheticQueueResult σ α) :
    PsSyntheticQueueResult σ α := Id.run do
  let ordered := ((state.pending.flatMap priorities).mergeSort (· >= ·)).eraseDups
  let mut attempts := state.attempts
  for priority in ordered do
    for (constraint, position) in state.pending.zipIdx do
      if !(priorities constraint).contains priority then continue
      if attempts >= limit then return { state with attempts, resourceExceeded := true }
      attempts := attempts + 1
      match attempt state.context constraint priority with
      | .error () => return { state with attempts, resourceExceeded := true }
      | .ok none => pure ()
      | .ok (some context) =>
        return { state with
          context := context
          attempts := attempts
          pending := state.pending.take position ++ state.pending.drop (position + 1) }
  return { state with attempts }

-- Every productive round removes a constraint. Defaults run only after
-- ordinary work reaches quiescence; a single default can wake ordinary work.
def psSyntheticQueueRunChecked {σ α : Type} (fuel : Nat)
    (attempt : σ → α → Except Unit (Option σ)) (isDefault : α → Bool)
    (attemptDefault : σ → α → Nat → Except Unit (Option σ)) (priorities : α → List Nat)
    (allowDefaults : Bool) (limit : Nat)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  match fuel with
  | 0 => { state with resourceExceeded := !state.pending.isEmpty }
  | fuel + 1 =>
    if state.pending.isEmpty then state else
    let ordinary := psSyntheticQueuePassChecked attempt isDefault limit state.pending
      { state with pending := [] }
    if ordinary.resourceExceeded then ordinary else
    if ordinary.pending.length < state.pending.length then
      psSyntheticQueueRunChecked fuel attempt isDefault attemptDefault priorities allowDefaults limit ordinary
    else if !allowDefaults then ordinary else
      let defaults := psSyntheticQueueDefault attemptDefault priorities limit ordinary
      if defaults.resourceExceeded then defaults else
      if defaults.pending.length < ordinary.pending.length then
        psSyntheticQueueRunChecked fuel attempt isDefault attemptDefault priorities allowDefaults limit defaults
      else defaults

def psSyntheticQueueRun {σ α : Type} (fuel : Nat)
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (attemptDefault : σ → α → Nat → Except Unit (Option σ)) (priorities : α → List Nat)
    (allowDefaults : Bool) (limit : Nat)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  psSyntheticQueueRunChecked fuel (fun context constraint => .ok (attempt context constraint))
    isDefault attemptDefault priorities allowDefaults limit state

def psSyntheticQueueSolveChecked {σ α : Type}
    (attempt : σ → α → Except Unit (Option σ)) (isDefault : α → Bool)
    (priorities : α → List Nat)
    (attemptDefault : σ → α → Nat → Except Unit (Option σ))
    (context : σ) (pending : List α)
    (allowDefaults : Bool := true) (limit : Nat := 32768) :
    PsSyntheticQueueResult σ α :=
  let result := psSyntheticQueueRunChecked (pending.length + 1) attempt isDefault
    attemptDefault priorities allowDefaults limit { context, pending }
  if result.resourceExceeded then { result with context, pending } else result

def psSyntheticQueueSolve {σ α : Type}
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (priorities : α → List Nat)
    (attemptDefault : σ → α → Nat → Except Unit (Option σ))
    (context : σ) (pending : List α)
    (allowDefaults : Bool := true) (limit : Nat := 32768) :
    PsSyntheticQueueResult σ α :=
  psSyntheticQueueSolveChecked (fun context constraint => .ok (attempt context constraint))
    isDefault priorities attemptDefault context pending allowDefaults limit

def psSyntheticSolve (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (pending : List PsSyntheticConstraint)
    (allowDefaults : Bool := true) (limit : Nat := 32768) : PsSyntheticResult :=
  psSyntheticQueueSolveChecked (psSyntheticAttemptChecked environment index) psSyntheticIsDefault
    (psSyntheticConstraintPriorities index) (psSyntheticAttemptDefault environment index)
    context pending allowDefaults limit
