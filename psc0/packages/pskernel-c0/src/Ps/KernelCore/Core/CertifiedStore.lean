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

/-- The indexed lookup is decidable for each specific Fin index,
    including the (unreachable in a valid store) missing-node branch. -/
private instance (store : PsKernelC0TermStore)
    (i : Fin store.nodes.size) :
    Decidable
      (match psKernelC0StoreGet store i.val with
      | some entry => psKernelC0NodeTopological i.val entry.node
      | none => False) := by
  cases h : psKernelC0StoreGet store i.val with
  | none =>
      simpa [h] using (inferInstance : Decidable False)
  | some entry =>
      simpa [h] using
        (inferInstance : Decidable (psKernelC0NodeTopological i.val entry.node))

instance (store : PsKernelC0TermStore) :
    Decidable (psKernelC0StoreTopological store) := by
  unfold psKernelC0StoreTopological
  infer_instance

/-- The stored columns must equal their *actual* child-derived
    values in this immutable store. This is a mathematical proposition over
    the exact stored entry, not an assumption based on a hash match. -/
def psKernelC0NodeColumnsCorrect
    (store : PsKernelC0TermStore)
    (i : Fin store.nodes.size) : Prop :=
  let entry := store.nodes[i]
  let hashes := psKernelC0NodeHashes store entry.node
  entry.hash = hashes.fst ∧
    entry.checkerHash = hashes.snd ∧
    entry.depth = psKernelC0NodeDepth store entry.node ∧
    entry.looseBVarRange = psKernelC0NodeLooseRange store entry.node

private instance (store : PsKernelC0TermStore)
    (i : Fin store.nodes.size) :
    Decidable (psKernelC0NodeColumnsCorrect store i) := by
  unfold psKernelC0NodeColumnsCorrect
  infer_instance

/-- All stored hash, checker-hash, depth and de Bruijn-range columns
    are exactly recomputed from the immutable graph. -/
def psKernelC0StoreColumnsCorrect
    (store : PsKernelC0TermStore) : Prop :=
  ∀ i : Fin store.nodes.size, psKernelC0NodeColumnsCorrect store i

instance (store : PsKernelC0TermStore) :
    Decidable (psKernelC0StoreColumnsCorrect store) := by
  unfold psKernelC0StoreColumnsCorrect
  infer_instance

/-- Each node must be discoverable in its own collision-checked index
    bucket at its exact canonical ID. This expresses per-node index
    ownership without quadratic all-pairs comparison or trusting a hash
    collision as equality. Global absence of ghost bucket entries is
    separately established by the canonical replay proof. -/
def psKernelC0NodeIndexedAt
    (store : PsKernelC0TermStore)
    (i : Fin store.nodes.size) : Prop :=
  let entry := store.nodes[i]
  psKernelC0FindNode store entry.node
    (psKernelC0TermTrieBucket psKernelC0IndexDepth
      store.index entry.hash) = some i.val

private instance (store : PsKernelC0TermStore)
    (i : Fin store.nodes.size) :
    Decidable (psKernelC0NodeIndexedAt store i) := by
  unfold psKernelC0NodeIndexedAt
  infer_instance

def psKernelC0StoreIndexed
    (store : PsKernelC0TermStore) : Prop :=
  ∀ i : Fin store.nodes.size, psKernelC0NodeIndexedAt store i

instance (store : PsKernelC0TermStore) :
    Decidable (psKernelC0StoreIndexed store) := by
  unfold psKernelC0StoreIndexed
  infer_instance

/-- A coherent, explicit mathematical representation invariant:
    topological acyclicity, exact derived columns, canonical per-node
    index discovery, and the independently replayed whole collision
    index (the latter carried separately in CertifiedStore). -/
def psKernelC0StoreWF (store : PsKernelC0TermStore) : Prop :=
  psKernelC0StoreTopological store ∧
    psKernelC0StoreColumnsCorrect store ∧
    psKernelC0StoreIndexed store

instance (store : PsKernelC0TermStore) :
    Decidable (psKernelC0StoreWF store) := by
  unfold psKernelC0StoreWF
  infer_instance

/-- An immutable store together with a proof that deterministic canonical
    replay accepts its entire node graph and index. A hash alone is never
    sufficient to construct this value. -/
structure PsKernelC0CertifiedStore where
  store : PsKernelC0TermStore
  canonical : psKernelC0ReplayValidateStore store = true
  wellFormed : psKernelC0StoreWF store

/-- Check exactly once at construction. Future code using the same immutable
    value may rely on the proof, not on an untrusted cache or a hash. -/
/-- Keep the certified immutable store tied to the EXACT argument
    snapshot with propositional equality, not just the same hash or a
    coincidentally equal numeric root handle. -/
def psKernelC0CertifyStoreOwned
    (store : PsKernelC0TermStore) :
    Option { cert : PsKernelC0CertifiedStore // cert.store = store } :=
  if h : psKernelC0ReplayValidateStore store = true then
    if wf : psKernelC0StoreWF store then
      some ⟨{ store := store, canonical := h, wellFormed := wf }, rfl⟩
    else none
  else none

/-- Ordinary certificate API; preserve the provenance-aware variant for
    callers that must transport a proof across checked work sessions. -/
def psKernelC0CertifyStore
    (store : PsKernelC0TermStore) : Option PsKernelC0CertifiedStore :=
  (psKernelC0CertifyStoreOwned store).map Subtype.val

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
  cert.owner.wellFormed.1

/-- The derived metadata and canonical-index ownership are proven
    properties of this exact immutable stored expression graph. -/
theorem psKernelC0CertifiedRootColumns_correct
    (cert : PsKernelC0CertifiedRoot) :
    psKernelC0StoreColumnsCorrect cert.owner.store :=
  cert.owner.wellFormed.2.1

theorem psKernelC0CertifiedRootIndex_correct
    (cert : PsKernelC0CertifiedRoot) :
    psKernelC0StoreIndexed cert.owner.store :=
  cert.owner.wellFormed.2.2

theorem psKernelC0CertifiedRootStore_wf
    (cert : PsKernelC0CertifiedRoot) :
    psKernelC0StoreWF cert.owner.store :=
  cert.owner.wellFormed

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
