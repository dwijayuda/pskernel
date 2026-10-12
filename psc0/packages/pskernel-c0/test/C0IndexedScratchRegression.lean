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
  | some (next, _) => scratch := next
  match psKernelC0ScratchEncode scratch
      (.lam name leaf (.bvar 0) .implicit) with
  | none => throw (IO.userError "C0 unused binder construction failed")
  | some (next, _) => scratch := next

  if !psKernelC0ScratchValid scratch ||
      psKernelC0ScratchAbort scratch |>.nodes.size != persistent.nodes.size then
    throw (IO.userError "C0 scratch discarded or mutated persistent nodes")

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
  if psKernelC0ScratchValid forged ||
      (psKernelC0ScratchPromote forged selected).isSome then
    throw (IO.userError "C0 accepted forged derived node metadata")

  IO.println "C0_LEAN435 indexed_scratch_promotion=pass"
