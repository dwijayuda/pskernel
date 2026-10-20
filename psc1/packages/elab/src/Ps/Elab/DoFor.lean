import Ps.Elab.DoBase
import Ps.Environment.Control

-- A finite loop builds checked continuation values with the existing recursors.
-- User actions run only when the resulting continuation receives the initial
-- mutable values. This preserves left-to-right effects and genuine early return.
def PsElabDoForFinish : Type :=
  PsElabContext -> List PsElabDoMutable ->
  Except PsElabError PsElabTermResult

def PsElabDoForNext : Type :=
  PsElabContext -> List PsElabDoMutable -> PsSyntaxTerm ->
  PsElabDoForFinish -> Except PsElabError PsElabTermResult

def psElabDoForLambda
    (next : PsElabContext -> Nat -> Except PsElabError PsElabTermResult)
    (context : PsElabContext) (name : PsName) (domain : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let pushed := psLocalPushBinding context.localContext name domain PsBinderInfo.explicit
  let body <- next (psElabContextWithLocal context pushed.context) pushed.id
  let meta := body.context.metaContext
  let term := PsExpr.lam name (psMetaInstantiate meta domain)
    (psExprAbstractFVar pushed.id (psMetaInstantiate meta body.term))
    PsBinderInfo.explicit
  psElabResolvedTerm (psElabContextWithMeta context meta) term none

def psElabDoForApply
    (ops : PsElabDoOps) (result : PsExpr) (fn : PsExpr)
    (carried : List PsElabDoMutable) (context : PsElabContext)
    (state : List PsElabDoMutable) : Except PsElabError PsElabTermResult := do
  let arguments <- psElabDoJoinArguments state carried
  psElabResolvedTerm context (psExprApplyMany fn arguments)
    (some (psElabDoType ops result))

def psElabDoForIteration
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (body : PsSyntaxTerm) (continuationId : Nat) :
    Except PsElabError PsElabTermResult :=
  psElabDoJoin
    (fun loopContext loopState =>
      next loopContext loopState body
        (psElabDoJoinCall ops result continuationId carried))
    carried context state

def psElabDoForSort
    (context : PsElabContext) (type : PsExpr) : Except PsElabError PsLevel := do
  let typeType <- match psInferType context.environment context.metaContext
      context.localContext type with
    | .error error => .error (PsElabError.infer error)
    | .ok value => .ok value
  match psInferEnsureSort context.environment context.metaContext
      context.localContext typeType with
  | .error error => .error (PsElabError.infer error)
  | .ok level => .ok level

def psElabDoForList
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (name : PsName) (element collection : PsExpr) (body : PsSyntaxTerm)
    (continuationId : Nat) (continuationType : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let minor <- psElabDoForLambda
    (fun elementContext _ =>
      psElabDoForLambda
        (fun recursiveContext recursiveId =>
          psElabDoForIteration next ops result recursiveContext state carried body recursiveId)
        elementContext (psElabDoInternalName "_psc1ForTail" elementContext) continuationType)
    context name element
  let current := psElabContextWithMeta context minor.context.metaContext
  let folded := psExprApplyMany (PsExpr.constE psControlListFoldName [])
    [element, continuationType, PsExpr.fvar continuationId, minor.term, collection]
  let checked <- psElabResolvedTerm current folded (some continuationType)
  psElabDoForApply ops result checked.term carried checked.context state

def psElabDoForArray
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (name : PsName) (element collection : PsExpr) (body : PsSyntaxTerm)
    (continuationId : Nat) (continuationType : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let transformType := PsExpr.forallE (psRootName "_") continuationType
    (psExprLiftBVars 1 0 continuationType) PsBinderInfo.explicit
  let identity <- psElabDoForLambda
    (fun identityContext id =>
      psElabResolvedTerm identityContext (PsExpr.fvar id) (some continuationType))
    context (psElabDoInternalName "_psc1ForIdentity" context) continuationType
  let current := psElabContextWithMeta context identity.context.metaContext
  let minor <- psElabDoForLambda
    (fun accumulatorContext accumulatorId =>
      psElabDoForLambda
        (fun elementContext _ =>
          psElabDoForLambda
            (fun nextContext nextId => do
              let iteration <- psElabDoForIteration next ops result
                nextContext state carried body nextId
              psElabResolvedTerm iteration.context
                (PsExpr.app (PsExpr.fvar accumulatorId) iteration.term)
                (some continuationType))
            elementContext (psElabDoInternalName "_psc1ForNext" elementContext) continuationType)
        accumulatorContext name element)
    current (psElabDoInternalName "_psc1ForAccumulator" current) transformType
  let current := psElabContextWithMeta current minor.context.metaContext
  let size := psExprApplyMany (PsExpr.constE psArraySizeName []) [element, collection]
  let folded := psExprApplyMany (PsExpr.constE psArrayFoldlName [])
    [element, transformType, minor.term, identity.term, collection,
      PsExpr.lit (PsLiteral.natural 0), size]
  let completed := PsExpr.app folded (PsExpr.fvar continuationId)
  let checked <- psElabResolvedTerm current completed (some continuationType)
  psElabDoForApply ops result checked.term carried checked.context state

def psElabDoFor
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (sourceName : PsSyntaxName) (collection body rest : PsSyntaxTerm)
    (finish : PsElabDoForFinish) : Except PsElabError PsElabTermResult := do
  let name <- match psSyntaxNameToName sourceName with
    | none => .error PsElabError.emptyName
    | some value => .ok value
  if psElabDoMutableHasName name state then
    throw (PsElabError.doMutableShadowing name)
  let source <- elaborate context collection none
  let reduced := psWhnf source.context.environment source.context.metaContext
    source.context.localContext source.type
  let view := psExprAppView reduced
  let selection <- match view.head, view.args with
    | .constE family [], [element] =>
        if psNameEq family psListName then .ok (Prod.mk false element)
        else if psNameEq family psArrayName then .ok (Prod.mk true element)
        else .error PsElabError.doForUnsupportedIterable
    | _, _ => .error PsElabError.doForUnsupportedIterable
  let expected := some (psElabDoType ops result)
  psElabDoWithLocal
    (fun collectionContext collectionId => do
      let carried := psElabDoMutableVisible collectionContext state
      let continuation <- psElabDoJoin
        (fun restContext restState => next restContext restState rest finish)
        carried collectionContext state
      psElabDoWithLocal
        (fun loopContext continuationId =>
          if selection.fst then
            psElabDoForArray next ops result loopContext state carried name selection.snd
              (PsExpr.fvar collectionId) body continuationId continuation.type
          else
            psElabDoForList next ops result loopContext state carried name selection.snd
              (PsExpr.fvar collectionId) body continuationId continuation.type)
        collectionContext (psElabDoInternalName "_psc1ForRest" collectionContext)
        continuation.type continuation expected)
    context (psElabDoInternalName "_psc1ForCollection" context) source.type source expected

def psElabDoForRangeLoop
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (name : PsName) (lower upper : PsExpr) (body : PsSyntaxTerm)
    (continuationId : Nat) (continuationType : PsExpr) :
    Except PsElabError PsElabTermResult := do
  let natType := PsExpr.constE psNatName []
  let minor <- psElabDoForLambda
    (fun indexContext indexId =>
      psElabDoForLambda
        (fun recursiveContext recursiveId => do
          let successor := PsExpr.app (PsExpr.constE psNatSuccName []) (PsExpr.fvar indexId)
          let index := psExprApplyMany (PsExpr.constE psNatSubName []) [upper, successor]
          let indexValue <- psElabResolvedTerm recursiveContext index (some natType)
          psElabDoWithLocal
            (fun bodyContext _ =>
              psElabDoForIteration next ops result bodyContext state carried body recursiveId)
            recursiveContext name natType indexValue (some continuationType))
        indexContext (psElabDoInternalName "_psc1RangeTail" indexContext) continuationType)
    context (psElabDoInternalName "_psc1RangeIndex" context) natType
  let current := psElabContextWithMeta context minor.context.metaContext
  let count := psExprApplyMany (PsExpr.constE psNatSubName []) [upper, lower]
  let folded := psExprApplyMany (PsExpr.constE psControlNatFoldName [])
    [continuationType, PsExpr.fvar continuationId, minor.term, count]
  let checked <- psElabResolvedTerm current folded (some continuationType)
  psElabDoForApply ops result checked.term carried checked.context state

def psElabDoForRange
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (sourceName : PsSyntaxName) (lower upper body rest : PsSyntaxTerm)
    (finish : PsElabDoForFinish) : Except PsElabError PsElabTermResult := do
  let name <- match psSyntaxNameToName sourceName with
    | none => .error PsElabError.emptyName
    | some value => .ok value
  if psElabDoMutableHasName name state then
    throw (PsElabError.doMutableShadowing name)
  let natType := PsExpr.constE psNatName []
  let lowerValue <- elaborate context lower (some natType)
  let expected := some (psElabDoType ops result)
  psElabDoWithLocal
    (fun lowerContext lowerId => do
      let upperValue <- elaborate lowerContext upper (some natType)
      psElabDoWithLocal
        (fun upperContext upperId => do
          let carried := psElabDoMutableVisible upperContext state
          let continuation <- psElabDoJoin
            (fun restContext restState => next restContext restState rest finish)
            carried upperContext state
          psElabDoWithLocal
            (fun loopContext continuationId =>
              psElabDoForRangeLoop next ops result loopContext state carried name
                (PsExpr.fvar lowerId) (PsExpr.fvar upperId) body continuationId continuation.type)
            upperContext (psElabDoInternalName "_psc1RangeRest" upperContext)
            continuation.type continuation expected)
        lowerContext (psElabDoInternalName "_psc1RangeUpper" lowerContext)
        natType upperValue expected)
    context (psElabDoInternalName "_psc1RangeLower" context)
    natType lowerValue expected
