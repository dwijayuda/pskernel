import Ps.KernelCore.Core.ExprV2.Validation
import PsKernelExprV2PagedModelProofs

/-!
Physical-layout guarantees derived from the actual untrusted-input guard.

The source arena is arbitrary. No Layout premise, cached metadata premise,
decoder correspondence or replay success is assumed by the first theorem.
The companion exposes the same source guarantee at public validator success.
The replay and fuel lemmas preserve physical Layout of an internal accumulator;
the final theorem derives Layout of the actual returned canonical arena.
No theorem here establishes metadata correctness, topological decoding, or
ArenaModel.
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
        nonzero, active] at accepted
      exact accepted.1
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
            · simp [Nat.beq_eq, finished] at acceptedScan
              simpa only [Array.getD_eq_getD_getElem?, Array.emptyWithCapacity_eq]
                using acceptedScan.1
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

/- Internal append/replay preservation assumes Layout only for the arena being
   extended. It does not assume valid source metadata or decoded expressions. -/
theorem replay_node_ok_preserves_layout
    (canonical : PsKernelExprV2PagedArena) (node : PsKernelExprV2Node)
    (inserted : PsKernelExprV2PagedArena × Nat)
    (layout : Layout canonical)
    (accepted : psKernelExprV2PagedReplayNode canonical node = Except.ok inserted) :
    Layout inserted.fst := by
  have checked (entry : PsKernelExprV2Entry)
      (success : psKernelExprV2PagedPushChecked canonical entry = Except.ok inserted) :
      Layout inserted.fst := by
    change Except.ok (psKernelExprV2PagedPush canonical entry) = Except.ok inserted at success
    have same : psKernelExprV2PagedPush canonical entry = inserted := by
      injection success
    rw [← same]
    exact push_layout canonical entry layout
  have one (child : Nat) (make : PsKernelExprV2Entry → PsKernelExprV2Entry)
      (success : psKernelExprV2PagedWith1 canonical child make = Except.ok inserted) :
      Layout inserted.fst := by
    cases found : psKernelExprV2PagedRequire canonical child with
    | error error =>
        simp [psKernelExprV2PagedWith1, found] at success
    | ok entry =>
        exact checked (make entry)
          (by simpa only [psKernelExprV2PagedWith1, found] using success)
  have two (left right : Nat)
      (make : PsKernelExprV2Entry → PsKernelExprV2Entry → PsKernelExprV2Entry)
      (success : psKernelExprV2PagedWith2 canonical left right make = Except.ok inserted) :
      Layout inserted.fst := by
    cases first : psKernelExprV2PagedRequire canonical left with
    | error error =>
        simp [psKernelExprV2PagedWith2, first] at success
    | ok leftEntry =>
        cases second : psKernelExprV2PagedRequire canonical right with
        | error error =>
            simp [psKernelExprV2PagedWith2, first, second] at success
        | ok rightEntry =>
            exact checked (make leftEntry rightEntry)
              (by simpa only [psKernelExprV2PagedWith2, first, second] using success)
  have three (first second third : Nat)
      (make : PsKernelExprV2Entry → PsKernelExprV2Entry →
        PsKernelExprV2Entry → PsKernelExprV2Entry)
      (success : psKernelExprV2PagedWith3 canonical first second third make = Except.ok inserted) :
      Layout inserted.fst := by
    cases firstFound : psKernelExprV2PagedRequire canonical first with
    | error error =>
        simp [psKernelExprV2PagedWith3, firstFound] at success
    | ok firstEntry =>
        cases secondFound : psKernelExprV2PagedRequire canonical second with
        | error error =>
            simp [psKernelExprV2PagedWith3, firstFound, secondFound] at success
        | ok secondEntry =>
            cases thirdFound : psKernelExprV2PagedRequire canonical third with
            | error error =>
                simp [psKernelExprV2PagedWith3, firstFound, secondFound, thirdFound] at success
            | ok thirdEntry =>
                exact checked (make firstEntry secondEntry thirdEntry)
                  (by simpa only [psKernelExprV2PagedWith3, firstFound,
                    secondFound, thirdFound] using success)
  cases node with
  | bvar index =>
      exact checked _ accepted
  | fvar name =>
      exact checked _ accepted
  | mvar name =>
      exact checked _ accepted
  | sort level =>
      exact checked _ accepted
  | const name levels =>
      exact checked _ accepted
  | lit literal =>
      exact checked _ accepted
  | app fn arg =>
      exact two fn arg (psKernelExprV2AppEntry fn arg) accepted
  | lam name type body binderInfo =>
      exact two type body (psKernelExprV2LamEntry name type body binderInfo) accepted
  | forallE name type body binderInfo =>
      exact two type body (psKernelExprV2ForallEntry name type body binderInfo) accepted
  | letE name type value body nondep =>
      exact three type value body (psKernelExprV2LetEntry name type value body nondep) accepted
  | mdata tag body =>
      exact one body (psKernelExprV2MDataEntry tag body) accepted
  | proj name index body =>
      exact one body (psKernelExprV2ProjEntry name index body) accepted

/- The source and starting ID are arbitrary. Successful replay preserves the
   physical Layout of the internal canonical accumulator at every fuel step. -/
theorem validate_fuel_ok_preserves_layout
    (fuel : Nat) (source canonical result : PsKernelExprV2PagedArena) (id : Nat)
    (layout : Layout canonical)
    (accepted : psKernelExprV2PagedValidateFuel fuel source canonical id = Except.ok result) :
    Layout result := by
  induction fuel generalizing canonical id with
  | zero =>
      simp [psKernelExprV2PagedValidateFuel] at accepted
  | succ remaining ih =>
      simp only [psKernelExprV2PagedValidateFuel] at accepted
      split at accepted
      · have same : canonical = result := by simpa using accepted
        cases same
        exact layout
      · cases found : psKernelExprV2PagedFind source id with
        | none =>
            simp [found] at accepted
        | some original =>
            simp only [found] at accepted
            cases replayed : psKernelExprV2PagedReplayNode canonical original.node with
            | error error =>
                simp [replayed] at accepted
            | ok inserted =>
                simp only [replayed] at accepted
                have nextLayout : Layout inserted.fst :=
                  replay_node_ok_preserves_layout canonical original.node inserted layout replayed
                split at accepted
                · cases foundNext : psKernelExprV2PagedFind inserted.fst inserted.snd with
                  | none =>
                      simp [foundNext] at accepted
                  | some computed =>
                      simp only [foundNext] at accepted
                      split at accepted
                      · exact ih inserted.fst (Nat.succ id) nextLayout accepted
                      · contradiction
                · contradiction

/- Public success establishes output Layout without any caller-supplied
   source or canonical validity premise. The canonical seed is the actual
   production empty arena; no output validity is assumed. -/
theorem validate_ok_establishes_canonical_layout
    (source canonical : PsKernelExprV2PagedArena)
    (accepted : psKernelExprV2PagedValidate source = Except.ok canonical) :
    Layout canonical := by
  cases shape : psKernelExprV2PagedShapeValid source with
  | false =>
      simp [psKernelExprV2PagedValidate, shape] at accepted
  | true =>
      apply validate_fuel_ok_preserves_layout
        (Nat.succ source.size) source
        (psKernelExprV2PagedEmptyWithLimit source.pageLimit) canonical 0
        (empty_layout source.pageLimit)
      simpa only [psKernelExprV2PagedValidate, shape, ite_true] using accepted

end PsKernelExprV2LayoutBoundaryProofs

#print axioms PsKernelExprV2LayoutBoundaryProofs.shape_valid_establishes_layout
#print axioms PsKernelExprV2LayoutBoundaryProofs.validate_ok_establishes_source_layout
#print axioms PsKernelExprV2LayoutBoundaryProofs.replay_node_ok_preserves_layout
#print axioms PsKernelExprV2LayoutBoundaryProofs.validate_fuel_ok_preserves_layout
#print axioms PsKernelExprV2LayoutBoundaryProofs.validate_ok_establishes_canonical_layout
