import Ps.KernelCore.Architecture.VerifiedIndexedCacheTrace

/-!
Composition-level regression for all seven source-equivalent cache slots.
An indexed session retains one certified canonical immutable owner while
source checker cache state evolves by exact source update operations.
Nothing in the trace authorizes a proof, a type or DefEq acceptance.
-/

def main : IO Unit := do
  let fnExpr : PsKernelExpr := .sort .zero
  let argExpr : PsKernelExpr := .lit (.nat 7)
  let root : PsKernelExpr := .app fnExpr argExpr
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let initial := psKernelC0IndexedSessionNew source
  let some indexed := psKernelC0IndexedSessionRetain initial root
    | throw (IO.userError "indexed trace: valid root syntax not retained")
  let some owned := psKernelC0CertifyStoreOwned indexed.store
    | throw (IO.userError "indexed trace: canonical session owner not certified")
  let owner := owned.val
  let some (_, fnId) := psKernelC0EncodeExpr indexed.store fnExpr
    | throw (IO.userError "indexed trace: missing function handle")
  let some (_, argId) := psKernelC0EncodeExpr indexed.store argExpr
    | throw (IO.userError "indexed trace: missing argument handle")
  let some (_, rootId) := psKernelC0EncodeExpr indexed.store root
    | throw (IO.userError "indexed trace: missing application handle")
  let some fn := psKernelC0VerifiedIndexedHashSourceOracle owner fnId
    | throw (IO.userError "indexed trace: function proof not certified")
  let some arg := psKernelC0VerifiedIndexedHashSourceOracle owner argId
    | throw (IO.userError "indexed trace: argument proof not certified")
  let some checked := psKernelC0VerifiedIndexedHashAppTry
      owner rootId fnId argId fn arg
    | throw (IO.userError "indexed trace: compositional root hash declined")

  let ty : PsKernelExpr := .sort (.succ .zero)
  let commands : List (PsKernelC0VerifiedIndexedCacheCommand owner) := [
    .exprInsert .checkedInfer checked ty,
    .exprInsert .inferOnly checked ty,
    .exprInsert .whnfCore checked ty,
    .exprInsert .whnf checked ty,
    .exprInsert .unfold checked ty,
    .pairInsert .success checked fn,
    .pairInsert .failure checked arg,
    .pairInsert .success fn checked
  ]
  let result := psKernelC0VerifiedIndexedCacheTraceSession
    indexed owner owned.property commands
  let updated := result.val
  let _unchangedStore : updated.store = indexed.store := result.property.1
  let _unchangedContext :
      updated.checker.context = indexed.checker.context :=
    result.property.2.1
  let _completeSourceState :
      updated.checker.state =
        psKernelC0VerifiedIndexedCacheTraceSource
          commands indexed.checker.state :=
    result.property.2.2

  let routeNames : List PsKernelC0IndexedExprCacheRoute :=
    [.checkedInfer, .inferOnly, .whnfCore, .whnf, .unfold]
  for route in routeNames do
    let hit := psKernelC0VerifiedIndexedStateCacheGet
      route updated.checker.state checked
    if !hit.isSome then
      throw (IO.userError "indexed trace: valid source expression cache miss")
    let _source :
        hit = psKernelExprMapGet
          (psKernelC0IndexedExprCacheSelect route updated.checker.state)
          checked.expr :=
      psKernelC0VerifiedIndexedStateCacheGet_source
        route updated.checker.state checked

  if !psKernelC0VerifiedIndexedStatePairContains
      .success updated.checker.state checked fn ||
      !psKernelC0VerifiedIndexedStatePairContains
        .success updated.checker.state fn checked then
    throw (IO.userError "indexed trace: symmetric DefEq cache membership lost")
  if !psKernelC0VerifiedIndexedStatePairContains
      .failure updated.checker.state checked arg then
    throw (IO.userError "indexed trace: failure-cache entry lost")
  if psKernelC0VerifiedIndexedStatePairContains
      .failure updated.checker.state checked fn then
    throw (IO.userError "indexed trace: failure-cache member invented")

  let _rawProof :
      psKernelC0VerifiedIndexedCacheTraceRun commands indexed.checker.state =
        psKernelC0VerifiedIndexedCacheTraceSource commands
          indexed.checker.state :=
    psKernelC0VerifiedIndexedCacheTraceRun_source commands indexed.checker.state
  let forged := { indexed.store with index := PsKernelC0HashTrie.empty }
  if (psKernelC0CertifyStoreOwned forged).isSome then
    throw (IO.userError "indexed trace: forged source cache store certified")
  if (psKernelC0VerifiedIndexedHashSourceOracle
      owner (rootId + 51)).isSome then
    throw (IO.userError "indexed trace: missing handle supplied source hash")
  IO.println "C0_VERIFIED_INDEXED_CACHE_TRACE ordered_cache_updates=8 full_source_state=Lean all_slots=pass defeq_symmetry=pass forged_store=declined bad_id=declined"
