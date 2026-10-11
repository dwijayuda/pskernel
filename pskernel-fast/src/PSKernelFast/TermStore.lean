import Lean

/-!
Independent V3 substrate experiment. This file is NOT a kernel proof checker.
It implements only a tiny RawExpr language and a collision-checked interning
store; Lean 4.35 semantic term checking, universes and admission are FUTURE.
-/

namespace PSKernelFast

/-- A deliberately narrow prototype AST, not the complete Lean expression type. -/
inductive RawExpr where
  | bvar (index : Nat)
  | sort (level : Nat)
  | app (fn arg : RawExpr)
  | lam (domain body : RawExpr)
  deriving Inhabited, Repr, BEq

/-- Validated DAG node fields; child identifiers are only created by encode. -/
inductive Node where
  | bvar (index : Nat)
  | sort (level : Nat)
  | app (fn arg : Nat)
  | lam (domain body : Nat)
  deriving Inhabited, Repr, BEq, Hashable

/-- Explicit fail-closed outcomes for this prototype. -/
inductive StoreError where
  | looseBound (index depth : Nat)
  | invalidHandle (handle : Nat)
  | inconsistentIndex (handle : Nat)
  | nodeLimit (maximum : Nat)
  | decodeFuelExhausted
  | invalidScope
  deriving Repr, BEq, Inhabited

/--
  Independently specified well-scopedness of the small prototype RawExpr.
  This is only a binder-scope fact, not a typing judgment.
-/
def RawScoped : Nat → RawExpr → Prop
  | depth, .bvar index => index < depth
  | _, .sort _ => True
  | depth, .app fn arg => RawScoped depth fn ∧ RawScoped depth arg
  | depth, .lam domain body =>
      RawScoped depth domain ∧ RawScoped (depth + 1) body

/-- Executable strict scope validator used at all G2 decoding boundaries. -/
def isScoped : Nat → RawExpr → Bool
  | depth, .bvar index => decide (index < depth)
  | _, .sort _ => true
  | depth, .app fn arg => isScoped depth fn && isScoped depth arg
  | depth, .lam domain body =>
      isScoped depth domain && isScoped (depth + 1) body

/--
  A successful executable scope check guarantees the declarative binder
  predicate. No old kernel metatheory is imported or assumed.
-/
theorem isScoped_sound (depth : Nat) (term : RawExpr)
    (h : isScoped depth term = true) : RawScoped depth term := by
  induction term generalizing depth with
  | bvar index =>
      simpa [isScoped, RawScoped, decide_eq_true_eq] using h
  | sort _ =>
      trivial
  | app fn arg ihFn ihArg =>
      have both : isScoped depth fn = true ∧ isScoped depth arg = true := by
        simpa [isScoped, Bool.and_eq_true] using h
      change RawScoped depth fn ∧ RawScoped depth arg
      exact ⟨ihFn depth both.1, ihArg depth both.2⟩
  | lam domain body ihDomain ihBody =>
      have both :
          isScoped depth domain = true ∧
            isScoped (depth + 1) body = true := by
        simpa [isScoped, Bool.and_eq_true] using h
      change RawScoped depth domain ∧ RawScoped (depth + 1) body
      exact ⟨ihDomain depth both.1, ihBody (depth + 1) both.2⟩

/-- Persistent functional table; no proof authority or unchecked declaration API. -/
structure Store where
  nodes : Array Node := #[]
  byNode : Std.HashMap Node Nat := {}

/--
  A hit is accepted only if the stored node at the indexed handle is
  exactly the requested node. Hash equality alone is never trusted.
  A malformed map/handle fails closed, rather than returning a false match.
-/
def Store.intern (store : Store) (maxNodes : Nat) (node : Node) :
    Except StoreError (Nat × Store) :=
  match store.byNode[node]? with
  | some handle =>
    match store.nodes[handle]? with
    | none => .error (.invalidHandle handle)
    | some stored =>
      if stored == node then
        .ok (handle, store)
      else
        .error (.inconsistentIndex handle)
  | none =>
    if store.nodes.size >= maxNodes then
      .error (.nodeLimit maxNodes)
    else
      let handle := store.nodes.size
      .ok (handle, {
        nodes := store.nodes.push node
        byNode := store.byNode.insert node handle
      })

/--
  Total structural encoder with explicit binder-depth check.
  No raw bound variable can escape its binder. This is a representative
  structural store prototype only; it has no kernel acceptance mechanism.
-/
def encode (maxNodes depth : Nat) (store : Store) :
    RawExpr → Except StoreError (Nat × Store)
  | .bvar index =>
    if index < depth then
      store.intern maxNodes (.bvar index)
    else
      .error (.looseBound index depth)
  | .sort level =>
    store.intern maxNodes (.sort level)
  | .app fn arg => do
    let (fnId, afterFn) ← encode maxNodes depth store fn
    let (argId, afterArg) ← encode maxNodes depth afterFn arg
    afterArg.intern maxNodes (.app fnId argId)
  | .lam domain body => do
    let (domainId, afterDomain) ← encode maxNodes depth store domain
    let (bodyId, afterBody) ← encode maxNodes (depth + 1) afterDomain body
    afterBody.intern maxNodes (.lam domainId bodyId)

/-- Root terms must be closed; no arbitrary local-context admission. -/
def encodeClosed (maxNodes : Nat) (term : RawExpr) :
    Except StoreError (Nat × Store) :=
  encode maxNodes 0 {} term

/--
  Total, fuel-limited decoder. Even a malformed/cyclic/forged input Store
  cannot cause unbounded structural recursion through stored handles.
-/
def decode (store : Store) : Nat → Nat → Except StoreError RawExpr
  | 0, _ => .error .decodeFuelExhausted
  | remaining + 1, id =>
    match store.nodes[id]? with
    | none => .error (.invalidHandle id)
    | some (.bvar index) => .ok (.bvar index)
    | some (.sort level) => .ok (.sort level)
    | some (.app fn arg) => do
      let fnRaw ← decode store remaining fn
      let argRaw ← decode store remaining arg
      pure (.app fnRaw argRaw)
    | some (.lam domain body) => do
      let domainRaw ← decode store remaining domain
      let bodyRaw ← decode store remaining body
      pure (.lam domainRaw bodyRaw)

end PSKernelFast
