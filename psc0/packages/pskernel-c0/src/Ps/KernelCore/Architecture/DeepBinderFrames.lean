import Ps.KernelCore.Architecture.DeepSubstitutionTape

/-!
Non-admitting source-stage extraction for a CHECKED lambda binder.

Unlike an application-only frame stack, dag_app_binder is a deeply
alternating application/lambda DAG. This module separates a lambda's
source-owned domain/sort/freshness/substitution preparation from its body
judgment and final closing, so a future machine can suspend/resume the body
without carrying its original recursive call stack.

The original source smaller callback is retained for domain and body;
no claim of fuel-independent typing or authentic 4000-layer acceptance is
made by these operations. Neither provider nor production checker calls them.
-/

/-- Exact data needed to resume the original checked lambda rule.
    In particular, sourceFreshState must survive through body inference so
    the original ExitLocalScope operation retains its precise provenance. -/
structure PsKernelC0DeepLambdaFrame where
  name : PsKernelName
  domain : PsKernelExpr
  originalBody : PsKernelExpr
  binderInfo : PsKernelBinderInfo
  fresh : PsKernelName
  sourceFreshState : PsKernelCheckerState
  scopedContext : PsKernelCheckerContext
  openedBody : PsKernelExpr
  remainingRanges : List Nat

/-- Perform exactly the original CHECKED-domain inference, sort check,
    fresh local generation, local-context extension and de Bruijn opening.
    No unchecked inference result or source memo can authorize this stage. -/
def psKernelC0DeepLambdaPrepare
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (currentBinderRanges : List Nat) :
    Except String PsKernelC0DeepLambdaFrame :=
  match smaller [] [] whnf defeq nextContext state domain false with
  | .error error => .error error
  | .ok domainResult =>
    match psKernelEnsureSortWith whnf nextContext
        domainResult.2 domainResult.1 with
    | .error error => .error error
    | .ok sortResult =>
      let freshResult := psKernelCheckerStateFreshName sortResult.2 name
      let fresh := freshResult.1
      let state1 := freshResult.2
      let childLocal :=
        psKernelLocalContextAddLocal nextContext.localContext
          fresh name domain binderInfo
      let child := psKernelCheckerContextWithLocalContext nextContext childLocal
      let (openedBody, restRanges) :=
        match currentBinderRanges with
        | range :: tail =>
          if range == 0 then (body, tail)
          else (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh), [])
        | [] => (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh), [])
      .ok {
        name := name
        domain := domain
        originalBody := body
        binderInfo := binderInfo
        fresh := fresh
        sourceFreshState := state1
        scopedContext := child
        openedBody := openedBody
        remainingRanges := restRanges
      }

/-- Finish a previously checked binder body using exactly the C0 source
    cheap beta, abstraction, local-scope exit and checked inference cache.
    This function never decides that the body was well typed; callers
    must first obtain a legitimate checked source body judgment. -/
def psKernelC0DeepLambdaClose
    (frame : PsKernelC0DeepLambdaFrame)
    (bodyType : PsKernelExpr)
    (bodyState : PsKernelCheckerState) :
    PsKernelExpr × PsKernelCheckerState :=
  let bodyType := psKernelExprCheapBetaReduce bodyType
  let closedBody := psKernelExprAbstractFVars bodyType [frame.fresh]
  let result := PsKernelExpr.forallE
    frame.name frame.domain closedBody frame.binderInfo
  (result,
    psKernelCacheInferResult
      (psKernelCheckerStateExitLocalScope frame.sourceFreshState bodyState)
      false
      (.lam frame.name frame.domain frame.originalBody frame.binderInfo)
      result)

/-- Source-backed executor of the split lambda rule, retaining the original
    checked recursive callback for the body. This is a research oracle for
    later continuation-machine transitions, NOT yet a trampoline. -/
def psKernelC0DeepLambdaSplit
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (currentBinderRanges : List Nat) :
    Except String (PsKernelExpr × PsKernelCheckerState) := do
  let frame ← psKernelC0DeepLambdaPrepare smaller whnf defeq
    nextContext state name domain body binderInfo currentBinderRanges
  let (bodyType, bodyState) ←
    smaller [] frame.remainingRanges whnf defeq
      frame.scopedContext frame.sourceFreshState frame.openedBody false
  pure (psKernelC0DeepLambdaClose frame bodyType bodyState)

/-- In a non-admitting proof-carrying route, the ONLY source of a
    successful checked binder receipt remains the original checker. -/
structure PsKernelC0DeepLambdaReceipt
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (ranges : List Nat) where
  result : PsKernelExpr × PsKernelCheckerState
  source : psKernelInferLambdaHead smaller whnf defeq
    context state name domain body binderInfo false ranges = .ok result

def psKernelC0DeepLambdaSourceReceipt
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (ranges : List Nat) :
    Except String
      (PsKernelC0DeepLambdaReceipt smaller whnf defeq
        context state name domain body binderInfo ranges) :=
  match h : psKernelInferLambdaHead smaller whnf defeq
      context state name domain body binderInfo false ranges with
  | .error message => .error message
  | .ok result => .ok ⟨result, h⟩
