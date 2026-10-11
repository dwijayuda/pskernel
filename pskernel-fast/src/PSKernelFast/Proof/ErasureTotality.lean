import PSKernelFast.Proof.Erasure
import PSKernelFast.GeneralPiFormation

/-!
P1c: the independent erased semantic syntax is TOTAL for every term/type
the actual six-rule G4.3b checker can infer in a certified context. The
proof is by RULE induction, NOT just the shape of accepted syntax.

This ensures future denotational interpretation will have inputs for all
successful fragment types. It is NOT yet a SetTheory model, semantic typing
soundness, DefEq, or theorem admission.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec

def Erasable (ρ : KName → Nat) (expr : KExpr) : Prop :=
  ∃ sem : ErasedExpr, eraseExpr ρ expr = some sem

def ContextErasable (ρ : KName → Nat) (ctx : List KExpr) : Prop :=
  ∀ (index : Nat) (domain : KExpr),
    ctx[index]? = some domain → Erasable ρ domain

private theorem contextErasable_empty (ρ : KName → Nat) :
    ContextErasable ρ [] := by
  intro index domain h
  simp at h

private theorem contextErasable_extend (ρ : KName → Nat)
    (ctx : List KExpr) (domain : KExpr)
    (parent : ContextErasable ρ ctx) (hDomain : Erasable ρ domain) :
    ContextErasable ρ (domain :: ctx) := by
  intro index observed h
  cases index with
  | zero =>
      have eq : domain = observed := by simpa using h
      subst observed
      exact hDomain
  | succ older =>
      exact parent older observed (by simpa using h)

private theorem erasable_lift (ρ : KName → Nat) (expr : KExpr)
    (h : Erasable ρ expr) (amount cutoff : Nat) :
    Erasable ρ (expr.liftBVars amount cutoff) := by
  rcases h with ⟨term, hTerm⟩
  refine ⟨term.lift amount cutoff, ?_⟩
  rw [eraseExpr_lift, hTerm]
  rfl

private theorem erasable_instantiate (ρ : KName → Nat)
    (body replacement : KExpr) (hBody : Erasable ρ body)
    (hReplacement : Erasable ρ replacement) (depth : Nat) :
    Erasable ρ (body.instantiateBVar replacement depth) := by
  rcases hBody with ⟨bodyTerm, hBodyTerm⟩
  rcases hReplacement with ⟨replacementTerm, hReplacementTerm⟩
  refine ⟨bodyTerm.instantiate replacementTerm depth, ?_⟩
  rw [eraseExpr_instantiate ρ replacement replacementTerm
      hReplacementTerm body depth, hBodyTerm]
  rfl

private theorem erasable_app (ρ : KName → Nat)
    (fn arg : KExpr) (hFn : Erasable ρ fn) (hArg : Erasable ρ arg) :
    Erasable ρ (.app fn arg) := by
  rcases hFn with ⟨f, hf⟩
  rcases hArg with ⟨a, ha⟩
  refine ⟨.app f a, ?_⟩
  simp [eraseExpr, hf, ha]

private theorem erasable_lam (ρ : KName → Nat)
    (name : KName) (domain body : KExpr) (style : BinderStyle)
    (hDomain : Erasable ρ domain) (hBody : Erasable ρ body) :
    Erasable ρ (.lam name domain body style) := by
  rcases hDomain with ⟨d, hd⟩
  rcases hBody with ⟨b, hb⟩
  refine ⟨.lam d b, ?_⟩
  simp [eraseExpr, hd, hb]

private theorem erasable_pi (ρ : KName → Nat)
    (name : KName) (domain body : KExpr) (style : BinderStyle)
    (hDomain : Erasable ρ domain) (hBody : Erasable ρ body) :
    Erasable ρ (.forallE name domain body style) := by
  rcases hDomain with ⟨d, hd⟩
  rcases hBody with ⟨b, hb⟩
  refine ⟨.pi d b, ?_⟩
  simp [eraseExpr, hd, hb]

private theorem erasable_let (ρ : KName → Nat)
    (name : KName) (ty value body : KExpr)
    (hTy : Erasable ρ ty) (hValue : Erasable ρ value)
    (hBody : Erasable ρ body) :
    Erasable ρ (.letE name ty value body false) := by
  rcases hTy with ⟨t, ht⟩
  rcases hValue with ⟨v, hv⟩
  rcases hBody with ⟨b, hb⟩
  refine ⟨.letE t v b, ?_⟩
  simp [eraseExpr, ht, hv, hb]

/--
Every rule derivation whose parent binder domains are erasable yields
erasable SOURCE TERM and erasable INFERRED TYPE. This includes the result
type after the ACTUAL app/let substitution, relying on the bridge proof.
-/
theorem generalPiRule_erasable (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr ty},
      GeneralPiRule params ctx expr ty →
      ContextErasable ρ ctx →
      Erasable ρ expr ∧ Erasable ρ ty := by
  intro ctx expr ty rule
  induction rule with
  | sort ctx u good =>
      intro _
      exact ⟨⟨.sort (u.denote ρ), rfl⟩,
        ⟨.sort ((ULevel.succ u).denote ρ), rfl⟩⟩
  | bound ctx index domain found =>
      intro hCtx
      exact ⟨⟨.bvar index, rfl⟩,
        erasable_lift ρ domain (hCtx index domain found) (index + 1) 0⟩
  | pi ctx name domain body style u v domainTyped bodyTyped ihDomain ihBody =>
      intro hCtx
      have domErased := (ihDomain hCtx).1
      have hExtended := contextErasable_extend ρ ctx domain hCtx domErased
      have bodyErased := (ihBody hExtended).1
      exact ⟨erasable_pi ρ name domain body style domErased bodyErased,
        ⟨.sort ((ULevel.imax u v).denote ρ), rfl⟩⟩
  | lam ctx name domain body style u bodyType domainTyped bodyTyped
      ihDomain ihBody =>
      intro hCtx
      have domErased := (ihDomain hCtx).1
      have hExtended := contextErasable_extend ρ ctx domain hCtx domErased
      have hBody := ihBody hExtended
      exact ⟨erasable_lam ρ name domain body style domErased hBody.1,
        erasable_pi ρ name domain bodyType style domErased hBody.2⟩
  | app ctx fn arg name domain body style fnTyped argTyped ihFn ihArg =>
      intro hCtx
      have hFn := ihFn hCtx
      have hArg := ihArg hCtx
      obtain ⟨semPi, hPi⟩ := hFn.2
      have hBody : Erasable ρ body := by
        cases hD : eraseExpr ρ domain with
        | none =>
            simp [eraseExpr, hD] at hPi
        | some d =>
            cases hB : eraseExpr ρ body with
            | none =>
                simp [eraseExpr, hD, hB] at hPi
            | some b =>
                exact ⟨b, hB⟩
      exact ⟨erasable_app ρ fn arg hFn.1 hArg.1,
        erasable_instantiate ρ body arg hBody hArg.1 0⟩
  | letE ctx name declaredType value body nondep flag level bodyType
      typeTyped valueTyped bodyTyped ihType ihValue ihBody =>
      intro hCtx
      have hType := ihType hCtx
      have hValue := ihValue hCtx
      have hExtended := contextErasable_extend ρ ctx declaredType
        hCtx hType.1
      have hBody := ihBody hExtended
      have hFlag : nondep = false := flag
      have hLet : Erasable ρ
          (.letE name declaredType value body nondep) := by
        cases nondep with
        | false =>
            exact erasable_let ρ name declaredType value body
              hType.1 hValue.1 hBody.1
        | true => cases hFlag
      exact ⟨hLet,
        erasable_instantiate ρ bodyType value hBody.2 hValue.1 0⟩

/-- The genuinely checked binder-context formation guarantees erasure. -/
theorem generalPiContextWF_erasable (params : List KName)
    (ρ : KName → Nat) :
    ∀ {ctx}, GeneralPiContextWF params ctx → ContextErasable ρ ctx := by
  intro ctx wf
  induction wf with
  | empty => exact contextErasable_empty ρ
  | extend parent domainTyped ih =>
      exact contextErasable_extend ρ _ _ ih
        (generalPiRule_erasable params ρ domainTyped ih).1

/--
Every successfully inferred G4.3b closed expression and its inferred type
admit an independent ground-level erasure under ANY valuation. This is the
minimal total-input gate a later mathematical denotation can rely on.
-/
theorem inferClosedGeneralPi_erasable (params : List KName)
    (ρ : KName → Nat) (expr ty : KExpr)
    (h : inferClosedGeneralPi params expr = .ok ty) :
    Erasable ρ expr ∧ Erasable ρ ty := by
  have rule := (inferClosedGeneralPi_sound params expr ty h).2
  exact generalPiRule_erasable params ρ rule
    (contextErasable_empty ρ)

#print axioms generalPiRule_erasable
#print axioms generalPiContextWF_erasable
#print axioms inferClosedGeneralPi_erasable

end PSKernelFast.Proof
