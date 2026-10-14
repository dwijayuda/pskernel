import Ps.KernelCore.Checker.Inference.Constant

/-!
Source-compatible dependent-binder inference rules.

Pinned Lean 4.35 src/kernel/type_checker.cpp::infer_lambda/infer_pi is
the reference for binder-domain checking, opening local declarations,
fresh-name generation, recursive body typing, universe imax, and close
by abstraction. These are the existing C0 source rules mechanically
extracted from Checker/Inference/Core.lean without reordering any source
state, fuel, cache, WHNF, or DefEq effects.

The explicit smaller callback is exactly the prior recursive inference
worker. This extraction does not independently prove all inner recursive
typing operations; it creates one reusable kernel binder-step boundary
for subsequent source-refinement proof obligations.
-/

abbrev PsKernelC0BinderWhnf :=
  PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
    Except String (PsKernelExpr × PsKernelCheckerState)

abbrev PsKernelC0BinderDefEq :=
  PsKernelCheckerContext → PsKernelCheckerState →
    PsKernelExpr → PsKernelExpr →
    Except String (Bool × PsKernelCheckerState)

abbrev PsKernelC0BinderSmaller :=
  List (Nat × Nat) → List Nat →
    PsKernelC0BinderWhnf → PsKernelC0BinderDefEq →
    PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
    Bool → Except String (PsKernelExpr × PsKernelCheckerState)

/-- The original checked lambda rule; its recursive worker and all
    environment-local state transitions are passed explicitly. -/
def psKernelInferLambdaHead
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (inferOnly : Bool)
    (currentBinderRanges : List Nat) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .lam name domain body binderInfo
  let checkedDomain :=
    if inferOnly then
      Except.ok
        (Prod.mk
          domain
          state)
    else
      match
          smaller [] []
            whnf
            defeq
            nextContext
            state
            domain
            false with
      | Except.error error =>
          Except.error error
      | Except.ok domainResult =>
          match
              psKernelEnsureSortWith
                whnf
                nextContext
                (Prod.snd domainResult)
                (Prod.fst domainResult) with
          | Except.error error =>
              Except.error error
          | Except.ok sortResult =>
              Except.ok
                (Prod.mk
                  domain
                  (Prod.snd sortResult));
  match checkedDomain with
  | Except.error error =>
      Except.error error
  | Except.ok domainState =>
      let freshResult :=
        psKernelCheckerStateFreshName
          (Prod.snd domainState)
          name;
      let fresh :=
        Prod.fst freshResult;
      let state1 :=
        Prod.snd freshResult;
      let childLocal :=
        psKernelLocalContextAddLocal
          nextContext.localContext
          fresh
          name
          domain
          binderInfo;
      let child :=
        psKernelCheckerContextWithLocalContext
          nextContext
          childLocal;
      let (openedBody, restRanges) :=
        match currentBinderRanges with
        | range :: tail =>
            if range == 0 then (body, tail)
            else (psKernelExprInstantiate1 body
              (PsKernelExpr.fvar fresh), [])
        | [] => (psKernelExprInstantiate1 body
            (PsKernelExpr.fvar fresh), []);
      match
          smaller [] restRanges
            whnf
            defeq
            child
            state1
            openedBody
            inferOnly with
      | Except.error error =>
          Except.error error
      | Except.ok bodyResult =>
          let bodyType :=
            psKernelExprCheapBetaReduce
              (Prod.fst bodyResult);
          let closedBody :=
            psKernelExprAbstractFVars
              bodyType
              (List.cons
                fresh
                List.nil);
          let result :=
            PsKernelExpr.forallE
              name
              domain
              closedBody
              binderInfo;
          Except.ok
            (Prod.mk
              result
              (psKernelCacheInferResult
                (Prod.snd bodyResult)
                inferOnly
                expr
                result))

/-- The original dependent Π-formation rule. In particular, child body
    checking happens under a fresh source local context, and the sort is
    built with Lean-compatible imax instead of a guessed successor level. -/
def psKernelInferForallHead
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo)
    (inferOnly : Bool)
    (currentBinderRanges : List Nat) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .forallE name domain body binderInfo
  match
      smaller [] []
        whnf
        defeq
        nextContext
        state
        domain
        inferOnly with
  | Except.error error =>
      Except.error error
  | Except.ok domainResult =>
      match
          psKernelEnsureSortWith
            whnf
            nextContext
            (Prod.snd domainResult)
            (Prod.fst domainResult) with
      | Except.error error =>
          Except.error error
      | Except.ok domainSort =>
          let freshResult :=
            psKernelCheckerStateFreshName
              (Prod.snd domainSort)
              name;
          let fresh :=
            Prod.fst freshResult;
          let state1 :=
            Prod.snd freshResult;
          let childLocal :=
            psKernelLocalContextAddLocal
              nextContext.localContext
              fresh
              name
              domain
              binderInfo;
          let child :=
            psKernelCheckerContextWithLocalContext
              nextContext
              childLocal;
          let (openedBody, restRanges) :=
            match currentBinderRanges with
            | range :: tail =>
                if range == 0 then (body, tail)
                else (psKernelExprInstantiate1 body
                  (PsKernelExpr.fvar fresh), [])
            | [] => (psKernelExprInstantiate1 body
                (PsKernelExpr.fvar fresh), []);
          match
              smaller [] restRanges
                whnf
                defeq
                child
                state1
                openedBody
                inferOnly with
          | Except.error error =>
              Except.error error
          | Except.ok bodyResult =>
              match
                  psKernelEnsureSortWith
                    whnf
                    child
                    (Prod.snd bodyResult)
                    (Prod.fst bodyResult) with
              | Except.error error =>
                  Except.error error
              | Except.ok bodySort =>
                  let result :=
                    PsKernelExpr.sort
                      (psKernelLevelMkIMax
                        (Prod.fst domainSort)
                        (Prod.fst bodySort));
                  Except.ok
                    (Prod.mk
                      result
                      (psKernelCacheInferResult
                        (Prod.snd bodySort)
                        inferOnly
                        expr
                        result))
