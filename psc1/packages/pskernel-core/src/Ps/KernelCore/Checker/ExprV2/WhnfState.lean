import Ps.KernelCore.Core.ExprV2.Equality

/-
WHNF memo state is created empty for one public operation. Every key and value
belongs to its owning canonical arena and to an append-only continuation of
that arena. No caller-provided cache is accepted at the public DAG boundary.
The checker context is unchanged except for recursion depth in this fragment.

The disjoint core/public caches store successful results only. Hashes filter
candidates; same-arena identity or collision-safe structural comparison decides
a hit. Free-variable-containing sources never enter either semantic cache.
-/
structure PsKernelExprV2WhnfCacheEntry where
  source : Nat
  result : Nat
  hash : Nat

structure PsKernelExprV2WhnfState where
  arena : PsKernelExprV2PagedArena
  coreCache : List PsKernelExprV2WhnfCacheEntry
  publicCache : List PsKernelExprV2WhnfCacheEntry

def psKernelExprV2WhnfStateEmpty
    (arena : PsKernelExprV2PagedArena) : PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena List.nil List.nil

def psKernelExprV2WhnfStateWithArena
    (state : PsKernelExprV2WhnfState) (arena : PsKernelExprV2PagedArena) :
    PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena state.coreCache state.publicCache

def psKernelExprV2WhnfCacheFindIn
    (entries : List PsKernelExprV2WhnfCacheEntry) :
    PsKernelExprV2PagedArena -> Nat -> Nat -> Except String (Option Nat) :=
  match entries with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_source _hash : Nat) =>
        Except.ok Option.none
  | List.cons first rest =>
      let smaller :=
        fun (nextArena : PsKernelExprV2PagedArena) (nextSource nextHash : Nat) =>
          let recur := psKernelExprV2WhnfCacheFindIn rest;
          recur nextArena nextSource nextHash;
      fun (arena : PsKernelExprV2PagedArena) (source hash : Nat) =>
        if Nat.beq first.hash hash then
          match psKernelExprV2PagedEqOnCanonical arena first.source source with
          | Except.error error => Except.error error
          | Except.ok equal =>
              if equal then Except.ok (Option.some first.result)
              else smaller arena source hash
        else smaller arena source hash

def psKernelExprV2WhnfCacheFind
    (state : PsKernelExprV2WhnfState) (source : Nat)
    (entry : PsKernelExprV2Entry) : Except String (Option Nat) :=
  if entry.hasFVar then Except.ok Option.none
  else psKernelExprV2WhnfCacheFindIn state.coreCache state.arena source entry.hash

def psKernelExprV2WhnfCoreFinish
    (state : PsKernelExprV2WhnfState) (source result : Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  match psKernelExprV2PagedRequire state.arena source with
  | Except.error error => Except.error error
  | Except.ok entry =>
      if entry.hasFVar then Except.ok (Prod.mk state result)
      else
        Except.ok
          (Prod.mk
            (PsKernelExprV2WhnfState.mk state.arena
              (List.cons
                (PsKernelExprV2WhnfCacheEntry.mk source result entry.hash)
                state.coreCache)
              state.publicCache)
            result)

def psKernelExprV2WhnfPublicCacheFind
    (state : PsKernelExprV2WhnfState) (source : Nat)
    (entry : PsKernelExprV2Entry) : Except String (Option Nat) :=
  if entry.hasFVar then Except.ok Option.none
  else psKernelExprV2WhnfCacheFindIn state.publicCache state.arena source entry.hash

def psKernelExprV2WhnfPublicFinish
    (state : PsKernelExprV2WhnfState) (source result : Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  match psKernelExprV2PagedRequire state.arena source with
  | Except.error error => Except.error error
  | Except.ok entry =>
      if entry.hasFVar then Except.ok (Prod.mk state result)
      else
        Except.ok
          (Prod.mk
            (PsKernelExprV2WhnfState.mk state.arena state.coreCache
              (List.cons
                (PsKernelExprV2WhnfCacheEntry.mk source result entry.hash)
                state.publicCache))
            result)
