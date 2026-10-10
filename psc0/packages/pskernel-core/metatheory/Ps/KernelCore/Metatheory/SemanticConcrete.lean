import Ps.KernelCore.Metatheory.SemanticContext
import Ps.KernelCore.Metatheory.SemanticErasure
import Ps.KernelCore.Metatheory.SemanticSortInference

/-!
Concrete operation bridges into the relative set model. These results cover
the stated operations only; they do not assume or conclude full-knot soundness.
-/

namespace PsKernelSemantics.SetModel
open ConLeche
open AnnotatedExpr

universe u
variable {V : Type u} [SetTheory V]

/-- Actual uncached core sort inference, now in the universe-set model, at every
parameter valuation. Both inference modes and arbitrary callbacks are covered. -/
theorem sort_inference_has_set_model
    (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (context : PsKernelCheckerContext) (state next : PsKernelCheckerState)
    (level : PsKernelLevel) (result : PsKernelExpr) (inferOnly : Bool)
    (hMiss : psKernelExprMapGet
      (if inferOnly then state.inferOnly else state.checkedInfer) (.sort level) = none)
    (run : psKernelInferCoreWithFuel fuel whnf defeq context state (.sort level) inferOnly =
      .ok (result, next)) :
    ∃ A : AnnotatedExpr, A.erase = result ∧ ModelsType M Γ (.sort level) A := by
  rcases inferCore_sort_result fuel whnf defeq context state next level result inferOnly run
    with h | h
  · rw [hMiss] at h
    cases h
  · exact ⟨.sort (.succ level), h.symm, models_sort M Γ level⟩

/-- The actual zeta substitution always has the reading of the original let.
A complete WHNF proof must additionally justify recursive reduction and caches. -/
theorem zeta_has_set_model
    (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A a b : AnnotatedExpr) (nd : Bool) :
    ∃ r : AnnotatedExpr,
      r.erase = psKernelExprInstantiate1 b.erase a.erase ∧
      ModelsEqual M Γ (.letE n A a b nd) r :=
  ⟨inst a b 0, erase_instantiate1 b a, models_zeta M Γ n A a b nd⟩

/-- Production single substitution preserves a typed reading with the actual
argument premise. The result type is also the production substitution result. -/
theorem substitution_has_typed_set_model
    (M : Reading V) (Γ : List AnnotatedExpr)
    (A a e B : AnnotatedExpr)
    (ha : ModelsType M Γ a A) (he : ModelsType M (A :: Γ) e B) :
    ∃ r T : AnnotatedExpr,
      r.erase = psKernelExprInstantiate1 e.erase a.erase ∧
      T.erase = psKernelExprInstantiate1 B.erase a.erase ∧
      ModelsType M Γ r T :=
  ⟨inst a e 0, inst a B 0, erase_instantiate1 e a,
    erase_instantiate1 B a, models_substitution M Γ A a e B ha he⟩

/-- A typed beta contraction to the production substitution result. This is not
an assertion of unrestricted subject reduction for Lean's algorithmic equality. -/
theorem beta_has_set_model
    (M : Reading V) (Γ : List AnnotatedExpr)
    (n : PsKernelName) (A a b B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel)
    (ha : ModelsType M Γ a A)
    (hb : ModelsType M (A :: Γ) b B)
    (hB : ModelsType M (A :: Γ) B (.sort v)) :
    ∃ r : AnnotatedExpr,
      r.erase = psKernelExprInstantiate1 b.erase a.erase ∧
      ModelsEqual M Γ (.app (.lam n A b bi v) a) r :=
  ⟨inst a b 0, erase_instantiate1 b a, models_beta M Γ n A a b B bi v ha hb hB⟩

end PsKernelSemantics.SetModel
