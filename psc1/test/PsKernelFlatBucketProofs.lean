import Lean
import Ps.KernelCore.Runtime.Acceleration.Cache

namespace PsKernelFlatBucketProofs

private def originalMapBucket
    (fuel : Nat) :
    PsKernelExprMapIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelExprMapIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelExprMapIndex.bucket entries =>
            entries
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprMapIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) :=
        originalMapBucket remaining;
      fun
        (index : PsKernelExprMapIndex)
        (hash : Nat) =>
        match index with
        | PsKernelExprMapIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil


private def originalPairBucket
    (fuel : Nat) :
    PsKernelExprPairSetIndex ->
    Nat ->
    List (Prod PsKernelExpr PsKernelExpr) :=
  match fuel with
  | Nat.zero =>
      fun
        (index : PsKernelExprPairSetIndex)
        (_hash : Nat) =>
        match index with
        | PsKernelExprPairSetIndex.bucket entries =>
            entries
        | _ =>
            List.nil
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprPairSetIndex ->
          Nat ->
          List (Prod PsKernelExpr PsKernelExpr) :=
        originalPairBucket remaining;
      fun
        (index : PsKernelExprPairSetIndex)
        (hash : Nat) =>
        match index with
        | PsKernelExprPairSetIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then
              smaller
                left
                (Nat.div hash 2)
            else
              smaller
                right
                (Nat.div hash 2)
        | _ =>
            List.nil


theorem map_worker_exact_original_all_fuel
    (fuel : Nat) (index : PsKernelExprMapIndex) (hash : Nat) :
    psKernelExprMapIndexBucketWorker fuel index hash = originalMapBucket fuel index hash := by
  induction fuel generalizing index hash with
  | zero => rfl
  | succ remaining ih =>
      cases index <;> simp [psKernelExprMapIndexBucketWorker,originalMapBucket,ih]

theorem map_public_curried_abi_exact_original
    (fuel : Nat) (index : PsKernelExprMapIndex) (hash : Nat) :
    psKernelExprMapIndexBucket fuel index hash = originalMapBucket fuel index hash := by
  cases fuel with
  | zero => exact map_worker_exact_original_all_fuel 0 index hash
  | succ remaining => exact map_worker_exact_original_all_fuel (Nat.succ remaining) index hash

theorem map_premature_bucket_preserves_original_budget_semantics
    (remaining hash : Nat) (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprMapIndexBucketWorker (Nat.succ remaining) (PsKernelExprMapIndex.bucket entries) hash = List.nil := rfl

theorem pair_worker_exact_original_all_fuel
    (fuel : Nat) (index : PsKernelExprPairSetIndex) (hash : Nat) :
    psKernelExprPairSetIndexBucketWorker fuel index hash = originalPairBucket fuel index hash := by
  induction fuel generalizing index hash with
  | zero => rfl
  | succ remaining ih =>
      cases index <;> simp [psKernelExprPairSetIndexBucketWorker,originalPairBucket,ih]

theorem pair_public_curried_abi_exact_original
    (fuel : Nat) (index : PsKernelExprPairSetIndex) (hash : Nat) :
    psKernelExprPairSetIndexBucket fuel index hash = originalPairBucket fuel index hash := by
  cases fuel with
  | zero => exact pair_worker_exact_original_all_fuel 0 index hash
  | succ remaining => exact pair_worker_exact_original_all_fuel (Nat.succ remaining) index hash

theorem pair_premature_bucket_preserves_original_budget_semantics
    (remaining hash : Nat) (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprPairSetIndexBucketWorker (Nat.succ remaining) (PsKernelExprPairSetIndex.bucket entries) hash = List.nil := rfl

end PsKernelFlatBucketProofs
#print axioms PsKernelFlatBucketProofs.map_worker_exact_original_all_fuel
#print axioms PsKernelFlatBucketProofs.map_public_curried_abi_exact_original
#print axioms PsKernelFlatBucketProofs.map_premature_bucket_preserves_original_budget_semantics
#print axioms PsKernelFlatBucketProofs.pair_worker_exact_original_all_fuel
#print axioms PsKernelFlatBucketProofs.pair_public_curried_abi_exact_original
#print axioms PsKernelFlatBucketProofs.pair_premature_bucket_preserves_original_budget_semantics
