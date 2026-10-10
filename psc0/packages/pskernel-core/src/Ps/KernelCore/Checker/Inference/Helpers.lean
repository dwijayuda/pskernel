import Ps.KernelCore.Core.InferenceBoundary
import Ps.KernelCore.Checker.Projection
import Ps.KernelCore.Checker.ResourcePolicy
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-
Inference helper layer.

This module owns checker-state publication of inference results, WHNF views for
Sort/Pi expectations, and the application-spine exposure worker used by
syntax-directed inference. These helpers do not choose the typing rule for an
expression.

The pure decision of which inference results are worth memoizing is a
non-semantic acceleration policy owned by
`Runtime/Acceleration/CachePolicy.lean`. This module only applies that policy
to the checker state.
-/



def psKernelCacheInferResult
    [cachePolicy : PsKernelSemanticCachePolicy]
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
        psKernelSemanticCacheInsert
          state.inferOnly
          expr
          result;
      psKernelCheckerStateWithInferOnly
        state
        cache
    else
      let cache :=
        psKernelSemanticCacheInsert
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

/-- Extra annotation certification is conservative: inability to certify is
a decline, not a logical rejection. Preserve resource exhaustion exactly. -/
def psKernelLambdaCodomainSortFailure (message : String) : String :=
  match psKernelResourceMessage message with
  | Option.some _ => message
  | Option.none => "lambda codomain sort could not be certified"


/-- A successful infer-then-sort visit retains both the actual inferred type
and the level exposed from it. This runtime data does not itself prove typing. -/
structure PsKernelSortVisitResult where
  inferredType : PsKernelExpr
  level : PsKernelLevel

/-- Infer-only lambda visits skip the extra codomain check. The unchecked
case contains no selected level and cannot supply an annotation. -/
inductive PsKernelLambdaCodomainVisit where
  | unchecked
  | observed (visit : PsKernelSortVisitResult)

def psKernelLambdaCodomainVisitLevel
    (visit : PsKernelLambdaCodomainVisit) : Option PsKernelLevel :=
  match visit with
  | PsKernelLambdaCodomainVisit.unchecked => Option.none
  | PsKernelLambdaCodomainVisit.observed result => Option.some result.level

/-- The shared infer-then-expose operation used at actual binder sort sites. -/
def psKernelInferSortWith
    (infer :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelSortVisitResult PsKernelCheckerState) :=
  match infer context state expr with
  | Except.error error => Except.error error
  | Except.ok inferred =>
      match psKernelEnsureSortWith whnf context (Prod.snd inferred) (Prod.fst inferred) with
      | Except.error error => Except.error error
      | Except.ok exposed =>
          Except.ok
            (Prod.mk
              { inferredType := Prod.fst inferred, level := Prod.fst exposed }
              (Prod.snd exposed))

/-- Preserve the lambda grade and its established error classification while
retaining the actual checked codomain visit. The infer callback is infer-only
at the production lambda call site. -/
def psKernelLambdaCodomainVisitWith
    (infer :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (bodyType : PsKernelExpr)
    (inferOnly : Bool) :
    Except String
      (Prod PsKernelLambdaCodomainVisit PsKernelCheckerState) :=
  if inferOnly then
    Except.ok (Prod.mk PsKernelLambdaCodomainVisit.unchecked state)
  else
    match psKernelInferSortWith infer whnf context state bodyType with
    | Except.error error =>
        Except.error (psKernelLambdaCodomainSortFailure error)
    | Except.ok result =>
        Except.ok
          (Prod.mk
            (PsKernelLambdaCodomainVisit.observed (Prod.fst result))
            (Prod.snd result))

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
