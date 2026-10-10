import PSKernelFast.Substitution

/-!
# G5: conservative checked inference for a Lean-like calculus fragment

Supports only closed Sort, Pi, Lambda, App, Let and transparent MData with
explicit universe parameter names. No constants, free/metavariables, literals,
projections, inductives, axioms, proof irrelevance or theorem admission.

The equality check is intentionally INCOMPLETE: exact syntax after beta/zeta
WHNF only, and exact syntactic universe levels. It may reject Lean-valid
convertible types; it never returns equality from a guessed heuristic.
This implementation is an experimental executable judgment, NOT a verified
Lean 4.35 kernel or an externally trusted proof certificate.
-/

namespace PSKernelFast

inductive TinyFailure where
  | syntax (reason : Failure)
  | invalidUniverseParam
  | unsupported
  | expectedSort
  | expectedPi
  | typeMismatch
  | budget
deriving Repr, BEq, Inhabited

/-- A level parameter must have an exact declared name; level mvars are banned. -/
def Level.allowed (params : List Name) : Level → Bool
  | .zero => true
  | .succ a => a.allowed params
  | .max a b | .imax a b => a.allowed params && b.allowed params
  | .param n => params.any (fun p => p == n)
  | .mvar _ => false

/-- Only the beta/zeta raw reference WHNF; not full Lean conversion. -/
def tinyWhnf (fuel : Nat) (e : RawExpr) : Except TinyFailure RawExpr :=
  match referenceWhnfFuel fuel e with
  | .ok v => .ok v
  | .error f => .error (.syntax f)

/-- Conservatively recognize a tiny *subset* of definitional equality. -/
def tinySameType (fuel : Nat) (a b : RawExpr) :
    Except TinyFailure Bool := do
  let a' ← tinyWhnf fuel a
  let b' ← tinyWhnf fuel b
  pure (a' == b')

/--
De Bruijn context convention: stored Γ[i] is the type of variable i
relative to the context at its introduction. Lifting i+1 adjusts that
type to the current full context.
-/
def tinyInferFuel (fuel : Nat) (params : List Name)
    (ctx : List RawExpr) (expr : RawExpr) : Except TinyFailure RawExpr :=
  match fuel with
  | 0 => .error .budget
  | Nat.succ smaller =>
      match expr with
      | .bvar i =>
          match ctx[i]? with
          | some ty => .ok (liftBVars (i + 1) 0 ty)
          | none => .error (.syntax .unscopedInput)
      | .sort level =>
          if level.allowed params then .ok (.sort (.succ level))
          else .error .invalidUniverseParam
      | .pi n domain body bi => do
          let domainSortTy ← tinyInferFuel smaller params ctx domain
          let domainSortTy ← tinyWhnf smaller domainSortTy
          match domainSortTy with
          | .sort u =>
              let rangeSortTy ← tinyInferFuel smaller params (domain :: ctx) body
              let rangeSortTy ← tinyWhnf smaller rangeSortTy
              match rangeSortTy with
              | .sort v => pure (.sort (.imax u v))
              | _ => .error .expectedSort
          | _ => .error .expectedSort
      | .lam n domain body bi => do
          let domainSortTy ← tinyInferFuel smaller params ctx domain
          let domainSortTy ← tinyWhnf smaller domainSortTy
          match domainSortTy with
          | .sort _ =>
              let bodyTy ← tinyInferFuel smaller params (domain :: ctx) body
              pure (.pi n domain bodyTy bi)
          | _ => .error .expectedSort
      | .app fn arg => do
          let fnTy ← tinyInferFuel smaller params ctx fn
          let fnTy ← tinyWhnf smaller fnTy
          match fnTy with
          | .pi _ domain body _ =>
              let argTy ← tinyInferFuel smaller params ctx arg
              let same ← tinySameType smaller argTy domain
              if same then
                pure (instantiateBVar arg 0 body)
              else
                .error .typeMismatch
          | _ => .error .expectedPi
      | .letE _ ty value body _ => do
          let declaredSort ← tinyInferFuel smaller params ctx ty
          let declaredSort ← tinyWhnf smaller declaredSort
          match declaredSort with
          | .sort _ =>
              let valueTy ← tinyInferFuel smaller params ctx value
              let same ← tinySameType smaller valueTy ty
              if !same then
                .error .typeMismatch
              else
                let bodyTy ← tinyInferFuel smaller params (ty :: ctx) body
                pure (instantiateBVar value 0 bodyTy)
          | _ => .error .expectedSort
      | .mdata _ body =>
          tinyInferFuel smaller params ctx body
      | _ => .error .unsupported

/--
Fully checked inference restricted to this explicitly advertised fragment.
No declaration admission and no infer-only mode are exposed.
-/
def tinyInferClosed (fuel : Nat) (params : List Name)
    (expr : RawExpr) : Except TinyFailure RawExpr := do
  if !expr.scoped 0 then throw (.syntax .unscopedInput)
  if expr.hasUntrustedMeta then throw (.syntax .forbiddenMeta)
  tinyInferFuel fuel params [] expr

end PSKernelFast
