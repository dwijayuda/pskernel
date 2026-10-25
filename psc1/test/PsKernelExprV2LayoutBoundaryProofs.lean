import Ps.KernelCore.Core.ExprV2.Validation
import PsKernelExprV2PagedModelProofs

/-!
Physical-layout guarantees derived from the actual untrusted-input guard.

The source arena is arbitrary. No Layout premise, cached metadata premise,
decoder correspondence or replay success is assumed by the first theorem.
The companion exposes the same guarantee at the successful public validator
boundary. Neither theorem establishes metadata correctness, topological
decoding, ArenaModel, or a property of the returned canonical arena.
-/
namespace PsKernelExprV2LayoutBoundaryProofs

open PsKernelExprV2PagedModelProofs

theorem shape_valid_establishes_layout
    (source : PsKernelExprV2PagedArena)
    (accepted : psKernelExprV2PagedShapeValid source = true) :
    Layout source := by
  have nonzero : source.pageLimit ≠ 0 := by
    intro zero
    simp [psKernelExprV2PagedShapeValid, zero] at accepted
  have active : source.active.size ≤ source.pageLimit := by
    by_cases bound : source.active.size ≤ source.pageLimit
    · exact bound
    · simp [psKernelExprV2PagedShapeValid, Nat.beq_eq, Nat.ble_eq,
        nonzero, bound] at accepted
  have total : source.size =
      Nat.add (Nat.mul source.pages.size source.pageLimit) source.active.size := by
    by_cases exactSize : source.size =
        Nat.add (Nat.mul source.pages.size source.pageLimit) source.active.size
    · exact exactSize
    · simp [psKernelExprV2PagedShapeValid, Nat.beq_eq, Nat.ble_eq,
        nonzero, active, exactSize] at accepted
  have fullFromScan :
      ∀ fuel index,
        psKernelExprV2PagedFullPagesFuel
          fuel source.pages source.pageLimit index = true →
        ∀ page, index ≤ page → page < source.pages.size →
          (source.pages.getD page (Array.emptyWithCapacity 0)).size =
            source.pageLimit := by
    intro fuel
    induction fuel with
    | zero =>
        intro index acceptedScan page lower before
        simp [psKernelExprV2PagedFullPagesFuel] at acceptedScan
    | succ remaining ih =>
        intro index acceptedScan page lower before
        change
          (if Nat.beq index source.pages.size then true
           else if Nat.beq
               (source.pages.getD index (Array.emptyWithCapacity 0)).size
               source.pageLimit then
             psKernelExprV2PagedFullPagesFuel
               remaining source.pages source.pageLimit (Nat.succ index)
           else false) = true at acceptedScan
        by_cases finished : index = source.pages.size
        · omega
        · have currentFull :
              (source.pages.getD index (Array.emptyWithCapacity 0)).size =
                source.pageLimit := by
            by_cases full :
                (source.pages.getD index (Array.emptyWithCapacity 0)).size =
                  source.pageLimit
            · exact full
            · simp [Nat.beq_eq, finished, full] at acceptedScan
          have tailAccepted :
              psKernelExprV2PagedFullPagesFuel
                remaining source.pages source.pageLimit (Nat.succ index) = true := by
            simpa only [Nat.beq_eq, finished, currentFull, ite_false, ite_true]
              using acceptedScan
          by_cases current : page = index
          · subst page
            exact currentFull
          · exact ih (Nat.succ index) tailAccepted page (by omega) before
  have scanned :
      psKernelExprV2PagedFullPagesFuel
        (Nat.succ source.pages.size) source.pages source.pageLimit 0 = true := by
    simpa only [psKernelExprV2PagedShapeValid, Nat.beq_eq, Nat.ble_eq,
      nonzero, active, total, ite_false, ite_true] using accepted
  refine ⟨Nat.pos_of_ne_zero nonzero, ?_, active, total⟩
  intro page before
  exact fullFromScan (Nat.succ source.pages.size) 0 scanned page
    (Nat.zero_le page) before

theorem validate_ok_establishes_source_layout
    (source canonical : PsKernelExprV2PagedArena)
    (accepted : psKernelExprV2PagedValidate source = Except.ok canonical) :
    Layout source := by
  cases shape : psKernelExprV2PagedShapeValid source with
  | false =>
      simp [psKernelExprV2PagedValidate, shape] at accepted
  | true =>
      exact shape_valid_establishes_layout source shape

end PsKernelExprV2LayoutBoundaryProofs

#print axioms PsKernelExprV2LayoutBoundaryProofs.shape_valid_establishes_layout
#print axioms PsKernelExprV2LayoutBoundaryProofs.validate_ok_establishes_source_layout
