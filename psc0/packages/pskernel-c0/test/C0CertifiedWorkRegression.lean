import Ps.KernelCore.Architecture.CertifiedWork

/-!
Phase C/E: immutable proof-carrying replay certificates.

These tests deliberately distinguish canonical syntax validity from source
type checking, and ensure a certified store's proof persists only when the
syntax/store is unchanged. No admission is granted from the certificate.
-/

def c0CertificateName (s : String) : PsKernelName := .str .anonymous s

def main : IO Unit := do
  let term : PsKernelExpr :=
    .lam (c0CertificateName "x") (.sort .zero)
      (.mdata 17 (.bvar 0)) .implicit
  let some (rawStore, id) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty term
    | throw (IO.userError "certificate test could not encode source term")
  let some certified := psKernelC0CertifyRoot rawStore id
    | throw (IO.userError "canonical store root was not certifiable")
  if !psKernelExprEqual (psKernelC0CertifiedRootRead certified) term then
    throw (IO.userError "certified readback changed binder metadata")
  -- These are native Lean proof witnesses with no runtime assumptions.
  let _canonical :
      psKernelC0ReplayValidateStore certified.owner.store = true :=
    psKernelC0CertifiedRootStore_canonical certified
  let _exact :
      psKernelC0DecodeExpr certified.owner.store certified.root =
        some (psKernelC0CertifiedRootRead certified) :=
    psKernelC0CertifiedRootRead_exact certified
  if (psKernelC0CertifyRoot rawStore (rawStore.nodes.size + 8)).isSome then
    throw (IO.userError "foreign numeric handle acquired certificate")
  -- The same numeric root ID has no meaning outside its owner.
  -- A different canonical store may use an overlapping ID for distinct
  -- binder metadata; cross-store transfer must re-encode and prove exact
  -- source syntax equality, not simply copy the original number.
  let alternate : PsKernelExpr :=
    .lam (c0CertificateName "x") (.sort .zero)
      (.mdata 18 (.bvar 0)) .implicit
  let some (foreignStore, foreignId) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty alternate
    | throw (IO.userError "cross-store collision fixture failed")
  let some foreignRoot := psKernelC0CertifyRoot foreignStore foreignId
    | throw (IO.userError "foreign canonical snapshot was not certifiable")
  if psKernelExprEqual (psKernelC0CertifiedRootRead certified)
      (psKernelC0CertifiedRootRead foreignRoot) then
    throw (IO.userError "different immutable stores lost source metadata")
  let some transferred := psKernelC0CertifiedRootRehome
      certified foreignRoot.owner
    | throw (IO.userError "certified root failed cross-store rehome")
  let _transferProof :
      psKernelExprEqual transferred.source.expression
        transferred.target.expression = true :=
    psKernelC0CertifiedTransferExact transferred
  if !psKernelExprEqual (psKernelC0CertifiedRootRead transferred.target)
      term then
    throw (IO.userError "rehome reused a foreign handle incorrectly")
  let _transferValid :
      psKernelC0ReplayValidateStore transferred.target.owner.store = true :=
    psKernelC0CertifiedRootStore_canonical transferred.target
  let some rootNode := psKernelC0StoreGet rawStore id
    | throw (IO.userError "certified test root disappeared")
  let malformed : PsKernelC0TermStore :=
    { rawStore with
      nodes := rawStore.nodes.set! id
        { rootNode with checkerHash := rootNode.checkerHash + 1 }
    }
  -- Canonical replay certifies the ENTIRE radix index, not merely
  -- the root's hash and per-node metadata. Ghost bucket entries fail.
  let candidates := psKernelC0TermTrieBucket
    psKernelC0IndexDepth rawStore.index rootNode.hash
  let forgedIndex := psKernelC0TermTrieReplace
    psKernelC0IndexDepth rawStore.index rootNode.hash
    ((rawStore.nodes.size + 5) :: candidates)
  let ghostStore : PsKernelC0TermStore :=
    { rawStore with index := forgedIndex }
  if (psKernelC0CertifyStore ghostStore).isSome then
    throw (IO.userError "forged canonical trie acquired proof certificate")
  if (psKernelC0CertifyStore malformed).isSome then
    throw (IO.userError "tampered store hash acquired replay certificate")
  if (psKernelC0CertifyRoot malformed id).isSome then
    throw (IO.userError "tampered source root acquired certificate")

  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let some rawWork := psKernelC0ArchitectureBegin source rawStore
    | throw (IO.userError "verified work could not begin from canonical store")
  let some initial := psKernelC0ArchitectureCertifyWork rawWork
    | throw (IO.userError "valid work did not acquire proof witness")
  let _initialValid : psKernelC0ArchitectureWorkValid initial.raw = true :=
    initial.valid
  let some staged := psKernelC0CertifiedWorkStage initial (.bvar 0)
    | throw (IO.userError "ill-typed syntax should be stageable")
  let _stageValid : psKernelC0ArchitectureWorkValid staged.raw = true :=
    staged.valid
  -- A staged root can itself carry an immutable source-store proof.
  -- That proof authorizes *readback*, never full term acceptance.
  let some (stagedWithRoot, stagedBound) :=
      psKernelC0CertifiedWorkStageRoot initial (.bvar 0)
    | throw (IO.userError "exact staged root certificate was unavailable")
  let _rootValid :
      psKernelC0DecodeExpr stagedBound.owner.store stagedBound.root =
        some stagedBound.expression :=
    psKernelC0CertifiedRootRead_exact stagedBound
  if !psKernelExprEqual stagedBound.expression (.bvar 0) then
    throw (IO.userError "staged root did not preserve exact loose bvar")
  match psKernelC0CertifiedWorkCheckRoot 4096 stagedWithRoot stagedBound with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "certified staged root bypassed full source check")
  let some (wellFormedStage, wellFormedRoot) :=
      psKernelC0CertifiedWorkStageRoot initial (.sort .zero)
    | throw (IO.userError "source-sort staging did not certify")
  let (checkedRootTy, checkedRootWork) ← match
      psKernelC0CertifiedWorkCheckRoot 4096 wellFormedStage
        wellFormedRoot with
    | .ok result => pure result
    | .error reason =>
        throw (IO.userError ("certified valid root failed checking: " ++ reason))
  if !psKernelExprEqual checkedRootTy (.sort (.succ .zero)) ||
      !psKernelC0ArchitectureWorkValid checkedRootWork.raw then
    throw (IO.userError "certified root checking changed source typing")
  -- Stage validation is syntax-only. The same ill-typed bvar must fail
  -- mandatory checking even though it lives in a certified canonical store.
  match psKernelC0CertifiedWorkCheck 4096 staged (.bvar 0) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "certified syntax bypassed source type checking")
  let some (persisted, roots) := psKernelC0CertifiedWorkCommit staged
    | throw (IO.userError "certified scratch promotion failed")
  if roots.length != 1 then
    throw (IO.userError "certified promotion changed root count")
  if !psKernelC0ReplayValidateStore persisted.store then
    throw (IO.userError "certified promotion lost canonical index")
  match roots with
  | [root] =>
      if !psKernelExprEqual (psKernelC0CertifiedRootRead root) (.bvar 0) then
        throw (IO.userError "certified promotion changed staged syntax")
  | _ => throw (IO.userError "certified promotion lost root")
  let forgedRaw : PsKernelC0ArchitectureWork := {
    staged.raw with stagedRoots := [staged.raw.scratch.working.nodes.size + 7]
  }
  if (psKernelC0ArchitectureCertifyWork forgedRaw).isSome then
    throw (IO.userError "forged work roots acquired a proof certificate")

  -- Source checked operations preserve replay-validity by construction,
  -- rather than rerunning full indexed-store replay on every WHNF/DefEq.
  let (inferred, inferredWork) ← match
      psKernelC0CertifiedWorkInfer 4096 staged (.sort .zero) with
    | .ok x => pure x
    | .error e => throw (IO.userError ("certified inference failed: " ++ e))
  if !psKernelExprEqual inferred (.sort (.succ .zero)) then
    throw (IO.userError "certified inference changed source type")
  let _inferValid :
      psKernelC0ArchitectureWorkValid inferredWork.raw = true :=
    inferredWork.valid
  let (checked, checkedWork) ← match
      psKernelC0CertifiedWorkCheck 4096 inferredWork (.sort .zero) with
    | .ok x => pure x
    | .error e => throw (IO.userError ("certified checker failed: " ++ e))
  if !psKernelExprEqual checked inferred then
    throw (IO.userError "certified checker disagreed with source inference")
  let (same, defeqWork) ← match
      psKernelC0CertifiedWorkDefEq 4096 checkedWork
        (.sort .zero) (.sort (.succ .zero)) with
    | .ok x => pure x
    | .error e => throw (IO.userError ("certified DefEq failed: " ++ e))
  if same then
    throw (IO.userError "certified source DefEq equated different universes")
  let (whnf, whnfWork) ← match
      psKernelC0CertifiedWorkWhnf 4096 defeqWork
        (.app (.lam (c0CertificateName "x") (.sort .zero)
          (.bvar 0) .default) (.sort .zero)) with
    | .ok x => pure x
    | .error e => throw (IO.userError ("certified WHNF failed: " ++ e))
  if !psKernelExprEqual whnf (.sort .zero) then
    throw (IO.userError "certified source WHNF changed β reduction")
  let _whnfValid :
      psKernelC0ArchitectureWorkValid whnfWork.raw = true :=
    whnfWork.valid

  -- Admit only a source-checked definition. Admission must refresh the
  -- checker state while retaining the proof about the unchanged syntax.
  let defName := c0CertificateName "CertifiedDefinition"
  let declaration : PsKernelDefinitionInfo := {
    base := {
      name := defName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .safe
  }
  let admitted ← match psKernelC0CertifiedWorkAdmit 4096 whnfWork
      (.definition declaration) with
    | .ok next => pure next
    | .error e => throw (IO.userError ("certified source admission failed: " ++ e))
  let (unfolded, _) ← match psKernelC0CertifiedWorkWhnf 4096
      admitted (.const defName []) with
    | .ok x => pure x
    | .error e => throw (IO.userError ("certified admitted WHNF failed: " ++ e))
  if !psKernelExprEqual unfolded (.sort .zero) then
    throw (IO.userError "certified admission reused stale environment WHNF")
  match psKernelC0CertifiedWorkAdmit 4096 admitted (.definition declaration) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "duplicate declaration bypassed certified admission")
  IO.println "C0_CERTIFIED canonical_store_and_owned_root_proofs=pass"
  IO.println "C0_CERTIFIED immutable_transaction_checking=pass"
  IO.println "C0_CERTIFIED admitted_source_and_cache_revision=pass"
