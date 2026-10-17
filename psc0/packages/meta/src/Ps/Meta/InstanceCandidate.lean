import Ps.Core.Subst
import Ps.Core.LevelSubst
import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Meta.Unify
import Ps.Meta.InstanceTarget
import Ps.Meta.Abstract

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

-- Candidate preparation owns a speculative snapshot. No assignments from it
-- are committed until the resulting witness has been checked by its consumer.
def psPrepareInstanceWithFuel (environment : PsEnvironment)
    (localContext : PsLocalContext) (context : PsMetaContext)
    (value type : PsExpr) (arguments : List PsPreparedInstanceArgument)
    (fuel : Nat) : PsPreparedInstance :=
  match fuel with
  | 0 => { context, value, resultType := type,
           arguments := arguments.reverse, success := false }
  | fuel + 1 =>
    let type := psWhnfWithTransparency .instances environment context localContext type
    match type with
    | .forallE _ domain body binder =>
      let isInstance := psBinderInfoIsInstance binder
      let fresh := psMetaFresh context localContext domain
        (if isInstance then .synthetic else .natural)
      psPrepareInstanceWithFuel environment localContext fresh.context
        (.app value fresh.expr) (psExprInstantiate1 body fresh.expr)
        ({ expr := fresh.expr, type := domain, isInstance } :: arguments) fuel
    | _ => { context, value, resultType := type,
             arguments := arguments.reverse, success := true }

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

-- A template replay is re-inferred in the receiver's own snapshot. Natural
-- inference parameters may remain while a consumer resolves later subgoals;
-- publication separately verifies that no synthetic obligations were abstracted.
def psInstanceCheckChecked (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (target value : PsExpr) :
    Except Unit (Option PsSynthInstanceResult) :=
  match psInferType environment context locals value with
  | .error .fuelExhausted => .error ()
  | .error _ => .ok none
  | .ok type =>
    let checked := psUnify environment locals context type target
    if checked.resourceExceeded then .error () else
    .ok (if checked.success then
      some (psSynthSuccess checked.context (psMetaInstantiate checked.context value))
    else none)

-- Compatibility API for callers that only distinguish solved from blocked.
def psInstanceCheck (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (target value : PsExpr) : Option PsSynthInstanceResult :=
  match psInstanceCheckChecked environment locals context target value with
  | .ok result => result
  | .error () => none

-- Closed evidence remains a useful stronger boundary for callers and audits.
def psInstanceReplay (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (target value : PsExpr) : Option PsSynthInstanceResult :=
  if psExprHasUnresolvedMeta value then none
  else psInstanceCheck environment locals context target value

def psInstanceGoalReady (environment : PsEnvironment) (locals : PsLocalContext)
    (context : PsMetaContext) (target : PsExpr) : Bool :=
  match psPrepareInstanceTarget environment locals context target with
  | some _ => true
  | none =>
    match psWhnfWithTransparency .instances environment context locals (psMetaInstantiate context target) with
    | .forallE _ _ _ _ => true
    | _ => false
