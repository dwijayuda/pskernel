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
  let _topology : psKernelC0StoreTopological certified.owner.store :=
    psKernelC0CertifiedRootStore_topological certified
  let _columns : psKernelC0StoreColumnsCorrect certified.owner.store :=
    psKernelC0CertifiedRootColumns_correct certified
  let _index : psKernelC0StoreIndexed certified.owner.store :=
    psKernelC0CertifiedRootIndex_correct certified
  let _storeWF : psKernelC0StoreWF certified.owner.store :=
    psKernelC0CertifiedRootStore_wf certified
  if psKernelC0NodeTopological 0 (.app 0 0) then
    throw (IO.userError "forward-ref node satisfied topology invariant")
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
  -- The mathematical StoreWF propositions independently reject changed
  -- derived columns or forged indices; canonical replay is still required
  -- for the *entire* radix trie, including ghost entries.
  let wrongDepthNode : PsKernelC0StoredNode :=
    { rootNode with depth := rootNode.depth + 1 }
  let wrongDepthStore : PsKernelC0TermStore :=
    { rawStore with nodes := rawStore.nodes.set! id wrongDepthNode }
  if psKernelC0StoreColumnsCorrect wrongDepthStore then
    throw (IO.userError "altered indexed depth satisfied metadata invariant")
  if psKernelC0StoreWF wrongDepthStore then
    throw (IO.userError "StoreWF accepted corrupt derived metadata")
  if (psKernelC0CertifyStore wrongDepthStore).isSome then
    throw (IO.userError "corrupted derived column gained StoreWF certificate")
  let wrongRangeNode : PsKernelC0StoredNode :=
    { rootNode with looseBVarRange := rootNode.looseBVarRange + 1 }
  let wrongRangeStore : PsKernelC0TermStore :=
    { rawStore with nodes := rawStore.nodes.set! id wrongRangeNode }
  if psKernelC0StoreColumnsCorrect wrongRangeStore then
    throw (IO.userError "altered loose-bound range passed column invariant")
  let malformed : PsKernelC0TermStore :=
    { rawStore with
      nodes := rawStore.nodes.set! id
        { rootNode with checkerHash := rootNode.checkerHash + 1 }
    }
  let forwardRef : PsKernelC0TermStore := {
    rawStore with
    nodes := rawStore.nodes.set! id { rootNode with node := .app id id }
  }
  if psKernelC0StoreTopological forwardRef then
    throw (IO.userError "topological proof admitted a self-reference")
  if (psKernelC0CertifyStore forwardRef).isSome then
    throw (IO.userError "self-referential store acquired topology certificate")
  -- Canonical replay certifies the ENTIRE radix index, not merely
  -- the root's hash and per-node metadata. Ghost bucket entries fail.
  let candidates := psKernelC0TermTrieBucket
    psKernelC0IndexDepth rawStore.index rootNode.hash
  let forgedIndex := psKernelC0TermTrieReplace
    psKernelC0IndexDepth rawStore.index rootNode.hash
    ((rawStore.nodes.size + 5) :: candidates)
  let ghostStore : PsKernelC0TermStore :=
    { rawStore with index := forgedIndex }
  if psKernelC0StoreIndexed
      { rawStore with index := PsKernelC0HashTrie.empty } then
    throw (IO.userError "missing canonical node lookup passed index invariant")
  -- An extra bucket entry may still let every proper node resolve;
  -- the separate canonical-replay certificate must reject that ghost.
  if !psKernelC0StoreIndexed ghostStore then
    throw (IO.userError "index reachability falsely covered ghost validation")
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
  let _initialOwned :
      initial.working.store = initial.raw.scratch.working :=
    initial.owned
  let _initialWF : psKernelC0StoreWF initial.raw.scratch.working :=
    psKernelC0CertifiedWorkStoreWF initial
  let _initialCanonical :
      psKernelC0ReplayValidateStore initial.raw.scratch.working = true :=
    psKernelC0CertifiedWorkCanonical initial
  -- A locally checked free variable is NOT a closed deployable root.
  -- Checking may legitimately succeed inside a local hypothesis context,
  -- but the stronger checked-publication gate must reject that context-
  -- dependent syntax rather than silently treating it as global evidence.
  let localName := c0CertificateName "contextProof"
  let scopedLocals := psKernelLocalContextAddLocal
    initial.raw.checker.context.localContext localName localName
    (.sort (.succ .zero)) .default
  let scopedSession : PsKernelCheckerSession := {
    initial.raw.checker with
    context := { initial.raw.checker.context with
      localContext := scopedLocals }
  }
  let scopedRaw : PsKernelC0ArchitectureWork := {
    initial.raw with checker := scopedSession
  }
  let some scopedWork := psKernelC0ArchitectureCertifyWork scopedRaw
    | throw (IO.userError "valid local scope did not certify")
  let some openStage := psKernelC0CertifiedWorkStage
      scopedWork (.fvar localName)
    | throw (IO.userError "typed local syntax could not be staged")
  match psKernelC0CertifiedWorkCheck 4096 openStage (.fvar localName) with
  | .error err =>
      throw (IO.userError ("locally typed free variable unexpectedly failed: " ++ err))
  | .ok _ => pure ()
  match psKernelC0CertifiedWorkCommitChecked 4096 openStage with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "checked publication leaked a local hypothesis")
  let levelName := c0CertificateName "undeclaredLevel"
  let some invalidLevelStage := psKernelC0CertifiedWorkStage initial
      (.sort (.param levelName))
    | throw (IO.userError "undeclared universe syntax stage was rejected")
  match psKernelC0CertifiedWorkCommitChecked 4096 invalidLevelStage with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "checked publication leaked an undeclared universe")
  let some staged := psKernelC0CertifiedWorkStage initial (.bvar 0)
    | throw (IO.userError "ill-typed syntax should be stageable")
  let _stageValid : psKernelC0ArchitectureWorkValid staged.raw = true :=
    staged.valid
  let _stageWF : psKernelC0StoreWF staged.raw.scratch.working :=
    psKernelC0CertifiedWorkStoreWF staged
  if staged.working.store.nodes.size != staged.raw.scratch.working.nodes.size then
    throw (IO.userError "staging certificate changed underlying owner snapshot")
  -- A canonical syntax-only commit is allowed, but the stronger checked
  -- publication must FAIL atomically on a loose, ill-typed variable.
  match psKernelC0CertifiedWorkCommitChecked 4096 staged with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "checked publication accepted an unbound staged term")
  if (psKernelC0ArchitectureAbort staged.raw).nodes.size !=
      rawStore.nodes.size then
    throw (IO.userError "failed checked publication modified persistent input")
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
  -- Publication is now explicitly gated by full checking of EVERY
  -- selected root; syntax provenance alone cannot issue this result.
  let (published, typedRoots, checkedPublished) ← match
      psKernelC0CertifiedWorkCommitChecked 4096 wellFormedStage with
    | .ok data => pure data
    | .error e =>
        throw (IO.userError ("checked root publication failed: " ++ e))
  if !psKernelC0ReplayValidateStore published.store ||
      !psKernelC0ArchitectureWorkValid checkedPublished.raw then
    throw (IO.userError "checked publication lost canonical work validation")
  match typedRoots with
  | [checkedRoot] =>
      let _verifiedCheckerResult :
          psKernelCheckerCheck checkedRoot.fuel checkedRoot.context
              checkedRoot.stateBefore checkedRoot.root.expression =
            .ok (checkedRoot.checkedType, checkedRoot.stateAfter) :=
        psKernelC0SourceCheckedRootExact checkedRoot
      if !psKernelExprEqual checkedRoot.root.expression (.sort .zero) ||
          !psKernelExprEqual checkedRoot.checkedType (.sort (.succ .zero)) then
        throw (IO.userError "source-checked publication returned wrong root/type")
  | _ => throw (IO.userError "source-checked publication lost selected root ordering")
  -- Two valid roots are checked in source order, with separate
  -- proof-carrying source-check results and immutable session updates.
  let some positiveOne := psKernelC0CertifiedWorkStage
      initial (.sort .zero)
    | throw (IO.userError "positive batch first stage failed")
  let some positiveTwo := psKernelC0CertifiedWorkStage
      positiveOne (.sort (.succ .zero))
    | throw (IO.userError "positive batch second stage failed")
  let (_, positiveReceipts, _) ← match
      psKernelC0CertifiedWorkCommitChecked 4096 positiveTwo with
    | .ok result => pure result
    | .error e =>
        throw (IO.userError ("positive checked batch failed: " ++ e))
  match positiveReceipts with
  | [firstReceipt, secondReceipt] =>
      let _firstProof :=
        psKernelC0SourceCheckedRootExact firstReceipt
      let _secondProof :=
        psKernelC0SourceCheckedRootExact secondReceipt
      if !psKernelExprEqual firstReceipt.root.expression (.sort .zero) ||
          !psKernelExprEqual firstReceipt.checkedType (.sort (.succ .zero)) ||
          !psKernelExprEqual secondReceipt.root.expression (.sort (.succ .zero)) ||
          !psKernelExprEqual secondReceipt.checkedType
            (.sort (.succ (.succ .zero))) then
        throw (IO.userError "checked batch altered source term order or type")
  | _ => throw (IO.userError "checked batch dropped one valid root")
  let some mixedFirst := psKernelC0CertifiedWorkStage initial (.sort .zero)
    | throw (IO.userError "mixed publication failed first stage")
  let some mixedSecond := psKernelC0CertifiedWorkStage mixedFirst (.bvar 0)
    | throw (IO.userError "mixed publication failed second stage")
  match psKernelC0CertifiedWorkCommitChecked 4096 mixedSecond with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "mixed checked publication partially accepted invalid root")
  if (psKernelC0ArchitectureAbort mixedSecond.raw).nodes.size !=
      rawStore.nodes.size then
    throw (IO.userError "mixed rejection mutated persistent source snapshot")
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
  -- The certified transaction now supports every source-checked
  -- observation and the same opt-in typed-demand candidate, without a
  -- redundant whole-store replay on an immutable checking-only update.
  let (isProp, classifiedWork) ← match
      psKernelC0CertifiedWorkIsProp 4096 admitted (.sort .zero) with
    | .ok result => pure result
    | .error e =>
        throw (IO.userError ("certified proposition query failed: " ++ e))
  if isProp then
    throw (IO.userError "certified proposition query mistyped Sort0")
  let (_, _) ← match psKernelC0CertifiedWorkPreviewTypedDemand
      4096 32768 classifiedWork (.const defName []) with
    | .ok (observation, next) =>
        if !observation.agrees ||
            !psKernelExprEqual observation.sourceValue (.sort .zero) then
          throw (IO.userError "certified typed preview lost source WHNF")
        pure (observation, next)
    | .error e =>
        throw (IO.userError ("certified typed preview failed: " ++ e))
  match psKernelC0CertifiedWorkPreviewTypedDemand
      4096 1 classifiedWork (.const defName []) with
  | .error e =>
      throw (IO.userError ("candidate budget changed source: " ++ e))
  | .ok (observation, _) =>
      if observation.candidateValue.isSome ||
          !psKernelExprEqual observation.sourceValue (.sort .zero) then
        throw (IO.userError "certified typed preview bypassed resource isolation")
  match psKernelC0CertifiedWorkObserveTypedMajor
      4096 classifiedWork defName (.sort .zero) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "non-recursor metadata received typed K judgment")
  let _admittedWF : psKernelC0StoreWF admitted.raw.scratch.working :=
    psKernelC0CertifiedWorkStoreWF admitted
  let _admittedOwner :
      admitted.working.store = admitted.raw.scratch.working :=
    admitted.owned
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
  IO.println "C0_CERTIFIED all_or_nothing_checked_root_publication=pass"
