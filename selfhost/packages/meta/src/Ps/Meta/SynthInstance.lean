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
            (argument :: arguments)
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

def psSynthInstanceWithFuel
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (index : PsInstanceIndex)
    (context : PsMetaContext) :
    Nat -> PsExpr -> PsSynthInstanceResult
  | 0, _ => psSynthFailure context
  | fuel + 1, target =>
      psTryInstanceCandidates
        environment
        localContext
        index
        context
        fuel
        target
        (psAllInstanceEntries localContext index)
where
  psSolvePreparedArguments
      (arguments : List PsPreparedInstanceArgument)
      (current : PsMetaContext) : PsSynthInstanceResult :=
    match arguments with
    | [] =>
        psSynthSuccess current (PsExpr.lit (PsLiteral.natural 0))
    | argument :: rest =>
        match argument.expr with
        | .mvar id =>
            match psMetaFindAssignment current id with
            | some _ =>
                psSolvePreparedArguments rest current
            | none =>
                if argument.isInstance then
                  let targetType := psMetaInstantiate current argument.type
                  let synthesized :=
                    psSynthInstanceWithFuel
                      environment
                      localContext
                      index
                      current
                      fuel
                      targetType
                  match synthesized.value with
                  | none => psSynthFailure current
                  | some instanceValue =>
                      match psMetaAssign synthesized.context id instanceValue with
                      | none => psSynthFailure current
                      | some next => psSolvePreparedArguments rest next
                else
                  psSynthFailure current
        | _ => psSolvePreparedArguments rest current

  psTryInstanceCandidate
      (entry : PsInstanceEntry)
      (original : PsMetaContext) : PsSynthInstanceResult :=
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
          psSolvePreparedArguments
            prepared.arguments
            targetResult.context
        match solved.value with
        | none => psSynthFailure original
        | some _ =>
            let finalValue :=
              psMetaInstantiate solved.context prepared.value
            if psExprHasUnresolvedMeta finalValue then
              psSynthFailure original
            else
              psSynthSuccess solved.context finalValue

  psTryInstanceCandidates
      (environment : PsEnvironment)
      (localContext : PsLocalContext)
      (index : PsInstanceIndex)
      (original : PsMetaContext)
      (fuel : Nat)
      (target : PsExpr) :
      List PsInstanceEntry -> PsSynthInstanceResult
    | [] => psSynthFailure original
    | entry :: rest =>
        let attempt := psTryInstanceCandidate entry original
        match attempt.value with
        | some _ => attempt
        | none =>
            psTryInstanceCandidates
              environment
              localContext
              index
              original
              fuel
              target
              rest

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
