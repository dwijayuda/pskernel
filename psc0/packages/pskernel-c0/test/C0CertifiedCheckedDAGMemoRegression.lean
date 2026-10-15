import Ps.KernelCore.Architecture.CertifiedCheckedDAGMemo
import Ps.KernelCore.Checker.Session

/-!
Exact checked DAG receipt regression. This is NOT a proof-checker shortcut:
certificate construction runs the authoritative source checker. Every result
carries Lean-checked equality to the exact source judgment at its initial
state, environment, local context, and fuel.
-/

def main : IO Unit := do
  let sortZero : PsKernelExpr := .sort .zero
  let some (store, id) := psKernelC0EncodeExpr psKernelC0StoreEmpty sortZero
    | throw (IO.userError "certified DAG: failed encoding valid expression")
  let some certifiedRoot := psKernelC0CertifyRoot store id
    | throw (IO.userError "certified DAG: valid canonical root rejected")
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let receipt ← match psKernelC0CaptureCheckedDAGRoot
      4096 session.context session.state certifiedRoot with
    | .ok r => pure r
    | .error e => throw (IO.userError
        ("certified DAG: source rejected valid Sort: " ++ e))
  let _exactSource :
      psKernelCheckerCheck 4096 session.context session.state
          receipt.root.expression =
        .ok (receipt.inferredType, receipt.finalState) :=
    psKernelC0CertifiedCheckedDAGRoot_source receipt
  let _wf : psKernelC0StoreWF receipt.root.owner.store :=
    psKernelC0CertifiedCheckedDAGRoot_storeWF receipt
  let _rootEq :
      psKernelC0DecodeExpr receipt.root.owner.store receipt.root.root =
        some receipt.root.expression :=
    psKernelC0CertifiedCheckedDAGRoot_exactRead receipt
  if !psKernelExprEqual receipt.inferredType (.sort (.succ .zero)) then
    throw (IO.userError "certified DAG: incorrect source inferred type")

  -- A store certificate is only syntax: it MUST NOT make a loose bound
  -- variable a checked, admitted term.
  let some (badStore, badId) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty (.bvar 0)
    | throw (IO.userError "certified DAG: bad syntax encoding declined")
  let some badRoot := psKernelC0CertifyRoot badStore badId
    | throw (IO.userError "certified DAG: canonical raw bvar not certifiable")
  match psKernelC0CaptureCheckedDAGRoot
      4096 session.context session.state badRoot with
  | .ok _ =>
      throw (IO.userError "certified DAG: source-invalid bvar accepted")
  | .error _ => pure ()
  -- The memo is indexed by an EXACT Nat ID under one certified store and
  -- a type-level fixed fuel/context/initial-state. A hit cannot fabricate
  -- a different root, silently update the state, or reuse infer-only data.
  let owner := certifiedRoot.owner
  let initialMemo : PsKernelC0ScopedCheckedDAGMemo
      owner 4096 session.context session.state := []
  let (fresh, memo) ← match psKernelC0ScopedCheckedDAGCheck
      owner 4096 session.context session.state initialMemo id with
    | .ok pair => pure pair
    | .error e => throw (IO.userError
        ("scoped checked DAG: valid miss rejected: " ++ e))
  let _checkedId : fresh.val.rootId = id := fresh.property
  let _freshType :
      psKernelCheckerCheck 4096 session.context session.state
          fresh.val.expression =
        .ok (fresh.val.inferredType, fresh.val.finalState) :=
    psKernelC0ScopedCheckedDAGReceipt_source fresh.val
  let _freshRead :
      psKernelC0DecodeExpr owner.store fresh.val.rootId =
        some fresh.val.expression :=
    psKernelC0ScopedCheckedDAGReceipt_readback fresh.val
  if memo.length != 1 then
    throw (IO.userError "scoped checked DAG: miss did not publish exactly one receipt")
  let (again, originalMemo) ← match psKernelC0ScopedCheckedDAGCheck
      owner 4096 session.context session.state memo id with
    | .ok pair => pure pair
    | .error e => throw (IO.userError
        ("scoped checked DAG: identical hit rejected: " ++ e))
  let _hitId : again.val.rootId = id := again.property
  let _hitType :
      psKernelCheckerCheck 4096 session.context session.state
          again.val.expression =
        .ok (again.val.inferredType, again.val.finalState) :=
    psKernelC0ScopedCheckedDAGReceipt_source again.val
  let sameId : fresh.val.rootId = again.val.rootId := by
    calc
      fresh.val.rootId = id := fresh.property
      _ = again.val.rootId := again.property.symm
  let sourceUnique := psKernelC0ScopedCheckedDAGSameRoot
    fresh.val again.val sameId
  let _uniqueExpr : fresh.val.expression = again.val.expression :=
    sourceUnique.1
  let _uniqueType : fresh.val.inferredType = again.val.inferredType :=
    sourceUnique.2.1
  let _uniqueState : fresh.val.finalState = again.val.finalState :=
    sourceUnique.2.2
  if originalMemo.length != 1 then
    throw (IO.userError "scoped checked DAG: cache hit changed immutable entries")
  if !psKernelExprEqual fresh.val.inferredType again.val.inferredType then
    throw (IO.userError "scoped checked DAG: cached checked result changed")
  -- A raw valid store node is still rejected by source typing when its
  -- expression is ill-formed in the exact empty local context.
  let badOwner := badRoot.owner
  match psKernelC0ScopedCheckedDAGCheck
      badOwner 4096 session.context session.state [] badId with
  | .ok _ =>
      throw (IO.userError "scoped checked DAG: invalid root accepted")
  | .error _ => pure ()
  -- Resource checks cannot be bypassed by memo entries from fuel 4096:
  -- each fuel profile has a distinct memo type.
  match psKernelC0ScopedCheckedDAGCheck
      owner 0 session.context session.state [] id with
  | .ok _ =>
      throw (IO.userError "scoped checked DAG: zero fuel accepted")
  | .error _ => pure ()
  match psKernelC0ScopedCheckedDAGCheck
      owner 4096 session.context session.state memo (id + store.nodes.size + 1) with
  | .ok _ =>
      throw (IO.userError "scoped checked DAG: foreign/out-of-bounds ID accepted")
  | .error _ => pure ()
  let (batched, batchMemo) ← match psKernelC0ScopedCheckedDAGCheckBatch
      owner 4096 session.context session.state [id, id, id] [] with
    | .ok pair => pure pair
    | .error e =>
        throw (IO.userError ("scoped checked DAG: repeated batch failed: " ++ e))
  if batched.length != 3 || batchMemo.length != 1 then
    throw (IO.userError
      "scoped checked DAG: identical three-root batch failed to reuse one receipt")
  for entry in batched do
    let _batchSource := psKernelC0ScopedCheckedDAGBatchEntry_source entry
    if entry.requestedId != id then
      throw (IO.userError "scoped checked DAG: batch returned unrelated ID")
  let some (mixedStore, mixedBadId) :=
      psKernelC0EncodeExpr store (.bvar 0)
    | throw (IO.userError "scoped checked DAG: mixed store encode failed")
  let some mixedOwner := psKernelC0CertifyStore mixedStore
    | throw (IO.userError "scoped checked DAG: mixed store certification failed")
  -- An invalid tail must reject the entire batch even after a valid head
  -- was successfully checked in this pure local evaluation.
  match psKernelC0ScopedCheckedDAGCheckBatch
      mixedOwner 4096 session.context session.state [id, mixedBadId] [] with
  | .ok _ =>
      throw (IO.userError "scoped checked DAG: partially invalid batch accepted")
  | .error _ => pure ()
  IO.println "C0_SCOPED_CHECKED_DAG_BATCH repeated=3 memo_entries=1 invalid_tail=atomic_rejection"
  IO.println "C0_SCOPED_CHECKED_DAG exact_id=pass memo_hit=pass source=pass invalid=declined zero_fuel=declined out_of_bounds=declined"
  IO.println "C0_CERTIFIED_CHECKED_DAG owned_root=pass exact_source=pass invalid=declined"
