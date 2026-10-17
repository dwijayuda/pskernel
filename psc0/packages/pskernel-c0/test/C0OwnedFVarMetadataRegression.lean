import Ps.KernelCore.Core.IndexedExpr

/-!
Owner-local, pure FVar syntactic metadata. A stored ID never transports
a type, equality judgment, proof admission or result from another store.
Each decoded modest expression is independently checked against the original
psKernelExprHasFVar source. Large shared DAGs are inspected via O(1)
same-owner metadata without exponentially expanding the source term.
-/

def c0FVarStoredNames : List PsKernelName :=
  [.str .anonymous "x", .str .anonymous "y"]

def c0FVarIndexedCheckDecoded
    (store : PsKernelC0TermStore)
    (id : Nat) : IO Unit := do
  let some stored ← pure (psKernelC0StoreGet store id)
    | throw (IO.userError "stored node unexpectedly unavailable")
  let some syntax ← pure (psKernelC0DecodeExpr store id)
    | throw (IO.userError "valid stored syntax could not be decoded")
  let some indexed ← pure (psKernelC0StoredHasFVar store id)
    | throw (IO.userError "stored FVar metadata not addressable")
  let source := psKernelExprHasFVar syntax
  if stored.hasFVar != source || indexed != source then
    throw (IO.userError "canonical node FVar flag differs from original source")

theorem c0FVarNodeAppSource
    (store : PsKernelC0TermStore) (fn arg : Nat) :
    psKernelC0NodeHasFVar store (.app fn arg) =
      (psKernelC0ChildHasFVar store fn ||
       psKernelC0ChildHasFVar store arg) := rfl

theorem c0FVarNodeLetSource
    (store : PsKernelC0TermStore)
    (name : PsKernelName)
    (ty value body : Nat)
    (nondep : Bool) :
    psKernelC0NodeHasFVar store (.letE name ty value body nondep) =
      (psKernelC0ChildHasFVar store ty ||
       psKernelC0ChildHasFVar store value ||
       psKernelC0ChildHasFVar store body) := rfl

def main : IO Unit := do
  let x := c0FVarStoredNames[0]!
  let y := c0FVarStoredNames[1]!
  let atom : PsKernelExpr := .const x []
  let variable : PsKernelExpr := .fvar y
  let expressions : List PsKernelExpr := [
    .bvar 0, variable, .mvar x,
    .sort .zero, .sort (.mvar x),
    .const x [.zero, .succ .zero],
    .lit (.nat 13), .lit (.str "hello"),
    .app atom atom,
    .app atom variable,
    .app variable (.app atom atom),
    .lam x atom variable .default,
    .forallE x (.app atom atom) variable .implicit,
    .letE x atom variable (.bvar 0) false,
    .letE x atom (.lit (.nat 1)) (.app atom atom) true,
    .mdata 47 (.app atom variable),
    .proj x 0 (.app variable atom)
  ]
  let mut store := psKernelC0StoreEmpty
  for expr in expressions do
    let some (next, id) := psKernelC0EncodeExpr store expr
      | throw (IO.userError "valid source expression could not be interned")
    store := next
    c0FVarIndexedCheckDecoded store id
  for id in [:store.nodes.size] do
    c0FVarIndexedCheckDecoded store id
  let some missing := pure (psKernelC0StoredHasFVar store (store.nodes.size + 1))
    | pure ()
  -- The metadata lookup must not turn invalid identifiers into a
  -- FVar-free witness. A valid false value is different from no value.
  if (psKernelC0StoredHasFVar store (store.nodes.size + 1)).isSome then
    throw (IO.userError "invalid DAG handle acquired a synthetic FVar certificate")
  let some (s0, closed) := psKernelC0Intern store (.const x [])
    | throw (IO.userError "could not create closed shared root")
  let some (s1, openNode) := psKernelC0Intern s0 (.fvar y)
    | throw (IO.userError "could not create FVar-positive shared root")
  store := s1
  let mut a := closed
  let mut b := openNode
  -- Shared expression *occurrences* double at each level, but only
  -- one new canonical interned node is created on each iteration.
  for _ in [:48] do
    let some (next, id) := psKernelC0Intern store (.app a a)
      | throw (IO.userError "closed shared DAG extension failed")
    store := next
    a := id
    let some (next, id) := psKernelC0Intern store (.app b b)
      | throw (IO.userError "FVar-positive shared DAG extension failed")
    store := next
    b := id
    if psKernelC0StoredHasFVar store a != some false ||
        psKernelC0StoredHasFVar store b != some true then
      throw (IO.userError "shared-DAG FVar metadata no longer compositional")
  IO.println s!"C0_OWNED_FVAR_METADATA source_decode_cases={expressions.length} shared_depth=48 syntax_predicate=source_equivalent no_admission=true"

/-- One source equation per indexed node constructor; no context-sensitive
checked result can be inferred from this syntax-only data. -/
theorem c0FVarNodeProjectSource
    (store : PsKernelC0TermStore)
    (n : PsKernelName) (i b : Nat) :
    psKernelC0NodeHasFVar store (.proj n i b) =
      psKernelC0ChildHasFVar store b := rfl
