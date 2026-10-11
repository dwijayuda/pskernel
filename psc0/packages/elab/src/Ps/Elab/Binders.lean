import Ps.Elab.Abstraction

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

-- One ordered name walk consumes the expected telescope. Concrete group
-- annotations are elaborated before entering this walk and reused by identity.
-- Inferred domains remain per-name, so (x y : _) can use different expected
-- domains without inventing a dependency in the shared source annotation.
def psElabBinderName (type : Option PsExpr) (kind : PsSyntaxBinderKind)
    (state : PsElabBinderState) (sourceName : PsSyntaxName) :
    Except PsElabError PsElabBinderState := do
  let some name := psSyntaxNameToName sourceName | throw .emptyName
  let expectedPi ← match state.expected with
    | none => pure none
    | some expected =>
      match psWhnf state.context.environment state.context.metaContext
          state.context.localContext expected with
      | .forallE name domain body binder => pure (some (PsForallView.mk name domain body binder))
      | .mvar _ => pure none
      | _ => throw (.infer .expectedFunction)
  let type := match type, expectedPi with
    | some type, _ => PsElabTypeResult.mk state.context type
    | none, some pi => PsElabTypeResult.mk state.context pi.domain
    | none, none => psElabFreshType state.context
  let constraints ← match expectedPi with
    | none => pure type.context.metaContext
    | some pi =>
      let unified := psUnify type.context.environment type.context.localContext
        type.context.metaContext type.type pi.domain
      if unified.success then pure unified.context else throw .typeMismatch
  let context := psElabContextWithMeta type.context constraints
  let binder := psElabBinderKindToCore kind
  let pushed := psLocalPushBinding context.localContext name (psMetaInstantiate constraints type.type) binder
  return {
    context := psElabContextWithLocal context pushed.context
    bindersRev := PsElabTypedBinder.mk pushed.id name type.type binder :: state.bindersRev
    expected := expectedPi.map (fun pi => psExprInstantiate1 pi.body (.fvar pushed.id)) }

-- Group scope is a semantic boundary, not parser expansion into repeated
-- annotations. All names enter only after their annotation has been elaborated.
def psElabBindersWithExpected (elaborate : PsElaborator)
    (entries : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (state : PsElabBinderState) : Except PsElabError PsElabBinderState := do
  match entries with
  | [] => return state
  | (head, sourceType) :: rest =>
    let (type, state) ← match sourceType with
      | .hole _ => pure (none, state)
      | _ => do
        let annotation ← psElabType elaborate state.context sourceType
        pure (some annotation.type, { state with context := annotation.context })
    let state ← (psSyntaxBinderNames head).foldlM (psElabBinderName type head.kind) state
    psElabBindersWithExpected elaborate rest state

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
  let typeAbstractions := prepared.bindersRev.map fun binder =>
    PsMetaAbstraction.forallE binder.id binder.name binder.type binder.binder
  let closedType ← psElabAbstractType context result.context typeAbstractions result.type
  let valueAbstractions := prepared.bindersRev.map fun binder =>
    PsMetaAbstraction.lambdaE binder.id binder.name binder.type binder.binder
  let inner := psElabContextWithMeta result.context closedType.context.metaContext
  let closed ← psElabAbstract context inner valueAbstractions result.term closedType.term
  psElabFinalizeExpected closed expected

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

def psElabForall (elaborate : PsElaborator) (context : PsElabContext)
    (binders : List (PsSyntaxBinderHead × PsSyntaxTerm)) (body : PsSyntaxTerm)
    (expected : Option PsExpr) : Except PsElabError PsElabTermResult := do
  let prepared ← psElabTypedBinders elaborate context binders
  let result ← elaborate prepared.context body none
  let abstractions := prepared.bindersRev.map fun binder =>
    PsMetaAbstraction.forallE binder.id binder.name binder.type binder.binder
  let closed ← psElabAbstractType context result.context abstractions result.term
  psElabFinalizeExpected closed expected

-- Both term bindings and tactic facts use this expected-type path.
def psElabLocalValue (elaborate : PsElaborator) (context : PsElabContext)
    (declaredType : Option PsSyntaxTerm) (value : PsSyntaxTerm) :
    Except PsElabError PsElabTermResult := do
  match declaredType with
  | none => elaborate context value none
  | some sourceType =>
    let annotation ← psElabType elaborate context sourceType
    elaborate annotation.context value (some annotation.type)

def psElabLetAfterValue (elaborate : PsElaborator) (outerContext : PsElabContext)
    (name : PsName) (bindingType : PsExpr) (valueResult : PsElabTermResult)
    (body : PsSyntaxTerm) (expected : Option PsExpr) (nondependent : Bool := false) :
    Except PsElabError PsElabTermResult := do
  let pushed := if nondependent then
      psLocalPushBinding valueResult.context.localContext name bindingType .explicit
    else psLocalPushLet valueResult.context.localContext name bindingType valueResult.term
  let bodyContext := psElabContextWithLocal valueResult.context pushed.context
  let bodyResult ← elaborate bodyContext body expected
  psElabCloseLetScope outerContext bodyResult pushed.id name bindingType valueResult.term expected

def psElabLet (elaborate : PsElaborator) (context : PsElabContext)
    (nameSyntax : PsSyntaxName) (declaredType : Option PsSyntaxTerm)
    (value body : PsSyntaxTerm) (expected : Option PsExpr) (nondependent : Bool := false) :
    Except PsElabError PsElabTermResult := do
  let some name := psSyntaxNameToName nameSyntax | throw .emptyName
  let valueResult ← psElabLocalValue elaborate context declaredType value
  psElabLetAfterValue elaborate context name valueResult.type valueResult body expected nondependent

-- Open a Core telescope once, retaining its terminal body. A bounded count is
-- used for constructor fields; none opens all indices of an inductive family.
structure PsElabOpenTelescope where
  context : PsElabContext
  bindersRev : List PsElabTypedBinder
  body : PsExpr

def psElabOpenCoreTelescope (fuel : Nat) (context : PsElabContext)
    (type : PsExpr) (count : Option Nat) (bindersRev : List PsElabTypedBinder := []) :
    Except PsElabError PsElabOpenTelescope := do
  if count == some 0 then return { context, bindersRev, body := type }
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psWhnf context.environment context.metaContext context.localContext type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding context.localContext name domain binder
      psElabOpenCoreTelescope fuel (psElabContextWithLocal context pushed.context)
        (psExprInstantiate1 body (.fvar pushed.id)) (count.map Nat.pred)
        (PsElabTypedBinder.mk pushed.id name domain binder :: bindersRev)
    | body =>
      if count.isSome then throw (.infer .expectedFunction)
      return { context, bindersRev, body }

def psElabBinderArguments (bindersRev : List PsElabTypedBinder) : List PsExpr :=
  bindersRev.reverse.map (fun binder => .fvar binder.id)

def psCloseElabImplicitBinders (metaContext : PsMetaContext)
    (bindersRev : List PsElabTypedBinder) (body : PsExpr) : PsExpr :=
  psCloseElabForallBinders metaContext
    (bindersRev.map (fun binder => { binder with binder := .implicit })) body

def psCloseElabLambdaBinders (metaContext : PsMetaContext)
    (bindersRev : List PsElabTypedBinder) (body : PsExpr) : PsExpr :=
  bindersRev.foldl (fun body binder =>
    .lam binder.name (psMetaInstantiate metaContext binder.type)
      (psExprAbstractFVar binder.id body) binder.binder) body
