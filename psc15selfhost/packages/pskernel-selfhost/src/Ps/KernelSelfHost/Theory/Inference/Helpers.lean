import Ps.KernelSelfHost.TypeCheckerProjection

/-
Inference helper layer.

This module owns cache publication, WHNF views for Sort/Pi expectations, and the
application-spine exposure worker used by syntax-directed inference. These
helpers do not choose the typing rule for an expression.

Checked application nodes are intentionally not memoized. A cold checked spine
visits each node once, while memoizing every growing application tree can force
expensive structural hashing/promotion in the portable cache. Checked lambda
nodes are likewise one-shot in generated recursor-rule validation, where
memoizing each growing lambda subtree adds structural hashing without useful
reuse. Infer-only application and lambda results remain memoized because those
whole-expression inference results are commonly reused.
-/


structure PsKernelForallView where
  name : PsKernelName
  domain : PsKernelExpr
  body : PsKernelExpr
  binderInfo : PsKernelBinderInfo

def psKernelInferCacheEligible
    (inferOnly : Bool)
    (expr : PsKernelExpr) :
    Bool :=
  match expr with
  | PsKernelExpr.lit _ =>
      false
  | PsKernelExpr.app _ _ =>
      inferOnly
  | PsKernelExpr.lam _ _ _ _ =>
      inferOnly
  | _ =>
      true

def psKernelCacheInferResult
    (state : PsKernelCheckerState)
    (inferOnly : Bool)
    (expr : PsKernelExpr)
    (result : PsKernelExpr) :
    PsKernelCheckerState :=
  if
      psKernelInferCacheEligible
        inferOnly
        expr then
    if inferOnly then
      let cache :=
        psKernelExprMapInsert
          state.inferOnly
          expr
          result;
      psKernelCheckerStateWithInferOnly
        state
        cache
    else
      let cache :=
        psKernelExprMapInsert
          state.checkedInfer
          expr
          result;
      psKernelCheckerStateWithCheckedInfer
        state
        cache
  else
    state

def psKernelEnsureSortWith
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (type : PsKernelExpr) :
    Except String
      (Prod PsKernelLevel PsKernelCheckerState) :=
  match type with
  | PsKernelExpr.sort level =>
      Except.ok
        (Prod.mk level state)
  | _ =>
      match whnf context state type with
      | Except.error error =>
          Except.error error
      | Except.ok result =>
          match Prod.fst result with
          | PsKernelExpr.sort level =>
              Except.ok
                (Prod.mk
                  level
                  (Prod.snd result))
          | _ =>
              Except.error "expected sort"

def psKernelEnsureForallWith
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (type : PsKernelExpr) :
    Except String
      (Prod PsKernelForallView PsKernelCheckerState) :=
  match type with
  | PsKernelExpr.forallE name domain body binderInfo =>
      Except.ok
        (Prod.mk
          (PsKernelForallView.mk
            name
            domain
            body
            binderInfo)
          state)
  | _ =>
      match whnf context state type with
      | Except.error error =>
          Except.error error
      | Except.ok result =>
          match Prod.fst result with
          | PsKernelExpr.forallE name domain body binderInfo =>
              let view :=
                PsKernelForallView.mk
                  name
                  domain
                  body
                  binderInfo;
              Except.ok
                (Prod.mk
                  view
                  (Prod.snd result))
          | _ =>
              Except.error "expected function type"

def psKernelInferAppOnlyLoopWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    List PsKernelExpr ->
    Nat ->
    Nat ->
    PsKernelExpr ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_args : List PsKernelExpr)
        (_index : Nat)
        (_instantiated : Nat)
        (_current : PsKernelExpr) =>
        Except.error
          "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelInferAppOnlyLoopWithFuel remaining;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (args : List PsKernelExpr)
        (index : Nat)
        (instantiated : Nat)
        (current : PsKernelExpr) =>
        let argCount :=
          psKernelExprListLength args;
        if psKernelNatLt index argCount then
          match current with
          | PsKernelExpr.forallE _ _ body _ =>
              smaller
                whnf
                context
                state
                args
                (Nat.succ index)
                instantiated
                body
          | _ =>
              let pending :=
                psKernelExprListTake
                  (Nat.sub index instantiated)
                  (psKernelExprListDrop
                    instantiated
                    args);
              let exposed :=
                psKernelExprInstantiateRev
                  current
                  pending;
              match
                  psKernelEnsureForallWith
                    whnf
                    context
                    state
                    exposed with
              | Except.error error =>
                  Except.error error
              | Except.ok forallResult =>
                  let view :=
                    Prod.fst forallResult;
                  smaller
                    whnf
                    context
                    (Prod.snd forallResult)
                    args
                    (Nat.succ index)
                    index
                    view.body
        else
          Except.ok
            (Prod.mk
              (psKernelExprInstantiateRev
                current
                (psKernelExprListDrop
                  instantiated
                  args))
              state)
