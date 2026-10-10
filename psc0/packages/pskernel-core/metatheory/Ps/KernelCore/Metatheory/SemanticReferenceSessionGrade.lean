import Ps.KernelCore.Metatheory.SemanticReferenceSessionFVar
import Ps.KernelCore.Metatheory.SemanticReferenceSessionConst
import Ps.KernelCore.Metatheory.SemanticReferenceApplication
import Ps.KernelCore.Metatheory.SemanticReferenceLambda

/-!
A shared, proof-only execution interface for both PUBLIC reference-session
inference grades. It does not introduce another checker or change runtime rules:
the grade is dispatched to the actual Session -> Knot -> Inference/Core path.

The trace retains the exact input, result, state and shared callbacks. It
lets the sort, selected-local and modeled-constant base cases use the SAME
execution-to-semantics lemmas for both grades. Recursive inference, WHNF and
DefEq soundness, state/frame invariants inside binders, and full consistency
remain separate open obligations.
-/

namespace PsKernelSemantics.Reference
open PsKernelSemantics.SetModel ConLeche ConLeche.SetTheory
universe u
variable {V : Type u} [SetTheory V]

/-- A proof-level selection between the two existing public APIs.
This function has no role in the production acceptance decision. -/
def referenceSessionGrade
    (inferOnly : Bool) (fuel : Nat)
    (session : PsKernelCheckerSession) (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerSession) :=
  if inferOnly then
    @psKernelSessionInfer psKernelReferenceCachePolicy fuel session expr
  else
    @psKernelSessionCheck psKernelReferenceCachePolicy fuel session expr

/-- Every successful public grade comes from the one actual recursive
reference inference core and returns EXACTLY its selected state. Neither
callback soundness nor a type annotation is assumed here. -/
theorem referenceSessionGrade_core_trace
    (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession)
    (expr result : PsKernelExpr)
    (run : referenceSessionGrade io fuel session expr = .ok (result, next)) :
    ∃ returnedState : PsKernelCheckerState,
      @psKernelInferCoreWithFuel psKernelReferenceCachePolicy fuel
        (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
        session.context session.state expr io = .ok (result, returnedState) ∧
      next = PsKernelCheckerSession.mk session.context returnedState := by
  cases io with
  | false =>
      cases hChecker : @psKernelCheckerCheck psKernelReferenceCachePolicy
          fuel session.context session.state expr with
      | error err =>
          simp [referenceSessionGrade, psKernelSessionCheck, hChecker] at run
      | ok pair =>
          rcases pair with ⟨rawType, returnedState⟩
          have hPair :
              (rawType, PsKernelCheckerSession.mk session.context returnedState) =
                (result, next) := by
            simpa [referenceSessionGrade, psKernelSessionCheck, hChecker] using run
          have hType : rawType = result := congrArg Prod.fst hPair
          have hNext :
              PsKernelCheckerSession.mk session.context returnedState = next :=
            congrArg Prod.snd hPair
          refine ⟨returnedState, ?_, hNext.symm⟩
          simpa only [psKernelCheckerCheck, psKernelCheckWithFuel, hType] using hChecker
  | true =>
      cases hChecker : @psKernelCheckerInfer psKernelReferenceCachePolicy
          fuel session.context session.state expr with
      | error err =>
          simp [referenceSessionGrade, psKernelSessionInfer, hChecker] at run
      | ok pair =>
          rcases pair with ⟨rawType, returnedState⟩
          have hPair :
              (rawType, PsKernelCheckerSession.mk session.context returnedState) =
                (result, next) := by
            simpa [referenceSessionGrade, psKernelSessionInfer, hChecker] using run
          have hType : rawType = result := congrArg Prod.fst hPair
          have hNext :
              PsKernelCheckerSession.mk session.context returnedState = next :=
            congrArg Prod.snd hPair
          refine ⟨returnedState, ?_, hNext.symm⟩
          simpa only [psKernelCheckerInfer, psKernelInferWithRecursorFuel,
            psKernelInferWithFuel, hType] using hChecker

/-- The public wrapper never publishes a changed checker context, even when
the recursive core changes its returned state. This is a session boundary
invariant, not yet an invariant of the recursive child contexts. -/
theorem referenceSessionGrade_context_fixed
    (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession) (expr result : PsKernelExpr)
    (run : referenceSessionGrade io fuel session expr = .ok (result, next)) :
    next.context = session.context := by
  obtain ⟨s, _, hNext⟩ :=
    referenceSessionGrade_core_trace io fuel session next expr result run
  rw [hNext]

/-- Both grades agree on the exact Sort type and on the unmodified session
when successful; a cache/WHNF/DefEq soundness premise is unnecessary. -/
theorem referenceSessionGrade_sort_result
    (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession)
    (level : PsKernelLevel) (result : PsKernelExpr)
    (run : referenceSessionGrade io fuel session (.sort level) =
      .ok (result, next)) :
    result = .sort (.succ level) ∧ next = session := by
  obtain ⟨returnedState, coreRun, hNext⟩ :=
    referenceSessionGrade_core_trace io fuel session next (.sort level) result run
  obtain ⟨hType, hState⟩ := inferCore_sort_result fuel
    (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
    (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
    session.context session.state returnedState level result io coreRun
  refine ⟨hType, ?_⟩
  calc
    next = PsKernelCheckerSession.mk session.context returnedState := hNext
    _ = PsKernelCheckerSession.mk session.context session.state :=
      congrArg (PsKernelCheckerSession.mk session.context) hState
    _ = session := by cases session; rfl

/-- The actual accepted Sort carries its canonical annotated model type,
in either public grade. -/
theorem referenceSessionGrade_sort_models (M : Reading V)
    (Γ : List AnnotatedExpr) (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession)
    (level : PsKernelLevel) (result : PsKernelExpr)
    (run : referenceSessionGrade io fuel session (.sort level) =
      .ok (result, next)) :
    ∃ A : AnnotatedExpr,
      A.erase = result ∧ ModelsType M Γ (.sort level) A := by
  have hType := (referenceSessionGrade_sort_result
    io fuel session next level result run).1
  exact ⟨.sort (.succ level), hType.symm, models_sort M Γ level⟩

/-- Both public grades select the actual first local declaration, preserve
its exact raw type and publish no state mutation in the fvar case. -/
theorem referenceSessionGrade_fvar_selected
    (io : Bool) (fuel : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (result : PsKernelExpr)
    (run : referenceSessionGrade io fuel session (.fvar name) =
      .ok (result, next)) :
    ∃ decl : PsKernelLocalDecl,
      psKernelLocalContextFind session.context.localContext name = some decl ∧
      result = psKernelLocalDeclType decl ∧ next = session := by
  obtain ⟨returnedState, coreRun, hNext⟩ :=
    referenceSessionGrade_core_trace io fuel session next (.fvar name) result run
  obtain ⟨decl, found, hType, hState⟩ := inferCore_fvar_result fuel
    (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
    (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
    session.context session.state returnedState name result io coreRun
  refine ⟨decl, found, hType, ?_⟩
  calc
    next = PsKernelCheckerSession.mk session.context returnedState := hNext
    _ = PsKernelCheckerSession.mk session.context session.state :=
      congrArg (PsKernelCheckerSession.mk session.context) hState
    _ = session := by cases session; rfl

/-- Both public grades preserve the SAME first stored annotated local type,
including hereditary checked-reading validity; no raw-type re-annotation. -/
theorem referenceSessionGrade_fvar_checked_reading
    (M : Reading V) (Γ : List AnnotatedExpr)
    (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession)
    (name : PsKernelName) (result : PsKernelExpr)
    (locals : AnnotatedLocalContext)
    (erasure : eraseLocalContext locals = session.context.localContext)
    (localModel : ModelsLocalContext M Γ locals)
    (run : referenceSessionGrade io fuel session (.fvar name) =
      .ok (result, next)) :
    ∃ decl : AnnotatedLocalDecl,
      psKernelLocalContextFind locals name = some decl ∧
      (psKernelLocalDeclType decl).erase = result ∧
      CheckedReading M Γ (.fvar name) (psKernelLocalDeclType decl) ∧
      next = session := by
  obtain ⟨returnedState, coreRun, hNext⟩ :=
    referenceSessionGrade_core_trace io fuel session next (.fvar name) result run
  obtain ⟨decl, found, typeEq, checked, hState⟩ :=
    fvar_inference_checked_reading M Γ fuel
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
      session.context session.state returnedState name result io
      locals erasure localModel coreRun
  refine ⟨decl, found, typeEq, checked, ?_⟩
  calc
    next = PsKernelCheckerSession.mk session.context returnedState := hNext
    _ = PsKernelCheckerSession.mk session.context session.state :=
      congrArg (PsKernelCheckerSession.mk session.context) hState
    _ = session := by cases session; rfl

/-- No initially empty public checker session accepts a free variable in
EITHER inference grade; the result follows from actual local lookup. -/
theorem referenceInitialSessionGrade_fvar_cannot_succeed
    (io : Bool) (fuel : Nat) (env : PsKernelEnvironment)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (maxRecDepth maxNatSize : Nat) (name : PsKernelName)
    (result : PsKernelExpr) (next : PsKernelCheckerSession) :
    referenceSessionGrade io fuel
      (psKernelMkCheckerSession env params safety maxRecDepth maxNatSize)
      (.fvar name) ≠ .ok (result, next) := by
  intro run
  obtain ⟨decl, found, _, _⟩ :=
    referenceSessionGrade_fvar_selected io fuel
      (psKernelMkCheckerSession env params safety maxRecDepth maxNatSize)
      next name result run
  simp [psKernelMkCheckerSession, psKernelCheckerContextEmpty,
    psKernelLocalContextEmpty, psKernelLocalContextEmptyOf,
    psKernelLocalContextFind, psKernelLocalContextFindIn] at found

/-- Both successful public constant grades use the actual stored declaration
and its independently established environment-model interpretation. -/
theorem referenceSessionGrade_const_models (M : Reading V)
    (Γ : List AnnotatedExpr) (io : Bool) (fuel : Nat)
    (session next : PsKernelCheckerSession)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (result : PsKernelExpr)
    (model : EnvironmentModel M session.context.environment)
    (run : referenceSessionGrade io fuel session (.const name levels) =
      .ok (result, next)) :
    ∃ A : AnnotatedExpr,
      A.erase = result ∧ ModelsType M Γ (.const name levels) A := by
  obtain ⟨returnedState, coreRun, _⟩ :=
    referenceSessionGrade_core_trace io fuel session next
      (.const name levels) result run
  exact SetModel.referenceConstant_from_environmentModel M Γ fuel
    (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy fuel
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel))
    (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy fuel)
    session.context session.state returnedState name levels result io model coreRun


/-- Lift the executed dependent-product trace into EITHER public session grade.
The selected domain/body inference and sort checks retain their actual
states; no annotation or semantic soundness has been postulated. -/
theorem referenceSessionGrade_forall_trace
    (io : Bool) (remaining : Nat)
    (session next : PsKernelCheckerSession)
    (name : PsKernelName) (domain body : PsKernelExpr)
    (bi : PsKernelBinderInfo) (result : PsKernelExpr)
    (run : referenceSessionGrade io (remaining + 1) session
      (.forallE name domain body bi) = .ok (result, next)) :
    ∃ returnedState : PsKernelCheckerState,
      Nonempty (ForallTrace remaining
        (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
        session.context session.state name domain body bi io result returnedState) ∧
      next = PsKernelCheckerSession.mk session.context returnedState := by
  obtain ⟨returnedState, coreRun, nextEq⟩ :=
    referenceSessionGrade_core_trace io (remaining + 1)
      session next (.forallE name domain body bi) result run
  exact ⟨returnedState,
    inferCore_forall_trace remaining
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
      session.context session.state returnedState
      name domain body bi result io coreRun,
    nextEq⟩

/-- A successful FULLY CHECKED public application selects the exact recursive
function inference, exposed product view, argument inference, and one of the
executed equality comparison branches. Inference-only application is not
silently awarded the checked argument-comparison trace. -/
theorem referenceSessionCheck_app_trace
    (remaining : Nat) (session next : PsKernelCheckerSession)
    (fn arg result : PsKernelExpr)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      (remaining + 1) session (.app fn arg) = .ok (result, next)) :
    ∃ returnedState : PsKernelCheckerState,
      Nonempty (ApplicationTrace remaining
        (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
        session.context session.state fn arg result returnedState) ∧
      next = PsKernelCheckerSession.mk session.context returnedState := by
  have graded : referenceSessionGrade false (remaining + 1) session
      (.app fn arg) = .ok (result, next) := by
    simpa [referenceSessionGrade] using run
  obtain ⟨returnedState, coreRun, nextEq⟩ :=
    referenceSessionGrade_core_trace false (remaining + 1)
      session next (.app fn arg) result graded
  exact ⟨returnedState,
    inferCore_app_trace remaining
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
      session.context session.state returnedState fn arg result coreRun,
    nextEq⟩

/-- A successful FULLY CHECKED public lambda retains the exact visited
domain sort, body inference and body-type sort exposure, including the
actual allocator and scope exit. Infer-only lambda remains unchecked. -/
theorem referenceSessionCheck_lambda_trace
    (remaining : Nat) (session next : PsKernelCheckerSession)
    (name : PsKernelName) (domain body : PsKernelExpr)
    (bi : PsKernelBinderInfo) (result : PsKernelExpr)
    (run : @psKernelSessionCheck psKernelReferenceCachePolicy
      (remaining + 1) session (.lam name domain body bi) = .ok (result, next)) :
    ∃ returnedState : PsKernelCheckerState,
      Nonempty (LambdaTrace remaining
        (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
          (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
        session.context session.state name domain body bi result returnedState) ∧
      next = PsKernelCheckerSession.mk session.context returnedState := by
  have graded : referenceSessionGrade false (remaining + 1) session
      (.lam name domain body bi) = .ok (result, next) := by
    simpa [referenceSessionGrade] using run
  obtain ⟨returnedState, coreRun, nextEq⟩ :=
    referenceSessionGrade_core_trace false (remaining + 1)
      session next (.lam name domain body bi) result graded
  exact ⟨returnedState,
    inferCore_lam_trace remaining
      (@psKernelWhnfWithRecursorFuel psKernelReferenceCachePolicy (remaining + 1)
        (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1)))
      (@psKernelIsDefEqWithFuel psKernelReferenceCachePolicy (remaining + 1))
      session.context session.state returnedState
      name domain body bi result coreRun,
    nextEq⟩

end PsKernelSemantics.Reference
