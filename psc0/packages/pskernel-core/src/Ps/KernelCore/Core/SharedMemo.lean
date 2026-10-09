import Std.Data.HashMap
import Lean.Data.PersistentHashMap
import Init.Util

/-!
Native sharing support. Keys are hints only: every entry carries the equation
it proves, and a hit validates both the input and the binder cursor. Each table
fixes its specification. Substitution tables are operation-local; structural hash
metadata can persist across queries. No equality decision is inferred from a hash.

These safe Lean primitives require separate PSC0 backend qualification.
-/
namespace PsKernelSharing

structure Entry (α β : Type) (spec : α → Nat → β) where
  node : α
  cursor : Nat
  value : β
  valid : value = spec node cursor

/-- A traversal owns its scratch delta. Checkpointed metadata is persistent
because callers retain parent checker states. Keeping these lifetimes separate
avoids path copying for every temporary syntax result and whole-table copying
when a retained checkpoint is extended. Neither store needs a logical invariant:
every entry already certifies the result it stores. -/
structure Memo (α β : Type) (spec : α → Nat → β) where
  checkpoint : Lean.PersistentHashMap Nat (Entry α β spec) := {}
  scratch : Std.HashMap Nat (Entry α β spec) := {}

instance : EmptyCollection (Memo α β spec) :=
  ⟨{ checkpoint := {}, scratch := {} }⟩

@[inline] def Memo.find? (memo : @& Memo α β spec) (key : Nat) :
    Option (Entry α β spec) :=
  match memo.scratch[key]? with
  | some entry => some entry
  | none => memo.checkpoint.find? key

@[inline] def Memo.insert (memo : Memo α β spec) (key : Nat)
    (entry : Entry α β spec) : Memo α β spec :=
  { memo with scratch := memo.scratch.insert key entry }

/-- Freeze only when metadata must outlive this operation. Read-only cache
queries can consume the result without paying for a persistent checkpoint. -/
def Memo.freeze (memo : Memo α β spec) : Memo α β spec :=
  if memo.scratch.isEmpty then memo else
    { checkpoint := memo.scratch.fold
        (fun (table : Lean.PersistentHashMap Nat (Entry α β spec)) key entry =>
          table.insert key entry) memo.checkpoint
      scratch := {} }

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
    (key : Nat) (node : @& α) (cursor : Nat) (memo : Memo α β spec)
    (descend : Unit → Squash (Result spec node cursor))
    (cacheResult : β → Bool := fun _ => true) :
    Squash (Result spec node cursor) :=
  let miss := fun _ : Unit =>
    Squash.lift (descend ()) fun (result, next) =>
      let updated := if cacheResult result.1 then
        next.insert key ⟨node, cursor, result.1, result.2⟩ else next
      Squash.mk (result, updated)
  match memo.find? key with
  | none => miss ()
  | some entry =>
    if hc : entry.cursor = cursor then
      match withPtrEqDecEq entry.node node (fun _ => inferInstance) with
      | isTrue hn =>
          Squash.mk (⟨entry.value, by simpa [hn, hc] using entry.valid⟩, memo)
      | isFalse _ => miss ()
    else miss ()

/-- A mixed scalar hint avoids allocating a pair at every probe. Collisions are
permitted: probe still validates the full node and cursor. The high bit is
discarded so ordinary 64-bit native keys fit Lean's scalar Nat representation. -/
@[inline] def memoKey (address : USize) (cursor : Nat) : Nat :=
  (mixHash (hash address) (hash cursor) >>> 1).toNat

@[inline] def step {α β : Type} [DecidableEq α] {spec : α → Nat → β}
    (node : @& α) (cursor : Nat) (memo : Memo α β spec)
    (descend : Unit → Squash (Result spec node cursor)) :
    Squash (Result spec node cursor) :=
  withPtrAddr node (fun address => probe (memoKey address cursor) node cursor memo descend)
    (fun _ _ => Subsingleton.elim _ _)


/-- Retain the memo for later calls without exposing any hint-dependent state
logically. The value is exact and the memo component is a subsingleton. -/
def valueAndMemo {α β : Type} {spec : α → Nat → β} {node : α} {cursor : Nat}
    (result : Squash (Result spec node cursor)) :
    β × Squash (Memo α β spec) :=
  Quotient.lift (fun p => (p.1.1, Squash.mk p.2))
    (fun p q _ => Prod.ext (p.1.2.trans q.1.2.symm) (Subsingleton.elim _ _)) result

theorem valueAndMemo_eq {α β : Type} {spec : α → Nat → β} {node : α} {cursor : Nat}
    (result : Squash (Result spec node cursor)) :
    (valueAndMemo result).1 = spec node cursor := by
  induction result using Quotient.ind with
  | _ p => exact p.1.2

end PsKernelSharing
