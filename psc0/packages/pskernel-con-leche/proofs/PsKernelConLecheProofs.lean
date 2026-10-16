import PsKernelConLeche.Check
import ConLeche.MainTheorem

namespace PsKernelConLeche

/-- Wrapper refinement: every adapter accept is an accept of the exact
upstream verified fold on the prepared declarations. The input policy and
resource guards can only remove accepts. No claim about a PSC0 exporter. -/
theorem accepted_by_upstream (chunks : List ByteArray) (limits : Limits)
    (env : ConLeche.Env) (h : checkInput chunks limits = .ok env) :
    ∃ prepared, prepareChunks chunks limits = .ok prepared ∧
      ConLeche.Cached.checkDecls .verified ConLeche.natOpPinSets
        prepared.declarations = .ok env := by
  cases hp : prepareChunks chunks limits with
  | error e => simp [checkInput, hp] at h
  | ok prepared =>
    cases hk : ConLeche.Cached.checkDecls .verified ConLeche.natOpPinSets prepared.declarations with
    | error e => simp [checkInput, hp, hk] at h
    | ok checkedEnv =>
      have he : checkedEnv = env := by simpa [checkInput, hp, hk] using h
      subst env
      exact ⟨prepared, hp, hk⟩

/-- Conditional on upstream's SetTheory interface, every checked input has a
model. This inherits upstream's metatheoretic assumptions (including choice);
it does not expand the permitted axioms IN THE INPUT program. -/
theorem checkedInput_model_exists (V : Type w) [ConLeche.SetTheory V]
    (chunks : List ByteArray) (limits : Limits) (checked : CheckedInput chunks limits) :
    Nonempty (ConLeche.Model V checked.environment) := by
  obtain ⟨prepared, _, h⟩ := accepted_by_upstream chunks limits
    checked.environment checked.accepted
  exact ConLeche.model_exists V ConLeche.natOpPinSets prepared.declarations checked.environment h

#print axioms accepted_by_upstream
#print axioms checkedInput_model_exists

end PsKernelConLeche
