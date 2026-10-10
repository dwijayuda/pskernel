import Ps.KernelCore.Metatheory.SemanticEnvironmentConsistency
import Ps.KernelCore.Metatheory.EnvironmentIndexCanonical

/-!
A concrete extension step for the actual PSKernel declaration history.

The existing indexed lookup must agree with the authoritative list; the
real index insertion has already been proved to preserve this equality.
The NEW declaration's semantic model is a visible premise, to be supplied
by a later inference/admission-soundness theorem. This does NOT equate raw
successful admission with certified semantic membership.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel
universe u
variable {V : Type u} [SetTheory V]

/-- Successful authoritative lookup selects a member of the actual history. -/
private theorem findConstant_member (query : PsKernelName)
    (values : List PsKernelConstantInfo) (selected : PsKernelConstantInfo)
    (found : psKernelFindConstantInList query values = some selected) :
    selected ∈ values := by
  induction values with
  | nil =>
      simp [psKernelFindConstantInList] at found
  | cons first rest ih =>
      by_cases hSame :
          psKernelNameEq (psKernelConstantInfoName first) query = true
      · have eq : first = selected := by
          simpa [psKernelFindConstantInList, hSame] using found
        simp [eq]
      · have foundTail : psKernelFindConstantInList query rest =
            some selected := by
          simpa [psKernelFindConstantInList, hSame] using found
        exact List.mem_cons_of_mem first (ih foundTail)

/-- A successful authoritative lookup is named by precisely the query. -/
private theorem findConstant_name (query : PsKernelName)
    (values : List PsKernelConstantInfo) (selected : PsKernelConstantInfo)
    (found : psKernelFindConstantInList query values = some selected) :
    psKernelConstantInfoName selected = query := by
  induction values with
  | nil =>
      simp [psKernelFindConstantInList] at found
  | cons first rest ih =>
      by_cases hSame :
          psKernelNameEq (psKernelConstantInfoName first) query = true
      · have eq : first = selected := by
          simpa [psKernelFindConstantInList, hSame] using found
        rw [← eq]
        exact psKernelNameEq_sound_of_string_law
          psKernelStringEq_sound_lean435 _ _ hSame
      · have foundTail : psKernelFindConstantInList query rest =
            some selected := by
          simpa [psKernelFindConstantInList, hSame] using found
        exact ih foundTail

/-- The real index insertion still agrees with *every* lookup in the new
authoritative history. This reuses the native index-refinement theorem,
instead of postulating that a hash index preserves semantic access. -/
theorem addUnchecked_lookupCanonical (M : Reading V)
    (env : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (model : EnvironmentModel M env) (query : PsKernelName) :
    psKernelEnvironmentFind (psKernelEnvironmentAddUnchecked env info) query =
      psKernelFindConstantInList query (info :: env.constants) := by
  exact psKernelEnvironmentIndexInsert_refines_authoritative
    env.index env.constants info (fun q => model.lookupCanonical q) query

/-- The actual insertion updates the environment while retaining the single
modeled declaration history, provided this new declaration already has its
semantic reading at every valid universe instance.

The proof does not assume all checker callbacks sound, or infer the model
for the new constant from mere successful raw admission. -/
theorem addUnchecked_model (M : Reading V)
    (env : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (model : EnvironmentModel M env)
    (newStored : StoredConstantModeled M info) :
    EnvironmentModel M (psKernelEnvironmentAddUnchecked env info) := by
  have canonical : ∀ query,
      psKernelEnvironmentFind (psKernelEnvironmentAddUnchecked env info) query =
        psKernelFindConstantInList query (info :: env.constants) :=
    fun query => addUnchecked_lookupCanonical M env info model query
  refine {
    lookupCanonical := canonical
    lookupInHistory := ?_
    lookupName := ?_
    stored := ?_
    falsePinned := model.falsePinned
  }
  · intro query selected found
    have actual : psKernelFindConstantInList query (info :: env.constants) =
        some selected := (canonical query).symm.trans found
    exact findConstant_member query (info :: env.constants) selected actual
  · intro query selected found
    have actual : psKernelFindConstantInList query (info :: env.constants) =
        some selected := (canonical query).symm.trans found
    exact findConstant_name query (info :: env.constants) selected actual
  · intro selected present
    rcases List.mem_cons.mp present with head | tail
    · subst selected
      exact newStored
    · exact model.stored selected tail

/-- What the executable add-operation actually returns, if it succeeds.
No statement here upgrades its raw validity checks to semantic validity. -/
theorem add_success_is_unchecked (env next : PsKernelEnvironment)
    (info : PsKernelConstantInfo)
    (run : psKernelEnvironmentAdd env info = .ok next) :
    next = psKernelEnvironmentAddUnchecked env info := by
  cases hExists : psKernelEnvironmentContains env
      (psKernelConstantInfoName info) with
  | true =>
      simp [psKernelEnvironmentAdd, hExists] at run
  | false =>
      cases hDuplicates : psKernelNameHasDuplicates
          (psKernelConstantInfoLevelParams info) with
      | true =>
          simp [psKernelEnvironmentAdd, hExists, hDuplicates] at run
      | false =>
          have heq : psKernelEnvironmentAddUnchecked env info = next := by
            simpa [psKernelEnvironmentAdd, hExists, hDuplicates] using run
          exact heq.symm

/-- A real successful checked add preserves the proposed full-history model
once the NEW constant's modeled typing is established independently. -/
theorem add_success_preserves_model (M : Reading V)
    (env next : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (model : EnvironmentModel M env)
    (newStored : StoredConstantModeled M info)
    (run : psKernelEnvironmentAdd env info = .ok next) :
    EnvironmentModel M next := by
  rw [add_success_is_unchecked env next info run]
  exact addUnchecked_model M env info model newStored

end PsKernelSemantics.SetModel
