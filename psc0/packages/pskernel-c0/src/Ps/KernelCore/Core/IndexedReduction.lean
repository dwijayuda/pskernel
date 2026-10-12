import Ps.KernelCore.Core.IndexedExpr

/-
PSKernel-C0 experimental indexed de Bruijn execution.

All operations use the native Lean PsKernelC0TermStore. Expressions are
represented as Nat handles, with immutable shared child nodes.

This is the prerequisite for a future full indexed WHNF / DefEq checker. It
does not change the accepting API. In particular, the original resource
budget and all recursive/nat/native/quotient rules remain authoritative.

Fuel is bounded by the *stored expression depth* (one step for each path
edge). Child handles were already validated at intern time.
-/

/-- Retain the exact old handle when an indexed rewrite changes nothing. -/
def psKernelC0KeepOrIntern
    (store : PsKernelC0TermStore)
    (id : Nat)
    (node : PsKernelC0Node) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let original ← psKernelC0StoreGet store id
  if psKernelC0NodeEq original.node node then
    some (store, id)
  else
    psKernelC0Intern store node

/-- Shift loose de Bruijn variables in an indexed term, preserving shares. -/
def psKernelC0LiftIndexedWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (start : Nat)
    (amount : Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      if amount == 0 then
        some (store, id)
      else
        match stored.node with
        | .bvar i =>
            if i < start then some (store, id)
            else psKernelC0Intern store (.bvar (i + amount))
        | .app fn arg => do
            let (s1, f) ← psKernelC0LiftIndexedWithFuel remaining store fn start amount
            let (s2, a) ← psKernelC0LiftIndexedWithFuel remaining s1 arg start amount
            psKernelC0KeepOrIntern s2 id (.app f a)
        | .lam name ty body info => do
            let (s1, t) ← psKernelC0LiftIndexedWithFuel remaining store ty start amount
            let (s2, b) ← psKernelC0LiftIndexedWithFuel remaining s1 body (start + 1) amount
            psKernelC0KeepOrIntern s2 id (.lam name t b info)
        | .forallE name ty body info => do
            let (s1, t) ← psKernelC0LiftIndexedWithFuel remaining store ty start amount
            let (s2, b) ← psKernelC0LiftIndexedWithFuel remaining s1 body (start + 1) amount
            psKernelC0KeepOrIntern s2 id (.forallE name t b info)
        | .letE name ty value body nondep => do
            let (s1, t) ← psKernelC0LiftIndexedWithFuel remaining store ty start amount
            let (s2, v) ← psKernelC0LiftIndexedWithFuel remaining s1 value start amount
            let (s3, b) ← psKernelC0LiftIndexedWithFuel remaining s2 body (start + 1) amount
            psKernelC0KeepOrIntern s3 id (.letE name t v b nondep)
        | .mdata metadata body => do
            let (s1, b) ← psKernelC0LiftIndexedWithFuel remaining store body start amount
            psKernelC0KeepOrIntern s1 id (.mdata metadata b)
        | .proj name index body => do
            let (s1, b) ← psKernelC0LiftIndexedWithFuel remaining store body start amount
            psKernelC0KeepOrIntern s1 id (.proj name index b)
        | _ => some (store, id)

def psKernelC0LiftIndexed
    (store : PsKernelC0TermStore)
    (id start amount : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store id
  psKernelC0LiftIndexedWithFuel entry.depth store id start amount

/-- Capture-avoiding substitution for exactly one removed binder. -/
def psKernelC0Instantiate1IndexedWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (replacement : Nat)
    (offset : Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match stored.node with
      | .bvar i =>
          if i < offset then
            some (store, id)
          else if i == offset then
            psKernelC0LiftIndexed store replacement 0 offset
          else
            psKernelC0Intern store (.bvar (i - 1))
      | .app fn arg => do
          let (s1, f) ← psKernelC0Instantiate1IndexedWithFuel remaining store fn replacement offset
          let (s2, a) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 arg replacement offset
          psKernelC0KeepOrIntern s2 id (.app f a)
      | .lam name ty body info => do
          let (s1, t) ← psKernelC0Instantiate1IndexedWithFuel remaining store ty replacement offset
          let (s2, b) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 body replacement (offset + 1)
          psKernelC0KeepOrIntern s2 id (.lam name t b info)
      | .forallE name ty body info => do
          let (s1, t) ← psKernelC0Instantiate1IndexedWithFuel remaining store ty replacement offset
          let (s2, b) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 body replacement (offset + 1)
          psKernelC0KeepOrIntern s2 id (.forallE name t b info)
      | .letE name ty value body nondep => do
          let (s1, t) ← psKernelC0Instantiate1IndexedWithFuel remaining store ty replacement offset
          let (s2, v) ← psKernelC0Instantiate1IndexedWithFuel remaining s1 value replacement offset
          let (s3, b) ← psKernelC0Instantiate1IndexedWithFuel remaining s2 body replacement (offset + 1)
          psKernelC0KeepOrIntern s3 id (.letE name t v b nondep)
      | .mdata metadata body => do
          let (s1, b) ← psKernelC0Instantiate1IndexedWithFuel remaining store body replacement offset
          psKernelC0KeepOrIntern s1 id (.mdata metadata b)
      | .proj name index body => do
          let (s1, b) ← psKernelC0Instantiate1IndexedWithFuel remaining store body replacement offset
          psKernelC0KeepOrIntern s1 id (.proj name index b)
      | _ => some (store, id)

/--
  Substitution over same-store handles; result is *not* a checked proof term.
  It remains the caller's job to compare against the normal kernel semantics.
-/
def psKernelC0Instantiate1Indexed
    (store : PsKernelC0TermStore)
    (id replacement : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store id
  if !(psKernelC0StoreValid store replacement) then none
  else psKernelC0Instantiate1IndexedWithFuel entry.depth store id replacement 0

/-- The only reduction performed is beta on an explicit indexed lambda head. -/
def psKernelC0IndexedBetaStep
    (store : PsKernelC0TermStore)
    (fn arg : Nat) :
    Option (Prod PsKernelC0TermStore Nat) := do
  let entry ← psKernelC0StoreGet store fn
  match entry.node with
  | .lam _ _ body _ => psKernelC0Instantiate1Indexed store body arg
  | _ => none
