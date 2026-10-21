import Ps.KernelCore.Checker.Inference.Constant
import Ps.KernelCore.Checker.ExprV2.Check
import Init.Data.Nat.MinMax
import Ps.KernelCore.Checker.State
import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Checker.ExprV2.DefEq
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-!
Exact local cache restoration and eligibility facts for arbitrary states.
This does not establish validity of stored judgments, FVar scanner completeness,
proper use of scope exit at every call site, or whole-kernel soundness.
Native proof material is outside the portable executable source closure.
-/
namespace PsKernelCacheScopeProofs

def beforeInferConstantType
    (context : PsKernelCheckerContext)
    (name : PsKernelName) (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Except String PsKernelExpr :=
  match psKernelEnvironmentFind context.environment name with
  | Option.none => Except.error "unknown constant"
  | Option.some info =>
      let params := psKernelConstantInfoLevelParams info;
      if Nat.beq
          (psKernelNameListLength params) (psKernelLevelListLength levels) then
        if inferOnly then
          Except.ok
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info) params levels)
        else if psKernelConstantInfoIsUnsafe info then
          if psKernelDefinitionSafetyIsUnsafe context.safety then
            Except.ok
              (psKernelExprInstantiateLevelParams
                (psKernelConstantInfoType info) params levels)
          else
            Except.error "safe declaration uses unsafe constant"
        else if psKernelConstantInfoIsPartial info then
          if psKernelDefinitionSafetyIsSafe context.safety then
            Except.error "safe declaration uses partial constant"
          else
            Except.ok
              (psKernelExprInstantiateLevelParams
                (psKernelConstantInfoType info) params levels)
        else
          Except.ok
            (psKernelExprInstantiateLevelParams
              (psKernelConstantInfoType info) params levels)
      else
        Except.error "incorrect number of universe levels"

theorem constant_reference_factorization_preserves
    (context : PsKernelCheckerContext)
    (name : PsKernelName) (levels : List PsKernelLevel) (inferOnly : Bool) :
    psKernelInferConstantType context name levels inferOnly =
      beforeInferConstantType context name levels inferOnly := by
  cases found : psKernelEnvironmentFind context.environment name with
  | none =>
      simp [psKernelInferConstantType, psKernelCheckConstantReference,
        beforeInferConstantType, found]
  | some info =>
      cases arity : Nat.beq
          (psKernelNameListLength (psKernelConstantInfoLevelParams info))
          (psKernelLevelListLength levels) <;>
        cases mode : inferOnly <;>
        cases unsafeFlag : psKernelConstantInfoIsUnsafe info <;>
        cases unsafeAllowed : psKernelDefinitionSafetyIsUnsafe context.safety <;>
        cases partialFlag : psKernelConstantInfoIsPartial info <;>
        cases safeFlag : psKernelDefinitionSafetyIsSafe context.safety <;>
        simp [psKernelInferConstantType, psKernelCheckConstantReference,
          beforeInferConstantType, found, arity, mode, unsafeFlag,
          unsafeAllowed, partialFlag, safeFlag]

theorem constant_reference_factorization_extensional :
    psKernelInferConstantType = beforeInferConstantType := by
  funext context name levels inferOnly
  exact constant_reference_factorization_preserves context name levels inferOnly


structure SameSemanticCaches (left right : PsKernelCheckerState) : Prop where
  inferOnly : left.inferOnly = right.inferOnly
  checkedInfer : left.checkedInfer = right.checkedInfer
  whnfCore : left.whnfCore = right.whnfCore
  whnf : left.whnf = right.whnf
  unfold : left.unfold = right.unfold
  success : left.success = right.success
  failure : left.failure = right.failure

theorem exit_scope_restores_all_caches (saved child : PsKernelCheckerState) :
    SameSemanticCaches (psKernelCheckerStateExitLocalScope saved child) saved := by
  constructor <;> rfl

theorem exit_scope_caches_independent_of_child
    (saved firstChild secondChild : PsKernelCheckerState) :
    SameSemanticCaches
      (psKernelCheckerStateExitLocalScope saved firstChild)
      (psKernelCheckerStateExitLocalScope saved secondChild) := by
  constructor <;> rfl

theorem stateNatMax_eq (left right : Nat) :
    psKernelStateNatMax left right = Nat.max left right := by
  simp only [psKernelStateNatMax, Nat.ble_eq, Nat.max_def]

theorem exit_scope_counter_exact (saved child : PsKernelCheckerState) :
    (psKernelCheckerStateExitLocalScope saved child).nextFresh =
      Nat.max saved.nextFresh child.nextFresh := by
  simp only [psKernelCheckerStateExitLocalScope, stateNatMax_eq]

theorem exit_scope_counter_ge_parent (saved child : PsKernelCheckerState) :
    saved.nextFresh ≤ (psKernelCheckerStateExitLocalScope saved child).nextFresh := by
  rw [exit_scope_counter_exact]
  exact Nat.le_max_left _ _

theorem exit_scope_counter_ge_child (saved child : PsKernelCheckerState) :
    child.nextFresh ≤ (psKernelCheckerStateExitLocalScope saved child).nextFresh := by
  rw [exit_scope_counter_exact]
  exact Nat.le_max_right _ _

theorem exit_scope_counter_retains_monotone_child
    (saved child : PsKernelCheckerState) (monotone : saved.nextFresh ≤ child.nextFresh) :
    (psKernelCheckerStateExitLocalScope saved child).nextFresh = child.nextFresh := by
  rw [exit_scope_counter_exact]
  exact Nat.max_eq_right monotone

theorem semantic_eligible_iff_no_fvar_flag (expr : PsKernelExpr) :
    (psKernelSemanticCacheEligible expr = true) ↔ (psKernelExprHasFVar expr = false) := by
  cases flag : psKernelExprHasFVar expr <;> simp [psKernelSemanticCacheEligible, flag]

theorem semantic_fvar_ineligible (name : PsKernelName) :
    psKernelSemanticCacheEligible (PsKernelExpr.fvar name) = false := by
  rfl

theorem semantic_pair_eligible_iff_no_fvar_flags (left right : PsKernelExpr) :
    (psKernelSemanticPairCacheEligible left right = true) ↔
      (psKernelExprHasFVar left = false ∧ psKernelExprHasFVar right = false) := by
  cases leftFlag : psKernelExprHasFVar left <;>
    cases rightFlag : psKernelExprHasFVar right <;>
    simp [psKernelSemanticPairCacheEligible, psKernelSemanticCacheEligible, leftFlag, rightFlag]

/- Frozen proof-only reference to the eligibility policy at e1b4deb.
This reference is outside the executable kernel closure. -/
def psKernelInferCacheEligibleBefore
    (inferOnly : Bool)
    (expr : PsKernelExpr) :
    Bool :=
  if psKernelSemanticCacheEligible expr then
    match expr with
    | PsKernelExpr.lit _ =>
        false
    | PsKernelExpr.app _ _ =>
        inferOnly
    | PsKernelExpr.lam _ _ _ _ =>
        inferOnly
    | PsKernelExpr.forallE _ _ _ _ =>
        inferOnly
    | _ =>
        true
  else
    false


private theorem cacheGate_comm (eligible requested : Bool) :
    (if requested then eligible else false) =
      (if eligible then requested else false) := by
  cases eligible <;> cases requested <;> rfl

private theorem cacheGate_true (eligible : Bool) :
    eligible = (if eligible then true else false) := by
  cases eligible <;> rfl

theorem inference_cache_eligibility_preserves
    (inferOnly : Bool) (expr : PsKernelExpr) :
    psKernelInferCacheEligible inferOnly expr =
      psKernelInferCacheEligibleBefore inferOnly expr := by
  cases expr with
  | bvar index => rfl
  | fvar name => rfl
  | mvar name => rfl
  | sort level => rfl
  | const name levels => rfl
  | app fn arg =>
      exact cacheGate_comm
        (psKernelSemanticCacheEligible (PsKernelExpr.app fn arg)) inferOnly
  | lam name type body binderInfo =>
      exact cacheGate_comm
        (psKernelSemanticCacheEligible (PsKernelExpr.lam name type body binderInfo)) inferOnly
  | forallE name type body binderInfo =>
      exact cacheGate_comm
        (psKernelSemanticCacheEligible (PsKernelExpr.forallE name type body binderInfo)) inferOnly
  | letE name type value body nondep =>
      exact cacheGate_true
        (psKernelSemanticCacheEligible (PsKernelExpr.letE name type value body nondep))
  | lit value => rfl
  | mdata metadata expr =>
      exact cacheGate_true
        (psKernelSemanticCacheEligible (PsKernelExpr.mdata metadata expr))
  | proj typeName index expr =>
      exact cacheGate_true
        (psKernelSemanticCacheEligible (PsKernelExpr.proj typeName index expr))

theorem inference_cache_eligibility_extensional :
    psKernelInferCacheEligible = psKernelInferCacheEligibleBefore := by
  funext inferOnly expr
  exact inference_cache_eligibility_preserves inferOnly expr

theorem inference_ineligible_of_fvar_flag
    (inferOnly : Bool) (expr : PsKernelExpr) (flag : psKernelExprHasFVar expr = true) :
    psKernelInferCacheEligible inferOnly expr = false := by
  rw [inference_cache_eligibility_preserves]
  simp [psKernelInferCacheEligibleBefore, psKernelSemanticCacheEligible, flag]

theorem dag_whnf_starts_without_cache (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2WhnfStateEmpty arena).coreCache = List.nil := by
  rfl

theorem dag_whnf_fvar_flag_prevents_lookup
    (state : PsKernelExprV2WhnfState) (source : Nat)
    (entry : PsKernelExprV2Entry) (flag : entry.hasFVar = true) :
    psKernelExprV2WhnfCacheFind state source entry = Except.ok Option.none := by
  simp [psKernelExprV2WhnfCacheFind, flag]

theorem dag_whnf_fvar_flag_prevents_publication
    (state : PsKernelExprV2WhnfState) (source result : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.arena source = Except.ok entry)
    (flag : entry.hasFVar = true) :
    psKernelExprV2WhnfCoreFinish state source result =
      Except.ok (Prod.mk state result) := by
  simp [psKernelExprV2WhnfCoreFinish, found, flag]


theorem dag_whnf_starts_without_public_cache (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2WhnfStateEmpty arena).publicCache = List.nil := by
  rfl

theorem dag_whnf_fvar_flag_prevents_public_lookup
    (state : PsKernelExprV2WhnfState) (source : Nat)
    (entry : PsKernelExprV2Entry) (flag : entry.hasFVar = true) :
    psKernelExprV2WhnfPublicCacheFind state source entry = Except.ok Option.none := by
  simp [psKernelExprV2WhnfPublicCacheFind, flag]

theorem dag_whnf_fvar_flag_prevents_public_publication
    (state : PsKernelExprV2WhnfState) (source result : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.arena source = Except.ok entry)
    (flag : entry.hasFVar = true) :
    psKernelExprV2WhnfPublicFinish state source result =
      Except.ok (Prod.mk state result) := by
  simp [psKernelExprV2WhnfPublicFinish, found, flag]

theorem dag_quick_defeq_zero_fuel_precedes_syntax
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena)
    (left right : Nat) :
    psKernelExprV2TryQuickDefEqWithFuel 0 context arena left right =
      Option.some (Except.error "kernel definitional equality budget exhausted") := by
  rfl

theorem dag_quick_defeq_depth_error_precedes_syntax
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (left right : Nat) (error : String)
    (guard : psKernelCheckerContextEnterRecDepth context = Except.error error) :
    psKernelExprV2TryQuickDefEqWithFuel (Nat.succ fuel) context arena left right =
      Option.some (Except.error error) := by
  simp [psKernelExprV2TryQuickDefEqWithFuel, psKernelExprV2TryDefEqStateWithFuel,
    psKernelExprV2CheckContextEmpty, psKernelExprV2CheckContextEnterRecDepth, guard]

theorem dag_whnf_declaration_initialization_has_no_core_cache
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :
    (psKernelExprV2WhnfStateForDeclarations arena declarations).coreCache = List.nil := by
  rfl

theorem dag_whnf_declaration_initialization_has_no_public_cache
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) :
    (psKernelExprV2WhnfStateForDeclarations arena declarations).publicCache = List.nil := by
  rfl

theorem dag_whnf_arena_update_preserves_declaration_references
    (state : PsKernelExprV2WhnfState) (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2WhnfStateWithArena state arena).declarations = state.declarations := by
  rfl

theorem dag_check_scope_retains_child_arena
    (parent child : PsKernelExprV2CheckState) :
    (psKernelExprV2CheckStateExitLocalScope parent child).whnf.arena = child.whnf.arena := by
  rfl

theorem dag_check_scope_restores_semantic_caches
    (parent child : PsKernelExprV2CheckState) :
    (psKernelExprV2CheckStateExitLocalScope parent child).checkedInfer = parent.checkedInfer ∧
    (psKernelExprV2CheckStateExitLocalScope parent child).whnf.coreCache = parent.whnf.coreCache ∧
    (psKernelExprV2CheckStateExitLocalScope parent child).whnf.publicCache = parent.whnf.publicCache := by
  constructor
  · rfl
  · constructor <;> rfl

theorem dag_check_scope_counter_exact
    (parent child : PsKernelExprV2CheckState) :
    (psKernelExprV2CheckStateExitLocalScope parent child).nextFresh =
      Nat.max parent.nextFresh child.nextFresh := by
  simp only [psKernelExprV2CheckStateExitLocalScope, stateNatMax_eq]

theorem dag_check_starts_without_inference_cache (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2CheckStateEmpty arena).checkedInfer = List.nil := by
  rfl

theorem dag_check_fvar_flag_prevents_lookup
    (state : PsKernelExprV2CheckState) (source : Nat)
    (entry : PsKernelExprV2Entry) (flag : entry.hasFVar = true) :
    psKernelExprV2CheckedInferFind state source entry = Except.ok Option.none := by
  simp [psKernelExprV2CheckedInferFind, psKernelExprV2InferenceFind,
    psKernelExprV2InferenceCacheEligible, flag]

theorem dag_check_fvar_flag_prevents_publication
    (state : PsKernelExprV2CheckState) (source result : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena source = Except.ok entry)
    (flag : entry.hasFVar = true) :
    psKernelExprV2CheckedInferFinish state source result =
      Except.ok (Prod.mk state result) := by
  simp [psKernelExprV2CheckedInferFinish, psKernelExprV2InferenceFinish,
    psKernelExprV2InferenceCacheEligible, found, flag]

theorem dag_check_zero_fuel_precedes_cache
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (root : Nat) :
    psKernelExprV2TryCheckCoreWithFuel 0 whnf defeq context state root =
      Option.some (Except.error "kernel inference budget exhausted") := by
  rfl

theorem dag_check_depth_error_precedes_cached_judgment
    (fuel : Nat)
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root cached : Nat) (entry : PsKernelExprV2Entry) (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena root = Except.ok entry)
    (hit : psKernelExprV2CheckedInferFind state root entry = Except.ok (Option.some cached))
    (guard : psKernelCheckerContextEnterRecDepth context.scalar = Except.error error) :
    psKernelExprV2TryCheckCoreWithFuel (Nat.succ fuel) whnf defeq context state root =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2CheckedInferFind] at hit
  simp [psKernelExprV2TryCheckCoreWithFuel, psKernelExprV2TryInferCoreWithFuel,
    psKernelExprV2CheckContextEnterRecDepth, found, hit, guard]

theorem dag_check_starts_without_success_cache
    (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2CheckStateEmpty arena).success = List.nil := by
  rfl

theorem dag_check_scope_restores_success_cache
    (parent child : PsKernelExprV2CheckState) :
    (psKernelExprV2CheckStateExitLocalScope parent child).success = parent.success := by
  rfl

theorem dag_check_arena_update_preserves_success_cache
    (state : PsKernelExprV2CheckState) (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2CheckStateWithArena state arena).success = state.success := by
  rfl

theorem dag_defeq_false_does_not_publish
    (state : PsKernelExprV2CheckState) (left right : Nat) :
    psKernelExprV2CheckStateDefEqFinish state left right false =
      Except.ok (Prod.mk state false) := by
  rfl

theorem dag_defeq_fvar_flag_prevents_pair_lookup
    (arena : PsKernelExprV2PagedArena) (pairs : List PsKernelExprV2DefEqPair)
    (left right : Nat) (leftEntry rightEntry : PsKernelExprV2Entry)
    (foundLeft : psKernelExprV2PagedRequire arena left = Except.ok leftEntry)
    (foundRight : psKernelExprV2PagedRequire arena right = Except.ok rightEntry)
    (flag : leftEntry.hasFVar = true) :
    psKernelExprV2DefEqPairContains arena pairs left right = Except.ok false := by
  simp [psKernelExprV2DefEqPairContains, foundLeft, foundRight, flag]

theorem dag_defeq_fvar_flag_prevents_publication
    (state : PsKernelExprV2CheckState) (left right : Nat)
    (leftEntry rightEntry : PsKernelExprV2Entry)
    (foundLeft : psKernelExprV2PagedRequire state.whnf.arena left = Except.ok leftEntry)
    (foundRight : psKernelExprV2PagedRequire state.whnf.arena right = Except.ok rightEntry)
    (flag : leftEntry.hasFVar = true) :
    psKernelExprV2CheckStateDefEqFinish state left right true =
      Except.ok (Prod.mk state true) := by
  simp [psKernelExprV2CheckStateDefEqFinish, foundLeft, foundRight, flag]

theorem dag_defeq_zero_fuel_precedes_success_cache
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    psKernelExprV2TryDefEqStateWithFuel 0 context state left right =
      Option.some (Except.error "kernel definitional equality budget exhausted") := by
  rfl

theorem dag_defeq_depth_error_precedes_success_cache
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (left right : Nat) (error : String)
    (guard : psKernelCheckerContextEnterRecDepth context.scalar = Except.error error) :
    psKernelExprV2TryDefEqStateWithFuel (Nat.succ fuel) context state left right =
      Option.some (Except.error error) := by
  simp [psKernelExprV2TryDefEqStateWithFuel,
    psKernelExprV2CheckContextEnterRecDepth, guard]

/- Inference-only publications cannot enter the checked-inference cache.
   These local projection equalities do not assert validity of arbitrary
   caller-constructed caches or full checker soundness. -/
theorem dag_infer_only_update_preserves_checked_cache
    (state : PsKernelExprV2CheckState)
    (cache : List PsKernelExprV2WhnfCacheEntry) :
    (psKernelExprV2CheckStateWithInferOnly state cache).checkedInfer =
      state.checkedInfer := by
  rfl

theorem dag_infer_only_scope_restores_parent_cache
    (parent child : PsKernelExprV2CheckState) :
    (psKernelExprV2CheckStateExitLocalScope parent child).inferOnly =
      parent.inferOnly := by
  rfl

theorem dag_infer_only_starts_without_cache
    (arena : PsKernelExprV2PagedArena) :
    (psKernelExprV2CheckStateEmpty arena).inferOnly = List.nil := by
  rfl

theorem dag_inference_fvar_flag_prevents_lookup
    (state : PsKernelExprV2CheckState) (inferOnly : Bool) (source : Nat)
    (entry : PsKernelExprV2Entry) (flag : entry.hasFVar = true) :
    psKernelExprV2InferenceFind state inferOnly source entry =
      Except.ok Option.none := by
  simp [psKernelExprV2InferenceFind, psKernelExprV2InferenceCacheEligible, flag]

theorem dag_inference_fvar_flag_prevents_publication
    (state : PsKernelExprV2CheckState) (inferOnly : Bool) (source result : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena source = Except.ok entry)
    (flag : entry.hasFVar = true) :
    psKernelExprV2InferenceFinish state inferOnly source result =
      Except.ok (Prod.mk state result) := by
  simp [psKernelExprV2InferenceFinish, psKernelExprV2InferenceCacheEligible, found, flag]

theorem dag_infer_only_publication_preserves_checked_cache
    (state : PsKernelExprV2CheckState) (source result : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena source = Except.ok entry) :
    (psKernelExprV2InferenceFinish state true source result).map
        (fun inferred => inferred.fst.checkedInfer) =
      Except.ok state.checkedInfer := by
  cases eligible : psKernelExprV2InferenceCacheEligible true entry <;>
    simp [psKernelExprV2InferenceFinish, found, eligible,
      psKernelExprV2CheckStateWithInferOnly, Except.map]

theorem dag_checked_publication_preserves_infer_only_cache
    (state : PsKernelExprV2CheckState) (source result : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena source = Except.ok entry) :
    (psKernelExprV2InferenceFinish state false source result).map
        (fun inferred => inferred.fst.inferOnly) =
      Except.ok state.inferOnly := by
  cases eligible : psKernelExprV2InferenceCacheEligible false entry <;>
    simp [psKernelExprV2InferenceFinish, found, eligible, Except.map]

theorem dag_inference_zero_fuel_precedes_cache
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (inferOnly : Bool) :
    psKernelExprV2TryInferCoreWithFuel 0 whnf defeq context state root inferOnly =
      Option.some (Except.error "kernel inference budget exhausted") := by
  rfl

theorem dag_inference_depth_error_precedes_cached_judgment
    (fuel : Nat)
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root cached : Nat) (inferOnly : Bool)
    (entry : PsKernelExprV2Entry) (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena root = Except.ok entry)
    (hit : psKernelExprV2InferenceFind state inferOnly root entry =
      Except.ok (Option.some cached))
    (guard : psKernelCheckerContextEnterRecDepth context.scalar = Except.error error) :
    psKernelExprV2TryInferCoreWithFuel (Nat.succ fuel) whnf defeq
        context state root inferOnly =
      Option.some (Except.error error) := by
  simp [psKernelExprV2TryInferCoreWithFuel, psKernelExprV2CheckContextEnterRecDepth,
    found, hit, guard]


def psKernelExprV2WhnfCacheFindInBefore
    (entries : List PsKernelExprV2WhnfCacheEntry) :
    PsKernelExprV2PagedArena -> Nat -> Nat -> Except String (Option Nat) :=
  match entries with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_source _hash : Nat) =>
        Except.ok Option.none
  | List.cons first rest =>
      let smaller :=
        fun (nextArena : PsKernelExprV2PagedArena) (nextSource nextHash : Nat) =>
          let recur := psKernelExprV2WhnfCacheFindInBefore rest;
          recur nextArena nextSource nextHash;
      fun (arena : PsKernelExprV2PagedArena) (source hash : Nat) =>
        if Nat.beq first.hash hash then
          match psKernelExprV2PagedEqOnCanonical arena first.source source with
          | Except.error error => Except.error error
          | Except.ok equal =>
              if equal then Except.ok (Option.some first.result)
              else smaller arena source hash
        else smaller arena source hash

theorem psKernelExprV2WhnfCacheFindWorker_eq_before
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindWorker entries arena source hash =
      psKernelExprV2WhnfCacheFindInBefore entries arena source hash := by
  induction entries with
  | nil => rfl
  | cons first rest ih =>
      cases hashEqual : Nat.beq first.hash hash with
      | false =>
          have hashRelation : first.hash ≠ hash := by
            intro sameHash
            have yes : Nat.beq first.hash hash = true := by simpa using sameHash
            rw [yes] at hashEqual
            cases hashEqual
          simpa [psKernelExprV2WhnfCacheFindWorker,
            psKernelExprV2WhnfCacheFindInBefore, hashEqual, hashRelation] using ih
      | true =>
          have hashRelation : first.hash = hash := by simpa using hashEqual
          cases compared :
              psKernelExprV2PagedEqOnCanonical arena first.source source with
          | error error =>
              simp [psKernelExprV2WhnfCacheFindWorker,
                psKernelExprV2WhnfCacheFindInBefore, hashEqual, hashRelation, compared]
          | ok equal =>
              cases equal with
              | false =>
                  simpa [psKernelExprV2WhnfCacheFindWorker,
                    psKernelExprV2WhnfCacheFindInBefore, hashEqual, hashRelation, compared] using ih
              | true =>
                  simp [psKernelExprV2WhnfCacheFindWorker,
                    psKernelExprV2WhnfCacheFindInBefore, hashEqual, hashRelation, compared]

theorem psKernelExprV2WhnfCacheFindIn_eq_before
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindIn entries arena source hash =
      psKernelExprV2WhnfCacheFindInBefore entries arena source hash := by
  cases entries with
  | nil => rfl
  | cons first rest =>
      exact psKernelExprV2WhnfCacheFindWorker_eq_before
        (List.cons first rest) arena source hash

end PsKernelCacheScopeProofs

#print axioms PsKernelCacheScopeProofs.exit_scope_restores_all_caches
#print axioms PsKernelCacheScopeProofs.exit_scope_caches_independent_of_child
#print axioms PsKernelCacheScopeProofs.exit_scope_counter_exact
#print axioms PsKernelCacheScopeProofs.exit_scope_counter_ge_parent
#print axioms PsKernelCacheScopeProofs.exit_scope_counter_ge_child
#print axioms PsKernelCacheScopeProofs.exit_scope_counter_retains_monotone_child
#print axioms PsKernelCacheScopeProofs.semantic_eligible_iff_no_fvar_flag
#print axioms PsKernelCacheScopeProofs.semantic_fvar_ineligible
#print axioms PsKernelCacheScopeProofs.semantic_pair_eligible_iff_no_fvar_flags
#print axioms PsKernelCacheScopeProofs.inference_ineligible_of_fvar_flag

#print axioms PsKernelCacheScopeProofs.dag_whnf_starts_without_cache
#print axioms PsKernelCacheScopeProofs.dag_whnf_fvar_flag_prevents_lookup
#print axioms PsKernelCacheScopeProofs.dag_whnf_fvar_flag_prevents_publication

#print axioms PsKernelCacheScopeProofs.dag_whnf_starts_without_public_cache
#print axioms PsKernelCacheScopeProofs.dag_whnf_fvar_flag_prevents_public_lookup
#print axioms PsKernelCacheScopeProofs.dag_whnf_fvar_flag_prevents_public_publication

#print axioms PsKernelCacheScopeProofs.dag_quick_defeq_zero_fuel_precedes_syntax
#print axioms PsKernelCacheScopeProofs.dag_quick_defeq_depth_error_precedes_syntax

#print axioms PsKernelCacheScopeProofs.dag_whnf_declaration_initialization_has_no_core_cache
#print axioms PsKernelCacheScopeProofs.dag_whnf_declaration_initialization_has_no_public_cache
#print axioms PsKernelCacheScopeProofs.dag_whnf_arena_update_preserves_declaration_references

#print axioms PsKernelCacheScopeProofs.dag_check_scope_retains_child_arena
#print axioms PsKernelCacheScopeProofs.dag_check_scope_restores_semantic_caches
#print axioms PsKernelCacheScopeProofs.dag_check_scope_counter_exact
#print axioms PsKernelCacheScopeProofs.dag_check_starts_without_inference_cache
#print axioms PsKernelCacheScopeProofs.dag_check_fvar_flag_prevents_lookup
#print axioms PsKernelCacheScopeProofs.dag_check_fvar_flag_prevents_publication
#print axioms PsKernelCacheScopeProofs.dag_check_zero_fuel_precedes_cache
#print axioms PsKernelCacheScopeProofs.dag_check_depth_error_precedes_cached_judgment

#print axioms PsKernelCacheScopeProofs.constant_reference_factorization_preserves
#print axioms PsKernelCacheScopeProofs.constant_reference_factorization_extensional

#print axioms PsKernelCacheScopeProofs.dag_check_starts_without_success_cache
#print axioms PsKernelCacheScopeProofs.dag_check_scope_restores_success_cache
#print axioms PsKernelCacheScopeProofs.dag_check_arena_update_preserves_success_cache
#print axioms PsKernelCacheScopeProofs.dag_defeq_false_does_not_publish
#print axioms PsKernelCacheScopeProofs.dag_defeq_fvar_flag_prevents_pair_lookup
#print axioms PsKernelCacheScopeProofs.dag_defeq_fvar_flag_prevents_publication
#print axioms PsKernelCacheScopeProofs.dag_defeq_zero_fuel_precedes_success_cache
#print axioms PsKernelCacheScopeProofs.dag_defeq_depth_error_precedes_success_cache

#print axioms PsKernelCacheScopeProofs.dag_infer_only_update_preserves_checked_cache
#print axioms PsKernelCacheScopeProofs.dag_infer_only_scope_restores_parent_cache
#print axioms PsKernelCacheScopeProofs.dag_infer_only_starts_without_cache
#print axioms PsKernelCacheScopeProofs.dag_inference_fvar_flag_prevents_lookup
#print axioms PsKernelCacheScopeProofs.dag_inference_fvar_flag_prevents_publication
#print axioms PsKernelCacheScopeProofs.dag_infer_only_publication_preserves_checked_cache
#print axioms PsKernelCacheScopeProofs.dag_checked_publication_preserves_infer_only_cache
#print axioms PsKernelCacheScopeProofs.dag_inference_zero_fuel_precedes_cache
#print axioms PsKernelCacheScopeProofs.dag_inference_depth_error_precedes_cached_judgment

#print axioms PsKernelCacheScopeProofs.psKernelExprV2WhnfCacheFindWorker_eq_before
#print axioms PsKernelCacheScopeProofs.psKernelExprV2WhnfCacheFindIn_eq_before

#print axioms PsKernelCacheScopeProofs.inference_cache_eligibility_preserves
#print axioms PsKernelCacheScopeProofs.inference_cache_eligibility_extensional
