import Ps.KernelCore.Metatheory.SemanticReferenceBinders
import Ps.KernelCore.Metatheory.SemanticFunctionValidity

/-!
The actual checked lambda branch. In particular, this records cheap beta
reduction of the inferred body type and closing the allocator's fresh name.
Unlike forall inference, lambda inference does not visit a body-sort check.
Consequently the model bridge keeps body-type reduction preservation and the
proof-valued fibre obligation explicit; neither is invented from a sort visit.
-/
namespace PsKernelSemantics.Reference

structure LambdaTrace (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (n : PsKernelName) (A b : PsKernelExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (next : PsKernelCheckerState) where
  entered : PsKernelCheckerContext
  domainType : PsKernelExpr
  domainState : PsKernelCheckerState
  domainLevel : PsKernelLevel
  domainSortState : PsKernelCheckerState
  bodyType : PsKernelExpr
  bodyState : PsKernelCheckerState
  depth : psKernelCheckerContextEnterRecDepth c = .ok entered
  domainRun : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
    remaining whnf defeq entered s A false = .ok (domainType, domainState)
  domainSortRun : psKernelEnsureSortWith whnf entered domainState domainType =
    .ok (domainLevel, domainSortState)
  bodyRun : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy remaining whnf defeq
    (binderChild entered domainSortState n A bi)
    (psKernelCheckerStateFreshName domainSortState n).2
    (psKernelExprInstantiate1 b (.fvar (psKernelCheckerStateFreshName domainSortState n).1))
    false = .ok (bodyType, bodyState)
  resultEq : result = .forallE n A
    (psKernelExprAbstractFVars (psKernelExprCheapBetaReduce bodyType)
      [(psKernelCheckerStateFreshName domainSortState n).1]) bi
  stateEq : next = psKernelCheckerStateExitLocalScope
    (psKernelCheckerStateFreshName domainSortState n).2 bodyState

theorem inferCore_lam_trace (remaining : Nat)
    (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A b : PsKernelExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      (remaining + 1) whnf defeq c s (.lam n A b bi) false = .ok (result, next)) :
    Nonempty (LambdaTrace remaining whnf defeq c s n A b bi result next) := by
  cases hd : psKernelCheckerContextEnterRecDepth c with
  | error error =>
      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
        ite_self, hd] at run
      cases run
  | ok entered =>
      cases hA : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq entered s A false with
      | error error =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd, Bool.false_eq_true, ite_false, hA] at run
          cases run
      | ok a =>
          rcases a with ⟨aType, aState⟩
          cases hAS : psKernelEnsureSortWith whnf entered aState aType with
          | error error =>
              simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                ite_self, hd, Bool.false_eq_true, ite_false, hA, hAS] at run
              cases run
          | ok ua =>
              rcases ua with ⟨u, us⟩
              cases hB : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
                  remaining whnf defeq (binderChild entered us n A bi)
                  (psKernelCheckerStateFreshName us n).2
                  (psKernelExprInstantiate1 b (.fvar (psKernelCheckerStateFreshName us n).1))
                  false with
              | error error =>
                  simp only [binderChild] at hB
                  simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                    ite_self, hd, Bool.false_eq_true, ite_false, hA, hAS, hB] at run
                  cases run
              | ok body =>
                  rcases body with ⟨bType, bState⟩
                  simp only [binderChild] at hB
                  simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                    ite_self, hd, Bool.false_eq_true, ite_false, hA, hAS, hB,
                    infer_publication_noop, Except.ok.injEq, Prod.mk.injEq] at run
                  exact ⟨⟨entered, aType, aState, u, us, bType, bState,
                    hd, hA, hAS, hB, run.1.symm, run.2.symm⟩⟩

open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

/-- The actual returned type has a reading if the observed opened body is
typed, its cheap-beta type reduction preserves meaning, and the selected
lambda regime has truth-valued fibres when zero. Recursive checker validity,
reduction preservation and regime selection remain explicit obligations. -/
theorem lambda_trace_model_from_visits
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A b U C : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (v : PsKernelLevel)
    (trace : LambdaTrace remaining whnf defeq c s n A.erase b.erase bi result next)
    (hU : U.erase = trace.bodyType)
    (hC : C.erase = psKernelExprCheapBetaReduce U.erase)
    (scopedC : C.Scoped 0)
    (fresh : Fresh (psKernelCheckerStateFreshName trace.domainSortState n).1 b)
    (bodyTyped : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x)
          ρ (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) b 0) ∈ˢ
        interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U)
    (typeReduction : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ U =
        interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ C)
    (truthValues : M.level v = 0 → ∀ ρ, Satisfies M Γ ρ →
      ∀ x, x ∈ˢ interp M ρ A →
        interp (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x) ρ C ∈ˢ
          (univ 0 : V))
    (domainValid : ∀ ρ, Satisfies M Γ ρ → FunctionValid M ρ A)
    (bodyValid : ∀ ρ, Satisfies M Γ ρ → ∀ x, x ∈ˢ interp M ρ A →
      FunctionValid (M.withFree (psKernelCheckerStateFreshName trace.domainSortState n).1 x)
        ρ (inst (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1) b 0)) :
    ∃ term type : AnnotatedExpr,
      term.erase = .lam n A.erase b.erase bi ∧ type.erase = result ∧
      ModelsType M Γ term type ∧
      (∀ ρ, Satisfies M Γ ρ → FunctionValid M ρ term) := by
  let name := (psKernelCheckerStateFreshName trace.domainSortState n).1
  have opened (ρ : Nat → V) (x : V) :
      interp (M.withFree name x) ρ (inst (.fvar name) b 0) =
        interp M (extend x ρ) b := by
    rw [interp_inst_zero]
    have hn : psKernelNameEq name name = true :=
      psKernelNameEq_refl_of_string_law (fun s => by simp [psKernelStringEq]) name
    change interp (M.withFree name x)
      (extend (if psKernelNameEq name name then x else M.freeVars name) ρ) b = _
    simp only [hn, ite_true]
    exact interp_withFree_fresh M b name fresh x (extend x ρ)
  have typed (ρ : Nat → V) (hρ : Satisfies M Γ ρ)
      (x : V) (hx : x ∈ˢ interp M ρ A) :
      interp M (extend x ρ) b ∈ˢ interp M (extend x ρ) (close name C 0) := by
    rw [abstractFVar_closed_input M C name scopedC ρ x]
    rw [← typeReduction ρ hρ x hx, ← opened ρ x]
    exact bodyTyped ρ hρ x hx
  refine ⟨.lam n A b bi v, .forallE n A (close name C 0) bi v, rfl, ?_, ?_, ?_⟩
  · change PsKernelExpr.forallE n A.erase (close name C 0).erase bi = result
    rw [erase_abstractFVar, hC, hU]
    exact trace.resultEq.symm
  · intro ρ hρ
    exact lamR_mem (typed ρ hρ)
  · intro ρ hρ
    refine ⟨domainValid ρ hρ, ?_,
      (fun x => interp M (extend x ρ) (close name C 0)), typed ρ hρ, ?_⟩
    · intro x hx
      exact (functionValid_open_fresh M b name fresh x ρ).mp (bodyValid ρ hρ x hx)
    · intro hz x hx
      rw [abstractFVar_closed_input M C name scopedC ρ x]
      exact truthValues hz ρ hρ x hx

end PsKernelSemantics.Reference
