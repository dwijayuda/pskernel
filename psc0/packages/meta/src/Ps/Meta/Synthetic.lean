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

def psSyntheticAssign (environment : PsEnvironment) (context : PsMetaContext)
    (id : Nat) (value : PsExpr) : Option PsMetaContext := do
  let declaration ← psMetaFindDecl context id
  let checked ← psInstanceCheck environment declaration.localContext context declaration.type value
  let value ← checked.value
  match psMetaFindAssignment checked.context id with
  | none => psMetaAssign checked.context id value
  | some prior =>
    let unified := psUnify environment declaration.localContext checked.context prior value
    if unified.success then some unified.context else none

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
      match psSyntheticAssign environment context id value with
      | some checked => { result := psSynthSuccess checked value, table := {} }
      | none => { result := psSynthFailure context, table := {} }
    | none =>
      let searched := psSynthInstanceWithLimits environment declaration.localContext index
        context 64 limits (psMetaInstantiate context declaration.type)
      match searched.result.value with
      | none => searched
      | some value =>
        match psSyntheticAssign environment searched.result.context id value with
        | some checked => { searched with result := psSynthSuccess checked value }
        | none => { searched with result := psSynthFailure context }

def psSyntheticAttempt (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) : PsSyntheticConstraint → Option PsMetaContext
  | .expectedType locals actual expected =>
    let unified := psUnify environment locals context actual expected
    if unified.success then some unified.context else none
  | .defaultValue id value => psSyntheticAssign environment context id value
  | .instanceGoal id =>
    let checked := psSyntheticInstanceAttempt environment index context id
    checked.result.value.map (fun _ => checked.result.context)


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
      if !checked.success then continue
      let pending := candidate.arguments.filterMap fun arg =>
        if arg.isInstance then
          match arg.expr with | .mvar id => some id | _ => none
        else none
      let solved := psSyntheticDefaultGoals fuel environment index checked.context pending remaining
      remaining := solved.remaining
      if solved.exhausted then return { context, remaining, exhausted := true }
      if !solved.success then continue
      if let some next := psSyntheticAssign environment solved.context id candidate.value then
        return { context := next, remaining, success := true }
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
    for priority in psSyntheticDefaultPriorities index do
      for id in unresolved do
        let tried := psSyntheticDefaultSearch fuel environment index current id priority remaining
        remaining := tried.remaining
        if tried.exhausted then return { context, remaining, exhausted := true }
        if tried.success then
          return psSyntheticDefaultGoals fuel environment index tried.context unresolved remaining
    return { context, remaining }
end

def psSyntheticAttemptDefault (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (constraint : PsSyntheticConstraint) (priority : Nat) :
    Except Unit (Option PsMetaContext) :=
  match constraint with
  | .defaultValue id value =>
    .ok (if priority == 0 then psSyntheticAssign environment context id value else none)
  | .instanceGoal id =>
    if (psMetaFindAssignment context id).isSome then
      .ok (psSyntheticAttempt environment index context constraint)
    else
      let result := psSyntheticDefaultSearch 64 environment index context id priority
        psInstanceMaxCandidateChecks
      if result.exhausted then .error ()
      else .ok (if result.success then some result.context else none)
  | _ => .ok none

def psSyntheticConstraintPriorities (index : PsInstanceIndex) :
    PsSyntheticConstraint → List Nat
  | .defaultValue _ _ => [0]
  | .instanceGoal _ => psSyntheticDefaultPriorities index
  | _ => []

def psSyntheticHasDefault (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) : PsSyntheticConstraint → Bool
  | .instanceGoal id =>
    match psSyntheticInstanceClass environment context id with
    | none => false
    | some name => index.defaults.any (fun entry => entry.className.any (psNameEq name))
  | .defaultValue _ _ => true
  | _ => false

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

def psSyntheticQueuePass {σ α : Type}
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (limit : Nat) (pending : List α)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  match pending with
  | [] => { state with pending := state.pending.reverse }
  | constraint :: rest =>
    if isDefault constraint then
      psSyntheticQueuePass attempt isDefault limit rest
        { state with pending := constraint :: state.pending }
    else if state.attempts >= limit then
      { state with pending := state.pending.reverse ++ pending, resourceExceeded := true }
    else
      let solved := attempt state.context constraint
      psSyntheticQueuePass attempt isDefault limit rest {
        state with context := solved.getD state.context
                   pending := if solved.isSome then state.pending else constraint :: state.pending
                   attempts := state.attempts + 1 }

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
def psSyntheticQueueRun {σ α : Type} (fuel : Nat)
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (attemptDefault : σ → α → Nat → Except Unit (Option σ)) (priorities : α → List Nat)
    (allowDefaults : Bool) (limit : Nat)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  match fuel with
  | 0 => { state with resourceExceeded := !state.pending.isEmpty }
  | fuel + 1 =>
    if state.pending.isEmpty then state else
    let ordinary := psSyntheticQueuePass attempt isDefault limit state.pending
      { state with pending := [] }
    if ordinary.resourceExceeded then ordinary else
    if ordinary.pending.length < state.pending.length then
      psSyntheticQueueRun fuel attempt isDefault attemptDefault priorities allowDefaults limit ordinary
    else if !allowDefaults then ordinary else
      let defaults := psSyntheticQueueDefault attemptDefault priorities limit ordinary
      if defaults.resourceExceeded then defaults else
      if defaults.pending.length < ordinary.pending.length then
        psSyntheticQueueRun fuel attempt isDefault attemptDefault priorities allowDefaults limit defaults
      else defaults

def psSyntheticQueueSolve {σ α : Type}
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (priorities : α → List Nat)
    (attemptDefault : σ → α → Nat → Except Unit (Option σ))
    (context : σ) (pending : List α)
    (allowDefaults : Bool := true) (limit : Nat := 32768) :
    PsSyntheticQueueResult σ α :=
  let result := psSyntheticQueueRun (pending.length + 1) attempt isDefault
    attemptDefault priorities allowDefaults limit { context, pending }
  if result.resourceExceeded then { result with context, pending } else result

def psSyntheticSolve (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (pending : List PsSyntheticConstraint)
    (allowDefaults : Bool := true) (limit : Nat := 32768) : PsSyntheticResult :=
  psSyntheticQueueSolve (psSyntheticAttempt environment index) psSyntheticIsDefault
    (psSyntheticConstraintPriorities index) (psSyntheticAttemptDefault environment index)
    context pending allowDefaults limit
