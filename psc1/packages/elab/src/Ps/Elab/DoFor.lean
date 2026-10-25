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
    Except PsElabError PsElabTermResult :=
  let pushed := psLocalPushBinding context.localContext name domain PsBinderInfo.explicit;
  match next (psElabContextWithLocal context pushed.context) pushed.id with
  | Except.error error => Except.error error
  | Except.ok body =>
      let metas := body.context.metaContext;
      let term := PsExpr.lam name (psMetaInstantiate metas domain)
        (psExprAbstractFVar pushed.id (psMetaInstantiate metas body.term))
        PsBinderInfo.explicit;
      psElabResolvedTerm (psElabContextRestoreScope context body.context) term Option.none

def psElabDoForApply
    (ops : PsElabDoOps) (result : PsExpr) (fn : PsExpr)
    (carried : List PsElabDoMutable) (context : PsElabContext)
    (state : List PsElabDoMutable) : Except PsElabError PsElabTermResult :=
  match psElabDoJoinArguments state carried with
  | Except.error error => Except.error error
  | Except.ok arguments =>
      psElabResolvedTerm context (psExprApplyMany fn arguments)
        (Option.some (psElabDoType ops result))

def psElabDoForIteration
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (body : PsSyntaxTerm) (continuationId : Nat) :
    Except PsElabError PsElabTermResult :=
  psElabDoJoin
    (fun (loopContext : PsElabContext) (loopState : List PsElabDoMutable) =>
      next loopContext loopState body
        (psElabDoJoinCall ops result continuationId carried))
    carried context state

-- Force a deferred tail only on normal completion of this iteration.
-- Return and source errors bypass the tail through the existing checked owner.
def psElabDoForDeferredIteration
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (body : PsSyntaxTerm) (continuationId : Nat) :
    Except PsElabError PsElabTermResult :=
  psElabDoJoin
    (fun (loopContext : PsElabContext) (loopState : List PsElabDoMutable) =>
      next loopContext loopState body
        (fun (current : PsElabContext) (currentState : List PsElabDoMutable) =>
          psElabDoForApply ops result
            (PsExpr.app (PsExpr.fvar continuationId) (PsExpr.constE psUnitUnitName []))
            carried current currentState))
    carried context state

def psElabDoForSort
    (context : PsElabContext) (type : PsExpr) : Except PsElabError PsLevel :=
  match psInferType context.environment context.metaContext context.localContext type with
  | Except.error error => Except.error (PsElabError.infer error)
  | Except.ok typeType =>
      match psInferEnsureSort context.environment context.metaContext context.localContext typeType with
      | Except.error error => Except.error (PsElabError.infer error)
      | Except.ok level => Except.ok level

def psElabDoForList
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (name : PsName) (element collection : PsExpr) (body : PsSyntaxTerm)
    (continuationId : Nat) (continuationType : PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabDoForLambda
      (fun (elementContext : PsElabContext) (elementId : Nat) =>
        psElabDoForLambda
          (fun (recursiveContext : PsElabContext) (recursiveId : Nat) =>
            psElabDoForDeferredIteration next ops result recursiveContext state carried body recursiveId)
          elementContext (psElabDoInternalName "_psc1ForTail" elementContext)
            (psControlDeferredType continuationType))
      context name element with
  | Except.error error => Except.error error
  | Except.ok minor =>
      let current := psElabContextRestoreScope context minor.context;
      let folded := psExprApplyMany (PsExpr.constE psControlLazyListFoldName [])
        [element, continuationType, PsExpr.fvar continuationId, minor.term, collection];
      match psElabResolvedTerm current folded (Option.some continuationType) with
      | Except.error error => Except.error error
      | Except.ok checked =>
          psElabDoForApply ops result checked.term carried checked.context state

-- Build a linear immutable element view, then use the same deferred iterator.
-- No function-valued Array fold accumulator prebuilds user continuations.
def psElabDoForArray
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state carried : List PsElabDoMutable)
    (name : PsName) (element collection : PsExpr) (body : PsSyntaxTerm)
    (continuationId : Nat) (continuationType : PsExpr) :
    Except PsElabError PsElabTermResult :=
  let listType := psSelfHostListOf element;
  let converted := psExprApplyMany (PsExpr.constE psControlArrayToListName [])
    [element, collection];
  match psElabResolvedTerm context converted (Option.some listType) with
  | Except.error error => Except.error error
  | Except.ok values =>
      psElabDoWithLocal
        (fun (current : PsElabContext) (id : Nat) =>
          psElabDoForList next ops result current state carried name element
            (PsExpr.fvar id) body continuationId continuationType)
        context (psElabDoInternalName "_psc1ArrayItems" context) listType values
        (Option.some (psElabDoType ops result))

def psElabDoForName (sourceName : PsSyntaxName) (state : List PsElabDoMutable) :
    Except PsElabError PsName :=
  match psSyntaxNameToName sourceName with
  | Option.none => Except.error PsElabError.emptyName
  | Option.some name =>
      if psElabDoMutableHasName name state then
        Except.error (PsElabError.doMutableShadowing name)
      else Except.ok name

def psElabDoForSelection (reduced : PsExpr) : Except PsElabError (Prod Bool PsExpr) :=
  let view := psExprAppView reduced;
  match view.head with
  | PsExpr.constE family levels =>
      match levels with
      | List.nil =>
          match view.args with
          | List.nil => Except.error PsElabError.doForUnsupportedIterable
          | List.cons element rest =>
              match rest with
              | List.nil =>
                  if psNameEq family psListName then Except.ok (Prod.mk false element)
                  else if psNameEq family psArrayName then Except.ok (Prod.mk true element)
                  else Except.error PsElabError.doForUnsupportedIterable
              | _ => Except.error PsElabError.doForUnsupportedIterable
      | _ => Except.error PsElabError.doForUnsupportedIterable
  | _ => Except.error PsElabError.doForUnsupportedIterable

def psElabDoFor
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (sourceName : PsSyntaxName) (collection body rest : PsSyntaxTerm)
    (finish : PsElabDoForFinish) : Except PsElabError PsElabTermResult :=
  match psElabDoForName sourceName state with
  | Except.error error => Except.error error
  | Except.ok name =>
      match elaborate context collection Option.none with
      | Except.error error => Except.error error
      | Except.ok source =>
          let reduced := psWhnf source.context.environment source.context.metaContext
            source.context.localContext source.type;
          match psElabDoForSelection reduced with
          | Except.error error => Except.error error
          | Except.ok selection =>
              let expected : Option PsExpr := Option.some (psElabDoType ops result);
              psElabDoWithLocal
                (fun (collectionContext : PsElabContext) (collectionId : Nat) =>
                  let carried := psElabDoMutableVisible collectionContext state;
                  match psElabDoJoin
                      (fun (restContext : PsElabContext) (restState : List PsElabDoMutable) =>
                        next restContext restState rest finish)
                      carried collectionContext state with
                  | Except.error error => Except.error error
                  | Except.ok continuation =>
                      psElabDoWithLocal
                        (fun (loopContext : PsElabContext) (continuationId : Nat) =>
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
    Except PsElabError PsElabTermResult :=
  let natType := PsExpr.constE psNatName [];
  match psElabDoForLambda
      (fun (indexContext : PsElabContext) (indexId : Nat) =>
        psElabDoForLambda
          (fun (recursiveContext : PsElabContext) (recursiveId : Nat) =>
            let successor := PsExpr.app (PsExpr.constE psNatSuccName []) (PsExpr.fvar indexId);
            let index := psExprApplyMany (PsExpr.constE psNatSubName []) [upper, successor];
            match psElabResolvedTerm recursiveContext index (Option.some natType) with
            | Except.error error => Except.error error
            | Except.ok indexValue =>
                psElabDoWithLocal
                  (fun (bodyContext : PsElabContext) (id : Nat) =>
                    psElabDoForDeferredIteration next ops result bodyContext state carried body recursiveId)
                  recursiveContext name natType indexValue (Option.some continuationType))
          indexContext (psElabDoInternalName "_psc1RangeTail" indexContext)
            (psControlDeferredType continuationType))
      context (psElabDoInternalName "_psc1RangeIndex" context) natType with
  | Except.error error => Except.error error
  | Except.ok minor =>
      let current := psElabContextRestoreScope context minor.context;
      let count := psExprApplyMany (PsExpr.constE psNatSubName []) [upper, lower];
      let folded := psExprApplyMany (PsExpr.constE psControlLazyNatFoldName [])
        [continuationType, PsExpr.fvar continuationId, minor.term, count];
      match psElabResolvedTerm current folded (Option.some continuationType) with
      | Except.error error => Except.error error
      | Except.ok checked =>
          psElabDoForApply ops result checked.term carried checked.context state

def psElabDoForRange
    (elaborate :
      PsElabContext -> PsSyntaxTerm -> Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (next : PsElabDoForNext) (ops : PsElabDoOps) (result : PsExpr)
    (context : PsElabContext) (state : List PsElabDoMutable)
    (sourceName : PsSyntaxName) (lower upper body rest : PsSyntaxTerm)
    (finish : PsElabDoForFinish) : Except PsElabError PsElabTermResult :=
  match psElabDoForName sourceName state with
  | Except.error error => Except.error error
  | Except.ok name =>
      let natType := PsExpr.constE psNatName [];
      match elaborate context lower (Option.some natType) with
      | Except.error error => Except.error error
      | Except.ok lowerValue =>
          let expected : Option PsExpr := Option.some (psElabDoType ops result);
          psElabDoWithLocal
            (fun (lowerContext : PsElabContext) (lowerId : Nat) =>
              match elaborate lowerContext upper (Option.some natType) with
              | Except.error error => Except.error error
              | Except.ok upperValue =>
                  psElabDoWithLocal
                    (fun (upperContext : PsElabContext) (upperId : Nat) =>
                      let carried := psElabDoMutableVisible upperContext state;
                      match psElabDoJoin
                          (fun (restContext : PsElabContext) (restState : List PsElabDoMutable) =>
                            next restContext restState rest finish)
                          carried upperContext state with
                      | Except.error error => Except.error error
                      | Except.ok continuation =>
                          psElabDoWithLocal
                            (fun (loopContext : PsElabContext) (continuationId : Nat) =>
                              psElabDoForRangeLoop next ops result loopContext state carried name
                                (PsExpr.fvar lowerId) (PsExpr.fvar upperId) body continuationId continuation.type)
                            upperContext (psElabDoInternalName "_psc1RangeRest" upperContext)
                            continuation.type continuation expected)
                    lowerContext (psElabDoInternalName "_psc1RangeUpper" lowerContext)
                    natType upperValue expected)
            context (psElabDoInternalName "_psc1RangeLower" context)
            natType lowerValue expected
