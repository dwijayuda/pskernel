import Ps.KernelCore.Core.CertifiedStore

-- Exact propositional node-shape check for certificate construction.
-- This never replaces source typing or DefEq.
deriving instance DecidableEq for PsKernelC0Node

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

/-- Slow, strictly non-accepting reference witness builder for tests. It
intentionally evaluates the old source hash and must NOT be used as the
hot-path source of indexed certificates on large shared expressions.
The app constructor above builds that equality instead from exact child
certificates, without reevaluating the expanded expression hash. -/
def psKernelC0VerifiedIndexedHashSourceOracle
    (owner : PsKernelC0CertifiedStore)
    (id : Nat) :
    Option (PsKernelC0VerifiedIndexedHash owner id) :=
  match hGet : psKernelC0StoreGet owner.store id with
  | none => none
  | some entry =>
      match hRead : psKernelC0DecodeExpr owner.store id with
      | none => none
      | some expr =>
          if hHash : entry.checkerHash = psKernelExprHash expr then
            some {
              entry := entry
              expr := expr
              lookup := hGet
              readback := hRead
              valueCorrect := hHash
            }
          else none

/-- A compositional certificate can only be assembled after verifying that
the parent's owning node is exactly the indicated application and the
source readback is exactly its two certified children. This does not
recompute the original hash of the combined expanded application. -/
def psKernelC0VerifiedIndexedHashAppTry
    (owner : PsKernelC0CertifiedStore)
    (id fnId argId : Nat)
    (fn : PsKernelC0VerifiedIndexedHash owner fnId)
    (arg : PsKernelC0VerifiedIndexedHash owner argId) :
    Option (PsKernelC0VerifiedIndexedHash owner id) :=
  match hGet : psKernelC0StoreGet owner.store id with
  | none => none
  | some entry =>
      if hNode : entry.node = .app fnId argId then
        if hDerived : entry.checkerHash =
            (psKernelC0NodeHashes owner.store entry.node).snd then
          if hRead : psKernelC0DecodeExpr owner.store id =
              some (.app fn.expr arg.expr) then
            some (psKernelC0VerifiedIndexedHashApp owner id fnId argId
              entry hGet hNode hDerived fn arg hRead)
          else none
        else none
      else none

/-- Reuse the proven O(1) checker-hash field for source cache lookup. Exact
source expression equality STILL decides every hash-bucket collision. -/
def psKernelC0VerifiedIndexedCacheGet
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id)
    (cache : PsKernelExprMap) : Option PsKernelExpr :=
  psKernelExprMapGetWithKnownHash cache proof.expr
    (some (psKernelC0VerifiedIndexedHashRead proof))

/-- Complete cache-lookup refinement, including indexed/short caches and
every colliding-hash case, without trusting a hash as expression equality. -/
theorem psKernelC0VerifiedIndexedCacheGet_source
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id)
    (cache : PsKernelExprMap) :
    psKernelC0VerifiedIndexedCacheGet proof cache =
      psKernelExprMapGet cache proof.expr := by
  unfold psKernelC0VerifiedIndexedCacheGet psKernelExprMapGet
  rw [psKernelC0VerifiedIndexedHashRead_source proof]
  simp [psKernelExprMapGetWithKnownHash]

/-- Store the same source expression/type pair under its already certified
indexed hash. The canonical source map remains the semantic reference. -/
def psKernelC0VerifiedIndexedCacheInsert
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id)
    (cache : PsKernelExprMap)
    (ty : PsKernelExpr) : PsKernelExprMap :=
  psKernelExprMapInsertWithKnownHash cache proof.expr ty
    (some (psKernelC0VerifiedIndexedHashRead proof))

/-- Complete cache-update refinement: no equality, typing, failure or
resource decision changes when a cached indexed hash is provided. -/
theorem psKernelC0VerifiedIndexedCacheInsert_source
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id)
    (cache : PsKernelExprMap)
    (ty : PsKernelExpr) :
    psKernelC0VerifiedIndexedCacheInsert proof cache ty =
      psKernelExprMapInsert cache proof.expr ty := by
  unfold psKernelC0VerifiedIndexedCacheInsert psKernelExprMapInsert
  rw [psKernelC0VerifiedIndexedHashRead_source proof]
  simp [psKernelExprMapInsertWithKnownHash]

/-- An exact child-hash equality derived from its certified owning source
node, never an assumption about matching hashes across stores. -/
theorem psKernelC0VerifiedIndexedChildHash
    {owner : PsKernelC0CertifiedStore} {id : Nat}
    (proof : PsKernelC0VerifiedIndexedHash owner id) :
    psKernelC0ChildCheckerHash owner.store id =
      psKernelExprHash proof.expr := by
  simp only [psKernelC0ChildCheckerHash, proof.lookup]
  exact proof.valueCorrect

/-- Source hash of a certified metadata node, assembled in O(1)
from the child's checker-hash proof and canonical metadata. -/
def psKernelC0VerifiedIndexedHashMetadata
    (owner : PsKernelC0CertifiedStore)
    (id childId : Nat)
    (metadata : Nat)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .mdata metadata childId)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (child : PsKernelC0VerifiedIndexedHash owner childId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.mdata metadata child.expr)) :
    PsKernelC0VerifiedIndexedHash owner id := by
  have hChild := psKernelC0VerifiedIndexedChildHash child
  have hParent : entry.checkerHash =
      psKernelExprHash (.mdata metadata child.expr) := by
    calc
      entry.checkerHash =
          (psKernelC0NodeHashes owner.store entry.node).snd := hDerived
      _ = psKernelCacheMix (psKernelCacheMix 31 metadata) (psKernelC0ChildCheckerHash owner.store childId) := by
            rw [hNode]
            rfl
      _ = psKernelExprHash (.mdata metadata child.expr) := by
            simp only [psKernelExprHash, hChild]
  exact {
    entry := entry
    expr := .mdata metadata child.expr
    lookup := hGet
    readback := hRead
    valueCorrect := hParent
  }

/-- Source hash of a certified projection node, assembled in O(1)
from the child's checker-hash proof and canonical metadata. -/
def psKernelC0VerifiedIndexedHashProjection
    (owner : PsKernelC0CertifiedStore)
    (id childId : Nat)
    (name : PsKernelName) (index : Nat)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .proj name index childId)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (child : PsKernelC0VerifiedIndexedHash owner childId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.proj name index child.expr)) :
    PsKernelC0VerifiedIndexedHash owner id := by
  have hChild := psKernelC0VerifiedIndexedChildHash child
  have hParent : entry.checkerHash =
      psKernelExprHash (.proj name index child.expr) := by
    calc
      entry.checkerHash =
          (psKernelC0NodeHashes owner.store entry.node).snd := hDerived
      _ = psKernelCacheMix (psKernelCacheMix (psKernelCacheMix 32 (psKernelCacheNameHash name)) index) (psKernelC0ChildCheckerHash owner.store childId) := by
            rw [hNode]
            rfl
      _ = psKernelExprHash (.proj name index child.expr) := by
            simp only [psKernelExprHash, hChild]
  exact {
    entry := entry
    expr := .proj name index child.expr
    lookup := hGet
    readback := hRead
    valueCorrect := hParent
  }

/-- Exact source checker hash of a certified lambda binder.
The historical hash intentionally omits user binder name and info, but
the certified app node and exact readback still retain those fields. -/
def psKernelC0VerifiedIndexedHashLambda
    (owner : PsKernelC0CertifiedStore)
    (id typeId bodyId : Nat)
    (name : PsKernelName) (info : PsKernelBinderInfo)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .lam name typeId bodyId info)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (type : PsKernelC0VerifiedIndexedHash owner typeId)
    (body : PsKernelC0VerifiedIndexedHash owner bodyId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.lam name type.expr body.expr info)) :
    PsKernelC0VerifiedIndexedHash owner id := by
  have hType := psKernelC0VerifiedIndexedChildHash type
  have hBody := psKernelC0VerifiedIndexedChildHash body
  have hParent : entry.checkerHash =
      psKernelExprHash (.lam name type.expr body.expr info) := by
    calc
      entry.checkerHash =
          (psKernelC0NodeHashes owner.store entry.node).snd := hDerived
      _ = psKernelCacheMix
          (psKernelCacheMix 27
            (psKernelC0ChildCheckerHash owner.store typeId))
          (psKernelC0ChildCheckerHash owner.store bodyId) := by
            rw [hNode]
            rfl
      _ = psKernelExprHash (.lam name type.expr body.expr info) := by
            simp only [psKernelExprHash, hType, hBody]
  exact {
    entry := entry
    expr := .lam name type.expr body.expr info
    lookup := hGet
    readback := hRead
    valueCorrect := hParent
  }

/-- Exact source checker hash of a certified forall binder.
The historical hash intentionally omits user binder name and info, but
the certified app node and exact readback still retain those fields. -/
def psKernelC0VerifiedIndexedHashForall
    (owner : PsKernelC0CertifiedStore)
    (id typeId bodyId : Nat)
    (name : PsKernelName) (info : PsKernelBinderInfo)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .forallE name typeId bodyId info)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (type : PsKernelC0VerifiedIndexedHash owner typeId)
    (body : PsKernelC0VerifiedIndexedHash owner bodyId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.forallE name type.expr body.expr info)) :
    PsKernelC0VerifiedIndexedHash owner id := by
  have hType := psKernelC0VerifiedIndexedChildHash type
  have hBody := psKernelC0VerifiedIndexedChildHash body
  have hParent : entry.checkerHash =
      psKernelExprHash (.forallE name type.expr body.expr info) := by
    calc
      entry.checkerHash =
          (psKernelC0NodeHashes owner.store entry.node).snd := hDerived
      _ = psKernelCacheMix
          (psKernelCacheMix 28
            (psKernelC0ChildCheckerHash owner.store typeId))
          (psKernelC0ChildCheckerHash owner.store bodyId) := by
            rw [hNode]
            rfl
      _ = psKernelExprHash (.forallE name type.expr body.expr info) := by
            simp only [psKernelExprHash, hType, hBody]
  exact {
    entry := entry
    expr := .forallE name type.expr body.expr info
    lookup := hGet
    readback := hRead
    valueCorrect := hParent
  }

/-- Exact cached checker hash of a certified let node, including its
source nondependence bit, with all three children separately verified. -/
def psKernelC0VerifiedIndexedHashLet
    (owner : PsKernelC0CertifiedStore)
    (id typeId valueId bodyId : Nat)
    (name : PsKernelName) (nondep : Bool)
    (entry : PsKernelC0StoredNode)
    (hGet : psKernelC0StoreGet owner.store id = some entry)
    (hNode : entry.node = .letE name typeId valueId bodyId nondep)
    (hDerived :
      entry.checkerHash =
        (psKernelC0NodeHashes owner.store entry.node).snd)
    (type : PsKernelC0VerifiedIndexedHash owner typeId)
    (value : PsKernelC0VerifiedIndexedHash owner valueId)
    (body : PsKernelC0VerifiedIndexedHash owner bodyId)
    (hRead :
      psKernelC0DecodeExpr owner.store id =
        some (.letE name type.expr value.expr body.expr nondep)) :
    PsKernelC0VerifiedIndexedHash owner id := by
  have hType := psKernelC0VerifiedIndexedChildHash type
  have hValue := psKernelC0VerifiedIndexedChildHash value
  have hBody := psKernelC0VerifiedIndexedChildHash body
  have hParent : entry.checkerHash =
      psKernelExprHash (.letE name type.expr value.expr body.expr nondep) := by
    calc
      entry.checkerHash =
          (psKernelC0NodeHashes owner.store entry.node).snd := hDerived
      _ = psKernelCacheMix
          (psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix 29
                (psKernelC0ChildCheckerHash owner.store typeId))
              (psKernelC0ChildCheckerHash owner.store valueId))
            (psKernelC0ChildCheckerHash owner.store bodyId))
          (if nondep then 1 else 0) := by
            rw [hNode]
            rfl
      _ = psKernelExprHash
          (.letE name type.expr value.expr body.expr nondep) := by
            simp only [psKernelExprHash, hType, hValue, hBody]
  exact {
    entry := entry
    expr := .letE name type.expr value.expr body.expr nondep
    lookup := hGet
    readback := hRead
    valueCorrect := hParent
  }

/-- The exact historical symmetric DefEq pair-cache bucket, computed from
two certified O(1) indexed hash fields. Never a proof of definitional
equality; a bucket candidate must pass full pair syntax comparison. -/
def psKernelC0VerifiedIndexedPairHash
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) : Nat :=
  (psKernelC0VerifiedIndexedHashRead left +
    psKernelC0VerifiedIndexedHashRead right) % psKernelCacheHashModulus

theorem psKernelC0VerifiedIndexedPairHash_source
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) :
    psKernelC0VerifiedIndexedPairHash left right =
      psKernelExprPairHash left.expr right.expr := by
  simp only [psKernelC0VerifiedIndexedPairHash,
    psKernelC0VerifiedIndexedHashRead_source,
    psKernelExprPairHash]

/-- Full source semantics of success/failure DefEq cache lookup remain
unchanged. The certified pair hash is only a trie bucket selector;
psKernelExprPairSetContainsIn STILL compares the exact pair syntax. -/
def psKernelC0VerifiedIndexedPairContains
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (set : PsKernelExprPairSet)
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) : Bool :=
  match set.index with
  | none =>
      psKernelExprPairSetContainsIn left.expr right.expr set.small
  | some index =>
      psKernelExprPairSetContainsIn left.expr right.expr
        (psKernelExprPairSetIndexBucket
          psKernelC0IndexDepth index
          (psKernelC0VerifiedIndexedPairHash left right))

theorem psKernelC0VerifiedIndexedPairContains_source
    {owner : PsKernelC0CertifiedStore}
    {leftId rightId : Nat}
    (set : PsKernelExprPairSet)
    (left : PsKernelC0VerifiedIndexedHash owner leftId)
    (right : PsKernelC0VerifiedIndexedHash owner rightId) :
    psKernelC0VerifiedIndexedPairContains set left right =
      psKernelExprPairSetContains set left.expr right.expr := by
  unfold psKernelC0VerifiedIndexedPairContains
    psKernelExprPairSetContains
  cases h : set.index with
  | none => rfl
  | some index =>
      simp only [psKernelC0VerifiedIndexedPairHash_source]
