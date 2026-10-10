import Std
import PSKernelFast.Level

/-!
# G3: Lean 4.35 expression *syntax* and immutable hash-consed representation.

This is NOT a type checker. Node IDs are syntax handles, not proof objects.
Scope and metavariable rejection are separate from syntax interning.
MData is represented here by an opaque String placeholder; its exact official
serialization and non-semantic treatment remain future parser obligations.
Fresh fvar/mvar identity is represented by Name, not an opaque scoped handle.
-/

namespace PSKernelFast

inductive BinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit
deriving Repr, BEq, Hashable, Inhabited

inductive Literal where
  | nat (value : Nat)
  | str (value : String)
deriving Repr, BEq, Hashable, Inhabited

inductive RawExpr where
  | bvar (index : Nat)
  | fvar (name : Name)
  | mvar (name : Name)
  | sort (level : Level)
  | const (name : Name) (levels : List Level)
  | app (fn arg : RawExpr)
  | lam (name : Name) (type body : RawExpr) (binderInfo : BinderInfo)
  | pi (name : Name) (type body : RawExpr) (binderInfo : BinderInfo)
  | letE (name : Name) (type value body : RawExpr) (nondep : Bool)
  | lit (value : Literal)
  | mdata (metadata : String) (expr : RawExpr)
  | proj (typeName : Name) (index : Nat) (expr : RawExpr)
deriving Repr, BEq, Inhabited

/-- Binder scope only; fvars and metavars have separate ownership policy. -/
def RawExpr.scoped (expr : RawExpr) (depth : Nat) : Bool :=
  match expr with
  | .bvar i => decide (i < depth)
  | .app fn arg => fn.scoped depth && arg.scoped depth
  | .lam _ ty body _ | .pi _ ty body _ =>
      ty.scoped depth && body.scoped (depth + 1)
  | .letE _ ty value body _ =>
      ty.scoped depth && value.scoped depth && body.scoped (depth + 1)
  | .mdata _ e | .proj _ _ e => e.scoped depth
  | _ => true

/-- Reject fvars, expr mvars and level mvars at a closed export boundary. -/
def RawExpr.hasUntrustedMeta (expr : RawExpr) : Bool :=
  match expr with
  | .fvar _ | .mvar _ => true
  | .sort l => l.hasMVar
  | .const _ ls => ls.any Level.hasMVar
  | .app fn arg => fn.hasUntrustedMeta || arg.hasUntrustedMeta
  | .lam _ ty body _ | .pi _ ty body _ =>
      ty.hasUntrustedMeta || body.hasUntrustedMeta
  | .letE _ ty value body _ =>
      ty.hasUntrustedMeta || value.hasUntrustedMeta || body.hasUntrustedMeta
  | .mdata _ e | .proj _ _ e => e.hasUntrustedMeta
  | _ => false

inductive Node where
  | bvar (index : Nat)
  | fvar (name : Name)
  | mvar (name : Name)
  | sort (level : Level)
  | const (name : Name) (levels : List Level)
  | app (fn arg : Nat)
  | lam (name : Name) (type body : Nat) (binderInfo : BinderInfo)
  | pi (name : Name) (type body : Nat) (binderInfo : BinderInfo)
  | letE (name : Name) (type value body : Nat) (nondep : Bool)
  | lit (value : Literal)
  | mdata (metadata : String) (expr : Nat)
  | proj (typeName : Name) (index : Nat) (expr : Nat)
deriving Repr, BEq, Hashable, Inhabited

def Node.children : Node → List Nat
  | .app f a => [f, a]
  | .lam _ t b _ | .pi _ t b _ => [t, b]
  | .letE _ t v b _ => [t, v, b]
  | .mdata _ e | .proj _ _ e => [e]
  | _ => []

inductive Failure where
  | unscopedInput
  | forbiddenMeta
  | invalidChild
  | invalidHandle (index : Nat)
  | corruptIndex
  | decodeBudget
  | reductionBudget
deriving Repr, BEq, Inhabited

structure Store where
  nodes : Array Node
  byNode : Std.HashMap Node Nat
deriving Inhabited

def Store.empty : Store := { nodes := #[], byNode := {} }

/--
Interning checks full node identity after a hash lookup. This is syntax equality
only, not kernel DefEq. Recovered handles are checked against the node array.
Direct public construction of a forged Store would NOT be a checked authority.
-/
def Store.intern (store : Store) (node : Node) :
    Except Failure (Nat × Store) :=
  if node.children.all (fun id => decide (id < store.nodes.size)) then
    match store.byNode.get? node with
    | some id =>
        match store.nodes[id]? with
        | some prior =>
            if prior == node then .ok (id, store)
            else .error .corruptIndex
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
  | .fvar n, store => store.intern (.fvar n)
  | .mvar n, store => store.intern (.mvar n)
  | .sort l, store => store.intern (.sort l)
  | .const n levels, store => store.intern (.const n levels)
  | .app fn arg, store => do
      let (fi, store) ← encode fn store
      let (ai, store) ← encode arg store
      store.intern (.app fi ai)
  | .lam n ty body bi, store => do
      let (ti, store) ← encode ty store
      let (biId, store) ← encode body store
      store.intern (.lam n ti biId bi)
  | .pi n ty body bi, store => do
      let (ti, store) ← encode ty store
      let (biId, store) ← encode body store
      store.intern (.pi n ti biId bi)
  | .letE n ty value body nd, store => do
      let (ti, store) ← encode ty store
      let (vi, store) ← encode value store
      let (biId, store) ← encode body store
      store.intern (.letE n ti vi biId nd)
  | .lit l, store => store.intern (.lit l)
  | .mdata m expr, store => do
      let (id, store) ← encode expr store
      store.intern (.mdata m id)
  | .proj n i expr, store => do
      let (id, store) ← encode expr store
      store.intern (.proj n i id)

/-- Syntax preflight only. This does not verify types, constants or universes. -/
def encodeClosed (expr : RawExpr) : Except Failure (Nat × Store) :=
  if !expr.scoped 0 then .error .unscopedInput
  else if expr.hasUntrustedMeta then .error .forbiddenMeta
  else encode expr Store.empty

/-- Total fuel-bounded erasure, including malformed/cyclic store rejection. -/
def decodeFuel : Nat → Store → Nat → Except Failure RawExpr
  | 0, _, _ => .error .decodeBudget
  | Nat.succ remaining, store, id =>
      match store.nodes[id]? with
      | none => .error (.invalidHandle id)
      | some node =>
          match node with
          | .bvar i => .ok (.bvar i)
          | .fvar n => .ok (.fvar n)
          | .mvar n => .ok (.mvar n)
          | .sort l => .ok (.sort l)
          | .const n levels => .ok (.const n levels)
          | .app fi ai => do
              let fn ← decodeFuel remaining store fi
              let arg ← decodeFuel remaining store ai
              pure (.app fn arg)
          | .lam n ti biId info => do
              let ty ← decodeFuel remaining store ti
              let body ← decodeFuel remaining store biId
              pure (.lam n ty body info)
          | .pi n ti biId info => do
              let ty ← decodeFuel remaining store ti
              let body ← decodeFuel remaining store biId
              pure (.pi n ty body info)
          | .letE n ti vi biId nd => do
              let ty ← decodeFuel remaining store ti
              let value ← decodeFuel remaining store vi
              let body ← decodeFuel remaining store biId
              pure (.letE n ty value body nd)
          | .lit l => .ok (.lit l)
          | .mdata m e => do
              let expr ← decodeFuel remaining store e
              pure (.mdata m expr)
          | .proj n i e => do
              let expr ← decodeFuel remaining store e
              pure (.proj n i expr)

def decodeClosed (store : Store) (id : Nat) : Except Failure RawExpr := do
  let expr ← decodeFuel (store.nodes.size + 1) store id
  if !expr.scoped 0 then throw .unscopedInput
  else if expr.hasUntrustedMeta then throw .forbiddenMeta
  else pure expr

end PSKernelFast
