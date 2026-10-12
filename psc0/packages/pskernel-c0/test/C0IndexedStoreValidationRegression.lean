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

      let corruptHash : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id
            { root with hash := root.hash + 1 } }
      let corruptCheckerHash : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id
            { root with checkerHash := root.checkerHash + 1 } }
      let corruptDepth : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id
            { root with depth := root.depth + 1 } }
      let corruptRange : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id
            { root with looseBVarRange := root.looseBVarRange + 1 } }
      let missingIndex : PsKernelC0TermStore :=
        { store with index := PsKernelC0HashTrie.empty }
      let duplicate : PsKernelC0TermStore :=
        { store with nodes := store.nodes.push root }
      let cycle : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id
            { root with node := .app id id } }
      let dangling : PsKernelC0TermStore :=
        { store with nodes := store.nodes.set! id
            { root with node := .app (store.nodes.size + 5) 0 } }
      let malformed := [
        corruptHash, corruptCheckerHash, corruptDepth, corruptRange,
        missingIndex, duplicate, cycle, dangling
      ]
      for bad in malformed do
        if psKernelC0ReplayValidateStore bad then
          throw (IO.userError "C0 StoreWF accepted malformed indexed metadata")
      if !psKernelC0ReplayValidateStore store then
        throw (IO.userError "C0 StoreWF validation mutated immutable input")

  IO.println "C0_LEAN435 indexed_store_replay_validation=pass"
