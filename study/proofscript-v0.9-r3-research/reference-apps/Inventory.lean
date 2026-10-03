import Std
set_option autoImplicit false

namespace ProofScript.R3.ReferenceApp

structure Inventory where
  total : Nat
  available : Nat
  reserved : Nat
  deriving Repr, DecidableEq

def invariant (s : Inventory) : Prop :=
  s.available + s.reserved = s.total

def reserve (s : Inventory) (amount : Nat) : Except Unit Inventory :=
  if amount <= s.available then
    .ok {
      total := s.total
      available := s.available - amount
      reserved := s.reserved + amount
    }
  else
    .error ()

theorem reserve_success
    (s : Inventory)
    (amount : Nat)
    (hAvail : amount <= s.available) :
    reserve s amount =
      .ok {
        total := s.total
        available := s.available - amount
        reserved := s.reserved + amount
      } := by
  simp [reserve, hAvail]

theorem reserve_preserves_invariant
    (s : Inventory)
    (amount : Nat)
    (hInv : invariant s)
    (hAvail : amount <= s.available) :
    invariant {
      total := s.total
      available := s.available - amount
      reserved := s.reserved + amount
    } := by
  unfold invariant at hInv ⊢
  calc
    (s.available - amount) + (s.reserved + amount)
        = ((s.available - amount) + amount) + s.reserved := by
            simp [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]
    _ = s.available + s.reserved := by
          rw [Nat.sub_add_cancel hAvail]
    _ = s.total := hInv

theorem reserve_failure_unchanged
    (s : Inventory)
    (amount : Nat)
    (hTooLarge : ¬ amount <= s.available) :
    reserve s amount = .error () := by
  simp [reserve, hTooLarge]

#print axioms ProofScript.R3.ReferenceApp.reserve_preserves_invariant
