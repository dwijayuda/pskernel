import Ps.KernelCore.API.Reference
import Ps.KernelCore.Metatheory.SemanticConstantInference

/-!
Concrete reference-mode proofs have no semantic-cache coherence hypotheses.
Full recursive-checker and declaration-admission soundness remain open.
-/
namespace PsKernelSemantics.Reference

theorem infer_publication_noop (s : PsKernelCheckerState) (io : Bool)
    (e A : PsKernelExpr) :
    @psKernelCacheInferResult psKernelReferenceCachePolicy s io e A = s := by
  cases io <;> cases s <;>
    simp [psKernelCacheInferResult, psKernelSemanticCacheInsert,
      psKernelReferenceCachePolicy, psKernelCheckerStateWithInferOnly,
      psKernelCheckerStateWithCheckedInfer]

theorem equality_publication_noop (s : PsKernelCheckerState)
    (a b : PsKernelExpr) (answer : Bool) :
    @psKernelDefEqFinish psKernelReferenceCachePolicy s a b answer = (answer, s) := by
  cases answer <;> cases s <;>
    simp [psKernelDefEqFinish, psKernelSemanticCacheInsertPair,
      psKernelReferenceCachePolicy, psKernelCheckerStateWithSuccess]

theorem unfold_uncached (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (e : PsKernelExpr) :
    @psKernelDefEqUnfold psKernelReferenceCachePolicy c s e =
      (psKernelUnfoldDefinition c e, s) := by
  cases h : psKernelUnfoldDefinition c e <;> cases s <;>
    simp [psKernelDefEqUnfold, psKernelSemanticCacheGet,
      psKernelSemanticCacheInsert, psKernelReferenceCachePolicy,
      psKernelCheckerStateWithUnfold, h]

theorem inferCore_sort_result
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (u : PsKernelLevel) (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.sort u) io = .ok (result, next)) :
    result = .sort (.succ u) ∧ next = s := by
  cases fuel with
  | zero => simp [psKernelInferCoreWithFuel] at run
  | succ fuel =>
      cases he : psKernelCheckerContextEnterRecDepth c with
      | error error =>
          simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
            psKernelReferenceCachePolicy, he] at run
      | ok entered =>
          simp only [psKernelInferCoreWithFuel, psKernelReferenceCacheGet_miss,
            ite_self, he, infer_publication_noop,
            Except.ok.injEq, Prod.mk.injEq] at run
          exact ⟨run.1.symm, run.2.symm⟩

private theorem entered_environment (c entered : PsKernelCheckerContext)
    (h : psKernelCheckerContextEnterRecDepth c = .ok entered) :
    entered.environment = c.environment := by
  by_cases hz : Nat.beq c.maxRecDepth 0 = true
  · simp only [psKernelCheckerContextEnterRecDepth, hz, ite_true, Except.ok.injEq] at h
    exact (congrArg PsKernelCheckerContext.environment h).symm
  · by_cases hl : psKernelNatGt (Nat.succ c.recDepth)
        (Nat.mul c.maxRecDepth psKernelRecDepthFactor) = true
    · simp only [psKernelCheckerContextEnterRecDepth, hz, hl,
        Bool.false_eq_true, ite_false, ite_true] at h
      cases h
    · simp only [psKernelCheckerContextEnterRecDepth, hz, hl,
        Bool.false_eq_true, ite_false, Except.ok.injEq] at h
      exact (congrArg PsKernelCheckerContext.environment h).symm

theorem inferCore_const_result
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (levels : List PsKernelLevel) (result : PsKernelExpr)
    (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.const name levels) io = .ok (result, next)) :
    ∃ info, psKernelEnvironmentFind c.environment name = some info ∧
      result = psKernelExprInstantiateLevelParams (psKernelConstantInfoType info)
        (psKernelConstantInfoLevelParams info) levels := by
  cases fuel with
  | zero => simp [psKernelInferCoreWithFuel] at run
  | succ fuel =>
      cases he : psKernelCheckerContextEnterRecDepth c with
      | error error =>
          simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
            psKernelReferenceCachePolicy, he] at run
      | ok entered =>
          have henv := entered_environment c entered he
          cases hi : psKernelEnvironmentFind entered.environment name with
          | none =>
              simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
                psKernelReferenceCachePolicy, he, hi] at run
          | some info =>
              refine ⟨info, ?_, ?_⟩
              · simpa only [henv] using hi
              · simp only [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
                  psKernelReferenceCachePolicy, Bool.false_eq_true, ite_false,
                  ite_self, he, hi] at run
                repeat' first | (solve | simp_all) | split at run


/-- The actual reference constant-inference success branch has passed its
universe-arity guard. Unlike a hypothesis supplied by a model caller, this
is derived from the production checker run in both inference grades. -/
theorem inferCore_const_success_valid_arity
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.const name levels) io = .ok (result, next)) :
    ∀ info, psKernelEnvironmentFind c.environment name = some info →
      psKernelNameListLength (psKernelConstantInfoLevelParams info) =
        psKernelLevelListLength levels := by
  cases fuel with
  | zero =>
      simp [psKernelInferCoreWithFuel] at run
  | succ remaining =>
      cases he : psKernelCheckerContextEnterRecDepth c with
      | error error =>
          simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
            psKernelReferenceCachePolicy, he] at run
      | ok entered =>
          have henv := entered_environment c entered he
          cases hi : psKernelEnvironmentFind entered.environment name with
          | none =>
              simp [psKernelInferCoreWithFuel, psKernelSemanticCacheGet,
                psKernelReferenceCachePolicy, he, hi] at run
          | some selected =>
              have arity :
                  psKernelNameListLength
                    (psKernelConstantInfoLevelParams selected) =
                  psKernelLevelListLength levels := by
                cases hc : Nat.beq
                    (psKernelNameListLength
                      (psKernelConstantInfoLevelParams selected))
                    (psKernelLevelListLength levels) with
                | true =>
                    simpa using hc
                | false =>
                    have hne : psKernelNameListLength
                        (psKernelConstantInfoLevelParams selected) ≠
                        psKernelLevelListLength levels := by
                      intro eq
                      rw [eq] at hc
                      simp at hc
                    simp [psKernelInferCoreWithFuel,
                      psKernelReferenceCacheGet_miss,
                      psKernelSemanticCacheGet, he, hi, hne] at run
              intro info found
              have actual :
                  psKernelEnvironmentFind c.environment name = some selected := by
                simpa only [henv] using hi
              have same : info = selected :=
                Option.some.inj (found.symm.trans actual)
              subst info
              exact arity

open ConLeche SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

theorem sort_inference_has_set_model (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (u : PsKernelLevel) (result : PsKernelExpr) (io : Bool)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.sort u) io = .ok (result, next)) :
    ∃ A : AnnotatedExpr, A.erase = result ∧ ModelsType M Γ (.sort u) A := by
  have hr := (inferCore_sort_result fuel whnf defeq c s next u result io run).1
  exact ⟨.sort (.succ u), hr.symm, models_sort M Γ u⟩

theorem const_inference_has_set_model (M : Reading V) (Γ : List AnnotatedExpr)
    (fuel : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (name : PsKernelName) (levels : List PsKernelLevel) (result : PsKernelExpr)
    (io : Bool)
    (hEnv : ∀ info, psKernelEnvironmentFind c.environment name = some info →
      ConstantInstance M Γ name levels info)
    (run : @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
      fuel whnf defeq c s (.const name levels) io = .ok (result, next)) :
    ∃ A : AnnotatedExpr, A.erase = result ∧ ModelsType M Γ (.const name levels) A := by
  obtain ⟨info, hi, hr⟩ :=
    inferCore_const_result fuel whnf defeq c s next name levels result io run
  obtain ⟨A, hA, hmem⟩ := hEnv info hi
  refine ⟨instLevels (psKernelConstantInfoLevelParams info) levels A, ?_, ?_⟩
  · rw [erase_instLevels, hA, hr]
  · intro ρ hρ
    rw [interp_instLevels]
    exact hmem ρ hρ

end PsKernelSemantics.Reference
