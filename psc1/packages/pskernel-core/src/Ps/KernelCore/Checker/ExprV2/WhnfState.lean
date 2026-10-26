import Ps.KernelCore.Core.ExprV2.Equality
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
structure PsKernelExprV2WhnfCacheEntry where
  source : Nat
  result : Nat
  hash : Nat

structure PsKernelExprV2WhnfState where
  arena : PsKernelExprV2PagedArena
  coreCache : List PsKernelExprV2WhnfCacheEntry
  publicCache : List PsKernelExprV2WhnfCacheEntry
  declarations : List PsKernelExprV2DeclarationRef

def psKernelExprV2WhnfStateEmpty
    (arena : PsKernelExprV2PagedArena) : PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena List.nil List.nil List.nil

def psKernelExprV2WhnfStateForDeclarations
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) : PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena List.nil List.nil declarations

def psKernelExprV2WhnfStateWithArena
    (state : PsKernelExprV2WhnfState) (arena : PsKernelExprV2PagedArena) :
    PsKernelExprV2WhnfState :=
  PsKernelExprV2WhnfState.mk arena state.coreCache state.publicCache state.declarations

def psKernelExprV2WhnfCacheFindWorker
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    Except String (Option Nat) :=
  match entries with
  | List.nil => Except.ok Option.none
  | List.cons first rest =>
      if Nat.beq first.hash hash then
        match psKernelExprV2PagedEqOnCanonical arena first.source source with
        | Except.error error => Except.error error
        | Except.ok equal =>
            if equal then Except.ok (Option.some first.result)
            else psKernelExprV2WhnfCacheFindWorker rest arena source hash
      else psKernelExprV2WhnfCacheFindWorker rest arena source hash

/- Scan at most four ordered entries per recursive call. The structural
   scheduler follows one direct tail, independently of the four consumed
   entries, so the portable compiler needs no nested-subterm recursion rule.
   The original worker is the exact fallback when any internal scheduler is
   exhausted. The public wrapper seeds it with the entries themselves: there
   is no upfront length pass, copied list, checker-fuel change or new cache.
   All-input equality includes every arbitrary scheduler, error and order. -/
def psKernelExprV2WhnfCacheScanFour
    (scheduler entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    Except String (Option Nat) :=
  match scheduler with
  | List.nil => psKernelExprV2WhnfCacheFindWorker entries arena source hash
  | List.cons _ rest =>
      match entries with
      | List.nil => Except.ok Option.none
      | List.cons first0 rest0 =>
          if Nat.beq first0.hash hash then
            match psKernelExprV2PagedEqOnCanonical arena first0.source source with
            | Except.error error => Except.error error
            | Except.ok equal =>
                if equal then Except.ok (Option.some first0.result)
                else
                  match rest0 with
                  | List.nil => Except.ok Option.none
                  | List.cons first1 rest1 =>
                      if Nat.beq first1.hash hash then
                        match psKernelExprV2PagedEqOnCanonical arena first1.source source with
                        | Except.error error => Except.error error
                        | Except.ok equal =>
                            if equal then Except.ok (Option.some first1.result)
                            else
                              match rest1 with
                              | List.nil => Except.ok Option.none
                              | List.cons first2 rest2 =>
                                  if Nat.beq first2.hash hash then
                                    match psKernelExprV2PagedEqOnCanonical arena first2.source source with
                                    | Except.error error => Except.error error
                                    | Except.ok equal =>
                                        if equal then Except.ok (Option.some first2.result)
                                        else
                                          match rest2 with
                                          | List.nil => Except.ok Option.none
                                          | List.cons first3 rest3 =>
                                              if Nat.beq first3.hash hash then
                                                match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                                | Except.error error => Except.error error
                                                | Except.ok equal =>
                                                    if equal then Except.ok (Option.some first3.result)
                                                    else
                                                      psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                              else
                                                psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                  else
                                    match rest2 with
                                    | List.nil => Except.ok Option.none
                                    | List.cons first3 rest3 =>
                                        if Nat.beq first3.hash hash then
                                          match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                          | Except.error error => Except.error error
                                          | Except.ok equal =>
                                              if equal then Except.ok (Option.some first3.result)
                                              else
                                                psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                        else
                                          psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                      else
                        match rest1 with
                        | List.nil => Except.ok Option.none
                        | List.cons first2 rest2 =>
                            if Nat.beq first2.hash hash then
                              match psKernelExprV2PagedEqOnCanonical arena first2.source source with
                              | Except.error error => Except.error error
                              | Except.ok equal =>
                                  if equal then Except.ok (Option.some first2.result)
                                  else
                                    match rest2 with
                                    | List.nil => Except.ok Option.none
                                    | List.cons first3 rest3 =>
                                        if Nat.beq first3.hash hash then
                                          match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                          | Except.error error => Except.error error
                                          | Except.ok equal =>
                                              if equal then Except.ok (Option.some first3.result)
                                              else
                                                psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                        else
                                          psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                            else
                              match rest2 with
                              | List.nil => Except.ok Option.none
                              | List.cons first3 rest3 =>
                                  if Nat.beq first3.hash hash then
                                    match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                    | Except.error error => Except.error error
                                    | Except.ok equal =>
                                        if equal then Except.ok (Option.some first3.result)
                                        else
                                          psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                  else
                                    psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
          else
            match rest0 with
            | List.nil => Except.ok Option.none
            | List.cons first1 rest1 =>
                if Nat.beq first1.hash hash then
                  match psKernelExprV2PagedEqOnCanonical arena first1.source source with
                  | Except.error error => Except.error error
                  | Except.ok equal =>
                      if equal then Except.ok (Option.some first1.result)
                      else
                        match rest1 with
                        | List.nil => Except.ok Option.none
                        | List.cons first2 rest2 =>
                            if Nat.beq first2.hash hash then
                              match psKernelExprV2PagedEqOnCanonical arena first2.source source with
                              | Except.error error => Except.error error
                              | Except.ok equal =>
                                  if equal then Except.ok (Option.some first2.result)
                                  else
                                    match rest2 with
                                    | List.nil => Except.ok Option.none
                                    | List.cons first3 rest3 =>
                                        if Nat.beq first3.hash hash then
                                          match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                          | Except.error error => Except.error error
                                          | Except.ok equal =>
                                              if equal then Except.ok (Option.some first3.result)
                                              else
                                                psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                        else
                                          psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                            else
                              match rest2 with
                              | List.nil => Except.ok Option.none
                              | List.cons first3 rest3 =>
                                  if Nat.beq first3.hash hash then
                                    match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                    | Except.error error => Except.error error
                                    | Except.ok equal =>
                                        if equal then Except.ok (Option.some first3.result)
                                        else
                                          psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                  else
                                    psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                else
                  match rest1 with
                  | List.nil => Except.ok Option.none
                  | List.cons first2 rest2 =>
                      if Nat.beq first2.hash hash then
                        match psKernelExprV2PagedEqOnCanonical arena first2.source source with
                        | Except.error error => Except.error error
                        | Except.ok equal =>
                            if equal then Except.ok (Option.some first2.result)
                            else
                              match rest2 with
                              | List.nil => Except.ok Option.none
                              | List.cons first3 rest3 =>
                                  if Nat.beq first3.hash hash then
                                    match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                                    | Except.error error => Except.error error
                                    | Except.ok equal =>
                                        if equal then Except.ok (Option.some first3.result)
                                        else
                                          psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                                  else
                                    psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                      else
                        match rest2 with
                        | List.nil => Except.ok Option.none
                        | List.cons first3 rest3 =>
                            if Nat.beq first3.hash hash then
                              match psKernelExprV2PagedEqOnCanonical arena first3.source source with
                              | Except.error error => Except.error error
                              | Except.ok equal =>
                                  if equal then Except.ok (Option.some first3.result)
                                  else
                                    psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash
                            else
                              psKernelExprV2WhnfCacheScanFour rest rest3 arena source hash

def psKernelExprV2WhnfCacheFindWorker4
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    Except String (Option Nat) :=
  psKernelExprV2WhnfCacheScanFour entries entries arena source hash

/-
Keep the existing generated curried entry point. The recursive scan receives
all arguments explicitly so it does not allocate argument closures per entry.
Candidate order, collision checks and exact failure behavior are unchanged.
-/
def psKernelExprV2WhnfCacheFindIn
    (entries : List PsKernelExprV2WhnfCacheEntry) :
    PsKernelExprV2PagedArena -> Nat -> Nat -> Except String (Option Nat) :=
  match entries with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_source _hash : Nat) =>
        Except.ok Option.none
  | List.cons _ _ =>
      fun (arena : PsKernelExprV2PagedArena) (source hash : Nat) =>
        psKernelExprV2WhnfCacheFindWorker4 entries arena source hash

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
              state.publicCache state.declarations)
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
                state.publicCache)
              state.declarations)
            result)
