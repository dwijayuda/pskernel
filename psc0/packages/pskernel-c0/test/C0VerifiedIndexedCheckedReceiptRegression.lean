import Ps.KernelCore.Architecture.VerifiedIndexedCheckedReceipt
import Ps.KernelCore.Checker.Session

/-!
Test exact source checked memo reuse without installing arbitrary inferred
values into a trusted source checker state or changing its admission rules.
-/

def main : IO Unit := do
  let expr : PsKernelExpr := .sort .zero
  let some (store, id) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty expr
    | throw (IO.userError "checked indexed memo: Sort encoding failed")
  let some certifiedRoot := psKernelC0CertifyRoot store id
    | throw (IO.userError "checked indexed memo: canonical store declined")
  let owner := certifiedRoot.owner
  let some hash := psKernelC0VerifiedIndexedHashSourceOracle owner id
    | throw (IO.userError "checked indexed memo: source hash unavailable")
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let empty := psKernelC0IndexedCheckedReceiptTableEmpty
    owner 4096 source.context source.state
  if empty.entries.size != owner.store.nodes.size then
    throw (IO.userError "checked indexed memo: wrong initial table size")

  let (fresh, table) ← match psKernelC0IndexedCheckedReceiptTableCheck
      owner 4096 source.context source.state empty hash with
    | .ok pair => pure pair
    | .error e => throw (IO.userError
        ("checked indexed memo: valid miss rejected: " ++ e))
  let _freshSource :
      psKernelCheckerCheck 4096 source.context source.state hash.expr =
        .ok (fresh.val.inferredType, fresh.val.finalState) :=
    psKernelC0IndexedCheckedReceiptHash_source hash fresh
  if !(psKernelC0IndexedCheckedReceiptTableLookup table id).isSome then
    throw (IO.userError "checked indexed memo: checked miss not retained")

  let (hit, identicalTable) ← match psKernelC0IndexedCheckedReceiptTableCheck
      owner 4096 source.context source.state table hash with
    | .ok pair => pure pair
    | .error e => throw (IO.userError
        ("checked indexed memo: identical hit rejected: " ++ e))
  let _hitSource :
      psKernelCheckerCheck 4096 source.context source.state hash.expr =
        .ok (hit.val.inferredType, hit.val.finalState) :=
    psKernelC0IndexedCheckedReceiptHash_source hash hit
  let sameId : fresh.val.rootId = hit.val.rootId := by
    calc
      fresh.val.rootId = id := fresh.property
      _ = hit.val.rootId := hit.property.symm
  let unique := psKernelC0ScopedCheckedDAGSameRoot fresh.val hit.val sameId
  let _exactType : fresh.val.inferredType = hit.val.inferredType := unique.2.1
  let _exactState : fresh.val.finalState = hit.val.finalState := unique.2.2
  if identicalTable.entries.size != table.entries.size then
    throw (IO.userError "checked indexed memo: hit changed table size")

  -- Deliberate table-position corruption may not become a false checked hit.
  let misplaced : PsKernelC0IndexedCheckedReceiptTable
      owner 4096 source.context source.state :=
    { entries := Array.replicate (id + 3) (some fresh.val) }
  if (psKernelC0IndexedCheckedReceiptTableLookup
      misplaced (id + 1)).isSome then
    throw (IO.userError "checked indexed memo: wrong-root hit accepted")
  if (psKernelExprMapGet source.state.checkedInfer expr).isSome then
    throw (IO.userError "checked indexed memo: source state was modified")

  let some (badStore, badId) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty (.bvar 0)
    | throw (IO.userError "checked indexed memo: bvar encoding failed")
  let some badRoot := psKernelC0CertifyRoot badStore badId
    | throw (IO.userError "checked indexed memo: bvar store not certified")
  let some badHash :=
      psKernelC0VerifiedIndexedHashSourceOracle badRoot.owner badId
    | throw (IO.userError "checked indexed memo: bvar source hash failed")
  let badEmpty := psKernelC0IndexedCheckedReceiptTableEmpty
    badRoot.owner 4096 source.context source.state
  match psKernelC0IndexedCheckedReceiptTableCheck
      badRoot.owner 4096 source.context source.state badEmpty badHash with
  | .ok _ => throw (IO.userError "checked indexed memo: loose bvar accepted")
  | .error _ => pure ()

  let zeroFuel := psKernelC0IndexedCheckedReceiptTableEmpty
    owner 0 source.context source.state
  match psKernelC0IndexedCheckedReceiptTableCheck
      owner 0 source.context source.state zeroFuel hash with
  | .ok _ => throw (IO.userError "checked indexed memo: zero fuel accepted")
  | .error _ => pure ()
  IO.println "C0_INDEXED_CHECKED_RECEIPT hit=source_checked exact_result_and_state=Lean wrong_id=declined invalid=declined zero_fuel=declined no_unchecked_state_write=pass"
