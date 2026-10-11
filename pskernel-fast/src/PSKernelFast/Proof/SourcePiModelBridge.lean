import PSKernelFast.Spec.TaggedDependentPi
import PSKernelFast.Proof.SourceTaggedContextBridge

/-!
P1m: checked SOURCE Sort/bvar/Pi to the unified tagged/graph Pi model.

Unlike P1i, Pi codomains may have ANY source universe rank, not just Prop.
The numerical annotation is the valuation of the source typing rule's
codomain Sort. No semantic-fibre premise appears in SourcePiAnnotation:
all fibres are DERIVED by source induction and source-context extension.

This remains a precisely guarded fragment: used variables must have an
actual syntactic Sort as their source binder domain. In particular a
proof variable x:P is not mistaken for a proposition P:Prop. No source
lambda/app/let interpretation or general substitution bridge is claimed.
The actual runtime checker and its source judgments are unchanged.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec
universe u

/-- Proof-only annotation syntax; a raw instance is not a checked certificate. -/
inductive PiModelTerm where
  | bvar (index : Nat)
  | sort (level : Nat)
  | pi (codomainLevel : Nat) (domain body : PiModelTerm)
  deriving Repr, Inhabited, BEq, DecidableEq

def PiModelTerm.forget : PiModelTerm → ErasedExpr
  | .bvar i => .bvar i
  | .sort n => .sort n
  | .pi _ domain body => .pi domain.forget body.forget

noncomputable def interpPiModel (V : Type u) [SetTheoryBasis V] :
    (Nat → V) → PiModelTerm → V
  | env, .bvar i => env i
  | _, .sort n => taggedSortSet V n
  | env, .pi v domain body =>
      modelPi V v (interpPiModel V env domain)
        (fun x => interpPiModel V (extendSetEnv x env) body)

/-- Source-only constraints; no V, semantic values or model laws are inputs. -/
inductive SourcePiAnnotation (params : List KName) (ρ : KName → Nat) :
    List KExpr → KExpr → ULevel → PiModelTerm → Prop where
  | sort (ctx : List KExpr) (level : ULevel)
      (good : ULevel.WellFormed params level) :
      SourcePiAnnotation params ρ ctx (.sort level) (.succ level)
        (.sort (level.denote ρ))
  | bvar (ctx : List KExpr) (index : Nat) (level : ULevel)
      (found : ctx[index]? = some (.sort level)) :
      SourcePiAnnotation params ρ ctx (.bvar index) level (.bvar index)
  | pi (ctx : List KExpr) (name : KName) (domain body : KExpr)
      (style : BinderStyle) (domainSort bodySort : ULevel)
      (annDomain annBody : PiModelTerm)
      (domainAnn : SourcePiAnnotation params ρ ctx domain domainSort annDomain)
      (bodyAnn : SourcePiAnnotation params ρ (domain :: ctx) body bodySort annBody) :
      SourcePiAnnotation params ρ ctx (.forallE name domain body style)
        (.imax domainSort bodySort) (.pi (bodySort.denote ρ) annDomain annBody)

/-- Every supported source reconstructs an actual existing G4.3b typing derivation. -/
theorem sourcePiAnnotation_typed (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr level ann}, SourcePiAnnotation params ρ ctx expr level ann →
      GeneralPiRule params ctx expr (.sort level) := by
  intro ctx expr level ann h
  induction h with
  | sort ctx level good => exact .sort ctx level good
  | bvar ctx index level found =>
      exact .bound ctx index (.sort level) found
  | pi ctx name domain body style d b ad ab hd hb ihd ihb =>
      exact .pi ctx name domain body style d b ihd ihb

/-- No annotation may change the underlying source syntax after erasure. -/
theorem sourcePiAnnotation_erases (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr level ann}, SourcePiAnnotation params ρ ctx expr level ann →
      eraseExpr ρ expr = some ann.forget := by
  intro ctx expr level ann h
  induction h with
  | sort ctx level good => rfl
  | bvar ctx index level found => rfl
  | pi ctx name domain body style d b ad ab hd hb ihd ihb =>
      simp [eraseExpr, PiModelTerm.forget, ihd, ihb]

private theorem sourcePiAnnotation_sort_exact
    {params : List KName} {ρ : KName → Nat} {ctx : List KExpr}
    {level result : ULevel} {ann : PiModelTerm}
    (h : SourcePiAnnotation params ρ ctx (.sort level) result ann) :
    ann = .sort (level.denote ρ) := by
  cases h
  rfl

private theorem sourcePiAnnotation_context_extend
    (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ρ : KName → Nat)
    (ctx : List KExpr) (env : Nat → V) (domain : KExpr)
    (level : ULevel) (ann : PiModelTerm)
    (hCtx : TaggedSortContextValid V ρ ctx env)
    (hAnn : SourcePiAnnotation params ρ ctx domain level ann)
    (x : V) (hx : SetTheoryBasis.member x (interpPiModel V env ann)) :
    TaggedSortContextValid V ρ (domain :: ctx) (extendSetEnv x env) := by
  intro i foundLevel hFound
  cases i with
  | zero =>
      have hDomain : domain = .sort foundLevel := by simpa using hFound
      subst domain
      have hSame := sourcePiAnnotation_sort_exact hAnn
      simpa only [hSame, interpPiModel, extendSetEnv] using hx
  | succ i =>
      have hTail : ctx[i]? = some (.sort foundLevel) := by simpa using hFound
      simpa only [extendSetEnv] using hCtx i foundLevel hTail

/--
The source induction discharges the unified Pi algebra's fibre obligations.
Both Prop- and positive-sort codomains use exactly their source-derived rank.
-/
theorem sourcePiAnnotation_model_member
    (V : Type u) [SetTheoryBasis V] (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr level ann}, SourcePiAnnotation params ρ ctx expr level ann →
      ∀ env : Nat → V, TaggedSortContextValid V ρ ctx env →
        SetTheoryBasis.member (interpPiModel V env ann) (taggedSortSet V (level.denote ρ)) := by
  intro ctx expr level ann h
  induction h with
  | sort ctx level good =>
      intro env hCtx
      exact taggedSort_member_succ V ρ level
  | bvar ctx index level found =>
      intro env hCtx
      exact hCtx index level found
  | pi ctx name domain body style d b ad ab hd hb ihd ihb =>
      intro env hCtx
      apply modelPi_member_sort V (d.denote ρ) (b.denote ρ)
        (interpPiModel V env ad) (fun x => interpPiModel V (extendSetEnv x env) ab)
      · exact ihd env hCtx
      · intro x hx
        exact ihb (extendSetEnv x env)
          (sourcePiAnnotation_context_extend V params ρ ctx env domain d ad hCtx hd x hx)

/-- Any actual checker derivation has the EXACT annotated source result, not just a rank. -/
theorem sourcePiAnnotation_result_exact (params : List KName) (ρ : KName → Nat) :
    ∀ {ctx expr level ann}, SourcePiAnnotation params ρ ctx expr level ann →
      ∀ {result}, GeneralPiRule params ctx expr result → result = .sort level := by
  intro ctx expr level ann h
  induction h with
  | sort ctx level good =>
      intro result hTyped
      cases hTyped
      rfl
  | bvar ctx index level found =>
      intro result hTyped
      cases hTyped with
      | bound _ _ domain hFound =>
          have hDomain : domain = .sort level := Option.some.inj (hFound.symm.trans found)
          subst domain
          rfl
  | pi ctx name domain body style d b ad ab hd hb ihd ihb =>
      intro result hTyped
      cases hTyped with
      | pi _ _ _ _ _ dOther bOther hDomOther hBodyOther =>
          have hdEq := ihd hDomOther
          have hbEq := ihb hBodyOther
          have hdSame : dOther = d := by injection hdEq
          have hbSame : bOther = b := by injection hbEq
          subst dOther
          subst bOther
          rfl

/-- Actual closed executions are connected to both source erasure and exact modeled type. -/
theorem sourcePiAnnotation_executed_model
    (V : Type u) [SetTheoryBasis V] (params : List KName) (ρ : KName → Nat)
    (env : Nat → V) (expr result : KExpr) (level : ULevel) (ann : PiModelTerm)
    (hRun : inferClosedGeneralPi params expr = .ok result)
    (hAnn : SourcePiAnnotation params ρ [] expr level ann) :
    result = .sort level ∧
    eraseExpr ρ expr = some ann.forget ∧
    eraseExpr ρ result = some (.sort (level.denote ρ)) ∧
    SetTheoryBasis.member (interpPiModel V env ann)
      (interpPiModel V env (.sort (level.denote ρ))) := by
  have hRule := (inferClosedGeneralPi_sound params expr result hRun).2
  have hResult := sourcePiAnnotation_result_exact params ρ hAnn hRule
  refine ⟨hResult, sourcePiAnnotation_erases params ρ hAnn, ?_, ?_⟩
  · simp [hResult, eraseExpr]
  · exact sourcePiAnnotation_model_member V params ρ hAnn env
      (taggedSortContextValid_empty V ρ env)

/-- One source family covers forall P:Prop, P->P and forall A:Type, A->A. -/
def sourcePiIdentityFamily (level : ULevel) : KExpr :=
  .forallE .anonymous (.sort level)
    (.forallE .anonymous (.bvar 0) (.bvar 1) .default) .default

def sourcePiIdentityFamilyType (level : ULevel) : KExpr :=
  .sort (.imax (.succ level) (.imax level level))

def sourcePiIdentityAnn (n : Nat) : PiModelTerm :=
  .pi (numericImax n n) (.sort n) (.pi n (.bvar 0) (.bvar 1))

/-- All well-formed symbolic universes use the same source-derived annotation proof. -/
theorem sourcePiIdentityFamily_annotation
    (params : List KName) (ρ : KName → Nat) (level : ULevel)
    (good : ULevel.WellFormed params level) :
    SourcePiAnnotation params ρ [] (sourcePiIdentityFamily level)
      (.imax (.succ level) (.imax level level)) (sourcePiIdentityAnn (level.denote ρ)) := by
  refine .pi [] .anonymous (.sort level)
    (.forallE .anonymous (.bvar 0) (.bvar 1) .default) .default
    (.succ level) (.imax level level) (.sort (level.denote ρ))
    (.pi (level.denote ρ) (.bvar 0) (.bvar 1)) (.sort [] level good) ?_
  exact .pi [(.sort level)] .anonymous (.bvar 0) (.bvar 1) .default
    level level (.bvar 0) (.bvar 1)
    (.bvar [(.sort level)] 0 level rfl)
    (.bvar [(.bvar 0), (.sort level)] 1 level rfl)

/-- Kernel-checked computation of the ACTUAL source checker, not native_decide. -/
theorem sourcePiIdentityProp_exec :
    inferClosedGeneralPi [] (sourcePiIdentityFamily .zero) =
      .ok (sourcePiIdentityFamilyType .zero) := by rfl

/-- Positive-sort dependent Pi is not merely an unused mathematical carrier. -/
theorem sourcePiIdentityType_exec :
    inferClosedGeneralPi [] (sourcePiIdentityFamily (.succ .zero)) =
      .ok (sourcePiIdentityFamilyType (.succ .zero)) := by rfl

/-- Real positive-sort source execution and its denotation share the general bridge. -/
theorem sourcePiIdentityType_exec_model
    (V : Type u) [SetTheoryBasis V] (ρ : KName → Nat) (env : Nat → V) :
    inferClosedGeneralPi [] (sourcePiIdentityFamily (.succ .zero)) =
      .ok (sourcePiIdentityFamilyType (.succ .zero)) ∧
    SetTheoryBasis.member (interpPiModel V env (sourcePiIdentityAnn 1)) (taggedSortSet V 2) := by
  have h := sourcePiAnnotation_executed_model V [] ρ env
    (sourcePiIdentityFamily (.succ .zero)) (sourcePiIdentityFamilyType (.succ .zero))
    (.imax (.succ (.succ .zero)) (.imax (.succ .zero) (.succ .zero)))
    (sourcePiIdentityAnn 1) sourcePiIdentityType_exec
    (sourcePiIdentityFamily_annotation [] ρ (.succ .zero) (by trivial))
  exact ⟨sourcePiIdentityType_exec, h.2.2.2⟩

#print axioms sourcePiAnnotation_typed
#print axioms sourcePiAnnotation_erases
#print axioms sourcePiAnnotation_model_member
#print axioms sourcePiAnnotation_result_exact
#print axioms sourcePiAnnotation_executed_model
#print axioms sourcePiIdentityFamily_annotation
#print axioms sourcePiIdentityProp_exec
#print axioms sourcePiIdentityType_exec
#print axioms sourcePiIdentityType_exec_model

end PSKernelFast.Proof
