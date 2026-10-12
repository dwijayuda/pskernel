import Ps.KernelCore.Core.IndexedScratch

/-!
Exact differential qualification of staged DAG promotion and discard.
This is syntax-only storage work, not kernel admission or DefEq.
-/

def main : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "Scratch.value"
  let leaf : PsKernelExpr := .sort .zero
  let (persistent, original) ←
    match psKernelC0EncodeExpr psKernelC0StoreEmpty leaf with
    | some result => pure result
    | none => throw (IO.userError "C0 scratch seed construction failed")
  let start := psKernelC0ScratchBegin persistent
  if !psKernelC0ScratchValid start ||
      start.working.nodes.size != persistent.nodes.size then
    throw (IO.userError "C0 scratch start invalid")

  let mut scratch := start
  let mut root := original
  for _ in [:14] do
    match psKernelC0ScratchIntern scratch (.app root root) with
    | none => throw (IO.userError "C0 scratch shared DAG append failed")
    | some (next, id) =>
        scratch := next
        root := id
  let selected := root
  match psKernelC0ScratchIntern scratch (.mdata 49 root) with
  | none => throw (IO.userError "C0 unused temporary metadata append failed")
  | some (next, id) =>
      scratch := next
      match psKernelC0ScratchPromoteVerified next id with
      | none => throw (IO.userError "C0 verified metadata promotion failed")
      | some (checked, target) =>
          match psKernelC0DecodeExpr checked target with
          | some (.mdata 49 (.app _ _)) => pure ()
          | _ => throw (IO.userError "C0 promotion erased root metadata")
  match psKernelC0ScratchEncode scratch
      (.lam name leaf (.bvar 0) .implicit) with
  | none => throw (IO.userError "C0 unused binder construction failed")
  | some (next, id) =>
      scratch := next
      match psKernelC0ScratchPromoteVerified next id with
      | none => throw (IO.userError "C0 verified binder promotion failed")
      | some (checked, target) =>
          let some actual := psKernelC0DecodeExpr checked target
            | throw (IO.userError "C0 verified binder readback missing")
          if !psKernelExprEqual actual (.lam name leaf (.bvar 0) .implicit) then
            throw (IO.userError "C0 verified promotion lost binder information")

  if !psKernelC0ScratchValid scratch ||
      (psKernelC0ScratchAbort scratch).nodes.size != persistent.nodes.size then
    throw (IO.userError "C0 scratch discarded or mutated persistent nodes")

  -- The stronger diagnostic gate replays the complete output store and
  -- compares metadata-sensitive source syntax at every promoted root.
  match psKernelC0ScratchPromoteVerifiedRoots scratch
      [selected, original, selected] with
  | none => throw (IO.userError "C0 verified scratch promotion failed")
  | some (verified, ids) =>
      if !psKernelC0ReplayValidateStore verified ||
          verified.nodes.size != persistent.nodes.size + 14 then
        throw (IO.userError "C0 verified promotion corrupted persistent store")
      match ids with
      | [first, second, third] =>
          if first != third || second != original then
            throw (IO.userError "C0 verified promotion lost shared roots")
          let some expected := psKernelC0DecodeExpr scratch.working selected
            | throw (IO.userError "C0 verified source root missing")
          let some actual := psKernelC0DecodeExpr verified first
            | throw (IO.userError "C0 verified target root missing")
          if !psKernelExprEqual expected actual then
            throw (IO.userError "C0 verified promotion lost exact source metadata")
      | _ => throw (IO.userError "C0 verified promotion lost root order")

  match psKernelC0ScratchPromote scratch selected with
  | none => throw (IO.userError "C0 scratch canonical promotion failed")
  | some (committed, rootId) =>
      if !psKernelC0ReplayValidateStore committed ||
          committed.nodes.size != persistent.nodes.size + 14 ||
          committed.nodes.size >= scratch.working.nodes.size then
        throw (IO.userError "C0 scratch promotion retained irrelevant nodes")
      match psKernelC0DecodeExpr committed rootId,
            psKernelC0DecodeExpr scratch.working selected with
      | some (.app _ _), some (.app _ _) => pure ()
      | _, _ => throw (IO.userError "C0 scratch promoted term is malformed")
      match psKernelC0ScratchPromoteRoots scratch [selected, selected] with
      | none => throw (IO.userError "C0 shared promotion could not repeat root")
      | some (again, ids) =>
          if again.nodes.size != committed.nodes.size ||
              ids != [rootId, rootId] then
            throw (IO.userError "C0 scratch memo lost canonical sharing")
      let fork := psKernelC0ScratchBegin committed
      match psKernelC0ScratchIntern fork (.proj name 0 rootId) with
      | none => throw (IO.userError "C0 scratch could not start second phase")
      | some (next, _) =>
          if (psKernelC0ScratchAbort next).nodes.size != committed.nodes.size then
            throw (IO.userError "C0 scratch abort changed committed store")

  match psKernelC0ScratchPromoteRoots scratch [original] with
  | some (unchanged, ids) =>
      if ids != [original] ||
          unchanged.nodes.size != persistent.nodes.size then
        throw (IO.userError "C0 persistent handle did not retain identity")
  | none => throw (IO.userError "C0 existing root lost on promotion")

  if (psKernelC0ScratchPromoteVerified
      scratch (scratch.working.nodes.size + 10)).isSome then
    throw (IO.userError "C0 verified promotion accepted dangling root")
  if (psKernelC0ScratchPromote
      scratch (scratch.working.nodes.size + 10)).isSome then
    throw (IO.userError "C0 dangling handle was promoted")
  let truncated : PsKernelC0Scratch :=
    { persistent := scratch.working, working := persistent }
  if psKernelC0ScratchValid truncated ||
      (psKernelC0ScratchPromoteRoots truncated [original]).isSome then
    throw (IO.userError "C0 accepted truncated persistent prefix")
  let (unrelated, _) ←
    match psKernelC0EncodeExpr psKernelC0StoreEmpty (.lit (.nat 42)) with
    | some result => pure result
    | none => throw (IO.userError "C0 unrelated store construction failed")
  let wrongPrefix : PsKernelC0Scratch :=
    { persistent := persistent, working := unrelated }
  if psKernelC0ScratchValid wrongPrefix ||
      (psKernelC0ScratchPromote wrongPrefix original).isSome then
    throw (IO.userError "C0 accepted a different arena's prefix")
  let some staged := psKernelC0StoreGet scratch.working selected
    | throw (IO.userError "C0 staged root missing")
  let badNode : PsKernelC0StoredNode :=
    { staged with checkerHash := staged.checkerHash + 1 }
  let badWorking : PsKernelC0TermStore :=
    { scratch.working with
      nodes := scratch.working.nodes.set! selected badNode }
  let forged : PsKernelC0Scratch :=
    { scratch with working := badWorking }
  if (psKernelC0ScratchPromoteVerified forged selected).isSome then
    throw (IO.userError "C0 verified promotion accepted forged metadata")
  if psKernelC0ScratchValid forged ||
      (psKernelC0ScratchPromote forged selected).isSome then
    throw (IO.userError "C0 accepted forged derived node metadata")


  -- Two valid stores may allocate handle zero for different terms.
  -- A bound-root transfer must use the source expression, not that number.
  let (leftStore, leftId) ←
    match psKernelC0EncodeExpr psKernelC0StoreEmpty (.sort .zero) with
    | some result => pure result
    | none => throw (IO.userError "C0 first bound store unavailable")
  let (rightStore, rightId) ←
    match psKernelC0EncodeExpr psKernelC0StoreEmpty (.lit (.nat 42)) with
    | some result => pure result
    | none => throw (IO.userError "C0 second bound store unavailable")
  if leftId != rightId then
    throw (IO.userError "C0 bound root alias fixture is ineffective")
  let rightRoot : PsKernelC0BoundRoot :=
    { store := rightStore, root := rightId }
  let some imported := psKernelC0BoundRootRehome leftStore rightRoot
    | throw (IO.userError "C0 source-preserving import failed")
  if imported.root == leftId then
    throw (IO.userError "C0 cross-store numeric handle was reused")
  match psKernelC0BoundRootRead imported with
  | some (.lit (.nat 42)) => pure ()
  | _ => throw (IO.userError "C0 source-preserving import changed expression")
  let some (stagedRoot, stagedId) :=
      psKernelC0ScratchStageBoundRoot (psKernelC0ScratchBegin leftStore) rightRoot
    | throw (IO.userError "C0 source-preserving staging failed")
  match psKernelC0ScratchPromoteVerified stagedRoot stagedId with
  | none => throw (IO.userError "C0 source-preserving promotion failed")
  | some (committedStore, committedId) =>
      match psKernelC0DecodeExpr committedStore committedId with
      | some (.lit (.nat 42)) => pure ()
      | _ => throw (IO.userError "C0 staged root changed its meaning")
  let invalidRoot : PsKernelC0BoundRoot :=
    { store := badWorking, root := selected }
  if (psKernelC0BoundRootRead invalidRoot).isSome ||
      (psKernelC0BoundRootRehome leftStore invalidRoot).isSome ||
      (psKernelC0ScratchStageBoundRoot
        (psKernelC0ScratchBegin leftStore) invalidRoot).isSome then
    throw (IO.userError "C0 accepted inconsistent bound-root metadata")
  let outOfRange : PsKernelC0BoundRoot :=
    { store := rightStore, root := rightStore.nodes.size }
  if (psKernelC0BoundRootRead outOfRange).isSome ||
      (psKernelC0BoundRootRehome leftStore outOfRange).isSome then
    throw (IO.userError "C0 accepted an out-of-range bound root")

  IO.println "C0_LEAN435 indexed_scratch_promotion=pass"
