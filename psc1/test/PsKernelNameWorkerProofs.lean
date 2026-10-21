import Lean
import Ps.KernelCore.Core.Name

/-!
Frozen definitions below are copied from Core/Name.lean at both
f9e9b20f92ce2ffa4a666acaf55aa8852949f589 and
3aa077cb64ff06f76727decd01c43ad6c33f351d, with only their identifiers renamed.
The exact equalities quantify over arbitrary strings, names, Nat fuel and raw
byte positions. They do not assume a valid string position or extra fuel.
-/
namespace PsKernelNameWorkerProofs

def originalStringEqFromWithFuel
    (fuel : Nat) :
    String -> String -> Nat -> Nat -> Bool :=
  match fuel with
  | Nat.zero =>
      fun
        (_left : String)
        (_right : String)
        (_leftPos : Nat)
        (_rightPos : Nat) =>
        false
  | Nat.succ remaining =>
      let smaller :
          String -> String -> Nat -> Nat -> Bool :=
        originalStringEqFromWithFuel remaining;
      fun
        (left : String)
        (right : String)
        (leftPos : Nat)
        (rightPos : Nat) =>
        if String.Pos.Raw.atEnd left (String.Pos.Raw.mk leftPos) then
          String.Pos.Raw.atEnd right (String.Pos.Raw.mk rightPos)
        else if String.Pos.Raw.atEnd right (String.Pos.Raw.mk rightPos) then
          false
        else
          let leftChar :=
            String.Internal.get left (String.Pos.Raw.mk leftPos);
          let rightChar :=
            String.Internal.get right (String.Pos.Raw.mk rightPos);
          if Nat.beq (Char.toNat leftChar) (Char.toNat rightChar) then
            smaller
              left
              right
              (String.Pos.Raw.byteIdx
                (String.Pos.Raw.next
                  left
                  (String.Pos.Raw.mk leftPos)))
              (String.Pos.Raw.byteIdx
                (String.Pos.Raw.next
                  right
                  (String.Pos.Raw.mk rightPos)))
          else
            false

def originalStringEq
    (left : String)
    (right : String) : Bool :=
  if Nat.beq (String.utf8ByteSize left) (String.utf8ByteSize right) then
    originalStringEqFromWithFuel
      (Nat.succ (String.utf8ByteSize left))
      left
      right
      0
      0
  else
    false

def originalNameEq
    (left : PsKernelName) :
    PsKernelName -> Bool :=
  match left with
  | PsKernelName.anonymous =>
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.anonymous => true
        | _ => false
  | PsKernelName.str leftParent leftValue =>
      let smaller : PsKernelName -> Bool :=
        originalNameEq leftParent;
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.str rightParent rightValue =>
            if originalStringEq leftValue rightValue then
              smaller rightParent
            else
              false
        | _ => false
  | PsKernelName.num leftParent leftValue =>
      let smaller : PsKernelName -> Bool :=
        originalNameEq leftParent;
      fun (right : PsKernelName) =>
        match right with
        | PsKernelName.num rightParent rightValue =>
            if Nat.beq leftValue rightValue then
              smaller rightParent
            else
              false
        | _ => false

theorem raw_worker_exact
    (fuel : Nat) (left right : String) (leftPos rightPos : Nat) :
    psKernelStringEqFromWorkerWithFuel fuel left right leftPos rightPos =
      originalStringEqFromWithFuel fuel left right leftPos rightPos := by
  induction fuel generalizing left right leftPos rightPos with
  | zero => rfl
  | succ remaining ih =>
      simp only [psKernelStringEqFromWorkerWithFuel,
        originalStringEqFromWithFuel, ih]

theorem raw_public_exact
    (fuel : Nat) (left right : String) (leftPos rightPos : Nat) :
    psKernelStringEqFromWithFuel fuel left right leftPos rightPos =
      originalStringEqFromWithFuel fuel left right leftPos rightPos := by
  exact raw_worker_exact fuel left right leftPos rightPos

theorem string_public_exact (left right : String) :
    psKernelStringEq left right = originalStringEq left right := by
  simp only [psKernelStringEq, originalStringEq, raw_worker_exact]

theorem name_worker_exact (left right : PsKernelName) :
    psKernelNameEqWorker left right = originalNameEq left right := by
  induction left generalizing right with
  | anonymous => cases right <;> rfl
  | str parent value ih =>
      cases right <;>
        simp only [psKernelNameEqWorker, originalNameEq, string_public_exact, ih]
  | num parent value ih =>
      cases right <;> simp only [psKernelNameEqWorker, originalNameEq, ih]

theorem name_public_exact (left right : PsKernelName) :
    psKernelNameEq left right = originalNameEq left right := by
  exact name_worker_exact left right

theorem raw_partial_application_exact (fuel : Nat) :
    psKernelStringEqFromWithFuel fuel = originalStringEqFromWithFuel fuel := by
  funext left right leftPos rightPos
  exact raw_public_exact fuel left right leftPos rightPos

theorem name_partial_application_exact (left : PsKernelName) :
    psKernelNameEq left = originalNameEq left := by
  funext right
  exact name_public_exact left right

theorem raw_zero_fuel_exact (left right : String) (leftPos rightPos : Nat) :
    psKernelStringEqFromWithFuel 0 left right leftPos rightPos = false := by
  rfl

end PsKernelNameWorkerProofs

#print axioms PsKernelNameWorkerProofs.raw_worker_exact
#print axioms PsKernelNameWorkerProofs.raw_public_exact
#print axioms PsKernelNameWorkerProofs.string_public_exact
#print axioms PsKernelNameWorkerProofs.name_worker_exact
#print axioms PsKernelNameWorkerProofs.name_public_exact
#print axioms PsKernelNameWorkerProofs.raw_partial_application_exact
#print axioms PsKernelNameWorkerProofs.name_partial_application_exact
#print axioms PsKernelNameWorkerProofs.raw_zero_fuel_exact
