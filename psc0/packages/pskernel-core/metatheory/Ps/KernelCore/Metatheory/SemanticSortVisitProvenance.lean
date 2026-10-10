import Ps.KernelCore.Metatheory.SemanticCheckedAnnotationVisits
import Ps.KernelCore.Metatheory.SemanticReferenceLambda
import Ps.KernelCore.Metatheory.SemanticAnnotationCoherence
import Ps.KernelCore.Core.AnnotatedInference

/-!
Intensional provenance at the shared, executable binder sort visits.

A selected annotation is tied to a particular successful infer-then-sort call.
This evidence is outside every satisfying-valuation premise, so it remains
informative when a binder domain or a semantic context has no inhabitants.
Infer-only lambda success is explicitly unchecked and supplies no sort tag.

The source equations do not assume that callbacks are semantically sound.
Conversely, semantic validity alone cannot construct these equations. The
full recursive invariant must retain both kinds of evidence for the same
carried syntax. Same-call agreement is not a theorem about different calls
whose raw inputs happen to compare equal.
-/
namespace PsKernelSemantics.Reference
open AnnotatedExpr

/-- Forgetting the retained inferred type gives exactly the old sort pipeline,
including every failure string and the complete returned state. -/
theorem inferSortWith_forget_type (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState) (input : PsKernelExpr) :
    (match psKernelInferSortWith infer whnf c s input with
      | .error error => .error error
      | .ok (visit, next) => Except.ok (visit.level, next)) =
      (match infer c s input with
        | .error error => .error error
        | .ok (inferredType, intermediate) =>
            psKernelEnsureSortWith whnf c intermediate inferredType) := by
  unfold psKernelInferSortWith
  cases hi : infer c s input with
  | error error => rfl
  | ok inferred =>
      rcases inferred with ⟨inferredType, intermediate⟩
      cases hs : psKernelEnsureSortWith whnf c intermediate inferredType with
      | error error => rfl
      | ok exposed =>
          cases exposed
          rfl

/-- Forgetting the codomain carrier recovers the previous state-only lambda
check exactly. Its inference grade and established error mapping are unchanged. -/
theorem lambdaCodomainVisitWith_forget (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (bodyType : PsKernelExpr) (io : Bool) :
    (match psKernelLambdaCodomainVisitWith infer whnf c s bodyType io with
      | .error error => .error error
      | .ok (_, next) => Except.ok next) =
      (if io then Except.ok s else
        match infer c s bodyType with
        | .error error => .error (psKernelLambdaCodomainSortFailure error)
        | .ok (inferredType, intermediate) =>
            match psKernelEnsureSortWith whnf c intermediate inferredType with
            | .error error => .error (psKernelLambdaCodomainSortFailure error)
            | .ok (_, next) => Except.ok next) := by
  cases io with
  | true => rfl
  | false =>
      unfold psKernelLambdaCodomainVisitWith psKernelInferSortWith
      cases hi : infer c s bodyType with
      | error error => rfl
      | ok inferred =>
          rcases inferred with ⟨inferredType, intermediate⟩
          cases hs : psKernelEnsureSortWith whnf c intermediate inferredType with
          | error error => rfl
          | ok exposed =>
              cases exposed
              rfl

/-- The retained fields are exactly those produced by the two actual visits. -/
theorem inferSortWith_ok_iff (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (input : PsKernelExpr) (visit : PsKernelSortVisitResult) :
    psKernelInferSortWith infer whnf c s input = .ok (visit, next) ↔
      ∃ intermediate : PsKernelCheckerState,
        infer c s input = .ok (visit.inferredType, intermediate) ∧
          psKernelEnsureSortWith whnf c intermediate visit.inferredType =
            .ok (visit.level, next) := by
  constructor
  · intro run
    cases hi : infer c s input with
    | error error =>
        simp only [psKernelInferSortWith, hi] at run
        cases run
    | ok inferred =>
        rcases inferred with ⟨inferredType, intermediate⟩
        cases hs : psKernelEnsureSortWith whnf c intermediate inferredType with
        | error error =>
            simp only [psKernelInferSortWith, hi, hs] at run
            cases run
        | ok exposed =>
            rcases exposed with ⟨level, finalState⟩
            have equal :
                ({ inferredType := inferredType, level := level } :
                  PsKernelSortVisitResult) = visit ∧ finalState = next := by
              simpa only [psKernelInferSortWith, hi, hs,
                Except.ok.injEq, Prod.mk.injEq] using run
            rcases equal with ⟨visitEq, stateEq⟩
            cases visitEq
            cases stateEq
            exact ⟨intermediate, by simp only [hi], by simp only [hs]⟩
  · rintro ⟨intermediate, hi, hs⟩
    cases visit
    simpa only [psKernelInferSortWith, hi, hs]

/-- An observed codomain is available only at the checked lambda grade. -/
theorem lambdaCodomainVisitWith_observed_iff (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (bodyType : PsKernelExpr) (io : Bool) (visit : PsKernelSortVisitResult) :
    psKernelLambdaCodomainVisitWith infer whnf c s bodyType io =
        .ok (.observed visit, next) ↔
      io = false ∧ psKernelInferSortWith infer whnf c s bodyType =
        .ok (visit, next) := by
  cases io with
  | false =>
      cases h : psKernelInferSortWith infer whnf c s bodyType with
      | error error => simp [psKernelLambdaCodomainVisitWith, h]
      | ok result =>
          rcases result with ⟨found, state⟩
          simp [psKernelLambdaCodomainVisitWith, h]
  | true => simp [psKernelLambdaCodomainVisitWith]

/-- Skipped certification carries no fabricated default level. -/
theorem lambdaCodomainVisitWith_unchecked_iff (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (bodyType : PsKernelExpr) (io : Bool) :
    psKernelLambdaCodomainVisitWith infer whnf c s bodyType io =
        .ok (.unchecked, next) ↔
      io = true ∧ s = next := by
  cases io with
  | false =>
      cases h : psKernelInferSortWith infer whnf c s bodyType with
      | error error => simp [psKernelLambdaCodomainVisitWith, h]
      | ok result =>
          rcases result with ⟨found, state⟩
          simp [psKernelLambdaCodomainVisitWith, h]
  | true => simp [psKernelLambdaCodomainVisitWith]

/-- The accessor exposes precisely the level in the observed runtime carrier. -/
theorem lambdaCodomainVisitWith_selected_level (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (bodyType : PsKernelExpr) (io : Bool) (visit : PsKernelLambdaCodomainVisit)
    (level : PsKernelLevel)
    (run : psKernelLambdaCodomainVisitWith infer whnf c s bodyType io =
      .ok (visit, next))
    (selected : psKernelLambdaCodomainVisitLevel visit = some level) :
    ∃ observed : PsKernelSortVisitResult,
      visit = .observed observed ∧ observed.level = level ∧
        io = false ∧
        psKernelInferSortWith infer whnf c s bodyType = .ok (observed, next) := by
  cases visit with
  | unchecked =>
      simp only [psKernelLambdaCodomainVisitLevel] at selected
      cases selected
  | observed observed =>
      have levelEq : observed.level = level := by
        exact Option.some.inj selected
      obtain ⟨grade, produced⟩ :=
        (lambdaCodomainVisitWith_observed_iff infer whnf c s next bodyType io observed).mp run
      exact ⟨observed, rfl, levelEq, grade, produced⟩

/-- Proof-only provenance for one selected binder tag. The executable checker
stores ordinary syntax/levels, not this predicate or any model-valued oracle.
The regime comparison allows exactly the zero-condition agreement used by
the model; assigning the actually produced level satisfies it immediately. -/
structure SortVisitSelected (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (input : PsKernelExpr) (visit : PsKernelSortVisitResult)
    (next : PsKernelCheckerState) (claimed : PsKernelLevel) : Prop where
  produced : psKernelInferSortWith infer whnf c s input = .ok (visit, next)
  regime : UniverseRegime.check claimed visit.level = true

theorem SortVisitSelected.of_produced (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (input : PsKernelExpr) (visit : PsKernelSortVisitResult)
    (run : psKernelInferSortWith infer whnf c s input = .ok (visit, next)) :
    SortVisitSelected infer whnf c s input visit next visit.level :=
  ⟨run, UniverseRegime.check_refl visit.level⟩

theorem SortVisitSelected.of_observed (infer whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (input : PsKernelExpr) (io : Bool) (visit : PsKernelSortVisitResult)
    (run : psKernelLambdaCodomainVisitWith infer whnf c s input io =
      .ok (.observed visit, next)) :
    SortVisitSelected infer whnf c s input visit next visit.level :=
  SortVisitSelected.of_produced infer whnf c s next input visit
    ((lambdaCodomainVisitWith_observed_iff infer whnf c s next input io visit).mp run).2

/-- Two claims about the same actual call agree, even if no valuation satisfies
the local context. This does not identify different checker calls. -/
theorem SortVisitSelected.agrees
    {infer whnf : InferOperation} {c : PsKernelCheckerContext}
    {s : PsKernelCheckerState} {input : PsKernelExpr}
    {left right : PsKernelSortVisitResult}
    {leftNext rightNext : PsKernelCheckerState}
    {leftClaim rightClaim : PsKernelLevel}
    (hl : SortVisitSelected infer whnf c s input left leftNext leftClaim)
    (hr : SortVisitSelected infer whnf c s input right rightNext rightClaim) :
    UniverseRegime.check leftClaim rightClaim = true := by
  have pairEq : (left, leftNext) = (right, rightNext) :=
    Except.ok.inj (hl.produced.symm.trans hr.produced)
  have visitEq : left = right := (Prod.mk.inj pairEq).1
  cases visitEq
  exact UniverseRegime.check_trans hl.regime (UniverseRegime.check_symm hr.regime)

/-- Level substitution transports the stored tag and its recorded source
level together. This is not a claim that a substituted checker call was run. -/
theorem SortVisitSelected.instantiated_regime
    {infer whnf : InferOperation} {c : PsKernelCheckerContext}
    {s next : PsKernelCheckerState} {input : PsKernelExpr}
    {visit : PsKernelSortVisitResult} {claimed : PsKernelLevel}
    (h : SortVisitSelected infer whnf c s input visit next claimed)
    (names : List PsKernelName) (values : List PsKernelLevel) :
    UniverseRegime.check
      (psKernelLevelInstantiateParams claimed names values)
      (psKernelLevelInstantiateParams visit.level names values) = true :=
  UniverseRegime.check_instParams claimed visit.level names values h.regime

/-- The empty-domain counterexample's conflicting tags cannot both originate
from this fixed actual visit. No semantic inhabitance premise occurs. -/
theorem selected_sort_not_zero_and_succ
    (infer whnf : InferOperation) (c : PsKernelCheckerContext)
    (s : PsKernelCheckerState) (input : PsKernelExpr)
    (left right : PsKernelSortVisitResult)
    (leftNext rightNext : PsKernelCheckerState) (level : PsKernelLevel)
    (zero : SortVisitSelected infer whnf c s input left leftNext .zero)
    (positive : SortVisitSelected infer whnf c s input right rightNext (.succ level)) :
    False := by
  have impossible := zero.agrees positive
  change false = true at impossible
  cases impossible

/-- Closing or substituting coherent children can be composed with this
constructor rule using the existing Coherent transport theorems. -/
theorem annotatedLambdaResult_same_visit_coherent
    {infer whnf : InferOperation} {c : PsKernelCheckerContext}
    {s : PsKernelCheckerState} {input : PsKernelExpr}
    {left right : PsKernelSortVisitResult}
    {leftNext rightNext : PsKernelCheckerState}
    {leftClaim rightClaim : PsKernelLevel}
    (hl : SortVisitSelected infer whnf c s input left leftNext leftClaim)
    (hr : SortVisitSelected infer whnf c s input right rightNext rightClaim)
    (n m : PsKernelName) (bi bj : PsKernelBinderInfo)
    (A A' body body' bodyType bodyType' : AnnotatedExpr)
    (domain : Coherent A A') (terms : Coherent body body')
    (types : Coherent bodyType bodyType') :
    Coherent
        (annotatedLambdaResult n A body bodyType bi leftClaim).expr
        (annotatedLambdaResult m A' body' bodyType' bj rightClaim).expr ∧
      Coherent
        (annotatedLambdaResult n A body bodyType bi leftClaim).type
        (annotatedLambdaResult m A' body' bodyType' bj rightClaim).type :=
  ⟨.lam (hl.agrees hr) domain terms, .forallE (hl.agrees hr) domain types⟩

/-- The checked lambda trace supplies provenance without any model premises. -/
theorem lambda_trace_selected_sort
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A body : PsKernelExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr)
    (trace : LambdaTrace remaining whnf defeq c s n A body bi result next) :
    SortVisitSelected
      (fun child state expr =>
        @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq child state expr true)
      whnf (binderChild trace.entered trace.domainSortState n A bi)
      trace.bodyState trace.bodyType
      { inferredType := trace.typeOfBodyType, level := trace.codomainLevel }
      trace.codomainState trace.codomainLevel := by
  apply SortVisitSelected.of_produced
  exact (inferSortWith_ok_iff _ _ _ _ _ _ _).mpr
    ⟨trace.typeState, trace.typeRun, trace.codomainSortRun⟩

/-- The production forall domain visit retains its actual inferred type and
sort in both inference grades. -/
theorem forall_trace_domain_selected_sort
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A body : PsKernelExpr) (bi : PsKernelBinderInfo)
    (io : Bool) (result : PsKernelExpr)
    (trace : ForallTrace remaining whnf defeq c s n A body bi io result next) :
    SortVisitSelected
      (fun child state expr =>
        @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq child state expr io)
      whnf trace.entered s A
      { inferredType := trace.domainType, level := trace.domainLevel }
      trace.domainSortState trace.domainLevel := by
  apply SortVisitSelected.of_produced
  exact (inferSortWith_ok_iff _ _ _ _ _ _ _).mpr
    ⟨trace.domainState, trace.domainRun, trace.domainSortRun⟩

/-- The range tag is selected at the exact fresh-variable body visit, even
when its binder domain has an empty interpretation. -/
theorem forall_trace_range_selected_sort
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A body : PsKernelExpr) (bi : PsKernelBinderInfo)
    (io : Bool) (result : PsKernelExpr)
    (trace : ForallTrace remaining whnf defeq c s n A body bi io result next) :
    SortVisitSelected
      (fun child state expr =>
        @psKernelInferCoreWithFuel psKernelReferenceCachePolicy
          remaining whnf defeq child state expr io)
      whnf (binderChild trace.entered trace.domainSortState n A bi)
      (psKernelCheckerStateFreshName trace.domainSortState n).2
      (psKernelExprInstantiate1 body
        (.fvar (psKernelCheckerStateFreshName trace.domainSortState n).1))
      { inferredType := trace.bodyType, level := trace.rangeLevel }
      trace.bodySortState trace.rangeLevel := by
  apply SortVisitSelected.of_produced
  exact (inferSortWith_ok_iff _ _ _ _ _ _ _).mpr
    ⟨trace.bodyState, trace.bodyRun, trace.bodySortRun⟩

end PsKernelSemantics.Reference
