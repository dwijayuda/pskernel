import Ps.KernelCore.Architecture.VerifiedIndexedCacheState

/-!
An actual checker-state regression for certified, O(1) indexed hash hints.
The five expression caches and both DefEq pair caches are exercised with
real promoted radix buckets, colliding but structurally different terms,
symmetric pair keys, absent IDs and invalid canonical metadata.

Lean separately proves the whole source checker-state update equation.
This test never uses a cache membership claim to accept a proof or term.
-/

def main : IO Unit := do
  let fnExpr : PsKernelExpr := .sort .zero
  let leftArg : PsKernelExpr := .lit (.nat 7)
  let sameHashArg : PsKernelExpr :=
    .lit (.nat (7 + psKernelCacheHashModulus))
  let rootExpr : PsKernelExpr := .app fnExpr leftArg
  let collisionExpr : PsKernelExpr := .app fnExpr sameHashArg

  let some (s1, fnId) := psKernelC0EncodeExpr
      psKernelC0StoreEmpty fnExpr
    | throw (IO.userError "indexed state: function encode failed")
  let some (s2, leftId) := psKernelC0EncodeExpr s1 leftArg
    | throw (IO.userError "indexed state: argument encode failed")
  let some (s3, rootId) := psKernelC0EncodeExpr s2 rootExpr
    | throw (IO.userError "indexed state: first application encode failed")
  let some (s4, collisionArgId) := psKernelC0EncodeExpr s3 sameHashArg
    | throw (IO.userError "indexed state: colliding argument encode failed")
  let some (store, collisionId) := psKernelC0EncodeExpr s4 collisionExpr
    | throw (IO.userError "indexed state: colliding application encode failed")
  let some owner := psKernelC0CertifyStore store
    | throw (IO.userError "indexed state: canonical store declined")
  let some fn := psKernelC0VerifiedIndexedHashSourceOracle owner fnId
    | throw (IO.userError "indexed state: function hash not certified")
  let some left := psKernelC0VerifiedIndexedHashSourceOracle owner leftId
    | throw (IO.userError "indexed state: first argument hash not certified")
  let some right :=
      psKernelC0VerifiedIndexedHashSourceOracle owner collisionArgId
    | throw (IO.userError "indexed state: colliding argument not certified")
  let some first := psKernelC0VerifiedIndexedHashAppTry
      owner rootId fnId leftId fn left
    | throw (IO.userError "indexed state: first app not source-certified")
  let some collision := psKernelC0VerifiedIndexedHashAppTry
      owner collisionId fnId collisionArgId fn right
    | throw (IO.userError "indexed state: second app not source-certified")

  if psKernelExprHash rootExpr != psKernelExprHash collisionExpr ||
      psKernelExprEq rootExpr collisionExpr then
    throw (IO.userError "indexed state: negative control is not an exact bucket collision")

  let sourceMap := (List.range 14).foldl
    (fun memo (n : Nat) =>
      psKernelExprMapInsert memo (.lit (.nat n)) (.sort .zero))
    psKernelExprMapEmpty
  let ty : PsKernelExpr := .sort (.succ .zero)
  let routes : List PsKernelC0IndexedExprCacheRoute :=
    [.checkedInfer, .inferOnly, .whnfCore, .whnf, .unfold]
  for route in routes do
    let seeded := psKernelC0IndexedExprCacheReplace route
      psKernelCheckerStateEmpty sourceMap
    let updated := psKernelC0VerifiedIndexedStateCacheInsert
      route seeded first ty
    let _sourceInsert :
        updated =
          psKernelC0IndexedExprCacheReplace route seeded
            (psKernelExprMapInsert
              (psKernelC0IndexedExprCacheSelect route seeded)
              first.expr ty) :=
      psKernelC0VerifiedIndexedStateCacheInsert_source
        route seeded first ty
    let _sourceLookup :
        psKernelC0VerifiedIndexedStateCacheGet route updated first =
          psKernelExprMapGet
            (psKernelC0IndexedExprCacheSelect route updated)
            first.expr :=
      psKernelC0VerifiedIndexedStateCacheGet_source route updated first
    if !(psKernelC0VerifiedIndexedStateCacheGet route updated first).isSome then
      throw (IO.userError "indexed state: source expression cache hit lost")
    if (psKernelC0VerifiedIndexedStateCacheGet
        route updated collision).isSome then
      throw (IO.userError "indexed state: hash collision forged a source cache hit")
    if !(psKernelC0VerifiedIndexedStateCacheGet
        route seeded first).isNone then
      throw (IO.userError "indexed state: invented pre-insertion cache hit")

  let seedPairs := (List.range 14).foldl
    (fun pairs (n : Nat) =>
      psKernelExprPairSetInsert pairs (.lit (.nat n)) fnExpr)
    psKernelExprPairSetEmpty
  let pairRoutes : List PsKernelC0IndexedPairCacheRoute :=
    [.success, .failure]
  for route in pairRoutes do
    let seeded := psKernelC0IndexedPairCacheReplace route
      psKernelCheckerStateEmpty seedPairs
    let updated := psKernelC0VerifiedIndexedStatePairInsert
      route seeded first fn
    let _sourceInsert :
        updated =
          psKernelC0IndexedPairCacheReplace route seeded
            (psKernelExprPairSetInsert
              (psKernelC0IndexedPairCacheSelect route seeded)
              first.expr fn.expr) :=
      psKernelC0VerifiedIndexedStatePairInsert_source
        route seeded first fn
    let _sourceContains :
        psKernelC0VerifiedIndexedStatePairContains route updated first fn =
          psKernelExprPairSetContains
            (psKernelC0IndexedPairCacheSelect route updated)
            first.expr fn.expr :=
      psKernelC0VerifiedIndexedStatePairContains_source
        route updated first fn
    if !psKernelC0VerifiedIndexedStatePairContains route updated first fn ||
        !psKernelC0VerifiedIndexedStatePairContains route updated fn first then
      throw (IO.userError "indexed state: symmetric DefEq pair membership lost")
    if psKernelC0VerifiedIndexedStatePairContains
        route updated collision fn then
      throw (IO.userError "indexed state: colliding pair forged DefEq membership")
    if psKernelC0VerifiedIndexedStatePairContains
        route seeded first fn then
      throw (IO.userError "indexed state: invented pre-insertion DefEq membership")
    let repeated := psKernelC0VerifiedIndexedStatePairInsert
      route updated first fn
    let _sourceRepeat :
        repeated =
          psKernelC0IndexedPairCacheReplace route updated
            (psKernelExprPairSetInsert
              (psKernelC0IndexedPairCacheSelect route updated)
              first.expr fn.expr) :=
      psKernelC0VerifiedIndexedStatePairInsert_source
        route updated first fn

  if (psKernelC0VerifiedIndexedHashSourceOracle
      owner (collisionId + 200)).isSome then
    throw (IO.userError "indexed state: source hash certified a missing ID")
  let corrupted := { store with index := PsKernelC0HashTrie.empty }
  if (psKernelC0CertifyStore corrupted).isSome then
    throw (IO.userError "indexed state: malformed canonical index accepted")
  IO.println "C0_VERIFIED_INDEXED_STATE_CACHE five_expr_caches=source_exact two_defeq_caches=source_exact collision=declined symmetry=pass wrong_handle=declined forged_store=declined"
