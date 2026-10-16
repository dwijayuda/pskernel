import Ps.KernelCore.Architecture.CertifiedDefEqPairHash

/-!
Diff the checked unordered pair-cache key against the unchanged original
source over constructor variants and both operand orders; independently
check the large shared-DAG recurrence without invoking exponential source.
-/
def c0PairShared (seed : PsKernelExpr) (count : Nat) : PsKernelExpr :=
  (List.range count).foldl (fun e (_ : Nat) => .app e e) seed

def c0PairSample : List PsKernelExpr :=
  let n : PsKernelName := .str .anonymous "sample"
  let z : PsKernelExpr := .sort .zero
  let x : PsKernelExpr := .bvar 0
  let c : PsKernelExpr := .const n [.zero]
  [z, x, c, .fvar n, .lit (.nat 7),
   .app c z, .app (.app c x) (.app c x),
   .lam n z x .default, .forallE n z (.app c x) .implicit,
   .mdata 3 (.app x c), .proj n 2 (.app c z),
   c0PairShared (.app c z) 7, c0PairShared x 17]

def main : IO Unit := do
  let examples := c0PairSample
  for a in examples do
    for b in examples do
      let native := psKernelExprPairHash a b
      let memo := psKernelC0MemoizedPairHash a b
      let adaptive := psKernelC0AdaptivePairHash a b
      let _proofMemo :
          psKernelC0MemoizedPairHash a b =
            psKernelExprPairHash a b :=
        psKernelC0MemoizedPairHash_source a b
      let _proofAdaptive :
          psKernelC0AdaptivePairHash a b =
            psKernelExprPairHash a b :=
        psKernelC0AdaptivePairHash_source a b
      let _comm :
          psKernelC0AdaptivePairHash a b =
            psKernelC0AdaptivePairHash b a :=
        psKernelC0AdaptivePairHash_comm a b
      if native != memo || native != adaptive ||
          adaptive != psKernelC0AdaptivePairHash b a then
        throw (IO.userError "C0 pair hash memo disagrees with source key or symmetry")
  let base : PsKernelExpr := .app (.lit (.nat 1)) (.bvar 0)
  let large := c0PairShared base 26
  if !psKernelC0PairHashMemoWorthwhile large large then
    throw (IO.userError "C0 large shared pair candidate did not select memo")
  let start ← IO.monoNanosNow
  let fused := psKernelC0AdaptivePairHash large large
  let finish ← IO.monoNanosNow
  let hash := psKernelC0ExactMemoizedExprHash large
  let expected := (hash + hash) % psKernelCacheHashModulus
  if fused != expected then
    throw (IO.userError "C0 shared pair hash disagrees with exact source recurrence")
  IO.println s!"C0_CERTIFIED_PAIR_HASH all_constructors=pass symmetric=pass source_proof=Lean shared_depth=26 elapsed_ms={(finish-start)/1000000}"
