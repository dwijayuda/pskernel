import Std

/-!
# PSKernel-Fast G0: representation only

Standalone data-representation experiment, NOT a Lean proof checker.
Nat-only sorts are a deliberate placeholder, not true Lean universe semantics.
Node identifiers are data-structure handles, never logical proof certificates.
-/

namespace PSKernelFast

inductive RawExpr where
  | bvar (index : Nat)
  | sort (level : Nat)
  | const (name : String)
  | app (fn arg : RawExpr)
  | lam (type body : RawExpr)
  | pi (type body : RawExpr)
  | letE (type value body : RawExpr)
deriving Repr, BEq, Inhabited

def RawExpr.scoped (expr : RawExpr) (depth : Nat) : Bool :=
  match expr with
  | .bvar i => decide (i < depth)
  | .sort _ | .const _ => true
  | .app fn arg => fn.scoped depth && arg.scoped depth
  | .lam ty body | .pi ty body => ty.scoped depth && body.scoped (depth + 1)
  | .letE ty value body =>
      ty.scoped depth && value.scoped depth && body.scoped (depth + 1)

inductive Node where
  | bvar (index : Nat)
  | sort (level : Nat)
  | const (name : String)
  | app (fn arg : Nat)
  | lam (type body : Nat)
  | pi (type body : Nat)
  | letE (type value body : Nat)
deriving Repr, BEq, Hashable, Inhabited

def Node.children : Node → List Nat
  | .app f a => [f, a]
  | .lam t b | .pi t b => [t, b]
  | .letE t v b => [t, v, b]
  | _ => []

inductive Failure where
  | unscopedInput
  | invalidChild
  | invalidHandle (index : Nat)
  | corruptIndex
  | decodeBudget
deriving Repr, BEq, Inhabited

structure Store where
  nodes : Array Node
  byNode : Std.HashMap Node Nat
deriving Inhabited

def Store.empty : Store :=
  { nodes := #[], byNode := {} }

/--
Store a collision-checked exact syntax node, rejecting out-of-bounds children.
No semantic equality or kernel type checking is performed here.
-/
def Store.intern (store : Store) (node : Node) :
    Except Failure (Nat × Store) :=
  if node.children.all (fun id => decide (id < store.nodes.size)) then
    match store.byNode.get? node with
    | some id =>
        match store.nodes[id]? with
        | some prior =>
            if prior == node then
              .ok (id, store)
            else
              .error .corruptIndex
        | none => .error .corruptIndex
    | none =>
        let id := store.nodes.size
        .ok (id, {
          nodes := store.nodes.push node
          byNode := store.byNode.insert node id
        })
  else
    .error .invalidChild

def encode : RawExpr → Store → Except Failure (Nat × Store)
  | .bvar i, store => store.intern (.bvar i)
  | .sort l, store => store.intern (.sort l)
  | .const n, store => store.intern (.const n)
  | .app fn arg, store => do
      let (fi, store) ← encode fn store
      let (ai, store) ← encode arg store
      store.intern (.app fi ai)
  | .lam ty body, store => do
      let (ti, store) ← encode ty store
      let (bi, store) ← encode body store
      store.intern (.lam ti bi)
  | .pi ty body, store => do
      let (ti, store) ← encode ty store
      let (bi, store) ← encode body store
      store.intern (.pi ti bi)
  | .letE ty value body, store => do
      let (ti, store) ← encode ty store
      let (vi, store) ← encode value store
      let (bi, store) ← encode body store
      store.intern (.letE ti vi bi)

def encodeClosed (expr : RawExpr) : Except Failure (Nat × Store) :=
  if expr.scoped 0 then
    encode expr Store.empty
  else
    .error .unscopedInput

/-- Total fuel-bounded decoding even if a caller passes a malformed DAG. -/
def decodeFuel : Nat → Store → Nat → Except Failure RawExpr
  | 0, _, _ => .error .decodeBudget
  | Nat.succ remaining, store, id =>
      match store.nodes[id]? with
      | none => .error (.invalidHandle id)
      | some node =>
          match node with
          | .bvar i => .ok (.bvar i)
          | .sort l => .ok (.sort l)
          | .const n => .ok (.const n)
          | .app fi ai => do
              let fn ← decodeFuel remaining store fi
              let arg ← decodeFuel remaining store ai
              pure (.app fn arg)
          | .lam ti bi => do
              let ty ← decodeFuel remaining store ti
              let body ← decodeFuel remaining store bi
              pure (.lam ty body)
          | .pi ti bi => do
              let ty ← decodeFuel remaining store ti
              let body ← decodeFuel remaining store bi
              pure (.pi ty body)
          | .letE ti vi bi => do
              let ty ← decodeFuel remaining store ti
              let value ← decodeFuel remaining store vi
              let body ← decodeFuel remaining store bi
              pure (.letE ty value body)

def decodeClosed (store : Store) (id : Nat) : Except Failure RawExpr := do
  let expr ← decodeFuel (store.nodes.size + 1) store id
  if expr.scoped 0 then
    pure expr
  else
    throw .unscopedInput

end PSKernelFast
