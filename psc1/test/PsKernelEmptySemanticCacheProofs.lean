import PsKernelCacheScan4Proofs
import Lean
import Ps.KernelCore.Runtime.Acceleration.CacheAnalysis

namespace PsKernelEmptySemanticCacheProofs

/- Frozen from ae47's complete CacheAnalysis.lean Git blob
   4d5ca3d8e2a6136d5fcb35dec131e5c28e6b743b.
   The preflight must compare this body to that authenticated predecessor.
   Both equations quantify over arbitrary typed expressions; the first also
   quantifies over arbitrary raw caches, including seeded open entries. -/
namespace Frozen

def psKernelSemanticExprMapGet
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  match cache.index with
  | Option.none =>
      if psKernelSemanticCacheEligible expr then
        psKernelExprMapGetIn expr cache.small
      else
        Option.none
  | Option.some index =>
      let analysis := psKernelExprClosedCacheAnalysis expr;
      if Prod.snd analysis then
        Option.none
      else
        psKernelExprMapGetIn
          expr
          (psKernelExprMapIndexBucket 16 index (Prod.fst analysis))

end Frozen

theorem semantic_map_get_eq_before
    (cache : PsKernelExprMap) (expr : PsKernelExpr) :
    psKernelSemanticExprMapGet cache expr =
      Frozen.psKernelSemanticExprMapGet cache expr := by
  rcases cache with ⟨small, index⟩
  cases index with
  | none =>
      cases small with
      | nil =>
          cases h : psKernelSemanticCacheEligible expr <;>
            simp [psKernelSemanticExprMapGet,
              Frozen.psKernelSemanticExprMapGet, psKernelExprMapGetIn, h]
      | cons entry rest =>
          simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,
            PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]
  | some index =>
      simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,
        PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]

theorem empty_lookup_ignores_expression (expr : PsKernelExpr) :
    psKernelSemanticExprMapGet
      (PsKernelExprMap.mk List.nil Option.none) expr = Option.none := by
  rfl

end PsKernelEmptySemanticCacheProofs

#print axioms PsKernelEmptySemanticCacheProofs.semantic_map_get_eq_before
#print axioms PsKernelEmptySemanticCacheProofs.empty_lookup_ignores_expression
