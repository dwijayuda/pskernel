import Ps.KernelCore.Metatheory.SemanticUniverseSubstitution
import Ps.KernelCore.Metatheory.SemanticSortInference

/-!
The actual constant-inference branch, including its cache-hit path.
An environment model must provide membership at the instantiated valuation.
This theorem consumes that declaration fact; it does not assert that admission
has established it, or that the resulting cache state is globally valid.
-/

namespace PsKernelSemantics

private theorem entered_environment (context entered : PsKernelCheckerContext)
    (h : psKernelCheckerContextEnterRecDepth context = .ok entered) :
    entered.environment = context.environment := by
  unfold psKernelCheckerContextEnterRecDepth at h
  repeat' first | (solve | simp_all) | split at h

theorem inferCore_const_result
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (context : PsKernelCheckerContext) (state next : PsKernelCheckerState)
    (name : PsKernelName) (levels : List PsKernelLevel) (result : PsKernelExpr)
    (inferOnly : Bool)
    (run : psKernelInferCoreWithFuel fuel whnf defeq context state (.const name levels)
      inferOnly = .ok (result, next)) :
    psKernelExprMapGet (if inferOnly then state.inferOnly else state.checkedInfer)
      (.const name levels) = some result ∨
    ∃ info, psKernelEnvironmentFind context.environment name = some info ∧
      result = psKernelExprInstantiateLevelParams (psKernelConstantInfoType info)
        (psKernelConstantInfoLevelParams info) levels := by
  cases fuel with
  | zero => simp [psKernelInferCoreWithFuel] at run
  | succ fuel =>
      cases hc : psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer) (.const name levels) with
      | some cached =>
          cases he : psKernelCheckerContextEnterRecDepth context with
          | error error =>
              simp [psKernelInferCoreWithFuel, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, hc, he] at run
          | ok entered =>
              simp only [psKernelInferCoreWithFuel, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, ite_true, hc, he,
                Except.ok.injEq, Prod.mk.injEq] at run
              exact Or.inl (congrArg some run.1)
      | none =>
          cases he : psKernelCheckerContextEnterRecDepth context with
          | error error =>
              simp [psKernelInferCoreWithFuel, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, hc, he] at run
          | ok entered =>
              have henv := entered_environment context entered he
              cases hi : psKernelEnvironmentFind entered.environment name with
              | none =>
                  simp [psKernelInferCoreWithFuel, psKernelInferCacheEligible,
                    psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                    psKernelSemanticCacheNodeBudget, hc, he, hi] at run
              | some info =>
                  refine Or.inr ⟨info, ?_, ?_⟩
                  · simpa only [henv] using hi
                  · simp only [psKernelInferCoreWithFuel, psKernelInferCacheEligible,
                      psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                      psKernelSemanticCacheNodeBudget, ite_true, hc, he, hi] at run
                    repeat' first | (solve | simp_all) | split at run

namespace SetModel
open ConLeche ConLeche.SetTheory AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- A modeled stored constant at this universe instance. It is a membership
fact about the actual declaration type, not a kernel-soundness assumption. -/
def ConstantInstance (M : Reading V) (Γ : List AnnotatedExpr)
    (name : PsKernelName) (levels : List PsKernelLevel) (info : PsKernelConstantInfo) : Prop :=
  ∃ A : AnnotatedExpr, A.erase = psKernelConstantInfoType info ∧
    ∀ ρ, Satisfies M Γ ρ →
      M.constants name (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ A

/-- Both inference modes and all safety-check branches are covered. The selected
cache and the stored declaration must already have their respective model facts. -/
theorem const_inference_has_set_model (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (context : PsKernelCheckerContext) (state next : PsKernelCheckerState)
    (name : PsKernelName) (levels : List PsKernelLevel) (result : PsKernelExpr)
    (inferOnly : Bool)
    (hCache : ∀ cached,
      psKernelExprMapGet (if inferOnly then state.inferOnly else state.checkedInfer)
        (.const name levels) = some cached →
      ∃ A : AnnotatedExpr, A.erase = cached ∧ ModelsType M Γ (.const name levels) A)
    (hEnv : ∀ info, psKernelEnvironmentFind context.environment name = some info →
      ConstantInstance M Γ name levels info)
    (run : psKernelInferCoreWithFuel fuel whnf defeq context state (.const name levels)
      inferOnly = .ok (result, next)) :
    ∃ A : AnnotatedExpr, A.erase = result ∧ ModelsType M Γ (.const name levels) A := by
  rcases inferCore_const_result fuel whnf defeq context state next name levels result
    inferOnly run with h | ⟨info, hi, hr⟩
  · exact hCache result h
  · obtain ⟨A, hA, hmem⟩ := hEnv info hi
    refine ⟨instLevels (psKernelConstantInfoLevelParams info) levels A, ?_, ?_⟩
    · rw [erase_instLevels, hA, hr]
    · intro ρ hρ
      rw [interp_instLevels]
      exact hmem ρ hρ

end SetModel
end PsKernelSemantics
