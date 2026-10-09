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
            String.Pos.Raw.atEnd
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
              (String.Pos.Raw.next
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


namespace PsKernelSharing

@[inline, instance_reducible]
def hashAlgebra : Algebra Nat where
  atom := fun e _ => psKernelExprHash e
  unary := fun e _ b => match e with
    | .mdata md _ => psKernelCacheMix (psKernelCacheMix 31 md) b
    | .proj n i _ => psKernelCacheMix
        (psKernelCacheMix (psKernelCacheMix 32 (psKernelCacheNameHash n)) i) b
    | _ => psKernelExprHash e
  binary := fun e _ l r => match e with
    | .app .. => psKernelCacheMix (psKernelCacheMix 26 l) r
    | .lam .. => psKernelCacheMix (psKernelCacheMix 27 l) r
    | .forallE .. => psKernelCacheMix (psKernelCacheMix 28 l) r
    | _ => psKernelExprHash e
  ternary := fun e _ t v b => match e with
    | .letE _ _ _ _ nd => psKernelCacheMix
        (psKernelCacheMix (psKernelCacheMix (psKernelCacheMix 29 t) v) b)
        (if nd then 1 else 0)
    | _ => psKernelExprHash e

theorem hash_fold (e : PsKernelExpr) (cursor : Nat) :
    fold hashAlgebra e cursor = psKernelExprHash e := by
  induction e generalizing cursor <;>
    simp_all [Algebra.atom, Algebra.unary, Algebra.binary, Algebra.ternary,
      fold, hashAlgebra, psKernelExprHash]

abbrev HashMemo := Squash (Memo PsKernelExpr Nat (fold hashAlgebra))

def hashWalk (e : @& PsKernelExpr) (memo : HashMemo) :
    Squash (Result (fold hashAlgebra) e 0) :=
  Squash.lift memo fun m =>
    step e 0 m (fun _ => walk hashAlgebra e 0 m)

/-- A read-only query needs the exact hash but does not publish new metadata. -/
def hashRead (e : @& PsKernelExpr) (memo : HashMemo) : Nat :=
  value (hashWalk e memo)

theorem hashRead_eq (e : PsKernelExpr) (memo : HashMemo) :
    hashRead e memo = psKernelExprHash e := by
  unfold hashRead
  rw [value_eq, hash_fold]

/-- Publish the operation's scratch entries once, at the lifetime boundary. -/
def hashCached (e : @& PsKernelExpr) (memo : HashMemo) : Nat × HashMemo :=
  let (hash, next) := valueAndMemo (hashWalk e memo)
  (hash, Squash.lift next fun m => Squash.mk m.freeze)

theorem hashCached_eq (e : PsKernelExpr) (memo : HashMemo) :
    (hashCached e memo).1 = psKernelExprHash e := by
  unfold hashCached
  rw [valueAndMemo_eq, hash_fold]

end PsKernelSharing

inductive PsKernelExprMapIndex where
  | empty
  | bucket
      (entries :
        List (Prod PsKernelExpr PsKernelExpr))
  | branch
      (left : PsKernelExprMapIndex)
      (right : PsKernelExprMapIndex)

def psKernelExprMapIndexBucket
    (fuel : Nat) :
    PsKernelExprMapIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelExprMapIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelExprMapIndex.bucket entries =>
            entries
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprMapIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) :=
        psKernelExprMapIndexBucket remaining;
      fun
        (index : PsKernelExprMapIndex)
        (hash : Nat) =>
        match index with
        | PsKernelExprMapIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil

def psKernelExprMapIndexSet
    (fuel : Nat) :
    PsKernelExprMapIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) ->
    PsKernelExprMapIndex :=
  match fuel with
  | Nat.zero =>
      fun
        (_index : PsKernelExprMapIndex)
        (_hash : Nat)
        (entries :
          List (Prod PsKernelExpr PsKernelExpr)) =>
        PsKernelExprMapIndex.bucket entries
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprMapIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) ->
          PsKernelExprMapIndex :=
        psKernelExprMapIndexSet remaining;
      fun
        (index : PsKernelExprMapIndex)
        (hash : Nat)
        (entries :
          List (Prod PsKernelExpr PsKernelExpr)) =>
        let left : PsKernelExprMapIndex :=
          match index with
          | PsKernelExprMapIndex.branch value _ =>
              value
          | _ =>
              PsKernelExprMapIndex.empty;
        let right : PsKernelExprMapIndex :=
          match index with
          | PsKernelExprMapIndex.branch _ value =>
              value
          | _ =>
              PsKernelExprMapIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsKernelExprMapIndex.branch
            (smaller
              left
              (Nat.div hash 2)
              entries)
            right
        else
          PsKernelExprMapIndex.branch
            left
            (smaller
              right
              (Nat.div hash 2)
              entries)

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
  hashMemo : PsKernelSharing.HashMemo := Squash.mk {}

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
          16
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
      PsKernelExprMapIndex.empty
  | List.cons entry rest =>
      let index :=
        psKernelExprMapBuildIndex rest;
      let key :=
        Prod.fst entry;
      let hash :=
        psKernelExprHash key;
      let bucket :=
        psKernelExprMapIndexBucket
          16
          index
          hash;
      psKernelExprMapIndexSet
        16
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
          16
          index
          hash;
      {
        small := List.nil
        index :=
          Option.some
            (psKernelExprMapIndexSet
              16
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

inductive PsKernelExprPairSetIndex where
  | empty
  | bucket
      (entries :
        List (Prod PsKernelExpr PsKernelExpr))
  | branch
      (left : PsKernelExprPairSetIndex)
      (right : PsKernelExprPairSetIndex)

def psKernelExprPairSetIndexBucket
    (fuel : Nat) :
    PsKernelExprPairSetIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelExprPairSetIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelExprPairSetIndex.bucket entries =>
            entries
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprPairSetIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) :=
        psKernelExprPairSetIndexBucket remaining;
      fun
        (index : PsKernelExprPairSetIndex)
        (hash : Nat) =>
        match index with
        | PsKernelExprPairSetIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil

def psKernelExprPairSetIndexSet
    (fuel : Nat) :
    PsKernelExprPairSetIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) ->
    PsKernelExprPairSetIndex :=
  match fuel with
  | Nat.zero =>
      fun
        (_index : PsKernelExprPairSetIndex)
        (_hash : Nat)
        (entries :
          List (Prod PsKernelExpr PsKernelExpr)) =>
        PsKernelExprPairSetIndex.bucket entries
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprPairSetIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) ->
          PsKernelExprPairSetIndex :=
        psKernelExprPairSetIndexSet remaining;
      fun
        (index : PsKernelExprPairSetIndex)
        (hash : Nat)
        (entries :
          List (Prod PsKernelExpr PsKernelExpr)) =>
        let left : PsKernelExprPairSetIndex :=
          match index with
          | PsKernelExprPairSetIndex.branch value _ =>
              value
          | _ =>
              PsKernelExprPairSetIndex.empty;
        let right : PsKernelExprPairSetIndex :=
          match index with
          | PsKernelExprPairSetIndex.branch _ value =>
              value
          | _ =>
              PsKernelExprPairSetIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsKernelExprPairSetIndex.branch
            (smaller
              left
              (Nat.div hash 2)
              entries)
            right
        else
          PsKernelExprPairSetIndex.branch
            left
            (smaller
              right
              (Nat.div hash 2)
              entries)

structure PsKernelExprPairSet where
  small :
    List (Prod PsKernelExpr PsKernelExpr)
  index : Option PsKernelExprPairSetIndex
  hashMemo : PsKernelSharing.HashMemo := Squash.mk {}

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
          16
          index
          (psKernelExprPairHash left right))

def psKernelExprPairSetBuildIndex
    (entries :
      List (Prod PsKernelExpr PsKernelExpr)) :
    PsKernelExprPairSetIndex :=
  match entries with
  | List.nil =>
      PsKernelExprPairSetIndex.empty
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
          16
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
          16
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
          16
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
                16
                index
                hash
                (List.cons
                  (Prod.mk left right)
                  bucket))
        }


/-- Hash hints persist with a semantic cache, but carry no logical information.
All four equations below preserve the entire result, including failed lookups. -/
def psKernelExprMapGetShared (cache : PsKernelExprMap) (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  match cache.index with
  | none => psKernelExprMapGetIn expr cache.small
  | some index =>
      psKernelExprMapGetIn expr (psKernelExprMapIndexBucket 16 index
        (PsKernelSharing.hashRead expr cache.hashMemo))

@[csimp] theorem psKernelExprMapGet_shared_eq :
    psKernelExprMapGet = psKernelExprMapGetShared := by
  funext cache expr
  simp only [psKernelExprMapGet, psKernelExprMapGetShared,
    PsKernelSharing.hashRead_eq]

def psKernelExprMapInsertShared (cache : PsKernelExprMap)
    (expr value : PsKernelExpr) : PsKernelExprMap :=
  match cache.index with
  | none => psKernelExprMapInsert cache expr value
  | some index =>
      let (hash, memo) := PsKernelSharing.hashCached expr cache.hashMemo
      let bucket := psKernelExprMapIndexBucket 16 index hash
      { small := [], index := some (psKernelExprMapIndexSet 16 index hash
          (psKernelExprMapInsertIn expr value bucket)), hashMemo := memo }

@[csimp] theorem psKernelExprMapInsert_shared_eq :
    psKernelExprMapInsert = psKernelExprMapInsertShared := by
  funext cache expr value
  cases h : cache.index with
  | none => simp [psKernelExprMapInsertShared, h]
  | some index =>
      simp only [psKernelExprMapInsertShared, psKernelExprMapInsert, h,
        PsKernelSharing.hashCached_eq]
      congr 1
      exact Subsingleton.elim _ _

namespace PsKernelSharing

def pairHashCached (left right : PsKernelExpr) (memo : HashMemo) : Nat × HashMemo :=
  let (lh, memo) := hashCached left memo
  let (rh, memo) := hashCached right memo
  (Nat.mod (Nat.add lh rh) psKernelCacheHashModulus, memo)

theorem pairHashCached_eq (left right : PsKernelExpr) (memo : HashMemo) :
    (pairHashCached left right memo).1 = psKernelExprPairHash left right := by
  simp [pairHashCached, hashCached_eq, psKernelExprPairHash]

end PsKernelSharing

def psKernelExprPairSetContainsShared (set : PsKernelExprPairSet)
    (left right : PsKernelExpr) : Bool :=
  match set.index with
  | none => psKernelExprPairSetContainsIn left right set.small
  | some index =>
      psKernelExprPairSetContainsIn left right
        (psKernelExprPairSetIndexBucket 16 index
          (Nat.mod
            (PsKernelSharing.hashRead left set.hashMemo +
              PsKernelSharing.hashRead right set.hashMemo) psKernelCacheHashModulus))

@[csimp] theorem psKernelExprPairSetContains_shared_eq :
    psKernelExprPairSetContains = psKernelExprPairSetContainsShared := by
  funext set left right
  simp only [psKernelExprPairSetContains, psKernelExprPairSetContainsShared,
    PsKernelSharing.hashRead_eq, psKernelExprPairHash]

def psKernelExprPairSetInsertShared (set : PsKernelExprPairSet)
    (left right : PsKernelExpr) : PsKernelExprPairSet :=
  match set.index with
  | none => psKernelExprPairSetInsert set left right
  | some index =>
      let (hash, memo) := PsKernelSharing.pairHashCached left right set.hashMemo
      let bucket := psKernelExprPairSetIndexBucket 16 index hash
      if psKernelExprPairSetContainsIn left right bucket then set
      else { small := [], index := some (psKernelExprPairSetIndexSet 16 index hash
          ((left, right) :: bucket)), hashMemo := memo }

@[csimp] theorem psKernelExprPairSetInsert_shared_eq :
    psKernelExprPairSetInsert = psKernelExprPairSetInsertShared := by
  funext set left right
  cases h : set.index with
  | none => simp [psKernelExprPairSetInsertShared, h]
  | some index =>
      simp only [psKernelExprPairSetInsertShared, psKernelExprPairSetInsert, h,
        PsKernelSharing.pairHashCached_eq]
      split
      · rfl
      · congr 1
        exact Subsingleton.elim _ _
