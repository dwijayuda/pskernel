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
      let smaller :
          PsEnvironment ->
          PsLocalContext ->
          PsMetaContext ->
          PsExpr ->
          PsExpr ->
          List PsPreparedInstanceArgument ->
          PsPreparedInstance :=
        psPrepareInstanceWithFuelWorker fuel;
      fun (environment : PsEnvironment) =>
        fun (localContext : PsLocalContext) =>
          fun (context : PsMetaContext) =>
            fun (value : PsExpr) =>
              fun (type : PsExpr) =>
                fun (arguments : List PsPreparedInstanceArgument) =>
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
  psPrepareInstanceWithFuel
    environment
    localContext
    context
    entry.value
    entry.type
    []
    128

def psSolvePreparedInstanceArgumentsWorker
    (arguments : List PsPreparedInstanceArgument) :
    (PsMetaContext -> PsExpr -> PsSynthInstanceResult) ->
    PsMetaContext ->
    PsSolveInstanceArgsResult :=
  match arguments with
  | [] =>
      fun (_synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult) =>
        fun (current : PsMetaContext) =>
          { context := current, success := true }
  | argument :: rest =>
      let smaller :
          (PsMetaContext -> PsExpr -> PsSynthInstanceResult) ->
          PsMetaContext ->
          PsSolveInstanceArgsResult :=
        psSolvePreparedInstanceArgumentsWorker rest;
      fun (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult) =>
        fun (current : PsMetaContext) =>
          match argument.expr with
          | .mvar id =>
              match psMetaFindAssignment current id with
              | Option.some _ =>
                  smaller synthesize current
              | Option.none =>
                  if argument.isInstance then
                    let targetType := psMetaInstantiate current argument.type;
                    let synthesized := synthesize current targetType;
                    match synthesized.value with
                    | Option.none => { context := current, success := false }
                    | Option.some instanceValue =>
                        match psMetaAssign synthesized.context id instanceValue with
                        | Option.none => { context := current, success := false }
                        | Option.some next =>
                            smaller synthesize next
                  else
                    { context := current, success := false }
          | _ =>
              smaller synthesize current

def psSolvePreparedInstanceArguments
    (synthesize : PsMetaContext -> PsExpr -> PsSynthInstanceResult)
    (arguments : List PsPreparedInstanceArgument)
    (current : PsMetaContext) : PsSolveInstanceArgsResult :=
  psSolvePreparedInstanceArgumentsWorker
    arguments
    synthesize
    current

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

def psSynthInstanceWithFuelWorker
    (remainingFuel : Nat) :
    PsEnvironment ->
    PsLocalContext ->
    PsInstanceIndex ->
    PsMetaContext ->
    PsExpr ->
    PsSynthInstanceResult :=
  match remainingFuel with
  | Nat.zero =>
      fun (_environment : PsEnvironment) =>
        fun (_localContext : PsLocalContext) =>
          fun (_index : PsInstanceIndex) =>
            fun (context : PsMetaContext) =>
              fun (_target : PsExpr) =>
                psSynthFailure context
  | Nat.succ fuel =>
      let smaller :
          PsEnvironment ->
          PsLocalContext ->
          PsInstanceIndex ->
          PsMetaContext ->
          PsExpr ->
          PsSynthInstanceResult :=
        psSynthInstanceWithFuelWorker fuel;
      fun (environment : PsEnvironment) =>
        fun (localContext : PsLocalContext) =>
          fun (index : PsInstanceIndex) =>
            fun (context : PsMetaContext) =>
              fun (target : PsExpr) =>
                let synthesize :
                    PsMetaContext ->
                    PsExpr ->
                    PsSynthInstanceResult :=
                  fun (nextContext : PsMetaContext) =>
                    fun (nextTarget : PsExpr) =>
                      smaller
                        environment
                        localContext
                        index
                        nextContext
                        nextTarget;
                psTryInstanceCandidates
                  environment
                  localContext
                  context
                  target
                  synthesize
                  (psAllInstanceEntries localContext index)

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
