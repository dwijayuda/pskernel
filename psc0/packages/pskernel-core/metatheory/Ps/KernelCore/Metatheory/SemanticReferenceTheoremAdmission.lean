import Ps.KernelCore.Metatheory.SemanticEnvironmentAdmission
import Ps.KernelCore.Admission.Declaration.Admission

/-!
The concrete safe theorem-admission transaction boundary.

PSKernel's actual psKernelAddTheorem checks a header, proposition sort, source
variable and level discipline, the proof term, and definitional equality
before inserting a theorem. These lemmas do NOT skip or replace those checks.

The semantic membership of the newly admitted theorem still must follow
from a joint recursive inference/WHNF/DefEq soundness proof. Merely reaching
the final insertion cannot be used to assert such membership.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- A successful execution of the actual reference theorem-admission
function must come from its guarded final environment insertion. The
checker-facing result is not independently constructed here. -/
theorem referenceAddTheorem_returns_insert
    (fuel : Nat) (env next : PsKernelEnvironment)
    (value : PsKernelTheoremInfo) (maxDepth maxNatSize : Nat)
    (run : @psKernelAddTheorem psKernelReferenceCachePolicy
      fuel env value maxDepth maxNatSize = .ok next) :
    psKernelEnvironmentAdd env (.thmInfo value) = .ok next := by
  cases hHeader : @psKernelCheckConstantBaseWithSession
      psKernelReferenceCachePolicy fuel
      (psKernelMkCheckerSession env value.base.levelParams
        PsKernelDefinitionSafety.safe maxDepth maxNatSize) value.base with
  | error err =>
      simp [psKernelAddTheorem, hHeader] at run
  | ok afterHeader =>
      cases hProp : @psKernelSessionIsProp psKernelReferenceCachePolicy
          fuel afterHeader value.base.type with
      | error err =>
          simp [psKernelAddTheorem, hHeader, hProp] at run
      | ok propResult =>
          by_cases hIsProp : Prod.fst propResult = true
          · cases hGuard : psKernelCheckNoMVarNoFVar value.value with
            | error err =>
                simp [psKernelAddTheorem, hHeader, hProp, hIsProp,
                  hGuard] at run
            | ok valid =>
                cases hLevels : psKernelCheckLevelParams
                    value.value value.base.levelParams with
                | error err =>
                    simp [psKernelAddTheorem, hHeader, hProp, hIsProp,
                      hGuard, hLevels] at run
                | ok levels =>
                    cases hProof : @psKernelSessionCheck psKernelReferenceCachePolicy
                        fuel (Prod.snd propResult) value.value with
                    | error err =>
                        simp [psKernelAddTheorem, hHeader, hProp, hIsProp,
                          hGuard, hLevels, hProof] at run
                    | ok valueType =>
                        cases hDefEq : @psKernelSessionIsDefEq
                            psKernelReferenceCachePolicy fuel
                            (Prod.snd valueType) (Prod.fst valueType)
                            value.base.type with
                        | error err =>
                            simp [psKernelAddTheorem, hHeader, hProp,
                              hIsProp, hGuard, hLevels, hProof,
                              hDefEq] at run
                        | ok equal =>
                            by_cases hEqual : Prod.fst equal = true
                            · simpa [psKernelAddTheorem, hHeader, hProp,
                                hIsProp, hGuard, hLevels, hProof,
                                hDefEq, hEqual] using run
                            · simp [psKernelAddTheorem, hHeader, hProp,
                                hIsProp, hGuard, hLevels, hProof,
                                hDefEq, hEqual] at run
          · simp [psKernelAddTheorem, hHeader, hProp, hIsProp] at run

/-- The actual reference theorem-admission transaction preserves indexed
declaration history WHEN its accepted proof's type already has the exact
required modeled interpretation. Supplying that interpretation is the open
checker soundness theorem, not a new assumption about runtime correctness. -/
theorem referenceAddTheorem_preserves_model
    (M : Reading V) (fuel : Nat)
    (env next : PsKernelEnvironment) (value : PsKernelTheoremInfo)
    (maxDepth maxNatSize : Nat)
    (model : EnvironmentModel M env)
    (modeledProof : StoredConstantModeled M (.thmInfo value))
    (run : @psKernelAddTheorem psKernelReferenceCachePolicy
      fuel env value maxDepth maxNatSize = .ok next) :
    EnvironmentModel M next := by
  exact add_success_preserves_model M env next (.thmInfo value) model
    modeledProof
    (referenceAddTheorem_returns_insert fuel env next value maxDepth maxNatSize run)

end PsKernelSemantics.SetModel
