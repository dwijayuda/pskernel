import Ps.KernelCore.Core.Expr

def psKernelCacheHashModulus : Nat :=
  65521

def psKernelCacheMix
    (left : Nat)
    (right : Nat) :
    Nat :=
  Nat.mod
    (Nat.add
      (Nat.mul left 31)
      right)
    psKernelCacheHashModulus

def psKernelCacheStringHashWorker
    (fuel : Nat) :
    String -> Nat -> Nat -> Nat :=
  match fuel with
  | Nat.zero =>
      fun
        (_value : String)
        (_position : Nat)
        (hash : Nat) =>
        hash
  | Nat.succ remaining =>
      let smaller :
          String -> Nat -> Nat -> Nat :=
        psKernelCacheStringHashWorker remaining;
      fun
        (value : String)
        (position : Nat)
        (hash : Nat) =>
        if
            String.Internal.atEnd
              value
              (String.Pos.Raw.mk position) then
          hash
        else
          let char :=
            String.Internal.get
              value
              (String.Pos.Raw.mk position);
          let next :=
            String.Pos.Raw.byteIdx
              (String.Internal.next
                value
                (String.Pos.Raw.mk position));
          smaller
            value
            next
            (psKernelCacheMix
              hash
              (Char.toNat char))

def psKernelCacheStringHash
    (value : String) :
    Nat :=
  psKernelCacheStringHashWorker
    (Nat.succ
      (String.utf8ByteSize value))
    value
    0
    0

def psKernelCacheNameHash
    (name : PsKernelName) :
    Nat :=
  match name with
  | PsKernelName.anonymous =>
      1
  | PsKernelName.str parent value =>
      psKernelCacheMix
        (psKernelCacheMix
          2
          (psKernelCacheNameHash parent))
        (psKernelCacheStringHash value)
  | PsKernelName.num parent value =>
      psKernelCacheMix
        (psKernelCacheMix
          3
          (psKernelCacheNameHash parent))
        value

def psKernelCacheLevelHash
    (level : PsKernelLevel) :
    Nat :=
  match level with
  | PsKernelLevel.zero =>
      11
  | PsKernelLevel.succ inner =>
      psKernelCacheMix
        12
        (psKernelCacheLevelHash inner)
  | PsKernelLevel.max left right =>
      psKernelCacheMix
        (psKernelCacheMix
          13
          (psKernelCacheLevelHash left))
        (psKernelCacheLevelHash right)
  | PsKernelLevel.imax left right =>
      psKernelCacheMix
        (psKernelCacheMix
          14
          (psKernelCacheLevelHash left))
        (psKernelCacheLevelHash right)
  | PsKernelLevel.param name =>
      psKernelCacheMix
        15
        (psKernelCacheNameHash name)
  | PsKernelLevel.mvar name =>
      psKernelCacheMix
        16
        (psKernelCacheNameHash name)

def psKernelCacheLevelListHashWorker
    (values : List PsKernelLevel) :
    Nat -> Nat :=
  match values with
  | List.nil =>
      fun (hash : Nat) =>
        psKernelCacheMix hash 17
  | List.cons head tail =>
      let smaller : Nat -> Nat :=
        psKernelCacheLevelListHashWorker tail;
      fun (hash : Nat) =>
        smaller
          (psKernelCacheMix
            hash
            (psKernelCacheLevelHash head))

def psKernelCacheLevelListHash
    (values : List PsKernelLevel) :
    Nat :=
  psKernelCacheLevelListHashWorker
    values
    18

def psKernelCacheLiteralHash
    (literal : PsKernelLiteral) :
    Nat :=
  match literal with
  | PsKernelLiteral.nat value =>
      psKernelCacheMix 19 value
  | PsKernelLiteral.str value =>
      psKernelCacheMix
        20
        (psKernelCacheStringHash value)

def psKernelExprHash
    (expr : PsKernelExpr) :
    Nat :=
  match expr with
  | PsKernelExpr.bvar index =>
      psKernelCacheMix 21 index
  | PsKernelExpr.fvar name =>
      psKernelCacheMix
        22
        (psKernelCacheNameHash name)
  | PsKernelExpr.mvar name =>
      psKernelCacheMix
        23
        (psKernelCacheNameHash name)
  | PsKernelExpr.sort level =>
      psKernelCacheMix
        24
        (psKernelCacheLevelHash level)
  | PsKernelExpr.const name levels =>
      psKernelCacheMix
        (psKernelCacheMix
          25
          (psKernelCacheNameHash name))
        (psKernelCacheLevelListHash levels)
  | PsKernelExpr.app fn arg =>
      psKernelCacheMix
        (psKernelCacheMix
          26
          (psKernelExprHash fn))
        (psKernelExprHash arg)
  | PsKernelExpr.lam _ type body _ =>
      psKernelCacheMix
        (psKernelCacheMix
          27
          (psKernelExprHash type))
        (psKernelExprHash body)
  | PsKernelExpr.forallE _ type body _ =>
      psKernelCacheMix
        (psKernelCacheMix
          28
          (psKernelExprHash type))
        (psKernelExprHash body)
  | PsKernelExpr.letE _ type value body nondep =>
      let typeHash :=
        psKernelExprHash type;
      let valueHash :=
        psKernelExprHash value;
      let bodyHash :=
        psKernelExprHash body;
      let flag :=
        if nondep then 1 else 0;
      psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix
            (psKernelCacheMix
              29
              typeHash)
            valueHash)
          bodyHash)
        flag
  | PsKernelExpr.lit literal =>
      psKernelCacheMix
        30
        (psKernelCacheLiteralHash literal)
  | PsKernelExpr.mdata metadata body =>
      psKernelCacheMix
        (psKernelCacheMix
          31
          metadata)
        (psKernelExprHash body)
  | PsKernelExpr.proj typeName index body =>
      psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix
            32
            (psKernelCacheNameHash typeName))
          index)
        (psKernelExprHash body)

/-
PSKernel-C0 radix-16 cache index.

One generic persistent trie replaces the two duplicated binary tries.  Four
radix-16 levels index the existing bounded 16-bit expression hash.  Collisions
remain in leaf buckets and are always resolved by structural expression
equality; the hash is never an acceptance predicate.

The small-entry fast path is preserved.  Each insertion path allocates at most
four trie branches rather than sixteen.  Fixed-width child arrays reduce lookup
branching overhead without requiring Std or external hash-table instances.
-/

inductive PsKernelC0HashTrie (α : Type) where
  | empty
  | bucket (entries : List α)
  | branch (children : Array (PsKernelC0HashTrie α))

def psKernelC0Radix : Nat := 16
def psKernelC0IndexDepth : Nat := 4

def psKernelC0TrieBucket {α : Type}
    (fuel : Nat)
    (index : PsKernelC0HashTrie α)
    (hash : Nat) : List α :=
  match fuel with
  | Nat.zero =>
      match index with
      | PsKernelC0HashTrie.bucket entries => entries
      | _ => []
  | Nat.succ remaining =>
      match index with
      | PsKernelC0HashTrie.branch children =>
          match children[hash % psKernelC0Radix]? with
          | Option.some child =>
              psKernelC0TrieBucket remaining child (hash / psKernelC0Radix)
          | Option.none => []
      | _ => []

def psKernelC0TrieSet {α : Type}
    (fuel : Nat)
    (index : PsKernelC0HashTrie α)
    (hash : Nat)
    (entries : List α) : PsKernelC0HashTrie α :=
  match fuel with
  | Nat.zero => PsKernelC0HashTrie.bucket entries
  | Nat.succ remaining =>
      let children :=
        match index with
        | PsKernelC0HashTrie.branch values => values
        | _ => Array.replicate psKernelC0Radix PsKernelC0HashTrie.empty
      let slot := hash % psKernelC0Radix
      let previous :=
        match children[slot]? with
        | Option.some value => value
        | Option.none => PsKernelC0HashTrie.empty
      let next :=
        psKernelC0TrieSet remaining previous (hash / psKernelC0Radix) entries
      PsKernelC0HashTrie.branch (children.set! slot next)

abbrev PsKernelExprMapIndex :=
  PsKernelC0HashTrie (Prod PsKernelExpr PsKernelExpr)

def psKernelExprMapIndexBucket
    (fuel : Nat)
    (index : PsKernelExprMapIndex)
    (hash : Nat) : List (Prod PsKernelExpr PsKernelExpr) :=
  psKernelC0TrieBucket fuel index hash

def psKernelExprMapIndexSet
    (fuel : Nat)
    (index : PsKernelExprMapIndex)
    (hash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    PsKernelExprMapIndex :=
  psKernelC0TrieSet fuel index hash entries

def psKernelCacheSmallLimit : Nat :=
  8

def psKernelCacheEntryListLength
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    Nat :=
  match entries with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelCacheEntryListLength rest)

structure PsKernelExprMap where
  small :
    List (Prod PsKernelExpr PsKernelExpr)
  index : Option PsKernelExprMapIndex

def psKernelExprMapEmpty :
    PsKernelExprMap :=
  {
    small := List.nil
    index := Option.none
  }

def psKernelExprMapGetIn
    (expr : PsKernelExpr)
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    Option PsKernelExpr :=
  match entries with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if
          psKernelExprEq
            (Prod.fst entry)
            expr then
        Option.some (Prod.snd entry)
      else
        psKernelExprMapGetIn
          expr
          rest

def psKernelExprMapGet
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  match cache.index with
  | Option.none =>
      psKernelExprMapGetIn
        expr
        cache.small
  | Option.some index =>
      psKernelExprMapGetIn
        expr
        (psKernelExprMapIndexBucket
          psKernelC0IndexDepth
          index
          (psKernelExprHash expr))

def psKernelExprMapInsertIn
    (expr : PsKernelExpr)
    (value : PsKernelExpr)
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    List (Prod PsKernelExpr PsKernelExpr) :=
  match entries with
  | List.nil =>
      List.cons
        (Prod.mk expr value)
        List.nil
  | List.cons entry rest =>
      if
          psKernelExprEq
            (Prod.fst entry)
            expr then
        List.cons
          (Prod.mk expr value)
          rest
      else
        List.cons
          entry
          (psKernelExprMapInsertIn
            expr
            value
            rest)

def psKernelExprMapBuildIndex
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    PsKernelExprMapIndex :=
  match entries with
  | List.nil =>
      PsKernelC0HashTrie.empty
  | List.cons entry rest =>
      let index :=
        psKernelExprMapBuildIndex rest;
      let key :=
        Prod.fst entry;
      let hash :=
        psKernelExprHash key;
      let bucket :=
        psKernelExprMapIndexBucket
          psKernelC0IndexDepth
          index
          hash;
      psKernelExprMapIndexSet
        psKernelC0IndexDepth
        index
        hash
        (psKernelExprMapInsertIn
          key
          (Prod.snd entry)
          bucket)

def psKernelExprMapInsert
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr)
    (value : PsKernelExpr) :
    PsKernelExprMap :=
  match cache.index with
  | Option.none =>
      let next :=
        psKernelExprMapInsertIn
          expr
          value
          cache.small;
      if
          Nat.ble
            (psKernelCacheEntryListLength next)
            psKernelCacheSmallLimit then
        {
          small := next
          index := Option.none
        }
      else
        {
          small := List.nil
          index :=
            Option.some
              (psKernelExprMapBuildIndex next)
        }
  | Option.some index =>
      let hash :=
        psKernelExprHash expr;
      let bucket :=
        psKernelExprMapIndexBucket
          psKernelC0IndexDepth
          index
          hash;
      {
        small := List.nil
        index :=
          Option.some
            (psKernelExprMapIndexSet
              psKernelC0IndexDepth
              index
              hash
              (psKernelExprMapInsertIn
                expr
                value
                bucket))
      }

def psKernelExprPairEq
    (left : PsKernelExpr)
    (right : PsKernelExpr)
    (entry :
      Prod PsKernelExpr PsKernelExpr) :
    Bool :=
  let first := Prod.fst entry;
  let second := Prod.snd entry;
  if psKernelExprEq first left then
    psKernelExprEq second right
  else if psKernelExprEq first right then
    psKernelExprEq second left
  else
    false

def psKernelExprPairHash
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Nat :=
  Nat.mod
    (Nat.add
      (psKernelExprHash left)
      (psKernelExprHash right))
    psKernelCacheHashModulus

abbrev PsKernelExprPairSetIndex :=
  PsKernelC0HashTrie (Prod PsKernelExpr PsKernelExpr)

def psKernelExprPairSetIndexBucket
    (fuel : Nat)
    (index : PsKernelExprPairSetIndex)
    (hash : Nat) : List (Prod PsKernelExpr PsKernelExpr) :=
  psKernelC0TrieBucket fuel index hash

def psKernelExprPairSetIndexSet
    (fuel : Nat)
    (index : PsKernelExprPairSetIndex)
    (hash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    PsKernelExprPairSetIndex :=
  psKernelC0TrieSet fuel index hash entries

structure PsKernelExprPairSet where
  small :
    List (Prod PsKernelExpr PsKernelExpr)
  index : Option PsKernelExprPairSetIndex

def psKernelExprPairSetEmpty :
    PsKernelExprPairSet :=
  {
    small := List.nil
    index := Option.none
  }

def psKernelExprPairSetContainsIn
    (left : PsKernelExpr)
    (right : PsKernelExpr)
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    Bool :=
  match entries with
  | List.nil =>
      false
  | List.cons entry rest =>
      if
          psKernelExprPairEq
            left
            right
            entry then
        true
      else
        psKernelExprPairSetContainsIn
          left
          right
          rest

def psKernelExprPairSetContains
    (set : PsKernelExprPairSet)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Bool :=
  match set.index with
  | Option.none =>
      psKernelExprPairSetContainsIn
        left
        right
        set.small
  | Option.some index =>
      psKernelExprPairSetContainsIn
        left
        right
        (psKernelExprPairSetIndexBucket
          psKernelC0IndexDepth
          index
          (psKernelExprPairHash left right))

def psKernelExprPairSetBuildIndex
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    PsKernelExprPairSetIndex :=
  match entries with
  | List.nil =>
      PsKernelC0HashTrie.empty
  | List.cons entry rest =>
      let index :=
        psKernelExprPairSetBuildIndex rest;
      let left :=
        Prod.fst entry;
      let right :=
        Prod.snd entry;
      let hash :=
        psKernelExprPairHash left right;
      let bucket :=
        psKernelExprPairSetIndexBucket
          psKernelC0IndexDepth
          index
          hash;
      if
          psKernelExprPairSetContainsIn
            left
            right
            bucket then
        index
      else
        psKernelExprPairSetIndexSet
          psKernelC0IndexDepth
          index
          hash
          (List.cons entry bucket)

def psKernelExprPairSetInsert
    (set : PsKernelExprPairSet)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    PsKernelExprPairSet :=
  match set.index with
  | Option.none =>
      if
          psKernelExprPairSetContainsIn
            left
            right
            set.small then
        set
      else
        let next :=
          List.cons
            (Prod.mk left right)
            set.small;
        if
            Nat.ble
              (psKernelCacheEntryListLength next)
              psKernelCacheSmallLimit then
          {
            small := next
            index := Option.none
          }
        else
          {
            small := List.nil
            index :=
              Option.some
                (psKernelExprPairSetBuildIndex next)
          }
  | Option.some index =>
      let hash :=
        psKernelExprPairHash left right;
      let bucket :=
        psKernelExprPairSetIndexBucket
          psKernelC0IndexDepth
          index
          hash;
      if
          psKernelExprPairSetContainsIn
            left
            right
            bucket then
        set
      else
        {
          small := List.nil
          index :=
            Option.some
              (psKernelExprPairSetIndexSet
                psKernelC0IndexDepth
                index
                hash
                (List.cons
                  (Prod.mk left right)
                  bucket))
        }
