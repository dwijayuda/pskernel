import Ps.KernelCore.Core.ExprV2.Equality

/-
Immutable operation-owned candidate indexing for the five unary DAG caches.

A cache never authorizes a judgment by a hash. The unchanged list scanner below
checks every full hash and then exact arena equality in publication order.
The radix index only removes candidates whose full hash cannot match.

The fixed 16 index levels are a representation bound, not kernel fuel. Hashes
above 65535 are also supported: routes may collide and the scanner still checks
the complete Nat hash. No caller-owned cache is admitted by the public boundary.
-/
structure PsKernelExprV2WhnfCacheEntry where
  source : Nat
  result : Nat
  hash : Nat

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
        psKernelExprV2WhnfCacheFindWorker entries arena source hash

inductive PsKernelExprV2WhnfCacheIndex where
  | empty
  | bucket (entries : List PsKernelExprV2WhnfCacheEntry)
  | branch (left right : PsKernelExprV2WhnfCacheIndex)

def psKernelExprV2WhnfCacheIndexBucket
    (levels : Nat) :
    PsKernelExprV2WhnfCacheIndex -> Nat -> List PsKernelExprV2WhnfCacheEntry :=
  match levels with
  | Nat.zero =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (_hash : Nat) =>
        match index with
        | PsKernelExprV2WhnfCacheIndex.bucket entries => entries
        | _ => List.nil
  | Nat.succ remaining =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat) =>
        match index with
        | PsKernelExprV2WhnfCacheIndex.branch left right =>
            let worker := psKernelExprV2WhnfCacheIndexBucket remaining;
            if Nat.beq (Nat.mod hash 2) 0 then worker left (Nat.div hash 2)
            else worker right (Nat.div hash 2)
        | _ => List.nil

def psKernelExprV2WhnfCacheIndexSet
    (levels : Nat) :
    PsKernelExprV2WhnfCacheIndex -> Nat -> List PsKernelExprV2WhnfCacheEntry ->
    PsKernelExprV2WhnfCacheIndex :=
  match levels with
  | Nat.zero =>
      fun (_index : PsKernelExprV2WhnfCacheIndex) (_hash : Nat)
          (entries : List PsKernelExprV2WhnfCacheEntry) =>
        PsKernelExprV2WhnfCacheIndex.bucket entries
  | Nat.succ remaining =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat)
          (entries : List PsKernelExprV2WhnfCacheEntry) =>
        let left : PsKernelExprV2WhnfCacheIndex :=
          match index with
          | PsKernelExprV2WhnfCacheIndex.branch value _ => value
          | _ => PsKernelExprV2WhnfCacheIndex.empty;
        let right : PsKernelExprV2WhnfCacheIndex :=
          match index with
          | PsKernelExprV2WhnfCacheIndex.branch _ value => value
          | _ => PsKernelExprV2WhnfCacheIndex.empty;
        let worker := psKernelExprV2WhnfCacheIndexSet remaining;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsKernelExprV2WhnfCacheIndex.branch
            (worker left (Nat.div hash 2) entries) right
        else
          PsKernelExprV2WhnfCacheIndex.branch
            left (worker right (Nat.div hash 2) entries)

def psKernelExprV2WhnfCacheIndexInsert
    (index : PsKernelExprV2WhnfCacheIndex)
    (entry : PsKernelExprV2WhnfCacheEntry) : PsKernelExprV2WhnfCacheIndex :=
  let bucket := psKernelExprV2WhnfCacheIndexBucket 16 index entry.hash;
  psKernelExprV2WhnfCacheIndexSet 16 index entry.hash (List.cons entry bucket)

def psKernelExprV2WhnfCacheIndexBuild
    (entries : List PsKernelExprV2WhnfCacheEntry) : PsKernelExprV2WhnfCacheIndex :=
  match entries with
  | List.nil => PsKernelExprV2WhnfCacheIndex.empty
  | List.cons first rest =>
      psKernelExprV2WhnfCacheIndexInsert
        (psKernelExprV2WhnfCacheIndexBuild rest) first

def psKernelExprV2WhnfCacheListLength
    (entries : List PsKernelExprV2WhnfCacheEntry) : Nat :=
  match entries with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psKernelExprV2WhnfCacheListLength rest)

structure PsKernelExprV2WhnfCache where
  small : List PsKernelExprV2WhnfCacheEntry
  index : Option PsKernelExprV2WhnfCacheIndex

def psKernelExprV2WhnfCacheEmpty : PsKernelExprV2WhnfCache :=
  PsKernelExprV2WhnfCache.mk List.nil Option.none

def psKernelExprV2WhnfCacheBucket
    (cache : PsKernelExprV2WhnfCache) (hash : Nat) :
    List PsKernelExprV2WhnfCacheEntry :=
  match cache.index with
  | Option.none => cache.small
  | Option.some index => psKernelExprV2WhnfCacheIndexBucket 16 index hash

def psKernelExprV2WhnfCacheInsert
    (cache : PsKernelExprV2WhnfCache)
    (entry : PsKernelExprV2WhnfCacheEntry) : PsKernelExprV2WhnfCache :=
  match cache.index with
  | Option.none =>
      let next := List.cons entry cache.small;
      if Nat.ble (psKernelExprV2WhnfCacheListLength next) 8 then
        PsKernelExprV2WhnfCache.mk next Option.none
      else
        PsKernelExprV2WhnfCache.mk List.nil
          (Option.some (psKernelExprV2WhnfCacheIndexBuild next))
  | Option.some index =>
      PsKernelExprV2WhnfCache.mk List.nil
        (Option.some (psKernelExprV2WhnfCacheIndexInsert index entry))

def psKernelExprV2WhnfCacheFromList
    (entries : List PsKernelExprV2WhnfCacheEntry) : PsKernelExprV2WhnfCache :=
  match entries with
  | List.nil => psKernelExprV2WhnfCacheEmpty
  | List.cons first rest =>
      psKernelExprV2WhnfCacheInsert (psKernelExprV2WhnfCacheFromList rest) first

def psKernelExprV2WhnfCacheLookup
    (cache : PsKernelExprV2WhnfCache)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    Except String (Option Nat) :=
  psKernelExprV2WhnfCacheFindWorker
    (psKernelExprV2WhnfCacheBucket cache hash) arena source hash

/-
Diagnostic enumeration only. It is never used to make a checking decision.
Within each radix bucket publication order is preserved; between different
buckets the order is the deterministic radix traversal, not publication order.
-/
def psKernelExprV2WhnfCacheEntryAppend
    (left right : List PsKernelExprV2WhnfCacheEntry) :
    List PsKernelExprV2WhnfCacheEntry :=
  match left with
  | List.nil => right
  | List.cons first rest =>
      List.cons first (psKernelExprV2WhnfCacheEntryAppend rest right)

def psKernelExprV2WhnfCacheIndexEntries
    (index : PsKernelExprV2WhnfCacheIndex) : List PsKernelExprV2WhnfCacheEntry :=
  match index with
  | PsKernelExprV2WhnfCacheIndex.empty => List.nil
  | PsKernelExprV2WhnfCacheIndex.bucket entries => entries
  | PsKernelExprV2WhnfCacheIndex.branch left right =>
      psKernelExprV2WhnfCacheEntryAppend
        (psKernelExprV2WhnfCacheIndexEntries left)
        (psKernelExprV2WhnfCacheIndexEntries right)

def psKernelExprV2WhnfCacheEntries
    (cache : PsKernelExprV2WhnfCache) : List PsKernelExprV2WhnfCacheEntry :=
  match cache.index with
  | Option.none => cache.small
  | Option.some index => psKernelExprV2WhnfCacheIndexEntries index
