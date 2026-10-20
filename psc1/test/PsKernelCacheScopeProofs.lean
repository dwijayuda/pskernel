import Init.Data.Nat.MinMax
import Ps.KernelCore.Checker.State
import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/-!
Exact local cache restoration and eligibility facts for arbitrary states.
This does not establish validity of stored judgments, FVar scanner completeness,
proper use of scope exit at every call site, or whole-kernel soundness.
Native proof material is outside the portable executable source closure.
-/
namespace PsKernelCacheScopeProofs

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

theorem inference_ineligible_of_fvar_flag
    (inferOnly : Bool) (expr : PsKernelExpr) (flag : psKernelExprHasFVar expr = true) :
    psKernelInferCacheEligible inferOnly expr = false := by
  simp [psKernelInferCacheEligible, psKernelSemanticCacheEligible, flag]

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
