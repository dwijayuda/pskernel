import Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration

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
