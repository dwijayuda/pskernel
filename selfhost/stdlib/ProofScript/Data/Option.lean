inductive Option (α : Type) where
  | none
  | some (value : α)

def optionMap {α : Type} {β : Type}
    (f : α -> β) (value : Option α) : Option β :=
  match value with
  | Option.none => Option.none
  | Option.some x => Option.some (f x)

def optionGetOrElse {α : Type}
    (value : Option α) (fallback : α) : α :=
  match value with
  | Option.none => fallback
  | Option.some x => x

def optionOrElse {α : Type}
    (value : Option α) (fallback : Option α) : Option α :=
  match value with
  | Option.none => fallback
  | Option.some x => Option.some x

def optionIsSome {α : Type} (value : Option α) : Bool :=
  match value with
  | Option.none => false
  | Option.some x => true

def optionBind {α : Type} {β : Type}
    (value : Option α) (f : α -> Option β) : Option β :=
  match value with
  | Option.none => Option.none
  | Option.some x => f x
