import Ps.Elab.Basic

structure PsElabTypedBinder where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsElabTypedBindersResult where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder

def psElabBinderKindToCore : PsSyntaxBinderKind -> PsBinderInfo
  | .explicit => PsBinderInfo.explicit
  | .implicit => PsBinderInfo.implicit
  | .strictImplicit => PsBinderInfo.strictImplicit
  | .instanceImplicit => PsBinderInfo.instanceImplicit

structure PsElabBinderState where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  expected : Option PsExpr

-- One ordered telescope walk for declarations, lambdas and forall. Expected
-- domains are available before entering each binder; each codomain is opened
-- using that binder's fresh identity before processing the next binder.
def psElabBindersWithExpected (elaborate : PsElaborator)
    (entries : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (state : PsElabBinderState) : Except PsElabError PsElabBinderState := do
  match entries with
  | [] => return state
  | (head, sourceType) :: rest =>
    let some name := psSyntaxNameToName head.name | throw .emptyName
    let expectedPi ← match state.expected with
      | none => pure none
      | some expected =>
        match psWhnf state.context.environment state.context.metaContext
            state.context.localContext expected with
        | .forallE name domain body binder => pure (some (PsForallView.mk name domain body binder))
        | .mvar _ => pure none
        | _ => throw (.infer .expectedFunction)
    let type ← match sourceType, expectedPi with
      | .hole _, some pi => pure (PsElabTermResult.mk state.context pi.domain (.sortE .zero))
      | _, _ => psElabType elaborate state.context sourceType
    let constraints ← match expectedPi with
      | none => pure type.context.metaContext
      | some pi =>
        let unified := psUnify type.context.environment type.context.localContext
          type.context.metaContext type.term pi.domain
        if unified.success then pure unified.context else throw .typeMismatch
    let context := psElabContextWithMeta type.context constraints
    let binder := psElabBinderKindToCore head.kind
    let pushed := psLocalPushBinding context.localContext name (psMetaInstantiate constraints type.term) binder
    let nextExpected := expectedPi.map (fun pi => psExprInstantiate1 pi.body (.fvar pushed.id))
    psElabBindersWithExpected elaborate rest {
      context := psElabContextWithLocal context pushed.context
      bindersRev := PsElabTypedBinder.mk pushed.id name type.term binder :: state.bindersRev
      expected := nextExpected }

def psElabTypedBindersAcc (elaborate : PsElaborator)
    (entries : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (context : PsElabContext) (bindersRev : List PsElabTypedBinder) :
    Except PsElabError PsElabTypedBindersResult := do
  let result ← psElabBindersWithExpected elaborate entries { context, bindersRev, expected := none }
  return { context := result.context, bindersRev := result.bindersRev }

def psElabTypedBinders
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsElabError PsElabTypedBindersResult :=
  psElabTypedBindersAcc elaborate binders context []

def psElabTypedBinderListReverseAux
    (remaining : List PsElabTypedBinder) :
    List PsElabTypedBinder -> List PsElabTypedBinder :=
  match remaining with
  | List.nil =>
      fun (acc : List PsElabTypedBinder) => acc
  | List.cons head tail =>
      let smaller :
          List PsElabTypedBinder -> List PsElabTypedBinder :=
        psElabTypedBinderListReverseAux tail;
      fun (acc : List PsElabTypedBinder) =>
        smaller (List.cons head acc)

def psElabTypedBinderListReverse
    (values : List PsElabTypedBinder) :
    List PsElabTypedBinder :=
  psElabTypedBinderListReverseAux values List.nil

def psCloseElabTypedBinders
    (metaContext : PsMetaContext)
    (binders : List PsElabTypedBinder) :
    PsExpr ->
    PsExpr ->
    Prod PsExpr PsExpr :=
  match binders with
  | [] =>
      fun (value : PsExpr) =>
        fun (type : PsExpr) =>
          Prod.mk value type
  | binder :: rest =>
      let smaller :
          PsExpr ->
          PsExpr ->
          Prod PsExpr PsExpr :=
        psCloseElabTypedBinders metaContext rest;
      fun (value : PsExpr) =>
        fun (type : PsExpr) =>
          let binderType :=
            psMetaInstantiate metaContext binder.type;
          let closedValue :=
            PsExpr.lam
              binder.name
              binderType
              (psExprAbstractFVar binder.id value)
              binder.binder;
          let closedType :=
            PsExpr.forallE
              binder.name
              binderType
              (psExprAbstractFVar binder.id type)
              binder.binder;
          smaller closedValue closedType

def psElabLambda (elaborate : PsElaborator) (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (body : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult := do
  let prepared ← psElabBindersWithExpected elaborate binders {
    context, bindersRev := [], expected }
  let result ← elaborate prepared.context body prepared.expected
  let constraints := result.context.metaContext
  let closed := psCloseElabTypedBinders constraints prepared.bindersRev
    (psMetaInstantiate constraints result.term) (psMetaInstantiate constraints result.type)
  psElabFinalizeExpected
    (PsElabTermResult.mk (psElabLeaveScope context result.context) closed.fst closed.snd) expected

def psCloseElabForallBinders
    (metaContext : PsMetaContext)
    (binders : List PsElabTypedBinder) :
    PsExpr ->
    PsExpr :=
  match binders with
  | [] =>
      fun (body : PsExpr) =>
        body
  | binder :: rest =>
      let smaller : PsExpr -> PsExpr :=
        psCloseElabForallBinders metaContext rest;
      fun (body : PsExpr) =>
        let binderType :=
          psMetaInstantiate metaContext binder.type;
        let closedBody :=
          PsExpr.forallE
            binder.name
            binderType
            (psExprAbstractFVar binder.id body)
            binder.binder;
        smaller closedBody

def psElabForall
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psElabTypedBinders elaborate context binders with
  | Except.error error => Except.error error
  | Except.ok binderResult =>
      match elaborate binderResult.context body Option.none with
      | Except.error error => Except.error error
      | Except.ok bodyResult =>
          match psInferEnsureSort
              bodyResult.context.environment
              bodyResult.context.metaContext
              bodyResult.context.localContext
              bodyResult.type with
          | Except.error error =>
              Except.error (PsElabError.infer error)
          | Except.ok _ =>
              let metaContext := bodyResult.context.metaContext;
              let openBody :=
                psMetaInstantiate metaContext bodyResult.term;
              let closed :=
                psCloseElabForallBinders
                  metaContext
                  binderResult.bindersRev
                  openBody;
              let outerContext :=
                psElabLeaveScope context bodyResult.context;
              psElabResolvedTerm
                outerContext
                closed
                expected

def psElabLetAfterValue
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (outerContext : PsElabContext)
    (name : PsName)
    (bindingType : PsExpr)
    (valueResult : PsElabTermResult)
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let pushed :=
    psLocalPushLet
      valueResult.context.localContext
      name
      bindingType
      valueResult.term;
  let bodyContext :=
    psElabContextWithLocal
      valueResult.context
      pushed.context;
  match elaborate bodyContext body expected with
  | Except.error error => Except.error error
  | Except.ok bodyResult =>
      let metaContext := bodyResult.context.metaContext;
      let closedBindingType :=
        psMetaInstantiate metaContext bindingType;
      let closedValue :=
        psMetaInstantiate metaContext valueResult.term;
      let openBody :=
        psMetaInstantiate metaContext bodyResult.term;
      let closedBody :=
        psExprAbstractFVar pushed.id openBody;
      let term :=
        PsExpr.letE
          name
          closedBindingType
          closedValue
          closedBody;
      let restoredContext :=
        psElabLeaveScope outerContext bodyResult.context;
      psElabResolvedTerm
        restoredContext
        term
        expected

def psElabLet
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (nameSyntax : PsSyntaxName)
    (declaredType : Option PsSyntaxTerm)
    (value : PsSyntaxTerm)
    (body : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match psSyntaxNameToName nameSyntax with
  | none => Except.error PsElabError.emptyName
  | some name =>
      match declaredType with
      | none =>
          match elaborate context value Option.none with
          | Except.error error => Except.error error
          | Except.ok valueResult =>
              psElabLetAfterValue
                elaborate
                context
                name
                valueResult.type
                valueResult
                body
                expected
      | some sourceType =>
          match elaborate context sourceType Option.none with
          | Except.error error => Except.error error
          | Except.ok typeResult =>
              match psInferEnsureSort
                  typeResult.context.environment
                  typeResult.context.metaContext
                  typeResult.context.localContext
                  typeResult.type with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok _ =>
                  match elaborate
                      typeResult.context
                      value
                      (Option.some typeResult.term) with
                  | Except.error error => Except.error error
                  | Except.ok valueResult =>
                      psElabLetAfterValue
                        elaborate
                        context
                        name
                        typeResult.term
                        valueResult
                        body
                        expected

