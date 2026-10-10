import Ps.KernelCore.Metatheory.SemanticFunctionValidity
import Ps.KernelCore.Metatheory.SemanticCheckedAnnotations
import Ps.KernelCore.Metatheory.SemanticReferenceSortChecks

/-!
An executable annotation-validation step at an actual sort-exposure visit.
The proposed guard is an assurance operation, not yet a public acceptance path.
It propagates sort-check errors and rejects a conflicting annotation. It cannot
certify a fabricated recursive inference result: the model lemmas still require
soundness of the actual recursive typing/reduction visits.
-/
namespace PsKernelSemantics.Reference

def validateSortAnnotationWith (whnf : InferOperation)
    (c : PsKernelCheckerContext) (s : PsKernelCheckerState)
    (input : PsKernelExpr) (claimed : PsKernelLevel) :
    Except String (PsKernelLevel × PsKernelCheckerState) :=
  match psKernelEnsureSortWith whnf c s input with
  | .error error => .error error
  | .ok (actual, next) =>
      if UniverseRegime.check claimed actual then .ok (actual, next)
      else .error "annotation does not match the checked universe regime"

theorem validateSortAnnotationWith_ok_iff (whnf : InferOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (input : PsKernelExpr) (claimed actual : PsKernelLevel) :
    validateSortAnnotationWith whnf c s input claimed = .ok (actual, next) ↔
      psKernelEnsureSortWith whnf c s input = .ok (actual, next) ∧
        UniverseRegime.check claimed actual = true := by
  unfold validateSortAnnotationWith
  cases hr : psKernelEnsureSortWith whnf c s input with
  | error error => simp
  | ok found =>
      rcases found with ⟨level, state⟩
      by_cases hc : UniverseRegime.check claimed level = true
      · simp only [hc, ite_true, Except.ok.injEq, Prod.mk.injEq]
        constructor
        · rintro ⟨rfl, rfl⟩
          exact ⟨⟨rfl, rfl⟩, hc⟩
        · exact fun h => h.1
      · simp only [hc, ite_false]
        constructor
        · intro h; cases h
        · rintro ⟨pair, h⟩
          obtain ⟨rfl, rfl⟩ := Prod.mk.inj (Except.ok.inj pair)
          exact False.elim (hc h)

open ConLeche ConLeche.SetTheory ConLeche.SetModel SetModel AnnotatedExpr
universe w
variable {V : Type w} [SetTheory V]

/-- The zero claim is justified by the executable guard and the actual visited
sort, independently of whether the context's binder domain is inhabited. -/
theorem validateSortAnnotationWith_zero_mem (M : Reading V) (ρ : Nat → V)
    (whnf : InferOperation) (c : PsKernelCheckerContext)
    (s next : PsKernelCheckerState) (e A : AnnotatedExpr)
    (claimed actual : PsKernelLevel)
    (run : validateSortAnnotationWith whnf c s A.erase claimed = .ok (actual, next))
    (typed : interp M ρ e ∈ˢ interp M ρ A)
    (reduction : whnf c s A.erase = .ok (.sort actual, next) →
      interp M ρ A = univ (M.level actual))
    (zero : M.level claimed = 0) :
    interp M ρ e ∈ˢ (univ 0 : V) := by
  obtain ⟨sortRun, guard⟩ :=
    (validateSortAnnotationWith_ok_iff whnf c s next A.erase claimed actual).mp run
  have actualZero : M.level actual = 0 :=
    ((UniverseRegime.check_spec claimed actual).mp guard M.levelParams M.levelMetavariables).mp zero
  simpa only [actualZero] using
    ensureSort_mem M ρ whnf c s next e A actual typed sortRun reduction

/-- The existing forall visit yields this guarded visit exactly when its
supplied annotation agrees with the computed range sort. -/
theorem forall_trace_checked_sort
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A B : PsKernelExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (io : Bool) (claimed : PsKernelLevel)
    (trace : ForallTrace remaining whnf defeq c s n A B bi io result next)
    (guard : UniverseRegime.check claimed trace.rangeLevel = true) :
    validateSortAnnotationWith whnf
      (binderChild trace.entered trace.domainSortState n A bi)
      trace.bodyState trace.bodyType claimed = .ok (trace.rangeLevel, trace.bodySortState) :=
  (validateSortAnnotationWith_ok_iff _ _ _ _ _ _ _).mpr ⟨trace.bodySortRun, guard⟩

/-- A matching symbolic annotation can read a concrete successful forall run.
The input's selected annotation is checked against the actual range level,
rather than inferred from vacuous semantic validity. -/
theorem forall_trace_model_checked_annotation
    (M : Reading V) (Γ : List AnnotatedExpr)
    (remaining : Nat) (whnf : InferOperation) (defeq : DefEqOperation)
    (c : PsKernelCheckerContext) (s next : PsKernelCheckerState)
    (n : PsKernelName) (A B : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (result : PsKernelExpr) (io : Bool) (claimed : PsKernelLevel)
    (trace : ForallTrace remaining whnf defeq c s n A.erase B.erase bi io result next)
    (guard : UniverseRegime.check claimed trace.rangeLevel = true)
    (hA : ModelsType M Γ A (.sort trace.domainLevel))
    (hB : ModelsType M (A :: Γ) B (.sort trace.rangeLevel))
    (ha : ∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ A)
    (hb : ∀ ρ, Satisfies M (A :: Γ) ρ → AnnotationValid M ρ B) :
    ∃ type : AnnotatedExpr, type.erase = result ∧
      ModelsType M Γ (.forallE n A B bi claimed) type ∧
      (∀ ρ, Satisfies M Γ ρ → AnnotationValid M ρ (.forallE n A B bi claimed)) := by
  have regimes : M.level claimed = 0 ↔ M.level trace.rangeLevel = 0 :=
    (UniverseRegime.check_spec claimed trace.rangeLevel).mp guard
      M.levelParams M.levelMetavariables
  refine ⟨.sort (psKernelLevelMkIMax trace.domainLevel trace.rangeLevel),
    trace.resultEq.symm, ?_, ?_⟩
  · intro ρ hρ
    change piR (M.level claimed) (interp M ρ A)
      (fun x => interp M (extend x ρ) B) ∈ˢ
      univ (M.level (psKernelLevelMkIMax trace.domainLevel trace.rangeLevel))
    rw [piR_zero_agree regimes (fun _ _ => rfl)]
    have hl : M.level (psKernelLevelMkIMax trace.domainLevel trace.rangeLevel) =
        SetModel.imax (M.level trace.domainLevel) (M.level trace.rangeLevel) :=
      mkIMax_eval M.levelParams M.levelMetavariables trace.domainLevel trace.rangeLevel
    rw [hl]
    exact pi_mem_sort (hA ρ hρ)
      (fun x hx => hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx))
  · intro ρ hρ
    refine ⟨ha ρ hρ,
      (fun x hx => hb (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx)), ?_⟩
    intro hz x hx
    have typed := hB (extend x ρ) (satisfies_extend M Γ A ρ x hρ hx)
    change interp M (extend x ρ) B ∈ˢ univ (M.level trace.rangeLevel) at typed
    simpa only [regimes.mp hz] using typed

/-- The actual production universe predicate discharges the positive-regime
premise of beta soundness for every reading. The selected annotation and
hereditary application evidence still have to come from checked visits. -/
theorem beta_of_native_positive (M : Reading V) (ρ : Nat → V)
    (n : PsKernelName) (A b a : AnnotatedExpr) (bi : PsKernelBinderInfo)
    (v : PsKernelLevel) (positive : psKernelLevelIsNotZero v = true)
    (valid : FunctionValid M ρ (.app (.lam n A b bi v) a)) :
    interp M ρ (.app (.lam n A b bi v) a) = interp M ρ (inst a b 0) ∧
      FunctionValid M ρ (inst a b 0) :=
  functionValid_beta_positive M ρ n A b a bi v
    ((UniverseRegime.native_positive_spec v).mp positive M.levelParams M.levelMetavariables)
    valid

end PsKernelSemantics.Reference
