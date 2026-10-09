import Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration
import Init.Data.List.Perm
import Init.Data.List.Nat.Range

/--
Exact bounded candidate-search exit. The exhaustion alternative remains open;
excluding it requires independent candidate distinctness for opaque bootstrap
string append and decimal representation. No additional trusted law is adopted.
-/
theorem psKernelSimpleFreshElimNameAux_exit_refines (fuel : Nat) :
    ∀ (params : List PsKernelName) (start : Nat),
      ∃ offset : Nat, offset ≤ fuel ∧
        psKernelSimpleFreshElimNameAux fuel params start =
          psKernelSimpleElimNameCandidate (start + offset) ∧
        (offset = fuel ∨
          psKernelNameMember (psKernelSimpleFreshElimNameAux fuel params start) params = false) := by
  induction fuel with
  | zero =>
      intro params start
      exact ⟨0, Nat.le_refl 0, by simp [psKernelSimpleFreshElimNameAux], Or.inl rfl⟩
  | succ remaining ih =>
      intro params start
      cases hMember : psKernelNameMember (psKernelSimpleElimNameCandidate start) params with
      | false =>
          refine ⟨0, Nat.zero_le _, ?_, Or.inr ?_⟩
          · simp [psKernelSimpleFreshElimNameAux, hMember]
          · simpa [psKernelSimpleFreshElimNameAux, hMember] using hMember
      | true =>
          obtain ⟨offset, hBound, hCandidate, hExit⟩ := ih params (Nat.succ start)
          have hShift : Nat.succ start + offset = start + Nat.succ offset := by omega
          refine ⟨Nat.succ offset, by omega, ?_, ?_⟩
          · simpa [psKernelSimpleFreshElimNameAux, hMember, hShift] using hCandidate
          · cases hExit with
            | inl hLast => exact Or.inl (congrArg Nat.succ hLast)
            | inr hAbsent =>
                exact Or.inr (by simpa [psKernelSimpleFreshElimNameAux, hMember] using hAbsent)

theorem psKernelSimpleFreshElimName_exit_refines (params : List PsKernelName) :
    ∃ offset : Nat, offset ≤ Nat.succ (psKernelNameListLength params) ∧
      psKernelSimpleFreshElimName params = psKernelSimpleElimNameCandidate offset ∧
      (offset = Nat.succ (psKernelNameListLength params) ∨
        psKernelNameMember (psKernelSimpleFreshElimName params) params = false) := by
  simpa [psKernelSimpleFreshElimName] using
    psKernelSimpleFreshElimNameAux_exit_refines (Nat.succ (psKernelNameListLength params)) params 0


/-- Positive membership reflects syntactic list membership under the existing soundness law. -/
theorem psKernelNameMember_true_refines_membership
    (hString : PsKernelStringEqSoundLaw) (name : PsKernelName) (names : List PsKernelName)
    (hMember : psKernelNameMember name names = true) : name ∈ names := by
  induction names with
  | nil => simp [psKernelNameMember] at hMember
  | cons head tail ih =>
      cases hHead : psKernelNameEq name head with
      | false =>
          exact List.Mem.tail head (ih (by simpa [psKernelNameMember, hHead] using hMember))
      | true =>
          have hEqual := psKernelNameEq_sound_of_string_law hString name head hHead
          subst name
          exact List.Mem.head tail

/-- A negative comparator result excludes syntactic equality only with explicit reflexivity. -/
theorem psKernelNameMember_false_excludes_membership
    (hReflexive : PsKernelStringEqReflexiveLaw) (name : PsKernelName)
    (names : List PsKernelName) (hAbsent : psKernelNameMember name names = false) :
    name ∉ names := by
  induction names with
  | nil => simp
  | cons head tail ih =>
      intro hMember
      cases hHead : psKernelNameEq name head with
      | true => simp [psKernelNameMember, hHead] at hAbsent
      | false =>
          cases hMember with
          | head =>
              have hSelf := psKernelNameEq_refl_of_string_law hReflexive name
              simp [hSelf] at hHead
          | tail _ hTail =>
              exact ih (by simpa [psKernelNameMember, hHead] using hAbsent) hTail

/-- Exact trace, including the membership evidence for every skipped candidate. -/
theorem psKernelSimpleFreshElimNameAux_trace_refines (fuel : Nat) :
    ∀ (params : List PsKernelName) (start : Nat),
      ∃ offset : Nat, offset ≤ fuel ∧
        psKernelSimpleFreshElimNameAux fuel params start =
          psKernelSimpleElimNameCandidate (start + offset) ∧
        (∀ i : Nat, i < offset ->
          psKernelNameMember (psKernelSimpleElimNameCandidate (start + i)) params = true) ∧
        (offset = fuel ∨
          psKernelNameMember (psKernelSimpleFreshElimNameAux fuel params start) params = false) := by
  induction fuel with
  | zero =>
      intro params start
      refine ⟨0, Nat.le_refl 0, ?_, ?_, Or.inl rfl⟩
      · simp [psKernelSimpleFreshElimNameAux]
      · intro i hi; omega
  | succ remaining ih =>
      intro params start
      cases hMember : psKernelNameMember (psKernelSimpleElimNameCandidate start) params with
      | false =>
          refine ⟨0, Nat.zero_le _, ?_, ?_, Or.inr ?_⟩
          · simp [psKernelSimpleFreshElimNameAux, hMember]
          · intro i hi; omega
          · simpa [psKernelSimpleFreshElimNameAux, hMember] using hMember
      | true =>
          obtain ⟨offset, hBound, hCandidate, hVisited, hExit⟩ := ih params (Nat.succ start)
          have hShift : Nat.succ start + offset = start + Nat.succ offset := by omega
          refine ⟨Nat.succ offset, by omega, ?_, ?_, ?_⟩
          · simpa [psKernelSimpleFreshElimNameAux, hMember, hShift] using hCandidate
          · intro i hi
            cases i with
            | zero => simpa using hMember
            | succ i =>
                have hPrev := hVisited i (by omega)
                have hStep : Nat.succ start + i = start + Nat.succ i := by omega
                simpa [hStep] using hPrev
          · cases hExit with
            | inl hLast => exact Or.inl (congrArg Nat.succ hLast)
            | inr hAbsent =>
                exact Or.inr (by simpa [psKernelSimpleFreshElimNameAux, hMember] using hAbsent)

theorem psKernelNameListLength_eq_length (names : List PsKernelName) :
    psKernelNameListLength names = names.length := by
  induction names with
  | nil => rfl
  | cons head tail ih => simpa [psKernelNameListLength] using congrArg Nat.succ ih

/--
The counting argument is closed. Candidate distinctness is an explicit finite
obligation for this declaration, not an adopted primitive law or an axiom.
Only positive comparator soundness is used to exclude fuel exhaustion.
-/
theorem psKernelSimpleFreshElimName_checked_of_distinct_candidates
    (hString : PsKernelStringEqSoundLaw) (params : List PsKernelName)
    (hDistinct : ∀ i : Nat, i < Nat.succ (psKernelNameListLength params) ->
      ∀ j : Nat, j < Nat.succ (psKernelNameListLength params) ->
        psKernelSimpleElimNameCandidate i = psKernelSimpleElimNameCandidate j -> i = j) :
    ∃ offset : Nat, offset < Nat.succ (psKernelNameListLength params) ∧
      psKernelSimpleFreshElimName params = psKernelSimpleElimNameCandidate offset ∧
      psKernelNameMember (psKernelSimpleFreshElimName params) params = false := by
  let fuel := Nat.succ (psKernelNameListLength params)
  obtain ⟨offset, hBound, hCandidate, hVisited, hExit⟩ :=
    psKernelSimpleFreshElimNameAux_trace_refines fuel params 0
  have hNotLast : offset ≠ fuel := by
    intro hLast
    have hNodup : ((List.range fuel).map psKernelSimpleElimNameCandidate).Nodup := by
      apply List.pairwise_map.mpr
      apply List.Pairwise.imp_of_mem _ (List.nodup_range (n := fuel))
      intro i j hi hj hNe hEq
      exact hNe (hDistinct i (List.mem_range.mp hi) j (List.mem_range.mp hj) hEq)
    have hSubset : (List.range fuel).map psKernelSimpleElimNameCandidate ⊆ params := by
      intro name hMem
      obtain ⟨i, hi, rfl⟩ := List.mem_map.mp hMem
      apply psKernelNameMember_true_refines_membership hString
      simpa using hVisited i (by simpa [hLast] using List.mem_range.mp hi)
    have hLength := hNodup.length_le_of_subset hSubset
    simp only [List.length_map, List.length_range] at hLength
    have hParamLength := psKernelNameListLength_eq_length params
    dsimp [fuel] at hLength
    omega
  refine ⟨offset, by omega, ?_, ?_⟩
  · simpa [psKernelSimpleFreshElimName, fuel] using hCandidate
  · have hAbsent := hExit.resolve_left hNotLast
    simpa [psKernelSimpleFreshElimName, fuel] using hAbsent

/--
Semantic freshness needs both the still-open finite candidate obligation and
the still-open comparator reflexivity obligation. Neither follows from the
one-direction StringEq soundness premise.
-/
theorem psKernelSimpleFreshElimName_fresh_of_distinct_candidates
    (hString : PsKernelStringEqSoundLaw) (hReflexive : PsKernelStringEqReflexiveLaw)
    (params : List PsKernelName)
    (hDistinct : ∀ i : Nat, i < Nat.succ (psKernelNameListLength params) ->
      ∀ j : Nat, j < Nat.succ (psKernelNameListLength params) ->
        psKernelSimpleElimNameCandidate i = psKernelSimpleElimNameCandidate j -> i = j) :
    psKernelSimpleFreshElimName params ∉ params := by
  obtain ⟨offset, hBound, hCandidate, hAbsent⟩ :=
    psKernelSimpleFreshElimName_checked_of_distinct_candidates hString params hDistinct
  exact psKernelNameMember_false_excludes_membership hReflexive _ params hAbsent
