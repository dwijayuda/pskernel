import Ps.KernelCore.Runtime.Acceleration.Cache

/-!
A source-exact candidate for *shared* DefEq pair hashing.

The original expression-pair cache key is an unordered modular sum of the
historical exact expression hashes. For large related DAGs, independent
hashing discards opportunities to reuse the first root's checked subhashes
while hashing the second.

Every returned pair-hash equals that original source function for ALL
inputs. Pointer/hash collisions cannot confer equality or checked results:
this only selects a bucket, and the source pair cache compares full syntax.

No trusted checker routes through this module until full native benchmark
and source-refinement gates qualify it.
-/

/-- Reuse verified subhashes for both sides of one source DefEq pair. The
result contains no permission to admit a proof, just a Nat cache key. -/
def psKernelC0MemoizedPairHash
    (left right : PsKernelExpr) : Nat :=
  let (lh, memo) :=
    psKernelC0ExactHashWithMemo left PsKernelC0HashTrie.empty
  let (rh, _) := psKernelC0ExactHashWithMemo right memo
  (lh.value + rh.value) % psKernelCacheHashModulus

/-- Strong source equality for ALL expression-pair keys. -/
theorem psKernelC0MemoizedPairHash_source
    (left right : PsKernelExpr) :
    psKernelC0MemoizedPairHash left right =
      psKernelExprPairHash left right := by
  let leftHash :=
    psKernelC0ExactHashWithMemo left PsKernelC0HashTrie.empty
  let rightHash :=
    psKernelC0ExactHashWithMemo right leftHash.2
  change
    (leftHash.1.value + rightHash.1.value) %
        psKernelCacheHashModulus =
      (psKernelExprHash left + psKernelExprHash right) %
        psKernelCacheHashModulus
  rw [leftHash.1.source, rightHash.1.source]

/-- Bounded, syntactic, non-semantic routing guard. Short spines retain
the original two exact hashes and avoid allocating a memo trie. -/
def psKernelC0PairHashMemoWorthwhile (left right : PsKernelExpr) : Bool :=
  psKernelExprGetAppNumArgs left >= 16 &&
  psKernelExprGetAppNumArgs right >= 16

/-- Source-equal adaptive pair hash, with the exact old arithmetic on
non-qualified shapes. No hash alone ever validates DefEq. -/
def psKernelC0AdaptivePairHash
    (left right : PsKernelExpr) : Nat :=
  match psKernelC0PairHashMemoWorthwhile left right with
  | true => psKernelC0MemoizedPairHash left right
  | false =>
      (psKernelExprHash left + psKernelExprHash right) %
        psKernelCacheHashModulus

theorem psKernelC0AdaptivePairHash_source
    (left right : PsKernelExpr) :
    psKernelC0AdaptivePairHash left right =
      psKernelExprPairHash left right := by
  cases h : psKernelC0PairHashMemoWorthwhile left right with
  | false =>
      simp [psKernelC0AdaptivePairHash, h, psKernelExprPairHash]
  | true =>
      simpa [psKernelC0AdaptivePairHash, h] using
        psKernelC0MemoizedPairHash_source left right

/-- Source pair hashing is commutative, even on memoized large DAGs;
    this is essential for the historical symmetric success-pair cache. -/
theorem psKernelC0AdaptivePairHash_comm
    (left right : PsKernelExpr) :
    psKernelC0AdaptivePairHash left right =
      psKernelC0AdaptivePairHash right left := by
  rw [psKernelC0AdaptivePairHash_source,
      psKernelC0AdaptivePairHash_source]
  change
    (psKernelExprHash left + psKernelExprHash right) %
        psKernelCacheHashModulus =
      (psKernelExprHash right + psKernelExprHash left) %
        psKernelCacheHashModulus
  exact congrArg (fun n : Nat => n % psKernelCacheHashModulus)
    (Nat.add_comm (psKernelExprHash left) (psKernelExprHash right))
