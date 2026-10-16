import Ps.KernelCore.Checker.Inference.App

/-!
Extracted exact dependent-let inference source rule.

Pinned Lean 4.35 type_checker.cpp::infer_let checks the declared type,
checks the value against it, introduces a fresh typed local, recursively
checks the opened body, cheap-beta reduces and abstracts the result.
C0 additionally owns its exact checked/infer-only caches, source recursion
budget, eager DefEq policy, and optional immutable let-frame acceleration.

This module is a mechanically factored piece of C0 source inference:
no new theorem or proof-admission authority follows from extraction alone.
The externally passed smaller/WHNF/DefEq callbacks remain exactly the
source-owned checked evaluator during source inference.
-/

/-- The exact immutable source let-frame selection used by both ordinary
    inference and qualified let heads. It does not inspect or modify a
    trusted checker cache. -/
def psKernelInferCurrentLetFrames {α : Type}
    (expr : PsKernelExpr)
    (onCheckedApp : Option α)
    (letFrames : List (Nat × Nat)) : List (Nat × Nat) :=
  match expr, onCheckedApp with
  | .letE _ _ _ _ _, some _ =>
      match letFrames with
      | [] =>
          if psKernelC0HasLetPrefix 12 expr then
            match psKernelC0LetCacheFramesWithFuel 1024 expr with
            | some (_, _, frames) => frames
            | none => []
          else []
      | _ => letFrames
  | _, _ => []

/-!
Every non-let term has definitionally empty immutable let frames. These
source equations preserve the original cache-hash key and allow the
preexisting scalar, local, constant and metadata refinement proofs to
normalize after extraction, without changing evaluation behavior.
-/

@[simp] theorem psKernelInferCurrentLetFrames_sort {α : Type}
    (u : PsKernelLevel) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.sort u) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_lit {α : Type}
    (literal : PsKernelLiteral) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.lit literal) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_fvar {α : Type}
    (name : PsKernelName) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.fvar name) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_const {α : Type}
    (name : PsKernelName) (levels : List PsKernelLevel) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.const name levels) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_app {α : Type}
    (fn arg : PsKernelExpr) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.app fn arg) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_lam {α : Type}
    (name : PsKernelName) (domain body : PsKernelExpr) (info : PsKernelBinderInfo) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.lam name domain body info) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_pi {α : Type}
    (name : PsKernelName) (domain body : PsKernelExpr) (info : PsKernelBinderInfo) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.forallE name domain body info) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_mdata {α : Type}
    (tag : Nat) (body : PsKernelExpr) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.mdata tag body) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_bvar {α : Type}
    (idx : Nat) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.bvar idx) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_mvar {α : Type}
    (name : PsKernelName) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.mvar name) hook frames = [] := rfl

@[simp] theorem psKernelInferCurrentLetFrames_proj {α : Type}
    (name : PsKernelName) (index : Nat) (expr : PsKernelExpr) (hook : Option α) (frames : List (Nat × Nat)) :
    psKernelInferCurrentLetFrames (.proj name index expr) hook frames = [] := rfl

/-- Original source let-type and value checking with exact error precedence,
    local context ownership, opened-body inference, and result hash cache. -/
def psKernelInferLetHead
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep : Bool)
    (inferOnly : Bool)
    (currentFrames : List (Nat × Nat))
    (currentHash : Option Nat) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .letE name type value body nondep
  let checked :=
    if inferOnly then
      Except.ok
        (Prod.mk
          type
          state)
    else
      match
          smaller [] []
            whnf
            defeq
            nextContext
            state
            type
            false with
      | Except.error error =>
          Except.error error
      | Except.ok typeResult =>
          match
              psKernelEnsureSortWith
                whnf
                nextContext
                (Prod.snd typeResult)
                (Prod.fst typeResult) with
          | Except.error error =>
              Except.error error
          | Except.ok typeSort =>
              match
                  smaller [] []
                    whnf
                    defeq
                    nextContext
                    (Prod.snd typeSort)
                    value
                    false with
              | Except.error error =>
                  Except.error error
              | Except.ok valueResult =>
                  match
                      defeq
                        nextContext
                        (Prod.snd valueResult)
                        (Prod.fst valueResult)
                        type with
                  | Except.error error =>
                      Except.error error
                  | Except.ok eqResult =>
                      if Prod.fst eqResult then
                        Except.ok
                          (Prod.mk
                            type
                            (Prod.snd eqResult))
                      else
                        Except.error
                          "let value type mismatch";
  match checked with
  | Except.error error =>
      Except.error error
  | Except.ok checkedResult =>
      let freshResult :=
        psKernelCheckerStateFreshName
          (Prod.snd checkedResult)
          name;
      let fresh :=
        Prod.fst freshResult;
      let state1 :=
        Prod.snd freshResult;
      let childLocal :=
        psKernelLocalContextAddLet
          nextContext.localContext
          fresh
          name
          type
          value;
      let child :=
        psKernelCheckerContextWithLocalContext
          nextContext
          childLocal;
      let (openedBody, remainingFrames) :=
        match currentFrames with
        | (range, _) :: tail =>
            if range == 0 then (body, tail)
            else
              (psKernelExprInstantiate1 body
                (PsKernelExpr.fvar fresh), [])
        | [] =>
            (psKernelExprInstantiate1 body
              (PsKernelExpr.fvar fresh), []);
      match
          smaller remainingFrames []
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
            if
                psKernelExprHasLooseBVarAt
                  closedBody
                  0 then
              PsKernelExpr.letE
                name
                type
                value
                closedBody
                nondep
            else
              bodyType;
          Except.ok
            (Prod.mk
              result
              (psKernelCacheInferResultWithKnownHash
                (psKernelCheckerStateExitLocalScope
                  state1 (Prod.snd bodyResult))
                inferOnly
                expr
                result
                currentHash))
