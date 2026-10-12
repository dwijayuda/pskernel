import Ps.KernelCore.Core.Expr
import Ps.KernelCore.Runtime.Acceleration.Cache

inductive PsKernelLocalDecl where
  | localDecl
      (index : Nat)
      (name : PsKernelName)
      (userName : PsKernelName)
      (type : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
  | letDecl
      (index : Nat)
      (name : PsKernelName)
      (userName : PsKernelName)
      (type : PsKernelExpr)
      (value : PsKernelExpr)

def psKernelLocalDeclName
    (decl : PsKernelLocalDecl) : PsKernelName :=
  match decl with
  | PsKernelLocalDecl.localDecl _ name _ _ _ =>
      name
  | PsKernelLocalDecl.letDecl _ name _ _ _ =>
      name

def psKernelLocalDeclUserName
    (decl : PsKernelLocalDecl) : PsKernelName :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ userName _ _ =>
      userName
  | PsKernelLocalDecl.letDecl _ _ userName _ _ =>
      userName

def psKernelLocalDeclType
    (decl : PsKernelLocalDecl) : PsKernelExpr :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ _ type _ =>
      type
  | PsKernelLocalDecl.letDecl _ _ _ type _ =>
      type

def psKernelLocalDeclValue
    (decl : PsKernelLocalDecl) :
    Option PsKernelExpr :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ _ _ _ =>
      Option.none
  | PsKernelLocalDecl.letDecl _ _ _ _ value =>
      Option.some value

def psKernelLocalDeclBinderInfo
    (decl : PsKernelLocalDecl) :
    PsKernelBinderInfo :=
  match decl with
  | PsKernelLocalDecl.localDecl _ _ _ _ binderInfo =>
      binderInfo
  | PsKernelLocalDecl.letDecl _ _ _ _ _ =>
      PsKernelBinderInfo.default

structure PsKernelLocalContext where
  decls : List PsKernelLocalDecl
  nextIndex : Nat
  -- Optional persistent index. Small contexts remain list-only.
  -- The list remains the authoritative declaration order (shadowing).
  index : Option (Thunk (PsKernelC0HashTrie PsKernelLocalDecl)) := Option.none
  -- Newly bound locals after the last indexed snapshot, most recent first.
  -- Lookup checks this overlay first to preserve exact name shadowing.
  pending : List PsKernelLocalDecl := []
  pendingCount : Nat := 0

def psKernelLocalContextEmpty : PsKernelLocalContext :=
  {
    decls := List.nil
    nextIndex := 0
  }

def psKernelLocalContextFindIn
    (name : PsKernelName)
    (decls : List PsKernelLocalDecl) :
    Option PsKernelLocalDecl :=
  match decls with
  | List.nil =>
      Option.none
  | List.cons decl rest =>
      if
          psKernelNameEq
            (psKernelLocalDeclName decl)
            name then
        Option.some decl
      else
        psKernelLocalContextFindIn
          name
          rest


/-
Adaptive local-context indexing.

Short-lived binder contexts should not pay to build a radix-16 index.
Measured complete admission workloads through depth 48 were slower with
eager indexed updates; deep (512-local) repeated lookups benefit strongly.
A static binder-depth threshold alone cannot represent both one-shot
local reads and heavily reused deep contexts. Keep only cheap thunks after
depth 128; no radix nodes are materialized while bindings are added. After
depth 256, a deep lookup can force the immutable snapshot at most once per
persistent context. For moderate-depth lookups we use the authoritative
ordered list without ever forcing a snapshot.

Each group of sixteen later bindings is recorded in a newest-first pending
overlay. Snapshot publication itself is deferred as a thunk that captures
the previous immutable snapshot and a complete ordered pending batch.
Lookups check pending before the snapshot, preserving shadowing even across
previously published contexts. This avoids eager index maintenance for
one-shot deeply nested checked declarations, without sacrificing persistent
radix lookup where it can amortize construction.
No cache value is ever used as proof of well-typedness.
-/
def psKernelC0LocalIndexThreshold : Nat := 128
def psKernelC0LocalIndexBatchSize : Nat := 16
-- Index lookup is a separate performance policy from index availability.
-- Keep it outside the replaceable index-update implementation.
def psKernelC0LocalIndexLookupThreshold : Nat := 256

def psKernelC0LocalIndexInsert
    (index : PsKernelC0HashTrie PsKernelLocalDecl)
    (decl : PsKernelLocalDecl) :
    PsKernelC0HashTrie PsKernelLocalDecl :=
  let hash := psKernelCacheNameHash (psKernelLocalDeclName decl)
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth index hash
  psKernelC0TrieSet psKernelC0IndexDepth index hash (List.cons decl bucket)

def psKernelC0LocalIndexBuild
    (decls : List PsKernelLocalDecl) :
    PsKernelC0HashTrie PsKernelLocalDecl :=
  match decls with
  | List.nil => PsKernelC0HashTrie.empty
  | List.cons decl rest =>
      psKernelC0LocalIndexInsert (psKernelC0LocalIndexBuild rest) decl

/-- Commit oldest pending declaration first, so newest equal-name entries
    remain first in each exact-collision bucket. -/
def psKernelC0LocalIndexCommit
    (index : PsKernelC0HashTrie PsKernelLocalDecl)
    (pending : List PsKernelLocalDecl) :
    PsKernelC0HashTrie PsKernelLocalDecl :=
  match pending with
  | [] => index
  | decl :: rest =>
      psKernelC0LocalIndexInsert
        (psKernelC0LocalIndexCommit index rest) decl

structure PsKernelC0LocalIndexUpdate where
  index : Option (Thunk (PsKernelC0HashTrie PsKernelLocalDecl))
  pending : List PsKernelLocalDecl
  pendingCount : Nat

def psKernelC0LocalContextNextIndex
    (context : PsKernelLocalContext)
    (decl : PsKernelLocalDecl) :
    PsKernelC0LocalIndexUpdate :=
  match context.index with
  | Option.some index =>
      let pending := decl :: context.pending
      let count := context.pendingCount + 1
      if count >= psKernelC0LocalIndexBatchSize then
        { index := some (Thunk.mk (fun _ =>
            psKernelC0LocalIndexCommit index.get pending))
          pending := []
          pendingCount := 0 }
      else
        { index := some index
          pending := pending
          pendingCount := count }
  | Option.none =>
      if context.decls.length >= psKernelC0LocalIndexThreshold then
        { index := some (Thunk.mk (fun _ =>
            psKernelC0LocalIndexBuild (decl :: context.decls)))
          pending := []
          pendingCount := 0 }
      else
        { index := none
          pending := []
          pendingCount := 0 }

/-- Small/medium locals use exact ordered-list lookup. Thunk forcing is
    allowed only for sufficiently deep contexts, where repeated lookups
    amortize the construction of an immutable snapshot.

    nextIndex is a performance heuristic, NOT a semantic proof of list
    length; all branches use the exact same ordered declaration names and
    therefore preserve shadowing even if a continuation has a larger
    fresh-name counter than its local declaration count. -/
def psKernelLocalContextFind
    (context : PsKernelLocalContext)
    (name : PsKernelName) :
    Option PsKernelLocalDecl :=
  if context.nextIndex < psKernelC0LocalIndexLookupThreshold then
    psKernelLocalContextFindIn name context.decls
  else
    match context.index with
    | Option.none => psKernelLocalContextFindIn name context.decls
    | Option.some snapshot =>
        match psKernelLocalContextFindIn name context.pending with
        | Option.some decl => Option.some decl
        | Option.none =>
            psKernelLocalContextFindIn name
              (psKernelC0TrieBucket psKernelC0IndexDepth snapshot.get
                (psKernelCacheNameHash name))

def psKernelLocalContextAddLocal
    (context : PsKernelLocalContext)
    (name : PsKernelName)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    PsKernelLocalContext :=
  let decl := PsKernelLocalDecl.localDecl
    context.nextIndex name userName type binderInfo
  let update := psKernelC0LocalContextNextIndex context decl
  {
    decls := List.cons decl context.decls
    nextIndex := Nat.succ context.nextIndex
    index := update.index
    pending := update.pending
    pendingCount := update.pendingCount
  }

def psKernelLocalContextAddLet
    (context : PsKernelLocalContext)
    (name : PsKernelName)
    (userName : PsKernelName)
    (type : PsKernelExpr)
    (value : PsKernelExpr) :
    PsKernelLocalContext :=
  let decl := PsKernelLocalDecl.letDecl
    context.nextIndex name userName type value
  let update := psKernelC0LocalContextNextIndex context decl
  {
    decls := List.cons decl context.decls
    nextIndex := Nat.succ context.nextIndex
    index := update.index
    pending := update.pending
    pendingCount := update.pendingCount
  }
