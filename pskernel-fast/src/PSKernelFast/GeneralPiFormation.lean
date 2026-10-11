import PSKernelFast.Substitution

/-!
G4.4 prototype: a *restricted*, proof-carrying general-domain Pi fragment.
This extends the earlier Sort-only context: domains may themselves be Pi
expressions or context-dependent types, provided their ACTUAL inferred type
is syntactically Sort-shaped. Bound variables read their validated domain
with the correct de Bruijn lift.

This is NOT Lean's complete infer_type_core, WHNF, DefEq, proof acceptance,
or a production-level FullyChecked witness. In particular, syntactic
Sort exposure is deliberately incomplete; a stuck/convertible Sort is
UNSUPPORTED, never silently considered equal.
-/

namespace PSKernelFast.Core

/--
Independent typing rules for Sort, context variables, dependent Pi, lambda introduction and
application with EXACT syntactic domain-type agreement.
No DefEq, let/constant or other logical rules are assumed.
The context must separately be certified well-formed before an executable
checker is allowed to use these rules.
-/
inductive GeneralPiRule (params : List KName) :
    List KExpr → KExpr → KExpr → Prop where
  | sort (ctx : List KExpr) (u : ULevel)
      (good : ULevel.WellFormed params u) :
      GeneralPiRule params ctx (.sort u) (.sort (.succ u))
  | bound (ctx : List KExpr) (index : Nat) (domain : KExpr)
      (found : ctx[index]? = some domain) :
      GeneralPiRule params ctx (.bvar index)
        (domain.liftBVars (index + 1) 0)
  | pi (ctx : List KExpr) (name : KName) (domain body : KExpr)
      (style : BinderStyle) (u v : ULevel)
      (domainTyped : GeneralPiRule params ctx domain (.sort u))
      (bodyTyped : GeneralPiRule params (domain :: ctx) body (.sort v)) :
      GeneralPiRule params ctx (.forallE name domain body style)
        (.sort (.imax u v))

  | lam (ctx : List KExpr) (name : KName) (domain body : KExpr)
      (style : BinderStyle) (u : ULevel) (bodyType : KExpr)
      (domainTyped : GeneralPiRule params ctx domain (.sort u))
      (bodyTyped : GeneralPiRule params (domain :: ctx) body bodyType) :
      GeneralPiRule params ctx (.lam name domain body style)
        (.forallE name domain bodyType style)

  | app (ctx : List KExpr) (fn arg : KExpr)
      (name : KName) (domain body : KExpr) (style : BinderStyle)
      (fnTyped :
        GeneralPiRule params ctx fn (.forallE name domain body style))
      (argTyped : GeneralPiRule params ctx arg domain) :
      GeneralPiRule params ctx (.app fn arg)
        (body.instantiateBVar arg 0)

/--
Only contexts constructed from an empty context by checking a new domain
to HAVE a Sort type are admitted. This proof is separate from the raw
structural frame, and no untrusted catalog can mint it.
-/
inductive GeneralPiContextWF (params : List KName) :
    List KExpr → Prop where
  | empty : GeneralPiContextWF params []
  | extend {ctx : List KExpr} {domain : KExpr} {level : ULevel}
      (parent : GeneralPiContextWF params ctx)
      (domainTyped : GeneralPiRule params ctx domain (.sort level)) :
      GeneralPiContextWF params (domain :: ctx)

/--
Actual interpreter over a well-formed formation context; certificates are
constructed from every successful branch, not an untrusted type annotation.
The source recursion is structural over expr.
-/
def inferGeneralPi {params : List KName} (ctx : List KExpr)
    (wf : GeneralPiContextWF params ctx) :
    (expr : KExpr) →
      Option {ty : KExpr // GeneralPiRule params ctx expr ty}
  | .sort u =>
      if h : u.validParams params = true then
        some ⟨.sort (.succ u),
          .sort ctx u (ULevel.validParams_sound params u h)⟩
      else none
  | .bvar index =>
      match h : ctx[index]? with
      | some domain =>
          some ⟨domain.liftBVars (index + 1) 0,
            .bound ctx index domain h⟩
      | none => none
  | .forallE name domain body style =>
      match inferGeneralPi ctx wf domain with
      | some ⟨.sort u, domainTyped⟩ =>
          match inferGeneralPi (domain :: ctx) (.extend wf domainTyped) body with
          | some ⟨.sort v, bodyTyped⟩ =>
              some ⟨.sort (.imax u v),
                .pi ctx name domain body style u v domainTyped bodyTyped⟩
          | _ => none
      | _ => none
  | .lam name domain body style =>
      match inferGeneralPi ctx wf domain with
      | some ⟨.sort u, domainTyped⟩ =>
          match inferGeneralPi (domain :: ctx) (.extend wf domainTyped) body with
          | some bodyResult =>
              some ⟨.forallE name domain bodyResult.val style,
                .lam ctx name domain body style u bodyResult.val
                  domainTyped bodyResult.property⟩
          | none => none
      | _ => none
  | .app fn arg =>
      match inferGeneralPi ctx wf fn with
      | some ⟨.forallE name domain body style, fnTyped⟩ =>
          match inferGeneralPi ctx wf arg with
          | some argResult =>
              if hEq : argResult.val = domain then
                some ⟨body.instantiateBVar arg 0,
                  .app ctx fn arg name domain body style fnTyped
                    (hEq ▸ argResult.property)⟩
              else none
          | none => none
      | _ => none
  | _ => none

/--
A run-time wrapper for privately **validated in this fragment** contexts.
The packed proof is erased and does not turn the raw context into a trusted
kernel environment or a general dependent typing witness.
-/
structure GeneralPiContext (params : List KName) where
  entries : List KExpr
  valid : GeneralPiContextWF params entries

def GeneralPiContext.empty (params : List KName) :
    GeneralPiContext params :=
  ⟨[], .empty⟩

/-- Extend only when the executing checker sees the domain has Sort type. -/
def GeneralPiContext.extend {params : List KName}
    (ctx : GeneralPiContext params) (domain : KExpr) :
    Option (GeneralPiContext params) :=
  match inferGeneralPi ctx.entries ctx.valid domain with
  | some ⟨.sort _, domainTyped⟩ =>
      some ⟨domain :: ctx.entries, .extend ctx.valid domainTyped⟩
  | _ => none

/-- Observation only: never a source of untrusted checked-type facts. -/
def GeneralPiContext.infer {params : List KName}
    (ctx : GeneralPiContext params) (expr : KExpr) :
    Option {ty : KExpr // GeneralPiRule params ctx.entries expr ty} :=
  inferGeneralPi ctx.entries ctx.valid expr

inductive GeneralPiError where
  | malformed
  | unsupported
  deriving Inhabited, Repr, BEq

/--
Closed, version-scoped input gate. An affirmative answer is a certificate of
ONLY the three GeneralPiRule constructors. No acceptance/admission API exists.
-/
def inferClosedGeneralPi (params : List KName) (expr : KExpr) :
    Except GeneralPiError KExpr :=
  if h : expr.closedInput params = true then
    match inferGeneralPi (params := params) ([] : List KExpr)
      (GeneralPiContextWF.empty (params := params)) expr with
    | some witness => .ok witness.val
    | none => .error .unsupported
  else .error .malformed

/--
Executable-to-judgment theorem for the exact algorithm and closed preflight.
This is intentionally NOT a theorem about Lean 4.35 completeness, verified
model semantics, arbitrary contexts or full-checker soundness.
-/
theorem inferClosedGeneralPi_sound (params : List KName)
    (expr result : KExpr)
    (h : inferClosedGeneralPi params expr = .ok result) :
    KExpr.StructurallyValid params 0 expr ∧
      GeneralPiRule params [] expr result := by
  by_cases hv : expr.closedInput params = true
  · cases hi : inferGeneralPi (params := params) ([] : List KExpr)
      (GeneralPiContextWF.empty (params := params)) expr with
    | none => simp [inferClosedGeneralPi, hv, hi] at h
    | some witness =>
        have hSame : witness.val = result := by
          simpa [inferClosedGeneralPi, hv, hi] using h
        exact ⟨KExpr.closedInput_sound params expr hv,
          hSame ▸ witness.property⟩
  · simp [inferClosedGeneralPi, hv] at h

end PSKernelFast.Core
