import Ps.Elab.DoFor
import Ps.Elab.DoLoop

-- The initial while profile keeps recurrence in a private helper's direct
-- tail position. Nested procedural loops require a later control-result protocol.
def psElabDoWhileNestedLoop : PsSyntaxTerm -> Bool
  | .doForE _ _ _ _ _ => true
  | .doForRangeE _ _ _ _ _ _ => true
  | .doWhileE _ _ _ _ => true
  | .letE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | .letPatternE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | .doLetMutE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | .doAssignE _ _ rest _ => psElabDoWhileNestedLoop rest
  | .doBindE _ _ _ rest _ => psElabDoWhileNestedLoop rest
  | .doThenE _ rest _ => psElabDoWhileNestedLoop rest
  | .doTryE action _ recovery rest _ =>
      psElabDoWhileNestedLoop action || psElabDoWhileNestedLoop recovery ||
        psElabDoWhileNestedLoop rest
  | .doIfE _ yes no rest _ =>
      psElabDoWhileNestedLoop yes || psElabDoWhileNestedLoop no ||
        psElabDoWhileNestedLoop rest
  | _ => false

def psElabDoWhileStateType
    (context : PsElabContext) : List PsElabDoMutable -> PsExpr
  | [] => PsExpr.constE psUnitName []
  | entry :: rest =>
      psExprApplyMany (PsExpr.constE psProdName [])
        [psMetaInstantiate context.metaContext entry.type,
          psElabDoWhileStateType context rest]

def psElabDoWhileStateValue
    (context : PsElabContext) (state : List PsElabDoMutable) :
    List PsElabDoMutable -> Except PsElabError PsExpr
  | [] => .ok (PsExpr.constE psUnitUnitName [])
  | entry :: rest => do
      let some current := psElabDoMutableFindBinding entry.bindingId state
        | throw PsElabError.unsupportedTerm
      let tail <- psElabDoWhileStateValue context state rest
      pure (psExprApplyMany (PsExpr.constE psProdMkName [])
        [psMetaInstantiate context.metaContext entry.type,
          psElabDoWhileStateType context rest, PsExpr.fvar current.currentId, tail])

def psElabDoWhileOpenState
    (finish : PsElabDoForFinish) (ops : PsElabDoOps) (result : PsExpr)
    (carried : List PsElabDoMutable) (context : PsElabContext)
    (state : List PsElabDoMutable) (packed : PsExpr) :
    Except PsElabError PsElabTermResult :=
  match carried with
  | [] => finish context state
  | entry :: rest => do
      let type := psMetaInstantiate context.metaContext entry.type
      let value <- psElabResolvedTerm context (PsExpr.proj psProdName 0 packed) (some type)
      psElabDoWithLocal
        (fun current id =>
          psElabDoWhileOpenState finish ops result rest current
            (psElabDoMutableUpdate entry.bindingId id state)
            (PsExpr.proj psProdName 1 packed))
        context entry.userName type value (some (psElabDoType ops result))

def psElabDoWhileStep
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (condition body : PsSyntaxTerm) (restId recursiveId : Nat) :
    Except PsElabError PsElabTermResult := do
  let boolType := PsExpr.constE psBoolName []
  let conditionValue <- elaborate context condition (some boolType)
  psElabDoWithLocal
    (fun conditionContext conditionId => do
      let yes <- next conditionContext state body
        (fun current currentState => do
          let packed <- psElabDoWhileStateValue current currentState carried
          psElabResolvedTerm current
            (psExprApplyMany (PsExpr.fvar recursiveId)
              [packed, PsExpr.constE psUnitUnitName []])
            (some (psElabDoType ops result)))
      let noContext := psElabContextWithMeta conditionContext yes.context.metaContext
      let no <- psElabDoJoinCall ops result restId carried noContext state
      psElabDoCoreIf ops result no.context
        (PsExpr.fvar conditionId) yes.term no.term)
    context (psElabDoInternalName "_psc1WhileCondition" context)
    boolType conditionValue (some (psElabDoType ops result))

def psElabDoWhile
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (condition body rest : PsSyntaxTerm) (finish : PsElabDoForFinish) :
    Except PsElabError PsElabTermResult := do
  let some helperName := context.whileHelper
    | throw PsElabError.doWhileNeedsPartial
  match ops with
  | .compiler _ _ _ => throw PsElabError.doWhileUnsupportedBody
  | _ => pure ()
  if psElabDoWhileNestedLoop body then
    throw PsElabError.doWhileUnsupportedBody
  let resultType := psElabDoType ops result
  let reducedResult :=
    psWhnf context.environment context.metaContext context.localContext resultType
  match (psExprAppView reducedResult).head with
  | .constE name _ =>
      -- The retained profile represents these fixed primitive data types by
      -- trusted prelude headers, not by source-defined opaque type constants.
      if psNameEq name psBoolName || psNameEq name psUnitName ||
          psNameEq name psNatName || psNameEq name psIntName ||
          psNameEq name psStringName || psNameEq name psCharName then
        pure ()
      else
        match psEnvironmentFind context.environment name with
        | some (.inductiveDecl _) => pure ()
        | _ => throw PsElabError.doWhileUnsupportedBody
  | _ => throw PsElabError.doWhileUnsupportedBody
  let carried := psElabDoMutableVisible context state
  let continuation <- psElabDoJoin
    (fun current currentState => next current currentState rest finish)
    carried context state
  psElabDoWithLocal
    (fun loopContext restId => do
      let unitType := PsExpr.constE psUnitName []
      let stateType := psElabDoWhileStateType loopContext carried
      let thunkType := psElabDoLoopArrow unitType resultType
      let recursiveType := psElabDoLoopArrow stateType thunkType
      let fallback <- psElabDoForLambda
        (fun current _ => psElabDoJoinCall ops result restId carried current state)
        loopContext (psElabDoInternalName "_psc1WhileFallback" loopContext) unitType
      let current := psElabContextWithMeta loopContext fallback.context.metaContext
      let step <- psElabDoForLambda
        (fun recursiveContext recursiveId =>
          psElabDoForLambda
            (fun stateContext stateId =>
              psElabDoForLambda
                (fun thunkContext _ =>
                  psElabDoWhileOpenState
                    (fun bodyContext bodyState =>
                      psElabDoWhileStep elaborate next ops result bodyContext
                        bodyState carried condition body restId recursiveId)
                    ops result carried thunkContext state (PsExpr.fvar stateId))
                stateContext (psElabDoInternalName "_psc1WhileUnit" stateContext) unitType)
            recursiveContext (psElabDoInternalName "_psc1WhileState" recursiveContext) stateType)
        current (psElabDoInternalName "_psc1WhileNext" current) recursiveType
      let current := psElabContextWithMeta current step.context.metaContext
      let initial <- psElabDoWhileStateValue current state carried
      psElabResolvedTerm current
        (psExprApplyMany (PsExpr.constE helperName [])
          [stateType, resultType, fallback.term, step.term, initial,
            PsExpr.constE psUnitUnitName []])
        (some resultType))
    context (psElabDoInternalName "_psc1WhileRest" context)
    continuation.type continuation (some resultType)
