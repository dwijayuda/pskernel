import Ps.KernelCore.Core.IndexedScratch

/-!
Phase C: proof-carrying replay validation for immutable indexed snapshots.

The exact, slow canonical replay predicate already checks every node and the
complete collision-sensitive hash index. Once it has been established, an
immutable snapshot can carry a Lean equality witness rather than replaying
the whole store at every *read*. Raw Nat handles from different stores
remain unrelated. No certificate expresses typing or proof admission.
-/

/-- The mathematical children-before-parent ordering invariant for
    one node at a specific location in its owning immutable store. Leaf
    nodes have no child handles; composite nodes must refer only backward. -/
def psKernelC0NodeTopological (index : Nat)
    (node : PsKernelC0Node) : Prop :=
  match node with
  | .app fn arg => fn < index ∧ arg < index
  | .lam _ ty body _ => ty < index ∧ body < index
  | .forallE _ ty body _ => ty < index ∧ body < index
  | .letE _ ty value body _ =>
      ty < index ∧ value < index ∧ body < index
  | .mdata _ body => body < index
  | .proj _ _ body => body < index
  | _ => True

instance (index : Nat) (node : PsKernelC0Node) :
    Decidable (psKernelC0NodeTopological index node) := by
  cases node <;> dsimp [psKernelC0NodeTopological] <;> infer_instance

/-- Explicit mathematical acyclicity-by-order property of the whole store,
    independent of hashes or memoization. Unlike the replay Boolean, this
    is a dependent proposition over every valid node index. -/
def psKernelC0StoreTopological (store : PsKernelC0TermStore) : Prop :=
  ∀ i : Fin store.nodes.size,
    match psKernelC0StoreGet store i.val with
    | some entry => psKernelC0NodeTopological i.val entry.node
    | none => False

instance (store : PsKernelC0TermStore) :
    Decidable (psKernelC0StoreTopological store) := by
  unfold psKernelC0StoreTopological
  infer_instance

/-- An immutable store together with a proof that deterministic canonical
    replay accepts its entire node graph and index. A hash alone is never
    sufficient to construct this value. -/
structure PsKernelC0CertifiedStore where
  store : PsKernelC0TermStore
  canonical : psKernelC0ReplayValidateStore store = true
  topology : psKernelC0StoreTopological store

/-- Check exactly once at construction. Future code using the same immutable
    value may rely on the proof, not on an untrusted cache or a hash. -/
def psKernelC0CertifyStore
    (store : PsKernelC0TermStore) : Option PsKernelC0CertifiedStore :=
  if h : psKernelC0ReplayValidateStore store = true then
    if topology : psKernelC0StoreTopological store then
      some { store := store, canonical := h, topology := topology }
    else none
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

/-- A certified root is attached to a store satisfying an actual
    Lean proposition that all composite nodes reference earlier nodes. -/
theorem psKernelC0CertifiedRootStore_topological
    (cert : PsKernelC0CertifiedRoot) :
    psKernelC0StoreTopological cert.owner.store :=
  cert.owner.topology

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

/-- Two certified roots can belong to different immutable stores. This
    witness certifies their exact metadata-sensitive source syntax agrees;
    it never treats coincident numeric indices or hashes as equality. -/
structure PsKernelC0CertifiedTransfer where
  source : PsKernelC0CertifiedRoot
  target : PsKernelC0CertifiedRoot
  sameSyntax :
    psKernelExprEqual source.expression target.expression = true

/-- Rehome by decoding the source's certified expression and encoding it
    into the target owner. The target is independently replay-certified,
    and exact source syntax is checked before recording the relationship.
    No checked term/type judgment is implied. -/
def psKernelC0CertifiedRootRehome
    (source : PsKernelC0CertifiedRoot)
    (destination : PsKernelC0CertifiedStore) :
    Option PsKernelC0CertifiedTransfer := do
  let (store, targetId) ←
    psKernelC0EncodeExpr destination.store source.expression
  let target ← psKernelC0CertifyRoot store targetId
  if h : psKernelExprEqual source.expression target.expression = true then
    some { source := source, target := target, sameSyntax := h }
  else none

theorem psKernelC0CertifiedTransferExact
    (transfer : PsKernelC0CertifiedTransfer) :
    psKernelExprEqual transfer.source.expression
      transfer.target.expression = true :=
  transfer.sameSyntax
