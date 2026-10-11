import PSKernelFast.GeneralPiFormation

/-!
G4.4b: checked, fuel-indexed beta/zeta weak-head joins.

The existing G4.3b checker is the ONLY source typing authority here. Every
intermediate reduct must check at the original EXACT syntactic type.
Proof traces live in Prop, so they are erased rather than stored at runtime.
The accumulator loop is tail recursive; it retains a current term and count,
not a Type-valued list of historical terms or certificates.

Fuel is PER SIDE and counts head inspections, including the final stable
inspection. n contractions require at least n+1 fuel. It does NOT bound term
size, substitution allocation, the source checker or application-spine depth.
No hard CPU/RSS bound is claimed. Unsupported input and incomplete conversion
remain unresolved; this module never authorizes declaration admission.

No delta/iota, quotient, proof irrelevance, eta, reduction under binders or
argument congruence, complete universe conversion, or set-model preservation
is asserted. Equality means a common syntactic weak-head result, reached
through typed beta/zeta steps in precisely the same source context.
-/

namespace PSKernelFast.Core

/-- Independent operational rule family: beta, restricted zeta, head spine. -/
inductive WeakHeadStep : KExpr → KExpr → Prop where
  | beta (name : KName) (domain body : KExpr)
      (style : BinderStyle) (arg : KExpr) :
      WeakHeadStep (.app (.lam name domain body style) arg)
        (body.instantiateBVar arg 0)
  | zeta (name : KName) (ty value body : KExpr) :
      WeakHeadStep (.letE name ty value body false)
        (body.instantiateBVar value 0)
  | app {fn next : KExpr} (step : WeakHeadStep fn next) (arg : KExpr) :
      WeakHeadStep (.app fn arg) (.app next arg)

/-- One actual contraction, with ERASED evidence and a retained result only. -/
def stepWeakHead : (expr : KExpr) →
    Option { next : KExpr // WeakHeadStep expr next }
  | .app (.lam name domain body style) arg =>
      some ⟨body.instantiateBVar arg 0, .beta name domain body style arg⟩
  | .app fn arg =>
      match stepWeakHead fn with
      | some next => some ⟨.app next.val arg, .app next.property arg⟩
      | none => none
  | .letE name ty value body false =>
      some ⟨body.instantiateBVar value 0, .zeta name ty value body⟩
  | _ => none

/-- Every visited term is checked at one fixed type in one fixed context. -/
inductive TypedSteps (params : List KName) (ctx : List KExpr) (ty : KExpr) :
    Nat → KExpr → KExpr → Prop where
  | refl {expr : KExpr} (typed : GeneralPiRule params ctx expr ty) :
      TypedSteps params ctx ty 0 expr expr
  | snoc {source current next : KExpr} {steps : Nat}
      (prior : TypedSteps params ctx ty steps source current)
      (reduction : WeakHeadStep current next)
      (typed : GeneralPiRule params ctx next ty) :
      TypedSteps params ctx ty (steps + 1) source next

theorem TypedSteps.source_typed
    {params : List KName} {ctx : List KExpr} {ty source target : KExpr}
    {n : Nat} (h : TypedSteps params ctx ty n source target) :
    GeneralPiRule params ctx source ty := by
  induction h with
  | refl typed => exact typed
  | snoc prior reduction typed ih => exact ih

theorem TypedSteps.target_typed
    {params : List KName} {ctx : List KExpr} {ty source target : KExpr}
    {n : Nat} (h : TypedSteps params ctx ty n source target) :
    GeneralPiRule params ctx target ty := by
  cases h with
  | refl typed => exact typed
  | snoc prior reduction typed => exact typed

/--
Composition interface for future semantics. The one-step semantic law is an
EXPLICIT premise, not a new axiom or an already-proved model of beta/zeta.
-/
theorem TypedSteps.denotation_preserved
    {params : List KName} {ctx : List KExpr} {ty source target : KExpr}
    {n : Nat} {A : Type} (denote : KExpr → A)
    (stepSound : ∀ {a b : KExpr},
      GeneralPiRule params ctx a ty → GeneralPiRule params ctx b ty →
      WeakHeadStep a b → denote a = denote b)
    (path : TypedSteps params ctx ty n source target) :
    denote source = denote target := by
  induction path with
  | refl typed => rfl
  | snoc prior reduction typed ih =>
      exact ih.trans (stepSound prior.target_typed typed reduction)

/-- Runtime payload: final term and count. The path/bounds/stability are Prop. -/
structure TypedNormalForm (params : List KName) (ctx : List KExpr)
    (ty : KExpr) (fuel : Nat) (source : KExpr) where
  value : KExpr
  steps : Nat
  path : TypedSteps params ctx ty steps source value
  within : steps < fuel
  stable : stepWeakHead value = none

inductive TypedNormalizationResult (params : List KName) (ctx : List KExpr)
    (ty : KExpr) (fuel : Nat) (source : KExpr) where
  | done (normal : TypedNormalForm params ctx ty fuel source)
  | unresolved
  | resourceExhausted

/-- Tail-recursive loop. The accumulated historical path is erased. -/
private def normalizeTypedLoop {params : List KName}
    (ctx : GeneralPiContext params) (ty source : KExpr) (limit : Nat) :
    (remaining used : Nat) → (current : KExpr) →
    used + remaining = limit →
    TypedSteps params ctx.entries ty used source current →
    TypedNormalizationResult params ctx.entries ty limit source
  | 0, _, _, _, _ => .resourceExhausted
  | remaining + 1, used, current, balance, path =>
      match hNext : stepWeakHead current with
      | none => .done {
          value := current
          steps := used
          path := path
          within := by omega
          stable := hNext
        }
      | some next =>
          match ctx.infer next.val with
          | none => .unresolved
          | some checked =>
              if same : checked.val = ty then
                normalizeTypedLoop ctx ty source limit remaining (used + 1)
                  next.val (by omega)
                  (.snoc path next.property (same ▸ checked.property))
              else .unresolved

/-- Entry for an actually source-typed term, not unchecked frontend metadata. -/
def normalizeTyped {params : List KName}
    (ctx : GeneralPiContext params) (ty source : KExpr)
    (typed : GeneralPiRule params ctx.entries source ty) (fuel : Nat) :
    TypedNormalizationResult params ctx.entries ty fuel source :=
  normalizeTypedLoop ctx ty source fuel fuel 0 source
    (Nat.zero_add fuel) (.refl typed)

/-- Common reduct with two ERASED paths; source context/type are fixed indices. -/
structure JoinedCertificate (params : List KName) (ctx : List KExpr)
    (fuel : Nat) (lhs rhs : KExpr) where
  ty : KExpr
  common : KExpr
  leftSteps : Nat
  rightSteps : Nat
  leftPath : TypedSteps params ctx ty leftSteps lhs common
  rightPath : TypedSteps params ctx ty rightSteps rhs common
  leftBound : leftSteps < fuel
  rightBound : rightSteps < fuel
  stable : stepWeakHead common = none

inductive WeakHeadDecision (params : List KName) (ctx : List KExpr)
    (fuel : Nat) (lhs rhs : KExpr) where
  | equal (certificate : JoinedCertificate params ctx fuel lhs rhs)
  | unresolved
  | malformed
  | resourceExhausted

def WeakHeadDecision.isEqual {params : List KName} {ctx : List KExpr}
    {fuel : Nat} {lhs rhs : KExpr} :
    WeakHeadDecision params ctx fuel lhs rhs → Bool
  | .equal _ => true
  | _ => false

/--
Positive-only common-head conversion. The fuel bound applies independently
on each side. Different stable heads are unresolved, NOT proved unequal.
Malformed scope is checked before fuel; no hard allocation bound is claimed.
-/
def compareTypedWH {params : List KName} (ctx : GeneralPiContext params)
    (lhs rhs : KExpr) (fuel : Nat) :
    WeakHeadDecision params ctx.entries fuel lhs rhs :=
  if !lhs.validAt params ctx.entries.length ||
      !rhs.validAt params ctx.entries.length then
    .malformed
  else
    match fuel with
    | 0 => .resourceExhausted
    | fuel + 1 =>
        match ctx.infer lhs, ctx.infer rhs with
        | some left, some right =>
            if sameType : left.val = right.val then
              match normalizeTyped ctx left.val lhs left.property (fuel + 1) with
              | .unresolved => .unresolved
              | .resourceExhausted => .resourceExhausted
              | .done ln =>
                  match normalizeTyped ctx left.val rhs
                      (sameType.symm ▸ right.property) (fuel + 1) with
                  | .unresolved => .unresolved
                  | .resourceExhausted => .resourceExhausted
                  | .done rn =>
                      if sameHead : ln.value = rn.value then
                        .equal {
                          ty := left.val
                          common := ln.value
                          leftSteps := ln.steps
                          rightSteps := rn.steps
                          leftPath := ln.path
                          rightPath := by simpa only [sameHead] using rn.path
                          leftBound := ln.within
                          rightBound := rn.within
                          stable := ln.stable
                        }
                      else .unresolved
            else .unresolved
        | _, _ => .unresolved

/-- Actual executable yes entails two bounded typed paths to one common term. -/
theorem compareTypedWH_positive
    {params : List KName} (ctx : GeneralPiContext params)
    (lhs rhs : KExpr) (fuel : Nat)
    (h : (compareTypedWH ctx lhs rhs fuel).isEqual = true) :
    ∃ ty common : KExpr, ∃ leftSteps rightSteps : Nat,
      leftSteps < fuel ∧ rightSteps < fuel ∧
      TypedSteps params ctx.entries ty leftSteps lhs common ∧
      TypedSteps params ctx.entries ty rightSteps rhs common ∧
      stepWeakHead common = none := by
  cases result : compareTypedWH ctx lhs rhs fuel with
  | equal cert =>
      exact ⟨cert.ty, cert.common, cert.leftSteps, cert.rightSteps,
        cert.leftBound, cert.rightBound, cert.leftPath, cert.rightPath,
        cert.stable⟩
  | unresolved => simp [result, WeakHeadDecision.isEqual] at h
  | malformed => simp [result, WeakHeadDecision.isEqual] at h
  | resourceExhausted => simp [result, WeakHeadDecision.isEqual] at h

theorem compareTypedWH_zero
    {params : List KName} (ctx : GeneralPiContext params) (lhs rhs : KExpr) :
    (compareTypedWH ctx lhs rhs 0).isEqual = false := by
  unfold compareTypedWH
  split <;> rfl

theorem JoinedCertificate.total_steps_bound
    {params : List KName} {ctx : List KExpr} {fuel : Nat} {lhs rhs : KExpr}
    (cert : JoinedCertificate params ctx fuel lhs rhs) :
    cert.leftSteps + cert.rightSteps < 2 * fuel := by
  have hl := cert.leftBound
  have hr := cert.rightBound
  omega

#print axioms TypedSteps.source_typed
#print axioms TypedSteps.target_typed
#print axioms TypedSteps.denotation_preserved
#print axioms compareTypedWH_positive
#print axioms compareTypedWH_zero
#print axioms JoinedCertificate.total_steps_bound

end PSKernelFast.Core
