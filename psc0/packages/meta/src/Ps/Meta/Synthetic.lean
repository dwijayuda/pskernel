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

def psSyntheticAttempt (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) : PsSyntheticConstraint → Option PsMetaContext
  | .expectedType locals actual expected =>
    let unified := psUnify environment locals context actual expected
    if unified.success then some unified.context else none
  | .defaultValue id value => psSyntheticAssign environment context id value
  | .instanceGoal id => do
    let declaration ← psMetaFindDecl context id
    match psMetaFindAssignment context id with
    | some value => psSyntheticAssign environment context id value
    | none =>
      let result := (psSynthInstanceWithLimits environment declaration.localContext index
        context 64 {} (psMetaInstantiate context declaration.type)).result
      let value ← result.value
      psSyntheticAssign environment result.context id value

def psSyntheticIsDefault : PsSyntheticConstraint → Bool
  | .defaultValue _ _ => true
  | _ => false

def psSyntheticQueuePass {σ α : Type}
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (defaults : Bool) (limit : Nat) (pending : List α)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  match pending with
  | [] => { state with pending := state.pending.reverse }
  | constraint :: rest =>
    if isDefault constraint != defaults then
      psSyntheticQueuePass attempt isDefault defaults limit rest
        { state with pending := constraint :: state.pending }
    else if state.attempts >= limit then
      { state with pending := state.pending.reverse ++ pending, resourceExceeded := true }
    else
      let solved := attempt state.context constraint
      psSyntheticQueuePass attempt isDefault defaults limit rest {
        state with context := solved.getD state.context
                   pending := if solved.isSome then state.pending else constraint :: state.pending
                   attempts := state.attempts + 1 }

-- Every productive round removes a constraint. Defaults run only after
-- ordinary work reaches quiescence; defaults may wake ordinary work again.
def psSyntheticQueueRun {σ α : Type} (fuel : Nat)
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (allowDefaults : Bool) (limit : Nat)
    (state : PsSyntheticQueueResult σ α) : PsSyntheticQueueResult σ α :=
  match fuel with
  | 0 => { state with resourceExceeded := !state.pending.isEmpty }
  | fuel + 1 =>
    if state.pending.isEmpty then state else
    let ordinary := psSyntheticQueuePass attempt isDefault false limit state.pending
      { state with pending := [] }
    if ordinary.resourceExceeded then ordinary else
    if ordinary.pending.length < state.pending.length then
      psSyntheticQueueRun fuel attempt isDefault allowDefaults limit ordinary
    else if !allowDefaults then ordinary else
      let defaults := psSyntheticQueuePass attempt isDefault true limit ordinary.pending
        { ordinary with pending := [] }
      if defaults.resourceExceeded then defaults else
      if defaults.pending.length < ordinary.pending.length then
        psSyntheticQueueRun fuel attempt isDefault allowDefaults limit defaults
      else defaults

def psSyntheticQueueSolve {σ α : Type}
    (attempt : σ → α → Option σ) (isDefault : α → Bool)
    (context : σ) (pending : List α)
    (allowDefaults : Bool := true) (limit : Nat := 32768) :
    PsSyntheticQueueResult σ α :=
  let result := psSyntheticQueueRun (pending.length + 1) attempt isDefault
    allowDefaults limit { context, pending }
  if result.resourceExceeded then { result with context, pending } else result

def psSyntheticSolve (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (pending : List PsSyntheticConstraint)
    (allowDefaults : Bool := true) (limit : Nat := 32768) : PsSyntheticResult :=
  psSyntheticQueueSolve (psSyntheticAttempt environment index) psSyntheticIsDefault
    context pending allowDefaults limit
