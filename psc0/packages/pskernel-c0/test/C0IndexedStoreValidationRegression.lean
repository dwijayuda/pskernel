import Ps.KernelCore.Core.IndexedStoreValidation

/-!
Fail-closed, non-accepting indexed term-store invariant regression.
This is executable negative conformance, not a formal StoreWF theorem.
-/

def main : IO Unit := do
  if !psKernelC0ReplayValidateStore psKernelC0StoreEmpty then
    throw (IO.userError "C0 rejected a valid empty canonical store")
  let name := PsKernelName.str PsKernelName.anonymous "Arena.invariant"
  let domain : PsKernelExpr := .sort .zero
  let body : PsKernelExpr := .app (.bvar 0) (.lit (.nat 7))
  let term : PsKernelExpr := .mdata 11
    (.letE name domain (.lam name domain body .implicit)
      (.app (.bvar 0) domain) false)
  match psKernelC0EncodeExpr psKernelC0StoreEmpty term with
  | none => throw (IO.userError "C0 StoreWF sample encode failed")
  | some (store, id) =>
      if !psKernelC0ReplayValidateStore store then
        throw (IO.userError "C0 StoreWF rejected a canonical expression")
      let some root := psKernelC0StoreGet store id
        | throw (IO.userError "C0 StoreWF root missing")

      -- Build altered nodes separately; all variants exercise the same
      -- one-node replacement rather than relying on nested record syntax.
      let hashNode : PsKernelC0StoredNode :=
        { root with hash := root.hash + 1 }
      let checkerHashNode : PsKernelC0StoredNode :=
        { root with checkerHash := root.checkerHash + 1 }
      let depthNode : PsKernelC0StoredNode :=
        { root with depth := root.depth + 1 }
      let rangeNode : PsKernelC0StoredNode :=
        { root with looseBVarRange := root.looseBVarRange + 1 }
      let cycleNode : PsKernelC0StoredNode :=
        { root with node := .app id id }
      let danglingNode : PsKernelC0StoredNode :=
        { root with node := .app (store.nodes.size + 5) 0 }

      let corruptHash : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id hashNode }
      let corruptCheckerHash : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id checkerHashNode }
      let corruptDepth : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id depthNode }
      let corruptRange : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id rangeNode }
      let missingIndex : PsKernelC0TermStore :=
        { store with index := PsKernelC0HashTrie.empty }
      let duplicate : PsKernelC0TermStore :=
        { store with nodes := store.nodes.push root }
      let cycle : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id cycleNode }
      let dangling : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id danglingNode }
      -- The original per-node lookup still succeeds if the index
      -- also contains a forged/duplicated candidate ID. Full replay
      -- equality now detects both incorrect bucket memberships.
      let bucket := psKernelC0TermTrieBucket psKernelC0IndexDepth
        store.index root.hash
      let forgedIndex := psKernelC0TermTrieReplace
        psKernelC0IndexDepth store.index root.hash
        ((store.nodes.size + 3) :: bucket)
      let repeatedIndex := psKernelC0TermTrieReplace
        psKernelC0IndexDepth store.index root.hash
        (id :: bucket)
      let forged : PsKernelC0TermStore :=
        { store with index := forgedIndex }
      let repeatedId : PsKernelC0TermStore :=
        { store with index := repeatedIndex }
      let malformed := [
        corruptHash, corruptCheckerHash, corruptDepth, corruptRange,
        missingIndex, duplicate, cycle, dangling, forged, repeatedId
      ]
      for bad in malformed do
        if psKernelC0ReplayValidateStore bad then
          throw (IO.userError "C0 StoreWF accepted malformed indexed metadata")
      if !psKernelC0ReplayValidateStore store then
        throw (IO.userError "C0 StoreWF validation mutated immutable input")

  IO.println "C0_LEAN435 indexed_store_replay_validation=pass"
