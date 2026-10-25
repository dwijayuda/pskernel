import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Runtime.Acceleration.Cache
import Lean

/- Retained production workers remain literal byte-preserved definitions.
   Equality covers arbitrary lists and arenas, including malformed
   references; it does not assert that malformed internal state is authorized. -/
namespace PsKernelCacheScan4Proofs
theorem map_scan_four_preserves_every_expression_list_and_order
    (expr : PsKernelExpr) (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprMapGetIn4 expr entries = psKernelExprMapGetIn expr entries := by
  have allLengths : ∀ n, ∀ (xs : List (Prod PsKernelExpr PsKernelExpr)),
      xs.length = n → ∀ query, psKernelExprMapGetIn4 query xs = psKernelExprMapGetIn query xs := by
    intro n
    induction n using Nat.strongRecOn with
    | ind n ih =>
      intro xs lengthEq query
      cases xs with
      | nil => rfl
      | cons a as =>
        cases as with
        | nil => rfl
        | cons b bs =>
          cases bs with
          | nil => rfl
          | cons c cs =>
            cases cs with
            | nil => rfl
            | cons d tail =>
              have smaller : tail.length < n := by simp_all; omega
              have recurse := ih tail.length smaller tail rfl query
              rw [psKernelExprMapGetIn4]
              simp only [recurse, psKernelExprMapGetIn]
  exact allLengths entries.length entries rfl expr

theorem whnf_scan_four_preserves_every_arena_error_hash_and_first_hit
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindWorker4 entries arena source hash = psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  have allLengths : ∀ n, ∀ (xs : List PsKernelExprV2WhnfCacheEntry), xs.length = n →
      ∀ owner root key, psKernelExprV2WhnfCacheFindWorker4 xs owner root key = psKernelExprV2WhnfCacheFindWorker xs owner root key := by
    intro n
    induction n using Nat.strongRecOn with
    | ind n ih =>
      intro xs lengthEq owner root key
      cases xs with
      | nil => simp only [psKernelExprV2WhnfCacheFindWorker4, psKernelExprV2WhnfCacheFindWorker]
      | cons a as =>
        cases as with
        | nil => simp only [psKernelExprV2WhnfCacheFindWorker4, psKernelExprV2WhnfCacheFindWorker]
        | cons b bs =>
          cases bs with
          | nil => simp only [psKernelExprV2WhnfCacheFindWorker4, psKernelExprV2WhnfCacheFindWorker]
          | cons c cs =>
            cases cs with
            | nil => simp only [psKernelExprV2WhnfCacheFindWorker4, psKernelExprV2WhnfCacheFindWorker]
            | cons d tail =>
              have smaller : tail.length < n := by simp_all; omega
              have recurse := ih tail.length smaller tail rfl owner root key
              rw [psKernelExprV2WhnfCacheFindWorker4]
              simp only [recurse, psKernelExprV2WhnfCacheFindWorker]
  exact allLengths entries.length entries rfl arena source hash

#print axioms map_scan_four_preserves_every_expression_list_and_order
#print axioms whnf_scan_four_preserves_every_arena_error_hash_and_first_hit

theorem map_get_wrapper_preserves_small_and_all_index_bucket_shapes
    (cache : PsKernelExprMap) (expr : PsKernelExpr) :
    psKernelExprMapGet cache expr =
      (match cache.index with
       | none => psKernelExprMapGetIn expr cache.small
       | some index => psKernelExprMapGetIn expr
           (psKernelExprMapIndexBucket 16 index (psKernelExprHash expr))) := by
  cases h : cache.index <;> simp only [psKernelExprMapGet, h, map_scan_four_preserves_every_expression_list_and_order]

theorem whnf_curried_wrapper_preserves_all_inputs_and_exact_errors
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindIn entries arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  cases entries <;> simp only [psKernelExprV2WhnfCacheFindIn, whnf_scan_four_preserves_every_arena_error_hash_and_first_hit] <;> rfl

#print axioms map_get_wrapper_preserves_small_and_all_index_bucket_shapes
#print axioms whnf_curried_wrapper_preserves_all_inputs_and_exact_errors
end PsKernelCacheScan4Proofs
