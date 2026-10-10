import Ps.KernelCore.Admission.Declaration.Validation
import Ps.KernelCore.Metatheory.SemanticReferenceBinderContext

/-!
The *executed* public declaration guard and initial checker-session boundary.

The checker starts with no local declarations and a zero fresh-name counter.
Admission rejects expressions containing free variables or metavariables
before invoking the checker. Relating that concrete guard to the semantic
name bound avoids postulating freshness on externally supplied declarations.

This proves only the input and initial-frame obligations. It does not prove
that inference, WHNF, DefEq or admission preserves the frame, that arbitrary
annotated readings are sound, or that the public checker is consistent.
-/

namespace PsKernelSemantics
open AnnotatedExpr SetModel

private theorem false_if_or (a b : Bool)
    (h : (if a then true else b) = false) :
    a = false ∧ b = false := by
  cases a <;> cases b <;> simp_all

/-- Free-variable absence in the executable expression is sufficient for the
semantic frame's numeric-name bound, at any allocator counter. The binder
sort annotations are not trusted or chosen in this argument. -/
theorem noFVar_namesBelow (e : AnnotatedExpr) (limit : Nat)
    (h : psKernelExprHasFVar e.erase = false) :
    NamesBelow limit e := by
  induction e with
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | fvar _ =>
      simp [AnnotatedExpr.erase, psKernelExprHasFVar] at h
  | app f a ihf iha =>
      have h' : (if psKernelExprHasFVar f.erase then true
          else psKernelExprHasFVar a.erase) = false := by
        simpa only [AnnotatedExpr.erase, psKernelExprHasFVar] using h
      obtain ⟨hf, ha⟩ :=
        false_if_or (psKernelExprHasFVar f.erase) (psKernelExprHasFVar a.erase) h'
      exact ⟨ihf hf, iha ha⟩
  | lam n A body bi rangeSort ihA ihBody
  | forallE n A body bi rangeSort ihA ihBody =>
      have h' : (if psKernelExprHasFVar A.erase then true
          else psKernelExprHasFVar body.erase) = false := by
        simpa only [AnnotatedExpr.erase, psKernelExprHasFVar] using h
      obtain ⟨hA, hBody⟩ :=
        false_if_or (psKernelExprHasFVar A.erase)
          (psKernelExprHasFVar body.erase) h'
      exact ⟨ihA hA, ihBody hBody⟩
  | letE n A value body nd ihA ihValue ihBody =>
      have h' : (if psKernelExprHasFVar A.erase then true
          else if psKernelExprHasFVar value.erase then true
          else psKernelExprHasFVar body.erase) = false := by
        simpa only [AnnotatedExpr.erase, psKernelExprHasFVar] using h
      obtain ⟨hA, hRest⟩ :=
        false_if_or (psKernelExprHasFVar A.erase)
          (if psKernelExprHasFVar value.erase then true
          else psKernelExprHasFVar body.erase) h'
      obtain ⟨hValue, hBody⟩ :=
        false_if_or (psKernelExprHasFVar value.erase)
          (psKernelExprHasFVar body.erase) hRest
      exact ⟨ihA hA, ihValue hValue, ihBody hBody⟩
  | mdata md e ih | proj n i e ih =>
      apply ih
      simpa only [AnnotatedExpr.erase, psKernelExprHasFVar] using h

/-- The admission implementation's own no-mvar/no-fvar check, when it
succeeds, entails the semantic numeric-name bound. No new runtime guard or
stronger accepted-input restriction is introduced. -/
theorem admittedInput_namesBelow_zero (e : AnnotatedExpr)
    (h : psKernelCheckNoMVarNoFVar e.erase = .ok ()) :
    NamesBelow 0 e := by
  have hf : psKernelExprHasFVar e.erase = false := by
    cases hm : psKernelExprHasMVar e.erase <;>
      cases hv : psKernelExprHasFVar e.erase <;>
      simp_all [psKernelCheckNoMVarNoFVar]
  exact noFVar_namesBelow e 0 hf

/-- The concrete public-session constructor has the exact empty local
storage and allocator origin required by the earlier binder-frame lemmas.
This says nothing about user-supplied continuation sessions. -/
theorem publicSession_initial_frame (env : PsKernelEnvironment)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) :
    let session := psKernelMkCheckerSession env params safety maxRecDepth maxNatSize
    session.context.localContext = eraseLocalContext annotatedLocalContextEmpty ∧
    session.state.nextFresh = 0 ∧
    LocalFrame session.state.nextFresh annotatedLocalContextEmpty ∧
    BoundFrame session.state.nextFresh [] := by
  refine ⟨rfl, rfl, ?_, ?_⟩
  · change LocalFrame 0 annotatedLocalContextEmpty
    exact localFrame_empty 0
  · change BoundFrame 0 []
    exact boundFrame_empty 0

/-- When a closed annotated source passes the *actual* admission guard,
it is eligible for the initial public checker frame. This does not assert
the existence of an annotation witness for every raw source term. -/
theorem admittedInput_initial_frame (env : PsKernelEnvironment)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) (e : AnnotatedExpr)
    (acceptedGuard : psKernelCheckNoMVarNoFVar e.erase = .ok ())
    (scope : e.Scoped 0) :
    let session := psKernelMkCheckerSession env params safety maxRecDepth maxNatSize
    NamesBelow session.state.nextFresh e ∧ e.Scoped 0 := by
  exact ⟨admittedInput_namesBelow_zero e acceptedGuard, scope⟩


/-- A submitted lambda with no free-variable/metavariable syntax enters its
first *actual* native binder opening under the advanced syntactic frame.
The displayed annotation is fixed input data, not inferred from a model.
This is an input/binder bridge, not full lambda inference soundness. -/
theorem admittedLambda_firstBinderFrame (n : PsKernelName)
    (A body : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (rangeSort : PsKernelLevel)
    (guard : psKernelCheckNoMVarNoFVar
      (AnnotatedExpr.lam n A body bi rangeSort).erase = .ok ())
    (domainScope : A.Scoped 0) (bodyScope : body.Scoped 1) :
    let s := psKernelCheckerStateEmpty
    let name := (psKernelCheckerStateFreshName s n).1
    let next := (psKernelCheckerStateFreshName s n).2
    let child := psKernelLocalContextAddLocal annotatedLocalContextEmpty name n A bi
    ∃ opened : AnnotatedExpr,
      LocalFrame next.nextFresh child ∧
      opened.erase = psKernelExprInstantiate1 body.erase (.fvar name) ∧
      opened.Scoped 0 ∧ NamesBelow next.nextFresh opened := by
  have bound := admittedInput_namesBelow_zero (.lam n A body bi rangeSort) guard
  change NamesBelow 0 A ∧ NamesBelow 0 body at bound
  exact Reference.binderChild_opened_frame psKernelCheckerStateEmpty
    annotatedLocalContextEmpty n A body bi (localFrame_empty 0)
    bound.1 domainScope bound.2 bodyScope

/-- A submitted dependent product obeys the same binder/capture invariant.
Its universe level is still an untrusted source annotation until justified
by the actual inference/sort visits. -/
theorem admittedForall_firstBinderFrame (n : PsKernelName)
    (A body : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (rangeSort : PsKernelLevel)
    (guard : psKernelCheckNoMVarNoFVar
      (AnnotatedExpr.forallE n A body bi rangeSort).erase = .ok ())
    (domainScope : A.Scoped 0) (bodyScope : body.Scoped 1) :
    let s := psKernelCheckerStateEmpty
    let name := (psKernelCheckerStateFreshName s n).1
    let next := (psKernelCheckerStateFreshName s n).2
    let child := psKernelLocalContextAddLocal annotatedLocalContextEmpty name n A bi
    ∃ opened : AnnotatedExpr,
      LocalFrame next.nextFresh child ∧
      opened.erase = psKernelExprInstantiate1 body.erase (.fvar name) ∧
      opened.Scoped 0 ∧ NamesBelow next.nextFresh opened := by
  have bound := admittedInput_namesBelow_zero (.forallE n A body bi rangeSort) guard
  change NamesBelow 0 A ∧ NamesBelow 0 body at bound
  exact Reference.binderChild_opened_frame psKernelCheckerStateEmpty
    annotatedLocalContextEmpty n A body bi (localFrame_empty 0)
    bound.1 domainScope bound.2 bodyScope

/-- Even a let declaration with a stored value preserves the actual local
frame after its first name allocation, provided both accepted stored readings
have no loose bound indices. Checking the value's *type* is separate. -/
theorem admittedLet_firstLocalFrame (n : PsKernelName)
    (A value body : AnnotatedExpr) (nd : Bool)
    (guard : psKernelCheckNoMVarNoFVar
      (AnnotatedExpr.letE n A value body nd).erase = .ok ())
    (domainScope : A.Scoped 0) (valueScope : value.Scoped 0) :
    let s := psKernelCheckerStateEmpty
    let name := (psKernelCheckerStateFreshName s n).1
    let next := (psKernelCheckerStateFreshName s n).2
    LocalFrame next.nextFresh
      (psKernelLocalContextAddLet annotatedLocalContextEmpty name n A value) := by
  have bound := admittedInput_namesBelow_zero (.letE n A value body nd) guard
  change NamesBelow 0 A ∧ NamesBelow 0 value ∧ NamesBelow 0 body at bound
  exact localFrame_addLet 0 annotatedLocalContextEmpty n n A value
    (localFrame_empty 0) bound.1 domainScope bound.2.1 valueScope


/-- All public kernel sessions—including the trusted low-level construction
boundary—create a checker with the same empty local frame and allocator
origin. This is independent of whether an arbitrary supplied environment is
well modeled; the latter is a separate admission/soundness obligation. -/
theorem publicKernelSession_checker_initial_frame
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety) :
    let checker := psKernelKernelSessionChecker session levelParams safety
    checker.context.localContext = eraseLocalContext annotatedLocalContextEmpty ∧
    checker.state.nextFresh = 0 ∧
    LocalFrame checker.state.nextFresh annotatedLocalContextEmpty ∧
    BoundFrame checker.state.nextFresh [] := by
  simpa only [psKernelKernelSessionChecker] using
    (publicSession_initial_frame (psKernelKernelSessionEnvironment session)
      levelParams safety session.resources.maxRecDepth session.resources.maxNatSize)

end PsKernelSemantics
