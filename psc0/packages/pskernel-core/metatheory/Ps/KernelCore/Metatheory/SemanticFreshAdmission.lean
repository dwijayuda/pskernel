import Ps.KernelCore.Metatheory.SemanticReadingExtension

/-!
Fresh declaration admission: a concrete syntax/semantic bridge.

The previous model-extension theorem requires a caller to provide separate
fresh-name facts and fixed annotated witnesses that avoid the new name.
Here a successful ACTUAL environment insertion discharges the name fact;
a syntactic no-forward-reference condition on the actual stored raw types
discharges the annotation condition.  The new constant is interpreted by
an explicitly given mathematical value with independently justified type
membership in the preceding Reading.

This is a model-construction step, NOT an assertion that the checker has
already established that membership for every accepted theorem/definition.
In particular it does not assert unconditional consistency for user axioms.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- A direct predicate on the same raw syntax stored in the authoritative
environment. This says exactly that the prospective new constant name is
absent, including in dependent domains, bodies and let values. -/
def RawAvoidsConstant (fresh : PsKernelName) : PsKernelExpr → Prop
  | .const name _ => name ≠ fresh
  | .app f a => RawAvoidsConstant fresh f ∧ RawAvoidsConstant fresh a
  | .lam _ A body _ | .forallE _ A body _ =>
      RawAvoidsConstant fresh A ∧ RawAvoidsConstant fresh body
  | .letE _ A value body _ =>
      RawAvoidsConstant fresh A ∧ RawAvoidsConstant fresh value ∧
        RawAvoidsConstant fresh body
  | .mdata _ e | .proj _ _ e => RawAvoidsConstant fresh e
  | _ => True

/-- The raw syntax guard and the existing annotated guard agree exactly.
The annotation witness can therefore be the SAME stored type selected by
the checker, rather than an unrelated reinterpretation of raw expressions. -/
theorem rawAvoids_erase_iff (fresh : PsKernelName) (e : AnnotatedExpr) :
    RawAvoidsConstant fresh e.erase ↔ AvoidsConstant fresh e := by
  induction e with
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha => exact and_congr ihf iha
  | lam n A body bi v ihA ihBody
  | forallE n A body bi v ihA ihBody =>
      exact and_congr ihA ihBody
  | letE n A value body nd ihA ihValue ihBody =>
      exact and_congr ihA (and_congr ihValue ihBody)
  | mdata md e ih | proj n i e ih => exact ih

/-- A modeled declaration whose actual raw type does not mention the
prospective new constant already supplies the precise fixed witness needed
to transport its interpretation. -/
theorem storedConstantAvoids_of_raw (M : Reading V)
    (info : PsKernelConstantInfo) (fresh : PsKernelName)
    (modeled : StoredConstantModeled M info)
    (noForward : RawAvoidsConstant fresh (psKernelConstantInfoType info)) :
    StoredConstantAvoids M info fresh := by
  obtain ⟨A, erased, membership⟩ := modeled
  refine ⟨A, erased, ?_, membership⟩
  apply (rawAvoids_erase_iff fresh A).mp
  simpa only [erased] using noForward

/-- The authoritative list cannot contain a declaration with the queried
name if its own first-match lookup returns none. This is independent of the
accelerating hash index. -/
theorem findConstant_none_namesFresh (fresh : PsKernelName)
    (values : List PsKernelConstantInfo)
    (missing : psKernelFindConstantInList fresh values = none) :
    ∀ info, info ∈ values → psKernelConstantInfoName info ≠ fresh := by
  induction values with
  | nil =>
      intro info present
      cases present
  | cons head tail ih =>
      have hNoMatch :
          psKernelNameEq (psKernelConstantInfoName head) fresh = false := by
        cases heq : psKernelNameEq (psKernelConstantInfoName head) fresh with
        | false => rfl
        | true =>
            simp [psKernelFindConstantInList, heq] at missing
      have hHeadName : psKernelConstantInfoName head ≠ fresh := by
        intro eq
        have hRefl : psKernelNameEq (psKernelConstantInfoName head)
            (psKernelConstantInfoName head) = true :=
          psKernelNameEq_refl_of_string_law
            (fun s => by simp [psKernelStringEq]) _
        have hContradiction : psKernelNameEq
            (psKernelConstantInfoName head) fresh = true := by
          rw [← eq]
          exact hRefl
        rw [hContradiction] at hNoMatch
        cases hNoMatch
      have missingTail : psKernelFindConstantInList fresh tail = none := by
        simpa [psKernelFindConstantInList, hNoMatch] using missing
      intro info present
      rcases List.mem_cons.mp present with eq | inTail
      · subst info
        exact hHeadName
      · exact ih missingTail info inTail

/-- Successful execution of the genuine duplicate-name guard, plus the
existing exact indexed/history model, proves that NO old stored declaration
has the new name. This was previously a caller-provided assumption. -/
theorem successfulAdd_oldNamesFresh (M : Reading V)
    (env next : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (model : EnvironmentModel M env)
    (run : psKernelEnvironmentAdd env info = .ok next) :
    ∀ old, old ∈ env.constants →
      psKernelConstantInfoName old ≠ psKernelConstantInfoName info := by
  have absent :
      psKernelEnvironmentContains env (psKernelConstantInfoName info) = false := by
    cases h : psKernelEnvironmentContains env (psKernelConstantInfoName info) with
    | false => rfl
    | true => simp [psKernelEnvironmentAdd, h] at run
  have notFound :
      psKernelEnvironmentFind env (psKernelConstantInfoName info) = none := by
    cases h : psKernelEnvironmentFind env (psKernelConstantInfoName info) with
    | none => rfl
    | some selected =>
        simp [psKernelEnvironmentContains, h] at absent
  have missing : psKernelFindConstantInList
      (psKernelConstantInfoName info) env.constants = none := by
    calc
      psKernelFindConstantInList (psKernelConstantInfoName info) env.constants =
          psKernelEnvironmentFind env (psKernelConstantInfoName info) :=
        (model.lookupCanonical (psKernelConstantInfoName info)).symm
      _ = none := notFound
  exact findConstant_none_namesFresh
    (psKernelConstantInfoName info) env.constants missing

/-- Construct the NEW declaration's semantic type interpretation from a
selected mathematical assignment evaluated in the PRE-ADMISSION reading.
Its actual stored type must avoid self-reference. The result is a modeled
constant in the explicitly extended reading, not an arbitrary assumption
that the previous global constant table happened to interpret a fresh name. -/
theorem newConstant_from_assignment (M : Reading V)
    (info : PsKernelConstantInfo) (value : List Nat → V)
    (A : AnnotatedExpr)
    (erased : A.erase = psKernelConstantInfoType info)
    (selfFree : RawAvoidsConstant (psKernelConstantInfoName info)
      (psKernelConstantInfoType info))
    (assignment : ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, value (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info)
          levels) ρ A) :
    StoredConstantModeled
      (M.extendConstant (psKernelConstantInfoName info) value) info := by
  let fresh := psKernelConstantInfoName info
  have avoids : AvoidsConstant fresh A := by
    exact (rawAvoids_erase_iff fresh A).mp (by simpa only [erased] using selfFree)
  refine ⟨A, erased, ?_⟩
  intro levels arity ρ
  rw [substLevels_extendConstant]
  rw [interp_extendConstant
    (M.substLevels (psKernelConstantInfoLevelParams info) levels)
    fresh value A avoids ρ]
  have hLevels :
      levels.map (M.extendConstant fresh value).level =
        levels.map M.level := by
    simp only [Reading.extendConstant_level]
  rw [hLevels]
  have hConstant :
      (M.extendConstant fresh value).constants fresh (levels.map M.level) =
        value (levels.map M.level) := by
    simp [Reading.extendConstant]
  rw [hConstant]
  exact assignment levels arity ρ

/-- Actual guarded environment insertion admits a CONSTRUCTED extended
interpretation, preserving indexed history, fixed old annotated readings,
and the reserved empty False interpretation.

The two remaining non-administrative obligations are precisely (1) that
the prior stored types have no forward reference to this name and (2) that
the chosen new interpretation inhabits its genuinely checked type at all
valid universe instances. These must be established from executed checking,
not introduced as unchecked axioms. -/
theorem successfulAdd_model_with_fresh_reading (M : Reading V)
    (env next : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (value : List Nat → V) (A : AnnotatedExpr)
    (model : EnvironmentModel M env)
    (priorTypes : ∀ old, old ∈ env.constants →
      RawAvoidsConstant (psKernelConstantInfoName info)
        (psKernelConstantInfoType old))
    (reserved : psKernelConstantInfoName info ≠ falseConstantName)
    (erased : A.erase = psKernelConstantInfoType info)
    (selfFree : RawAvoidsConstant (psKernelConstantInfoName info)
      (psKernelConstantInfoType info))
    (assignment : ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, value (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info)
          levels) ρ A)
    (run : psKernelEnvironmentAdd env info = .ok next) :
    EnvironmentModel (M.extendConstant (psKernelConstantInfoName info) value)
      next := by
  have names := successfulAdd_oldNamesFresh M env next info model run
  have readings : ∀ old, old ∈ env.constants →
      StoredConstantAvoids M old (psKernelConstantInfoName info) := by
    intro old present
    exact storedConstantAvoids_of_raw M old (psKernelConstantInfoName info)
      (model.stored old present) (priorTypes old present)
  have newStored :=
    newConstant_from_assignment M info value A erased selfFree assignment
  rw [add_success_is_unchecked env next info run]
  exact addUnchecked_model_with_new_reading M env info value model
    readings names reserved newStored

/-- The newly constructed model gives an exact relative no-literal-False
corollary for successful guarded insertion, not an unconditional statement
about arbitrary user axioms or all derived proof terms. -/
theorem successfulAdd_no_stored_literalFalse (M : Reading V)
    (env next : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (value : List Nat → V) (A : AnnotatedExpr)
    (model : EnvironmentModel M env)
    (priorTypes : ∀ old, old ∈ env.constants →
      RawAvoidsConstant (psKernelConstantInfoName info)
        (psKernelConstantInfoType old))
    (reserved : psKernelConstantInfoName info ≠ falseConstantName)
    (erased : A.erase = psKernelConstantInfoType info)
    (selfFree : RawAvoidsConstant (psKernelConstantInfoName info)
      (psKernelConstantInfoType info))
    (assignment : ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, value (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info)
          levels) ρ A)
    (run : psKernelEnvironmentAdd env info = .ok next)
    (noParams : psKernelConstantInfoLevelParams info = [])
    (declaredFalse : psKernelConstantInfoType info =
      .const falseConstantName []) : False := by
  have modelNext :=
    successfulAdd_model_with_fresh_reading M env next info value A model
      priorTypes reserved erased selfFree assignment run
  have inserted : info ∈ next.constants := by
    rw [add_success_is_unchecked env next info run]
    exact List.mem_cons_self
  exact no_stored_constant_of_literalFalse
    (M.extendConstant (psKernelConstantInfoName info) value)
    next modelNext info inserted noParams declaredFalse

/-- Existing modeled declarations continue to have their exact fixed
interpretation after extending the constant table, even when the new name is
the reserved False name, PROVIDED its zero-universe interpretation is empty.

The alternative is mathematically necessary for eventually modeling the
actual empty False inductive. A new declaration's checking and the absence
of illegal constructors remain separate proof obligations. -/
theorem environmentModel_extendConstant_preservingFalse
    (M : Reading V) (env : PsKernelEnvironment)
    (fresh : PsKernelName) (value : List Nat → V)
    (old : EnvironmentModel M env)
    (oldReadings : ∀ info, info ∈ env.constants →
      StoredConstantAvoids M info fresh)
    (oldNames : ∀ info, info ∈ env.constants →
      psKernelConstantInfoName info ≠ fresh)
    (preservesFalse : fresh ≠ falseConstantName ∨
      value [] = (empty : V)) :
    EnvironmentModel (M.extendConstant fresh value) env := by
  refine {
    lookupCanonical := old.lookupCanonical
    lookupInHistory := old.lookupInHistory
    lookupName := old.lookupName
    stored := ?_
    falsePinned := ?_
  }
  · intro info present
    exact storedConstant_extendConstant M info fresh value
      (oldNames info present) (oldReadings info present)
  · by_cases matches : falseConstantName = fresh
    · rcases preservesFalse with different | assignedEmpty
      · exact False.elim (different matches.symm)
      · simpa [Reading.extendConstant, matches] using assignedEmpty
    · simpa [Reading.extendConstant, matches] using old.falsePinned

/-- Model a successful ACTUAL declaration insertion with the generalized
False-as-empty pin. For an ordinary fresh name this reduces to the previous
fresh-reading theorem; for the literal False name it requires the selected
new value at zero universe instances to be the empty set. -/
theorem successfulAdd_model_preservingFalse (M : Reading V)
    (env next : PsKernelEnvironment) (info : PsKernelConstantInfo)
    (value : List Nat → V) (A : AnnotatedExpr)
    (model : EnvironmentModel M env)
    (priorTypes : ∀ old, old ∈ env.constants →
      RawAvoidsConstant (psKernelConstantInfoName info)
        (psKernelConstantInfoType old))
    (preservesFalse : psKernelConstantInfoName info ≠ falseConstantName ∨
      value [] = (empty : V))
    (erased : A.erase = psKernelConstantInfoType info)
    (selfFree : RawAvoidsConstant (psKernelConstantInfoName info)
      (psKernelConstantInfoType info))
    (assignment : ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ, value (levels.map M.level) ∈ˢ
        interp (M.substLevels (psKernelConstantInfoLevelParams info)
          levels) ρ A)
    (run : psKernelEnvironmentAdd env info = .ok next) :
    EnvironmentModel (M.extendConstant (psKernelConstantInfoName info) value)
      next := by
  have names := successfulAdd_oldNamesFresh M env next info model run
  have readings : ∀ old, old ∈ env.constants →
      StoredConstantAvoids M old (psKernelConstantInfoName info) := by
    intro old present
    exact storedConstantAvoids_of_raw M old (psKernelConstantInfoName info)
      (model.stored old present) (priorTypes old present)
  have prefixModel : EnvironmentModel
      (M.extendConstant (psKernelConstantInfoName info) value) env :=
    environmentModel_extendConstant_preservingFalse M env
      (psKernelConstantInfoName info) value model
      readings names preservesFalse
  have newStored :=
    newConstant_from_assignment M info value A erased selfFree assignment
  rw [add_success_is_unchecked env next info run]
  exact addUnchecked_model
    (M.extendConstant (psKernelConstantInfoName info) value)
    env info prefixModel newStored


end PsKernelSemantics.SetModel
