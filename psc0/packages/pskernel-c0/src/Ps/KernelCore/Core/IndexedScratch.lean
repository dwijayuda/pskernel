import Ps.KernelCore.Core.IndexedStoreValidation

/-!
Operation-local indexed scratch storage with selective, memoized promotion.

The accepting PSKernel-C0 uses recursive source expressions. This module
explores the persistent/scratch lifetime split used by con-ron, but does NOT
implement its packed u32 handles, its physical per-constructor arrays or its
proved StoreWF invariant.

Scratch references may point to already-committed terms. Selected roots
are remapped into the persistent canonical store, children before parents;
unselected scratch nodes are discarded. Replaying both stores and validating
the persistent prefix before promotion rejects inconsistent externally
constructed stores. A numeric handle is never a type-checking judgment.
-/

structure PsKernelC0Scratch where
  persistent : PsKernelC0TermStore
  working : PsKernelC0TermStore

def psKernelC0ScratchBegin
    (persistent : PsKernelC0TermStore) : PsKernelC0Scratch :=
  { persistent := persistent, working := persistent }

/-- Unpromoted scratch nodes do not enter the persistent result. -/
def psKernelC0ScratchAbort
    (scratch : PsKernelC0Scratch) : PsKernelC0TermStore :=
  scratch.persistent

def psKernelC0ScratchIntern
    (scratch : PsKernelC0Scratch)
    (node : PsKernelC0Node) :
    Option (PsKernelC0Scratch × Nat) := do
  let (working, id) ← psKernelC0Intern scratch.working node
  some ({ scratch with working := working }, id)

def psKernelC0ScratchEncode
    (scratch : PsKernelC0Scratch)
    (expr : PsKernelExpr) :
    Option (PsKernelC0Scratch × Nat) := do
  let (working, id) ← psKernelC0EncodeExpr scratch.working expr
  some ({ scratch with working := working }, id)

def psKernelC0ScratchStoredEqual
    (a b : PsKernelC0StoredNode) : Bool :=
  psKernelC0NodeEq a.node b.node &&
    a.hash == b.hash && a.checkerHash == b.checkerHash &&
    a.depth == b.depth &&
    a.looseBVarRange == b.looseBVarRange

/-- Slow admission-to-a-syntax-store gate, not a kernel acceptance check.
    Both entire indexes must replay to canonical form and every persistent
    entry must appear unchanged as a prefix of working entries. -/
def psKernelC0ScratchValid
    (scratch : PsKernelC0Scratch) : Bool := Id.run do
  if scratch.working.nodes.size < scratch.persistent.nodes.size then
    return false
  if !psKernelC0ReplayValidateStore scratch.persistent ||
      !psKernelC0ReplayValidateStore scratch.working then
    return false
  for id in [:scratch.persistent.nodes.size] do
    let some a := psKernelC0StoreGet scratch.persistent id
      | return false
    let some b := psKernelC0StoreGet scratch.working id
      | return false
    if !psKernelC0ScratchStoredEqual a b then return false
  return true

abbrev PsKernelC0ScratchMemo := PsKernelC0HashTrie (Nat × Nat)

structure PsKernelC0ScratchPromotionState where
  persistent : PsKernelC0TermStore
  memo : PsKernelC0ScratchMemo

def psKernelC0ScratchMemoFind (id : Nat) :
    List (Nat × Nat) → Option Nat
  | [] => none
  | (source, target) :: rest =>
      if source == id then some target
      else psKernelC0ScratchMemoFind id rest

def psKernelC0ScratchMemoHash (id : Nat) : Nat :=
  psKernelCacheMix 73 id

def psKernelC0ScratchMemoGet
    (memo : PsKernelC0ScratchMemo) (id : Nat) : Option Nat :=
  psKernelC0ScratchMemoFind id
    (psKernelC0TrieBucket psKernelC0IndexDepth memo
      (psKernelC0ScratchMemoHash id))

def psKernelC0ScratchMemoPut
    (memo : PsKernelC0ScratchMemo)
    (id target : Nat) : PsKernelC0ScratchMemo :=
  let hash := psKernelC0ScratchMemoHash id
  let bucket := psKernelC0TrieBucket psKernelC0IndexDepth memo hash
  psKernelC0TrieSet psKernelC0IndexDepth memo hash
    ((id, target) :: bucket)

/-- Rewrite reachable child IDs from a staged store to canonical persistent
    IDs, sharing one per-operation memo. Exhausted fuel/invalid handles
    return none and leave the immutable input store unchanged. -/
def psKernelC0ScratchPromoteWithFuel
    (fuel : Nat)
    (scratch : PsKernelC0Scratch)
    (state : PsKernelC0ScratchPromotionState)
    (id : Nat) :
    Option (PsKernelC0ScratchPromotionState × Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let entry ← psKernelC0StoreGet scratch.working id
      if id < scratch.persistent.nodes.size then
        some (state, id)
      else
        match psKernelC0ScratchMemoGet state.memo id with
        | some cached => some (state, cached)
        | none => do
            let (next, remapped) ←
              match entry.node with
              | .app fn arg => do
                  let (s1, f) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch state fn
                  let (s2, a) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch s1 arg
                  some (s2, PsKernelC0Node.app f a)
              | .lam name ty body info => do
                  let (s1, t) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch state ty
                  let (s2, b) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch s1 body
                  some (s2, PsKernelC0Node.lam name t b info)
              | .forallE name ty body info => do
                  let (s1, t) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch state ty
                  let (s2, b) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch s1 body
                  some (s2, PsKernelC0Node.forallE name t b info)
              | .letE name ty value body nondep => do
                  let (s1, t) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch state ty
                  let (s2, v) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch s1 value
                  let (s3, b) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch s2 body
                  some (s3, PsKernelC0Node.letE name t v b nondep)
              | .mdata metadata body => do
                  let (s1, b) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch state body
                  some (s1, PsKernelC0Node.mdata metadata b)
              | .proj name index body => do
                  let (s1, b) ← psKernelC0ScratchPromoteWithFuel
                    remaining scratch state body
                  some (s1, PsKernelC0Node.proj name index b)
              | other => some (state, other)
            let (persistent, result) ← psKernelC0Intern next.persistent remapped
            let memo := psKernelC0ScratchMemoPut next.memo id result
            some ({ persistent := persistent, memo := memo }, result)

/-- One atomic promotion of all requested roots. No unselected temporary
    term or scratch reference survives in the returned canonical store. -/
def psKernelC0ScratchPromoteRoots
    (scratch : PsKernelC0Scratch)
    (roots : List Nat) :
    Option (PsKernelC0TermStore × List Nat) := do
  if !psKernelC0ScratchValid scratch then none
  else do
    let mut state : PsKernelC0ScratchPromotionState :=
      { persistent := scratch.persistent,
        memo := PsKernelC0HashTrie.empty }
    let mut outputs : List Nat := []
    for id in roots do
      let entry ← psKernelC0StoreGet scratch.working id
      let (s, target) ← psKernelC0ScratchPromoteWithFuel
        entry.depth scratch state id
      state := s
      outputs := target :: outputs
    some (state.persistent, outputs.reverse)

def psKernelC0ScratchPromote
    (scratch : PsKernelC0Scratch)
    (id : Nat) : Option (PsKernelC0TermStore × Nat) := do
  let (persistent, ids) ← psKernelC0ScratchPromoteRoots scratch [id]
  let root ← ids.head?
  some (persistent, root)

/-- Checked syntax-store boundary for future indexed execution experiments.
    This is intentionally more expensive than ordinary promotion: it verifies
    the *resulting* canonical index independently and re-decodes each selected
    source/target pair with metadata-sensitive exact syntax equality. A cache
    hash, numeric ID or an unchecked promotion never establishes this fact.
    Source acceptance and kernel judgments are deliberately out of scope. -/
def psKernelC0ScratchPromoteVerifiedRoots
    (scratch : PsKernelC0Scratch)
    (roots : List Nat) :
    Option (PsKernelC0TermStore × List Nat) := do
  let (committed, targets) ← psKernelC0ScratchPromoteRoots scratch roots
  if roots.length != targets.length ||
      !psKernelC0ReplayValidateStore committed then
    none
  else do
    for (source, target) in roots.zip targets do
      let before ← psKernelC0DecodeExpr scratch.working source
      let after ← psKernelC0DecodeExpr committed target
      if !psKernelExprEqual before after then
        none
    some (committed, targets)

/-- Single-root counterpart of the independently validated syntax promotion.
    The exported Nat remains store-local: this API does not seal ownership,
    grant any typing judgment or transfer con-ron's StoreWF proof. -/
def psKernelC0ScratchPromoteVerified
    (scratch : PsKernelC0Scratch)
    (root : Nat) : Option (PsKernelC0TermStore × Nat) := do
  let (committed, targets) ←
    psKernelC0ScratchPromoteVerifiedRoots scratch [root]
  let target ← targets.head?
  some (committed, target)

/-- A root paired with its exact source store. Constructing this structure
    makes no validity claim; every observation replays its owning store. -/
structure PsKernelC0BoundRoot where
  store : PsKernelC0TermStore
  root : Nat

/-- Checked source readback: a numeric handle alone is never portable. -/
def psKernelC0BoundRootRead
    (bound : PsKernelC0BoundRoot) : Option PsKernelExpr := do
  if !psKernelC0ReplayValidateStore bound.store then none
  else psKernelC0DecodeExpr bound.store bound.root

/-- Copy a validated source root into another canonical store by preserving
    its complete expression, never by reinterpreting its numeric handle.
    This is a syntax-only operation and supplies no typing judgment. -/
def psKernelC0BoundRootRehome
    (target : PsKernelC0TermStore)
    (bound : PsKernelC0BoundRoot) : Option PsKernelC0BoundRoot := do
  let expression ← psKernelC0BoundRootRead bound
  if !psKernelC0ReplayValidateStore target then none
  else do
    let (store, root) ← psKernelC0EncodeExpr target expression
    if !psKernelC0ReplayValidateStore store then none
    else do
      let result ← psKernelC0DecodeExpr store root
      if psKernelExprEqual expression result then
        some { store := store, root := root }
      else none

/-- Transactional staging from an independently stored expression. Each
    source and destination receives its own canonical replay validation. -/
def psKernelC0ScratchStageBoundRoot
    (scratch : PsKernelC0Scratch)
    (bound : PsKernelC0BoundRoot) :
    Option (PsKernelC0Scratch × Nat) := do
  if !psKernelC0ScratchValid scratch then none
  else do
    let expression ← psKernelC0BoundRootRead bound
    let (next, root) ← psKernelC0ScratchEncode scratch expression
    if !psKernelC0ScratchValid next then none
    else do
      let actual ← psKernelC0DecodeExpr next.working root
      if psKernelExprEqual expression actual then some (next, root)
      else none

/-- Import a list of independently owned syntax roots into one checked
    canonical snapshot. Foreign Nat handles are *never* interpreted against
    the destination. Staging is immutable and the final promotion is atomic:
    any malformed root fails the entire import without changing the input.
    Repeated roots retain canonical sharing and source order. This is solely
    a representation boundary, not a kernel judgment or a StoreWF proof. -/
def psKernelC0ScratchImportBoundRoots
    (persistent : PsKernelC0TermStore)
    (sources : List PsKernelC0BoundRoot) :
    Option (PsKernelC0TermStore × List Nat) := do
  if !psKernelC0ReplayValidateStore persistent then none
  else do
    let mut scratch := psKernelC0ScratchBegin persistent
    let mut stagedIds : List Nat := []
    for bound in sources do
      let (next, id) ← psKernelC0ScratchStageBoundRoot scratch bound
      scratch := next
      stagedIds := id :: stagedIds
    let (committed, outputs) ←
      psKernelC0ScratchPromoteVerifiedRoots scratch stagedIds.reverse
    if outputs.length != sources.length then none
    else do
      for (bound, id) in sources.zip outputs do
        let original ← psKernelC0BoundRootRead bound
        let copied ← psKernelC0DecodeExpr committed id
        if !psKernelExprEqual original copied then none
      some (committed, outputs)
