import Lean
import Ps.KernelCore.Runtime.Acceleration.CacheAnalysis

namespace PsKernelPackedCacheAnalysisProofs
private theorem mixed_hash_ne_marker (left right : Nat) :
    Nat.beq (psKernelCacheMix left right) psKernelCacheHashModulus = false := by
  have bound : psKernelCacheMix left right < psKernelCacheHashModulus :=
    Nat.mod_lt _ (by decide)
  have distinct : psKernelCacheMix left right ≠ psKernelCacheHashModulus := Nat.ne_of_lt bound
  simpa only [Nat.beq_eq_false] using distinct

theorem scalar_worker_decodes_to_exact_original_for_every_expression (expr : PsKernelExpr) :
    psKernelExprClosedCachePackedDecode (psKernelExprClosedCachePackedWorker expr) =
      psKernelExprClosedCacheAnalysis expr := by
  induction expr with
  | bvar index => simp [psKernelExprClosedCachePackedWorker,psKernelExprClosedCachePackedDecode,psKernelExprClosedCacheAnalysis,mixed_hash_ne_marker]
  | fvar name => simp [psKernelExprClosedCachePackedWorker,psKernelExprClosedCachePackedDecode,psKernelExprClosedCacheAnalysis,mixed_hash_ne_marker]
  | mvar name => simp [psKernelExprClosedCachePackedWorker,psKernelExprClosedCachePackedDecode,psKernelExprClosedCacheAnalysis,mixed_hash_ne_marker]
  | sort level => simp [psKernelExprClosedCachePackedWorker,psKernelExprClosedCachePackedDecode,psKernelExprClosedCacheAnalysis,mixed_hash_ne_marker]
  | const name levels => simp [psKernelExprClosedCachePackedWorker,psKernelExprClosedCachePackedDecode,psKernelExprClosedCacheAnalysis,mixed_hash_ne_marker]
  | lit value => simp [psKernelExprClosedCachePackedWorker,psKernelExprClosedCachePackedDecode,psKernelExprClosedCacheAnalysis,mixed_hash_ne_marker]
  | app fn arg ihFn ihArg =>
      simp only [psKernelExprClosedCachePackedWorker,psKernelExprClosedCacheAnalysis]
      rw [←ihFn, ←ihArg]
      cases flag0 : Nat.beq (psKernelExprClosedCachePackedWorker fn) psKernelCacheHashModulus <;>
      cases flag1 : Nat.beq (psKernelExprClosedCachePackedWorker arg) psKernelCacheHashModulus <;>
        simp [psKernelExprClosedCachePackedDecode,flag0,flag1,mixed_hash_ne_marker]
  | lam name domain body info ihDomain ihBody =>
      simp only [psKernelExprClosedCachePackedWorker,psKernelExprClosedCacheAnalysis]
      rw [←ihDomain, ←ihBody]
      cases flag0 : Nat.beq (psKernelExprClosedCachePackedWorker domain) psKernelCacheHashModulus <;>
      cases flag1 : Nat.beq (psKernelExprClosedCachePackedWorker body) psKernelCacheHashModulus <;>
        simp [psKernelExprClosedCachePackedDecode,flag0,flag1,mixed_hash_ne_marker]
  | forallE name domain body info ihDomain ihBody =>
      simp only [psKernelExprClosedCachePackedWorker,psKernelExprClosedCacheAnalysis]
      rw [←ihDomain, ←ihBody]
      cases flag0 : Nat.beq (psKernelExprClosedCachePackedWorker domain) psKernelCacheHashModulus <;>
      cases flag1 : Nat.beq (psKernelExprClosedCachePackedWorker body) psKernelCacheHashModulus <;>
        simp [psKernelExprClosedCachePackedDecode,flag0,flag1,mixed_hash_ne_marker]
  | letE name domain value body nondep ihDomain ihValue ihBody =>
      simp only [psKernelExprClosedCachePackedWorker,psKernelExprClosedCacheAnalysis]
      rw [←ihDomain, ←ihValue, ←ihBody]
      cases flag0 : Nat.beq (psKernelExprClosedCachePackedWorker domain) psKernelCacheHashModulus <;>
      cases flag1 : Nat.beq (psKernelExprClosedCachePackedWorker value) psKernelCacheHashModulus <;>
      cases flag2 : Nat.beq (psKernelExprClosedCachePackedWorker body) psKernelCacheHashModulus <;>
        simp [psKernelExprClosedCachePackedDecode,flag0,flag1,flag2,mixed_hash_ne_marker]
  | mdata tag body ihBody =>
      simp only [psKernelExprClosedCachePackedWorker,psKernelExprClosedCacheAnalysis]
      rw [←ihBody]
      cases flag0 : Nat.beq (psKernelExprClosedCachePackedWorker body) psKernelCacheHashModulus <;>
        simp [psKernelExprClosedCachePackedDecode,flag0,mixed_hash_ne_marker]
  | proj name index body ihBody =>
      simp only [psKernelExprClosedCachePackedWorker,psKernelExprClosedCacheAnalysis]
      rw [←ihBody]
      cases flag0 : Nat.beq (psKernelExprClosedCachePackedWorker body) psKernelCacheHashModulus <;>
        simp [psKernelExprClosedCachePackedDecode,flag0,mixed_hash_ne_marker]

theorem public_candidate_preserves_entire_original_pair (expr : PsKernelExpr) :
    psKernelExprClosedCachePackedAnalysis expr = psKernelExprClosedCacheAnalysis expr :=
  scalar_worker_decodes_to_exact_original_for_every_expression expr

end PsKernelPackedCacheAnalysisProofs
#print axioms PsKernelPackedCacheAnalysisProofs.scalar_worker_decodes_to_exact_original_for_every_expression
#print axioms PsKernelPackedCacheAnalysisProofs.public_candidate_preserves_entire_original_pair
