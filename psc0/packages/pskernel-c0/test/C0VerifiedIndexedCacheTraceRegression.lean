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
  -- These synthetic write commands are a non-admitting MODEL only.
  -- Their results must never become an audited source-checker session:
  -- source-equivalent insertion does not prove cached typing legitimacy.
  let modelState := psKernelC0VerifiedIndexedCacheTraceRun
    commands indexed.checker.state
  let _completeSourceState :
      modelState =
        psKernelC0VerifiedIndexedCacheTraceSource
          commands indexed.checker.state :=
    psKernelC0VerifiedIndexedCacheTraceRun_source
      commands indexed.checker.state

  -- A real (unmodified) indexed session permits ONLY read-only hash hints.
  let originalRead := psKernelC0VerifiedIndexedCacheReadSession
    indexed owner owned.property .checkedInfer checked
  let _readSource :
      originalRead =
        psKernelExprMapGet indexed.checker.state.checkedInfer checked.expr :=
    psKernelC0VerifiedIndexedCacheReadSession_source
      indexed owner owned.property .checkedInfer checked
  if originalRead.isSome then
    throw (IO.userError "indexed trace: observer invented checked type")
  let originalPair := psKernelC0VerifiedIndexedPairReadSession
    indexed owner owned.property .success checked fn
  let _pairSource :
      originalPair =
        psKernelExprPairSetContains
          indexed.checker.state.success checked.expr fn.expr :=
    psKernelC0VerifiedIndexedPairReadSession_source
      indexed owner owned.property .success checked fn
  if originalPair then
    throw (IO.userError "indexed trace: observer invented DefEq proof")

  let routeNames : List PsKernelC0IndexedExprCacheRoute :=
    [.checkedInfer, .inferOnly, .whnfCore, .whnf, .unfold]
  for route in routeNames do
    let hit := psKernelC0VerifiedIndexedStateCacheGet
      route modelState checked
    if !hit.isSome then
      throw (IO.userError "indexed trace: valid source expression cache miss")
    let _source :
        hit = psKernelExprMapGet
          (psKernelC0IndexedExprCacheSelect route modelState)
          checked.expr :=
      psKernelC0VerifiedIndexedStateCacheGet_source
        route modelState checked

  if !psKernelC0VerifiedIndexedStatePairContains
      .success modelState checked fn ||
      !psKernelC0VerifiedIndexedStatePairContains
        .success modelState fn checked then
    throw (IO.userError "indexed trace: symmetric DefEq cache membership lost")
  if !psKernelC0VerifiedIndexedStatePairContains
      .failure modelState checked arg then
    throw (IO.userError "indexed trace: failure-cache entry lost")
  if psKernelC0VerifiedIndexedStatePairContains
      .failure modelState checked fn then
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
  IO.println "C0_VERIFIED_INDEXED_CACHE_TRACE model_updates=8 source_cache_transition=Lean read_only_session=pass no_unchecked_admission=yes all_slots=pass defeq_symmetry=pass forged_store=declined bad_id=declined"
