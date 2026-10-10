import Ps.KernelCore.Metatheory.SemanticClassifier
import Ps.KernelCore.Checker.Inference.Core

/-!
A first concrete checked-inference case against the new semantic relation.
Both inference modes and the actual cache-hit path are covered. The cache
premise is semantic membership for the selected cache, not the legacy judgment.
No callback soundness assumption is needed for a sort node.
-/

namespace PsKernelSemantics

universe u
variable {Value : Type u} {D : ProofDomain Value}

/-- Exact result sources for sort inference, including arbitrary checker states. -/
theorem inferCore_sort_result
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (context : PsKernelCheckerContext) (state next : PsKernelCheckerState)
    (level : PsKernelLevel) (result : PsKernelExpr) (inferOnly : Bool)
    (run : psKernelInferCoreWithFuel fuel whnf defeq context state (.sort level) inferOnly =
      .ok (result, next)) :
    psKernelExprMapGet (if inferOnly then state.inferOnly else state.checkedInfer)
        (.sort level) = some result ∨
      result = .sort (.succ level) := by
  cases fuel with
  | zero => simp [psKernelInferCoreWithFuel] at run
  | succ fuel =>
      cases hc : psKernelExprMapGet
          (if inferOnly then state.inferOnly else state.checkedInfer) (.sort level) with
      | none =>
          cases he : psKernelCheckerContextEnterRecDepth context with
          | error error =>
              simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet, psKernelCachedCachePolicy, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, hc, he] at run
          | ok entered =>
              simp only [psKernelInferCoreWithFuel, psKernelSemanticCacheGet, psKernelCachedCachePolicy, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, ite_true, hc, he,
                Except.ok.injEq, Prod.mk.injEq] at run
              exact Or.inr run.1.symm
      | some cached =>
          cases he : psKernelCheckerContextEnterRecDepth context with
          | error error =>
              simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet, psKernelCachedCachePolicy, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, hc, he] at run
          | ok entered =>
              simp only [psKernelInferCoreWithFuel, psKernelSemanticCacheGet, psKernelCachedCachePolicy, psKernelInferCacheEligible,
                psKernelSemanticCacheEligible, psKernelSemanticCacheRemaining,
                psKernelSemanticCacheNodeBudget, ite_true, hc, he,
                Except.ok.injEq, Prod.mk.injEq] at run
              exact Or.inl (congrArg some run.1)

theorem inferCore_sort_sound (I : Interpretation D)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (context : PsKernelCheckerContext) (state next : PsKernelCheckerState)
    (level : PsKernelLevel) (result : PsKernelExpr) (inferOnly : Bool)
    (hSort : I.HasType (.sort level) (.sort (.succ level)))
    (hCache : ∀ cached,
      psKernelExprMapGet (if inferOnly then state.inferOnly else state.checkedInfer)
        (.sort level) = some cached → I.HasType (.sort level) cached)
    (run : psKernelInferCoreWithFuel fuel whnf defeq context state (.sort level) inferOnly =
      .ok (result, next)) :
    I.HasType (.sort level) result := by
  rcases inferCore_sort_result fuel whnf defeq context state next level result inferOnly run
    with h | h
  · exact hCache result h
  · cases h
    exact hSort

/-- Concrete model instance: an uncached sort success has its advertised type. -/
theorem sort_inference_has_concrete_model
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (context : PsKernelCheckerContext) (state next : PsKernelCheckerState)
    (level : PsKernelLevel) (result : PsKernelExpr) (inferOnly : Bool)
    (hMiss : psKernelExprMapGet
      (if inferOnly then state.inferOnly else state.checkedInfer) (.sort level) = none)
    (run : psKernelInferCoreWithFuel fuel whnf defeq context state (.sort level) inferOnly =
      .ok (result, next)) :
    PropositionDomain.witness.HasType (.sort level) result := by
  apply inferCore_sort_sound PropositionDomain.witness fuel whnf defeq context state next
    level result inferOnly (PropositionDomain.witness_sort_hasType level) ?_ run
  intro cached h
  rw [hMiss] at h
  cases h

end PsKernelSemantics

#print axioms PsKernelSemantics.inferCore_sort_result
#print axioms PsKernelSemantics.inferCore_sort_sound
#print axioms PsKernelSemantics.sort_inference_has_concrete_model
