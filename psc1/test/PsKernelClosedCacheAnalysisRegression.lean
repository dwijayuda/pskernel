import PsKernelPackedCacheAnalysisProofs
import Lean
import Ps.KernelCore.Runtime.Acceleration.CacheAnalysis

namespace PsKernelClosedCacheAnalysisRegression

/- These statements quantify over all expressions and all cache records,
   including raw caches containing ineligible entries. No cache invariant is
   assumed. The old eligibility guards remain part of each specification. -/

theorem analysis_eq (expr : PsKernelExpr) :
    psKernelExprClosedCacheAnalysis expr =
      if psKernelExprHasFVar expr then
        Prod.mk 0 true
      else
        Prod.mk (psKernelExprHash expr) false := by
  induction expr with
  | bvar index => rfl
  | fvar name => rfl
  | mvar name => rfl
  | sort level => rfl
  | const name levels => rfl
  | app fn arg ihFn ihArg =>
      cases hFn : psKernelExprHasFVar fn <;>
        cases hArg : psKernelExprHasFVar arg <;>
          simp [psKernelExprClosedCacheAnalysis, psKernelExprHasFVar,
            psKernelExprHash, ihFn, ihArg, hFn, hArg]
  | lam name type body binderInfo ihType ihBody =>
      cases hType : psKernelExprHasFVar type <;>
        cases hBody : psKernelExprHasFVar body <;>
          simp [psKernelExprClosedCacheAnalysis, psKernelExprHasFVar,
            psKernelExprHash, ihType, ihBody, hType, hBody]
  | forallE name type body binderInfo ihType ihBody =>
      cases hType : psKernelExprHasFVar type <;>
        cases hBody : psKernelExprHasFVar body <;>
          simp [psKernelExprClosedCacheAnalysis, psKernelExprHasFVar,
            psKernelExprHash, ihType, ihBody, hType, hBody]
  | letE name type value body nondep ihType ihValue ihBody =>
      cases hType : psKernelExprHasFVar type <;>
        cases hValue : psKernelExprHasFVar value <;>
          cases hBody : psKernelExprHasFVar body <;>
            simp [psKernelExprClosedCacheAnalysis, psKernelExprHasFVar,
              psKernelExprHash, ihType, ihValue, ihBody, hType, hValue, hBody]
  | lit literal => rfl
  | mdata metadata body ihBody =>
      cases hBody : psKernelExprHasFVar body <;>
        simp [psKernelExprClosedCacheAnalysis, psKernelExprHasFVar,
          psKernelExprHash, ihBody, hBody]
  | proj typeName index body ihBody =>
      cases hBody : psKernelExprHasFVar body <;>
        simp [psKernelExprClosedCacheAnalysis, psKernelExprHasFVar,
          psKernelExprHash, ihBody, hBody]

theorem semantic_map_get_eq
    (cache : PsKernelExprMap) (expr : PsKernelExpr) :
    psKernelSemanticExprMapGet cache expr =
      if psKernelSemanticCacheEligible expr then
        psKernelExprMapGet cache expr
      else
        Option.none := by
  rcases cache with ⟨small, index⟩
  cases index with
  | none =>
      cases small with
      | nil =>
          cases h : psKernelSemanticCacheEligible expr <;>
            simp [psKernelSemanticExprMapGet, psKernelExprMapGet,
              psKernelExprMapGetIn, h]
      | cons entry rest => rfl
  | some index =>
      cases h : psKernelExprHasFVar expr <;>
        simp [psKernelSemanticExprMapGet, PsKernelPackedCacheAnalysisProofs.public_candidate_preserves_entire_original_pair, analysis_eq,
          psKernelSemanticCacheEligible, psKernelExprMapGet, h]

theorem semantic_map_insert_eq
    (cache : PsKernelExprMap) (expr value : PsKernelExpr) :
    psKernelSemanticExprMapInsert cache expr value =
      if psKernelSemanticCacheEligible expr then
        Option.some (psKernelExprMapInsert cache expr value)
      else
        Option.none := by
  rcases cache with ⟨small, index⟩
  cases index with
  | none => rfl
  | some index =>
      cases h : psKernelExprHasFVar expr <;>
        simp [psKernelSemanticExprMapInsert, PsKernelPackedCacheAnalysisProofs.public_candidate_preserves_entire_original_pair, analysis_eq,
          psKernelSemanticCacheEligible, psKernelExprMapInsert, h]

theorem semantic_pair_contains_eq
    (set : PsKernelExprPairSet) (left right : PsKernelExpr) :
    psKernelSemanticExprPairSetContains set left right =
      if psKernelSemanticPairCacheEligible left right then
        psKernelExprPairSetContains set left right
      else
        false := by
  rcases set with ⟨small, index⟩
  cases index with
  | none => rfl
  | some index =>
      cases hLeft : psKernelExprHasFVar left <;>
        cases hRight : psKernelExprHasFVar right <;>
          simp [psKernelSemanticExprPairSetContains, PsKernelPackedCacheAnalysisProofs.public_candidate_preserves_entire_original_pair, analysis_eq,
            psKernelSemanticPairCacheEligible, psKernelSemanticCacheEligible,
            psKernelExprPairSetContains, psKernelExprPairHash, hLeft, hRight]

theorem semantic_pair_insert_eq
    (set : PsKernelExprPairSet) (left right : PsKernelExpr) :
    psKernelSemanticExprPairSetInsert set left right =
      if psKernelSemanticPairCacheEligible left right then
        Option.some (psKernelExprPairSetInsert set left right)
      else
        Option.none := by
  rcases set with ⟨small, index⟩
  cases index with
  | none => rfl
  | some index =>
      cases hLeft : psKernelExprHasFVar left <;>
        cases hRight : psKernelExprHasFVar right <;>
          simp [psKernelSemanticExprPairSetInsert, PsKernelPackedCacheAnalysisProofs.public_candidate_preserves_entire_original_pair, analysis_eq,
            psKernelSemanticPairCacheEligible, psKernelSemanticCacheEligible,
            psKernelExprPairSetInsert, psKernelExprPairHash, hLeft, hRight]
      split <;> simp_all

theorem infer_map_get_eq
    (cache : PsKernelExprMap) (inferOnly : Bool) (expr : PsKernelExpr) :
    psKernelInferCacheMapGet cache inferOnly expr =
      if psKernelInferCacheEligible inferOnly expr then
        psKernelExprMapGet cache expr
      else
        Option.none := by
  cases expr <;> cases inferOnly <;>
    first
    | rfl
    | apply semantic_map_get_eq

theorem infer_map_insert_eq
    (cache : PsKernelExprMap) (inferOnly : Bool) (expr value : PsKernelExpr) :
    psKernelInferCacheMapInsert cache inferOnly expr value =
      if psKernelInferCacheEligible inferOnly expr then
        Option.some (psKernelExprMapInsert cache expr value)
      else
        Option.none := by
  cases expr <;> cases inferOnly <;>
    first
    | rfl
    | apply semantic_map_insert_eq

#print axioms analysis_eq
#print axioms semantic_map_get_eq
#print axioms semantic_map_insert_eq
#print axioms semantic_pair_contains_eq
#print axioms semantic_pair_insert_eq
#print axioms infer_map_get_eq
#print axioms infer_map_insert_eq

end PsKernelClosedCacheAnalysisRegression

