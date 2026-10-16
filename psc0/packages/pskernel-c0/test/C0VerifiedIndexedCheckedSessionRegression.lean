import Ps.KernelCore.Architecture.VerifiedIndexedCheckedSession

/-!
Check the actual opt-in indexed SESSION entry, not an arbitrary raw cache
insertion. A legitimate earlier checked receipt may be reused only at the
same immutable owner, context, original fuel and initial source state.
-/

def main : IO Unit := do
  let expr : PsKernelExpr := .sort .zero
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let initial := psKernelC0IndexedSessionNew source
  let some session := psKernelC0IndexedSessionRetain initial expr
    | throw (IO.userError "indexed checked session: Sort root retain declined")
  let some owned := psKernelC0CertifyStoreOwned session.store
    | throw (IO.userError "indexed checked session: valid store not certified")
  let owner := owned.val
  let some (_, id) := psKernelC0EncodeExpr session.store expr
    | throw (IO.userError "indexed checked session: no canonical handle")
  let some hash := psKernelC0VerifiedIndexedHashSourceOracle owner id
    | throw (IO.userError "indexed checked session: no source hash proof")
  let empty := psKernelC0IndexedCheckedReceiptTableEmpty owner 4096
    session.checker.context session.checker.state
  let (_, memo) ← match psKernelC0IndexedCheckedReceiptTableCheck owner 4096
      session.checker.context session.checker.state empty hash with
    | .error e => throw (IO.userError
        ("indexed checked session: source check declined: " ++ e))
    | .ok pair => pure pair
  let _memoSource :
      psKernelC0IndexedSessionCheckWithVerifiedReceipt
          4096 session owner owned.property hash memo =
        psKernelC0IndexedSessionCheck 4096 session hash.expr :=
    psKernelC0IndexedSessionCheckWithVerifiedReceipt_source
      4096 session owner owned.property hash memo
  let (actualType, actualSession) ← match
      psKernelC0IndexedSessionCheckWithVerifiedReceipt
        4096 session owner owned.property hash memo with
    | .error e => throw (IO.userError
        ("indexed checked session: source-backed hit failed: " ++ e))
    | .ok value => pure value
  let (refType, refSession) ← match psKernelC0IndexedSessionCheck
      4096 session expr with
    | .error e => throw (IO.userError
        ("indexed checked session: original source failed: " ++ e))
    | .ok pair => pure pair
  if !psKernelExprEqual actualType refType ||
      actualSession.store.nodes.size != refSession.store.nodes.size ||
      actualSession.checker.state.nextFresh !=
        refSession.checker.state.nextFresh then
    throw (IO.userError "indexed checked session: state/type mismatch")

  -- Check the fallback route with no memo and its complete source theorem.
  let _coldProof :
      psKernelC0IndexedSessionCheckWithVerifiedReceipt
          4096 session owner owned.property hash empty =
        psKernelC0IndexedSessionCheck 4096 session hash.expr :=
    psKernelC0IndexedSessionCheckWithVerifiedReceipt_source
      4096 session owner owned.property hash empty

  -- Resource denial is unchanged with a different (zero-fuel) typed table.
  let zero := psKernelC0IndexedCheckedReceiptTableEmpty owner 0
    session.checker.context session.checker.state
  let _resourceProof :
      psKernelC0IndexedSessionCheckWithVerifiedReceipt
          0 session owner owned.property hash zero =
        psKernelC0IndexedSessionCheck 0 session hash.expr :=
    psKernelC0IndexedSessionCheckWithVerifiedReceipt_source
      0 session owner owned.property hash zero
  match psKernelC0IndexedSessionCheckWithVerifiedReceipt
      0 session owner owned.property hash zero with
  | .ok _ =>
      throw (IO.userError "indexed checked session: zero fuel admitted")
  | .error _ => pure ()

  IO.println "C0_INDEXED_VERIFIED_CHECKED_SESSION source_complete=Lean hit=pass fallback=pass exact_session_state=pass resource=declined raw_writes=none"
