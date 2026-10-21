import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Checker.Context

/-
Checked inference owns its arena, typed local context, fresh counter and caches.
Only value-free locals are introduced here. Types are IDs in the same canonical
append-only arena; no legacy local type is imported during binder traversal.

The reduction state is the existing WHNF state, not a second cache engine.
Inference keys use the same collision-safe lookup and the original checked
cache eligibility policy. No cache is accepted from an untrusted public caller.
-/
structure PsKernelExprV2CheckLocal where
  name : PsKernelName
  userName : PsKernelName
  type : Nat
  binderInfo : PsKernelBinderInfo

structure PsKernelExprV2CheckContext where
  scalar : PsKernelCheckerContext
  locals : List PsKernelExprV2CheckLocal

structure PsKernelExprV2CheckState where
  whnf : PsKernelExprV2WhnfState
  nextFresh : Nat
  checkedInfer : List PsKernelExprV2WhnfCacheEntry

def psKernelExprV2CheckContextEmpty
    (context : PsKernelCheckerContext) : PsKernelExprV2CheckContext :=
  PsKernelExprV2CheckContext.mk context List.nil

def psKernelExprV2CheckContextEnterRecDepth
    (context : PsKernelExprV2CheckContext) :
    Except String PsKernelExprV2CheckContext :=
  match psKernelCheckerContextEnterRecDepth context.scalar with
  | Except.error error => Except.error error
  | Except.ok entered =>
      Except.ok (PsKernelExprV2CheckContext.mk entered context.locals)

def psKernelExprV2CheckLocalFind
    (locals : List PsKernelExprV2CheckLocal)
    (name : PsKernelName) : Option PsKernelExprV2CheckLocal :=
  match locals with
  | List.nil => Option.none
  | List.cons first rest =>
      if psKernelNameEq first.name name then Option.some first
      else psKernelExprV2CheckLocalFind rest name

def psKernelExprV2CheckContextWithLocal
    (context : PsKernelExprV2CheckContext)
    (name userName : PsKernelName) (type : Nat) (binderInfo : PsKernelBinderInfo) :
    PsKernelExprV2CheckContext :=
  PsKernelExprV2CheckContext.mk context.scalar
    (List.cons
      (PsKernelExprV2CheckLocal.mk name userName type binderInfo)
      context.locals)

def psKernelExprV2CheckStateEmpty
    (arena : PsKernelExprV2PagedArena) : PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk (psKernelExprV2WhnfStateEmpty arena) 0 List.nil

def psKernelExprV2CheckStateWithWhnf
    (state : PsKernelExprV2CheckState) (whnf : PsKernelExprV2WhnfState) :
    PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk whnf state.nextFresh state.checkedInfer

def psKernelExprV2CheckStateWithArena
    (state : PsKernelExprV2CheckState) (arena : PsKernelExprV2PagedArena) :
    PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf state
    (psKernelExprV2WhnfStateWithArena state.whnf arena)

def psKernelExprV2CheckStateFreshName
    (state : PsKernelExprV2CheckState) (base : PsKernelName) :
    Prod PsKernelName PsKernelExprV2CheckState :=
  Prod.mk
    (PsKernelName.num base state.nextFresh)
    (PsKernelExprV2CheckState.mk state.whnf (Nat.succ state.nextFresh)
      state.checkedInfer)

/-
The child arena is retained because returned type IDs may name appended nodes.
All semantic caches are restored to the pre-child state, including both WHNF
caches. Only the globally monotone fresh counter survives the local scope.
-/
def psKernelExprV2CheckStateExitLocalScope
    (parent child : PsKernelExprV2CheckState) : PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk
    (psKernelExprV2WhnfStateWithArena parent.whnf child.whnf.arena)
    (psKernelStateNatMax parent.nextFresh child.nextFresh)
    parent.checkedInfer

def psKernelExprV2CheckedInferEligible
    (entry : PsKernelExprV2Entry) : Bool :=
  if entry.hasFVar then false
  else
    match entry.node with
    | PsKernelExprV2Node.lit _ => false
    | PsKernelExprV2Node.app _ _ => false
    | PsKernelExprV2Node.lam _ _ _ _ => false
    | PsKernelExprV2Node.forallE _ _ _ _ => false
    | _ => true

def psKernelExprV2CheckedInferFind
    (state : PsKernelExprV2CheckState) (source : Nat)
    (entry : PsKernelExprV2Entry) : Except String (Option Nat) :=
  if psKernelExprV2CheckedInferEligible entry then
    psKernelExprV2WhnfCacheFindIn
      state.checkedInfer state.whnf.arena source entry.hash
  else Except.ok Option.none

def psKernelExprV2CheckedInferFinish
    (state : PsKernelExprV2CheckState) (source result : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2PagedRequire state.whnf.arena source with
  | Except.error error => Except.error error
  | Except.ok entry =>
      if psKernelExprV2CheckedInferEligible entry then
        Except.ok
          (Prod.mk
            (PsKernelExprV2CheckState.mk state.whnf state.nextFresh
              (List.cons
                (PsKernelExprV2WhnfCacheEntry.mk source result entry.hash)
                state.checkedInfer))
            result)
      else Except.ok (Prod.mk state result)

def psKernelExprV2CheckedInferBuilt
    (state : PsKernelExprV2CheckState) (source : Nat)
    (built : Except String (Prod PsKernelExprV2PagedArena Nat)) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match built with
  | Except.error error => Except.error error
  | Except.ok result =>
      psKernelExprV2CheckedInferFinish
        (psKernelExprV2CheckStateWithArena state (Prod.fst result))
        source (Prod.snd result)
