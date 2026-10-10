import Ps.KernelCore.Core.AnnotatedLocalContext
import Ps.KernelCore.Core.AnnotatedInference
import Ps.KernelCore.Metatheory.SemanticFunctionValidity

/-!
The typing and hereditary-validity part of the recursive checker invariant.
Both readings are fixed data: this predicate never chooses a new reading of
an erased term. Annotation provenance, scope, environment admission and the
recursive checker theorem remain separate obligations.

The local-context model describes the exact declaration returned by the shared
lookup operation. It is an induction invariant for stored declarations, not an
assumption that the checker or its callbacks are sound.
-/
namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetTheory ConLeche.SetModel AnnotatedExpr
universe u
variable {V : Type u} [SetTheory V]

structure CheckedReading (M : Reading V) (Γ : List AnnotatedExpr)
    (term type : AnnotatedExpr) : Prop where
  typed : ModelsType M Γ term type
  termAnnotation : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ term
  typeAnnotation : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ type
  termFunction : ∀ ρ, Satisfies M Γ ρ → FunctionValid M ρ term
  typeFunction : ∀ ρ, Satisfies M Γ ρ → FunctionValid M ρ type

def CheckedInferenceResult (M : Reading V) (Γ : List AnnotatedExpr)
    (result : AnnotatedInferenceResult) : Prop :=
  CheckedReading M Γ result.expr result.type

/-- The queried name is explicit because production lookup selects the first
matching declaration. Let values also retain their own fixed reading and their
equality with the free variable used by reduction. -/
structure LocalDeclModel (M : Reading V) (Γ : List AnnotatedExpr)
    (name : PsKernelName) (decl : AnnotatedLocalDecl) : Prop where
  member : ∀ ρ, Satisfies M Γ ρ →
    M.freeVars name ∈ˢ interp M ρ (psKernelLocalDeclType decl)
  typeAnnotation : ∀ ρ, Satisfies M Γ ρ →
    AnnotationValid M ρ (psKernelLocalDeclType decl)
  typeFunction : ∀ ρ, Satisfies M Γ ρ →
    FunctionValid M ρ (psKernelLocalDeclType decl)
  letValue : ∀ value, psKernelLocalDeclValue decl = some value →
    CheckedReading M Γ value (psKernelLocalDeclType decl) ∧
      ModelsEqual M Γ (.fvar name) value

def ModelsLocalContext (M : Reading V) (Γ : List AnnotatedExpr)
    (context : AnnotatedLocalContext) : Prop :=
  ∀ name decl, psKernelLocalContextFind context name = some decl →
    LocalDeclModel M Γ name decl

theorem LocalDeclModel.checkedReading (M : Reading V) (Γ : List AnnotatedExpr)
    (name : PsKernelName) (decl : AnnotatedLocalDecl)
    (model : LocalDeclModel M Γ name decl) :
    CheckedReading M Γ (.fvar name) (psKernelLocalDeclType decl) where
  typed := model.member
  termAnnotation := fun _ _ => True.intro
  typeAnnotation := model.typeAnnotation
  termFunction := fun _ _ => True.intro
  typeFunction := model.typeFunction

theorem modelsLocalContext_empty (M : Reading V) (Γ : List AnnotatedExpr) :
    ModelsLocalContext M Γ annotatedLocalContextEmpty := by
  intro name decl found
  simp [annotatedLocalContextEmpty, psKernelLocalContextEmptyOf,
    psKernelLocalContextFind, psKernelLocalContextFindIn] at found

end PsKernelSemantics.SetModel
