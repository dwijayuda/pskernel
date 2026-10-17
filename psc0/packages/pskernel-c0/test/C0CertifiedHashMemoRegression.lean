import Ps.KernelCore.Runtime.Acceleration.CertifiedHashMemo

/-!
Exact source hash conformance. The large shared DAG is intentionally
checked against a closed-form recurrence, never expanded by the old
exponential source-hash oracle. Lean separately proves the equation for
every source expression in psKernelC0ExactMemoizedExprHash_source.
-/

def c0HashMemoMakeShared (base : PsKernelExpr) (depth : Nat) : PsKernelExpr :=
  (List.range depth).foldl (fun x (_ : Nat) => .app x x) base

def c0HashMemoExpected (base : Nat) (depth : Nat) : Nat :=
  (List.range depth).foldl
    (fun x (_ : Nat) => psKernelCacheMix (psKernelCacheMix 26 x) x)
    base

def c0HashMemoCheck (expr : PsKernelExpr) : IO Unit := do
  let source := psKernelExprHash expr
  let cached := psKernelC0ExactMemoizedExprHash expr
  let _eq : psKernelC0ExactMemoizedExprHash expr =
      psKernelExprHash expr :=
    psKernelC0ExactMemoizedExprHash_source expr
  if cached != source then
    throw (IO.userError "certified memo hash differs from historical exact source hash")

def main : IO Unit := do
  let one : PsKernelName := .str .anonymous "one"
  let two : PsKernelName := .str .anonymous "two"
  let type : PsKernelExpr := .sort (.succ .zero)
  let f : PsKernelExpr := .fvar one
  let x : PsKernelExpr := .bvar 0
  let base : PsKernelExpr := .app (.const one [.zero]) (.lit (.nat 2))
  -- Cheap leaf hashes are already the original source formula.
  -- The optimized worker must return that proof WITHOUT extending its
  -- operation-local trie with an unnecessary leaf memo entry.
  let bv : PsKernelExpr := .bvar 13
  let natLeaf : PsKernelExpr := .lit (.nat 2048)
  let (bvCert, bvMemo) := psKernelC0ExactHashWithMemo bv (∅ : PsKernelC0ExactHashMemo)
  let (natCert, natMemo) := psKernelC0ExactHashWithMemo natLeaf (∅ : PsKernelC0ExactHashMemo)
  let _bvSource : bvCert.value = psKernelExprHash bv := bvCert.source
  let _natSource : natCert.value = psKernelExprHash natLeaf := natCert.source
  if bvCert.value != psKernelExprHash bv ||
      natCert.value != psKernelExprHash natLeaf then
    throw (IO.userError "source-certified direct leaf hash mismatch")
  if !bvMemo.isEmpty || !natMemo.isEmpty then
    throw (IO.userError "cheap leaf hash unnecessarily mutated memo")
  IO.println "C0_CERTIFIED_HASH_MEMO direct_bvar_nat_leaves=source_exact memo_unchanged=true"

  let all : List PsKernelExpr := [
    .bvar 0, .bvar 13, .fvar one, .mvar one,
    .sort .zero, .sort (.max .zero (.succ .zero)),
    .const two [.zero, .succ .zero],
    .lit (.nat 7), .lit (.str "é"),
    .app f base,
    .lam one type (.app x f) .default,
    .forallE one type (.app f x) .implicit,
    .letE two type f (.app x x) false,
    .letE one type (.lit (.nat 3)) f true,
    .mdata 17 (.app f (.mdata 11 base)),
    .proj two 1 (.const two []),
    c0HashMemoMakeShared base 12,
    c0HashMemoMakeShared (.app base f) 15,
    .app (c0HashMemoMakeShared base 11)
         (c0HashMemoMakeShared (.mdata 3 base) 11)
  ]
  for expression in all do
    c0HashMemoCheck expression
    -- The memo hash index can have ALL keys colliding; it still cannot
    -- return an incorrect source hash or grant an unverified cache fact.
    let pureSource := psKernelExprHash expression
    let colliding := (psKernelC0ExactHashWithMemoWithHash
      (fun _ => 0) expression (∅ : PsKernelC0ExactHashMemo)).1
    if colliding.value != pureSource then
      throw (IO.userError "all-collision hash map changed source exact hash")

  -- 26 shared parent levels represent over 134 million tree nodes.
  -- Computing the *historical* pure hash here would expand the full
  -- tree, so compare the memo result to an independent numerical fold.
  let depth := 26
  let big := c0HashMemoMakeShared base depth
  let expected := c0HashMemoExpected (psKernelExprHash base) depth
  let before ← IO.monoNanosNow
  let memoized := psKernelC0ExactMemoizedExprHash big
  let after ← IO.monoNanosNow
  if memoized != expected then
    throw (IO.userError "large shared hash memo differs from exact hash recurrence")
  IO.println s!"C0_CERTIFIED_HASH_MEMO small_source=pass arbitrary_hash=Lean_proved all_collision=pass shared_depth={depth} memo_ms={(after - before)/1000000} exact_source_proof=Lean"
