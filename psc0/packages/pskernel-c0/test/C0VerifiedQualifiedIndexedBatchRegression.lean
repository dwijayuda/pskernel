import Ps.KernelCore.Architecture.VerifiedQualifiedIndexedBatch

/-!
All three routes remain sound: certified exact-state memo hit, existing
independent checked-inference fragment, and authoritative negative/resource
fallback. Every route retains complete source type and returned checker state.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let original := psKernelC0IndexedSessionNew source
  let good : PsKernelExpr := .sort .zero
  let bad : PsKernelExpr := .bvar 0
  let some retained := psKernelC0IndexedSessionRetain original good
    | throw (IO.userError "qualified indexed: cannot retain good syntax")
  let some indexed := psKernelC0IndexedSessionRetain retained bad
    | throw (IO.userError "qualified indexed: cannot retain bad syntax")
  let some owned := psKernelC0CertifyStoreOwned indexed.store
    | throw (IO.userError "qualified indexed: canonical store declined")
  let owner := owned.val
  let some (_, goodId) := psKernelC0EncodeExpr indexed.store good
    | throw (IO.userError "qualified indexed: missing good root")
  let some (_, badId) := psKernelC0EncodeExpr indexed.store bad
    | throw (IO.userError "qualified indexed: missing bad root")
  let some goodHash := psKernelC0VerifiedIndexedHashSourceOracle owner goodId
    | throw (IO.userError "qualified indexed: no good source hash")
  let some badHash := psKernelC0VerifiedIndexedHashSourceOracle owner badId
    | throw (IO.userError "qualified indexed: no bad source hash")
  let g : PsKernelC0IndexedCheckedBatchRequest owner :=
    { id := goodId, hash := goodHash }
  let b : PsKernelC0IndexedCheckedBatchRequest owner :=
    { id := badId, hash := badHash }
  let tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner 4096 indexed.checker.context state :=
    fun state => psKernelC0IndexedCheckedReceiptTableEmpty
      owner 4096 indexed.checker.context state

  -- This simple source expression genuinely enters the independently
  -- qualified recursive checked-inference fragment, not just the fallback.
  if !(psKernelC0QualifiedDAGCandidateEligible good) ||
      (psKernelC0RecursiveCheckedWithFuel 4096
        indexed.checker.context indexed.checker.state good).isNone then
    throw (IO.userError "qualified indexed: independent fragment never ran")

  let _independentSource :
      psKernelC0IndexedMemoQualifiedStep owner 4096
          indexed.checker.context indexed.checker.state
          (tables indexed.checker.state) g =
        psKernelCheckerCheck 4096 indexed.checker.context
          indexed.checker.state goodHash.expr :=
    psKernelC0IndexedMemoQualifiedStep_source owner 4096
      indexed.checker.context indexed.checker.state
      (tables indexed.checker.state) g

  -- A REAL earlier full source-check receipt takes precedence when present.
  let (receipt, seeded) ← match psKernelC0IndexedCheckedReceiptTableCheck
      owner 4096 indexed.checker.context indexed.checker.state
      (tables indexed.checker.state) goodHash with
    | .error e => throw (IO.userError
        ("qualified indexed: source seed declined: " ++ e))
    | .ok answer => pure answer
  let _priorSource := psKernelC0IndexedCheckedReceiptHash_source
    goodHash receipt
  if !(psKernelC0IndexedCheckedReceiptTableLookup seeded goodId).isSome then
    throw (IO.userError "qualified indexed: no real checked cache hit")
  let _memoSource :
      psKernelC0IndexedMemoQualifiedStep owner 4096
          indexed.checker.context indexed.checker.state seeded g =
        psKernelCheckerCheck 4096 indexed.checker.context
          indexed.checker.state goodHash.expr :=
    psKernelC0IndexedMemoQualifiedStep_source owner 4096
      indexed.checker.context indexed.checker.state seeded g

  let requests := [g,g,g]
  let _wholeSource :
      psKernelC0IndexedSessionCheckMemoQualifiedBatch
          4096 indexed owner owned.property requests tables =
        psKernelC0IndexedSessionCheckSourceBatch
          4096 indexed owner requests :=
    psKernelC0IndexedSessionCheckMemoQualifiedBatch_source
      4096 indexed owner owned.property requests tables
  let (types, finalSession) ← match
      psKernelC0IndexedSessionCheckMemoQualifiedBatch
        4096 indexed owner owned.property requests tables with
    | .error e => throw (IO.userError
        ("qualified indexed: repeated source check failed: " ++ e))
    | .ok answer => pure answer
  if types.length != 3 ||
      finalSession.store.nodes.size != indexed.store.nodes.size then
    throw (IO.userError "qualified indexed: incorrect checked result list")

  let mixed := [g,b]
  let _negativeSource :
      psKernelC0IndexedSessionCheckMemoQualifiedBatch
          4096 indexed owner owned.property mixed tables =
        psKernelC0IndexedSessionCheckSourceBatch
          4096 indexed owner mixed :=
    psKernelC0IndexedSessionCheckMemoQualifiedBatch_source
      4096 indexed owner owned.property mixed tables
  match psKernelC0IndexedSessionCheckMemoQualifiedBatch
      4096 indexed owner owned.property mixed tables with
  | .ok _ => throw (IO.userError "qualified indexed: invalid tail admitted")
  | .error _ => pure ()

  let zeroTables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner 0 indexed.checker.context state :=
    fun state => psKernelC0IndexedCheckedReceiptTableEmpty
      owner 0 indexed.checker.context state
  let _zeroSource :
      psKernelC0IndexedSessionCheckMemoQualifiedBatch
          0 indexed owner owned.property [g] zeroTables =
        psKernelC0IndexedSessionCheckSourceBatch
          0 indexed owner [g] :=
    psKernelC0IndexedSessionCheckMemoQualifiedBatch_source
      0 indexed owner owned.property [g] zeroTables
  match psKernelC0IndexedSessionCheckMemoQualifiedBatch
      0 indexed owner owned.property [g] zeroTables with
  | .ok _ =>
      throw (IO.userError "qualified indexed: zero fuel accepted")
  | .error _ => pure ()

  IO.println "C0_INDEXED_MEMO_QUALIFIED source_exact=Lean source_state=Lean independent_recursive=pass checked_memo_hit=pass invalid_tail=declined zero_fuel=declined"
