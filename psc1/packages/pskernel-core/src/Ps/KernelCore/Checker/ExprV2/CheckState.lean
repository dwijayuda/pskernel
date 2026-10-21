import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Checker.ExprV2.DefEqPair

/-
Inference owns its arena, typed local context, fresh counter and separate caches
for fully checked and inference-only judgments.
Local types and optional let values are IDs in the same canonical append-only
arena; no legacy local type is imported during binder traversal.

The reduction state is the existing WHNF state, not a second cache engine.
Inference keys use the same collision-safe lookup and the original checked
cache eligibility policy. The success-pair cache shares this operation and is restored on scope exit.
No cache is accepted from an untrusted public caller.
-/
structure PsKernelExprV2CheckLocal where
  name : PsKernelName
  userName : PsKernelName
  type : Nat
  binderInfo : PsKernelBinderInfo
  value : Option Nat

structure PsKernelExprV2CheckContext where
  scalar : PsKernelCheckerContext
  locals : List PsKernelExprV2CheckLocal

structure PsKernelExprV2CheckState where
  whnf : PsKernelExprV2WhnfState
  nextFresh : Nat
  checkedInfer : List PsKernelExprV2WhnfCacheEntry
  success : List PsKernelExprV2DefEqPair
  inferOnly : List PsKernelExprV2WhnfCacheEntry

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

def psKernelExprV2CheckContextWithLocalValue
    (context : PsKernelExprV2CheckContext)
    (name userName : PsKernelName) (type : Nat) (binderInfo : PsKernelBinderInfo)
    (value : Option Nat) : PsKernelExprV2CheckContext :=
  PsKernelExprV2CheckContext.mk context.scalar
    (List.cons
      (PsKernelExprV2CheckLocal.mk name userName type binderInfo value)
      context.locals)

def psKernelExprV2CheckContextWithLocal
    (context : PsKernelExprV2CheckContext)
    (name userName : PsKernelName) (type : Nat) (binderInfo : PsKernelBinderInfo) :
    PsKernelExprV2CheckContext :=
  psKernelExprV2CheckContextWithLocalValue
    context name userName type binderInfo Option.none

def psKernelExprV2CheckContextWithLet
    (context : PsKernelExprV2CheckContext)
    (name userName : PsKernelName) (type value : Nat) : PsKernelExprV2CheckContext :=
  psKernelExprV2CheckContextWithLocalValue
    context name userName type PsKernelBinderInfo.default (Option.some value)

def psKernelExprV2CheckLocalValue
    (context : PsKernelExprV2CheckContext) (name : PsKernelName) : Option Nat :=
  match psKernelExprV2CheckLocalFind context.locals name with
  | Option.none => Option.none
  | Option.some declaration => declaration.value

def psKernelExprV2CheckStateEmpty
    (arena : PsKernelExprV2PagedArena) : PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk (psKernelExprV2WhnfStateEmpty arena) 0 List.nil List.nil List.nil

def psKernelExprV2CheckStateWithWhnf
    (state : PsKernelExprV2CheckState) (whnf : PsKernelExprV2WhnfState) :
    PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk whnf state.nextFresh state.checkedInfer state.success state.inferOnly

def psKernelExprV2CheckStateWithArena
    (state : PsKernelExprV2CheckState) (arena : PsKernelExprV2PagedArena) :
    PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf state
    (psKernelExprV2WhnfStateWithArena state.whnf arena)

def psKernelExprV2CheckStateWithSuccess
    (state : PsKernelExprV2CheckState)
    (success : List PsKernelExprV2DefEqPair) : PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk state.whnf state.nextFresh state.checkedInfer success state.inferOnly

def psKernelExprV2CheckStateDefEqFinish
    (state : PsKernelExprV2CheckState) (left right : Nat) (equal : Bool) :
    Except String (Prod PsKernelExprV2CheckState Bool) :=
  if equal then
    match psKernelExprV2PagedRequire state.whnf.arena left with
    | Except.error error => Except.error error
    | Except.ok leftEntry =>
        match psKernelExprV2PagedRequire state.whnf.arena right with
        | Except.error error => Except.error error
        | Except.ok rightEntry =>
            if leftEntry.hasFVar then Except.ok (Prod.mk state true)
            else
              if rightEntry.hasFVar then Except.ok (Prod.mk state true)
              else
                let hash := Nat.mod
                  (Nat.add leftEntry.hash rightEntry.hash) psKernelCacheHashModulus;
                match psKernelExprV2DefEqPairFindIn
                    state.success state.whnf.arena left right hash with
                | Except.error error => Except.error error
                | Except.ok cached =>
                    if cached then Except.ok (Prod.mk state true)
                    else
                      Except.ok
                        (Prod.mk
                          (psKernelExprV2CheckStateWithSuccess state
                            (List.cons
                              (PsKernelExprV2DefEqPair.mk left right hash)
                              state.success))
                          true)
  else Except.ok (Prod.mk state false)

def psKernelExprV2CheckStateFreshName
    (state : PsKernelExprV2CheckState) (base : PsKernelName) :
    Prod PsKernelName PsKernelExprV2CheckState :=
  Prod.mk
    (PsKernelName.num base state.nextFresh)
    (PsKernelExprV2CheckState.mk state.whnf (Nat.succ state.nextFresh)
      state.checkedInfer state.success state.inferOnly)

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
    parent.checkedInfer parent.success parent.inferOnly

def psKernelExprV2CheckStateWithInferOnly
    (state : PsKernelExprV2CheckState)
    (cache : List PsKernelExprV2WhnfCacheEntry) : PsKernelExprV2CheckState :=
  PsKernelExprV2CheckState.mk state.whnf state.nextFresh
    state.checkedInfer state.success cache

def psKernelExprV2InferenceCacheEligible
    (inferOnly : Bool) (entry : PsKernelExprV2Entry) : Bool :=
  if entry.hasFVar then false
  else
    match entry.node with
    | PsKernelExprV2Node.lit _ => false
    | PsKernelExprV2Node.app _ _ => inferOnly
    | PsKernelExprV2Node.lam _ _ _ _ => inferOnly
    | PsKernelExprV2Node.forallE _ _ _ _ => inferOnly
    | _ => true

def psKernelExprV2InferenceFind
    (state : PsKernelExprV2CheckState) (inferOnly : Bool)
    (source : Nat) (entry : PsKernelExprV2Entry) :
    Except String (Option Nat) :=
  if psKernelExprV2InferenceCacheEligible inferOnly entry then
    let cache := if inferOnly then state.inferOnly else state.checkedInfer;
    psKernelExprV2WhnfCacheFindIn cache state.whnf.arena source entry.hash
  else Except.ok Option.none

def psKernelExprV2InferenceFinish
    (state : PsKernelExprV2CheckState) (inferOnly : Bool)
    (source result : Nat) : Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2PagedRequire state.whnf.arena source with
  | Except.error error => Except.error error
  | Except.ok entry =>
      if psKernelExprV2InferenceCacheEligible inferOnly entry then
        let cached := PsKernelExprV2WhnfCacheEntry.mk source result entry.hash;
        let next :=
          if inferOnly then
            psKernelExprV2CheckStateWithInferOnly state
              (List.cons cached state.inferOnly)
          else
            PsKernelExprV2CheckState.mk state.whnf state.nextFresh
              (List.cons cached state.checkedInfer) state.success state.inferOnly;
        Except.ok (Prod.mk next result)
      else Except.ok (Prod.mk state result)

/- Construction does not publish a judgment. The owning inference entry
   publishes exactly once, in the cache selected by its explicit mode. -/
def psKernelExprV2InferenceBuilt
    (state : PsKernelExprV2CheckState)
    (built : Except String (Prod PsKernelExprV2PagedArena Nat)) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match built with
  | Except.error error => Except.error error
  | Except.ok result =>
      Except.ok
        (Prod.mk
          (psKernelExprV2CheckStateWithArena state (Prod.fst result))
          (Prod.snd result))

def psKernelExprV2InferenceFinishAttempt
    (inferOnly : Bool) (source : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Nat))) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok inferred =>
          Option.some
            (psKernelExprV2InferenceFinish
              (Prod.fst inferred) inferOnly source (Prod.snd inferred))

def psKernelExprV2CheckedInferEligible
    (entry : PsKernelExprV2Entry) : Bool :=
  psKernelExprV2InferenceCacheEligible false entry

def psKernelExprV2CheckedInferFind
    (state : PsKernelExprV2CheckState) (source : Nat)
    (entry : PsKernelExprV2Entry) : Except String (Option Nat) :=
  psKernelExprV2InferenceFind state false source entry

def psKernelExprV2CheckedInferFinish
    (state : PsKernelExprV2CheckState) (source result : Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  psKernelExprV2InferenceFinish state false source result

def psKernelExprV2CheckedInferBuilt
    (state : PsKernelExprV2CheckState) (source : Nat)
    (built : Except String (Prod PsKernelExprV2PagedArena Nat)) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelExprV2InferenceBuilt state built with
  | Except.error error => Except.error error
  | Except.ok result =>
      psKernelExprV2InferenceFinish (Prod.fst result) false source (Prod.snd result)
