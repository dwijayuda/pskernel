import Ps.KernelCore.Architecture.VerifiedIndexedCheckedBatch

/-!
Composable source-checked canonical-node batch: the checker transitions
are exact, errors are atomic, resource limits are not weakened, and
arbitrary source hash certificates cannot become typing judgments.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let initial := psKernelC0IndexedSessionNew source
  let good : PsKernelExpr := .sort .zero
  let bad : PsKernelExpr := .bvar 0
  let some withGood := psKernelC0IndexedSessionRetain initial good
    | throw (IO.userError "indexed batch: failed retaining good syntax")
  let some indexed := psKernelC0IndexedSessionRetain withGood bad
    | throw (IO.userError "indexed batch: failed retaining bad syntax")
  let some owned := psKernelC0CertifyStoreOwned indexed.store
    | throw (IO.userError "indexed batch: invalid canonical store")
  let owner := owned.val
  let some (_, goodId) := psKernelC0EncodeExpr indexed.store good
    | throw (IO.userError "indexed batch: no valid root ID")
  let some (_, badId) := psKernelC0EncodeExpr indexed.store bad
    | throw (IO.userError "indexed batch: no invalid root ID")
  let some goodHash := psKernelC0VerifiedIndexedHashSourceOracle owner goodId
    | throw (IO.userError "indexed batch: no hash proof for valid root")
  let some badHash := psKernelC0VerifiedIndexedHashSourceOracle owner badId
    | throw (IO.userError "indexed batch: no hash proof for invalid root")
  let checked : PsKernelC0IndexedCheckedBatchRequest owner :=
    { id := goodId, hash := goodHash }
  let invalid : PsKernelC0IndexedCheckedBatchRequest owner :=
    { id := badId, hash := badHash }
  let tables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner 4096 indexed.checker.context state :=
    fun state => psKernelC0IndexedCheckedReceiptTableEmpty
      owner 4096 indexed.checker.context state

  let requests := [checked, checked, checked]
  let _exactFold :
      psKernelC0IndexedCheckedBatchVerified owner 4096
          indexed.checker.context tables requests indexed.checker.state =
        psKernelC0IndexedCheckedBatchSource owner 4096
          indexed.checker.context requests indexed.checker.state :=
    psKernelC0IndexedCheckedBatchVerified_source
      owner 4096 indexed.checker.context tables requests indexed.checker.state
  let _exactSession :
      psKernelC0IndexedSessionCheckVerifiedBatch
          4096 indexed owner owned.property requests tables =
        psKernelC0IndexedSessionCheckSourceBatch
          4096 indexed owner requests :=
    psKernelC0IndexedSessionCheckVerifiedBatch_source
      4096 indexed owner owned.property requests tables
  let (types, finalSession) ← match psKernelC0IndexedSessionCheckVerifiedBatch
      4096 indexed owner owned.property requests tables with
    | .error e => throw (IO.userError
        ("indexed batch: repeated fully checked Sort declined: " ++ e))
    | .ok outcome => pure outcome
  if types.length != 3 ||
      finalSession.store.nodes.size != indexed.store.nodes.size then
    throw (IO.userError "indexed batch: lost type sequence or syntax store")

  -- A valid head followed by an invalid proof must atomically fail, not
  -- publish the checked head's final state as a successful batch.
  let mixed := [checked, invalid]
  let _mixedSource :
      psKernelC0IndexedSessionCheckVerifiedBatch
          4096 indexed owner owned.property mixed tables =
        psKernelC0IndexedSessionCheckSourceBatch
          4096 indexed owner mixed :=
    psKernelC0IndexedSessionCheckVerifiedBatch_source
      4096 indexed owner owned.property mixed tables
  match psKernelC0IndexedSessionCheckVerifiedBatch
      4096 indexed owner owned.property mixed tables with
  | .ok _ => throw (IO.userError "indexed batch: invalid late root accepted")
  | .error _ => pure ()

  let zeroTables : (state : PsKernelCheckerState) →
      PsKernelC0IndexedCheckedReceiptTable
        owner 0 indexed.checker.context state :=
    fun state => psKernelC0IndexedCheckedReceiptTableEmpty
      owner 0 indexed.checker.context state
  let _fuelProof :
      psKernelC0IndexedSessionCheckVerifiedBatch
          0 indexed owner owned.property [checked] zeroTables =
        psKernelC0IndexedSessionCheckSourceBatch
          0 indexed owner [checked] :=
    psKernelC0IndexedSessionCheckVerifiedBatch_source
      0 indexed owner owned.property [checked] zeroTables
  match psKernelC0IndexedSessionCheckVerifiedBatch
      0 indexed owner owned.property [checked] zeroTables with
  | .ok _ => throw (IO.userError "indexed batch: exhausted fuel admitted")
  | .error _ => pure ()

  IO.println "C0_VERIFIED_INDEXED_BATCH state_thread=Lean exact_source=Lean complete_except=Lean repeated=3 malformed_tail=declined zero_fuel=declined publication=atomic"
