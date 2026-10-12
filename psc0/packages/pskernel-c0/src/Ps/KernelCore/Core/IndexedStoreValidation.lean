import Ps.KernelCore.Core.IndexedExpr

/-!
Replay validation of one independently constructed canonical indexed store.

Con-ron's verified two-tier arena depends on a StoreWF invariant: no forward
references, canonical interning, correct derived columns and a readable index.
C0's public Nat handles and store constructors currently carry NO analogous
formal proof. This deliberately slow checker reconstructs interned nodes in
their stored order and checks the required local facts before a caller may
even *consider* an indexed store as well formed.

This is not a proof of StoreWF, not a seal against handles copied from
another store, not a complete check that an index contains no extraneous
unreachable entries, and not an accepting kernel operation.
-/

/-- Replaying nodes against an initially empty canonical store enforces:
    (1) every child points to a strictly earlier valid node;
    (2) no duplicate node has a distinct canonical handle;
    (3) hash/checkerHash, depth and loose-bvar range equal recomputation;
    (4) each stored node is discoverable in its own collision-checked bucket.
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
  return true
