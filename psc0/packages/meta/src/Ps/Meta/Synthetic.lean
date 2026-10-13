import Ps.Meta.InstanceSearch

-- Constraints carry their own scope. Only checked, successful attempts commit;
-- a blocked attempt cannot leak speculative assignments into another item.
inductive PsSyntheticConstraint where
  | instanceGoal (id : Nat)
  | expectedType (locals : PsLocalContext) (actual expected : PsExpr)
  | defaultValue (id : Nat) (value : PsExpr)

structure PsSyntheticResult where
  context : PsMetaContext
  pending : List PsSyntheticConstraint
  attempts : Nat := 0
  resourceExceeded : Bool := false

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

def psSyntheticPass (environment : PsEnvironment) (index : PsInstanceIndex)
    (defaults : Bool) (limit : Nat) (pending : List PsSyntheticConstraint)
    (state : PsSyntheticResult) : PsSyntheticResult :=
  match pending with
  | [] => { state with pending := state.pending.reverse }
  | constraint :: rest =>
    if psSyntheticIsDefault constraint != defaults then
      psSyntheticPass environment index defaults limit rest
        { state with pending := constraint :: state.pending }
    else if state.attempts >= limit then
      { state with pending := state.pending.reverse ++ pending, resourceExceeded := true }
    else
      let solved := psSyntheticAttempt environment index state.context constraint
      psSyntheticPass environment index defaults limit rest {
        state with context := solved.getD state.context
                   pending := if solved.isSome then state.pending else constraint :: state.pending
                   attempts := state.attempts + 1 }

-- Every productive round removes a constraint, so no-progress detection is
-- structural. Defaults run only after ordinary constraints reach quiescence;
-- their assignments may unlock an earlier expected type or instance.
def psSyntheticRun (fuel : Nat) (environment : PsEnvironment) (index : PsInstanceIndex)
    (allowDefaults : Bool) (limit : Nat) (state : PsSyntheticResult) : PsSyntheticResult :=
  match fuel with
  | 0 => { state with resourceExceeded := !state.pending.isEmpty }
  | fuel + 1 =>
    if state.pending.isEmpty then state else
    let ordinary := psSyntheticPass environment index false limit state.pending
      { state with pending := [] }
    if ordinary.resourceExceeded then ordinary else
    if ordinary.pending.length < state.pending.length then
      psSyntheticRun fuel environment index allowDefaults limit ordinary
    else if !allowDefaults then ordinary else
      let defaults := psSyntheticPass environment index true limit ordinary.pending
        { ordinary with pending := [] }
      if defaults.resourceExceeded then defaults else
      if defaults.pending.length < ordinary.pending.length then
        psSyntheticRun fuel environment index allowDefaults limit defaults
      else defaults

def psSyntheticSolve (environment : PsEnvironment) (index : PsInstanceIndex)
    (context : PsMetaContext) (pending : List PsSyntheticConstraint)
    (allowDefaults : Bool := true) (limit : Nat := 32768) : PsSyntheticResult :=
  let result := psSyntheticRun (pending.length + 1) environment index allowDefaults limit
    { context, pending }
  -- Resource refusal is transactional, including earlier successful attempts.
  if result.resourceExceeded then
    { result with context, pending }
  else result
