import Ps.KernelCore.Runtime.Acceleration.Cache
import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/- Analyze eligibility and its index hash together. A true second component
   excludes the expression from semantic caches; its zero hash is unused.
   Children are visited in the original HasFVar order, stopping at the first
   free variable. Hashes remain hints and never authorize equality. -/
def psKernelExprClosedCacheAnalysis
    (expr : PsKernelExpr) :
    Prod Nat Bool :=
  match expr with
  | PsKernelExpr.bvar index =>
      Prod.mk (psKernelCacheMix 21 index) false
  | PsKernelExpr.fvar _ =>
      Prod.mk 0 true
  | PsKernelExpr.mvar name =>
      Prod.mk
        (psKernelCacheMix 23 (psKernelCacheNameHash name))
        false
  | PsKernelExpr.sort level =>
      Prod.mk
        (psKernelCacheMix 24 (psKernelCacheLevelHash level))
        false
  | PsKernelExpr.const name levels =>
      Prod.mk
        (psKernelCacheMix
          (psKernelCacheMix 25 (psKernelCacheNameHash name))
          (psKernelCacheLevelListHash levels))
        false
  | PsKernelExpr.app fn arg =>
      let fnAnalysis := psKernelExprClosedCacheAnalysis fn;
      if Prod.snd fnAnalysis then
        Prod.mk 0 true
      else
        let argAnalysis := psKernelExprClosedCacheAnalysis arg;
        if Prod.snd argAnalysis then
          Prod.mk 0 true
        else
          Prod.mk
            (psKernelCacheMix
              (psKernelCacheMix 26 (Prod.fst fnAnalysis))
              (Prod.fst argAnalysis))
            false
  | PsKernelExpr.lam _ type body _ =>
      let typeAnalysis := psKernelExprClosedCacheAnalysis type;
      if Prod.snd typeAnalysis then
        Prod.mk 0 true
      else
        let bodyAnalysis := psKernelExprClosedCacheAnalysis body;
        if Prod.snd bodyAnalysis then
          Prod.mk 0 true
        else
          Prod.mk
            (psKernelCacheMix
              (psKernelCacheMix 27 (Prod.fst typeAnalysis))
              (Prod.fst bodyAnalysis))
            false
  | PsKernelExpr.forallE _ type body _ =>
      let typeAnalysis := psKernelExprClosedCacheAnalysis type;
      if Prod.snd typeAnalysis then
        Prod.mk 0 true
      else
        let bodyAnalysis := psKernelExprClosedCacheAnalysis body;
        if Prod.snd bodyAnalysis then
          Prod.mk 0 true
        else
          Prod.mk
            (psKernelCacheMix
              (psKernelCacheMix 28 (Prod.fst typeAnalysis))
              (Prod.fst bodyAnalysis))
            false
  | PsKernelExpr.letE _ type value body nondep =>
      let typeAnalysis := psKernelExprClosedCacheAnalysis type;
      if Prod.snd typeAnalysis then
        Prod.mk 0 true
      else
        let valueAnalysis := psKernelExprClosedCacheAnalysis value;
        if Prod.snd valueAnalysis then
          Prod.mk 0 true
        else
          let bodyAnalysis := psKernelExprClosedCacheAnalysis body;
          if Prod.snd bodyAnalysis then
            Prod.mk 0 true
          else
            let flag := if nondep then 1 else 0;
            Prod.mk
              (psKernelCacheMix
                (psKernelCacheMix
                  (psKernelCacheMix
                    (psKernelCacheMix 29 (Prod.fst typeAnalysis))
                    (Prod.fst valueAnalysis))
                  (Prod.fst bodyAnalysis))
                flag)
              false
  | PsKernelExpr.lit literal =>
      Prod.mk
        (psKernelCacheMix 30 (psKernelCacheLiteralHash literal))
        false
  | PsKernelExpr.mdata metadata body =>
      let bodyAnalysis := psKernelExprClosedCacheAnalysis body;
      if Prod.snd bodyAnalysis then
        Prod.mk 0 true
      else
        Prod.mk
          (psKernelCacheMix
            (psKernelCacheMix 31 metadata)
            (Prod.fst bodyAnalysis))
          false
  | PsKernelExpr.proj typeName index body =>
      let bodyAnalysis := psKernelExprClosedCacheAnalysis body;
      if Prod.snd bodyAnalysis then
        Prod.mk 0 true
      else
        Prod.mk
          (psKernelCacheMix
            (psKernelCacheMix
              (psKernelCacheMix 32 (psKernelCacheNameHash typeName))
              index)
            (Prod.fst bodyAnalysis))
          false

/- Nonempty small caches retain their original eligibility scan and promotion path.
   Indexed caches share the scan/hash traversal and retain exact collisions. -/
def psKernelSemanticExprMapGet
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  match cache.index with
  | Option.none =>
      match cache.small with
      | List.nil => Option.none
      | List.cons _ _ =>
          if psKernelSemanticCacheEligible expr then
            psKernelExprMapGetIn4 expr cache.small
          else
            Option.none
  | Option.some index =>
      let analysis := psKernelExprClosedCacheAnalysis expr;
      if Prod.snd analysis then
        Option.none
      else
        psKernelExprMapGetIn4
          expr
          (psKernelExprMapIndexBucket 16 index (Prod.fst analysis))

/- None means ineligible, so the checker can return its original state object
   without constructing a replacement or publishing any cache update. -/
def psKernelSemanticExprMapInsert
    (cache : PsKernelExprMap)
    (expr : PsKernelExpr)
    (value : PsKernelExpr) :
    Option PsKernelExprMap :=
  match cache.index with
  | Option.none =>
      if psKernelSemanticCacheEligible expr then
        Option.some (psKernelExprMapInsert cache expr value)
      else
        Option.none
  | Option.some index =>
      let analysis := psKernelExprClosedCacheAnalysis expr;
      if Prod.snd analysis then
        Option.none
      else
        let hash := Prod.fst analysis;
        let bucket := psKernelExprMapIndexBucket 16 index hash;
        let nextCache : PsKernelExprMap :=
          {
            small := List.nil
            index :=
              Option.some
                (psKernelExprMapIndexSet
                  16
                  index
                  hash
                  (psKernelExprMapInsertIn expr value bucket))
          };
        Option.some nextCache

def psKernelSemanticExprPairSetContains
    (set : PsKernelExprPairSet)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Bool :=
  match set.index with
  | Option.none =>
      if psKernelSemanticPairCacheEligible left right then
        psKernelExprPairSetContainsIn left right set.small
      else
        false
  | Option.some index =>
      let leftAnalysis := psKernelExprClosedCacheAnalysis left;
      if Prod.snd leftAnalysis then
        false
      else
        let rightAnalysis := psKernelExprClosedCacheAnalysis right;
        if Prod.snd rightAnalysis then
          false
        else
          let hash :=
            Nat.mod
              (Nat.add (Prod.fst leftAnalysis) (Prod.fst rightAnalysis))
              psKernelCacheHashModulus;
          psKernelExprPairSetContainsIn
            left
            right
            (psKernelExprPairSetIndexBucket 16 index hash)

def psKernelSemanticExprPairSetInsert
    (set : PsKernelExprPairSet)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Option PsKernelExprPairSet :=
  match set.index with
  | Option.none =>
      if psKernelSemanticPairCacheEligible left right then
        Option.some (psKernelExprPairSetInsert set left right)
      else
        Option.none
  | Option.some index =>
      let leftAnalysis := psKernelExprClosedCacheAnalysis left;
      if Prod.snd leftAnalysis then
        Option.none
      else
        let rightAnalysis := psKernelExprClosedCacheAnalysis right;
        if Prod.snd rightAnalysis then
          Option.none
        else
          let hash :=
            Nat.mod
              (Nat.add (Prod.fst leftAnalysis) (Prod.fst rightAnalysis))
              psKernelCacheHashModulus;
          let bucket := psKernelExprPairSetIndexBucket 16 index hash;
          if psKernelExprPairSetContainsIn left right bucket then
            Option.some set
          else
            let nextSet : PsKernelExprPairSet :=
              {
                small := List.nil
                index :=
                  Option.some
                    (psKernelExprPairSetIndexSet
                      16
                      index
                      hash
                      (List.cons (Prod.mk left right) bucket))
              };
            Option.some nextSet

/- Preserve the inference policy's early node-kind gate before any scan/hash. -/
def psKernelInferCacheMapGet
    (cache : PsKernelExprMap)
    (inferOnly : Bool)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  match expr with
  | PsKernelExpr.lit _ =>
      Option.none
  | PsKernelExpr.app _ _ =>
      if inferOnly then psKernelSemanticExprMapGet cache expr else Option.none
  | PsKernelExpr.lam _ _ _ _ =>
      if inferOnly then psKernelSemanticExprMapGet cache expr else Option.none
  | PsKernelExpr.forallE _ _ _ _ =>
      if inferOnly then psKernelSemanticExprMapGet cache expr else Option.none
  | _ =>
      psKernelSemanticExprMapGet cache expr

def psKernelInferCacheMapInsert
    (cache : PsKernelExprMap)
    (inferOnly : Bool)
    (expr : PsKernelExpr)
    (value : PsKernelExpr) :
    Option PsKernelExprMap :=
  match expr with
  | PsKernelExpr.lit _ =>
      Option.none
  | PsKernelExpr.app _ _ =>
      if inferOnly then
        psKernelSemanticExprMapInsert cache expr value
      else
        Option.none
  | PsKernelExpr.lam _ _ _ _ =>
      if inferOnly then
        psKernelSemanticExprMapInsert cache expr value
      else
        Option.none
  | PsKernelExpr.forallE _ _ _ _ =>
      if inferOnly then
        psKernelSemanticExprMapInsert cache expr value
      else
        Option.none
  | _ =>
      psKernelSemanticExprMapInsert cache expr value

