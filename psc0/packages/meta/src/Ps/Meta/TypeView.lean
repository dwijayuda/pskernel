import Ps.Meta.Infer

-- Recover annotations from an elaborated Core graph without repeating
-- application argument checking. This is a view, never admission authority.
def psExprTypeViewWithFuel
    (environment : PsEnvironment) (fuel : Nat)
    (localContext : PsLocalContext) (expr : PsExpr) :
    Except PsInferError PsExpr :=
  match fuel with
  | Nat.zero => Except.error PsInferError.fuelExhausted
  | Nat.succ remaining =>
      match expr with
      | PsExpr.app fn argument =>
          match psExprTypeViewWithFuel environment remaining localContext fn with
          | Except.error error => Except.error error
          | Except.ok functionType =>
              match psWhnf environment psMetaEmpty localContext functionType with
              | PsExpr.forallE _ _ body _ =>
                  Except.ok (psExprInstantiate1 body argument)
              | _ => Except.error PsInferError.expectedFunction
      | PsExpr.lam name domain body binder =>
          let pushed := psLocalPushBinding localContext name domain binder;
          match psExprTypeViewWithFuel environment remaining pushed.context
              (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
          | Except.error error => Except.error error
          | Except.ok bodyType =>
              Except.ok
                (PsExpr.forallE name domain (psExprAbstractFVar pushed.id bodyType) binder)
      | PsExpr.letE name type value body =>
          let pushed := psLocalPushLet localContext name type value;
          match psExprTypeViewWithFuel environment remaining pushed.context
              (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
          | Except.error error => Except.error error
          | Except.ok bodyType =>
              Except.ok
                (psExprInstantiate1 (psExprAbstractFVar pushed.id bodyType) value)
      | PsExpr.proj typeName index target =>
          match psExprTypeViewWithFuel environment remaining localContext target with
          | Except.error error => Except.error error
          | Except.ok targetType =>
              match psInferProjectionType environment psMetaEmpty localContext
                  targetType typeName index target with
              | Except.error error => Except.error error
              | Except.ok type => Except.ok type
      | _ =>
          match psInferTypeWithFuel environment psMetaEmpty localContext
              (Nat.succ remaining) expr with
          | Except.error error => Except.error error
          | Except.ok type => Except.ok type

def psExprTypeView
    (environment : PsEnvironment) (localContext : PsLocalContext) (expr : PsExpr) :
    Except PsInferError PsExpr :=
  psExprTypeViewWithFuel environment 4096 localContext expr

-- Runtime preparation must not introduce executable helpers for proofs or
-- type-valued computations, including functions that return types/predicates.
def psTypeViewReturnsSort (fuel : Nat) (environment : PsEnvironment)
    (locals : PsLocalContext) (type : PsExpr) : Except PsInferError Bool :=
  match fuel with
  | 0 => .error .fuelExhausted
  | fuel + 1 =>
    match psWhnf environment psMetaEmpty locals type with
    | .sortE _ => .ok true
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      psTypeViewReturnsSort fuel environment pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | _ => .ok false

def psTypeViewIsErased (environment : PsEnvironment)
    (locals : PsLocalContext) (type : PsExpr) : Except PsInferError Bool := do
  if (← psTypeViewReturnsSort 4096 environment locals type) then return true
  let sort ← psExprTypeView environment locals type
  match psWhnf environment psMetaEmpty locals sort with
  | .sortE level => return psInferClosedLevelValue level == some 0
  | _ => throw .expectedSort
