import Ps.Meta.InstanceSearch

structure PsInstanceSolvePass where
  context : PsMetaContext
  pending : List Nat

-- Pending dictionaries are a dependency worklist. A successful output can
-- unlock an earlier input; a failed attempt keeps its original snapshot.
def psSolveInstancePass (synthesize : PsMetaContext → PsExpr → PsSynthInstanceResult)
    (pending : List Nat) (context : PsMetaContext) : PsInstanceSolvePass :=
  match pending with
  | [] => { context, pending := [] }
  | id :: rest =>
    let solved := match psMetaFindAssignment context id, psMetaFindDecl context id with
      | some _, _ => some context
      | none, some declaration =>
        let result := synthesize context (psMetaInstantiate context declaration.type)
        result.value.bind fun value => psMetaAssign result.context id value
      | _, _ => none
    let tail := psSolveInstancePass synthesize rest (solved.getD context)
    { context := tail.context
      pending := if solved.isSome then tail.pending else id :: tail.pending }

def psSolveInstanceMetavarsWithFuel
    (synthesize : PsMetaContext → PsExpr → PsSynthInstanceResult)
    (fuel : Nat) (pending : List Nat) (context : PsMetaContext) : PsSolveInstanceArgsResult :=
  match fuel with
  | 0 => { context, success := pending.isEmpty }
  | fuel + 1 =>
    let pass := psSolveInstancePass synthesize pending context
    if pass.pending.isEmpty then { context := pass.context, success := true }
    else if pass.pending.length >= pending.length then { context, success := false }
    else psSolveInstanceMetavarsWithFuel synthesize fuel pass.pending pass.context

def psSolveInstanceMetavars
    (synthesize : PsMetaContext → PsExpr → PsSynthInstanceResult)
    (pending : List Nat) (context : PsMetaContext) : PsSolveInstanceArgsResult :=
  psSolveInstanceMetavarsWithFuel synthesize (pending.length + 1) pending context

-- Each invocation owns its graph; callers receive diagnostics, never a cache
-- that could accidentally outlive the local context or instance registry.
def psSynthInstanceWithTable (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (context : PsMetaContext) (fuel : Nat) (target : PsExpr) :
    PsInstanceTabledResult :=
  psSynthInstanceWithLimits environment localContext index context fuel {} target

def psSynthInstanceWithFuelWorker (fuel : Nat) (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (context : PsMetaContext) (target : PsExpr) : PsSynthInstanceResult :=
  (psSynthInstanceWithTable environment localContext index context fuel target).result

def psSynthInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext)
    (fuel : Nat)
    (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceWithFuelWorker fuel environment localContext index context target

def psSynthInstance
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext)
    (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceWithFuel environment localContext index context 64 target
