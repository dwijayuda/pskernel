import Ps.KernelCore.Core.Expr

/-
Non-semantic checker cache policy.

This module decides whether an inference result is worth memoizing. It does not
read or mutate checker state and must not change the inferred type or
accept/reject judgment.

Checked application nodes are intentionally not memoized. A cold checked spine
visits each node once, while memoizing every growing application tree can force
expensive structural hashing/promotion in the portable cache. Checked lambda
and forall nodes are likewise commonly one-shot in generated declaration and
recursor-rule validation. Infer-only application, lambda and forall results
remain memoized because whole-expression inference results are commonly reused.
-/

def psKernelInferCacheEligible
    (inferOnly : Bool)
    (expr : PsKernelExpr) :
    Bool :=
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

