import Ps.KernelCore.Core.IndexedExpr

/-!
Replay validation of one independently constructed canonical indexed store.

Con-ron's verified two-tier arena depends on a StoreWF invariant: no forward
references, canonical interning, correct derived columns and a readable index.
C0's public Nat handles and store constructors currently carry NO analogous
formal proof. This deliberately slow checker reconstructs interned nodes in
their stored order and checks the required local facts before a caller may
even *consider* an indexed store as well formed.

This is not a formal StoreWF proof and cannot seal an external Nat handle
against reuse in another store. However, it now checks the *entire* radix trie
against deterministic replay, including the absence of extraneous bucket
entries. It remains an offline, non-accepting diagnostic.
-/

/-- Entire canonical radix index equality, bounded by the fixed trie
    depth. This compares all child slots and leaf ID lists, including empty
    slots, so a reachable index cannot hide a ghost/duplicate entry. The
    replayed trie was built independently using canonical PsKernelC0Intern. -/
def psKernelC0IndexReplayEqualWithFuel
    (fuel : Nat)
    (left right : PsKernelC0Trie) : Bool :=
  match fuel with
  | 0 =>
      match left, right with
      | .empty, .empty => true
      | .bucket xs, .bucket ys => xs == ys
      | _, _ => false
  | remaining + 1 =>
      match left, right with
      | .empty, .empty => true
      | .branch first second =>
          if first.size != second.size then false
          else Id.run do
            for i in [:first.size] do
              let some lhs := first[i]?
                | return false
              let some rhs := second[i]?
                | return false
              if !psKernelC0IndexReplayEqualWithFuel remaining lhs rhs then
                return false
            return true
      | _, _ => false

/-- Replaying nodes against an initially empty canonical store enforces:
    (1) every child points to a strictly earlier valid node;
    (2) no duplicate node has a distinct canonical handle;
    (3) hash/checkerHash, depth and loose-bvar range equal recomputation;
    (4) each stored node is discoverable in its own collision-checked bucket.
    (5) the **entire** radix index exactly matches independently replayed
    canonical insertion, including no ghost or duplicate bucket entries.
    Validation costs a full replay and is never used as a hot-path shortcut. -/
def psKernelC0ReplayValidateStore
    (store : PsKernelC0TermStore) : Bool := Id.run do
  let mut rebuilt := psKernelC0StoreEmpty
  for i in [:store.nodes.size] do
    let some source := psKernelC0StoreGet store i
      | return false
    match psKernelC0Intern rebuilt source.node with
    | none => return false
    | some (next, canonical) =>
        if canonical != i then return false
        let some actual := psKernelC0StoreGet next canonical
          | return false
        if !psKernelC0NodeEq actual.node source.node ||
            actual.hash != source.hash ||
            actual.checkerHash != source.checkerHash ||
            actual.depth != source.depth ||
            actual.looseBVarRange != source.looseBVarRange then
          return false
        let candidates := psKernelC0TermTrieBucket
          psKernelC0IndexDepth store.index source.hash
        match psKernelC0FindNode store source.node candidates with
        | none => return false
        | some found =>
            if found != i then return false
        rebuilt := next
  return psKernelC0IndexReplayEqualWithFuel
    psKernelC0IndexDepth store.index rebuilt.index
