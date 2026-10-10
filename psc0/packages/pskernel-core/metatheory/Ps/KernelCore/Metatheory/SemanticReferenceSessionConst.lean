import Ps.KernelCore.Metatheory.SemanticReferenceSessionSort
import Ps.KernelCore.Metatheory.SemanticEnvironmentModel

/-!
Second actual public checker-session semantic soundness base case.

A successful reference-mode check of a constant uses the REAL PSKernel
session/knot/core implementation and the one modeled environment's stored
declaration. The executed constant branch establishes universe arity; no
extra cached-type or recursive callback assumption is introduced.

The complete recursive checker soundness theorem remains open.
-/
namespace PsKernelSemantics.Reference
open PsKernelSemantics.SetModel ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- Real fully checked reference-session constant inference is set-model
typed under the existing, explicitly proven environment model. -/
theorem referenceSessionCheck_const_models (M : Reading V)
    (Γ : List AnnotatedExpr)
    (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (returnedType : PsKernelExpr)
    (model : EnvironmentModel M session.context.environment)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      fuel session (.const name levels) = .ok (returnedType, next)) :
    ∃ A : AnnotatedExpr,
      A.erase = returnedType ∧
      ModelsType M Γ (.const name levels) A := by
  cases hCore : @psKernelCheckerCheck psKernelReferenceCachePolicy
      fuel session.context session.state (.const name levels) with
  | error err =>
      simp [psKernelSessionCheck, hCore] at run
  | ok pair =>
      rcases pair with ⟨rawType, returnedState⟩
      have checked :
          @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
            (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
              (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
            session.context session.state (.const name levels) false =
              .ok (rawType, returnedState) := by
        simpa only [psKernelCheckerCheck, psKernelCheckWithFuel] using hCore
      obtain ⟨A, hErase, hTyped⟩ :=
        SetModel.referenceConstant_from_environmentModel M Γ fuel
          (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
            (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
          session.context session.state returnedState name levels rawType false
          model checked
      have hPair :
          (rawType, PsKernelCheckerSession.mk session.context returnedState) =
            (returnedType, next) := by
        simpa [psKernelSessionCheck, hCore] using run
      have hType : rawType = returnedType := congrArg Prod.fst hPair
      exact ⟨A, hErase.trans hType, hTyped⟩

end PsKernelSemantics.Reference
