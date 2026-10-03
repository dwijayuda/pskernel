import PSC1Kernel.Expr

namespace PSC1Kernel

/--
Portable checker-cache implementation for the self-host kernel.

Caches are operational only: collisions are always resolved with kernel
structural equality, so changing the bucket hash cannot change acceptance
semantics. Keeping this code on Array/List removes the Std.HashMap dependency
from the trusted self-host closure and lets PSC1 lower the same source to
portable backends.
-/
def checkerCacheBucketCount : Nat := 256

def checkerMixBucket (left right : Nat) : Nat :=
  (left * 33 + right + 1) % checkerCacheBucketCount

def checkerStringBucketHashCore : List Char → Nat → Nat
  | [], acc => acc
  | char :: rest, acc =>
      checkerStringBucketHashCore rest
        (checkerMixBucket acc char.toNat)

def checkerStringBucketHash (value : String) : Nat :=
  checkerStringBucketHashCore value.toList 17

def checkerNameBucketHash : Name → Nat
  | .anonymous => 11
  | .str parent value =>
      checkerMixBucket 13
        (checkerMixBucket
          (checkerNameBucketHash parent)
          (checkerStringBucketHash value))
  | .num parent value =>
      checkerMixBucket 17
        (checkerMixBucket
          (checkerNameBucketHash parent)
          (value % checkerCacheBucketCount))

def checkerLevelBucketHash : Level → Nat
  | .zero => 19
  | .succ level =>
      checkerMixBucket 23 (checkerLevelBucketHash level)
  | .max left right =>
      checkerMixBucket 29
        (checkerMixBucket
          (checkerLevelBucketHash left)
          (checkerLevelBucketHash right))
  | .imax left right =>
      checkerMixBucket 31
        (checkerMixBucket
          (checkerLevelBucketHash left)
          (checkerLevelBucketHash right))
  | .param name =>
      checkerMixBucket 37 (checkerNameBucketHash name)
  | .mvar name =>
      checkerMixBucket 41 (checkerNameBucketHash name)

def checkerLevelsBucketHash : List Level → Nat
  | [] => 43
  | level :: rest =>
      checkerMixBucket
        (checkerLevelBucketHash level)
        (checkerLevelsBucketHash rest)

def checkerLiteralBucketHash : Literal → Nat
  | .nat value =>
      checkerMixBucket 89 (value % checkerCacheBucketCount)
  | .str value =>
      checkerMixBucket 97 (checkerStringBucketHash value)

/--
Hash compatible with Expr.eq, not Expr.equal: binder display names and binder
annotations are intentionally ignored, while let nondep and metadata remain
structural. Collisions are harmless because bucket lookup rechecks Expr.eq.
-/
def checkerExprBucketHash : Expr → Nat
  | .bvar index =>
      checkerMixBucket 47 (index % checkerCacheBucketCount)
  | .fvar name =>
      checkerMixBucket 53 (checkerNameBucketHash name)
  | .mvar name =>
      checkerMixBucket 59 (checkerNameBucketHash name)
  | .sort level =>
      checkerMixBucket 61 (checkerLevelBucketHash level)
  | .const name levels =>
      checkerMixBucket 67
        (checkerMixBucket
          (checkerNameBucketHash name)
          (checkerLevelsBucketHash levels))
  | .app fn arg =>
      checkerMixBucket 71
        (checkerMixBucket
          (checkerExprBucketHash fn)
          (checkerExprBucketHash arg))
  | .lam _ type body _ =>
      checkerMixBucket 73
        (checkerMixBucket
          (checkerExprBucketHash type)
          (checkerExprBucketHash body))
  | .forallE _ type body _ =>
      checkerMixBucket 79
        (checkerMixBucket
          (checkerExprBucketHash type)
          (checkerExprBucketHash body))
  | .letE _ type value body nondep =>
      let nondepHash := if nondep then 1 else 0
      checkerMixBucket 83
        (checkerMixBucket
          (checkerExprBucketHash type)
          (checkerMixBucket
            (checkerExprBucketHash value)
            (checkerMixBucket
              (checkerExprBucketHash body)
              nondepHash)))
  | .lit value =>
      checkerLiteralBucketHash value
  | .mdata metadata expr =>
      checkerMixBucket 101
        (checkerMixBucket
          (metadata % checkerCacheBucketCount)
          (checkerExprBucketHash expr))
  | .proj typeName index expr =>
      checkerMixBucket 103
        (checkerMixBucket
          (checkerNameBucketHash typeName)
          (checkerMixBucket
            (index % checkerCacheBucketCount)
            (checkerExprBucketHash expr)))

structure CheckerExprMap (α : Type) where
  buckets : Array (List (Prod Expr α))

namespace CheckerExprMap

def empty : CheckerExprMap α :=
  { buckets := Array.replicate checkerCacheBucketCount [] }

def findInBucket
    (expr : Expr) : List (Prod Expr α) → Option α
  | [] => none
  | entry :: rest =>
      if Expr.eq entry.fst expr then
        some entry.snd
      else
        findInBucket expr rest

def replaceInBucket
    (expr : Expr)
    (value : α) : List (Prod Expr α) → List (Prod Expr α)
  | [] => [Prod.mk expr value]
  | entry :: rest =>
      if Expr.eq entry.fst expr then
        Prod.mk expr value :: rest
      else
        entry :: replaceInBucket expr value rest

def get? (cache : CheckerExprMap α) (expr : Expr) : Option α :=
  let key := checkerExprBucketHash expr
  if cache.buckets.size == checkerCacheBucketCount then
    match cache.buckets[key]? with
    | some values => findInBucket expr values
    | none => none
  else
    none

def insert
    (cache : CheckerExprMap α)
    (expr : Expr)
    (value : α) : CheckerExprMap α :=
  let buckets :=
    if cache.buckets.size == checkerCacheBucketCount then
      cache.buckets
    else
      Array.replicate checkerCacheBucketCount []
  let key := checkerExprBucketHash expr
  match buckets[key]? with
  | some values =>
      { buckets := buckets.set! key (replaceInBucket expr value values) }
  | none =>
      { buckets := buckets }

end CheckerExprMap

structure CheckerExprPairSet where
  buckets : Array (List (Prod Expr Expr))

namespace CheckerExprPairSet

def empty : CheckerExprPairSet :=
  { buckets := Array.replicate checkerCacheBucketCount [] }

def pairEq
    (left right : Expr)
    (entry : Prod Expr Expr) : Bool :=
  (Expr.eq entry.fst left && Expr.eq entry.snd right) ||
    (Expr.eq entry.fst right && Expr.eq entry.snd left)

def containsInBucket
    (left right : Expr) : List (Prod Expr Expr) → Bool
  | [] => false
  | entry :: rest =>
      if pairEq left right entry then
        true
      else
        containsInBucket left right rest

def contains
    (set : CheckerExprPairSet)
    (left right : Expr) : Bool :=
  let key :=
    checkerMixBucket 107
      ((checkerExprBucketHash left +
        checkerExprBucketHash right) % checkerCacheBucketCount)
  if set.buckets.size == checkerCacheBucketCount then
    match set.buckets[key]? with
    | some values => containsInBucket left right values
    | none => false
  else
    false

def insert
    (set : CheckerExprPairSet)
    (left right : Expr) : CheckerExprPairSet :=
  if contains set left right then
    set
  else
    let buckets :=
      if set.buckets.size == checkerCacheBucketCount then
        set.buckets
      else
        Array.replicate checkerCacheBucketCount []
    let key :=
      checkerMixBucket 107
        ((checkerExprBucketHash left +
          checkerExprBucketHash right) % checkerCacheBucketCount)
    match buckets[key]? with
    | some values =>
        { buckets := buckets.set! key (Prod.mk left right :: values) }
    | none =>
        { buckets := buckets }

end CheckerExprPairSet

/--
Pure declaration-scoped counterpart of final Lean 4.34 type_checker::state.
No cache in this structure is valid across an environment mutation.
-/
structure CheckerState where
  nextFresh : Nat
  inferOnly : CheckerExprMap Expr
  checkedInfer : CheckerExprMap Expr
  whnfCore : CheckerExprMap Expr
  whnf : CheckerExprMap Expr
  unfold : CheckerExprMap Expr
  success : CheckerExprPairSet
  failure : CheckerExprPairSet

namespace CheckerState

def empty : CheckerState :=
  {
    nextFresh := 0
    inferOnly := CheckerExprMap.empty
    checkedInfer := CheckerExprMap.empty
    whnfCore := CheckerExprMap.empty
    whnf := CheckerExprMap.empty
    unfold := CheckerExprMap.empty
    success := CheckerExprPairSet.empty
    failure := CheckerExprPairSet.empty
  }

/-- Session-global fresh names: sibling local scopes cannot reuse an FVar id. -/
def freshName (state : CheckerState) (base : Name) : Name × CheckerState :=
  let name := Name.num base state.nextFresh
  (name, { state with nextFresh := state.nextFresh + 1 })

end CheckerState

end PSC1Kernel
