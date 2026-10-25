import Ps.KernelCore.API.DagMutualRecursiveArgument
import PsKernelExpandedSizeProofs

/- Local worker protocol, exact structural budget and a universal theorem
   about the retained original worker. This does not establish global checker
   soundness, backend preservation or complete mutual admission. -/
namespace PsKernelMutualRecursiveArgumentProofs

theorem original_applied_accumulator_irrelevant (fuel checkerFuel : Nat) :
    ∀ (session : PsKernelCheckerSession) (targets : List PsKernelName)
      (shapes : List PsKernelSimpleMutualTypeShape) (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder) (field : PsKernelOpenBinder)
      (domain : PsKernelExpr) (revArgs : List PsKernelOpenBinder)
      (left right : PsKernelExpr),
      psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel fuel checkerFuel
        session targets shapes levels params field domain revArgs left =
      psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel fuel checkerFuel
        session targets shapes levels params field domain revArgs right := by
  induction fuel with
  | zero => intros; rfl
  | succ remaining ih =>
      intro session targets shapes levels params field domain revArgs left right
      simp only [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel]
      cases direct : psKernelSimpleMutualAppInfo targets shapes levels params domain with
      | some info => simp only [direct]
      | none =>
          simp only [direct]
          cases reduced : psKernelSessionWhnf checkerFuel session domain with
          | error error => simp only [reduced]
          | ok result =>
              simp only [reduced]
              cases selected : psKernelSimpleMutualAppInfo targets shapes levels params result.fst with
              | some info => simp only [selected]
              | none =>
                  simp only [selected]
                  cases shape : result.fst <;> simp only [shape] <;> try rfl
                  split <;> try rfl
                  apply ih

variable (whnf : Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
    Option (Except String (Prod PsKernelExprV2CheckState Nat)))
  (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
  (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
  (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
  (field : PsKernelExprV2OrdinaryOpenBinder) (domain : Nat)
  (revArgs : List PsKernelExprV2OrdinaryOpenBinder) (remaining checkerFuel : Nat)

theorem structural_zero_precedes_lookup
    : psKernelExprV2MutualAnalyzeRecursiveArgumentWorker 0 checkerFuel whnf context state
        targets types levels parameters field domain revArgs =
      some (.error "mutual recursive-argument budget exhausted") := rfl

theorem direct_selection_precedes_whnf
    (info : PsKernelExprV2MutualAppInfo)
    (selected : psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena targets types levels parameters domain = .ok (some info)) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWorker (Nat.succ remaining) checkerFuel
      whnf context state targets types levels parameters field domain revArgs = some (.ok
      (psKernelExprV2MutualRecursiveSelected context state field revArgs info)) := by
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWorker, selected]

theorem direct_error_precedes_whnf
    (error : String) (failed : psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena targets types levels parameters domain = .error error) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWorker (Nat.succ remaining) checkerFuel
      whnf context state targets types levels parameters field domain revArgs = some (.error error) := by
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWorker, failed]

theorem whnf_decline_is_preserved
    
    (absent : psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena targets types levels parameters domain = .ok none)
    (attempted : whnf checkerFuel context state domain = none) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWorker (Nat.succ remaining) checkerFuel
      whnf context state targets types levels parameters field domain revArgs = none := by
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWorker, absent, attempted]

theorem whnf_error_is_preserved
    (error : String)
    (absent : psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena targets types levels parameters domain = .ok none)
    (attempted : whnf checkerFuel context state domain = some (.error error)) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWorker (Nat.succ remaining) checkerFuel
      whnf context state targets types levels parameters field domain revArgs = some (.error error) := by
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWorker, absent, attempted]

theorem whnf_owner_and_fixed_checker_fuel
    (next : PsKernelExprV2CheckState) (reduced : Nat)
    (absent : psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena targets types levels parameters domain = .ok none)
    (attempted : whnf checkerFuel context state domain = some (.ok (next,reduced))) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWorker (Nat.succ remaining) checkerFuel
      whnf context state targets types levels parameters field domain revArgs =
      psKernelExprV2MutualRecursiveAfterWhnfWith
        (fun childContext childState childDomain childArgs =>
          psKernelExprV2MutualAnalyzeRecursiveArgumentWorker remaining checkerFuel whnf childContext childState
            targets types levels parameters field childDomain childArgs)
        context next targets types levels parameters field domain reduced revArgs := by
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWorker, absent, attempted]

theorem post_whnf_selection_keeps_owner
    (recur : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
      List PsKernelExprV2OrdinaryOpenBinder →
      Option (Except String PsKernelExprV2MutualRecursiveArgumentResult))
    (reduced : Nat) (info : PsKernelExprV2MutualAppInfo)
    (selected : psKernelExprV2MutualAppInfoOnCanonical state.whnf.arena
      targets types levels parameters reduced = .ok (some info)) :
    psKernelExprV2MutualRecursiveAfterWhnfWith recur context state targets types levels
      parameters field domain reduced revArgs = some (.ok
        (psKernelExprV2MutualRecursiveSelected context state field revArgs info)) := by
  simp only [psKernelExprV2MutualRecursiveAfterWhnfWith, selected]

theorem negative_domain_precedes_opening
    (userName : PsKernelName) (body : Nat) (binderInfo : PsKernelBinderInfo)
    (negative : psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena
      targets domain = .ok true) :
    psKernelExprV2MutualRecursiveOpenBinder context state targets userName domain body binderInfo =
      .error "mutual inductive field has a non-positive recursive occurrence" := by
  simp only [psKernelExprV2MutualRecursiveOpenBinder, negative, ↓reduceIte]

theorem opened_binder_keeps_exact_owner
    (userName : PsKernelName) (body localDomain : Nat) (binderInfo : PsKernelBinderInfo)
    (opened : PsKernelExprV2OpenedCheckBinder)
    (positive : psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena
      targets domain = .ok false)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = .ok localDomain)
    (step : psKernelExprV2CheckOpenBinder context state userName localDomain body binderInfo = .ok opened) :
    psKernelExprV2MutualRecursiveOpenBinder context state targets userName domain body binderInfo =
      .ok (opened, PsKernelExprV2OrdinaryOpenBinder.mk opened.fresh userName localDomain binderInfo) := by
  simp only [psKernelExprV2MutualRecursiveOpenBinder, positive, ↓reduceIte, annotations, step]

theorem terminal_original_hit_precedes_reduced
    (reduced : Nat)
    (hit : psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena targets domain = .ok true) :
    psKernelExprV2MutualRecursiveTerminal context state targets domain reduced =
      .error "nested or invalid mutual inductive occurrence is not supported" := by
  simp only [psKernelExprV2MutualRecursiveTerminal, hit, ↓reduceIte]

theorem terminal_no_occurrences_keeps_owner
    (reduced : Nat)
    (originalClean : psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena targets domain = .ok false)
    (reducedClean : psKernelExprV2MutualContainsConstOnCanonical state.whnf.arena targets reduced = .ok false) :
    psKernelExprV2MutualRecursiveTerminal context state targets domain reduced =
      .ok (PsKernelExprV2MutualRecursiveArgumentResult.mk context state none) := by
  simp only [psKernelExprV2MutualRecursiveTerminal, originalClean, reducedClean, ↓reduceIte]

theorem selected_retains_field_and_index_ids
    (info : PsKernelExprV2MutualAppInfo) :
    (psKernelExprV2MutualRecursiveSelected context state field revArgs info).recursiveInfo =
      some (PsKernelExprV2MutualRecursiveField.mk field
        (psKernelExprV2OrdinaryReverseOpenBinders revArgs) info.target info.indices) := rfl

theorem count_error_precedes_checker
    (error : String)
    (failed : psKernelExprV2ExpandedSizeOnCanonical state.whnf.arena domain = .error error) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWith whnf checkerFuel context state
      targets types levels parameters field domain = some (.error error) := by
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWith, failed]

theorem wrapper_uses_exact_original_tree_budget
    (decode : Nat → PsKernelExpr)
    (model : PsKernelOrdinaryOccurrenceProofs.ArenaModel state.whnf.arena decode)
    (valid : PsKernelOrdinaryOccurrenceProofs.validId state.whnf.arena domain) :
    psKernelExprV2MutualAnalyzeRecursiveArgumentWith whnf checkerFuel context state
      targets types levels parameters field domain =
    psKernelExprV2MutualAnalyzeRecursiveArgumentWorker
      (Nat.succ (psKernelExprNodeCount (decode domain))) checkerFuel
      whnf context state targets types levels parameters field domain [] := by
  have count := PsKernelExpandedSizeProofs.canonical_count_is_exact
    state.whnf.arena decode model domain valid
  simp only [psKernelExprV2MutualAnalyzeRecursiveArgumentWith, count]

#print axioms original_applied_accumulator_irrelevant
#print axioms structural_zero_precedes_lookup
#print axioms direct_selection_precedes_whnf
#print axioms direct_error_precedes_whnf
#print axioms whnf_decline_is_preserved
#print axioms whnf_error_is_preserved
#print axioms whnf_owner_and_fixed_checker_fuel
#print axioms post_whnf_selection_keeps_owner
#print axioms negative_domain_precedes_opening
#print axioms opened_binder_keeps_exact_owner
#print axioms terminal_original_hit_precedes_reduced
#print axioms terminal_no_occurrences_keeps_owner
#print axioms selected_retains_field_and_index_ids
#print axioms count_error_precedes_checker
#print axioms wrapper_uses_exact_original_tree_budget
end PsKernelMutualRecursiveArgumentProofs
