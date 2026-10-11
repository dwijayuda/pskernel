import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Meta.Unify
import Ps.Meta.InstanceTarget

structure PsPreparedInstanceArgument where
  expr : PsExpr
  type : PsExpr
  isInstance : Bool

structure PsPreparedInstance where
  context : PsMetaContext
  value : PsExpr
  resultType : PsExpr
  arguments : List PsPreparedInstanceArgument
  success : Bool

structure PsSynthInstanceResult where
  context : PsMetaContext
  value : Option PsExpr

structure PsSolveInstanceArgsResult where
  context : PsMetaContext
  success : Bool

def psSynthFailure (context : PsMetaContext) : PsSynthInstanceResult :=
  { context := context, value := Option.none }

def psSynthSuccess
    (context : PsMetaContext)
    (value : PsExpr) : PsSynthInstanceResult :=
  { context := context, value := Option.some value }

def psBinderInfoIsInstance (binder : PsBinderInfo) : Bool :=
  match binder with
  | .instanceImplicit => true
  | _ => false

def psPreparedInstanceArgumentListReverseAux
    (remaining : List PsPreparedInstanceArgument) :
    List PsPreparedInstanceArgument -> List PsPreparedInstanceArgument :=
  match remaining with
  | List.nil =>
      fun (acc : List PsPreparedInstanceArgument) => acc
  | List.cons head tail =>
      let smaller :
          List PsPreparedInstanceArgument -> List PsPreparedInstanceArgument :=
        psPreparedInstanceArgumentListReverseAux tail;
      fun (acc : List PsPreparedInstanceArgument) =>
        smaller (List.cons head acc)

def psPreparedInstanceArgumentListReverse
    (values : List PsPreparedInstanceArgument) :
    List PsPreparedInstanceArgument :=
  psPreparedInstanceArgumentListReverseAux values List.nil

def psPrepareInstanceWithFuelWorker
    (remainingFuel : Nat) :
    PsEnvironment ->
    PsLocalContext ->
    PsMetaContext ->
    PsExpr ->
    PsExpr ->
    List PsPreparedInstanceArgument ->
    PsPreparedInstance :=
  match remainingFuel with
  | Nat.zero =>
      fun (_environment : PsEnvironment) =>
        fun (_localContext : PsLocalContext) =>
          fun (context : PsMetaContext) =>
            fun (value : PsExpr) =>
              fun (type : PsExpr) =>
                fun (arguments : List PsPreparedInstanceArgument) => {
                  context := context
                  value := value
                  resultType := type
                  arguments := psPreparedInstanceArgumentListReverse arguments
                  success := false
                }
  | Nat.succ fuel =>
      fun (environment : PsEnvironment) =>
        fun (localContext : PsLocalContext) =>
          fun (context : PsMetaContext) =>
            fun (value : PsExpr) =>
              fun (type : PsExpr) =>
                fun (arguments : List PsPreparedInstanceArgument) =>
                  let smaller :
                      PsEnvironment ->
                      PsLocalContext ->
                      PsMetaContext ->
                      PsExpr ->
                      PsExpr ->
                      List PsPreparedInstanceArgument ->
                      PsPreparedInstance :=
                    psPrepareInstanceWithFuelWorker fuel;
                  let typeValue :=
                    psWhnf environment context localContext type;
                  match typeValue with
                  | .forallE _ domain body binder =>
                      let kind :=
                        if psBinderInfoIsInstance binder then
                          PsMetaVarKind.synthetic
                        else
                          PsMetaVarKind.natural;
                      let fresh := psMetaFresh context localContext domain kind;
                      let nextValue := PsExpr.app value fresh.expr;
                      let nextType := psExprInstantiate1 body fresh.expr;
                      let argument : PsPreparedInstanceArgument := {
                        expr := fresh.expr
                        type := domain
                        isInstance := psBinderInfoIsInstance binder
                      };
                      smaller
                        environment
                        localContext
                        fresh.context
                        nextValue
                        nextType
                        (List.cons argument arguments)
                  | _ => {
                      context := context
                      value := value
                      resultType := typeValue
                      arguments := psPreparedInstanceArgumentListReverse arguments
                      success := true
                    }

def psPrepareInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (value : PsExpr)
    (type : PsExpr)
    (arguments : List PsPreparedInstanceArgument)
    (fuel : Nat) : PsPreparedInstance :=
  psPrepareInstanceWithFuelWorker
    fuel
    environment
    localContext
    context
    value
    type
    arguments

def psPrepareInstance
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (entry : PsInstanceEntry) : PsPreparedInstance :=
  let (context, levelsRev) := entry.levelParams.foldl
    (fun (state : PsMetaContext × List PsLevel) _ =>
      let fresh := psMetaFreshLevel state.fst
      (fresh.context, fresh.level :: state.snd)) (context, [])
  let levels := levelsRev.reverse
  psPrepareInstanceWithFuel
    environment
    localContext
    context
    (psExprInstantiateLevelParams entry.levelParams levels entry.value)
    (psExprInstantiateLevelParams entry.levelParams levels entry.type)
    []
    128

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

def psSolvePreparedInstanceArguments
    (synthesize : PsMetaContext → PsExpr → PsSynthInstanceResult)
    (arguments : List PsPreparedInstanceArgument)
    (current : PsMetaContext) : PsSolveInstanceArgsResult :=
  let pending := arguments.filterMap fun argument =>
    if argument.isInstance then
      match argument.expr with | .mvar id => some id | _ => none
    else none
  let solved := psSolveInstanceMetavars synthesize pending current
  if solved.success && arguments.all (fun argument =>
      !psExprHasUnresolvedMeta (psMetaInstantiate solved.context argument.expr)) then solved
  else { context := current, success := false }

def psTryInstanceCandidate
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (original : PsMetaContext)
    (target : PsExpr)
    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult)
    (entry : PsInstanceEntry) : PsSynthInstanceResult :=
  let prepared :=
    psPrepareInstance environment localContext original entry;
  if prepared.success then
    let targetResult :=
      psUnify
        environment
        localContext
        prepared.context
        prepared.resultType
        target;
    if targetResult.success then
      let solved :=
        psSolvePreparedInstanceArguments
          synthesize
          prepared.arguments
          targetResult.context;
      if solved.success then
        let finalValue :=
          psMetaInstantiate solved.context prepared.value;
        if psExprHasUnresolvedMeta finalValue then
          psSynthFailure original
        else
          psSynthSuccess solved.context finalValue
      else
        psSynthFailure original
    else
      psSynthFailure original
  else
    psSynthFailure original

def psTryInstanceCandidatesWorker
    (entries : List PsInstanceEntry) :
    PsEnvironment ->
    PsLocalContext ->
    PsMetaContext ->
    PsExpr ->
    (PsMetaContext -> PsExpr -> PsSynthInstanceResult) ->
    PsSynthInstanceResult :=
  match entries with
  | [] =>
      fun (_environment : PsEnvironment) =>
        fun (_localContext : PsLocalContext) =>
          fun (original : PsMetaContext) =>
            fun (_target : PsExpr) =>
              fun (_synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult) =>
                psSynthFailure original
  | entry :: rest =>
      let smaller :
          PsEnvironment ->
          PsLocalContext ->
          PsMetaContext ->
          PsExpr ->
          (PsMetaContext -> PsExpr -> PsSynthInstanceResult) ->
          PsSynthInstanceResult :=
        psTryInstanceCandidatesWorker rest;
      fun (environment : PsEnvironment) =>
        fun (localContext : PsLocalContext) =>
          fun (original : PsMetaContext) =>
            fun (target : PsExpr) =>
              fun (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult) =>
                let attempt :=
                  psTryInstanceCandidate
                    environment
                    localContext
                    original
                    target
                    synthesize
                    entry;
                match attempt.value with
                | Option.some _ => attempt
                | Option.none =>
                    smaller
                      environment
                      localContext
                      original
                      target
                      synthesize

def psTryInstanceCandidates
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (original : PsMetaContext)
    (target : PsExpr)
    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult)
    (entries : List PsInstanceEntry) : PsSynthInstanceResult :=
  psTryInstanceCandidatesWorker
    entries
    environment
    localContext
    original
    target
    synthesize

-- Each candidate owns its metavariable snapshot. Inputs must be known; output
-- positions and output-only universe levels are masked before search. Active
-- keys ignore outputs, making cycles independent of fresh output identities.
def psSynthInstanceSearch (fuel : Nat) (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (active : List PsExpr) (context : PsMetaContext) (target : PsExpr) :
    PsSynthInstanceResult :=
  match fuel with
  | 0 => psSynthFailure context
  | fuel + 1 =>
    match psPrepareInstanceTarget environment localContext context target with
    | none => psSynthFailure context
    | some prepared =>
      let cyclic := active.any fun prior =>
        psDefEqReadOnlyWithEnv environment prepared.context localContext prepared.key prior
      if cyclic then psSynthFailure context else
      let head := (psInferAppView prepared.type).head
      let entries := (psAllInstanceEntries localContext index).filter fun entry =>
        match entry.className, head with
        | some className, .constE name _ => psNameEq className name
        | none, _ => true
        | _, _ => false
      let synthesize := fun nextContext nextTarget =>
        psSynthInstanceSearch fuel environment localContext index
          (prepared.key :: active) nextContext nextTarget
      let solved := psTryInstanceCandidates environment localContext prepared.context
        prepared.type synthesize entries
      match solved.value with
      | none => psSynthFailure context
      | some value =>
        match psInferType environment solved.context localContext value with
        | .error _ => psSynthFailure context
        | .ok type =>
          let checked := psUnify environment localContext solved.context type target
          if checked.success then
            psSynthSuccess checked.context (psMetaInstantiate checked.context value)
          else psSynthFailure context

def psSynthInstanceWithFuelWorker (fuel : Nat) (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (context : PsMetaContext) (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceSearch fuel environment localContext index [] context target

def psSynthInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext)
    (fuel : Nat)
    (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceWithFuelWorker
    fuel
    environment
    localContext
    index
    context
    target

def psSynthInstance
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext)
    (target : PsExpr) : PsSynthInstanceResult :=
  psSynthInstanceWithFuel
    environment
    localContext
    index
    context
    64
    target
