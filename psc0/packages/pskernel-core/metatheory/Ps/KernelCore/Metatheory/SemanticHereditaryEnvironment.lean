import Ps.KernelCore.Metatheory.SemanticReferenceSessionGrade

/-!
A hereditary environment invariant for the ACTUAL reference checker.

EnvironmentModel established exact indexed history and semantic membership for
one fixed annotated type per declaration. It did NOT demand the selected type
annotation's hereditary soundness: an invalid impredicative product annotation
can have membership in a universe without justifying later application/DefEq.

This strengthened model retains membership, annotation validity and function
validity on the SAME stored type witness, uniformly in universe instances.
It is a necessary stronger recursive-proof invariant, not a new axiom or a
claim that the public checker already establishes it for all admissions.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

/-- One single uniform, exact, inherited annotation witness for a constant.
The valuation is the same one used for membership and both validity facts. -/
def HereditarilyStoredConstant (M : Reading V)
    (info : PsKernelConstantInfo) : Prop :=
  ∃ A : AnnotatedExpr,
    A.erase = psKernelConstantInfoType info ∧
      ∀ levels, CorrectUniverseArity info levels →
        ∀ ρ,
          M.constants (psKernelConstantInfoName info)
            (levels.map M.level) ∈ˢ
              interp (M.substLevels (psKernelConstantInfoLevelParams info)
                levels) ρ A ∧
          AnnotationValid
            (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ A ∧
          FunctionValid
            (M.substLevels (psKernelConstantInfoLevelParams info) levels) ρ A

/-- Retain the existing exact indexed/history EnvironmentModel and require
every stored constant to have ONE hereditary witness (not an independently
guessed annotation chosen after each successful checker call). -/
structure HereditaryEnvironmentModel (M : Reading V)
    (env : PsKernelEnvironment) : Prop where
  base : EnvironmentModel M env
  stored : ∀ info, info ∈ env.constants →
    HereditarilyStoredConstant M info

/-- The actual empty public environment possesses the strengthened model
under the SAME explicit model-theory assumption and the original False pin. -/
theorem hereditaryEnvironmentEmpty (M : Reading V)
    (pin : M.constants falseConstantName [] = (empty : V)) :
    HereditaryEnvironmentModel M psKernelEnvironmentEmpty where
  base := environmentEmpty_model M pin
  stored := by
    intro info present
    cases present

/-- The same REAL public successful empty-session constructor is modeled
by a hereditary environment. This is only the empty prefix, not an admitted
prelude or a theorem about arbitrary externally created sessions. -/
theorem publicEmptySession_has_hereditary_model (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability) (session : PsKernelKernelSession)
    (run : psKernelKernelSessionEmpty resources provider = .ok session) :
    ∃ M : Reading V, HereditaryEnvironmentModel M session.environment := by
  rw [PsKernelSemantics.emptyKernelSession_environment
    resources provider session run]
  exact ⟨initialReading V,
    hereditaryEnvironmentEmpty (initialReading V) (initialReading_falsePinned V)⟩

end PsKernelSemantics.SetModel

namespace PsKernelSemantics.Reference
open PsKernelSemantics.SetModel ConLeche ConLeche.SetTheory ConLeche.SetModel
universe u
variable {V : Type u} [SetTheory V]

/-- A successful REAL public reference constant visit at either grade
inherits one fixed valid type reading from the full hereditary environment.
The result type is EXACTLY the production universe-instantiated stored type;
all four hereditary facts (two for the term and two for the type) hold.

The premise is the strengthened environment model, NOT something assumed to
follow automatically from accepting a raw unchecked declaration. -/
theorem referenceSessionGrade_const_checked_reading (M : Reading V)
    (Γ : List AnnotatedExpr) (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (result : PsKernelExpr)
    (model : HereditaryEnvironmentModel M session.context.environment)
    (run : referenceSessionGrade io fuel session (.const name levels) =
      .ok (result, next)) :
    ∃ annotatedType : AnnotatedExpr,
      annotatedType.erase = result ∧
      CheckedReading M Γ (.const name levels) annotatedType := by
  obtain ⟨returnedState, coreRun, _⟩ :=
    referenceSessionGrade_core_trace io fuel session next
      (.const name levels) result run
  obtain ⟨info, found, resultEq⟩ :=
    inferCore_const_result fuel
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
      session.context session.state returnedState name levels result io coreRun
  have arity : CorrectUniverseArity info levels :=
    inferCore_const_success_valid_arity fuel
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
      session.context session.state returnedState name levels result io coreRun
      info found
  obtain ⟨A, erased, allValid⟩ :=
    model.stored info (model.base.lookupInHistory name info found)
  let params := psKernelConstantInfoLevelParams info
  let annotatedType := AnnotatedExpr.instLevels params levels A
  have hErased : annotatedType.erase = result := by
    dsimp [annotatedType, params]
    rw [AnnotatedExpr.erase_instLevels, erased, ← resultEq]
  refine ⟨annotatedType, hErased, ?_⟩
  have nameEq := model.base.lookupName name info found
  have evidence := allValid levels arity
  refine {
    typed := ?_
    termAnnotation := ?_
    typeAnnotation := ?_
    termFunction := ?_
    typeFunction := ?_
  }
  · intro ρ hρ
    have hValid := (evidence ρ).1
    change M.constants name (levels.map M.level) ∈ˢ
      interp M ρ annotatedType
    rw [show interp M ρ annotatedType =
      interp (M.substLevels params levels) ρ A from
        interp_instLevels M A params levels ρ]
    rw [← nameEq]
    exact hValid
  · intro ρ _
    trivial
  · intro ρ _
    exact (annotationValid_instLevels M A params levels ρ).mpr
      (evidence ρ).2.1
  · intro ρ _
    trivial
  · intro ρ _
    exact (functionValid_instLevels M A params levels ρ).mpr
      (evidence ρ).2.2

end PsKernelSemantics.Reference
