import Ps.KernelCore.Metatheory.SemanticReference
import Ps.KernelCore.Metatheory.SemanticAnnotationValidity

/-!
Exact observations of successful reference dependent-product inference.
The witnesses are extracted from production code, in either inference mode.
The semantic bridge requires recursive sort evidence only for the four calls
actually visited. It does not postulate a sort for arbitrary inferred types.
-/
namespace PsKernelSemantics.Reference

def binderChild (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (n : PsKernelName) (A : PsKernelExpr) (bi : PsKernelBinderInfo) :
    PsKernelCheckerContext :=
  psKernelCheckerContextWithLocalContext c
    (psKernelLocalContextAddLocal c.localContext
      (psKernelCheckerStateFreshName s n).1 n A bi)

structure ForallTrace (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (n : PsKernelName) (A B : PsKernelExpr) (bi : PsKernelBinderInfo) (io : Bool)
    (result : PsKernelExpr) (next : PsKernelCheckerState) where
  entered : PsKernelCheckerContext
  domainType : PsKernelExpr
  domainState : PsKernelCheckerState
  domainLevel : PsKernelLevel
  domainSortState : PsKernelCheckerState
  bodyType : PsKernelExpr
  bodyState : PsKernelCheckerState
  rangeLevel : PsKernelLevel
  bodySortState : PsKernelCheckerState
  depth : psKernelCheckerContextEnterRecDepth c = .ok entered
  domainRun : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
    remaining whnf defeq entered s A io = .ok (domainType, domainState)
  domainSortRun : psKernelEnsureSortWith whnf entered domainState domainType =
    .ok (domainLevel, domainSortState)
  bodyRun : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy remaining whnf defeq
    (binderChild entered domainSortState n A bi)
    (psKernelCheckerStateFreshName domainSortState n).2
    (psKernelExprInstantiate1 B (.fvar (psKernelCheckerStateFreshName domainSortState n).1))
    io = .ok (bodyType, bodyState)
  bodySortRun : psKernelEnsureSortWith whnf
    (binderChild entered domainSortState n A bi) bodyState bodyType =
    .ok (rangeLevel, bodySortState)
  resultEq : result = .sort (psKernelLevelMkIMax domainLevel rangeLevel)
  stateEq : next = psKernelCheckerStateExitLocalScope
    (psKernelCheckerStateFreshName domainSortState n).2 bodySortState

/-- Successful reference checking really visits both sort checks and the fresh
local body; no cache-miss or semantic validity premise is used here. -/
theorem inferCore_forall_trace (remaining : Nat)
    (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A B : PsKernelExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      (remaining + 1) whnf defeq c s (.forallE n A B bi) io = .ok (result, next)) :
    Nonempty (ForallTrace remaining whnf defeq c s n A B bi io result next) := by
  cases hd : psKernelCheckerContextEnterRecDepth c with
  | error error =>
      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
        ite_self, hd] at run
      cases run
  | ok entered =>
      cases hA : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq entered s A io with
      | error error =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, hd, hA] at run
          cases run
      | ok a =>
          rcases a with ⟨aType, aState⟩
          cases hAS : psKernelEnsureSortWith whnf entered aState aType with
          | error error =>
              simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                ite_self, hd, hA, hAS] at run
              cases run
          | ok ua =>
              rcases ua with ⟨u, us⟩
              cases hB : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
                  remaining whnf defeq (binderChild entered us n A bi)
                  (psKernelCheckerStateFreshName us n).2
                  (psKernelExprInstantiate1 B (.fvar (psKernelCheckerStateFreshName us n).1))
                  io with
              | error error =>
                  simp only [binderChild] at hB
                  simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                    ite_self, hd, hA, hAS, hB] at run
                  cases run
              | ok b =>
                  rcases b with ⟨bType, bState⟩
                  simp only [binderChild] at hB
                  cases hBS : psKernelEnsureSortWith whnf
                      (binderChild entered us n A bi) bState bType with
                  | error error =>
                      simp only [binderChild] at hBS
                      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                        ite_self, hd, hA, hAS, hB, hBS] at run
                      cases run
                  | ok vb =>
                      rcases vb with ⟨v, vs⟩
                      simp only [binderChild] at hBS
                      simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
                        ite_self, hd, hA, hAS, hB, hBS,
                        infer_publication_noop, Except.ok.injEq, Prod.mk.injEq] at run
                      exact ⟨⟨entered, aType, aState, u, us, bType, bState, v, vs,
                        hd, hA, hAS, hB, hBS, run.1.symm, run.2.symm⟩⟩

open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

/-- Pointwise semantic discharge for a concrete observed product run. These
are the recursive obligations at the domain/body sort sites, not an assumed
whole-checker soundness theorem. The returned annotation is the visited range. -/
theorem forall_trace_has_model
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (io : Bool)
    (trace : ForallTrace remaining whnf defeq c s n A.erase B.erase bi io result next)
    (hA : ModelsType M Γ A (.sort trace.domainLevel))
    (hB : ModelsType M (A :: Γ) B (.sort trace.rangeLevel))
    (ha : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ A)
    (hb : ∀ ρ, Satisfies M (A :: Γ) ρ → AnnotationValid M ρ B) :
    ∃ term type : AnnotatedExpr,
      term.erase = .forallE n A.erase B.erase bi ∧ type.erase = result ∧
      ModelsType M Γ term type ∧
      (∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ term) := by
  refine ⟨.forallE n A B bi trace.rangeLevel,
    .sort (psKernelLevelMkIMax trace.domainLevel trace.rangeLevel), rfl,
    trace.resultEq.symm, ?_, ?_⟩
  · intro ρ hρ
    change piR (M.level trace.rangeLevel) (interp M ρ A)
      (fun x => interp M (extend x ρ) B) ∈ˢ
      univ (M.level (psKernelLevelMkIMax trace.domainLevel trace.rangeLevel))
    rw [Reading.level, mkIMax_eval]
    exact pi_mem_sort (hA ρ hρ)
      (fun x hx => hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))
  · intro ρ hρ
    exact annotationValid_forall_of_sort M ρ n A B bi trace.rangeLevel
      (ha ρ hρ)
      (fun x hx => hb (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))
      (fun x hx => hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))

end PsKernelSemantics.Reference
