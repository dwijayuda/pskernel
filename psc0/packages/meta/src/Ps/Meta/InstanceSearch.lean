import Ps.Meta.InstanceCandidate

-- The table belongs to one environment, registry and synthesis invocation.
-- A Pi introduction gets a distinct scope, even when local IDs coincide.
-- Evidence crosses unrelated snapshots through scoped, freshened templates.
-- The creator owns its speculative context; shared subscribers never adopt it.
structure PsInstanceTableAnswer where
  goal : PsExpr
  template : PsMetaTemplate
  value : PsExpr
  height : Nat
  -- Adopted only by the root or the unique subscription that created this
  -- generator. Shared consumers replay value in their own saved context.
  context : PsMetaContext

def psInstanceMaxGoalVisits : Nat := 4096
def psInstanceMaxCandidateChecks : Nat := 4096
def psInstanceMaxTransitions : Nat := 32768

structure PsInstanceSearchLimits where
  goals : Nat := psInstanceMaxGoalVisits
  candidates : Nat := psInstanceMaxCandidateChecks
  transitions : Nat := psInstanceMaxTransitions
  answers : Nat := 4096

-- Diagnostics, not an externally reusable cache. Reuse lives inside the graph.
structure PsInstanceSearchTable where
  visits : Nat := 0
  candidateChecks : Nat := 0
  transitions : Nat := 0
  answers : Nat := 0
  generalizedAnswers : Nat := 0
  freshenedAnswers : Nat := 0
  reusedGoals : Nat := 0
  suspended : Nat := 0
  resumed : Nat := 0
  resourceExceeded : Bool := false

structure PsInstanceTabledResult where
  result : PsSynthInstanceResult
  table : PsInstanceSearchTable

structure PsInstanceConsumer where
  owner : Nat
  context : PsMetaContext
  value : PsExpr
  arguments : List PsPreparedInstanceArgument
  pending : List Nat
  height : Nat := 1

structure PsInstanceAbstraction where
  owner : Nat
  locals : PsLocalContext
  localId : Nat
  name : PsName
  domain : PsExpr
  binder : PsBinderInfo
  target : PsExpr

inductive PsInstanceWaiter where
  | argument (consumer : PsInstanceConsumer) (id : Nat) (target : PsExpr)
  | abstraction (abstraction : PsInstanceAbstraction)

structure PsInstanceSubscription where
  waiter : PsInstanceWaiter
  ownsContext : Bool

structure PsInstanceGenerator where
  scope : Nat
  locals : PsLocalContext
  context : PsMetaContext
  target : PsExpr
  key : Option PsExpr
  entries : List PsInstanceEntry
  opened : Bool := false
  answer : Option PsInstanceTableAnswer := none
  generalized : List PsInstanceTableAnswer := []
  waiters : List PsInstanceSubscription := []

inductive PsInstanceWork where
  | generate (id : Nat)
  | consume (consumer : PsInstanceConsumer)
  | resume (subscription : PsInstanceSubscription) (answer : PsInstanceTableAnswer)

structure PsInstanceSearchState where
  generators : Array PsInstanceGenerator := #[]
  work : List PsInstanceWork := []
  nextScope : Nat := 1
  limits : PsInstanceSearchLimits
  maxHeight : Nat
  table : PsInstanceSearchTable := {}

def psInstanceWaiterOwner : PsInstanceWaiter → Nat
  | .argument consumer _ _ => consumer.owner
  | .abstraction abstraction => abstraction.owner

def psInstanceOwnerAnswered (state : PsInstanceSearchState) (id : Nat) : Bool :=
  match state.generators[id]? with
  | some generator => generator.answer.isSome
  | none => true

-- Free-variable types can depend on caller metas. A shared scope number alone
-- does not make two speculative assignments to those types interchangeable.
-- Share only when the entire local signature is closed and identical.
def psInstanceSameLocalSignature (locals : PsLocalContext)
    (left right : PsMetaContext) : Bool :=
  locals.declarations.all fun declaration =>
    let same := fun value =>
      let l := psMetaInstantiate left value
      let r := psMetaInstantiate right value
      !psExprHasUnresolvedMeta l && !psExprHasUnresolvedMeta r && psExprAlphaEq l r
    same (psLocalDeclType declaration) &&
      match declaration with
      | .letDecl _ _ _ value => same value
      | _ => true

def psInstancePrepareGenerator (environment : PsEnvironment)
    (index : PsInstanceIndex) (scope : Nat) (locals : PsLocalContext)
    (context : PsMetaContext) (target : PsExpr) : Option PsInstanceGenerator :=
  match psPrepareInstanceTarget environment locals context target with
  | some prepared =>
    let head := (psInferAppView prepared.type).head
    let entries := (psAllInstanceEntries locals index).filter fun entry =>
      match entry.className, head with
      | some className, .constE name _ => psNameEq className name
      | none, _ => true
      | _, _ => false
    some {
      scope, locals, context := prepared.context,
      target := prepared.type, key := some prepared.key, entries }
  | none =>
    match psWhnf environment context locals (psMetaInstantiate context target) with
    | .forallE _ _ _ _ =>
      some { scope, locals, context, target, key := none, entries := [] }
    | _ => none

-- A canonical class key masks outputs during selection, as in InstanceTarget.
-- Comparing keys never supplies proof evidence. Every replay below is checked
-- against the receiver's complete, original dependent target.
def psInstanceFindGenerator (environment : PsEnvironment)
    (state : PsInstanceSearchState) (goal : PsInstanceGenerator) : Option Nat :=
  goal.key.bind fun key =>
    state.generators.findIdx? fun prior =>
      prior.scope == goal.scope &&
      psInstanceSameLocalSignature goal.locals prior.context goal.context &&
      match prior.key with
      | none => false
      | some priorKey =>
        psExprAlphaEq priorKey key ||
          psDefEqReadOnlyWithEnv environment goal.context goal.locals priorKey key

def psInstanceAcquire (environment : PsEnvironment) (index : PsInstanceIndex)
    (state : PsInstanceSearchState) (scope : Nat) (locals : PsLocalContext)
    (context : PsMetaContext) (target : PsExpr) :
    PsInstanceSearchState × Option Nat :=
  match psInstancePrepareGenerator environment index scope locals context target with
  | none => (state, none)
  | some goal =>
    match psInstanceFindGenerator environment state goal with
    | some id =>
      ({ state with table := { state.table with
          reusedGoals := state.table.reusedGoals + 1 } }, some id)
    | none =>
      if state.table.visits >= state.limits.goals then
        ({ state with table := { state.table with resourceExceeded := true } }, none)
      else
        let id := state.generators.size
        ({ state with
           generators := state.generators.push goal
           work := .generate id :: state.work
           table := { state.table with visits := state.table.visits + 1 } }, some id)

def psInstanceAwait (environment : PsEnvironment) (index : PsInstanceIndex)
    (state : PsInstanceSearchState) (scope : Nat) (locals : PsLocalContext)
    (context : PsMetaContext) (target : PsExpr) (waiter : PsInstanceWaiter) :
    PsInstanceSearchState :=
  let priorSize := state.generators.size
  let (state, id) := psInstanceAcquire environment index state scope locals context target
  match id.bind (fun id => (state.generators[id]?).map (id, ·)) with
  | none => state
  | some (id, generator) =>
    let subscription : PsInstanceSubscription := { waiter, ownsContext := decide (id >= priorSize) }
    match generator.answer with
    | some answer =>
      { state with
        work := (generator.generalized ++ [answer]).map
          (PsInstanceWork.resume subscription) ++ state.work }
    | none =>
      { state with
        generators := state.generators.setIfInBounds id
          { generator with waiters := subscription :: generator.waiters }
        work := generator.generalized.map (PsInstanceWork.resume subscription) ++ state.work
        table := { state.table with suspended := state.table.suspended + 1 } }

def psInstancePublish (environment : PsEnvironment) (state : PsInstanceSearchState)
    (owner : Nat) (context : PsMetaContext) (value : PsExpr) (height : Nat) :
    PsInstanceSearchState :=
  match state.generators[owner]? with
  | none => state
  | some generator =>
    if generator.answer.isSome || height > state.maxHeight then state else
    match psInstanceCheck environment generator.locals context generator.target value with
    | none => state
    | some checked =>
      match checked.value.bind (fun value =>
          (psMetaAbstract checked.context generator.locals value generator.target).map (value, ·)) with
      | none => state
      | some (value, template) =>
        if generator.generalized.any (fun prior => psMetaTemplateSameType prior.template template) then state
        else if state.table.answers >= state.limits.answers then
          { state with table := { state.table with resourceExceeded := true } }
        else
          let answer : PsInstanceTableAnswer := {
            goal := psMetaInstantiate checked.context generator.target
            template, value, height, context := checked.context }
          let generalized := !template.parameters.isEmpty
          -- An abstract answer can solve a consumer whose later subgoals
          -- constrain its parameters, but cannot finish a root on its own.
          -- Keep its waiters and remaining candidates available.
          let resumed := generator.waiters.reverse.filterMap fun subscription =>
            if psInstanceOwnerAnswered state (psInstanceWaiterOwner subscription.waiter) then none
            else some (PsInstanceWork.resume subscription answer)
          { state with
            generators := state.generators.setIfInBounds owner
              (if generalized then { generator with generalized := generator.generalized ++ [answer] }
               else { generator with answer := some answer, waiters := [] })
            work := resumed ++ state.work
            table := { state.table with
              answers := state.table.answers + 1
              generalizedAnswers := state.table.generalizedAnswers + (if generalized then 1 else 0) } }

def psInstanceGenerate (environment : PsEnvironment) (index : PsInstanceIndex)
    (state : PsInstanceSearchState) (id : Nat) : PsInstanceSearchState :=
  match state.generators[id]? with
  | none => state
  | some generator =>
    if generator.answer.isSome then state else
    match generator.key with
    | none =>
      if generator.opened then state else
      let state := { state with
        generators := state.generators.setIfInBounds id { generator with opened := true } }
      match psWhnf environment generator.context generator.locals
          (psMetaInstantiate generator.context generator.target) with
      | .forallE name domain body binder =>
        let pushed := psLocalPushBinding generator.locals name domain binder
        let target := psExprInstantiate1 body (.fvar pushed.id)
        let abstraction : PsInstanceAbstraction := {
          owner := id, locals := pushed.context, localId := pushed.id,
          name, domain, binder, target }
        let scope := state.nextScope
        psInstanceAwait environment index { state with nextScope := scope + 1 }
          scope pushed.context generator.context target (.abstraction abstraction)
      | _ => state
    | some _ =>
      match generator.entries with
      | [] => state
      | entry :: rest =>
        if state.table.candidateChecks >= state.limits.candidates then
          { state with table := { state.table with resourceExceeded := true } }
        else
          let state := { state with
            generators := state.generators.setIfInBounds id { generator with entries := rest }
            work := .generate id :: state.work
            table := { state.table with candidateChecks := state.table.candidateChecks + 1 } }
          let candidate := psPrepareInstance environment generator.locals generator.context entry
          if !candidate.success then state else
          let checked := psUnify environment generator.locals candidate.context
            candidate.resultType generator.target
          if !checked.success then state else
          let pending := candidate.arguments.filterMap fun arg =>
            if arg.isInstance then
              match arg.expr with | .mvar id => some id | _ => none
            else none
          let consumer : PsInstanceConsumer := {
            owner := id, context := checked.context, value := candidate.value,
            arguments := candidate.arguments, pending }
          { state with work := .consume consumer :: state.work }

def psInstanceConsume (environment : PsEnvironment) (index : PsInstanceIndex)
    (state : PsInstanceSearchState) (consumer : PsInstanceConsumer) :
    PsInstanceSearchState :=
  match state.generators[consumer.owner]? with
  | none => state
  | some generator =>
    if generator.answer.isSome || consumer.height > state.maxHeight then state else
    let pending := consumer.pending.filter fun id =>
      (psMetaFindAssignment consumer.context id).isNone
    if pending.isEmpty then
      psInstancePublish environment state consumer.owner consumer.context
        (psMetaInstantiate consumer.context consumer.value) consumer.height
    else
      -- Do not mistake an unknown input for a failing class. Another ready
      -- dictionary may determine it, including one later in the telescope.
      let ready := pending.findSome? fun id =>
        (psMetaFindDecl consumer.context id).bind fun declaration =>
          let target := psMetaInstantiate consumer.context declaration.type
          if psInstanceGoalReady environment generator.locals consumer.context target then
            some (id, target)
          else none
      match ready with
      | none => state
      | some (id, target) =>
        psInstanceAwait environment index state generator.scope generator.locals
          consumer.context target (.argument { consumer with pending } id target)

def psInstanceReceive (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (target : PsExpr) (ownsContext : Bool)
    (answer : PsInstanceTableAnswer) : Option PsSynthInstanceResult := do
  if ownsContext then
    psInstanceCheck environment locals answer.context target answer.value
  else do
    let (context, value, _) ← psMetaOpenTemplate context locals answer.template
    psInstanceCheck environment locals context target value

def psInstanceResume (environment : PsEnvironment) (state : PsInstanceSearchState)
    (subscription : PsInstanceSubscription) (answer : PsInstanceTableAnswer) :
    PsInstanceSearchState :=
  let waiter := subscription.waiter
  let owner := psInstanceWaiterOwner waiter
  match state.generators[owner]? with
  | none => state
  | some generator =>
    if generator.answer.isSome then state else
    let state := { state with table := { state.table with
      resumed := state.table.resumed + 1
      freshenedAnswers := state.table.freshenedAnswers + (if subscription.ownsContext then 0 else 1) } }
    match waiter with
    | .argument consumer id target =>
      let height := max consumer.height (answer.height + 1)
      if height > state.maxHeight then state else
      match psInstanceReceive environment generator.locals consumer.context target
          subscription.ownsContext answer with
      | none => state
      | some checked =>
        match checked.value.bind (psMetaAssign checked.context id) with
        | none => state
        | some context =>
          { state with work := .consume { consumer with context, height } :: state.work }
    | .abstraction abstraction =>
      let height := answer.height + 1
      if height > state.maxHeight then state else
      match psInstanceReceive environment abstraction.locals generator.context abstraction.target
          subscription.ownsContext answer with
      | none => state
      | some checked =>
        match checked.value with
        | none => state
        | some value =>
          let value := PsExpr.lam abstraction.name
            (psMetaInstantiate checked.context abstraction.domain)
            (psExprAbstractFVar abstraction.localId value) abstraction.binder
          psInstancePublish environment state owner checked.context value height

-- The sole scheduler. Recursive source instances cannot recurse on the host
-- stack; cycles subscribe to an existing node. Fuel bounds evidence height,
-- independently of graph visits, candidate attempts and queue transitions.
def psInstanceRun (fuel : Nat) (environment : PsEnvironment) (index : PsInstanceIndex)
    (state : PsInstanceSearchState) : PsInstanceSearchState :=
  if state.table.resourceExceeded || psInstanceOwnerAnswered state 0 then state else
  match state.work with
  | [] => state
  | work :: rest =>
    match fuel with
    | 0 => { state with table := { state.table with resourceExceeded := true } }
    | fuel + 1 =>
      let state := { state with
        work := rest
        table := { state.table with transitions := state.table.transitions + 1 } }
      let next := match work with
        | .generate id => psInstanceGenerate environment index state id
        | .consume consumer => psInstanceConsume environment index state consumer
        | .resume waiter answer => psInstanceResume environment state waiter answer
      psInstanceRun fuel environment index next

def psSynthInstanceWithLimits (environment : PsEnvironment) (locals : PsLocalContext)
    (index : PsInstanceIndex) (context : PsMetaContext) (height : Nat)
    (limits : PsInstanceSearchLimits) (target : PsExpr) : PsInstanceTabledResult :=
  if height == 0 then { result := psSynthFailure context, table := {} } else
  let initial : PsInstanceSearchState := { limits, maxHeight := height }
  let (initial, _) := psInstanceAcquire environment index initial 0 locals context target
  let final := psInstanceRun limits.transitions environment index initial
  let result := if final.table.resourceExceeded then psSynthFailure context else
    match (final.generators[0]?).bind (·.answer) with
    | none => psSynthFailure context
    | some answer =>
      -- Selection ignores outputs; this final check intentionally cannot
      -- backtrack into lower-priority instances to satisfy a preferred output.
      match psInstanceCheck environment locals answer.context target answer.value with
      | some checked =>
        match checked.value with
        | some value =>
          if psExprHasTermMeta value ||
              psExprHasTermMeta (psMetaInstantiate checked.context target) then psSynthFailure context
          else checked
        | none => psSynthFailure context
      | none => psSynthFailure context
  { result, table := final.table }
