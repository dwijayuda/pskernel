import Ps.KernelCore.Core.ExprV2.ExpandedSize
import PsKernelOrdinaryOccurrenceProofs

/- Local count correspondence under the existing owning ArenaModel. The memo
   is scoped to this immutable arena. No external cache result is an axiom. -/
namespace PsKernelExpandedSizeProofs
open PsKernelOrdinaryOccurrenceProofs

def MemoSound (decode : Nat → PsKernelExpr) (memo : List PsKernelExprV2SizeMemo) : Prop :=
  ∀ item ∈ memo, item.count = psKernelExprNodeCount (decode item.source)

def sizeSum (decode : Nat → PsKernelExpr) : List Nat → Nat
  | [] => 0
  | root :: rest => psKernelExprNodeCount (decode root) + sizeSum decode rest

theorem empty_memo_sound (decode : Nat → PsKernelExpr) : MemoSound decode [] := by
  simp [MemoSound]

theorem child_ids_match_existing_traversal (node : PsKernelExprV2Node) :
    psKernelExprV2ExpandedSizeChildIds node = childIds node := by
  cases node <;> rfl

theorem child_sum_is_exact_tree_size
    (decode : Nat → PsKernelExpr) (node : PsKernelExprV2Node) :
    Nat.succ (sizeSum decode (psKernelExprV2ExpandedSizeChildIds node)) =
      psKernelExprNodeCount (nodeExpr decode node) := by
  cases node <;> simp [psKernelExprV2ExpandedSizeChildIds, sizeSum, nodeExpr, psKernelExprNodeCount]

theorem child_depth_bound (decode : Nat → PsKernelExpr) (node : PsKernelExprV2Node)
    (child remaining : Nat)
    (member : child ∈ psKernelExprV2ExpandedSizeChildIds node)
    (bound : psKernelExprV2LegacyDepth (nodeExpr decode node) ≤ Nat.succ remaining) :
    psKernelExprV2LegacyDepth (decode child) ≤ remaining := by
  cases node with
  | app fn arg =>
      simp only [psKernelExprV2ExpandedSizeChildIds, List.mem_cons, List.mem_singleton] at member
      simp only [nodeExpr, psKernelExprV2LegacyDepth, Nat.succ_le_succ_iff, Nat.max_le] at bound
      rcases member with rfl | rfl
      · exact bound.1
      · exact bound.2
  | lam name type body info =>
      simp only [psKernelExprV2ExpandedSizeChildIds, List.mem_cons, List.mem_singleton] at member
      simp only [nodeExpr, psKernelExprV2LegacyDepth, Nat.succ_le_succ_iff, Nat.max_le] at bound
      rcases member with rfl | rfl
      · exact bound.1
      · exact bound.2
  | forallE name type body info =>
      simp only [psKernelExprV2ExpandedSizeChildIds, List.mem_cons, List.mem_singleton] at member
      simp only [nodeExpr, psKernelExprV2LegacyDepth, Nat.succ_le_succ_iff, Nat.max_le] at bound
      rcases member with rfl | rfl
      · exact bound.1
      · exact bound.2
  | letE name type value body nondep =>
      simp only [psKernelExprV2ExpandedSizeChildIds, List.mem_cons, List.mem_singleton] at member
      simp only [nodeExpr, psKernelExprV2LegacyDepth, Nat.succ_le_succ_iff, Nat.max_le] at bound
      rcases member with rfl | rfl | rfl
      · exact bound.1.1
      · exact bound.1.2
      · exact bound.2
  | mdata tag body =>
      simp only [psKernelExprV2ExpandedSizeChildIds, List.mem_singleton] at member
      subst child
      exact Nat.le_of_succ_le_succ bound
  | proj name index body =>
      simp only [psKernelExprV2ExpandedSizeChildIds, List.mem_singleton] at member
      subst child
      exact Nat.le_of_succ_le_succ bound
  | bvar _ | fvar _ | mvar _ | sort _ | const _ _ | lit _ =>
      simp [psKernelExprV2ExpandedSizeChildIds] at member

theorem memo_hit_is_exact
    (decode : Nat → PsKernelExpr) (memo : List PsKernelExprV2SizeMemo)
    (root count : Nat) (sound : MemoSound decode memo)
    (hit : psKernelExprV2SizeMemoFind memo root = some count) :
    count = psKernelExprNodeCount (decode root) := by
  induction memo with
  | nil => simp [psKernelExprV2SizeMemoFind] at hit
  | cons first rest ih =>
      by_cases same : first.source = root
      · have countEq : first.count = count := by
          simpa [psKernelExprV2SizeMemoFind, same] using hit
        rw [← countEq, ← same]
        exact sound first (by simp)
      · have tailHit : psKernelExprV2SizeMemoFind rest root = some count := by
          simpa [psKernelExprV2SizeMemoFind, Nat.beq_eq, same] using hit
        exact ih (fun item member => sound item (by simp [member])) tailHit

theorem insert_preserves_sound
    (decode : Nat → PsKernelExpr) (memo : List PsKernelExprV2SizeMemo) (root count : Nat)
    (sound : MemoSound decode memo) (exactCount : count = psKernelExprNodeCount (decode root)) :
    MemoSound decode (PsKernelExprV2SizeMemo.mk root count :: memo) := by
  intro item member
  rcases List.mem_cons.mp member with equal | old
  · subst item
    exact exactCount
  · exact sound item old

theorem children_correspondence
    (decode : Nat → PsKernelExpr)
    (visit : Nat → List PsKernelExprV2SizeMemo → Except String (List PsKernelExprV2SizeMemo × Nat))
    (roots : List Nat) :
    (∀ root ∈ roots, ∀ memo, MemoSound decode memo →
      ∃ next, visit root memo = .ok (next,psKernelExprNodeCount (decode root)) ∧ MemoSound decode next) →
    ∀ memo, MemoSound decode memo →
      ∃ next, psKernelExprV2ExpandedSizeChildren roots visit memo = .ok (next,sizeSum decode roots) ∧
        MemoSound decode next := by
  induction roots with
  | nil =>
      intro _ memo sound
      exact ⟨memo,rfl,sound⟩
  | cons first rest ih =>
      intro good memo sound
      rcases good first (by simp) memo sound with ⟨afterHead,headStep,headSound⟩
      have tailGood : ∀ root ∈ rest, ∀ memo, MemoSound decode memo →
          ∃ next, visit root memo = .ok (next,psKernelExprNodeCount (decode root)) ∧ MemoSound decode next := by
        intro root member memo sound
        exact good root (by simp [member]) memo sound
      rcases ih tailGood afterHead headSound with ⟨next,tailStep,nextSound⟩
      refine ⟨next,?_,nextSound⟩
      simp only [psKernelExprV2ExpandedSizeChildren, headStep, tailStep, sizeSum]

theorem worker_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat → PsKernelExpr)
    (model : ArenaModel arena decode) (fuel : Nat) :
    ∀ root, validId arena root → psKernelExprV2LegacyDepth (decode root) ≤ fuel →
      ∀ memo, MemoSound decode memo →
        ∃ next, psKernelExprV2ExpandedSizeWithFuel fuel arena root memo =
          .ok (next,psKernelExprNodeCount (decode root)) ∧ MemoSound decode next := by
  induction fuel with
  | zero =>
      intro root _ bound _ _
      have positive := legacy_depth_positive (decode root)
      omega
  | succ remaining ih =>
      intro root valid bound memo sound
      cases cached : psKernelExprV2SizeMemoFind memo root with
      | some count =>
          have exactCount := memo_hit_is_exact decode memo root count sound cached
          refine ⟨memo,?_,sound⟩
          simp only [psKernelExprV2ExpandedSizeWithFuel, cached, exactCount]
      | none =>
          rcases valid with ⟨entry,found⟩
          have shape := model.shape root entry found
          let visit := fun child entries => psKernelExprV2ExpandedSizeWithFuel remaining arena child entries
          have good : ∀ child ∈ psKernelExprV2ExpandedSizeChildIds entry.node,
              ∀ entries, MemoSound decode entries →
                ∃ next, visit child entries = .ok (next,psKernelExprNodeCount (decode child)) ∧ MemoSound decode next := by
            intro child member entries entriesSound
            have childValid := model.children root entry found child
              (by simpa only [child_ids_match_existing_traversal] using member)
            have childBound := child_depth_bound decode entry.node child remaining member (by simpa only [shape] using bound)
            exact ih child childValid childBound entries entriesSound
          rcases children_correspondence decode visit
            (psKernelExprV2ExpandedSizeChildIds entry.node) good memo sound with ⟨next,steps,nextSound⟩
          have countEq : Nat.succ (sizeSum decode (psKernelExprV2ExpandedSizeChildIds entry.node)) =
              psKernelExprNodeCount (decode root) := by
            rw [shape]
            exact child_sum_is_exact_tree_size decode entry.node
          refine ⟨PsKernelExprV2SizeMemo.mk root (psKernelExprNodeCount (decode root)) :: next,?_,
            insert_preserves_sound decode next root _ nextSound rfl⟩
          simp only [psKernelExprV2ExpandedSizeWithFuel, cached, psKernelExprV2PagedRequire, found,
            steps, countEq]

theorem canonical_count_is_exact
    (arena : PsKernelExprV2PagedArena) (decode : Nat → PsKernelExpr)
    (model : ArenaModel arena decode) (root : Nat) (valid : validId arena root) :
    psKernelExprV2ExpandedSizeOnCanonical arena root = .ok (psKernelExprNodeCount (decode root)) := by
  rcases valid with ⟨entry,found⟩
  have bound : psKernelExprV2LegacyDepth (decode root) ≤ Nat.succ entry.depth :=
    Nat.le_trans (model.depth root entry found) (Nat.le_succ _)
  rcases worker_correspondence arena decode model (Nat.succ entry.depth) root
    ⟨entry,found⟩ bound [] (empty_memo_sound decode) with ⟨next,step,_⟩
  simp only [psKernelExprV2ExpandedSizeOnCanonical, psKernelExprV2PagedRequire, found, step]

theorem structural_zero_precedes_memo
    (arena : PsKernelExprV2PagedArena) (root : Nat) (memo : List PsKernelExprV2SizeMemo) :
    psKernelExprV2ExpandedSizeWithFuel 0 arena root memo =
      .error "PSKERNEL_V2_EXPANDED_SIZE_FUEL" := rfl

theorem successful_hit_keeps_exact_memo
    (arena : PsKernelExprV2PagedArena) (root count remaining : Nat)
    (memo : List PsKernelExprV2SizeMemo)
    (hit : psKernelExprV2SizeMemoFind memo root = some count) :
    psKernelExprV2ExpandedSizeWithFuel (Nat.succ remaining) arena root memo = .ok (memo,count) := by
  simp only [psKernelExprV2ExpandedSizeWithFuel, hit]

#print axioms empty_memo_sound
#print axioms child_ids_match_existing_traversal
#print axioms child_sum_is_exact_tree_size
#print axioms child_depth_bound
#print axioms memo_hit_is_exact
#print axioms insert_preserves_sound
#print axioms children_correspondence
#print axioms worker_correspondence
#print axioms canonical_count_is_exact
#print axioms structural_zero_precedes_memo
#print axioms successful_hit_keeps_exact_memo
end PsKernelExpandedSizeProofs
