import Ps.KernelCore.Core.ExprV2.Validation
import PsKernelExprV2PagedModelProofs

/-!
Local metadata correspondence for the actual production replay operation.

ReplayInputs records actual child lookups and their five metadata
correspondences. It has no premise about the newly constructed entry, and its
six leaf cases have no child premise. A valid internal Layout is required only
when concluding the physical lookup and frame facts for the returned arena.

These are one-step preservation and metadata-guard transfer guarantees.
They do not establish a whole-validator canonical metadata invariant, executable
decoder correspondence, or ArenaModel for an arbitrary external source.
The existing public-validator physical Layout guarantees remain separate.
-/
namespace PsKernelExprV2ReplayMetadataProofs

open PsKernelExprV2MetadataProofs
open PsKernelExprV2PagedModelProofs

inductive ReplayInputs (arena : PsKernelExprV2PagedArena) :
    PsKernelExprV2Node → PsKernelExpr → Prop where
  | bvar (index : Nat) :
      ReplayInputs arena (.bvar index) (.bvar index)
  | fvar (name : PsKernelName) :
      ReplayInputs arena (.fvar name) (.fvar name)
  | mvar (name : PsKernelName) :
      ReplayInputs arena (.mvar name) (.mvar name)
  | sort (level : PsKernelLevel) :
      ReplayInputs arena (.sort level) (.sort level)
  | const (name : PsKernelName) (levels : List PsKernelLevel) :
      ReplayInputs arena (.const name levels) (.const name levels)
  | lit (literal : PsKernelLiteral) :
      ReplayInputs arena (.lit literal) (.lit literal)
  | app
      (fn arg : Nat) (f a : PsKernelExprV2Entry) (fe ae : PsKernelExpr)
      (fnLookup : psKernelExprV2PagedFind arena fn = some f)
      (argLookup : psKernelExprV2PagedFind arena arg = some a)
      (fnMetadata : Corresponds f fe) (argMetadata : Corresponds a ae) :
      ReplayInputs arena (.app fn arg) (.app fe ae)
  | lam
      (name : PsKernelName) (type body : Nat) (info : PsKernelBinderInfo)
      (t b : PsKernelExprV2Entry) (te be : PsKernelExpr)
      (typeLookup : psKernelExprV2PagedFind arena type = some t)
      (bodyLookup : psKernelExprV2PagedFind arena body = some b)
      (typeMetadata : Corresponds t te) (bodyMetadata : Corresponds b be) :
      ReplayInputs arena (.lam name type body info) (.lam name te be info)
  | forallE
      (name : PsKernelName) (type body : Nat) (info : PsKernelBinderInfo)
      (t b : PsKernelExprV2Entry) (te be : PsKernelExpr)
      (typeLookup : psKernelExprV2PagedFind arena type = some t)
      (bodyLookup : psKernelExprV2PagedFind arena body = some b)
      (typeMetadata : Corresponds t te) (bodyMetadata : Corresponds b be) :
      ReplayInputs arena (.forallE name type body info) (.forallE name te be info)
  | letE
      (name : PsKernelName) (type value body : Nat) (nondep : Bool)
      (t v b : PsKernelExprV2Entry) (te ve be : PsKernelExpr)
      (typeLookup : psKernelExprV2PagedFind arena type = some t)
      (valueLookup : psKernelExprV2PagedFind arena value = some v)
      (bodyLookup : psKernelExprV2PagedFind arena body = some b)
      (typeMetadata : Corresponds t te) (valueMetadata : Corresponds v ve)
      (bodyMetadata : Corresponds b be) :
      ReplayInputs arena (.letE name type value body nondep) (.letE name te ve be nondep)
  | mdata
      (tag body : Nat) (b : PsKernelExprV2Entry) (be : PsKernelExpr)
      (bodyLookup : psKernelExprV2PagedFind arena body = some b)
      (bodyMetadata : Corresponds b be) :
      ReplayInputs arena (.mdata tag body) (.mdata tag be)
  | proj
      (name : PsKernelName) (index body : Nat)
      (b : PsKernelExprV2Entry) (be : PsKernelExpr)
      (bodyLookup : psKernelExprV2PagedFind arena body = some b)
      (bodyMetadata : Corresponds b be) :
      ReplayInputs arena (.proj name index body) (.proj name index be)

/- Every node branch computes its new metadata from the actual entries returned
   by the owning arena's lookups. The result equation names the production
   ReplayNode and PagedPush, not a replacement replay implementation. -/
theorem replay_node_builds_corresponding_entry
    (arena : PsKernelExprV2PagedArena) (node : PsKernelExprV2Node)
    (expr : PsKernelExpr) (inputs : ReplayInputs arena node expr) :
    ∃ entry : PsKernelExprV2Entry,
      entry.node = node ∧
      Corresponds entry expr ∧
      psKernelExprV2PagedReplayNode arena node =
        Except.ok (psKernelExprV2PagedPush arena entry) := by
  cases inputs with
  | bvar index =>
      refine ⟨PsKernelExprV2Entry.mk (.bvar index)
        (psKernelCacheMix 21 index) (Nat.succ index) false false 1,
        rfl, ?_, rfl⟩
      exact ⟨rfl, rfl, rfl, rfl, rfl⟩
  | fvar name =>
      refine ⟨PsKernelExprV2Entry.mk (.fvar name)
        (psKernelCacheMix 22 (psKernelCacheNameHash name)) 0 true false 1,
        rfl, ?_, rfl⟩
      exact ⟨rfl, rfl, rfl, rfl, rfl⟩
  | mvar name =>
      refine ⟨PsKernelExprV2Entry.mk (.mvar name)
        (psKernelCacheMix 23 (psKernelCacheNameHash name)) 0 false true 1,
        rfl, ?_, rfl⟩
      exact ⟨rfl, rfl, rfl, rfl, rfl⟩
  | sort level =>
      refine ⟨PsKernelExprV2Entry.mk (.sort level)
        (psKernelCacheMix 24 (psKernelCacheLevelHash level)) 0 false false 1,
        rfl, ?_, rfl⟩
      exact ⟨rfl, rfl, rfl, rfl, rfl⟩
  | const name levels =>
      refine ⟨PsKernelExprV2Entry.mk (.const name levels)
        (psKernelCacheMix
          (psKernelCacheMix 25 (psKernelCacheNameHash name))
          (psKernelCacheLevelListHash levels)) 0 false false 1,
        rfl, ?_, rfl⟩
      exact ⟨rfl, rfl, rfl, rfl, rfl⟩
  | lit literal =>
      refine ⟨PsKernelExprV2Entry.mk (.lit literal)
        (psKernelCacheMix 30 (psKernelCacheLiteralHash literal)) 0 false false 1,
        rfl, ?_, rfl⟩
      exact ⟨rfl, rfl, rfl, rfl, rfl⟩
  | app fn arg f a fe ae fnLookup argLookup fnMetadata argMetadata =>
      refine ⟨psKernelExprV2AppEntry fn arg f a, rfl,
        app_preserves fn arg f a fe ae fnMetadata argMetadata, ?_⟩
      simp only [psKernelExprV2PagedReplayNode, psKernelExprV2PagedMkApp,
        psKernelExprV2PagedWith2, psKernelExprV2PagedRequire,
        fnLookup, argLookup, psKernelExprV2PagedPushChecked]
  | lam name type body info t b te be typeLookup bodyLookup typeMetadata bodyMetadata =>
      refine ⟨psKernelExprV2LamEntry name type body info t b, rfl,
        lam_preserves name type body info t b te be typeMetadata bodyMetadata, ?_⟩
      simp only [psKernelExprV2PagedReplayNode, psKernelExprV2PagedMkLam,
        psKernelExprV2PagedWith2, psKernelExprV2PagedRequire,
        typeLookup, bodyLookup, psKernelExprV2PagedPushChecked]
  | forallE name type body info t b te be typeLookup bodyLookup typeMetadata bodyMetadata =>
      refine ⟨psKernelExprV2ForallEntry name type body info t b, rfl,
        forall_preserves name type body info t b te be typeMetadata bodyMetadata, ?_⟩
      simp only [psKernelExprV2PagedReplayNode, psKernelExprV2PagedMkForall,
        psKernelExprV2PagedWith2, psKernelExprV2PagedRequire,
        typeLookup, bodyLookup, psKernelExprV2PagedPushChecked]
  | letE name type value body nondep t v b te ve be
      typeLookup valueLookup bodyLookup typeMetadata valueMetadata bodyMetadata =>
      refine ⟨psKernelExprV2LetEntry name type value body nondep t v b, rfl,
        let_preserves name type value body nondep t v b te ve be
          typeMetadata valueMetadata bodyMetadata, ?_⟩
      simp only [psKernelExprV2PagedReplayNode, psKernelExprV2PagedMkLet,
        psKernelExprV2PagedWith3, psKernelExprV2PagedRequire,
        typeLookup, valueLookup, bodyLookup, psKernelExprV2PagedPushChecked]
  | mdata tag body b be bodyLookup bodyMetadata =>
      refine ⟨psKernelExprV2MDataEntry tag body b, rfl,
        mdata_preserves tag body b be bodyMetadata, ?_⟩
      simp only [psKernelExprV2PagedReplayNode, psKernelExprV2PagedMkMData,
        psKernelExprV2PagedWith1, psKernelExprV2PagedRequire,
        bodyLookup, psKernelExprV2PagedPushChecked]
  | proj name index body b be bodyLookup bodyMetadata =>
      refine ⟨psKernelExprV2ProjEntry name index body b, rfl,
        proj_preserves name index body b be bodyMetadata, ?_⟩
      simp only [psKernelExprV2PagedReplayNode, psKernelExprV2PagedMkProj,
        psKernelExprV2PagedWith1, psKernelExprV2PagedRequire,
        bodyLookup, psKernelExprV2PagedPushChecked]

/- The successful production result contains the computed metadata at its
   returned fresh ID, retains page capacity, and frames every prior lookup.
   No desired output property appears as a premise. -/
theorem replay_node_preserves_layout_and_metadata
    (arena : PsKernelExprV2PagedArena) (node : PsKernelExprV2Node)
    (expr : PsKernelExpr) (inserted : PsKernelExprV2PagedArena × Nat)
    (layout : Layout arena) (inputs : ReplayInputs arena node expr)
    (accepted : psKernelExprV2PagedReplayNode arena node = Except.ok inserted) :
    inserted.snd = arena.size ∧
      inserted.fst.size = arena.size + 1 ∧
      inserted.fst.pageLimit = arena.pageLimit ∧
      Layout inserted.fst ∧
      (∀ id, id < arena.size →
        psKernelExprV2PagedFind inserted.fst id = psKernelExprV2PagedFind arena id) ∧
      ∃ entry : PsKernelExprV2Entry,
        psKernelExprV2PagedFind inserted.fst inserted.snd = some entry ∧
        entry.node = node ∧
        Corresponds entry expr := by
  rcases replay_node_builds_corresponding_entry arena node expr inputs with
    ⟨entry, nodeEq, metadata, built⟩
  have output : psKernelExprV2PagedPush arena entry = inserted :=
    Except.ok.inj (built.symm.trans accepted)
  subst inserted
  have sizes := push_id_and_size arena entry
  refine ⟨sizes.1, sizes.2.1, sizes.2.2, push_layout arena entry layout,
    ?_, entry, ?_, nodeEq, metadata⟩
  · intro id inside
    exact push_find_old arena entry layout id inside
  · rw [sizes.1]
    exact push_find_new arena entry layout

theorem bool_eq_true_iff (left right : Bool) :
    psKernelBoolEq left right = true ↔ left = right := by
  cases left <;> cases right <;> simp [psKernelBoolEq]

/- This is the exact guard used by PagedValidateFuel. It transfers only the
   five metadata fields; it does not assert node equality or decoded equality.
   The production replay theorem above separately preserves the node tag and
   every syntactic field in entry.node. -/
theorem portable_same_metadata_transfers_correspondence
    (original computed : PsKernelExprV2Entry) (expr : PsKernelExpr)
    (rebuilt : Corresponds computed expr)
    (accepted : psKernelExprV2PortableSameMetadata original computed = true) :
    Corresponds original expr := by
  unfold psKernelExprV2PortableSameMetadata at accepted
  split at accepted
  · rename_i hashMatch
    split at accepted
    · rename_i rangeMatch
      split at accepted
      · rename_i fvarMatch
        split at accepted
        · rename_i mvarMatch
          have hashEq : original.hash = computed.hash := by
            simpa only [Nat.beq_eq] using hashMatch
          have rangeEq : original.looseRange = computed.looseRange := by
            simpa only [Nat.beq_eq] using rangeMatch
          have fvarEq : original.hasFVar = computed.hasFVar :=
            (bool_eq_true_iff _ _).mp fvarMatch
          have mvarEq : original.hasExprMVar = computed.hasExprMVar :=
            (bool_eq_true_iff _ _).mp mvarMatch
          have depthEq : original.depth = computed.depth := by
            simpa only [Nat.beq_eq] using accepted
          exact ⟨hashEq.trans rebuilt.hash, rangeEq.trans rebuilt.looseRange,
            fvarEq.trans rebuilt.hasFVar, mvarEq.trans rebuilt.hasExprMVar,
            depthEq.trans rebuilt.depth⟩
        · contradiction
      · contradiction
    · contradiction
  · contradiction

end PsKernelExprV2ReplayMetadataProofs

#print axioms PsKernelExprV2ReplayMetadataProofs.replay_node_builds_corresponding_entry
#print axioms PsKernelExprV2ReplayMetadataProofs.replay_node_preserves_layout_and_metadata
#print axioms PsKernelExprV2ReplayMetadataProofs.bool_eq_true_iff
#print axioms PsKernelExprV2ReplayMetadataProofs.portable_same_metadata_transfers_correspondence
