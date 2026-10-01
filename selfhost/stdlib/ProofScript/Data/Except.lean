inductive Except (ε : Type) (α : Type) where
  | error (error : ε)
  | ok (value : α)
