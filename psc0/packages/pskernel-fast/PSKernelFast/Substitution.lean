import PSKernelFast.Core

/-!
# G4 reference substitution

Pure capture-avoiding de Bruijn lifting and substitution over raw syntax.
This is NOT the Lean 4 definitional equality checker. In particular it does not
perform universe equality, unfolding, proof irrelevance, recursors or eta.
-/

namespace PSKernelFast

/-- Shift loose de Bruijn indices by amount under the initial cutoff. -/
def liftBVars (amount cutoff : Nat) : RawExpr → RawExpr
  | .bvar i => if i < cutoff then .bvar i else .bvar (i + amount)
  | .app f a => .app (liftBVars amount cutoff f) (liftBVars amount cutoff a)
  | .lam n ty body bi =>
      .lam n (liftBVars amount cutoff ty)
        (liftBVars amount (cutoff + 1) body) bi
  | .pi n ty body bi =>
      .pi n (liftBVars amount cutoff ty)
        (liftBVars amount (cutoff + 1) body) bi
  | .letE n ty value body nd =>
      .letE n (liftBVars amount cutoff ty) (liftBVars amount cutoff value)
        (liftBVars amount (cutoff + 1) body) nd
  | .mdata m e => .mdata m (liftBVars amount cutoff e)
  | .proj n i e => .proj n i (liftBVars amount cutoff e)
  | e => e

/--
Instantiate the de Bruijn index at depth with a raw expression.
Outer indices decrease by one; the replacement is lifted under traversed
binders. Scope and type checking of the initial declaration are separate.
-/
def instantiateBVar (replacement : RawExpr) (depth : Nat) : RawExpr → RawExpr
  | .bvar i =>
      if i < depth then .bvar i
      else if i == depth then liftBVars depth 0 replacement
      else .bvar (i - 1)
  | .app f a =>
      .app (instantiateBVar replacement depth f)
        (instantiateBVar replacement depth a)
  | .lam n ty body bi =>
      .lam n (instantiateBVar replacement depth ty)
        (instantiateBVar replacement (depth + 1) body) bi
  | .pi n ty body bi =>
      .pi n (instantiateBVar replacement depth ty)
        (instantiateBVar replacement (depth + 1) body) bi
  | .letE n ty value body nd =>
      .letE n (instantiateBVar replacement depth ty)
        (instantiateBVar replacement depth value)
        (instantiateBVar replacement (depth + 1) body) nd
  | .mdata m e => .mdata m (instantiateBVar replacement depth e)
  | .proj n i e => .proj n i (instantiateBVar replacement depth e)
  | e => e

/-- A deliberately basic substitution-based beta/zeta WHNF reference. -/
def referenceWhnfFuel (fuel : Nat) (expr : RawExpr) : Except Failure RawExpr :=
  match fuel with
  | 0 => .error .reductionBudget
  | Nat.succ smaller =>
      match expr with
      | .app fn arg => do
          let reducedFn ← referenceWhnfFuel smaller fn
          match reducedFn with
          | .lam _ _ body _ =>
              referenceWhnfFuel smaller (instantiateBVar arg 0 body)
          | other => pure (.app other arg)
      | .letE _ _ value body _ =>
          referenceWhnfFuel smaller (instantiateBVar value 0 body)
      | .mdata _ e =>
          referenceWhnfFuel smaller e
      | _ => pure expr

end PSKernelFast
