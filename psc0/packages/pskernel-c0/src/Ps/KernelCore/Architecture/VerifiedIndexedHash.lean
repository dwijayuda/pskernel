import Ps.KernelCore.Core.CertifiedStore

/-!
Verified source-hash readout for a certified immutable indexed expression.

The actual checker hash is a cached array field; it is NEVER a proof of
expression equality, definitional equality, type checking or admission.
One compositional constructor proves that an indexed application field
equals the historical source expression hash using exact child
certificates and the independently certified node metadata.

The client must supply:
- exact parent and child handles from the SAME certified store;
- the real parent/child source readback proofs;
- the parent node's certified hash-column equation.
No raw Nat handle, fingerprint, or coincident hash suffices.
-/

/-- Source-hash evidence scoped to an owned, canonical, immutable store. -/
structure PsKernelC0VerifiedIndexedHash
    (owner : PsKernelC0CertifiedStore)
    (id : Nat) where
  entry : PsKernelC0StoredNode
  expr : PsKernelExpr
  lookup : psKernelC0StoreGet owner.store id = some entry
  readback : psKernelC0DecodeExpr owner.store id = some expr
  valueCorrect : entry.checkerHash = psKernelExprHash expr

/-- Constant-time field readout after the proof of correctness is carried. -/
def psKernelC0VerifiedIndexedHashRead
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id) : Nat :=
  proof.entry.checkerHash

theorem psKernelC0VerifiedIndexedHashRead_source
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id) :
    psKernelC0VerifiedIndexedHashRead proof = psKernelExprHash proof.expr :=
  proof.valueCorrect

/-- The app case of a compositional certified DAG-hash calculation.
Only the source-equivalent child checker hashes, together with the
parent's separately validated derived column, enter the equation.
The source expression readback is required and cannot be guessed. -/
def psKernelC0VerifiedIndexedHashApp
    (owner : PsKernelC0CertifiedStore)
    (id fnId argId : Nat)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .app fnId argId)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (fn : PsKernelC0VerifiedIndexedHash owner fnId)
    (arg : PsKernelC0VerifiedIndexedHash owner argId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.app fn.expr arg.expr)) :
    PsKernelC0VerifiedIndexedHash owner id := by
  have hFn :
      psKernelC0ChildCheckerHash owner.store fnId =
        psKernelExprHash fn.expr := by
    simp only [psKernelC0ChildCheckerHash, fn.lookup]
    exact fn.valueCorrect
  have hArg :
      psKernelC0ChildCheckerHash owner.store argId =
        psKernelExprHash arg.expr := by
    simp only [psKernelC0ChildCheckerHash, arg.lookup]
    exact arg.valueCorrect
  have hParent :
      entry.checkerHash =
        psKernelExprHash (.app fn.expr arg.expr) := by
    calc
      entry.checkerHash =
          (psKernelC0NodeHashes owner.store entry.node).snd := hDerived
      _ = psKernelCacheMix
          (psKernelCacheMix 26
            (psKernelC0ChildCheckerHash owner.store fnId))
          (psKernelC0ChildCheckerHash owner.store argId) := by
            rw [hNode]
            rfl
      _ = psKernelExprHash (.app fn.expr arg.expr) := by
            simp only [psKernelExprHash, hFn, hArg]
  exact {
    entry := entry
    expr := .app fn.expr arg.expr
    lookup := hGet
    readback := hRead
    valueCorrect := hParent
  }

/-- A source-hash certificate does NOT establish source expression equality.
In particular no theorem or declaration is accepted based on this field. -/
theorem psKernelC0VerifiedIndexedHashApp_source
    (owner : PsKernelC0CertifiedStore)
    (id fnId argId : Nat)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .app fnId argId)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (fn : PsKernelC0VerifiedIndexedHash owner fnId)
    (arg : PsKernelC0VerifiedIndexedHash owner argId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.app fn.expr arg.expr)) :
    psKernelC0VerifiedIndexedHashRead
        (psKernelC0VerifiedIndexedHashApp owner id fnId argId entry
          hGet hNode hDerived fn arg hRead) =
      psKernelExprHash (.app fn.expr arg.expr) :=
  psKernelC0VerifiedIndexedHashRead_source _
