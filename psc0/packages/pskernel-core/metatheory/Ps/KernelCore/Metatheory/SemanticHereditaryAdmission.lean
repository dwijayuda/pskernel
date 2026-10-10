import Ps.KernelCore.Metatheory.SemanticHereditaryExtension
import Ps.KernelCore.Metatheory.SemanticClosedTheoremValue

/-!
Hereditary admission of ONE actual fresh declaration.

This simultaneously preserves (1) exact indexed/history lookup, (2) the
uniform semantic membership of a stored constant, and (3) the same selected
type annotation's hereditary proposition/function validity under every
universe instantiation. These are necessary for future uses of a declaration
in checked application, proof irrelevance and definitional equality.

The new declaration's semantic value must still be verified; for the
monomorphic safe-theorem subcase, it is constructed from the denotation of
the exact submitted CLOSED proof, conditional on a concrete CheckedReading
for that same proof/declared type. The future joint checker theorem, not an
untrusted caller or an alternate checker, must discharge that last premise.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- One fixed annotation witnesses membership AND hereditary validity
for the new constant's value under all legal universe instances. -/
def FreshHereditaryValueModeled (M : Reading V)
    (info : PsKernelConstantInfo) (chosen : List Nat → V) : Prop :=
  ∃ A : AnnotatedExpr,
    A.erase = psKernelConstantInfoType info ∧
    RawAvoidsConstant (psKernelConstantInfoName info)
      (psKernelConstantInfoType info) ∧
    ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ,
        chosen (levels.map M.level) ∈ˢ
          interp (M.substLevels (psKernelConstantInfoLevelParams info)
            levels) ρ A ∧
        AnnotationValid
          (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ A ∧
        FunctionValid
          (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ A

/-- The new declaration's *same* annotated type receives all hereditary
model properties in the extended reading. The model is constructed from
the new value's independently validated pre-extension interpretation. -/
theorem freshHereditaryValue_extends (M : Reading V)
    (info : PsKernelConstantInfo) (chosen : List Nat → V)
    (valid : FreshHereditaryValueModeled M info chosen) :
    HereditarilyStoredConstant
      (M.extendConstant (psKernelConstantInfoName info) chosen) info := by
  obtain ⟨A, erased, rawSelfFree, assignment⟩ := valid
  let fresh := psKernelConstantInfoName info
  have avoids : AvoidsConstant fresh A :=
    (rawAvoids_erase_iff fresh A).mp
      (by simpa only [erased] using rawSelfFree)
  refine ⟨A, erased, ?_⟩
  intro levels arity ρ
  obtain ⟨member, annotation, functionOK⟩ := assignment levels arity ρ
  let before := M.substLevels (psKernelConstantInfoLevelParams info) levels
  have hAnnotation : AnnotationValid
      ((M.extendConstant fresh chosen).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A := by
    rw [substLevels_extendConstant]
    exact (annotationValid_extendConstant before fresh chosen A avoids ρ).mpr
      annotation
  have hFunction : FunctionValid
      ((M.extendConstant fresh chosen).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A := by
    rw [substLevels_extendConstant]
    exact (functionValid_extendConstant before fresh chosen A avoids ρ).mpr
      functionOK
  refine ⟨?_, hAnnotation, hFunction⟩
  have hType : interp
      ((M.extendConstant fresh chosen).substLevels
        (psKernelConstantInfoLevelParams info) levels) ρ A =
      interp before ρ A := by
    rw [substLevels_extendConstant]
    exact interp_extendConstant before fresh chosen A avoids ρ
  have hLevels :
      levels.map (M.extendConstant fresh chosen).level =
        levels.map M.level := by
    simp only [Reading.extendConstant_level]
  rw [hLevels, hType]
  simpa [Reading.extendConstant, fresh] using member

/-- The ONE executed guarded add transaction preserves the new stronger
hereditary environment invariant by extending the model of each old
declaration and inserting a new valid same-annotation witness. -/
theorem successfulAdd_hereditary_model
    (M : Reading V) (env next : PsKernelEnvironment)
    (info : PsKernelConstantInfo) (chosen : List Nat → V)
    (old : HereditaryEnvironmentModel M env)
    (noForward : ∀ prev, prev ∈ env.constants →
      RawAvoidsConstant (psKernelConstantInfoName info)
        (psKernelConstantInfoType prev))
    (preservesFalse : psKernelConstantInfoName info ≠ falseConstantName ∨
      chosen [] = (empty : V))
    (validated : FreshHereditaryValueModeled M info chosen)
    (accepted : psKernelEnvironmentAdd env info = .ok next) :
    HereditaryEnvironmentModel
      (M.extendConstant (psKernelConstantInfoName info) chosen) next := by
  let fresh := psKernelConstantInfoName info
  have names := successfulAdd_oldNamesFresh M env next info old.base accepted
  have prefix : HereditaryEnvironmentModel
      (M.extendConstant fresh chosen) env :=
    hereditaryEnvironment_extendConstant M env fresh chosen old
      noForward names preservesFalse
  obtain ⟨A, erased, selfFree, proofValue⟩ := validated
  have baseNext : EnvironmentModel (M.extendConstant fresh chosen) next :=
    successfulAdd_model_preservingFalse M env next info chosen A
      old.base noForward preservesFalse erased selfFree
      (fun levels arity ρ => (proofValue levels arity ρ).1)
      accepted
  refine {base := baseNext, stored := ?_}
  intro selected present
  have inserted : next = psKernelEnvironmentAddUnchecked env info :=
    add_success_is_unchecked env next info accepted
  rw [inserted] at present
  rcases List.mem_cons.mp present with heq | previous
  · subst selected
    exact freshHereditaryValue_extends M info chosen validated
  · exact prefix.stored selected previous

/-- A closed monomorphic CHECKED proof automatically supplies both of the
stronger hereditary reading obligations for its exact declared type. -/
theorem checkedClosedProof_hereditary_assignment (M : Reading V)
    (info : PsKernelConstantInfo) (proof type : AnnotatedExpr)
    (noParams : psKernelConstantInfoLevelParams info = [])
    (closed : proof.Scoped 0)
    (checked : CheckedReading M [] proof type) :
    ∀ levels, CorrectUniverseArity info levels →
      ∀ ρ,
        closedProofValue M proof (levels.map M.level) ∈ˢ
          interp (M.substLevels (psKernelConstantInfoLevelParams info)
            levels) ρ type ∧
        AnnotationValid
          (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ type ∧
        FunctionValid
          (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ type := by
  intro levels arity ρ
  have hMember := checkedClosedProof_monomorphic_assignment M info
    proof type noParams closed checked levels arity ρ
  have hNil : levels = [] := by
    cases levels with
    | nil => rfl
    | cons l ls =>
        simp [CorrectUniverseArity, noParams,
          psKernelNameListLength, psKernelLevelListLength] at arity
  subst levels
  refine ⟨hMember, ?_, ?_⟩
  · simpa [noParams, Reading.substLevels_nil] using
      checked.typeAnnotation ρ True.intro
  · simpa [noParams, Reading.substLevels_nil] using
      checked.typeFunction ρ True.intro

/-- The ACTUAL safe monomorphic theorem-add operation extends the strong
hereditary model when its very own submitted proof is semantically checked
against its very own declared type. The missing step for full kernel
consistency is exactly to derive that concrete CheckedReading from its
successful recursive infer/WHNF/DefEq execution without extra assumptions. -/
theorem referenceAddTheorem_monomorphic_hereditary_model
    (M : Reading V) (fuel : Nat)
    (env next : PsKernelEnvironment) (value : PsKernelTheoremInfo)
    (maxDepth maxNatSize : Nat)
    (old : HereditaryEnvironmentModel M env)
    (noParams : value.base.levelParams = [])
    (proof type : AnnotatedExpr)
    (proofSource : proof.erase = value.value)
    (typeSource : type.erase = value.base.type)
    (closed : proof.Scoped 0)
    (checked : CheckedReading M [] proof type)
    (oldNoForward : ∀ prev, prev ∈ env.constants →
      RawAvoidsConstant (psKernelConstantInfoName (.thmInfo value))
        (psKernelConstantInfoType prev))
    (notReserved : psKernelConstantInfoName (.thmInfo value) ≠
      falseConstantName)
    (selfFree : RawAvoidsConstant
      (psKernelConstantInfoName (.thmInfo value))
      (psKernelConstantInfoType (.thmInfo value)))
    (accepted : @psKernelAddTheorem psKernelReferenceCachePolicy fuel
      env value maxDepth maxNatSize = .ok next) :
    HereditaryEnvironmentModel
      (M.extendConstant (psKernelConstantInfoName (.thmInfo value))
        (closedProofValue M proof)) next := by
  have inserted := referenceAddTheorem_returns_insert
    fuel env next value maxDepth maxNatSize accepted
  have hParams : psKernelConstantInfoLevelParams (.thmInfo value) = [] :=
    noParams
  have hType : type.erase = psKernelConstantInfoType (.thmInfo value) :=
    typeSource
  have validated : FreshHereditaryValueModeled
      M (.thmInfo value) (closedProofValue M proof) :=
    ⟨type, hType, selfFree,
      checkedClosedProof_hereditary_assignment M (.thmInfo value)
        proof type hParams closed checked⟩
  exact successfulAdd_hereditary_model M env next (.thmInfo value)
    (closedProofValue M proof) old oldNoForward
    (Or.inl notReserved) validated inserted

end PsKernelSemantics.SetModel
