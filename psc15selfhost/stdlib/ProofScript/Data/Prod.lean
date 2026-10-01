structure Prod (α : Type) (β : Type) where
  fst : α
  snd : β

def product {α : Type} {β : Type}
    (first : α) (second : β) : Prod α β :=
  Prod.mk first second

def productFst {α : Type} {β : Type}
    (value : Prod α β) : α :=
  value.fst

def productSnd {α : Type} {β : Type}
    (value : Prod α β) : β :=
  value.snd

def productSwap {α : Type} {β : Type}
    (value : Prod α β) : Prod β α :=
  Prod.mk value.snd value.fst
