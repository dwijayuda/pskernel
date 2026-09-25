import Ps.Core.Subst
import Ps.Environment.Basic
import Ps.Environment.Instances
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Meta.Unify

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
  { context := context, value := none }

def psSynthSuccess
    (context : PsMetaContext)
    (value : PsExpr) : PsSynthInstanceResult :=
  { context := context, value := some value }

def psBinderInfoIsInstance (binder : PsBinderInfo) : Bool :=
  match binder with
  | .instanceImplicit => true
  | _ => false

def psPrepareInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (value : PsExpr)
    (type : PsExpr)
    (arguments : List PsPreparedInstanceArgument) :
    Nat -> PsPreparedInstance
  | 0 => {
      context := context
      value := value
      resultType := type
      arguments := arguments.reverse
      success := false
    }
  | fuel + 1 =>
      let typeValue := psWhnf environment context localContext type
      match typeValue with
      | .forallE _ domain body binder =>
          let kind :=
            if psBinderInfoIsInstance binder then
              PsMetaVarKind.synthetic
            else
              PsMetaVarKind.natural
          let fresh := psMetaFresh context localContext domain kind
          let nextValue := PsExpr.app value fresh.expr
          let nextType := psExprInstantiate1 body fresh.expr
          let argument : PsPreparedInstanceArgument := {
            expr := fresh.expr
            type := domain
            isInstance := psBinderInfoIsInstance binder
          }
          psPrepareInstanceWithFuel
            environment
            localContext
            fresh.context
            nextValue
            nextType
            (List.cons argument arguments)
            fuel
      | _ => {
          context := context
          value := value
          resultType := typeValue
          arguments := arguments.reverse
          success := true
        }

def psPrepareInstance
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (context : PsMetaContext)
    (entry : PsInstanceEntry) : PsPreparedInstance :=
  psPrepareInstanceWithFuel
    environment
    localContext
    context
    entry.value
    entry.type
    []
    128

def psSolvePreparedInstanceArguments
    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult) :
    List PsPreparedInstanceArgument ->
    PsMetaContext ->
    PsSolveInstanceArgsResult
  | [], current =>
      { context := current, success := true }
  | argument :: rest, current =>
      match argument.expr with
      | .mvar id =>
          match psMetaFindAssignment current id with
          | some _ =>
              psSolvePreparedInstanceArguments synthesize rest current
          | none =>
              if argument.isInstance then
                let targetType := psMetaInstantiate current argument.type
                let synthesized := synthesize current targetType
                match synthesized.value with
                | none => { context := current, success := false }
                | some instanceValue =>
                    match psMetaAssign synthesized.context id instanceValue with
                    | none => { context := current, success := false }
                    | some next =>
                        psSolvePreparedInstanceArguments synthesize rest next
              else
                { context := current, success := false }
      | _ =>
          psSolvePreparedInstanceArguments synthesize rest current

def psTryInstanceCandidate
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (original : PsMetaContext)
    (target : PsExpr)
    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult)
    (entry : PsInstanceEntry) : PsSynthInstanceResult :=
  let prepared :=
    psPrepareInstance environment localContext original entry
  if !prepared.success then
    psSynthFailure original
  else
    let targetResult :=
      psUnify
        environment
        localContext
        prepared.context
        prepared.resultType
        target
    if !targetResult.success then
      psSynthFailure original
    else
      let solved :=
        psSolvePreparedInstanceArguments
          synthesize
          prepared.arguments
          targetResult.context
      if !solved.success then
        psSynthFailure original
      else
        let finalValue :=
          psMetaInstantiate solved.context prepared.value
        if psExprHasUnresolvedMeta finalValue then
          psSynthFailure original
        else
          psSynthSuccess solved.context finalValue

def psTryInstanceCandidates
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (original : PsMetaContext)
    (target : PsExpr)
    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult) :
    List PsInstanceEntry -> PsSynthInstanceResult
  | [] => psSynthFailure original
  | entry :: rest =>
      let attempt :=
        psTryInstanceCandidate
          environment
          localContext
          original
          target
          synthesize
          entry
      match attempt.value with
      | some _ => attempt
      | none =>
          psTryInstanceCandidates
            environment
            localContext
            original
            target
            synthesize
            rest

def psSynthInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext) :
    Nat -> PsExpr -> PsSynthInstanceResult
  | 0, _ => psSynthFailure context
  | fuel + 1, target =>
      let synthesize :=
        fun nextContext nextTarget =>
          psSynthInstanceWithFuel
            environment
            localContext
            index
            nextContext
            fuel
            nextTarget
      psTryInstanceCandidates
        environment
        localContext
        context
        target
        synthesize
        (psAllInstanceEntries localContext index)

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
