import Ps.KernelCore.Runtime.Acceleration.Cache

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

deriving instance DecidableEq for PsKernelName
deriving instance DecidableEq for PsKernelLevel
deriving instance DecidableEq for PsKernelLiteral
deriving instance DecidableEq for PsKernelBinderInfo
deriving instance DecidableEq for PsKernelExpr

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
      match withPtrEqDecEq expr entry.expr (fun _ => inferInstance) with
      | .isTrue h =>
          some {
            value := entry.checkedHash.value
            source := entry.checkedHash.source.trans
              (congrArg psKernelExprHash h.symm)
          }
      | .isFalse _ => psKernelC0HashMemoFind expr rest

private def psKernelC0HashMemoLookup
    (expr : PsKernelExpr)
    (memo : PsKernelC0ExactHashMemo) :
    Option (PsKernelC0ExactHash expr) :=
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
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix 21 n, rfl⟩
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
      | .lit v =>
          psKernelC0ExactHashStore memo
            ⟨psKernelCacheMix 30 (psKernelCacheLiteralHash v), rfl⟩

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
