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

-- M2 answer table. It is scoped to a single environment/local instance set
-- and one synthesis invocation. Never share an entry across source modules,
-- local contexts or registries. Cache only closed, independently validated
-- successful goals; failures are NOT memoized because postponed output
-- metavariables and later dependencies can make them solvable.
structure PsInstanceTableAnswer where
  goal : PsExpr
  value : PsExpr

structure PsInstanceSearchTable where
  answers : List PsInstanceTableAnswer := []
  visits : Nat := 0

structure PsInstanceTabledResult where
  result : PsSynthInstanceResult
  table : PsInstanceSearchTable

structure PsInstanceTableSolvePass where
  context : PsMetaContext
  table : PsInstanceSearchTable
  pending : List Nat

structure PsInstanceTableSolveResult where
  context : PsMetaContext
  table : PsInstanceSearchTable
  success : Bool

def psInstanceTableFailure (context : PsMetaContext)
    (table : PsInstanceSearchTable) : PsInstanceTabledResult :=
  { result := psSynthFailure context, table }

def psInstanceTableSuccess (context : PsMetaContext) (value : PsExpr)
    (table : PsInstanceSearchTable) : PsInstanceTabledResult :=
  { result := psSynthSuccess context value, table }

-- A cached witness is NEVER trusted by the cache itself. Re-infer its type
-- and reconcile it with the caller's exact target (including outParams).
-- Comparing normalized FULL targets avoids mixing GetElem output families.
def psInstanceTableLookup (environment : PsEnvironment)
    (localContext : PsLocalContext) (context : PsMetaContext)
    (target : PsExpr) (table : PsInstanceSearchTable) :
    Option PsSynthInstanceResult := do
  let target := psMetaInstantiate context target
  if psExprHasUnresolvedMeta target then none else
  let answer ← table.answers.find? (fun answer =>
    psExprAlphaEq answer.goal target)
  if psExprHasUnresolvedMeta answer.value then none else
  match psInferType environment context localContext answer.value with
  | .error _ => none
  | .ok inferred =>
    let checked := psUnify environment localContext context inferred target
    if checked.success then
      some (psSynthSuccess checked.context
        (psMetaInstantiate checked.context answer.value))
    else none

def psInstanceTableInsert (table : PsInstanceSearchTable)
    (goal value : PsExpr) : PsInstanceSearchTable :=
  if psExprHasUnresolvedMeta goal || psExprHasUnresolvedMeta value ||
      table.answers.any (fun answer => psExprAlphaEq answer.goal goal) then table
  else { table with answers := { goal, value } :: table.answers }

-- A dependency pass consumes all currently solvable dictionary arguments.
-- Unresolved inputs are postponed until another dictionary constrains them.
-- Successful subgoal answers are shared across sibling candidates; failed
-- speculative META assignments are always rolled back to the caller context.
def psInstanceTableSolvePass
    (synthesize : PsInstanceSearchTable → PsMetaContext → PsExpr → PsInstanceTabledResult)
    (pending : List Nat) (context : PsMetaContext)
    (table : PsInstanceSearchTable) : PsInstanceTableSolvePass :=
  match pending with
  | [] => { context, table, pending := [] }
  | id :: rest =>
    let attempt : PsInstanceTabledResult :=
      match psMetaFindAssignment context id, psMetaFindDecl context id with
      | some _, _ => psInstanceTableSuccess context (.fvar id) table
      | none, some declaration =>
        synthesize table context (psMetaInstantiate context declaration.type)
      | _, _ => psInstanceTableFailure context table
    let assigned : Option PsMetaContext :=
      match psMetaFindAssignment context id with
      | some _ => some context
      | none => attempt.result.value.bind fun value =>
        psMetaAssign attempt.result.context id value
    let tail := psInstanceTableSolvePass synthesize rest
      (assigned.getD context) attempt.table
    { context := tail.context
      table := tail.table
      pending := if assigned.isSome then tail.pending else id :: tail.pending }

def psInstanceTableSolvePendingWithFuel
    (synthesize : PsInstanceSearchTable → PsMetaContext → PsExpr → PsInstanceTabledResult)
    (fuel : Nat) (pending : List Nat) (context : PsMetaContext)
    (table : PsInstanceSearchTable) : PsInstanceTableSolveResult :=
  match fuel with
  | 0 => { context, table, success := pending.isEmpty }
  | fuel + 1 =>
    let pass := psInstanceTableSolvePass synthesize pending context table
    if pass.pending.isEmpty then
      { context := pass.context, table := pass.table, success := true }
    else if pass.pending.length >= pending.length then
      { context, table := pass.table, success := false }
    else
      psInstanceTableSolvePendingWithFuel synthesize fuel
        pass.pending pass.context pass.table

def psInstanceTableSolvePrepared
    (synthesize : PsInstanceSearchTable → PsMetaContext → PsExpr → PsInstanceTabledResult)
    (args : List PsPreparedInstanceArgument)
    (context : PsMetaContext) (table : PsInstanceSearchTable) :
    PsInstanceTableSolveResult :=
  let pending := args.filterMap fun arg =>
    if arg.isInstance then
      match arg.expr with | .mvar id => some id | _ => none
    else none
  let solved := psInstanceTableSolvePendingWithFuel synthesize
    (pending.length + 1) pending context table
  if solved.success && args.all (fun arg =>
    !psExprHasUnresolvedMeta (psMetaInstantiate solved.context arg.expr)) then solved
  else { context, table := solved.table, success := false }

def psInstanceTableTryCandidate
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (original : PsMetaContext)
    (target : PsExpr)
    (table : PsInstanceSearchTable)
    (synthesize : PsInstanceSearchTable → PsMetaContext → PsExpr → PsInstanceTabledResult)
    (entry : PsInstanceEntry) : PsInstanceTabledResult :=
  let prepared := psPrepareInstance environment localContext original entry
  if !prepared.success then psInstanceTableFailure original table else
  let matchTarget := psUnify environment localContext
    prepared.context prepared.resultType target
  if !matchTarget.success then psInstanceTableFailure original table else
  let solved := psInstanceTableSolvePrepared synthesize
    prepared.arguments matchTarget.context table
  if !solved.success then psInstanceTableFailure original solved.table else
  let value := psMetaInstantiate solved.context prepared.value
  if psExprHasUnresolvedMeta value then
    psInstanceTableFailure original solved.table
  else
    psInstanceTableSuccess solved.context value solved.table

def psInstanceTableTryCandidates
    (environment : PsEnvironment) (localContext : PsLocalContext)
    (original : PsMetaContext) (target : PsExpr)
    (table : PsInstanceSearchTable)
    (synthesize : PsInstanceSearchTable → PsMetaContext → PsExpr → PsInstanceTabledResult)
    (entries : List PsInstanceEntry) : PsInstanceTabledResult :=
  match entries with
  | [] => psInstanceTableFailure original table
  | entry :: rest =>
    let attempt := psInstanceTableTryCandidate environment localContext
      original target table synthesize entry
    match attempt.result.value with
    | some _ => attempt
    | none => psInstanceTableTryCandidates environment localContext
        original target attempt.table synthesize rest

-- Global node cap bounds total search work even in a wide diamond DAG;
-- depth fuel bounds individual recursive evidence paths. Both fail closed.
def psSynthInstanceSearch (fuel : Nat) (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (active : List PsExpr) (table : PsInstanceSearchTable)
    (context : PsMetaContext) (target : PsExpr) :
    PsInstanceTabledResult :=
  match fuel with
  | 0 => psInstanceTableFailure context table
  | fuel + 1 =>
    match psInstanceTableLookup environment localContext context target table with
    | some cached => { result := cached, table }
    | none =>
      if table.visits >= 4096 then psInstanceTableFailure context table else
      let table := { table with visits := table.visits + 1 }
      match psPrepareInstanceTarget environment localContext context target with
      | none => psInstanceTableFailure context table
      | some prepared =>
        let cyclic := active.any fun prior =>
          psDefEqReadOnlyWithEnv environment prepared.context
            localContext prepared.key prior
        if cyclic then psInstanceTableFailure context table else
        let head := (psInferAppView prepared.type).head
        let entries := (psAllInstanceEntries localContext index).filter fun entry =>
          match entry.className, head with
          | some className, .constE name _ => psNameEq className name
          | none, _ => true
          | _, _ => false
        let synthesize := fun table nextContext nextTarget =>
          psSynthInstanceSearch fuel environment localContext index
            (prepared.key :: active) table nextContext nextTarget
        let attempted := psInstanceTableTryCandidates environment localContext
          prepared.context prepared.type table synthesize entries
        match attempted.result.value with
        | none => psInstanceTableFailure context attempted.table
        | some value =>
          match psInferType environment attempted.result.context localContext value with
          | .error _ => psInstanceTableFailure context attempted.table
          | .ok actualType =>
            let checked := psUnify environment localContext
              attempted.result.context actualType target
            if !checked.success then psInstanceTableFailure context attempted.table
            else
              let finalValue := psMetaInstantiate checked.context value
              let finalGoal := psMetaInstantiate checked.context target
              let updated := psInstanceTableInsert attempted.table finalGoal finalValue
              psInstanceTableSuccess checked.context finalValue updated

-- No persistent memo: the caller's context, local dictionaries and registry
-- are immutable *only for this invocation*. A new call owns a fresh table.
def psSynthInstanceWithTable (environment : PsEnvironment)
    (localContext : PsLocalContext) (index : PsInstanceIndex)
    (context : PsMetaContext) (fuel : Nat) (target : PsExpr) :
    PsInstanceTabledResult :=
  psSynthInstanceSearch fuel environment localContext index [] {} context target

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
