import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Runtime.Acceleration.Cache
import Lean

/- Retained production workers remain literal byte-preserved definitions.
   Equality covers arbitrary lists and arenas, including malformed
   references; it does not assert that malformed internal state is authorized. -/
namespace PsKernelCacheScan4Proofs
private theorem map_scheduler_equals_actual_original
    (scheduler : List (Prod PsKernelExpr PsKernelExpr))
    (expr : PsKernelExpr) (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprMapScanFour scheduler expr entries = psKernelExprMapGetIn expr entries := by
  induction scheduler generalizing entries with
  | nil => rfl
  | cons first rest ih =>
      cases entries with
      | nil => rfl
      | cons a as =>
        cases as with
        | nil => simp only [psKernelExprMapScanFour,psKernelExprMapGetIn]
        | cons b bs =>
          cases bs with
          | nil => simp only [psKernelExprMapScanFour,psKernelExprMapGetIn]
          | cons c cs =>
            cases cs with
            | nil => simp only [psKernelExprMapScanFour,psKernelExprMapGetIn]
            | cons d tail => simp only [psKernelExprMapScanFour,ih,psKernelExprMapGetIn]

private theorem whnf_scheduler_equals_actual_original
    (scheduler entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheScanFour scheduler entries arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  induction scheduler generalizing entries with
  | nil => rfl
  | cons first rest ih =>
      cases entries with
      | nil => rfl
      | cons a as =>
        cases as with
        | nil => simp only [psKernelExprV2WhnfCacheScanFour,psKernelExprV2WhnfCacheFindWorker]
        | cons b bs =>
          cases bs with
          | nil => simp only [psKernelExprV2WhnfCacheScanFour,psKernelExprV2WhnfCacheFindWorker]
          | cons c cs =>
            cases cs with
            | nil => simp only [psKernelExprV2WhnfCacheScanFour,psKernelExprV2WhnfCacheFindWorker]
            | cons d tail => simp only [psKernelExprV2WhnfCacheScanFour,ih,psKernelExprV2WhnfCacheFindWorker]

theorem map_scan_four_preserves_every_expression_list_and_order
    (expr : PsKernelExpr) (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprMapGetIn4 expr entries = psKernelExprMapGetIn expr entries :=
  map_scheduler_equals_actual_original entries expr entries

theorem whnf_scan_four_preserves_every_arena_error_hash_and_first_hit
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindWorker4 entries arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash :=
  whnf_scheduler_equals_actual_original entries entries arena source hash

#print axioms map_scan_four_preserves_every_expression_list_and_order
#print axioms whnf_scan_four_preserves_every_arena_error_hash_and_first_hit

theorem map_get_wrapper_preserves_small_and_all_index_bucket_shapes
    (cache : PsKernelExprMap) (expr : PsKernelExpr) :
    psKernelExprMapGet cache expr =
      (match cache.index with
       | none => psKernelExprMapGetIn expr cache.small
       | some index => psKernelExprMapGetIn expr
           (psKernelExprMapIndexBucket 16 index (psKernelExprHash expr))) := by
  cases h : cache.index with
  | none =>
      cases hs : cache.small <;> simp only [psKernelExprMapGet, h, hs,
        map_scan_four_preserves_every_expression_list_and_order, psKernelExprMapGetIn]
  | some index => simp only [psKernelExprMapGet, h, map_scan_four_preserves_every_expression_list_and_order]

theorem whnf_curried_wrapper_preserves_all_inputs_and_exact_errors
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindIn entries arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  cases entries <;> simp only [psKernelExprV2WhnfCacheFindIn, whnf_scan_four_preserves_every_arena_error_hash_and_first_hit] <;> rfl

#print axioms map_get_wrapper_preserves_small_and_all_index_bucket_shapes
#print axioms whnf_curried_wrapper_preserves_all_inputs_and_exact_errors
end PsKernelCacheScan4Proofs
