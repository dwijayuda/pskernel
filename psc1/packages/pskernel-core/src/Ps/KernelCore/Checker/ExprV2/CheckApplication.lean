import Ps.KernelCore.Checker.ExprV2.CheckHelpers

/-
Checked application preserves the original syntactic-equality fast path.
The function and argument use predecessor inference fuel. Exposing its function
type uses the same top-level WHNF callback as the rest of checked inference.

Only the original structural-equality branch is executed here. An unequal pair
requests the complete checker, because universe conversion, proof irrelevance
or other definitional-equality rules may still accept it. This branch never
creates or consults a DefEq judgment cache.
-/
structure PsKernelExprV2CheckedForallView where
  name : PsKernelName
  domain : Nat
  body : Nat
  binderInfo : PsKernelBinderInfo

def psKernelExprV2CheckReadForall
    (state : PsKernelExprV2CheckState) (type : Nat) :
    Except String (Prod PsKernelExprV2CheckState PsKernelExprV2CheckedForallView) :=
  match psKernelExprV2PagedRequire state.whnf.arena type with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.forallE name domain body binderInfo =>
          Except.ok
            (Prod.mk state
              (PsKernelExprV2CheckedForallView.mk name domain body binderInfo))
      | _ => Except.error "expected function type"

def psKernelExprV2CheckEnsureForallWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (type : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelExprV2CheckedForallView)) :=
  match psKernelExprV2PagedRequire state.whnf.arena type with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.forallE name domain body binderInfo =>
          Option.some
            (Except.ok
              (Prod.mk state
                (PsKernelExprV2CheckedForallView.mk name domain body binderInfo)))
      | _ =>
          match whnf context state.whnf type with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  Option.some
                    (psKernelExprV2CheckReadForall
                      (psKernelExprV2CheckStateWithWhnf state (Prod.fst reduced))
                      (Prod.snd reduced))

def psKernelExprV2CheckApplicationWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root fn arg : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match check context state fn with
  | Option.none => Option.none
  | Option.some attemptedFn =>
      match attemptedFn with
      | Except.error error => Option.some (Except.error error)
      | Except.ok fnResult =>
          match psKernelExprV2CheckEnsureForallWith
              whnf context (Prod.fst fnResult) (Prod.snd fnResult) with
          | Option.none => Option.none
          | Option.some attemptedForall =>
              match attemptedForall with
              | Except.error error => Option.some (Except.error error)
              | Except.ok forallResult =>
                  let view := Prod.snd forallResult;
                  match check context (Prod.fst forallResult) arg with
                  | Option.none => Option.none
                  | Option.some attemptedArg =>
                      match attemptedArg with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok argResult =>
                          let next := Prod.fst argResult;
                          match psKernelExprV2PagedEqOnCanonical
                              next.whnf.arena (Prod.snd argResult) view.domain with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok equal =>
                              if equal then
                                Option.some
                                  (psKernelExprV2CheckedInferBuilt next root
                                    (psKernelExprV2TransformOnCanonical
                                      (PsKernelExprV2Transform.instantiate 0
                                        (List.cons arg List.nil))
                                      next.whnf.arena view.body 0))
                              else Option.none
