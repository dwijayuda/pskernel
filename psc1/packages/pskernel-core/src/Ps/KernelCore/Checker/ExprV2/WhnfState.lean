import Ps.KernelCore.Checker.ExprV2.WhnfCache
import Ps.KernelCore.Checker.ExprV2.Environment

/-
WHNF memo state is created empty for one public operation. Every key and value
belongs to its owning canonical arena and to an append-only continuation of
that arena. No caller-provided cache is accepted at the public DAG boundary.
The checker context is unchanged except for recursion depth in this fragment.

The disjoint core/public caches store successful results only. Hashes filter
candidates; same-arena identity or collision-safe structural comparison decides
a hit. Free-variable-containing sources never enter either semantic cache.
-/
structure PsKernelExprV2WhnfState where
  arena : PsKernelExprV2PagedArena
  coreCache : PsKernelExprV2WhnfCache
  publicCache : PsKernelExprV2WhnfCache
  declarations : List PsKernelExprV2DeclarationRef

def psKernelExprV2WhnfStateEmpty
    (arena : PsKernelExprV2PagedArena) : PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena
    psKernelExprV2WhnfCacheEmpty psKernelExprV2WhnfCacheEmpty List.nil

def psKernelExprV2WhnfStateForDeclarations
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) : PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena
    psKernelExprV2WhnfCacheEmpty psKernelExprV2WhnfCacheEmpty declarations

def psKernelExprV2WhnfStateWithArena
    (state : PsKernelExprV2WhnfState) (arena : PsKernelExprV2PagedArena) :
    PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena state.coreCache state.publicCache state.declarations

def psKernelExprV2WhnfCacheFind
    (state : PsKernelExprV2WhnfState) (source : Nat)
    (entry : PsKernelExprV2Entry) : Except String (Option Nat) :=
  if entry.hasFVar then Except.ok Option.none
  else psKernelExprV2WhnfCacheLookup state.coreCache state.arena source entry.hash

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
              (psKernelExprV2WhnfCacheInsert state.coreCache
                (PsKernelExprV2WhnfCacheEntry.mk source result entry.hash))
              state.publicCache state.declarations)
            result)

def psKernelExprV2WhnfPublicCacheFind
    (state : PsKernelExprV2WhnfState) (source : Nat)
    (entry : PsKernelExprV2Entry) : Except String (Option Nat) :=
  if entry.hasFVar then Except.ok Option.none
  else psKernelExprV2WhnfCacheLookup state.publicCache state.arena source entry.hash

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
              (psKernelExprV2WhnfCacheInsert state.publicCache
                (PsKernelExprV2WhnfCacheEntry.mk source result entry.hash))
              state.declarations)
            result)
