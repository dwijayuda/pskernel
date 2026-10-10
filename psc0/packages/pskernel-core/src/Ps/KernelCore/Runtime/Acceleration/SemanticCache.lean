import Ps.KernelCore.Runtime.Acceleration.Cache

/-!
One explicit policy controls all semantic memoization. It changes no typing,
reduction, admission, or resource-exhaustion rule. The reference policy ignores
even pre-populated caches and does not publish results. Structural sharing and
its proved compiler simplifications remain available under either policy.

The instance argument is passed through the entire checker/admission call graph.
API.Reference fixes it explicitly; the default preserves the existing cached API.
-/
class PsKernelSemanticCachePolicy where
  enabled : Bool

instance psKernelCachedCachePolicy : PsKernelSemanticCachePolicy := ⟨true⟩

def psKernelReferenceCachePolicy : PsKernelSemanticCachePolicy := ⟨false⟩

@[inline] abbrev psKernelSemanticCacheGet [policy : PsKernelSemanticCachePolicy]
    (cache : PsKernelExprMap) (expr : PsKernelExpr) : Option PsKernelExpr :=
  if policy.enabled then psKernelExprMapGet cache expr else none

@[inline] abbrev psKernelSemanticCacheInsert [policy : PsKernelSemanticCachePolicy]
    (cache : PsKernelExprMap) (expr value : PsKernelExpr) : PsKernelExprMap :=
  if policy.enabled then psKernelExprMapInsert cache expr value else cache

@[inline] abbrev psKernelSemanticCacheContains [policy : PsKernelSemanticCachePolicy]
    (cache : PsKernelExprPairSet) (left right : PsKernelExpr) : Bool :=
  if policy.enabled then psKernelExprPairSetContains cache left right else false

@[inline] abbrev psKernelSemanticCacheInsertPair [policy : PsKernelSemanticCachePolicy]
    (cache : PsKernelExprPairSet) (left right : PsKernelExpr) : PsKernelExprPairSet :=
  if policy.enabled then psKernelExprPairSetInsert cache left right else cache

@[simp] theorem psKernelReferenceCacheGet_miss (cache : PsKernelExprMap) (e : PsKernelExpr) :
    @psKernelSemanticCacheGet psKernelReferenceCachePolicy cache e = none := rfl

@[simp] theorem psKernelReferenceCacheInsert_noop
    (cache : PsKernelExprMap) (e v : PsKernelExpr) :
    @psKernelSemanticCacheInsert psKernelReferenceCachePolicy cache e v = cache := rfl

@[simp] theorem psKernelReferenceCacheContains_miss
    (cache : PsKernelExprPairSet) (e v : PsKernelExpr) :
    @psKernelSemanticCacheContains psKernelReferenceCachePolicy cache e v = false := rfl

@[simp] theorem psKernelReferenceCacheInsertPair_noop
    (cache : PsKernelExprPairSet) (e v : PsKernelExpr) :
    @psKernelSemanticCacheInsertPair psKernelReferenceCachePolicy cache e v = cache := rfl
