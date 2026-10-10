import Ps.KernelCore.Metatheory.SemanticReference
import Ps.KernelCore.Checker.Session

/-!
First actual *public checker-session* soundness base case in reference mode.

The subject is the production psKernelSessionCheck path all the way through
Knot/CheckWithFuel/InferCoreWithFuel, not a parallel checker or an imagined
annotation. Sort inference requires no recursive callback soundness premise.

This verifies only the Sort constructor. The joint recursive theorem for
applications, binders, let, projections, inductives, reductions and DefEq
remains open.
-/
namespace PsKernelSemantics.Reference
open PsKernelSemantics.SetModel ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- Exact sort type and state from a successful fully checked, public
PSKernel session call in reference mode. No cache coherence premise. -/
theorem referenceSessionCheck_sort_result
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (level : PsKernelLevel) (type : PsKernelExpr)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      fuel session (.sort level) = .ok (type, next)) :
    type = .sort (.succ level) ∧
      next.context = session.context ∧
      next.state = session.state := by
  cases hCore : @psKernelCheckerCheck psKernelReferenceCachePolicy
      fuel session.context session.state (.sort level) with
  | error err =>
      simp [psKernelSessionCheck, hCore] at run
  | ok pair =>
      rcases pair with ⟨rawType, returnedState⟩
      have checked :
          @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
            (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
              (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
            session.context session.state (.sort level) false =
              .ok (rawType, returnedState) := by
        simpa only [psKernelCheckerCheck, psKernelCheckWithFuel] using hCore
      have hSort := inferCore_sort_result fuel
        (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
        session.context session.state returnedState level rawType false checked
      have hPair :
          (rawType, PsKernelCheckerSession.mk session.context returnedState) =
            (type, next) := by
        simpa [psKernelSessionCheck, hCore] using run
      have hType : rawType = type := congrArg Prod.fst hPair
      have hNext :
          PsKernelCheckerSession.mk session.context returnedState = next :=
        congrArg Prod.snd hPair
      refine ⟨hType.symm.trans hSort.1, ?_, ?_⟩
      · rw [← hNext]
      · rw [← hNext]
        exact hSort.2

/-- The actual fully checked session's accepted Sort constructor has an
exact annotated set-model reading, independent of WHNF/DefEq soundness. -/
theorem referenceSessionCheck_sort_models (M : Reading V)
    (Γ : List AnnotatedExpr)
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (level : PsKernelLevel) (type : PsKernelExpr)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      fuel session (.sort level) = .ok (type, next)) :
    ∃ A : AnnotatedExpr,
      A.erase = type ∧ ModelsType M Γ (.sort level) A := by
  have hType :=
    (referenceSessionCheck_sort_result fuel session next level type run).1
  exact ⟨.sort (.succ level), hType.symm, models_sort M Γ level⟩

end PsKernelSemantics.Reference
