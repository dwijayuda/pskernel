/-!
PSCV0 v7: abstract versioned source-AST interchange model.
Only source syntax is carried. Checked kernel proof terms are NOT represented
by a source packet. This model does not verify the concrete JavaScript adapter.
Lean 4.35.0-rc4, no axioms, sorry, unsafe, or partial declarations.
-/

namespace Pscv0.AbiTransport

/-- Grouping belongs to source syntax, not a new kernel constructor. -/
inductive Source where
  | name (value : String)
  | app (fn arg : Source)
  | group (inner : Source)
  deriving Repr, DecidableEq

/-- Wire grammar has a deliberate invalid constructor for negative evidence. -/
inductive Wire where
  | name (value : String)
  | app (fn arg : Wire)
  | group (inner : Wire)
  | invalid
  deriving Repr, DecidableEq

def encode : Source → Wire
  | .name value => .name value
  | .app fn arg => .app (encode fn) (encode arg)
  | .group inner => .group (encode inner)

def decode : Wire → Option Source
  | .name value => some (.name value)
  | .app fn arg =>
      (decode fn).bind fun lhs =>
        (decode arg).map fun rhs => .app lhs rhs
  | .group inner =>
      (decode inner).map fun result => .group result
  | .invalid => none

/-- A closed source tree round-trips through the abstract wire grammar. -/
theorem decode_encode (source : Source) : decode (encode source) = some source := by
  induction source with
  | name value => rfl
  | app fn arg ihFn ihArg =>
      change (decode (encode fn)).bind
        (fun lhs => (decode (encode arg)).map (fun rhs => Source.app lhs rhs)) =
          some (Source.app fn arg)
      rw [ihFn, ihArg]
      rfl
  | group inner ih =>
      change (decode (encode inner)).map Source.group = some (Source.group inner)
      rw [ih]
      rfl

inductive Domain where
  | generated
  | compiler
  | unrelated
  deriving Repr, DecidableEq

structure Packet where
  domain : Domain
  revision : Nat
  wireTree : Wire
  deriving Repr, DecidableEq

/-- A receiver changes the ownership label only after edition and source
domain checks, and only after decoding a structurally accepted wire tree. -/
def transfer (packet : Packet) : Option Packet :=
  if packet.domain = Domain.generated then
    if packet.revision = 7 then
      (decode packet.wireTree).map fun value =>
        { domain := .compiler, revision := 7, wireTree := encode value }
    else none
  else none

theorem valid_source_preserved (source : Source) :
    transfer ⟨.generated, 7, encode source⟩ =
      some ⟨.compiler, 7, encode source⟩ := by
  change (decode (encode source)).map
      (fun value => Packet.mk .compiler 7 (encode value)) =
        some (Packet.mk .compiler 7 (encode source))
  rw [decode_encode]
  rfl

theorem foreign_source_refused (wire : Wire) (revision : Nat) :
    transfer ⟨.unrelated, revision, wire⟩ = none := rfl

theorem incorrect_edition_refused (wire : Wire) (revision : Nat)
    (h : revision ≠ 7) :
    transfer ⟨.generated, revision, wire⟩ = none := by
  change (if revision = 7 then
      (decode wire).map (fun value => Packet.mk .compiler 7 (encode value))
      else none) = none
  rw [if_neg h]

theorem unknown_constructor_refused :
    transfer ⟨.generated, 7, .invalid⟩ = none := rfl

theorem nested_unknown_constructor_refused (value : String) :
    decode (.app (.name value) (.invalid)) = none := rfl

theorem transferred_packet_not_reaccepted_as_source (source : Source) :
    (transfer ⟨.generated, 7, encode source⟩).bind transfer = none := by
  rw [valid_source_preserved]
  rfl

def mixed (f x y : String) : Source :=
  .app (.name f) (.app (.name x) (.name y))

def grouped (f x y : String) : Source :=
  .app (.group (.app (.name f) (.name x))) (.name y)

theorem mixed_and_grouped_remain_distinct (f x y : String) :
    mixed f x y ≠ grouped f x y := by
  intro h
  cases h

theorem valid_grouped_source_preserved (f x y : String) :
    transfer ⟨.generated, 7, encode (grouped f x y)⟩ =
      some ⟨.compiler, 7, encode (grouped f x y)⟩ :=
  valid_source_preserved (grouped f x y)

#print axioms Pscv0.AbiTransport.decode_encode
#print axioms Pscv0.AbiTransport.valid_source_preserved
#print axioms Pscv0.AbiTransport.foreign_source_refused
#print axioms Pscv0.AbiTransport.incorrect_edition_refused
#print axioms Pscv0.AbiTransport.unknown_constructor_refused
#print axioms Pscv0.AbiTransport.nested_unknown_constructor_refused
#print axioms Pscv0.AbiTransport.transferred_packet_not_reaccepted_as_source
#print axioms Pscv0.AbiTransport.mixed_and_grouped_remain_distinct
#print axioms Pscv0.AbiTransport.valid_grouped_source_preserved

end Pscv0.AbiTransport
