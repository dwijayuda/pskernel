import Lean
import Ps.KernelCore.Checker.ExprV2.WhnfCache

/-!
Exact local cache-index laws. The complete Nat hash and original structural
scanner remain authoritative. These statements cover arbitrary hashes, arbitrary
candidate records, malformed arena lookups, duplicate publications and the first
collision error. They do not assume arena validation or prove kernel soundness.
-/
namespace PsKernelExprV2WhnfCacheProofs

/- Frozen functions are copied from WhnfCache.lean at
   5deaf5880c83a76290520fa1176982dab0bf87a5 with identifiers renamed only. -/
def originalIndexBucket
    (levels : Nat) :
    PsKernelExprV2WhnfCacheIndex -> Nat -> List PsKernelExprV2WhnfCacheEntry :=
  match levels with
  | Nat.zero =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (_hash : Nat) =>
        match index with
        | PsKernelExprV2WhnfCacheIndex.bucket entries => entries
        | _ => List.nil
  | Nat.succ remaining =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat) =>
        match index with
        | PsKernelExprV2WhnfCacheIndex.branch left right =>
            let worker := originalIndexBucket remaining;
            if Nat.beq (Nat.mod hash 2) 0 then worker left (Nat.div hash 2)
            else worker right (Nat.div hash 2)
        | _ => List.nil

def originalIndexSet
    (levels : Nat) :
    PsKernelExprV2WhnfCacheIndex -> Nat -> List PsKernelExprV2WhnfCacheEntry ->
    PsKernelExprV2WhnfCacheIndex :=
  match levels with
  | Nat.zero =>
      fun (_index : PsKernelExprV2WhnfCacheIndex) (_hash : Nat)
          (entries : List PsKernelExprV2WhnfCacheEntry) =>
        PsKernelExprV2WhnfCacheIndex.bucket entries
  | Nat.succ remaining =>
      fun (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat)
          (entries : List PsKernelExprV2WhnfCacheEntry) =>
        let left : PsKernelExprV2WhnfCacheIndex :=
          match index with
          | PsKernelExprV2WhnfCacheIndex.branch value _ => value
          | _ => PsKernelExprV2WhnfCacheIndex.empty;
        let right : PsKernelExprV2WhnfCacheIndex :=
          match index with
          | PsKernelExprV2WhnfCacheIndex.branch _ value => value
          | _ => PsKernelExprV2WhnfCacheIndex.empty;
        let worker := originalIndexSet remaining;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsKernelExprV2WhnfCacheIndex.branch
            (worker left (Nat.div hash 2) entries) right
        else
          PsKernelExprV2WhnfCacheIndex.branch
            left (worker right (Nat.div hash 2) entries)

theorem bucket_worker_exact
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat) :
    psKernelExprV2WhnfCacheIndexBucketWorker levels index hash =
      originalIndexBucket levels index hash := by
  induction levels generalizing index hash with
  | zero => rfl
  | succ remaining ih =>
      cases index <;>
        cases bit : Nat.beq (Nat.mod hash 2) 0 <;>
        simp [psKernelExprV2WhnfCacheIndexBucketWorker, originalIndexBucket, bit, ih]

theorem set_worker_exact
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat)
    (entries : List PsKernelExprV2WhnfCacheEntry) :
    psKernelExprV2WhnfCacheIndexSetWorker levels index hash entries =
      originalIndexSet levels index hash entries := by
  induction levels generalizing index hash with
  | zero => rfl
  | succ remaining ih =>
      cases index <;>
        cases bit : Nat.beq (Nat.mod hash 2) 0 <;>
        simp [psKernelExprV2WhnfCacheIndexSetWorker, originalIndexSet, bit, ih]

theorem bucket_public_exact
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat) :
    psKernelExprV2WhnfCacheIndexBucket levels index hash =
      originalIndexBucket levels index hash := by
  cases levels with
  | zero => rfl
  | succ remaining => exact bucket_worker_exact (Nat.succ remaining) index hash

theorem set_public_exact
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat)
    (entries : List PsKernelExprV2WhnfCacheEntry) :
    psKernelExprV2WhnfCacheIndexSet levels index hash entries =
      originalIndexSet levels index hash entries := by
  cases levels with
  | zero => rfl
  | succ remaining => exact set_worker_exact (Nat.succ remaining) index hash entries

theorem bucket_worker_public
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat) :
    psKernelExprV2WhnfCacheIndexBucketWorker levels index hash =
      psKernelExprV2WhnfCacheIndexBucket levels index hash := by
  exact (bucket_worker_exact levels index hash).trans
    (bucket_public_exact levels index hash).symm

theorem set_worker_public
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (hash : Nat)
    (entries : List PsKernelExprV2WhnfCacheEntry) :
    psKernelExprV2WhnfCacheIndexSetWorker levels index hash entries =
      psKernelExprV2WhnfCacheIndexSet levels index hash entries := by
  exact (set_worker_exact levels index hash entries).trans
    (set_public_exact levels index hash entries).symm

theorem bucket_partial_application_exact (levels : Nat) :
    psKernelExprV2WhnfCacheIndexBucket levels = originalIndexBucket levels := by
  funext index hash
  exact bucket_public_exact levels index hash

theorem set_partial_application_exact (levels : Nat) :
    psKernelExprV2WhnfCacheIndexSet levels = originalIndexSet levels := by
  funext index hash entries
  exact set_public_exact levels index hash entries

private theorem original_bucket_empty (levels hash : Nat) :
    originalIndexBucket levels .empty hash = [] := by
  cases levels <;> rfl

private def routeEq (levels left right : Nat) : Bool :=
  match levels with
  | 0 => true
  | Nat.succ remaining =>
      if Nat.beq (Nat.mod left 2) 0 then
        if Nat.beq (Nat.mod right 2) 0 then
          routeEq remaining (Nat.div left 2) (Nat.div right 2)
        else false
      else
        if Nat.beq (Nat.mod right 2) 0 then false
        else routeEq remaining (Nat.div left 2) (Nat.div right 2)

private def filterHash
    (hash : Nat) (entries : List PsKernelExprV2WhnfCacheEntry) :
    List PsKernelExprV2WhnfCacheEntry :=
  match entries with
  | [] => []
  | first :: rest =>
      if Nat.beq first.hash hash then first :: filterHash hash rest
      else filterHash hash rest

theorem route_reflexive (levels hash : Nat) :
    routeEq levels hash hash = true := by
  induction levels generalizing hash with
  | zero => rfl
  | succ remaining ih =>
      cases bit : Nat.beq (Nat.mod hash 2) 0 <;>
        simp [routeEq, bit, ih]

private theorem bucket_empty (levels hash : Nat) :
    psKernelExprV2WhnfCacheIndexBucket levels .empty hash = [] := by
  cases levels <;> rfl

theorem index_bucket_set
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex)
    (key query : Nat) (entries : List PsKernelExprV2WhnfCacheEntry) :
    psKernelExprV2WhnfCacheIndexBucket levels
        (psKernelExprV2WhnfCacheIndexSet levels index key entries) query =
      if routeEq levels key query then entries
      else psKernelExprV2WhnfCacheIndexBucket levels index query := by
  simp only [bucket_public_exact, set_public_exact]
  induction levels generalizing index key query with
  | zero => rfl
  | succ remaining ih =>
      cases index <;>
        cases keyBit : Nat.beq (Nat.mod key 2) 0 <;>
        cases queryBit : Nat.beq (Nat.mod query 2) 0 <;>
        simp [originalIndexSet,
          originalIndexBucket, routeEq, keyBit, queryBit, ih, original_bucket_empty]

theorem index_bucket_same_route
    (levels : Nat) (index : PsKernelExprV2WhnfCacheIndex) (key query : Nat)
    (same : routeEq levels key query = true) :
    psKernelExprV2WhnfCacheIndexBucket levels index key =
      psKernelExprV2WhnfCacheIndexBucket levels index query := by
  simp only [bucket_public_exact]
  induction levels generalizing index key query with
  | zero => rfl
  | succ remaining ih =>
      cases index with
      | empty => rfl
      | bucket entries => rfl
      | branch left right =>
          cases keyBit : Nat.beq (Nat.mod key 2) 0 <;>
            cases queryBit : Nat.beq (Nat.mod query 2) 0 <;>
            simp [routeEq, keyBit, queryBit] at same
          · simpa [originalIndexBucket, keyBit, queryBit] using
              ih right (Nat.div key 2) (Nat.div query 2) same
          · simpa [originalIndexBucket, keyBit, queryBit] using
              ih left (Nat.div key 2) (Nat.div query 2) same

theorem index_bucket_insert
    (index : PsKernelExprV2WhnfCacheIndex)
    (entry : PsKernelExprV2WhnfCacheEntry) (hash : Nat) :
    psKernelExprV2WhnfCacheIndexBucket 16
        (psKernelExprV2WhnfCacheIndexInsert index entry) hash =
      if routeEq 16 entry.hash hash then
        List.cons entry (psKernelExprV2WhnfCacheIndexBucket 16 index hash)
      else psKernelExprV2WhnfCacheIndexBucket 16 index hash := by
  unfold psKernelExprV2WhnfCacheIndexInsert
  change psKernelExprV2WhnfCacheIndexBucket 16
      (psKernelExprV2WhnfCacheIndexSet 16 index entry.hash
        (List.cons entry (psKernelExprV2WhnfCacheIndexBucket 16 index entry.hash))) hash = _
  rw [index_bucket_set]
  cases routed : routeEq 16 entry.hash hash with
  | false => simp [routed]
  | true =>
      have same := index_bucket_same_route 16 index entry.hash hash routed
      simp [routed, same]

theorem index_insert_exact_filter
    (index : PsKernelExprV2WhnfCacheIndex)
    (entry : PsKernelExprV2WhnfCacheEntry) (hash : Nat) :
    filterHash hash
        (psKernelExprV2WhnfCacheIndexBucket 16
          (psKernelExprV2WhnfCacheIndexInsert index entry) hash) =
      filterHash hash
        (List.cons entry (psKernelExprV2WhnfCacheIndexBucket 16 index hash)) := by
  rw [index_bucket_insert]
  cases routed : routeEq 16 entry.hash hash with
  | true => simp [routed]
  | false =>
      have different : entry.hash ≠ hash := by
        intro equal
        subst hash
        have yes := route_reflexive 16 entry.hash
        rw [yes] at routed
        cases routed
      simp [routed, filterHash, different]

theorem index_build_exact_filter
    (entries : List PsKernelExprV2WhnfCacheEntry) (hash : Nat) :
    filterHash hash
        (psKernelExprV2WhnfCacheIndexBucket 16
          (psKernelExprV2WhnfCacheIndexBuild entries) hash) =
      filterHash hash entries := by
  induction entries with
  | nil => rfl
  | cons first rest ih =>
      simp only [psKernelExprV2WhnfCacheIndexBuild]
      rw [index_insert_exact_filter]
      simp [filterHash, ih]

theorem scanner_filtered_exact
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindWorker (filterHash hash entries) arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  induction entries with
  | nil => rfl
  | cons first rest ih =>
      cases hashEqual : Nat.beq first.hash hash with
      | false =>
          have different : first.hash ≠ hash := by
            intro equal
            have yes : Nat.beq first.hash hash = true := by simpa using equal
            rw [yes] at hashEqual
            cases hashEqual
          simpa [filterHash, psKernelExprV2WhnfCacheFindWorker,
            hashEqual, different] using ih
      | true =>
          have equal : first.hash = hash := by simpa using hashEqual
          cases compared :
              psKernelExprV2PagedEqOnCanonical arena first.source source with
          | error error =>
              simp [filterHash, psKernelExprV2WhnfCacheFindWorker,
                hashEqual, equal, compared]
          | ok answer =>
              cases answer <;>
                simp [filterHash, psKernelExprV2WhnfCacheFindWorker,
                  hashEqual, equal, compared, ih]

theorem index_scan_exact
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheFindWorker
        (psKernelExprV2WhnfCacheIndexBucket 16
          (psKernelExprV2WhnfCacheIndexBuild entries) hash) arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  rw [← scanner_filtered_exact
    (psKernelExprV2WhnfCacheIndexBucket 16
      (psKernelExprV2WhnfCacheIndexBuild entries) hash) arena source hash]
  rw [index_build_exact_filter]
  exact scanner_filtered_exact entries arena source hash

theorem cache_insert_exact_filter
    (cache : PsKernelExprV2WhnfCache)
    (entry : PsKernelExprV2WhnfCacheEntry) (hash : Nat) :
    filterHash hash
        (psKernelExprV2WhnfCacheBucket
          (psKernelExprV2WhnfCacheInsert cache entry) hash) =
      filterHash hash
        (List.cons entry (psKernelExprV2WhnfCacheBucket cache hash)) := by
  cases cache with
  | mk small index =>
      cases index with
      | none =>
          simp only [psKernelExprV2WhnfCacheInsert]
          split
          · rfl
          · exact index_build_exact_filter (List.cons entry small) hash
      | some index =>
          exact index_insert_exact_filter index entry hash

theorem cache_from_list_exact_filter
    (entries : List PsKernelExprV2WhnfCacheEntry) (hash : Nat) :
    filterHash hash
        (psKernelExprV2WhnfCacheBucket
          (psKernelExprV2WhnfCacheFromList entries) hash) =
      filterHash hash entries := by
  induction entries with
  | nil => rfl
  | cons first rest ih =>
      simp only [psKernelExprV2WhnfCacheFromList]
      rw [cache_insert_exact_filter]
      simp [filterHash, ih]

theorem cache_from_list_lookup_exact
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheLookup
        (psKernelExprV2WhnfCacheFromList entries) arena source hash =
      psKernelExprV2WhnfCacheFindWorker entries arena source hash := by
  unfold psKernelExprV2WhnfCacheLookup
  rw [← scanner_filtered_exact
    (psKernelExprV2WhnfCacheBucket
      (psKernelExprV2WhnfCacheFromList entries) hash) arena source hash]
  rw [cache_from_list_exact_filter]
  exact scanner_filtered_exact entries arena source hash

theorem cache_from_list_curried_scanner_exact
    (entries : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheLookup
        (psKernelExprV2WhnfCacheFromList entries) arena source hash =
      psKernelExprV2WhnfCacheFindIn entries arena source hash := by
  rw [cache_from_list_lookup_exact]
  cases entries <;> rfl

def Models (cache : PsKernelExprV2WhnfCache)
    (history : List PsKernelExprV2WhnfCacheEntry) : Prop :=
  ∀ hash, filterHash hash (psKernelExprV2WhnfCacheBucket cache hash) =
    filterHash hash history

theorem empty_models : Models psKernelExprV2WhnfCacheEmpty [] := by
  intro hash
  rfl

theorem insert_models
    (cache : PsKernelExprV2WhnfCache)
    (history : List PsKernelExprV2WhnfCacheEntry)
    (entry : PsKernelExprV2WhnfCacheEntry) (model : Models cache history) :
    Models (psKernelExprV2WhnfCacheInsert cache entry) (List.cons entry history) := by
  intro hash
  rw [cache_insert_exact_filter]
  simp [filterHash, model hash]

theorem modeled_lookup_exact
    (cache : PsKernelExprV2WhnfCache)
    (history : List PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat)
    (model : Models cache history) :
    psKernelExprV2WhnfCacheLookup cache arena source hash =
      psKernelExprV2WhnfCacheFindWorker history arena source hash := by
  unfold psKernelExprV2WhnfCacheLookup
  rw [← scanner_filtered_exact
    (psKernelExprV2WhnfCacheBucket cache hash) arena source hash]
  rw [model hash]
  exact scanner_filtered_exact history arena source hash

theorem empty_no_hit (arena : PsKernelExprV2PagedArena) (source hash : Nat) :
    psKernelExprV2WhnfCacheLookup psKernelExprV2WhnfCacheEmpty arena source hash =
      Except.ok Option.none := by
  rfl

theorem same_hash_publication_precedes_older_candidates
    (cache : PsKernelExprV2WhnfCache)
    (history : List PsKernelExprV2WhnfCacheEntry)
    (entry : PsKernelExprV2WhnfCacheEntry)
    (arena : PsKernelExprV2PagedArena) (source hash : Nat)
    (model : Models cache history) (sameHash : entry.hash = hash) :
    psKernelExprV2WhnfCacheLookup
        (psKernelExprV2WhnfCacheInsert cache entry) arena source hash =
      match psKernelExprV2PagedEqOnCanonical arena entry.source source with
      | Except.error error => Except.error error
      | Except.ok equal =>
          if equal then Except.ok (Option.some entry.result)
          else psKernelExprV2WhnfCacheFindWorker history arena source hash := by
  rw [modeled_lookup_exact
    (psKernelExprV2WhnfCacheInsert cache entry) (List.cons entry history)
    arena source hash (insert_models cache history entry model)]
  cases compared : psKernelExprV2PagedEqOnCanonical arena entry.source source with
  | error error =>
      simp [psKernelExprV2WhnfCacheFindWorker, sameHash, compared]
  | ok equal =>
      cases equal <;>
        simp [psKernelExprV2WhnfCacheFindWorker, sameHash, compared]

end PsKernelExprV2WhnfCacheProofs

#print axioms PsKernelExprV2WhnfCacheProofs.route_reflexive
#print axioms PsKernelExprV2WhnfCacheProofs.index_bucket_set
#print axioms PsKernelExprV2WhnfCacheProofs.index_bucket_same_route
#print axioms PsKernelExprV2WhnfCacheProofs.index_bucket_insert
#print axioms PsKernelExprV2WhnfCacheProofs.index_insert_exact_filter
#print axioms PsKernelExprV2WhnfCacheProofs.index_build_exact_filter
#print axioms PsKernelExprV2WhnfCacheProofs.scanner_filtered_exact
#print axioms PsKernelExprV2WhnfCacheProofs.index_scan_exact
#print axioms PsKernelExprV2WhnfCacheProofs.cache_insert_exact_filter
#print axioms PsKernelExprV2WhnfCacheProofs.cache_from_list_exact_filter
#print axioms PsKernelExprV2WhnfCacheProofs.cache_from_list_lookup_exact
#print axioms PsKernelExprV2WhnfCacheProofs.cache_from_list_curried_scanner_exact
#print axioms PsKernelExprV2WhnfCacheProofs.empty_models
#print axioms PsKernelExprV2WhnfCacheProofs.insert_models
#print axioms PsKernelExprV2WhnfCacheProofs.modeled_lookup_exact
#print axioms PsKernelExprV2WhnfCacheProofs.empty_no_hit
#print axioms PsKernelExprV2WhnfCacheProofs.same_hash_publication_precedes_older_candidates

#print axioms PsKernelExprV2WhnfCacheProofs.bucket_worker_exact
#print axioms PsKernelExprV2WhnfCacheProofs.set_worker_exact
#print axioms PsKernelExprV2WhnfCacheProofs.bucket_public_exact
#print axioms PsKernelExprV2WhnfCacheProofs.set_public_exact
#print axioms PsKernelExprV2WhnfCacheProofs.bucket_worker_public
#print axioms PsKernelExprV2WhnfCacheProofs.set_worker_public
#print axioms PsKernelExprV2WhnfCacheProofs.bucket_partial_application_exact
#print axioms PsKernelExprV2WhnfCacheProofs.set_partial_application_exact
