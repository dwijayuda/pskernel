universe u

namespace FormalSmoke

inductive Box (α : Type u) where
  | mk (value : α)

def unwrap (b : Box α) : α :=
  match b with
  | .mk value => value

theorem unwrap_mk (x : α) : unwrap (Box.mk x) = x := rfl

def id (x : α) : α := x

theorem id_eq (x : α) : id x = x := rfl

end FormalSmoke
