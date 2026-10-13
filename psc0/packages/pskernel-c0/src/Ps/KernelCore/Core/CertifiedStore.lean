import Ps.KernelCore.Core.IndexedScratch

/-!
Phase C: proof-carrying replay validation for immutable indexed snapshots.

The exact, slow canonical replay predicate already checks every node and the
complete collision-sensitive hash index. Once it has been established, an
immutable snapshot can carry a Lean equality witness rather than replaying
the whole store at every *read*. Raw Nat handles from different stores
remain unrelated. No certificate expresses typing or proof admission.
-/

/-- An immutable store together with a proof that deterministic canonical
    replay accepts its entire node graph and index. A hash alone is never
    sufficient to construct this value. -/
structure PsKernelC0CertifiedStore where
  store : PsKernelC0TermStore
  canonical : psKernelC0ReplayValidateStore store = true

/-- Check exactly once at construction. Future code using the same immutable
    value may rely on the proof, not on an untrusted cache or a hash. -/
def psKernelC0CertifyStore
    (store : PsKernelC0TermStore) : Option PsKernelC0CertifiedStore :=
  if h : psKernelC0ReplayValidateStore store = true then
    some { store := store, canonical := h }
  else none

/-- The owner snapshot, root-in-bounds witness, and exact decoded syntax are
    bound together. A bare Nat handle cannot cross snapshot boundaries. -/
structure PsKernelC0CertifiedRoot where
  owner : PsKernelC0CertifiedStore
  root : Nat
  inBounds : psKernelC0StoreValid owner.store root = true
  expression : PsKernelExpr
  readback : psKernelC0DecodeExpr owner.store root = some expression

/-- Reuse an already certified store when constructing a root certificate. -/
def psKernelC0CertifyRootIn
    (owner : PsKernelC0CertifiedStore)
    (root : Nat) : Option PsKernelC0CertifiedRoot :=
  if hv : psKernelC0StoreValid owner.store root = true then
    match he : psKernelC0DecodeExpr owner.store root with
    | some expr =>
        some {
          owner := owner
          root := root
          inBounds := hv
          expression := expr
          readback := he
        }
    | none => none
  else none

/-- Validate the owning store first, then the requested root. -/
def psKernelC0CertifyRoot
    (store : PsKernelC0TermStore)
    (root : Nat) : Option PsKernelC0CertifiedRoot := do
  let owner ← psKernelC0CertifyStore store
  psKernelC0CertifyRootIn owner root

/-- A certified root's exact source expression is a total, immutable value. -/
def psKernelC0CertifiedRootRead
    (cert : PsKernelC0CertifiedRoot) : PsKernelExpr :=
  cert.expression

theorem psKernelC0CertifiedRootRead_exact
    (cert : PsKernelC0CertifiedRoot) :
    psKernelC0DecodeExpr cert.owner.store cert.root =
      some (psKernelC0CertifiedRootRead cert) :=
  cert.readback

/-- Exact canonical replay is the declared invariant, not an assumed store
    hash or an axiom about untrusted metadata. -/
theorem psKernelC0CertifiedRootStore_canonical
    (cert : PsKernelC0CertifiedRoot) :
    psKernelC0ReplayValidateStore cert.owner.store = true :=
  cert.owner.canonical

/-- Atomically promote selected scratch roots through the existing replay-
    validated implementation, then construct proof-carrying owner/root pairs
    for the resulting immutable store. No staged root is treated as checked
    merely because its exact source syntax was preserved. -/
def psKernelC0CertifyPromotedRoots
    (scratch : PsKernelC0Scratch)
    (roots : List Nat) :
    Option (PsKernelC0CertifiedStore × List PsKernelC0CertifiedRoot) := do
  let (store, ids) ← psKernelC0ScratchPromoteVerifiedRoots scratch roots
  let owner ← psKernelC0CertifyStore store
  let checked ← ids.mapM (psKernelC0CertifyRootIn owner)
  if checked.length == roots.length then some (owner, checked)
  else none
