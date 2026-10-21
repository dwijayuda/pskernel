import Ps.KernelCore.Checker.ExprV2.CheckHelpers

/-
Checked application preserves the original syntactic-equality fast path.
The function and argument use predecessor inference fuel. Exposing its function
type uses the same top-level WHNF callback as the rest of checked inference.

A structurally unequal argument type uses the same operation-owned DefEq state
and fixed top-level comparison budget. The original eager-reduction marker is
read from the raw argument shape. Unsupported DefEq work requests the complete
original operation; a definitive false comparison rejects the application.
The syntactic shortcut does not publish a DefEq cache entry.
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

def psKernelExprV2CheckApplicationEqContext
    (context : PsKernelExprV2CheckContext)
    (arena : PsKernelExprV2PagedArena) (arg : Nat) :
    Except String PsKernelExprV2CheckContext :=
  match psKernelExprV2PagedRequire arena arg with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.app first _ =>
          match psKernelExprV2PagedRequire arena first with
          | Except.error error => Except.error error
          | Except.ok firstEntry =>
              match firstEntry.node with
              | PsKernelExprV2Node.app head _ =>
                  match psKernelExprV2PagedRequire arena head with
                  | Except.error error => Except.error error
                  | Except.ok headEntry =>
                      match headEntry.node with
                      | PsKernelExprV2Node.const name _ =>
                          if psKernelNameEq name psKernelEagerReduceName then
                            Except.ok
                              (PsKernelExprV2CheckContext.mk
                                (psKernelCheckerContextWithEagerReduce context.scalar true)
                                context.locals)
                          else Except.ok context
                      | _ => Except.ok context
              | _ => Except.ok context
      | _ => Except.ok context

def psKernelExprV2CheckApplicationFinish
    (state : PsKernelExprV2CheckState) (_root arg body : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  psKernelExprV2InferenceBuilt state
    (psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons arg List.nil))
      state.whnf.arena body 0)

def psKernelExprV2CheckApplicationConvertWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root arg argType : Nat) (view : PsKernelExprV2CheckedForallView) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheckApplicationEqContext context state.whnf.arena arg with
  | Except.error error => Option.some (Except.error error)
  | Except.ok eqContext =>
      match defeq eqContext state argType view.domain with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result =>
              if Prod.snd result then
                Option.some
                  (psKernelExprV2CheckApplicationFinish
                    (Prod.fst result) root arg view.body)
              else Option.some (Except.error "application type mismatch")

def psKernelExprV2CheckApplicationWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
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
                                  (psKernelExprV2CheckApplicationFinish next root arg view.body)
                              else
                                psKernelExprV2CheckApplicationConvertWith defeq context next
                                  root arg (Prod.snd argResult) view
