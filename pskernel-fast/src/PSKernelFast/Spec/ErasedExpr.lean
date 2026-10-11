import PSKernelFast.SymbolicLevel

/-!
P1c SEMANTIC ROUTE SPIKE — independent erased syntax for the supported
G4.3b term fragment. This module deliberately does not import the actual
checker, its scoped context, runtime substitution, term stores or proof
admission. The universe valuation is explicit and symbolic params are
grounded to Nat using the previously proved ULevel semantics.

This is a syntax/translation tier ONLY, not a set-theoretic interpretation,
typing soundness, consistency model, or new proof-acceptance authority.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core

/--
Semantic syntax for the narrow supported six-rule fragment. Binder names
and styles are erased; each universe level becomes the Nat value from its
valuation. Unsupported expressions do NOT become invented semantic facts.
-/
inductive ErasedExpr where
  | bvar (index : Nat)
  | sort (level : Nat)
  | app (fn arg : ErasedExpr)
  | lam (domain body : ErasedExpr)
  | pi (domain body : ErasedExpr)
  | letE (type value body : ErasedExpr)
  deriving Repr, Inhabited, BEq, DecidableEq

/-- Independent reference de Bruijn lift on erased terms. -/
def ErasedExpr.lift (amount cutoff : Nat) : ErasedExpr → ErasedExpr
  | .bvar index =>
      if index < cutoff then .bvar index else .bvar (index + amount)
  | .sort u => .sort u
  | .app fn arg =>
      .app (fn.lift amount cutoff) (arg.lift amount cutoff)
  | .lam domain body =>
      .lam (domain.lift amount cutoff) (body.lift amount (cutoff + 1))
  | .pi domain body =>
      .pi (domain.lift amount cutoff) (body.lift amount (cutoff + 1))
  | .letE ty value body =>
      .letE (ty.lift amount cutoff) (value.lift amount cutoff)
        (body.lift amount (cutoff + 1))

/-- Independent beta/let substitution, with literal de Bruijn scope rules. -/
def ErasedExpr.instantiate (expr replacement : ErasedExpr)
    (depth : Nat) : ErasedExpr :=
  match expr with
  | .bvar index =>
      if index < depth then .bvar index
      else if index = depth then replacement.lift depth 0
      else .bvar (index - 1)
  | .sort u => .sort u
  | .app fn arg =>
      .app (fn.instantiate replacement depth)
        (arg.instantiate replacement depth)
  | .lam domain body =>
      .lam (domain.instantiate replacement depth)
        (body.instantiate replacement (depth + 1))
  | .pi domain body =>
      .pi (domain.instantiate replacement depth)
        (body.instantiate replacement (depth + 1))
  | .letE ty value body =>
      .letE (ty.instantiate replacement depth)
        (value.instantiate replacement depth)
        (body.instantiate replacement (depth + 1))

/--
Erase only the already-supported subset of KExpr. The function is partial:
a free variable, metavariable, constant, literal, metadata or projection,
or an unqualified nondependent-let flag returns NONE. This is not a
substitute for the G3 well-scoped/universe-parameter preflight.
-/
def eraseExpr (ρ : KName → Nat) : KExpr → Option ErasedExpr
  | .bvar index => some (.bvar index)
  | .sort level => some (.sort (level.denote ρ))
  | .app fn arg => do
      let f ← eraseExpr ρ fn
      let a ← eraseExpr ρ arg
      pure (.app f a)
  | .lam _ domain body _ => do
      let d ← eraseExpr ρ domain
      let b ← eraseExpr ρ body
      pure (.lam d b)
  | .forallE _ domain body _ => do
      let d ← eraseExpr ρ domain
      let b ← eraseExpr ρ body
      pure (.pi d b)
  | .letE _ ty value body false => do
      let d ← eraseExpr ρ ty
      let v ← eraseExpr ρ value
      let b ← eraseExpr ρ body
      pure (.letE d v b)
  | _ => none

end PSKernelFast.Spec
