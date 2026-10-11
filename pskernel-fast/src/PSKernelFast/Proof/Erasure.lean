import PSKernelFast.Spec.ErasedExpr
import PSKernelFast.Substitution

/-!
P1c representation-independent proof bridge. The spec independently
defines a ground-universe erased term language and its own binder rules.
For terms it supports, erasure commutes with the exact RUNNING kernel's
lifting and substitution. This is necessary for con-leche-style
semantic beta/let arguments; it is NOT yet a set-theoretic denotation,
typed substitution, or a global consistency proof.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

/--
Erasing a term after a real de Bruijn lift is equal to independently
lifting its erased representation, including nested binders and let.
Unsupported constructors decline identically on both sides.
-/
theorem eraseExpr_lift (ρ : KName → Nat)
    (amount cutoff : Nat) (expr : KExpr) :
    eraseExpr ρ (expr.liftBVars amount cutoff) =
      (eraseExpr ρ expr).map (fun e => e.lift amount cutoff) := by
  induction expr generalizing cutoff with
  | bvar index =>
      by_cases h : index < cutoff
      · simp [KExpr.liftBVars, eraseExpr, ErasedExpr.lift, h]
      · simp [KExpr.liftBVars, eraseExpr, ErasedExpr.lift, h]
  | fvar _ => rfl
  | mvar _ => rfl
  | sort _ => rfl
  | const _ _ => rfl
  | app fn arg ihFn ihArg =>
      cases hFn : eraseExpr ρ fn with
      | none =>
          simp [KExpr.liftBVars, eraseExpr, ihFn cutoff, hFn]
      | some fnVal =>
          cases hArg : eraseExpr ρ arg with
          | none =>
              simp [KExpr.liftBVars, eraseExpr,
                ihFn cutoff, ihArg cutoff, hFn, hArg]
          | some argVal =>
              simp [KExpr.liftBVars, eraseExpr, ErasedExpr.lift,
                ihFn cutoff, ihArg cutoff, hFn, hArg]
  | lam name domain body style ihDomain ihBody =>
      cases hD : eraseExpr ρ domain with
      | none =>
          simp [KExpr.liftBVars, eraseExpr, ihDomain cutoff, hD]
      | some d =>
          cases hB : eraseExpr ρ body with
          | none =>
              simp [KExpr.liftBVars, eraseExpr,
                ihDomain cutoff, ihBody (cutoff + 1), hD, hB]
          | some b =>
              simp [KExpr.liftBVars, eraseExpr, ErasedExpr.lift,
                ihDomain cutoff, ihBody (cutoff + 1), hD, hB]
  | forallE name domain body style ihDomain ihBody =>
      cases hD : eraseExpr ρ domain with
      | none =>
          simp [KExpr.liftBVars, eraseExpr, ihDomain cutoff, hD]
      | some d =>
          cases hB : eraseExpr ρ body with
          | none =>
              simp [KExpr.liftBVars, eraseExpr,
                ihDomain cutoff, ihBody (cutoff + 1), hD, hB]
          | some b =>
              simp [KExpr.liftBVars, eraseExpr, ErasedExpr.lift,
                ihDomain cutoff, ihBody (cutoff + 1), hD, hB]
  | letE name ty val body flag ihTy ihVal ihBody =>
      cases flag with
      | true => rfl
      | false =>
          cases hTy : eraseExpr ρ ty with
          | none =>
              simp [KExpr.liftBVars, eraseExpr, ihTy cutoff, hTy]
          | some t =>
              cases hVal : eraseExpr ρ val with
              | none =>
                  simp [KExpr.liftBVars, eraseExpr,
                    ihTy cutoff, ihVal cutoff, hTy, hVal]
              | some v =>
                  cases hBody : eraseExpr ρ body with
                  | none =>
                      simp [KExpr.liftBVars, eraseExpr,
                        ihTy cutoff, ihVal cutoff, ihBody (cutoff + 1),
                        hTy, hVal, hBody]
                  | some b =>
                      simp [KExpr.liftBVars, eraseExpr, ErasedExpr.lift,
                        ihTy cutoff, ihVal cutoff, ihBody (cutoff + 1),
                        hTy, hVal, hBody]
  | lit _ => rfl
  | mdata _ _ _ => rfl
  | proj _ _ _ _ => rfl

/--
The actual G4.3 substitution has EXACTLY the same erasure as the
independently defined erased-term substitution whenever the replacement
has a supported representation. The binder depth is arbitrary.
-/
theorem eraseExpr_instantiate (ρ : KName → Nat)
    (replacement : KExpr) (erasedReplacement : ErasedExpr)
    (hReplacement : eraseExpr ρ replacement = some erasedReplacement)
    (expr : KExpr) (depth : Nat) :
    eraseExpr ρ (expr.instantiateBVar replacement depth) =
      (eraseExpr ρ expr).map
        (fun e => e.instantiate erasedReplacement depth) := by
  induction expr generalizing depth with
  | bvar index =>
      by_cases hLocal : index < depth
      · simp [KExpr.instantiateBVar, ErasedExpr.instantiate,
          eraseExpr, hLocal]
      · by_cases hHere : index = depth
        · have hLift := eraseExpr_lift ρ depth 0 replacement
          simp [KExpr.instantiateBVar, ErasedExpr.instantiate,
            eraseExpr, hLocal, hHere, hLift, hReplacement]
        · simp [KExpr.instantiateBVar, ErasedExpr.instantiate,
            eraseExpr, hLocal, hHere]
  | fvar _ => rfl
  | mvar _ => rfl
  | sort _ => rfl
  | const _ _ => rfl
  | app fn arg ihFn ihArg =>
      cases hFn : eraseExpr ρ fn with
      | none =>
          simp [KExpr.instantiateBVar, eraseExpr,
            ihFn depth, hFn]
      | some fnVal =>
          cases hArg : eraseExpr ρ arg with
          | none =>
              simp [KExpr.instantiateBVar, eraseExpr,
                ihFn depth, ihArg depth, hFn, hArg]
          | some argVal =>
              simp [KExpr.instantiateBVar, eraseExpr, ErasedExpr.instantiate,
                ihFn depth, ihArg depth, hFn, hArg]
  | lam name domain body style ihDomain ihBody =>
      cases hD : eraseExpr ρ domain with
      | none =>
          simp [KExpr.instantiateBVar, eraseExpr, ihDomain depth, hD]
      | some d =>
          cases hB : eraseExpr ρ body with
          | none =>
              simp [KExpr.instantiateBVar, eraseExpr,
                ihDomain depth, ihBody (depth + 1), hD, hB]
          | some b =>
              simp [KExpr.instantiateBVar, eraseExpr, ErasedExpr.instantiate,
                ihDomain depth, ihBody (depth + 1), hD, hB]
  | forallE name domain body style ihDomain ihBody =>
      cases hD : eraseExpr ρ domain with
      | none =>
          simp [KExpr.instantiateBVar, eraseExpr, ihDomain depth, hD]
      | some d =>
          cases hB : eraseExpr ρ body with
          | none =>
              simp [KExpr.instantiateBVar, eraseExpr,
                ihDomain depth, ihBody (depth + 1), hD, hB]
          | some b =>
              simp [KExpr.instantiateBVar, eraseExpr, ErasedExpr.instantiate,
                ihDomain depth, ihBody (depth + 1), hD, hB]
  | letE name ty val body flag ihTy ihVal ihBody =>
      cases flag with
      | true => rfl
      | false =>
          cases hTy : eraseExpr ρ ty with
          | none =>
              simp [KExpr.instantiateBVar, eraseExpr, ihTy depth, hTy]
          | some t =>
              cases hVal : eraseExpr ρ val with
              | none =>
                  simp [KExpr.instantiateBVar, eraseExpr,
                    ihTy depth, ihVal depth, hTy, hVal]
              | some v =>
                  cases hBody : eraseExpr ρ body with
                  | none =>
                      simp [KExpr.instantiateBVar, eraseExpr,
                        ihTy depth, ihVal depth, ihBody (depth + 1),
                        hTy, hVal, hBody]
                  | some b =>
                      simp [KExpr.instantiateBVar, eraseExpr, ErasedExpr.instantiate,
                        ihTy depth, ihVal depth, ihBody (depth + 1),
                        hTy, hVal, hBody]
  | lit _ => rfl
  | mdata _ _ _ => rfl
  | proj _ _ _ _ => rfl

#print axioms eraseExpr_lift
#print axioms eraseExpr_instantiate

end PSKernelFast.Proof
