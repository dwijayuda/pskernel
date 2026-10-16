import Ps.KernelCore.Architecture.VerifiedIndexedHash

/-!
Certification of immutable indexed checker-hash metadata on an application.
The source-hash oracle is called only for two small leaf nodes and the
negative control. The parent proof uses exact child certificates rather
than recomputing a shared expanded source syntax tree.
-/

def main : IO Unit := do
  let fnExpr : PsKernelExpr := .sort .zero
  let argExpr : PsKernelExpr := .lit (.nat 7)
  let rootExpr : PsKernelExpr := .app fnExpr argExpr
  let some (s1, fnId) := psKernelC0EncodeExpr psKernelC0StoreEmpty fnExpr
    | throw (IO.userError "indexed-hash: cannot encode function")
  let some (s2, argId) := psKernelC0EncodeExpr s1 argExpr
    | throw (IO.userError "indexed-hash: cannot encode argument")
  let some (store, rootId) := psKernelC0EncodeExpr s2 rootExpr
    | throw (IO.userError "indexed-hash: cannot encode app")
  let some owner := psKernelC0CertifyStore store
    | throw (IO.userError "indexed-hash: cannot certify canonical source store")
  let some fn := psKernelC0VerifiedIndexedHashSourceOracle owner fnId
    | throw (IO.userError "indexed-hash: source function hash certificate failed")
  let some arg := psKernelC0VerifiedIndexedHashSourceOracle owner argId
    | throw (IO.userError "indexed-hash: source argument hash certificate failed")
  let some combined := psKernelC0VerifiedIndexedHashAppTry
      owner rootId fnId argId fn arg
    | throw (IO.userError "indexed-hash: source-certified app assembly declined")
  let _exactSource :
      psKernelC0VerifiedIndexedHashRead combined =
        psKernelExprHash combined.expr :=
    psKernelC0VerifiedIndexedHashRead_source combined
  if psKernelC0VerifiedIndexedHashRead combined != psKernelExprHash rootExpr then
    throw (IO.userError "indexed-hash: source application hash mismatch")
  -- Force the source cache past its small-entry threshold into the
  -- persistent radix index, where precomputed hash lookup matters.
  let cache := (List.range 14).foldl
    (fun state (n : Nat) =>
      psKernelExprMapInsert state (.lit (.nat n)) (.sort .zero))
    psKernelExprMapEmpty
  let resultType : PsKernelExpr := .sort (.succ .zero)
  let sourceCache := psKernelExprMapInsert cache combined.expr resultType
  let acceleratedCache :=
    psKernelC0VerifiedIndexedCacheInsert combined cache resultType
  let _exactInsertion :
      acceleratedCache = sourceCache :=
    psKernelC0VerifiedIndexedCacheInsert_source combined cache resultType
  let _exactLookup :
      psKernelC0VerifiedIndexedCacheGet combined acceleratedCache =
        psKernelExprMapGet acceleratedCache combined.expr :=
    psKernelC0VerifiedIndexedCacheGet_source combined acceleratedCache
  if psKernelC0VerifiedIndexedCacheGet combined acceleratedCache !=
      psKernelExprMapGet sourceCache combined.expr then
    throw (IO.userError "indexed-hash: checked indexed cache lookup differs from source")
  if !(psKernelC0VerifiedIndexedCacheGet combined cache).isNone then
    throw (IO.userError "indexed-hash: incorrect hit before inserting source term")
  if (psKernelC0VerifiedIndexedHashAppTry
      owner rootId argId fnId arg fn).isSome then
    throw (IO.userError "indexed-hash: swapped source children forged an app certificate")
  if (psKernelC0VerifiedIndexedHashAppTry
      owner (rootId + 100) fnId argId fn arg).isSome then
    throw (IO.userError "indexed-hash: nonexistent source root accepted")
  let forged := { store with index := PsKernelC0HashTrie.empty }
  if (psKernelC0CertifyStore forged).isSome then
    throw (IO.userError "indexed-hash: forged indexed store was certified")
  IO.println "C0_VERIFIED_INDEXED_HASH root=app certified_children=2 source_hash=equal swapped=declined nonexistent=declined forged=declined"
