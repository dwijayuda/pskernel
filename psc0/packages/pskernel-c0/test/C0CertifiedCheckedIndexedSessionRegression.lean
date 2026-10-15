import Ps.KernelCore.Architecture.CertifiedCheckedIndexedSession

/-!
The existing indexed session can return a genuinely checked source trace.
Store certification is mandatory even for empty requests. Raw node IDs,
forged indexes, and invalid source expressions cannot publish checked work.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let initial := psKernelC0IndexedSessionNew source
  let zero : PsKernelExpr := .sort .zero
  let bad : PsKernelExpr := .bvar 0
  let some withSort := psKernelC0IndexedSessionRetain initial zero
    | throw (IO.userError "indexed source run: cannot retain valid sort")
  let some indexed := psKernelC0IndexedSessionRetain withSort bad
    | throw (IO.userError "indexed source run: cannot retain test bvar syntax")
  let some (_, goodId) := psKernelC0EncodeExpr indexed.store zero
    | throw (IO.userError "indexed source run: no canonical sort handle")
  let some (_, badId) := psKernelC0EncodeExpr indexed.store bad
    | throw (IO.userError "indexed source run: no canonical bvar handle")

  let certified ← match psKernelC0IndexedSessionCheckCertifiedTrace
      4096 indexed [goodId, goodId] with
    | .ok receipt => pure receipt
    | .error err =>
        throw (IO.userError ("indexed source run: valid roots declined: " ++ err))
  let _exactOwner : certified.owner.store = indexed.store :=
    psKernelC0CertifiedIndexedSourceRun_owned certified
  let _exactSource :
      psKernelC0IndexedDAGReferenceFold certified.owner 4096
          indexed.checker.context
          (psKernelC0CheckedDAGTraceIds certified.checkedTrace)
          indexed.checker.state =
        .ok certified.finalState :=
    psKernelC0CertifiedIndexedSourceRun_source certified
  if psKernelC0CheckedDAGTraceIds certified.checkedTrace !=
      [goodId, goodId] then
    throw (IO.userError "indexed source run: returned unrelated node handles")

  match psKernelC0IndexedSessionCheckCertifiedTrace 4096 indexed
      [goodId, badId] with
  | .ok _ =>
      throw (IO.userError "indexed source run: invalid late proof accepted")
  | .error _ => pure ()
  match psKernelC0IndexedSessionCheckCertifiedTrace 0 indexed [goodId] with
  | .ok _ =>
      throw (IO.userError "indexed source run: source checking budget bypassed")
  | .error _ => pure ()

  -- No syntactically valid root list can certify a forged radix index.
  -- In particular, an empty requested sequence cannot avoid store validation.
  let forgedStore : PsKernelC0TermStore :=
    { indexed.store with index := PsKernelC0HashTrie.empty }
  let forged : PsKernelC0IndexedCheckerSession :=
    { indexed with store := forgedStore }
  match psKernelC0IndexedSessionCheckCertifiedTrace 4096 forged [] with
  | .ok _ =>
      throw (IO.userError "indexed source run: malformed store accepted")
  | .error _ => pure ()

  IO.println "C0_CERTIFIED_INDEXED_SOURCE owner=exact sequential_source=pass invalid_tail=declined zero_fuel=declined malformed_index=declined"
