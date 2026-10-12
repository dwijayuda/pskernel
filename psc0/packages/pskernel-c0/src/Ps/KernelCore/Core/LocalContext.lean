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
C0 local environment indexing.

Local binders often have short lifetimes. In checked definition admission,
a 16-binder chain spent more time maintaining the radix index than looking up
locals. Keep shallow contexts as lists through 32 entries and build a radix-16
index only when adding the 33rd local. Deep contexts then share indexed lookups
and four-level persistent updates. This prevents the demonstrated premature
index-maintenance cost without giving up the 512-local indexed lookup benefit.

The ordered list remains authoritative, including name shadowing; each
persistent snapshot preserves the index appropriate to its own depth.
-/
/-- Eager indexing is only worth its construction and update cost for
    sufficiently deep local environments. This threshold is a performance
    policy; correctness and shadowing never depend on it. -/
def psKernelC0LocalIndexThreshold : Nat := 32

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

def psKernelC0LocalContextNextIndex
    (context : PsKernelLocalContext)
    (decl : PsKernelLocalDecl) :
    Option (PsKernelC0HashTrie PsKernelLocalDecl) :=
  match context.index with
  | Option.some index =>
      Option.some (psKernelC0LocalIndexInsert index decl)
  | Option.none =>
      -- No radix maintenance within short-lived binder spines.
      -- A later extension constructs the complete indexed snapshot once.
      if Nat.ble psKernelC0LocalIndexThreshold context.decls.length then
        Option.some
          (psKernelC0LocalIndexBuild (List.cons decl context.decls))
      else
        Option.none

def psKernelLocalContextFind
    (context : PsKernelLocalContext)
    (name : PsKernelName) :
    Option PsKernelLocalDecl :=
  match context.index with
  | Option.none =>
      psKernelLocalContextFindIn name context.decls
  | Option.some index =>
      psKernelLocalContextFindIn
        name
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
  {
    decls := List.cons decl context.decls
    nextIndex := Nat.succ context.nextIndex
    index := psKernelC0LocalContextNextIndex context decl
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
  {
    decls := List.cons decl context.decls
    nextIndex := Nat.succ context.nextIndex
    index := psKernelC0LocalContextNextIndex context decl
  }
