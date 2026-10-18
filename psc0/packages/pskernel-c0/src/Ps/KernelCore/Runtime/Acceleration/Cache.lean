import Ps.KernelCore.Core.ExprDecidableEq

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

/-
C0 UTF-8 hash fast path: fold directly over Unicode scalar values.
The portable historical worker is retained above as a differential oracle.
String.foldl avoids a complete UTF-8 byte-length prepass and the fuelled
interpreter loop. Each step uses the same 31*x+c mod 65521 mixing rule.
-/
def psKernelC0HashStringFrom
    (value : String)
    (seed : Nat) : Nat :=
  value.foldl
    (fun hash ch => psKernelCacheMix hash (Char.toNat ch))
    seed

def psKernelCacheStringHash
    (value : String) :
    Nat :=
  psKernelC0HashStringFrom value 0

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

/-- Exact immutable structural hashes and loose ranges for a let
    chain, bottom-up. Each frame stores (body range, *current let* hash).
    Hashes only select buckets; all cache hits still compare full syntax. -/
def psKernelC0LetCacheFramesWithFuel (fuel : Nat) :
    PsKernelExpr ->
    Option (Prod Nat (Prod Nat (List (Prod Nat Nat)))) :=
  match fuel with
  | 0 => fun _ => none
  | Nat.succ remaining =>
      let smaller := psKernelC0LetCacheFramesWithFuel remaining
      fun expr =>
        match expr with
        | .letE _ ty value body nondep => do
            let tyRange ← psKernelC0SourceLooseRangeWithFuel remaining ty
            let valueRange ← psKernelC0SourceLooseRangeWithFuel remaining value
            let (bodyRange, bodyHash, suffixes) ← smaller body
            let h :=
              psKernelCacheMix
                (psKernelCacheMix
                  (psKernelCacheMix
                    (psKernelCacheMix 29 (psKernelExprHash ty))
                    (psKernelExprHash value))
                  bodyHash)
                (if nondep then 1 else 0)
            pure (Nat.max (Nat.max tyRange valueRange) (Nat.pred bodyRange),
              h, (bodyRange, h) :: suffixes)
        | _ => do
            let range ← psKernelC0SourceLooseRangeWithFuel remaining expr
            pure (range, psKernelExprHash expr, [])

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


/-!
Proof-carrying memoization of EXACT historical PsKernelExpr structural hashes.

One locally owned memo is built bottom-up. Every cached value carries a
Lean proof that it equals psKernelExprHash of its exact expression. A cheap
bounded-shape hash is used only to choose trie buckets; exact equality is
resolved by a Lean-proved DecidableEq with Lean's proof-constrained
withPtrEqDecEq shortcut. Collisions cannot change the result.

This is a source-syntax helper only. Its output is not a checked type, proof
term, DefEq fact, environment admission, or substitute for resource policy.
The original source hash remains an independent oracle.
-/


/-- Depth-bounded bucket selector; *never* a certified hash result. It
examines at most four constructor layers regardless of shared DAG expansion.
This result is used symmetrically by lookup and insertion only. -/
def psKernelC0MemoShapeHash : Nat → PsKernelExpr → Nat
  | 0, _ => 37
  | n + 1, expr =>
      match expr with
      | .app fn arg =>
          psKernelCacheMix
            (psKernelCacheMix 26 (psKernelC0MemoShapeHash n fn))
            (psKernelC0MemoShapeHash n arg)
      | .lam _ ty body _ =>
          psKernelCacheMix
            (psKernelCacheMix 27 (psKernelC0MemoShapeHash n ty))
            (psKernelC0MemoShapeHash n body)
      | .forallE _ ty body _ =>
          psKernelCacheMix
            (psKernelCacheMix 28 (psKernelC0MemoShapeHash n ty))
            (psKernelC0MemoShapeHash n body)
      | .letE _ ty value body nondep =>
          psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix
                (psKernelCacheMix 29 (psKernelC0MemoShapeHash n ty))
                (psKernelC0MemoShapeHash n value))
              (psKernelC0MemoShapeHash n body))
            (if nondep then 1 else 0)
      | .mdata md body =>
          psKernelCacheMix
            (psKernelCacheMix 31 md)
            (psKernelC0MemoShapeHash n body)
      | .proj name index body =>
          psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix 32 (psKernelCacheNameHash name))
              index)
            (psKernelC0MemoShapeHash n body)
      | .bvar i => psKernelCacheMix 21 i
      | .fvar name => psKernelCacheMix 22 (psKernelCacheNameHash name)
      | .mvar name => psKernelCacheMix 23 (psKernelCacheNameHash name)
      | .sort lev => psKernelCacheMix 24 (psKernelCacheLevelHash lev)
      | .const name levels =>
          psKernelCacheMix
            (psKernelCacheMix 25 (psKernelCacheNameHash name))
            (psKernelCacheLevelListHash levels)
      | .lit v => psKernelCacheMix 30 (psKernelCacheLiteralHash v)

/-- Exact source hash tied to the immutable source term. The certificate
is a Prop, erased by Lean's native compiler. -/
structure PsKernelC0ExactHash (expr : PsKernelExpr) where
  value : Nat
  source : value = psKernelExprHash expr

structure PsKernelC0HashMemoEntry where
  expr : PsKernelExpr
  checkedHash : PsKernelC0ExactHash expr

abbrev PsKernelC0ExactHashMemo :=
  PsKernelC0HashTrie PsKernelC0HashMemoEntry

private def psKernelC0HashMemoBucket (expr : PsKernelExpr) : Nat :=
  psKernelC0MemoShapeHash 4 expr

private def psKernelC0HashMemoFind
    (expr : PsKernelExpr) :
    List PsKernelC0HashMemoEntry → Option (PsKernelC0ExactHash expr)
  | [] => none
  | entry :: rest =>
      match psKernelC0ExactPairEq expr entry.expr with
      | .isTrue h =>
          some {
            value := entry.checkedHash.value
            source := entry.checkedHash.source.trans
              (congrArg psKernelExprHash h.symm)
          }
      | .isFalse _ => psKernelC0HashMemoFind expr rest

/-- Leaf terms whose source hash is cheaper than a trie lookup.
This is only a non-semantic memo selection heuristic. -/
private def psKernelC0HashMemoCheapLeaf : PsKernelExpr → Bool
  | .bvar _ => true
  | .lit (.nat _) => true
  | _ => false

private def psKernelC0HashMemoLookup
    (expr : PsKernelExpr)
    (memo : PsKernelC0ExactHashMemo) :
    Option (PsKernelC0ExactHash expr) :=
  if psKernelC0HashMemoCheapLeaf expr then
    none
  else
    psKernelC0HashMemoFind expr
      (psKernelC0TrieBucket psKernelC0IndexDepth memo
        (psKernelC0HashMemoBucket expr))

private def psKernelC0HashMemoInsert
    (expr : PsKernelExpr)
    (value : PsKernelC0ExactHash expr)
    (memo : PsKernelC0ExactHashMemo) :
    PsKernelC0ExactHashMemo :=
  let bucketHash := psKernelC0HashMemoBucket expr
  let entries :=
    psKernelC0TrieBucket psKernelC0IndexDepth memo bucketHash
  psKernelC0TrieSet psKernelC0IndexDepth memo bucketHash
    ({ expr := expr, checkedHash := value } :: entries)

/-- A source-certified hash and the updated operation-local memo. -/
private def psKernelC0ExactHashStore
    {expr : PsKernelExpr}
    (memo : PsKernelC0ExactHashMemo)
    (value : PsKernelC0ExactHash expr) :
    PsKernelC0ExactHash expr × PsKernelC0ExactHashMemo :=
  (value, psKernelC0HashMemoInsert expr value memo)

/-- Fully structural source-certified memo recursion. For every subtree,
only an EXACT syntax match can reuse a previously proved hash. The returned
proof is constructed compositionally from children's source hash equations.
No arbitrary hash table, untrusted pointer, or cache value is imported. -/
def psKernelC0ExactHashWithMemo
    (expr : PsKernelExpr)
    (memo : PsKernelC0ExactHashMemo) :
    PsKernelC0ExactHash expr × PsKernelC0ExactHashMemo :=
  match psKernelC0HashMemoLookup expr memo with
  | some cached => (cached, memo)
  | none =>
      match expr with
      | .app fn arg =>
          let (left, m1) := psKernelC0ExactHashWithMemo fn memo
          let (right, m2) := psKernelC0ExactHashWithMemo arg m1
          let hash := psKernelCacheMix
            (psKernelCacheMix 26 left.value) right.value
          let proof : hash = psKernelExprHash (.app fn arg) := by
            change psKernelCacheMix
              (psKernelCacheMix 26 left.value) right.value =
              psKernelCacheMix
                (psKernelCacheMix 26 (psKernelExprHash fn))
                (psKernelExprHash arg)
            rw [left.source, right.source]
          psKernelC0ExactHashStore m2 ⟨hash, proof⟩
      | .lam name ty body info =>
          let (left, m1) := psKernelC0ExactHashWithMemo ty memo
          let (right, m2) := psKernelC0ExactHashWithMemo body m1
          let hash := psKernelCacheMix
            (psKernelCacheMix 27 left.value) right.value
          let proof : hash = psKernelExprHash (.lam name ty body info) := by
            change psKernelCacheMix
              (psKernelCacheMix 27 left.value) right.value =
              psKernelCacheMix
                (psKernelCacheMix 27 (psKernelExprHash ty))
                (psKernelExprHash body)
            rw [left.source, right.source]
          psKernelC0ExactHashStore m2 ⟨hash, proof⟩
      | .forallE name ty body info =>
          let (left, m1) := psKernelC0ExactHashWithMemo ty memo
          let (right, m2) := psKernelC0ExactHashWithMemo body m1
          let hash := psKernelCacheMix
            (psKernelCacheMix 28 left.value) right.value
          let proof : hash = psKernelExprHash (.forallE name ty body info) := by
            change psKernelCacheMix
              (psKernelCacheMix 28 left.value) right.value =
              psKernelCacheMix
                (psKernelCacheMix 28 (psKernelExprHash ty))
                (psKernelExprHash body)
            rw [left.source, right.source]
          psKernelC0ExactHashStore m2 ⟨hash, proof⟩
      | .letE name ty value body nondep =>
          let (a, m1) := psKernelC0ExactHashWithMemo ty memo
          let (b, m2) := psKernelC0ExactHashWithMemo value m1
          let (c, m3) := psKernelC0ExactHashWithMemo body m2
          let hash := psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix
                (psKernelCacheMix 29 a.value) b.value)
              c.value)
            (if nondep then 1 else 0)
          let proof : hash =
              psKernelExprHash (.letE name ty value body nondep) := by
            change psKernelCacheMix
              (psKernelCacheMix
                (psKernelCacheMix
                  (psKernelCacheMix 29 a.value) b.value)
                c.value)
              (if nondep then 1 else 0) =
              psKernelCacheMix
                (psKernelCacheMix
                  (psKernelCacheMix
                    (psKernelCacheMix 29 (psKernelExprHash ty))
                    (psKernelExprHash value))
                  (psKernelExprHash body))
                (if nondep then 1 else 0)
            rw [a.source, b.source, c.source]
          psKernelC0ExactHashStore m3 ⟨hash, proof⟩
      | .mdata md body =>
          let (value, m1) := psKernelC0ExactHashWithMemo body memo
          let hash := psKernelCacheMix (psKernelCacheMix 31 md) value.value
          let proof : hash = psKernelExprHash (.mdata md body) := by
            change psKernelCacheMix (psKernelCacheMix 31 md) value.value =
              psKernelCacheMix (psKernelCacheMix 31 md)
                (psKernelExprHash body)
            rw [value.source]
          psKernelC0ExactHashStore m1 ⟨hash, proof⟩
      | .proj name i body =>
          let (value, m1) := psKernelC0ExactHashWithMemo body memo
          let hash := psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix 32 (psKernelCacheNameHash name)) i)
            value.value
          let proof : hash = psKernelExprHash (.proj name i body) := by
            change psKernelCacheMix
              (psKernelCacheMix
                (psKernelCacheMix 32 (psKernelCacheNameHash name)) i)
              value.value =
              psKernelCacheMix
                (psKernelCacheMix
                  (psKernelCacheMix 32 (psKernelCacheNameHash name)) i)
                (psKernelExprHash body)
            rw [value.source]
          psKernelC0ExactHashStore m1 ⟨hash, proof⟩
      | .bvar n =>
          -- Source is a constant-time exact hash; memo writes are costlier.
          (⟨psKernelCacheMix 21 n, rfl⟩, memo)
      | .fvar n =>
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix 22 (psKernelCacheNameHash n), rfl⟩
      | .mvar n =>
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix 23 (psKernelCacheNameHash n), rfl⟩
      | .sort l =>
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix 24 (psKernelCacheLevelHash l), rfl⟩
      | .const n ls =>
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix
              (psKernelCacheMix 25 (psKernelCacheNameHash n))
              (psKernelCacheLevelListHash ls), rfl⟩
      | .lit (.nat n) =>
          -- Exact Nat literal source formula without lookup/insertion.
          (⟨psKernelCacheMix 30 (psKernelCacheMix 19 n), rfl⟩, memo)
      | .lit (.str s) =>
          -- String hashing is not constant-time; preserve reuse here.
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix 30 (psKernelCacheLiteralHash (.str s)), rfl⟩

/-- An externally usable, operation-local exact hash. The original source
function is independently available as the proof target and regression
oracle. Every complete invocation starts with a private empty memo. -/
def psKernelC0ExactMemoizedExprHash (expr : PsKernelExpr) : Nat :=
  (psKernelC0ExactHashWithMemo expr .empty).1.value

/-- Strong all-input hash equivalence; neither collisions nor native pointer
shortcuts can change the original source hash, under ANY expression. -/
theorem psKernelC0ExactMemoizedExprHash_source
    (expr : PsKernelExpr) :
    psKernelC0ExactMemoizedExprHash expr = psKernelExprHash expr :=
  (psKernelC0ExactHashWithMemo expr .empty).1.source

/-- Native compiler replacement with a FULL Lean proof: every expression
returns precisely the historical C0 hash, including shape-hash collisions.
This replacement cannot change checking semantics. Registered only for
modules that explicitly import this experimental hash memo until the
complete real-WF benchmark qualifies the source-cache integration. -/
@[csimp] theorem psKernelExprHash_compiler_eq_exactMemo :
    @psKernelExprHash = @psKernelC0ExactMemoizedExprHash := by
  funext expr
  exact (psKernelC0ExactMemoizedExprHash_source expr).symm


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

def psKernelExprMapGetWithKnownHash
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr)
    (knownHash : Option Nat) :
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
          (match knownHash with
           | some h => h
           | none => psKernelExprHash expr))

def psKernelExprMapGet
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr) : Option PsKernelExpr :=
  psKernelExprMapGetWithKnownHash cache expr none

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

def psKernelExprMapInsertWithKnownHash
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr)
    (value : PsKernelExpr)
    (knownHash : Option Nat) :
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
        match knownHash with
        | some h => h
        | none => psKernelExprHash expr;
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

def psKernelExprMapInsert
    (cache : PsKernelExprMap)
    (expr value : PsKernelExpr) : PsKernelExprMap :=
  psKernelExprMapInsertWithKnownHash cache expr value none

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
