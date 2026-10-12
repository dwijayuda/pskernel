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
  index : Option (PsKernelC0HashTrie PsKernelLocalDecl) := Option.none
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
Use the ordered declaration list up through depth 64, then build an immutable
indexed snapshot at the 65th binder.

Thereafter collect up to sixteen new declarations in an ordered overlay.
Lookups first inspect the overlay and then the indexed snapshot. Once full,
publish a new persistent index with all pending entries in original order.
This amortizes expensive four-level radix path copies without changing
lookup, shadowing, historical snapshots or the authoritative declaration list.
No cache value is ever used as proof of well-typedness.
-/
def psKernelC0LocalIndexThreshold : Nat := 64
def psKernelC0LocalIndexBatchSize : Nat := 16

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
  index : Option (PsKernelC0HashTrie PsKernelLocalDecl)
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
        { index := some (psKernelC0LocalIndexCommit index pending)
          pending := []
          pendingCount := 0 }
      else
        { index := some index
          pending := pending
          pendingCount := count }
  | Option.none =>
      if context.decls.length >= psKernelC0LocalIndexThreshold then
        { index := some
            (psKernelC0LocalIndexBuild (decl :: context.decls))
          pending := []
          pendingCount := 0 }
      else
        { index := none
          pending := []
          pendingCount := 0 }

def psKernelLocalContextFind
    (context : PsKernelLocalContext)
    (name : PsKernelName) :
    Option PsKernelLocalDecl :=
  match context.index with
  | Option.none => psKernelLocalContextFindIn name context.decls
  | Option.some index =>
      match psKernelLocalContextFindIn name context.pending with
      | Option.some decl => Option.some decl
      | Option.none =>
          psKernelLocalContextFindIn name
            (psKernelC0TrieBucket psKernelC0IndexDepth index
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
