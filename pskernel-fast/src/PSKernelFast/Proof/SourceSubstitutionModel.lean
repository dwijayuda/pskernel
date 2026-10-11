import PSKernelFast.Spec.AnnotatedSubstitution
import PSKernelFast.Proof.SourcePiModelBridge
import PSKernelFast.TypedNormalization

/-!
P1n: actual SOURCE substitution / model connection, not a second checker.

The new annotation syntax embeds the already-qualified P1m interpretation.
Its substitution erasure is tied to real KExpr.instantiateBVar by the
existing source-erasure theorem. Combined with semantic substitution,
this yields beta/zeta equations for matching source redex annotations.

IMPORTANT: erasure is only syntactic correspondence; it does NOT validate
codomain ranks. General beta retains explicit fibre/body/argument semantic
membership premises. A complete source typing induction that derives all
such premises and coherent annotations is still required for stepSound.
The closed polymorphic identity cases below derive their memberships and
check the ACTUAL lambda terms, including a proof variable x:P.

General context lookup interprets a stored domain in the original outer
environment, not in the current environment. The proved lift law connects
this to the source checker's actual lifted domain. No Sort-only variable
guard is imposed, but a valid annotated model context remains a premise.
All proofs are conditional on the UNCHANGED SetTheoryBasis V.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core
open PSKernelFast.Spec
universe u

/-- Preserve P1m's meaning; do not introduce an unrelated Pi interpretation. -/
def PiModelTerm.toAnnotated : PiModelTerm → AnnotatedModelTerm
  | .bvar i => .bvar i
  | .sort n => .sort n
  | .pi n a b => .pi n a.toAnnotated b.toAnnotated

theorem PiModelTerm.toAnnotated_forget (term : PiModelTerm) :
    term.toAnnotated.forget = term.forget := by
  induction term with
  | bvar i => rfl
  | sort n => rfl
  | pi n a b iha ihb =>
      simp only [toAnnotated, AnnotatedModelTerm.forget, forget, iha, ihb]

theorem PiModelTerm.toAnnotated_interp (V : Type u) [SetTheoryBasis V]
    (term : PiModelTerm) (env : Nat → V) :
    interpAnnotated V env term.toAnnotated = interpPiModel V env term := by
  induction term generalizing env with
  | bvar i => rfl
  | sort n => rfl
  | pi n a b iha ihb =>
      simp only [toAnnotated, interpAnnotated, interpPiModel, iha, ihb]

/-- Exact lifting correspondence for an explicit source/annotation pair. -/
theorem source_annotated_lift (ρ : KName → Nat)
    (source : KExpr) (ann : AnnotatedModelTerm) (amount cutoff : Nat)
    (h : eraseExpr ρ source = some ann.forget) :
    eraseExpr ρ (source.liftBVars amount cutoff) =
      some (ann.lift amount cutoff).forget := by
  rw [eraseExpr_lift, h]
  simp only [Option.map_some, AnnotatedModelTerm.forget_lift]

/-- Uses the ACTUAL runtime operation's pre-existing erasure refinement. -/
theorem source_annotated_instantiate (ρ : KName → Nat)
    (source replacement : KExpr) (ann rep : AnnotatedModelTerm) (depth : Nat)
    (hSource : eraseExpr ρ source = some ann.forget)
    (hRep : eraseExpr ρ replacement = some rep.forget) :
    eraseExpr ρ (source.instantiateBVar replacement depth) =
      some (ann.instantiate rep depth).forget := by
  rw [eraseExpr_instantiate ρ replacement rep.forget hRep source depth, hSource]
  simp only [Option.map_some, AnnotatedModelTerm.forget_instantiate]

/--
One theorem pairs actual source substitution with the derived all-depth
semantic equation. It does not claim uniqueness of arbitrary annotations.
-/
theorem source_annotated_substitution_model (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (source replacement : KExpr)
    (ann rep : AnnotatedModelTerm) (depth : Nat) (env : Nat → V)
    (hSource : eraseExpr ρ source = some ann.forget)
    (hRep : eraseExpr ρ replacement = some rep.forget) :
    eraseExpr ρ (source.instantiateBVar replacement depth) =
        some (ann.instantiate rep depth).forget ∧
    interpAnnotated V env (ann.instantiate rep depth) =
      interpAnnotated V
        (insertModelEnv depth (interpAnnotated V (dropModelEnv depth env) rep) env) ann :=
  ⟨source_annotated_instantiate ρ source replacement ann rep depth hSource hRep,
    interpAnnotated_instantiate V ann rep depth env⟩

/--
Source beta with exact redex/reduct erasures and actual operational evidence.
Semantic fibre/body premises are EXPLICIT, not new source-soundness axioms.
-/
theorem source_annotated_beta (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) (name : KName) (style : BinderStyle)
    (domain body arg : KExpr) (ad ab aa : AnnotatedModelTerm) (rank : Nat)
    (B : V → V)
    (hd : eraseExpr ρ domain = some ad.forget)
    (hb : eraseExpr ρ body = some ab.forget)
    (ha : eraseExpr ρ arg = some aa.forget)
    (hB : ∀ x : V, SetTheoryBasis.member x (interpAnnotated V env ad) →
      SetTheoryBasis.member (B x) (taggedSortSet V rank))
    (hBody : ∀ x : V, SetTheoryBasis.member x (interpAnnotated V env ad) →
      SetTheoryBasis.member (interpAnnotated V (extendSetEnv x env) ab) (B x))
    (hArg : SetTheoryBasis.member (interpAnnotated V env aa) (interpAnnotated V env ad)) :
    WeakHeadStep (.app (.lam name domain body style) arg) (body.instantiateBVar arg 0) ∧
    eraseExpr ρ (.app (.lam name domain body style) arg) =
      some (AnnotatedModelTerm.app (.lam rank ad ab) aa).forget ∧
    eraseExpr ρ (body.instantiateBVar arg 0) = some (ab.instantiate aa 0).forget ∧
    interpAnnotated V env (.app (.lam rank ad ab) aa) =
      interpAnnotated V env (ab.instantiate aa 0) := by
  refine ⟨.beta name domain body style arg, ?_,
    source_annotated_instantiate ρ body arg ab aa 0 hb ha, ?_⟩
  · simp [eraseExpr, hd, hb, ha, AnnotatedModelTerm.forget]
  · rw [interpAnnotated_instantiate_zero]
    exact modelPi_beta V rank (interpAnnotated V env ad) B
      (fun x => interpAnnotated V (extendSetEnv x env) ab)
      (interpAnnotated V env aa) hB hBody hArg

/-- Source let-zeta needs no Pi-regime guess and uses the same substitution law. -/
theorem source_annotated_zeta (V : Type u) [SetTheoryBasis V]
    (ρ : KName → Nat) (env : Nat → V) (name : KName)
    (type value body : KExpr) (aType av ab : AnnotatedModelTerm)
    (ht : eraseExpr ρ type = some aType.forget)
    (hv : eraseExpr ρ value = some av.forget)
    (hb : eraseExpr ρ body = some ab.forget) :
    WeakHeadStep (.letE name type value body false) (body.instantiateBVar value 0) ∧
    eraseExpr ρ (.letE name type value body false) =
      some (AnnotatedModelTerm.letE aType av ab).forget ∧
    eraseExpr ρ (body.instantiateBVar value 0) = some (ab.instantiate av 0).forget ∧
    interpAnnotated V env (.letE aType av ab) =
      interpAnnotated V env (ab.instantiate av 0) := by
  refine ⟨.zeta name type value body, ?_,
    source_annotated_instantiate ρ body value ab av 0 hb hv, ?_⟩
  · simp [eraseExpr, ht, hv, hb, AnnotatedModelTerm.forget]
  · exact (interpAnnotated_instantiate_zero V ab av env).symm

/-- Stored dependent domain is interpreted OUTSIDE its own and all newer binders. -/
def AnnotatedContextValid (V : Type u) [SetTheoryBasis V]
    (ctx : List AnnotatedModelTerm) (env : Nat → V) : Prop :=
  ∀ i domain, ctx[i]? = some domain →
    SetTheoryBasis.member (env i)
      (interpAnnotated V (dropModelEnv (i + 1) env) domain)

theorem AnnotatedContextValid.empty (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) : AnnotatedContextValid V [] env := by
  intro i domain h
  simp at h

theorem AnnotatedContextValid.extend (V : Type u) [SetTheoryBasis V]
    (ctx : List AnnotatedModelTerm) (env : Nat → V) (domain : AnnotatedModelTerm)
    (x : V) (hCtx : AnnotatedContextValid V ctx env)
    (hx : SetTheoryBasis.member x (interpAnnotated V env domain)) :
    AnnotatedContextValid V (domain :: ctx) (extendSetEnv x env) := by
  intro i stored found
  cases i with
  | zero =>
      have hs : domain = stored := by simpa using found
      subst stored
      change SetTheoryBasis.member x
        (interpAnnotated V (dropModelEnv 1 (extendSetEnv x env)) domain)
      have he : dropModelEnv 1 (extendSetEnv x env) = env := rfl
      rw [he]
      exact hx
  | succ i =>
      have ht : ctx[i]? = some stored := by simpa using found
      change SetTheoryBasis.member (env i)
        (interpAnnotated V (dropModelEnv (i + 2) (extendSetEnv x env)) stored)
      have he : dropModelEnv (i + 2) (extendSetEnv x env) =
          dropModelEnv (i + 1) env := by
        funext j
        simp [dropModelEnv, extendSetEnv, Nat.add_assoc]
      rw [he]
      exact hCtx i stored ht

/--
Actual source lookup and actual lifted inferred domain meet the model.
Unlike P1m's Sort-only guard, sourceDomain may be a dependent type or P.
This requires matching stored annotations and a valid model environment;
it is not a theorem constructing such annotations for all source contexts.
-/
theorem source_bound_annotated_model (V : Type u) [SetTheoryBasis V]
    (params : List KName) (ctx : GeneralPiContext params) (ρ : KName → Nat)
    (modelCtx : List AnnotatedModelTerm) (env : Nat → V)
    (index : Nat) (sourceDomain : KExpr) (annDomain : AnnotatedModelTerm)
    (hSource : ctx.entries[index]? = some sourceDomain)
    (hAnn : modelCtx[index]? = some annDomain)
    (hErase : eraseExpr ρ sourceDomain = some annDomain.forget)
    (hModel : AnnotatedContextValid V modelCtx env) :
    (ctx.infer (.bvar index)).map (fun w => w.val) =
      some (sourceDomain.liftBVars (index + 1) 0) ∧
    eraseExpr ρ (sourceDomain.liftBVars (index + 1) 0) =
      some (annDomain.lift (index + 1) 0).forget ∧
    SetTheoryBasis.member (env index)
      (interpAnnotated V env (annDomain.lift (index + 1) 0)) := by
  refine ⟨?_, source_annotated_lift ρ sourceDomain annDomain (index + 1) 0 hErase, ?_⟩
  · unfold GeneralPiContext.infer
    simp only [inferGeneralPi]
    split
    · rename_i domain hFound
      have hDomain : domain = sourceDomain :=
        Option.some.inj (hFound.symm.trans hSource)
      subst domain
      rfl
    · rename_i hFound
      have hImpossible : (none : Option KExpr) = some sourceDomain :=
        hFound.symm.trans hSource
      cases hImpossible
  · rw [interpAnnotated_lift]
    have he : pullLiftEnv (index + 1) 0 env = dropModelEnv (index + 1) env := by
      funext i
      simp [pullLiftEnv, dropModelEnv]
    rw [he]
    exact hModel index annDomain hAnn

/-- Closed source TERM family, not merely formation of its Pi type. -/
def polyIdentitySource (level : ULevel) : KExpr :=
  .lam (.str .anonymous "A") (.sort level)
    (.lam (.str .anonymous "x") (.bvar 0) (.bvar 0) .default) .default

def polyIdentitySourceType (level : ULevel) : KExpr :=
  .forallE (.str .anonymous "A") (.sort level)
    (.forallE (.str .anonymous "x") (.bvar 0) (.bvar 1) .default) .default

def polyIdentityAnnotation (rank : Nat) : AnnotatedModelTerm :=
  .lam rank (.sort rank) (.lam rank (.bvar 0) (.bvar 0))

def polyIdentityTypeAnnotation (rank : Nat) : AnnotatedModelTerm :=
  .pi rank (.sort rank) (.pi rank (.bvar 0) (.bvar 1))

/-- Rank n is justified by the exact imax(n,n)=n of the inner source Pi. -/
theorem polyIdentity_model_member (V : Type u) [SetTheoryBasis V]
    (rank : Nat) (env : Nat → V) :
    SetTheoryBasis.member (interpAnnotated V env (polyIdentityAnnotation rank))
      (interpAnnotated V env (polyIdentityTypeAnnotation rank)) := by
  change SetTheoryBasis.member
    (modelLam V rank (taggedSortSet V rank) (fun A => modelLam V rank A (fun x => x)))
    (modelPi V rank (taggedSortSet V rank) (fun A => modelPi V rank A (fun _ => A)))
  apply modelLam_intro V rank
  · intro A hA
    have hRank : numericImax rank rank = rank := by
      cases rank <;> simp [numericImax]
    have h := modelPi_member_sort V rank rank A (fun _ => A) hA (fun _ _ => hA)
    rw [hRank] at h
    exact h
  · intro A hA
    exact modelLam_intro V rank A (fun _ => A) (fun x => x)
      (fun _ _ => hA) (fun _ hx => hx)

theorem polyIdentity_source_erasure (ρ : KName → Nat) (level : ULevel) :
    eraseExpr ρ (polyIdentitySource level) =
        some (polyIdentityAnnotation (level.denote ρ)).forget ∧
    eraseExpr ρ (polyIdentitySourceType level) =
        some (polyIdentityTypeAnnotation (level.denote ρ)).forget := ⟨rfl, rfl⟩

/--
Real successful closed executions plus modeled inferred-type membership,
for BOTH proof-valued and data-valued identity implementations. No native
proof evaluation or assumed typing result: checker equations are rfl.
-/
theorem polyIdentity_checked_cases (V : Type u) [SetTheoryBasis V] (env : Nat → V) :
    inferClosedGeneralPi [] (polyIdentitySource .zero) =
        .ok (polyIdentitySourceType .zero) ∧
    inferClosedGeneralPi [] (polyIdentitySource (.succ .zero)) =
        .ok (polyIdentitySourceType (.succ .zero)) ∧
    SetTheoryBasis.member (interpAnnotated V env (polyIdentityAnnotation 0))
      (interpAnnotated V env (polyIdentityTypeAnnotation 0)) ∧
    SetTheoryBasis.member (interpAnnotated V env (polyIdentityAnnotation 1))
      (interpAnnotated V env (polyIdentityTypeAnnotation 1)) :=
  ⟨rfl, rfl, polyIdentity_model_member V 0 env, polyIdentity_model_member V 1 env⟩

#print axioms PiModelTerm.toAnnotated_forget
#print axioms PiModelTerm.toAnnotated_interp
#print axioms source_annotated_lift
#print axioms source_annotated_instantiate
#print axioms source_annotated_substitution_model
#print axioms source_annotated_beta
#print axioms source_annotated_zeta
#print axioms AnnotatedContextValid.empty
#print axioms AnnotatedContextValid.extend
#print axioms source_bound_annotated_model
#print axioms polyIdentity_model_member
#print axioms polyIdentity_source_erasure
#print axioms polyIdentity_checked_cases

end PSKernelFast.Proof
