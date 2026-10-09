import Std.Data.HashMap
import Init.Util

/-!
Native sharing support. Keys are hints only: every entry carries the equation
it proves, and a hit validates both the input and the binder cursor. The table
is private to one operation. No equality decision is inferred from a hash.

These safe Lean primitives require separate PSC0 backend qualification.
-/
namespace PsKernelSharing

structure Entry (α β : Type) (spec : α → Nat → β) where
  node : α
  cursor : Nat
  value : β
  valid : value = spec node cursor

abbrev Memo (α β : Type) (spec : α → Nat → β) :=
  Std.HashMap (USize × Nat) (Entry α β spec)

abbrev Result {α β : Type} (spec : α → Nat → β) (node : α) (cursor : Nat) :=
  { value : β // value = spec node cursor } × Memo α β spec

def value {α β : Type} {spec : α → Nat → β} {node : α} {cursor : Nat}
    (result : Squash (Result spec node cursor)) : β :=
  Quotient.lift (fun p => p.1.1)
    (fun p q _ => by rw [p.1.2, q.1.2]) result

theorem value_eq {α β : Type} {spec : α → Nat → β} {node : α} {cursor : Nat}
    (result : Squash (Result spec node cursor)) :
    value result = spec node cursor := by
  induction result using Quotient.ind with
  | _ p => exact p.1.2

@[inline] def probe {α β : Type} [DecidableEq α] {spec : α → Nat → β}
    (key : USize × Nat) (node : @& α) (cursor : Nat) (memo : Memo α β spec)
    (descend : Unit → Squash (Result spec node cursor))
    (cacheResult : β → Bool := fun _ => true) :
    Squash (Result spec node cursor) :=
  let miss := fun _ : Unit =>
    Squash.lift (descend ()) fun (result, next) =>
      let updated := if cacheResult result.1 then
        next.insert key ⟨node, cursor, result.1, result.2⟩ else next
      Squash.mk (result, updated)
  match memo[key]? with
  | none => miss ()
  | some entry =>
    if hc : entry.cursor = cursor then
      match withPtrEqDecEq entry.node node (fun _ => inferInstance) with
      | isTrue hn =>
          Squash.mk (⟨entry.value, by simpa [hn, hc] using entry.valid⟩, memo)
      | isFalse _ => miss ()
    else miss ()

@[inline] def step {α β : Type} [DecidableEq α] {spec : α → Nat → β}
    (node : @& α) (cursor : Nat) (memo : Memo α β spec)
    (descend : Unit → Squash (Result spec node cursor)) :
    Squash (Result spec node cursor) :=
  withPtrAddr node (fun address => probe (address, cursor) node cursor memo descend)
    (fun _ _ => Subsingleton.elim _ _)

end PsKernelSharing
