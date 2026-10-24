import Init.Data.Array.Lemmas
import Init.Data.Nat.Div.Basic
import Lean.Elab.Tactic.Omega
import Ps.KernelCore.Core.ExprV2.Builder
import PsKernelExprV2MetadataProofs

/-!
Future native-only proof batch: concrete paged storage framing.

Layout describes the physical page lengths, active-page bound and total size.
It does not assume any desired lookup, append, decoder or replay result. The
lemmas below prove those lookup/append facts for the production Paged functions.

This file is separate from the current ordinary-header candidate. A future
native proof library must register the unchanged PsKernelExprV2MetadataProofs
module before importing it here. No production representation is changed.
Replay-validator preservation, topological decoding and the full ArenaModel
bridge are not claimed by this first storage batch.
-/
namespace PsKernelExprV2PagedModelProofs

structure Layout (arena : PsKernelExprV2PagedArena) : Prop where
  positive : 0 < arena.pageLimit
  full : forall page, page < arena.pages.size ->
    (arena.pages.getD page (Array.emptyWithCapacity 0)).size = arena.pageLimit
  active : arena.active.size <= arena.pageLimit
  size : arena.size = arena.pages.size * arena.pageLimit + arena.active.size

theorem array_getD_push_old {α : Type} (values : Array α)
    (value fallback : α) (index : Nat) (before : index < values.size) :
    (values.push value).getD index fallback = values.getD index fallback := by
  simp only [Array.getD_eq_getD_getElem?, Array.getElem?_push,
    Nat.ne_of_lt before, ite_false]

theorem array_getD_push_new {α : Type} (values : Array α)
    (value fallback : α) :
    (values.push value).getD values.size fallback = value := by
  simp [Array.getD_eq_getD_getElem?, Array.getElem?_push]

theorem paged_get_eq_optional_get (values : Array PsKernelExprV2Entry) (index : Nat) :
    psKernelExprV2PagedGet values index = values[index]? := by
  by_cases inside : index < values.size
  · simp [psKernelExprV2PagedGet, Nat.blt_eq, inside,
      Array.getD_eq_getD_getElem?]
  · simp [psKernelExprV2PagedGet, Nat.blt_eq, inside,
      Array.getD_eq_getD_getElem?]

theorem paged_get_push_old (values : Array PsKernelExprV2Entry)
    (value : PsKernelExprV2Entry) (index : Nat) (before : index < values.size) :
    psKernelExprV2PagedGet (values.push value) index = psKernelExprV2PagedGet values index := by
  rw [paged_get_eq_optional_get, paged_get_eq_optional_get, Array.getElem?_push]
  simp only [Nat.ne_of_lt before, ite_false]

theorem paged_get_push_new (values : Array PsKernelExprV2Entry)
    (value : PsKernelExprV2Entry) :
    psKernelExprV2PagedGet (values.push value) values.size = some value := by
  rw [paged_get_eq_optional_get]
  exact Array.getElem?_push_size

theorem empty_layout (limit : Nat) :
    Layout (psKernelExprV2PagedEmptyWithLimit limit) := by
  by_cases zero : limit = 0
  · subst limit
    constructor
    · simp [psKernelExprV2PagedEmptyWithLimit]
    · intro page before
      simp [psKernelExprV2PagedEmptyWithLimit] at before
    · simp [psKernelExprV2PagedEmptyWithLimit]
    · simp [psKernelExprV2PagedEmptyWithLimit]
  · simp only [psKernelExprV2PagedEmptyWithLimit, Nat.beq_eq, zero, ite_false]
    constructor
    · exact Nat.pos_of_ne_zero zero
    · intro page before
      simp at before
    · simp
    · simp

theorem push_growing (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (space : arena.active.size < arena.pageLimit) :
    psKernelExprV2PagedPush arena entry =
      (PsKernelExprV2PagedArena.mk arena.pages (arena.active.push entry)
        (arena.size + 1) arena.pageLimit, arena.size) := by
  simp [psKernelExprV2PagedPush, Nat.blt_eq, space, Nat.succ_eq_add_one]

theorem push_rollover (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (full : ¬ arena.active.size < arena.pageLimit) :
    psKernelExprV2PagedPush arena entry =
      (PsKernelExprV2PagedArena.mk (arena.pages.push arena.active) #[entry]
        (arena.size + 1) arena.pageLimit, arena.size) := by
  simp [psKernelExprV2PagedPush, Nat.blt_eq, full, Nat.succ_eq_add_one]

theorem push_id_and_size (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry) :
    (psKernelExprV2PagedPush arena entry).snd = arena.size /\
      (psKernelExprV2PagedPush arena entry).fst.size = arena.size + 1 /\
      (psKernelExprV2PagedPush arena entry).fst.pageLimit = arena.pageLimit := by
  unfold psKernelExprV2PagedPush
  split <;> exact ⟨rfl, rfl, rfl⟩

theorem push_layout (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (layout : Layout arena) : Layout (psKernelExprV2PagedPush arena entry).fst := by
  by_cases space : arena.active.size < arena.pageLimit
  · rw [push_growing arena entry space]
    constructor
    · exact layout.positive
    · exact layout.full
    · simpa only [Array.size_push] using Nat.succ_le_of_lt space
    · simp only [Array.size_push]
      rw [layout.size]
      omega
  · have full : arena.active.size = arena.pageLimit := by
      have bounded := layout.active
      omega
    rw [push_rollover arena entry space]
    constructor
    · exact layout.positive
    · intro page before
      simp only [Array.size_push] at before
      by_cases old : page < arena.pages.size
      · rw [array_getD_push_old arena.pages arena.active (Array.emptyWithCapacity 0) page old]
        exact layout.full page old
      · have same : page = arena.pages.size := by omega
        subst page
        rw [array_getD_push_new]
        exact full
    · have positive := layout.positive
      simp only [Array.size_singleton]
      omega
    · simp only [Array.size_push, Array.size_singleton]
      rw [layout.size, full]
      simp [Nat.add_mul, Nat.add_assoc]

/- A valid ID either lies in a completed page or in the active page. These
   inequalities come only from arithmetic layout facts, not from lookup. -/
theorem valid_id_location (arena : PsKernelExprV2PagedArena) (layout : Layout arena)
    (id : Nat) (inside : id < arena.size) :
    id / arena.pageLimit < arena.pages.size \/
      (id / arena.pageLimit = arena.pages.size /\ id % arena.pageLimit < arena.active.size) := by
  have total := layout.size
  have active := layout.active
  have upper : id < (arena.pages.size + 1) * arena.pageLimit := by
    rw [Nat.add_mul, Nat.one_mul]
    omega
  have quotient : id / arena.pageLimit <= arena.pages.size := by
    have less := (Nat.div_lt_iff_lt_mul layout.positive).2 upper
    omega
  by_cases completed : id / arena.pageLimit < arena.pages.size
  · exact Or.inl completed
  · have atActive : id / arena.pageLimit = arena.pages.size := by omega
    have division := Nat.div_add_mod id arena.pageLimit
    rw [atActive, Nat.mul_comm arena.pageLimit arena.pages.size] at division
    exact Or.inr ⟨atActive, by omega⟩

theorem find_out_of_bounds (arena : PsKernelExprV2PagedArena)
    (id : Nat) (outside : arena.size <= id) :
    psKernelExprV2PagedFind arena id = none := by
  have notInside : ¬ id < arena.size := by omega
  by_cases zero : arena.pageLimit = 0 <;>
    simp [psKernelExprV2PagedFind, Nat.beq_eq, Nat.blt_eq, zero, notInside]

theorem found_id_is_in_bounds (arena : PsKernelExprV2PagedArena)
    (id : Nat) (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedFind arena id = some entry) : id < arena.size := by
  apply Decidable.by_contra
  intro outside
  have absent := find_out_of_bounds arena id (by omega)
  rw [absent] at found
  contradiction

theorem valid_id_is_found (arena : PsKernelExprV2PagedArena) (layout : Layout arena)
    (id : Nat) (inside : id < arena.size) :
    Exists (fun entry => psKernelExprV2PagedFind arena id = some entry) := by
  have nonzero : arena.pageLimit ≠ 0 := Nat.ne_of_gt layout.positive
  rcases valid_id_location arena layout id inside with completed | ⟨atActive, offset⟩
  · have size := layout.full (id / arena.pageLimit) completed
    have offset : id % arena.pageLimit <
        (arena.pages.getD (id / arena.pageLimit) (Array.emptyWithCapacity 0)).size := by
      rw [size]
      exact Nat.mod_lt id layout.positive
    refine ⟨(arena.pages.getD (id / arena.pageLimit) (Array.emptyWithCapacity 0)).getD
      (id % arena.pageLimit) psKernelExprV2DummyEntry, ?_⟩
    dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
      HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
    simp [psKernelExprV2PagedFind, psKernelExprV2PagedGet, Nat.beq_eq, Nat.blt_eq,
      nonzero, inside, completed, offset]
  · refine ⟨arena.active.getD (id % arena.pageLimit) psKernelExprV2DummyEntry, ?_⟩
    dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
      HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
    simp [psKernelExprV2PagedFind, psKernelExprV2PagedGet, Nat.beq_eq, Nat.blt_eq,
      nonzero, inside, atActive, offset]

theorem push_find_old (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (layout : Layout arena) (id : Nat) (inside : id < arena.size) :
    psKernelExprV2PagedFind (psKernelExprV2PagedPush arena entry).fst id =
      psKernelExprV2PagedFind arena id := by
  have nonzero : arena.pageLimit ≠ 0 := Nat.ne_of_gt layout.positive
  have nextInside : id < arena.size + 1 := by omega
  by_cases space : arena.active.size < arena.pageLimit
  · rw [push_growing arena entry space]
    rcases valid_id_location arena layout id inside with completed | ⟨atActive, offset⟩
    · dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
        HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
      simp [psKernelExprV2PagedFind, Nat.beq_eq, Nat.blt_eq,
        nonzero, inside, nextInside, completed]
    · dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
        HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
      simpa only [psKernelExprV2PagedFind, Nat.beq_eq, Nat.blt_eq,
        nonzero, inside, nextInside, atActive, Nat.lt_irrefl, ite_false, ite_true] using
          paged_get_push_old arena.active entry (Nat.mod id arena.pageLimit) offset
  · rw [push_rollover arena entry space]
    rcases valid_id_location arena layout id inside with completed | ⟨atActive, offset⟩
    · have completedNext : id / arena.pageLimit < arena.pages.size + 1 := by omega
      dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
        HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
      simp only [psKernelExprV2PagedFind, Nat.beq_eq, Nat.blt_eq, Array.size_push,
        nonzero, inside, nextInside, completed, completedNext, ite_false, ite_true]
      rw [array_getD_push_old arena.pages arena.active (Array.emptyWithCapacity 0)
        (Nat.div id arena.pageLimit) completed]
    · dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
        HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
      simp [psKernelExprV2PagedFind, Nat.beq_eq, Nat.blt_eq, nonzero, inside,
        nextInside, atActive, array_getD_push_new]

theorem push_find_new (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (layout : Layout arena) :
    psKernelExprV2PagedFind (psKernelExprV2PagedPush arena entry).fst arena.size = some entry := by
  have nonzero : arena.pageLimit ≠ 0 := Nat.ne_of_gt layout.positive
  have nextInside : arena.size < arena.size + 1 := by omega
  by_cases space : arena.active.size < arena.pageLimit
  · have lower : arena.pages.size * arena.pageLimit <= arena.size := by
      rw [layout.size]
      omega
    have upper : arena.size < (arena.pages.size + 1) * arena.pageLimit := by
      rw [layout.size, Nat.add_mul, Nat.one_mul]
      omega
    have page : arena.size / arena.pageLimit = arena.pages.size :=
      Nat.div_eq_of_lt_le lower upper
    have offset : arena.size % arena.pageLimit = arena.active.size := by
      rw [layout.size, Nat.mul_add_mod_self_right, Nat.mod_eq_of_lt space]
    rw [push_growing arena entry space]
    dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
      HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
    simpa only [psKernelExprV2PagedFind, Nat.beq_eq, Nat.blt_eq, nonzero,
      nextInside, page, offset, Nat.lt_irrefl, ite_false, ite_true] using
        paged_get_push_new arena.active entry
  · have full : arena.active.size = arena.pageLimit := by
      have active := layout.active
      omega
    have total : arena.size = (arena.pages.size + 1) * arena.pageLimit := by
      rw [layout.size, full, Nat.add_mul, Nat.one_mul]
    have page : arena.size / arena.pageLimit = arena.pages.size + 1 := by
      rw [total]
      exact Nat.mul_div_cancel _ layout.positive
    have offset : arena.size % arena.pageLimit = 0 := by
      rw [total, Nat.mul_mod_left]
    rw [push_rollover arena entry space]
    dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
      HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
    simp [psKernelExprV2PagedFind, psKernelExprV2PagedGet, Nat.beq_eq, Nat.blt_eq,
      nonzero, nextInside, page, offset, Array.getD_eq_getD_getElem?]

/- All indices are covered: old IDs are framed, the new ID contains exactly
   the supplied entry, and every later ID remains absent. -/
theorem push_find (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (layout : Layout arena) (id : Nat) :
    psKernelExprV2PagedFind (psKernelExprV2PagedPush arena entry).fst id =
      if id = arena.size then some entry else psKernelExprV2PagedFind arena id := by
  by_cases fresh : id = arena.size
  · subst id
    simpa using push_find_new arena entry layout
  · simp only [fresh, ite_false]
    by_cases old : id < arena.size
    · exact push_find_old arena entry layout id old
    · have outside : arena.size <= id := by omega
      have nextOutside : (psKernelExprV2PagedPush arena entry).fst.size <= id := by
        rw [(push_id_and_size arena entry).2.1]
        omega
      rw [find_out_of_bounds _ _ nextOutside, find_out_of_bounds _ _ outside]

theorem push_require_old (arena : PsKernelExprV2PagedArena) (entry : PsKernelExprV2Entry)
    (layout : Layout arena) (id : Nat) (inside : id < arena.size) :
    psKernelExprV2PagedRequire (psKernelExprV2PagedPush arena entry).fst id =
      psKernelExprV2PagedRequire arena id := by
  simp only [psKernelExprV2PagedRequire, push_find_old arena entry layout id inside]

/- Direct reuse of the retained, already-audited local metadata theorem. This
   demonstrates the join needed by the next replay-step proof; it does not yet
   assert a whole-arena decoding invariant. -/
theorem mk_app_preserves_layout_and_metadata
    (arena : PsKernelExprV2PagedArena) (layout : Layout arena)
    (fn arg : Nat) (f a : PsKernelExprV2Entry) (fe ae : PsKernelExpr)
    (fnLookup : psKernelExprV2PagedFind arena fn = some f)
    (argLookup : psKernelExprV2PagedFind arena arg = some a)
    (fnMetadata : PsKernelExprV2MetadataProofs.Corresponds f fe)
    (argMetadata : PsKernelExprV2MetadataProofs.Corresponds a ae) :
    let entry := psKernelExprV2AppEntry fn arg f a
    let next := (psKernelExprV2PagedPush arena entry).fst
    psKernelExprV2PagedMkApp arena fn arg = Except.ok (next, arena.size) /\
      Layout next /\
      psKernelExprV2PagedFind next arena.size = some entry /\
      PsKernelExprV2MetadataProofs.Corresponds entry (PsKernelExpr.app fe ae) := by
  dsimp
  refine ⟨?_, push_layout arena _ layout, push_find_new arena _ layout, ?_⟩
  · simp only [psKernelExprV2PagedMkApp, psKernelExprV2PagedWith2,
      psKernelExprV2PagedRequire, fnLookup, argLookup, psKernelExprV2PagedPushChecked]
    apply congrArg (fun pair : PsKernelExprV2PagedArena × Nat =>
      (Except.ok pair : Except String (PsKernelExprV2PagedArena × Nat)))
    exact Prod.ext rfl (push_id_and_size arena (psKernelExprV2AppEntry fn arg f a)).1
  · exact PsKernelExprV2MetadataProofs.app_preserves fn arg f a fe ae fnMetadata argMetadata

end PsKernelExprV2PagedModelProofs

#print axioms PsKernelExprV2PagedModelProofs.array_getD_push_old
#print axioms PsKernelExprV2PagedModelProofs.array_getD_push_new
#print axioms PsKernelExprV2PagedModelProofs.paged_get_eq_optional_get
#print axioms PsKernelExprV2PagedModelProofs.paged_get_push_old
#print axioms PsKernelExprV2PagedModelProofs.paged_get_push_new
#print axioms PsKernelExprV2PagedModelProofs.empty_layout
#print axioms PsKernelExprV2PagedModelProofs.push_id_and_size
#print axioms PsKernelExprV2PagedModelProofs.push_layout
#print axioms PsKernelExprV2PagedModelProofs.valid_id_location
#print axioms PsKernelExprV2PagedModelProofs.find_out_of_bounds
#print axioms PsKernelExprV2PagedModelProofs.found_id_is_in_bounds
#print axioms PsKernelExprV2PagedModelProofs.valid_id_is_found
#print axioms PsKernelExprV2PagedModelProofs.push_find_old
#print axioms PsKernelExprV2PagedModelProofs.push_find_new
#print axioms PsKernelExprV2PagedModelProofs.push_find
#print axioms PsKernelExprV2PagedModelProofs.push_require_old
#print axioms PsKernelExprV2PagedModelProofs.mk_app_preserves_layout_and_metadata
