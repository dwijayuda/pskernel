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
  unfold psKernelAddTheorem at run
  repeat' first
    | exact run
    | (solve | simp_all)
    | split at run

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
